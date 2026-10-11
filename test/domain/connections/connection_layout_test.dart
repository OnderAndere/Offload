import 'package:flutter_test/flutter_test.dart';
import 'package:offload/domain/connections/connection_layout.dart';

/// The radial layout of Connections (T10.14, REQ-059, DD-018 point 15):
/// labels never overlap and everything stays on the canvas.
void main() {
  const sizes = {
    'phone': LayoutMetrics(
      width: 358,
      height: 440,
      labelWidth: 84,
      focusWidth: 120,
      focusHeight: 40,
      captionHeight: 12,
      lineHeight: 15,
    ),
    'small phone': LayoutMetrics(
      width: 296,
      height: 400,
      labelWidth: 76,
      focusWidth: 104,
      focusHeight: 40,
      captionHeight: 12,
      lineHeight: 15,
    ),
    'Windows pane': LayoutMetrics(
      width: 434,
      height: 470,
      labelWidth: 100,
      focusWidth: 150,
      focusHeight: 40,
    ),
  };

  /// The heaviest cases the graph can ask for (DD-018 point 15): up to 12
  /// direct nodes on one step (the twelfth "+n meer"); on two steps up to 8
  /// direct nodes, at most 2 second-step nodes per node and 8 in all.
  final cases = <String, (List<int>, bool)>{
    for (var n = 1; n <= 12; n++) '$n direct': (List.filled(n, 0), false),
    '11 direct and more': (List.filled(12, 0), true),
    'two steps, sketch': ([2, 1, 0, 0, 1, 1], false),
    'two steps, 1 x 2': ([2], false),
    'two steps, 3 x 2': ([2, 2, 2], false),
    'two steps, 4 x 2': ([2, 2, 2, 2], false),
    'two steps, 4 x 2 and 4': ([2, 2, 2, 2, 0, 0, 0, 0], false),
    'two steps, 6 x 1': ([1, 1, 1, 1, 1, 1], false),
    'two steps, 8 x 1': ([1, 1, 1, 1, 1, 1, 1, 1], false),
    'two steps, 7 and more with 8': ([2, 1, 1, 1, 1, 1, 1, 0], true),
  };

  for (final MapEntry(key: size, value: m) in sizes.entries) {
    group(size, () {
      for (final MapEntry(key: name, value: (seconds, more)) in cases.entries) {
        test(name, () {
          final layout = layoutConnections(
            seconds,
            m,
            twoSteps: name.startsWith('two steps'),
            more: more,
          );
          expect(layout.direct, hasLength(seconds.length));
          for (var i = 0; i < seconds.length; i++) {
            expect(layout.second[i], hasLength(seconds[i]));
          }
          final boxes = layout.boxes.toList();
          expect(layout.height, lessThanOrEqualTo(m.height * 2));
          for (final b in boxes) {
            expect(b.left, greaterThanOrEqualTo(0), reason: '$b');
            expect(b.top, greaterThanOrEqualTo(0), reason: '$b');
            expect(b.right, lessThanOrEqualTo(m.width), reason: '$b');
            expect(b.bottom, lessThanOrEqualTo(layout.height), reason: '$b');
          }
          for (var i = 0; i < boxes.length; i++) {
            for (var j = i + 1; j < boxes.length; j++) {
              expect(
                boxes[i].overlaps(boxes[j]),
                isFalse,
                reason: '${boxes[i]} and ${boxes[j]}',
              );
            }
          }
        });
      }
    });
  }

  test('one step keeps two lines of title when there is room', () {
    final layout = layoutConnections(
      List.filled(6, 0),
      sizes['phone']!,
      twoSteps: false,
    );
    expect(layout.direct.map((p) => p.lines), everyElement(2));
  });

  test('second-step titles have one line', () {
    final layout = layoutConnections([2, 1], sizes['phone']!, twoSteps: true);
    expect(layout.second.expand((s) => s).map((p) => p.lines), everyElement(1));
  });

  test('second-step nodes lie further out, in the sector of their node', () {
    final m = sizes['phone']!;
    final layout = layoutConnections([2, 0, 0, 0], m, twoSteps: true);
    final cx = m.width / 2;
    final first = layout.direct.first;
    for (final s in layout.second.first) {
      final d = (s.x - cx).abs() + (s.y - layout.focus.top).abs();
      final dd = (first.x - cx).abs() + (first.y - layout.focus.top).abs();
      expect(d, greaterThan(dd));
    }
  });

  test('"+n meer" has no label', () {
    final layout = layoutConnections(
      List.filled(12, 0),
      sizes['phone']!,
      twoSteps: false,
      more: true,
    );
    expect(layout.direct.last.label, isNull);
    expect(layout.direct.last.lines, 0);
  });

  test('a graph without connections is only the focus', () {
    final layout = layoutConnections(
      const [],
      sizes['phone']!,
      twoSteps: false,
    );
    expect(layout.boxes, hasLength(1));
  });

  test('two steps keep the inner ring, also with nothing behind', () {
    final m = sizes['phone']!;
    final one = layoutConnections([0, 0, 0], m, twoSteps: false);
    final two = layoutConnections([0, 0, 0], m, twoSteps: true);
    double reach(ConnectionLayout l) {
      final cy = l.focus.top + l.focus.height / 2;
      return l.direct
          .map((p) => (p.y - cy).abs())
          .reduce((a, b) => a > b ? a : b);
    }

    expect(reach(two), lessThan(reach(one)));
  });

  test('a canvas without height ends, laid out once', () {
    for (final height in [0.0, -20.0, double.nan, double.infinity]) {
      final m = LayoutMetrics(
        width: 358,
        height: height,
        labelWidth: 84,
        focusWidth: 120,
        focusHeight: 40,
      );
      expect(
        layoutConnections([0, 0, 0], m, twoSteps: false).direct,
        hasLength(3),
      );
      expect(
        layoutConnections([2, 1], m, twoSteps: true).second.expand((s) => s),
        hasLength(3),
      );
    }
  });

  test('an unbounded or missing limit still ends', () {
    // Far too many nodes for a tiny canvas: it never fits.
    const m = LayoutMetrics(
      width: 120,
      height: 80,
      labelWidth: 84,
      focusWidth: 100,
      focusHeight: 40,
    );
    for (final limit in [double.infinity, double.nan, 1e9]) {
      final layout = layoutConnections(
        List.filled(12, 0),
        m,
        twoSteps: false,
        maxHeight: limit,
      );
      expect(layout.direct, hasLength(12));
      expect(layout.height, lessThanOrEqualTo(m.height * 3));
    }
  });

  test('the first node is at the top when that fits', () {
    final m = sizes['phone']!;
    for (final n in [1, 3, 6]) {
      final layout = layoutConnections(List.filled(n, 0), m, twoSteps: false);
      final cy = layout.focus.top + layout.focus.height / 2;
      final first = layout.direct.first;
      expect(first.y, lessThan(cy), reason: '$n nodes');
      expect((first.x - m.width / 2).abs(), lessThan(1), reason: '$n nodes');
    }
  });

  test('up to four nodes stay closer to the focus than more', () {
    final m = sizes['Windows pane']!;
    double reach(int n) {
      final layout = layoutConnections(List.filled(n, 0), m, twoSteps: false);
      final cy = layout.focus.top + layout.focus.height / 2;
      return (layout.direct.first.y - cy).abs();
    }

    expect(reach(4), lessThan(reach(5)));
  });
}
