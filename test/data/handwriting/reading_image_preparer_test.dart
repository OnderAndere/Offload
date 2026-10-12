import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:offload/data/attachments/photo_compressor.dart';
import 'package:offload/data/handwriting/reading_image_preparer.dart';
import 'package:offload/domain/handwriting/reading_policy.dart';
import 'package:offload/domain/handwriting/straightening.dart';

/// A photo of handwriting made ready for the model (T6a.4, DD-021): upright,
/// optionally straightened, at most 1280 px, RGB in memory.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// A white [width] × [height] image, four channels.
  img.Image page(int width, int height) {
    final image = img.Image(width: width, height: height, numChannels: 4);
    img.fill(image, color: img.ColorRgba8(255, 255, 255, 255));
    return image;
  }

  ByteBuffer rgbaOf(img.Image image) =>
      image.getBytes(order: img.ChannelOrder.rgba).buffer;

  test('the whole photo: made smaller to 1280, three bytes a pixel', () {
    final image = page(2560, 1920);
    final reading = prepareRgba(
      width: 2560,
      height: 1920,
      rgba: rgbaOf(image),
      corners: Corners.whole,
      maxSide: 1280,
    );
    expect((reading.width, reading.height), (1280, 960));
    expect(reading.rgb.length, 1280 * 960 * 3);
    expect(reading.rgb.take(6), [255, 255, 255, 255, 255, 255]);
  });

  test('a small photo is never made larger', () {
    final reading = prepareRgba(
      width: 640,
      height: 480,
      rgba: rgbaOf(page(640, 480)),
      corners: Corners.whole,
      maxSide: 1280,
    );
    expect((reading.width, reading.height), (640, 480));
  });

  test('straightened: the part within the corners fills the result', () {
    // A grey board on a black wall, at an angle: everything inside the
    // corners is grey, so the straightened image is grey edge to edge.
    final image = img.Image(width: 1001, height: 1001, numChannels: 4);
    img.fill(image, color: img.ColorRgba8(0, 0, 0, 255));
    const corners = Corners(
      topLeft: CornerPoint(0.1, 0.1),
      topRight: CornerPoint(0.9, 0.2),
      bottomRight: CornerPoint(0.8, 0.9),
      bottomLeft: CornerPoint(0.2, 0.8),
    );
    img.fillPolygon(
      image,
      vertices: [
        for (final (x, y) in corners.inPixels(1001, 1001)) img.Point(x, y),
      ],
      color: img.ColorRgba8(128, 128, 128, 255),
    );
    final reading = prepareRgba(
      width: 1001,
      height: 1001,
      rgba: rgbaOf(image),
      corners: corners,
      maxSide: 1280,
    );
    expect((reading.width, reading.height), (806, 707));
    // Away from the edges (where the wall can be sampled in part), every
    // pixel is the board's grey.
    var notGrey = 0;
    for (var y = 3; y < reading.height - 3; y++) {
      for (var x = 3; x < reading.width - 3; x++) {
        final i = (y * reading.width + x) * 3;
        if ((reading.rgb[i] - 128).abs() > 8) notGrey++;
      }
    }
    expect(notGrey, 0);
  });

  test('a straightened part larger than 1280 is made smaller', () {
    const corners = Corners(
      topLeft: CornerPoint(0, 0),
      topRight: CornerPoint(1, 0.05),
      bottomRight: CornerPoint(1, 1),
      bottomLeft: CornerPoint(0, 1),
    );
    final reading = prepareRgba(
      width: 2560,
      height: 1920,
      rgba: rgbaOf(page(2560, 1920)),
      corners: corners,
      maxSide: 1280,
    );
    expect(reading.width, 1280);
    expect(reading.rgb.length, reading.width * reading.height * 3);
  });

  test('a photo opens upright at the working size, and is prepared from '
      'there', () async {
    // 3000 × 1000 as stored, EXIF orientation 6 (a quarter turn): upright
    // it is 1000 × 3000, at the working size 853 × 2560.
    final stored = img.Image(width: 3000, height: 1000);
    img.fill(stored, color: img.ColorRgb8(255, 255, 255));
    stored.exif.imageIfd.orientation = 6;
    final bytes = img.encodeJpg(stored, quality: 90);
    const preparer = ReadingImagePreparer();
    final photo = await preparer.open(bytes);
    addTearDown(photo.dispose);
    expect((photo.width, photo.height), (853, 2560));
    final reading = await preparer.prepare(photo, Corners.whole);
    expect((reading.width, reading.height), (427, 1280));
    expect(reading.rgb.length, 427 * 1280 * 3);
  });

  test('transparent pixels are white paper, opaque ones stay', () {
    final image = img.Image(width: 3, height: 1, numChannels: 4)
      ..setPixelRgba(0, 0, 0, 0, 0, 0)
      ..setPixelRgba(1, 0, 0, 0, 0, 255)
      ..setPixelRgba(2, 0, 0, 0, 0, 128);
    final reading = prepareRgba(
      width: 3,
      height: 1,
      rgba: rgbaOf(image),
      corners: Corners.whole,
      maxSide: 1280,
    );
    expect(reading.rgb, [255, 255, 255, 0, 0, 0, 127, 127, 127]);
  });

  test('crossed corners are refused, not read mirrored', () async {
    const preparer = ReadingImagePreparer();
    final photo = await preparer.open(img.encodePng(page(40, 30)));
    addTearDown(photo.dispose);
    final mirrored = Corners.whole
        .moved(Corner.topLeft, const CornerPoint(1, 0))
        .moved(Corner.topRight, const CornerPoint(0, 0))
        .moved(Corner.bottomRight, const CornerPoint(0, 1))
        .moved(Corner.bottomLeft, const CornerPoint(1, 1));
    await expectLater(
      preparer.prepare(photo, mirrored),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('not a picture is refused', () async {
    await expectLater(
      const ReadingImagePreparer().open(Uint8List.fromList([1, 2, 3, 4])),
      throwsA(isA<PhotoFormatException>()),
    );
  });

  test('the working size is twice what the model reads', () {
    expect(
      ReadingPolicy.standard.workingMaxSide,
      2 * ReadingPolicy.standard.maxSide,
    );
  });
}
