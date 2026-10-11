import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:offload/data/attachments/photo_compressor.dart';

/// Compressing a photo (T5.2, REQ-024, REQ-027, DD-006 D1, D4, D5): the
/// sizes, the orientation applied to the pixels and no EXIF left.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const compressor = PhotoCompressor();

  /// A JPEG of [width]×[height] as stored, blue with a red top-left
  /// corner, with EXIF [orientation] and a location.
  Uint8List photo(int width, int height, {int orientation = 1}) {
    final image = img.Image(width: width, height: height);
    img.fill(image, color: img.ColorRgb8(0, 0, 255));
    img.fillRect(
      image,
      x1: 0,
      y1: 0,
      x2: width ~/ 4,
      y2: height ~/ 4,
      color: img.ColorRgb8(255, 0, 0),
    );
    image.exif.imageIfd.orientation = orientation;
    image.exif.gpsIfd['GPSLatitudeRef'] = img.IfdValueAscii('N');
    image.exif.gpsIfd['GPSMapDatum'] = img.IfdValueAscii('WGS-84');
    return img.encodeJpg(image, quality: 95);
  }

  /// Whether [jpeg] holds an EXIF block anywhere.
  bool hasExif(Uint8List jpeg) {
    const marker = [0x45, 0x78, 0x69, 0x66, 0, 0]; // "Exif\0\0"
    for (var i = 0; i + marker.length <= jpeg.length; i++) {
      var match = true;
      for (var j = 0; j < marker.length && match; j++) {
        match = jpeg[i + j] == marker[j];
      }
      if (match) return true;
    }
    return false;
  }

  bool isRed(img.Pixel p) => p.r > 200 && p.g < 80 && p.b < 80;

  test('the test photo carries its orientation and location', () {
    final source = photo(400, 300, orientation: 6);
    final exif = img.decodeJpgExif(source)!;
    expect(exif.imageIfd.orientation, 6);
    expect(exif.gpsIfd.isEmpty, isFalse);
    expect(hasExif(source), isTrue);
  });

  test('display 1600 and thumbnail 256 on the long side', () async {
    final result = await compressor.compress(photo(3200, 2400));
    final display = img.decodeJpg(result.display)!;
    final thumbnail = img.decodeJpg(result.thumbnail)!;
    expect((display.width, display.height), (1600, 1200));
    expect((thumbnail.width, thumbnail.height), (256, 192));
  });

  test('a portrait photo stored on its side is upright in both files '
      '(orientation 6), and keeps no EXIF', () async {
    // Stored 3200×2400 with orientation 6: upright it is 2400×3200, and
    // the stored top-left corner ends up at the top right.
    final result = await compressor.compress(photo(3200, 2400, orientation: 6));
    for (final (bytes, long) in [
      (result.display, 1600),
      (result.thumbnail, 256),
    ]) {
      final image = img.decodeJpg(bytes)!;
      expect(image.height, long);
      expect(image.width, long * 3 ~/ 4);
      expect(isRed(image.getPixel(image.width - 2, 1)), isTrue);
      expect(isRed(image.getPixel(1, 1)), isFalse);
      expect(hasExif(bytes), isFalse);
    }
  });

  test(
    'a small photo is not enlarged; still upright and without EXIF',
    () async {
      final result = await compressor.compress(photo(400, 300, orientation: 6));
      final display = img.decodeJpg(result.display)!;
      expect((display.width, display.height), (300, 400));
      expect(hasExif(result.display), isFalse);
      final thumbnail = img.decodeJpg(result.thumbnail)!;
      expect((thumbnail.width, thumbnail.height), (192, 256));
    },
  );

  test('a PNG goes through the same way', () async {
    final png = img.encodePng(img.Image(width: 2000, height: 1000));
    final result = await compressor.compress(png);
    final display = img.decodeJpg(result.display)!;
    expect((display.width, display.height), (1600, 800));
  });

  test('something that is no picture: PhotoFormatException', () async {
    await expectLater(
      compressor.compress(Uint8List.fromList(List.filled(64, 7))),
      throwsA(isA<PhotoFormatException>()),
    );
  });
}
