/// Straightening a photo of handwriting before it is read (DD-021, SPEC
/// Q45): four corners the user drags onto the corners of the board or page.
/// Spike S6: character errors 7.9 → 4.5 % on the two most skewed photos.
library;

import 'dart:math' as math;

/// A point in a photo as fractions of its width and height (0–1), so the
/// corners stay put at any size the photo is shown.
class CornerPoint {
  const CornerPoint(this.x, this.y);

  final double x;
  final double y;

  @override
  bool operator ==(Object other) =>
      other is CornerPoint && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'CornerPoint($x, $y)';
}

enum Corner { topLeft, topRight, bottomRight, bottomLeft }

/// The four corners of the part of a photo to read; [whole] reads the photo
/// as it is.
class Corners {
  const Corners({
    required this.topLeft,
    required this.topRight,
    required this.bottomRight,
    required this.bottomLeft,
  });

  /// The corners of the photo itself: where the corners start.
  static const whole = Corners(
    topLeft: CornerPoint(0, 0),
    topRight: CornerPoint(1, 0),
    bottomRight: CornerPoint(1, 1),
    bottomLeft: CornerPoint(0, 1),
  );

  final CornerPoint topLeft;
  final CornerPoint topRight;
  final CornerPoint bottomRight;
  final CornerPoint bottomLeft;

  bool get isWhole => this == whole;

  CornerPoint operator [](Corner corner) => switch (corner) {
    Corner.topLeft => topLeft,
    Corner.topRight => topRight,
    Corner.bottomRight => bottomRight,
    Corner.bottomLeft => bottomLeft,
  };

  /// [corner] moved to [to], kept inside the photo.
  Corners moved(Corner corner, CornerPoint to) {
    final p = CornerPoint(to.x.clamp(0.0, 1.0), to.y.clamp(0.0, 1.0));
    return Corners(
      topLeft: corner == Corner.topLeft ? p : topLeft,
      topRight: corner == Corner.topRight ? p : topRight,
      bottomRight: corner == Corner.bottomRight ? p : bottomRight,
      bottomLeft: corner == Corner.bottomLeft ? p : bottomLeft,
    );
  }

  /// Whether the corners make a shape that can be straightened: in their
  /// own places (none dragged past another, so the shape is convex and not
  /// mirrored) and not tiny (at least [minArea] of a [width] × [height]
  /// photo).
  bool isUsable(int width, int height, {double minArea = 0.01}) {
    final p = _inPixels(width, height);
    for (var i = 0; i < 4; i++) {
      final (ax, ay) = p[i];
      final (bx, by) = p[(i + 1) % 4];
      final (cx, cy) = p[(i + 2) % 4];
      // Clockwise on screen (y down) gives a positive turn at each corner.
      final turn = (bx - ax) * (cy - by) - (by - ay) * (cx - bx);
      if (turn <= 0) return false;
    }
    var twiceArea = 0.0;
    for (var i = 0; i < 4; i++) {
      final (ax, ay) = p[i];
      final (bx, by) = p[(i + 1) % 4];
      twiceArea += ax * by - bx * ay;
    }
    return twiceArea / 2 >= minArea * width * height;
  }

  /// The corners in pixels of a [width] × [height] photo, clockwise from the
  /// top left; the last pixel is at `width - 1`, as a sampler counts.
  List<(double, double)> inPixels(int width, int height) =>
      _inPixels(width, height);

  List<(double, double)> _inPixels(int width, int height) => [
    for (final c in [topLeft, topRight, bottomRight, bottomLeft])
      (c.x * (width - 1), c.y * (height - 1)),
  ];

  /// The size of the straightened part of a [width] × [height] photo: the
  /// longer of each pair of opposite sides, so no detail is lost.
  PixelSize straightenedSize(int width, int height) {
    final [tl, tr, br, bl] = _inPixels(width, height);
    double d((double, double) a, (double, double) b) =>
        math.sqrt(math.pow(a.$1 - b.$1, 2) + math.pow(a.$2 - b.$2, 2));
    return PixelSize(
      math.max(1, math.max(d(tl, tr), d(bl, br)).round()),
      math.max(1, math.max(d(tl, bl), d(tr, br)).round()),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Corners &&
      other.topLeft == topLeft &&
      other.topRight == topRight &&
      other.bottomRight == bottomRight &&
      other.bottomLeft == bottomLeft;

  @override
  int get hashCode => Object.hash(topLeft, topRight, bottomRight, bottomLeft);
}

class PixelSize {
  const PixelSize(this.width, this.height);

  final int width;
  final int height;

  /// This size made smaller, keeping its shape, so its longest side is at
  /// most [maxSide]; never larger.
  PixelSize fitWithin(int maxSide) {
    final longest = math.max(width, height);
    if (longest <= maxSide) return this;
    final scale = maxSide / longest;
    return PixelSize(
      math.max(1, (width * scale).round()),
      math.max(1, (height * scale).round()),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PixelSize && other.width == width && other.height == height;

  @override
  int get hashCode => Object.hash(width, height);

  @override
  String toString() => '${width}x$height';
}
