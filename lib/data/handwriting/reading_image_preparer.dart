import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:image/image.dart' as img;

import '../../domain/handwriting/reading_policy.dart';
import '../../domain/handwriting/straightening.dart';
import '../../platform/handwriting/handwriting_reader.dart';
import '../attachments/photo_compressor.dart';

/// A photo of handwriting while its corners are placed (T6a.4, DD-021):
/// upright, at most `ReadingPolicy.workingMaxSide`, in memory only (AC
/// REQ-064 d). [image] is for the screen; [dispose] it when done.
class WorkingPhoto {
  /// [image] and its pixels [_rgba], four bytes each; made by
  /// [ReadingImagePreparer.open].
  WorkingPhoto(this.image, this._rgba);

  final ui.Image image;
  final ByteBuffer _rgba;

  int get width => image.width;
  int get height => image.height;

  void dispose() => image.dispose();
}

/// Turns a photo into what the model reads (DD-021): decoded upright by the
/// engine's codec (as for photo attachments, DD-006), optionally straightened
/// by four corners, then made smaller to `ReadingPolicy.maxSide` and handed
/// over as RGB pixels. The pixel work runs in an isolate. Nothing is written
/// to disk (CLAUDE.md rule 2).
class ReadingImagePreparer {
  const ReadingImagePreparer({this.policy = ReadingPolicy.standard});

  final ReadingPolicy policy;

  /// [bytes] (a JPEG, PNG, … as the camera or the picker gave it) as a
  /// working photo. Throws [PhotoFormatException].
  Future<WorkingPhoto> open(Uint8List bytes) async {
    final image = await PhotoCompressor.decodeUpright(
      bytes,
      policy.workingMaxSide,
    );
    try {
      return WorkingPhoto(image, await PhotoCompressor.rgbaOf(image));
    } catch (_) {
      image.dispose();
      rethrow;
    }
  }

  /// The part of [photo] within [corners], straightened, as the model reads
  /// it; [Corners.whole] gives the whole photo. Throws [ArgumentError] for
  /// corners that are not [Corners.isUsable] (crossed corners would give a
  /// mirrored image).
  Future<ReadingImage> prepare(WorkingPhoto photo, Corners corners) async {
    final width = photo.width;
    final height = photo.height;
    if (!corners.isWhole && !corners.isUsable(width, height)) {
      throw ArgumentError.value(corners, 'corners', 'not usable');
    }
    final rgba = photo._rgba;
    final maxSide = policy.maxSide;
    return Isolate.run(
      () => prepareRgba(
        width: width,
        height: height,
        rgba: rgba,
        corners: corners,
        maxSide: maxSide,
      ),
    );
  }
}

/// The pixel work of [ReadingImagePreparer.prepare] on [rgba] (four bytes
/// per pixel), without the engine: also what a test runs.
ReadingImage prepareRgba({
  required int width,
  required int height,
  required ByteBuffer rgba,
  required Corners corners,
  required int maxSide,
}) {
  var image = img.Image.fromBytes(
    width: width,
    height: height,
    bytes: rgba,
    numChannels: 4,
  );
  if (!corners.isWhole) {
    final [tl, tr, br, bl] = [
      for (final (x, y) in corners.inPixels(width, height)) img.Point(x, y),
    ];
    final size = corners.straightenedSize(width, height);
    // Linear: the corners rarely fall on whole pixels. The straightened part
    // keeps the working detail and is made smaller below, as in S6.
    image = img.copyRectify(
      image,
      topLeft: tl,
      topRight: tr,
      bottomRight: br,
      bottomLeft: bl,
      interpolation: img.Interpolation.linear,
      toImage: img.Image(
        width: size.width,
        height: size.height,
        numChannels: 4,
      ),
    );
  }
  final fit = PixelSize(image.width, image.height).fitWithin(maxSide);
  if (fit.width != image.width || fit.height != image.height) {
    // Average: each pixel of the result is the mean of the ones it covers,
    // as S6 made its images smaller.
    image = img.copyResize(
      image,
      width: fit.width,
      height: fit.height,
      interpolation: img.Interpolation.average,
    );
  }
  return ReadingImage(
    width: image.width,
    height: image.height,
    rgb: _onWhite(image.getBytes(order: img.ChannelOrder.rgba)),
  );
}

/// RGBA pixels as RGB on white paper: a transparent part of a picture (a
/// PNG from the picker) would otherwise be black, and dark ink on it lost.
Uint8List _onWhite(Uint8List rgba) {
  final rgb = Uint8List(rgba.length ~/ 4 * 3);
  for (var i = 0, o = 0; i < rgba.length; i += 4, o += 3) {
    final alpha = rgba[i + 3];
    if (alpha == 255) {
      rgb[o] = rgba[i];
      rgb[o + 1] = rgba[i + 1];
      rgb[o + 2] = rgba[i + 2];
    } else {
      final white = 255 * (255 - alpha);
      rgb[o] = (rgba[i] * alpha + white) ~/ 255;
      rgb[o + 1] = (rgba[i + 1] * alpha + white) ~/ 255;
      rgb[o + 2] = (rgba[i + 2] * alpha + white) ~/ 255;
    }
  }
  return rgb;
}
