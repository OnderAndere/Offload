import 'dart:math' as math;

/// A rectangle of a treemap, in the units of the area it was laid out in.
typedef TreemapRect = ({double x, double y, double width, double height});

/// Lays out [values] as rectangles that fill [width] × [height], each with
/// an area in proportion to its value: the squarified treemap of Bruls,
/// Huizing and Van Wijk (2000), which keeps the rectangles close to
/// squares (DD-017: the Standstill). The values must be positive and are
/// laid out in the order given, so pass them largest first. The result has
/// the same order. Empty when there is nothing to lay out.
List<TreemapRect> squarify(List<num> values, double width, double height) {
  if (values.isEmpty || width <= 0 || height <= 0) return const [];
  assert(values.every((v) => v > 0), 'values must be positive');
  final total = values.fold<double>(0, (sum, v) => sum + v);
  final scale = width * height / total;
  final areas = [for (final v in values) v * scale];
  final result = List<TreemapRect?>.filled(areas.length, null);

  var x = 0.0, y = 0.0, w = width, h = height;
  var i = 0;
  while (i < areas.length) {
    final side = math.min(w, h);
    // The worst aspect ratio of a row with this sum, smallest and largest
    // area, laid along [side].
    double worst(double sum, double smallest, double largest) {
      final side2 = side * side;
      return math.max(
        side2 * largest / (sum * sum),
        sum * sum / (side2 * smallest),
      );
    }

    var end = i + 1;
    var sum = areas[i], smallest = areas[i], largest = areas[i];
    while (end < areas.length) {
      final area = areas[end];
      final nextSum = sum + area;
      final nextSmallest = math.min(smallest, area);
      final nextLargest = math.max(largest, area);
      if (worst(nextSum, nextSmallest, nextLargest) >
          worst(sum, smallest, largest)) {
        break;
      }
      sum = nextSum;
      smallest = nextSmallest;
      largest = nextLargest;
      end++;
    }

    // The row as a strip along the shorter side of what is left.
    if (w >= h) {
      final strip = sum / h;
      var at = y;
      for (var k = i; k < end; k++) {
        final part = areas[k] / strip;
        result[k] = (x: x, y: at, width: strip, height: part);
        at += part;
      }
      x += strip;
      w -= strip;
    } else {
      final strip = sum / w;
      var at = x;
      for (var k = i; k < end; k++) {
        final part = areas[k] / strip;
        result[k] = (x: at, y: y, width: part, height: strip);
        at += part;
      }
      y += strip;
      h -= strip;
    }
    i = end;
  }
  return [for (final rect in result) rect!];
}
