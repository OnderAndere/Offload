import 'package:flutter_test/flutter_test.dart';
import 'package:offload/domain/ids/uuid_v7.dart';
import 'package:offload/domain/items/item.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/domain/overview/standstill.dart';
import 'package:offload/domain/overview/treemap.dart';
import 'package:offload/domain/projects/project.dart';

/// The Standstill of the Overview (T10.7 step C, REQ-052, DD-018 point 12
/// (c)) and its treemap layout (DD-017).
void main() {
  group('squarify', () {
    double area(TreemapRect r) => r.width * r.height;

    test('fills the area, in proportion, without overlap', () {
      const values = [6, 6, 4, 3, 2, 2, 1];
      final rects = squarify(values, 600, 400);
      expect(rects, hasLength(values.length));
      final total = rects.fold<double>(0, (s, r) => s + area(r));
      expect(total, closeTo(600 * 400, 1e-6));
      for (final (i, r) in rects.indexed) {
        expect(area(r), closeTo(600 * 400 * values[i] / 24, 1e-6));
        expect(r.x, greaterThanOrEqualTo(-1e-9));
        expect(r.y, greaterThanOrEqualTo(-1e-9));
        expect(r.x + r.width, lessThanOrEqualTo(600 + 1e-6));
        expect(r.y + r.height, lessThanOrEqualTo(400 + 1e-6));
      }
      for (var i = 0; i < rects.length; i++) {
        for (var j = i + 1; j < rects.length; j++) {
          final a = rects[i], b = rects[j];
          final overlapX =
              (a.x + a.width) - b.x > 1e-6 && (b.x + b.width) - a.x > 1e-6;
          final overlapY =
              (a.y + a.height) - b.y > 1e-6 && (b.y + b.height) - a.y > 1e-6;
          expect(overlapX && overlapY, isFalse, reason: '$i and $j overlap');
        }
      }
    });

    test('keeps the tiles close to squares', () {
      final rects = squarify([6, 6, 4, 3, 2, 2, 1], 600, 400);
      for (final r in rects) {
        final ratio = r.width > r.height
            ? r.width / r.height
            : r.height / r.width;
        expect(ratio, lessThan(3));
      }
    });

    test('one value fills everything; nothing gives nothing', () {
      expect(squarify([5], 300, 200).single, (
        x: 0.0,
        y: 0.0,
        width: 300.0,
        height: 200.0,
      ));
      expect(squarify([], 300, 200), isEmpty);
      expect(squarify([1], 0, 200), isEmpty);
    });
  });

  group('standstillOf', () {
    final now = DateTime.utc(2026, 10, 2, 12);
    var n = 0;

    /// An item captured [capturedDaysAgo] days ago, last changed
    /// [touchedDaysAgo] days ago.
    Item item({
      required int touchedDaysAgo,
      int? capturedDaysAgo,
      String? project,
      ItemStatus status = ItemStatus.active,
      ItemType type = ItemType.task,
      DateTime? revisitAt,
    }) {
      final captured = now.subtract(
        Duration(days: capturedDaysAgo ?? touchedDaysAgo, milliseconds: n++),
      );
      return Item(
        id: UuidV7Generator(now: () => captured.millisecondsSinceEpoch).next(),
        rawText: 'item $n',
        status: status,
        source: ItemSource.app,
        type: type,
        projectId: project,
        changedAt: now.subtract(Duration(days: touchedDaysAgo)),
        revisitAt: revisitAt,
      );
    }

    const house = Project(id: 'house', name: 'Verbouwing');
    const kitchen = Project(id: 'kitchen', name: 'Keuken', parentId: 'house');
    const club = Project(id: 'club', name: 'Vereniging');
    const projects = [club, kitchen, house];

    test('a tile per top-level project, most open first, aged by the '
        'most recent touch', () {
      final s = standstillOf(
        [
          item(touchedDaysAgo: 2, project: 'house'),
          item(touchedDaysAgo: 30, project: 'kitchen'),
          item(touchedDaysAgo: 50, project: 'house'),
          item(touchedDaysAgo: 28, project: 'club'),
          item(touchedDaysAgo: 45, project: 'club'),
          item(touchedDaysAgo: 1),
        ],
        projects: projects,
        now: now,
      );
      expect(
        [for (final t in s.tiles) (t.project, t.open, t.ageDays)],
        [('house', 3, 2), ('club', 2, 28), (null, 1, 1)],
      );
      expect(s.tiles[1].level, StandstillLevel.longer);
      expect([for (final o in s.oldest) o.ageDays], [50, 45, 30]);
      expect([for (final o in s.itemsOf('house')) o.ageDays], [50, 30, 2]);
    });

    test('only open items; a parked item ("revisit on" later) does not '
        'count', () {
      final s = standstillOf(
        [
          item(touchedDaysAgo: 9, status: ItemStatus.done),
          item(touchedDaysAgo: 9, status: ItemStatus.archived),
          item(touchedDaysAgo: 9, type: ItemType.note),
          item(
            touchedDaysAgo: 9,
            status: ItemStatus.scheduled,
            revisitAt: now.add(const Duration(days: 3)),
          ),
          item(touchedDaysAgo: 9, status: ItemStatus.inbox),
        ],
        projects: projects,
        now: now,
      );
      expect(s.tiles.single.open, 1);
      expect(s.items, hasLength(1));
    });

    test('the four classes: < 1 wk, 1–3 wk, 3–6 wk, 6 wk or more', () {
      expect(StandstillLevel.of(6), StandstillLevel.fresh);
      expect(StandstillLevel.of(7), StandstillLevel.weeks);
      expect(StandstillLevel.of(20), StandstillLevel.weeks);
      expect(StandstillLevel.of(21), StandstillLevel.longer);
      expect(StandstillLevel.of(41), StandstillLevel.longer);
      expect(StandstillLevel.of(42), StandstillLevel.longest);
    });
  });
}
