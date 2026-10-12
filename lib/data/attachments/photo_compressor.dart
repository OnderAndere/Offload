import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:image/image.dart' as img;

import '../../domain/attachments/image_policy.dart';

/// The two files of a photo (REQ-027, DD-006/D1), as JPEG bytes in memory:
/// nothing is written before it is encrypted (CLAUDE.md rule 2).
class CompressedPhoto {
  const CompressedPhoto({required this.display, required this.thumbnail});

  final Uint8List display;
  final Uint8List thumbnail;
}

/// A picture the platform cannot decode (a format it does not know, or no
/// picture at all).
class PhotoFormatException implements Exception {
  const PhotoFormatException(this.message);

  final String message;

  @override
  String toString() => 'PhotoFormatException: $message';
}

/// Makes the display version and the thumbnail of a photo (DD-006/D5, spike
/// S2): Flutter's engine codec decodes, applies the EXIF orientation and
/// downscales, natively and off the UI thread; `package:image` only encodes
/// the small result as JPEG, in an isolate. The pixels go into a new JPEG,
/// so no EXIF (location included) comes along (DD-006/D4, REQ-024).
class PhotoCompressor {
  const PhotoCompressor({this.policy = ImagePolicy.standard});

  final ImagePolicy policy;

  /// The display version of [source] and the thumbnail made from it.
  /// Throws [PhotoFormatException].
  Future<CompressedPhoto> compress(Uint8List source) async {
    final display = await _scaled(
      source,
      policy.displayMaxSide,
      policy.displayQuality,
    );
    return CompressedPhoto(
      display: display,
      thumbnail: await thumbnailOf(display),
    );
  }

  /// The thumbnail of a display version: also how a missing one is made
  /// again (DD-006/D9). Throws [PhotoFormatException].
  Future<Uint8List> thumbnailOf(Uint8List display) =>
      _scaled(display, policy.thumbnailMaxSide, policy.thumbnailQuality);

  Future<Uint8List> _scaled(Uint8List bytes, int maxSide, int quality) async {
    final image = await decodeUpright(bytes, maxSide);
    final ByteBuffer rgba;
    final int outWidth;
    final int outHeight;
    try {
      rgba = await rgbaOf(image);
      (outWidth, outHeight) = (image.width, image.height);
    } finally {
      image.dispose();
    }
    return Isolate.run(
      () => img.encodeJpg(
        img.Image.fromBytes(
          width: outWidth,
          height: outHeight,
          bytes: rgba,
          numChannels: 4,
        ),
        quality: quality,
      ),
    );
  }

  /// [bytes] decoded upright (EXIF orientation applied) and made smaller to
  /// fit in [maxSide], never larger; natively, off the UI thread. The caller
  /// disposes the image. Throws [PhotoFormatException].
  static Future<ui.Image> decodeUpright(Uint8List bytes, int maxSide) async {
    final (width, height, orientation) = await _storedSize(bytes);
    final target = decodeTarget(
      width: width,
      height: height,
      orientation: orientation,
      maxSide: maxSide,
    );
    final ui.Codec codec;
    try {
      codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: target.width,
        targetHeight: target.height,
      );
    } catch (e) {
      throw PhotoFormatException('cannot decode: $e');
    }
    try {
      return (await codec.getNextFrame()).image;
    } catch (e) {
      throw PhotoFormatException('cannot decode: $e');
    } finally {
      codec.dispose();
    }
  }

  /// The pixels of [image], four bytes (R, G, B, A) each, row by row.
  /// Throws [PhotoFormatException].
  static Future<ByteBuffer> rgbaOf(ui.Image image) async {
    final ByteData? data;
    try {
      data = await image.toByteData(format: ui.ImageByteFormat.rawStraightRgba);
    } catch (e) {
      throw PhotoFormatException('cannot decode: $e');
    }
    if (data == null) throw const PhotoFormatException('no pixels');
    return data.buffer;
  }

  /// The size as stored and the EXIF orientation: for a JPEG from its own
  /// headers (cheap, no decoding), else from the platform's descriptor,
  /// upright already.
  static Future<(int, int, int)> _storedSize(Uint8List bytes) async {
    if (_isJpeg(bytes)) {
      final headers = _jpegHeaders(bytes);
      if (headers case (final width, final height, final scan)) {
        // Only the headers, closed with an end marker: the EXIF never
        // follows the image data, and a JPEG without it is not walked to
        // its end on the UI isolate (review T5.2).
        final head = Uint8List(scan + 2)
          ..setRange(0, scan, bytes)
          ..setRange(scan, scan + 2, const [0xFF, 0xD9]);
        int orientation;
        try {
          orientation = img.decodeJpgExif(head)?.imageIfd.orientation ?? 1;
        } catch (_) {
          orientation = 1;
        }
        return (width, height, orientation);
      }
    }
    try {
      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      final size = (descriptor.width, descriptor.height, 1);
      descriptor.dispose();
      buffer.dispose();
      return size;
    } catch (e) {
      throw PhotoFormatException('not a picture: $e');
    }
  }

  static bool _isJpeg(Uint8List b) =>
      b.length > 3 && b[0] == 0xFF && b[1] == 0xD8;

  /// Width and height from the JPEG's start-of-frame marker and where its
  /// image data starts (the start-of-scan marker, else the end), or null.
  static (int, int, int)? _jpegHeaders(Uint8List b) {
    (int, int)? size;
    var i = 2;
    while (i + 9 < b.length) {
      if (b[i] != 0xFF) {
        i++;
        continue;
      }
      final marker = b[i + 1];
      // Fill bytes and markers without a length.
      if (marker == 0xFF || (marker >= 0xD0 && marker <= 0xD9)) {
        i += marker == 0xFF ? 1 : 2;
        continue;
      }
      if (marker == 0xDA) break;
      final length = (b[i + 2] << 8) | b[i + 3];
      final isFrame =
          marker >= 0xC0 &&
          marker <= 0xCF &&
          marker != 0xC4 &&
          marker != 0xC8 &&
          marker != 0xCC;
      if (isFrame && size == null) {
        final height = (b[i + 5] << 8) | b[i + 6];
        final width = (b[i + 7] << 8) | b[i + 8];
        if (width <= 0 || height <= 0) return null;
        size = (width, height);
      }
      i += 2 + length;
    }
    return switch (size) {
      (final width, final height) => (width, height, i.clamp(2, b.length)),
      null => null,
    };
  }
}
