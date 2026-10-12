import 'package:flutter_test/flutter_test.dart';
import 'package:offload/domain/handwriting/straightening.dart';

/// The corners of straightening (T6a.4, DD-021, SPEC Q45).
void main() {
  test('the corners start at the photo corners: the whole photo', () {
    expect(Corners.whole.isWhole, isTrue);
    expect(Corners.whole.isUsable(400, 300), isTrue);
    expect(Corners.whole.straightenedSize(400, 300), const PixelSize(399, 299));
  });

  test('a moved corner is no longer whole and stays inside the photo', () {
    final moved = Corners.whole.moved(
      Corner.topRight,
      const CornerPoint(1.4, -0.2),
    );
    expect(moved.isWhole, isTrue, reason: 'clamped back to the corner');
    final inward = Corners.whole.moved(
      Corner.topLeft,
      const CornerPoint(0.1, 0.2),
    );
    expect(inward.isWhole, isFalse);
    expect(inward[Corner.topLeft], const CornerPoint(0.1, 0.2));
    expect(inward[Corner.bottomRight], const CornerPoint(1, 1));
  });

  test('pixels count to the last pixel, clockwise from the top left', () {
    expect(Corners.whole.inPixels(101, 51), [
      (0.0, 0.0),
      (100.0, 0.0),
      (100.0, 50.0),
      (0.0, 50.0),
    ]);
  });

  test('a skewed board: the longer of each pair of opposite sides', () {
    const corners = Corners(
      topLeft: CornerPoint(0.1, 0.1),
      topRight: CornerPoint(0.9, 0.2),
      bottomRight: CornerPoint(0.8, 0.9),
      bottomLeft: CornerPoint(0.2, 0.8),
    );
    // 1001 × 1001 photo: 1000 px per unit. Top 806, bottom 608; left 707,
    // right 707.
    expect(corners.straightenedSize(1001, 1001), const PixelSize(806, 707));
    expect(corners.isUsable(1001, 1001), isTrue);
  });

  test('corners dragged past each other cannot be straightened', () {
    final crossed = Corners.whole
        .moved(Corner.topLeft, const CornerPoint(1, 0.5))
        .moved(Corner.topRight, const CornerPoint(0, 0.5));
    expect(crossed.isUsable(400, 300), isFalse);
    final mirrored = Corners.whole
        .moved(Corner.topLeft, const CornerPoint(1, 0))
        .moved(Corner.topRight, const CornerPoint(0, 0))
        .moved(Corner.bottomRight, const CornerPoint(0, 1))
        .moved(Corner.bottomLeft, const CornerPoint(1, 1));
    expect(mirrored.isUsable(400, 300), isFalse);
  });

  test('a dent (one corner pulled inside) cannot be straightened', () {
    final dent = Corners.whole.moved(
      Corner.bottomRight,
      const CornerPoint(0.3, 0.3),
    );
    expect(dent.isUsable(400, 300), isFalse);
  });

  test('a shape too small to read cannot be straightened', () {
    const tiny = Corners(
      topLeft: CornerPoint(0.5, 0.5),
      topRight: CornerPoint(0.55, 0.5),
      bottomRight: CornerPoint(0.55, 0.55),
      bottomLeft: CornerPoint(0.5, 0.55),
    );
    expect(tiny.isUsable(400, 300), isFalse);
    expect(tiny.isUsable(400, 300, minArea: 0.001), isTrue);
  });

  test('a size fits within the longest side, keeping its shape', () {
    expect(
      const PixelSize(2560, 1920).fitWithin(1280),
      const PixelSize(1280, 960),
    );
    expect(
      const PixelSize(900, 2000).fitWithin(1280),
      const PixelSize(576, 1280),
    );
    expect(
      const PixelSize(800, 600).fitWithin(1280),
      const PixelSize(800, 600),
    );
    expect(const PixelSize(5000, 1).fitWithin(1280), const PixelSize(1280, 1));
  });
}
