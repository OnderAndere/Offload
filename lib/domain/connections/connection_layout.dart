import 'dart:math' as math;

/// A rectangle on the canvas of Connections, in logical pixels.
class Box {
  const Box(this.left, this.top, this.width, this.height);

  /// The box of [width] by [height] around ([x], [y]).
  Box.around(double x, double y, this.width, this.height)
    : left = x - width / 2,
      top = y - height / 2;

  final double left;
  final double top;
  final double width;
  final double height;

  double get right => left + width;
  double get bottom => top + height;

  /// Whether the two overlap, or come closer than [gap].
  bool overlaps(Box other, {double gap = 0}) =>
      left < other.right + gap &&
      other.left < right + gap &&
      top < other.bottom + gap &&
      other.top < bottom + gap;

  /// The area the two share.
  double overlapArea(Box other) {
    final w = math.min(right, other.right) - math.max(left, other.left);
    final h = math.min(bottom, other.bottom) - math.max(top, other.top);
    return w > 0 && h > 0 ? w * h : 0;
  }

  Box union(Box other) {
    final l = math.min(left, other.left), t = math.min(top, other.top);
    return Box(
      l,
      t,
      math.max(right, other.right) - l,
      math.max(bottom, other.bottom) - t,
    );
  }

  @override
  String toString() =>
      'Box(${left.toStringAsFixed(1)}, ${top.toStringAsFixed(1)}, '
      '${width.toStringAsFixed(1)} x ${height.toStringAsFixed(1)})';
}

/// The sizes the layout works with; the screen gives them, scaled with the
/// text size.
class LayoutMetrics {
  const LayoutMetrics({
    required this.width,
    required this.height,
    required this.labelWidth,
    required this.focusWidth,
    required this.focusHeight,
    this.nodeSize = 28,
    this.farNodeSize = 22,
    double? farLabelWidth,
    this.captionHeight = 13,
    this.lineHeight = 16,
    this.moreWidth = 64,
    this.gap = 3,
    this.margin = 4,
    this.spacing = 2,
  }) : farLabelWidth = farLabelWidth ?? labelWidth * 0.85;

  /// The canvas.
  final double width;
  final double height;

  /// The width of a label under a direct node (type line and title).
  final double labelWidth;

  /// The focus in the middle.
  final double focusWidth;
  final double focusHeight;

  /// A direct node's shape, square.
  final double nodeSize;

  /// A second-step node and its label: smaller, as they are dimmed.
  final double farNodeSize;
  final double farLabelWidth;

  /// The type line of a label, and one line of its title.
  final double captionHeight;
  final double lineHeight;

  /// The "+n meer" node, as high as [nodeSize].
  final double moreWidth;

  /// Between a node and its label.
  final double gap;

  /// Kept free along the edge of the canvas.
  final double margin;

  /// Kept free between two boxes.
  final double spacing;

  /// How far the label of a direct node reaches below its centre.
  double below(int lines) =>
      nodeSize / 2 + gap + captionHeight + lines * lineHeight;
}

/// Where one node goes: its centre, its shape, its label and how many lines
/// of title the label has room for (0 for "+n meer").
class Placement {
  const Placement({
    required this.x,
    required this.y,
    required this.node,
    required this.label,
    required this.lines,
  });

  final double x;
  final double y;
  final Box node;

  /// Null for "+n meer", which has no label.
  final Box? label;
  final int lines;

  /// The node and its label together.
  Box get bounds => label == null ? node : node.union(label!);
}

/// The layout of a graph: the focus in the middle, the direct nodes around
/// it, and per direct node its second-step nodes.
class ConnectionLayout {
  const ConnectionLayout({
    required this.height,
    required this.focus,
    required this.direct,
    required this.second,
  });

  /// The height of the canvas the layout needs: [LayoutMetrics.height], or
  /// more when the nodes did not fit there.
  final double height;

  final Box focus;
  final List<Placement> direct;

  /// In the order of [direct]: the second-step nodes of each.
  final List<List<Placement>> second;

  /// Every box drawn: the focus, the nodes and their labels.
  Iterable<Box> get boxes sync* {
    yield focus;
    for (final p in [...direct, for (final s in second) ...s]) {
      yield p.bounds;
    }
  }
}

/// A fixed radial layout (DD-017, DD-018 point 15), no force-directed
/// layout. [seconds] has one entry per direct node: how many second-step
/// nodes it has (all 0 on one step). [twoSteps] puts the direct nodes on
/// the inner ring, leaving the outer one to the second step. With [more]
/// the last direct node is "+n meer". Every direct node gets a sector in
/// proportion to what hangs behind it, its second-step nodes on the outer
/// ring inside that sector; with more than eight direct nodes on one step
/// they alternate between two radii. Each node tries a few positions in its
/// sector, nearest to the ideal first, and takes the first where it
/// overlaps nothing, otherwise the one with the least overlap; a label goes
/// to one line when two do not fit. Titles on the second step have one line.
///
/// When the nodes do not all fit on [LayoutMetrics.height], the canvas
/// grows in steps of a tenth, up to [maxHeight] (by default twice the
/// height); the screen zooms. If they still do not fit, the layout at that
/// height is used. A canvas without height (a window made very small) is
/// laid out once, as it is.
ConnectionLayout layoutConnections(
  List<int> seconds,
  LayoutMetrics m, {
  required bool twoSteps,
  bool more = false,
  double? maxHeight,
}) {
  // Only a real height grows: none, or an unbounded one (a parent that
  // gives no limit), is laid out once.
  if (!m.height.isFinite || m.height <= 0) {
    return _attempt(seconds, m, m.height, twoSteps, more, firstAtTop: true).$1;
  }
  final step = m.height / 10;
  final limit = maxHeight != null && maxHeight.isFinite
      ? maxHeight
      : m.height * 2;
  var height = m.height;
  // At most twenty tries, whatever the limit.
  for (var tries = 1; ; tries++, height += step) {
    // The first node at the top when that fits, otherwise the sectors
    // turned by half of the first.
    final (layout, clean) = _attempt(
      seconds,
      m,
      height,
      twoSteps,
      more,
      firstAtTop: true,
    );
    if (clean) return layout;
    final (turned, turnedClean) = _attempt(
      seconds,
      m,
      height,
      twoSteps,
      more,
      firstAtTop: false,
    );
    if (turnedClean) return turned;
    if (tries >= 20 || height + step > limit + 0.01) return layout;
  }
}

(ConnectionLayout, bool) _attempt(
  List<int> seconds,
  LayoutMetrics m,
  double height,
  bool twoSteps,
  bool more, {
  required bool firstAtTop,
}) {
  var clean = true;
  final n = seconds.length;
  // The centre sits so the rings have as much room above as below: a label
  // hangs below its node.
  final top = m.margin + m.nodeSize / 2;
  final bottom = height - m.margin - m.below(2);
  final cx = m.width / 2;
  final cy = (top + bottom) / 2;
  final rx = math.max(0.0, cx - m.margin - m.labelWidth / 2);
  final ry = math.max(0.0, (bottom - top) / 2);
  final focus = Box.around(cx, cy, m.focusWidth, m.focusHeight);
  final placed = <Box>[focus];

  bool fits(Box b) =>
      b.left >= m.margin - 0.01 &&
      b.top >= m.margin - 0.01 &&
      b.right <= m.width - m.margin + 0.01 &&
      b.bottom <= height - m.margin + 0.01 &&
      !placed.any((p) => p.overlaps(b, gap: m.spacing));

  double overlap(Box b) {
    var sum = 0.0;
    for (final p in placed) {
      sum += p.overlapArea(b);
    }
    return sum;
  }

  // A rounded rectangle rather than an ellipse (a superellipse), so the
  // corners of the canvas are used too.
  (double, double) point(double angle, double radius) {
    final c = math.cos(angle), s = math.sin(angle);
    double bend(double v) => v.sign * math.pow(v.abs(), 2 / 3).toDouble();
    return (cx + rx * radius * bend(c), cy + ry * radius * bend(s));
  }

  Placement at(
    double angle,
    double radius,
    int lines, {
    bool isMore = false,
    bool far = false,
  }) {
    final (x, y) = point(angle, radius);
    final size = far ? m.farNodeSize : m.nodeSize;
    final labelWidth = far ? m.farLabelWidth : m.labelWidth;
    final node = Box.around(x, y, isMore ? m.moreWidth : size, size);
    final label = isMore
        ? null
        : Box(
            x - labelWidth / 2,
            y + size / 2 + m.gap,
            labelWidth,
            m.captionHeight + lines * m.lineHeight,
          );
    return Placement(x: x, y: y, node: node, label: label, lines: lines);
  }

  /// The first candidate that fits, with the most lines; otherwise the one
  /// with the least overlap on the fewest lines.
  Placement choose(
    List<(double, double)> candidates,
    List<int> lineChoices, {
    bool isMore = false,
    bool far = false,
  }) {
    for (final lines in lineChoices) {
      for (final (angle, radius) in candidates) {
        final p = at(angle, radius, lines, isMore: isMore, far: far);
        if (fits(p.bounds)) return p;
      }
    }
    clean = false;
    Placement? best;
    var least = double.infinity;
    for (final (angle, radius) in candidates) {
      final p = at(angle, radius, lineChoices.last, isMore: isMore, far: far);
      final o = overlap(p.bounds);
      if (o < least) {
        least = o;
        best = p;
      }
    }
    return best!;
  }

  /// [values] sorted by how near they are to [ideal].
  List<double> nearest(Iterable<double> values, double ideal) =>
      values.toList()
        ..sort((a, b) => (a - ideal).abs().compareTo((b - ideal).abs()));

  // Sectors: in proportion to what hangs behind each node.
  final weights = [for (final k in seconds) twoSteps ? math.max(1, k) : 1];
  final total = math.max(1, weights.fold<int>(0, (a, b) => a + b));
  final starts = <double>[];
  final spans = <double>[];
  var acc = 0;
  // The first node at the top: its sector is centred there.
  final first = weights.isEmpty || !firstAtTop
      ? 0
      : weights.first / total * math.pi;
  for (final w in weights) {
    starts.add(-math.pi / 2 - first + acc / total * 2 * math.pi);
    spans.add(w / total * 2 * math.pi);
    acc += w;
  }

  const offsets = [
    0.0,
    0.15,
    -0.15,
    0.3,
    -0.3,
    0.45,
    -0.45,
    0.6,
    -0.6,
    0.75,
    -0.75,
  ];
  final stagger = !twoSteps && n > 8;
  final direct = <Placement>[];
  for (var i = 0; i < n; i++) {
    final ideal = twoSteps
        ? 0.55
        : stagger
        ? (i.isOdd ? 1.0 : 0.6)
        // A few nodes stay close to the focus.
        : n <= 4
        ? 0.75
        : 1.0;
    final radii = nearest([
      for (var r = 0.3; r <= (twoSteps ? 0.8 : 1.0) + 1e-9; r += 0.05) r,
    ], ideal);
    final centre = starts[i] + spans[i] / 2;
    final candidates = [
      for (final r in radii)
        for (final o in offsets) (centre + o * spans[i] / 2, r),
    ];
    final isMore = more && i == n - 1;
    final p = choose(
      candidates,
      isMore ? const [0] : const [2, 1],
      isMore: isMore,
    );
    direct.add(p);
    placed.add(p.bounds);
  }

  final second = <List<Placement>>[];
  for (var i = 0; i < n; i++) {
    final k = seconds[i];
    final row = <Placement>[];
    for (var j = 0; j < k; j++) {
      final slot = spans[i] / k;
      final centre = starts[i] + (j + 0.5) * slot;
      // Within the node's own part of the sector first, then anywhere in
      // the sector.
      final candidates = [
        for (final r in [for (var r = 1.0; r >= 0.6 - 1e-9; r -= 0.05) r])
          for (final o in offsets) (centre + o * slot / 2, r),
        for (final r in [for (var r = 1.0; r >= 0.6 - 1e-9; r -= 0.05) r])
          for (final o in offsets)
            (starts[i] + spans[i] / 2 + o * spans[i] / 2, r),
      ];
      final p = choose(candidates, const [1], far: true);
      row.add(p);
      placed.add(p.bounds);
    }
    second.add(row);
  }
  return (
    ConnectionLayout(
      height: height,
      focus: focus,
      direct: direct,
      second: second,
    ),
    clean,
  );
}
