import 'package:flutter_test/flutter_test.dart';
import 'package:offload/domain/items/item.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/domain/overview/horizon.dart';
import 'package:offload/domain/projects/project.dart';
import 'package:offload/domain/time/local_date.dart';
import 'package:offload/domain/tokens/token_processing.dart';

/// The Horizon of the Overview (T10.7 step B, REQ-052, DD-018 point 12).
void main() {
  // Friday 2 October 2026, ISO week 40.
  final today = LocalDate(2026, 10, 2);
  var n = 0;

  Item item({
    LocalDate? due,
    LocalDate? expected,
    ItemStatus status = ItemStatus.active,
    ItemType type = ItemType.task,
    String? project,
  }) => Item(
    id: 'i${n++}'.padLeft(4, '0'),
    rawText: 'item $n',
    status: status,
    source: ItemSource.app,
    type: type,
    dueAt: due == null ? null : dateOnlyToStored(due),
    expectedAt: expected,
    projectId: project,
  );

  const house = Project(id: 'house', name: 'Verbouwing');
  const kitchen = Project(id: 'kitchen', name: 'Keuken', parentId: 'house');
  const garden = Project(id: 'garden', name: 'Tuin');
  const projects = [garden, kitchen, house];

  Horizon of(List<Item> items, {int busyFrom = 5}) =>
      horizonOf(items, today: today, projects: projects, busyFrom: busyFrom);

  test('ISO weeks and Mondays', () {
    expect(today.isoWeek, 40);
    expect(today.monday, LocalDate(2026, 9, 28));
    expect(LocalDate(2026, 1, 1).isoWeek, 1); // a Thursday
    expect(LocalDate(2027, 1, 1).isoWeek, 53); // Friday, week of 2026
    expect(LocalDate(2024, 12, 30).isoWeek, 1); // Monday of 2025's week 1
    expect(LocalDate(2026, 12, 28).isoWeek, 53);
  });

  test('six weeks from today: start, end and numbers', () {
    final h = of([]);
    expect(h.weeks, hasLength(6));
    expect(h.weeks.first.start, today);
    expect(h.weeks.first.end, LocalDate(2026, 10, 4));
    expect(h.weeks[1].start, LocalDate(2026, 10, 5));
    expect([for (final w in h.weeks) w.number], [40, 41, 42, 43, 44, 45]);
    expect(h.lanes, isEmpty);
  });

  test('marks: deliver, overdue, waiting and late; beyond is left out', () {
    final deliver = item(due: today.addDays(3));
    final overdue = item(due: today.addDays(-1));
    final waiting = item(
      status: ItemStatus.waiting,
      expected: today.addDays(10),
    );
    final late = item(status: ItemStatus.waiting, expected: today.addDays(-2));
    final beyond = item(due: today.addDays(60));
    final h = of([deliver, overdue, waiting, late, beyond]);

    final first = h.weeks.first.entries;
    expect(
      [for (final e in first) (e.item.id, e.mark)],
      [(late.id, HorizonMark.late), (overdue.id, HorizonMark.overdue)],
    );
    expect(h.weeks[1].entries.single.mark, HorizonMark.deliver);
    expect(h.weeks[2].entries.single.mark, HorizonMark.waiting);
    expect(h.itemCount, 4);
  });

  test('a waiting item: its deadline stays mine, its expected day a ring', () {
    final both = item(
      status: ItemStatus.waiting,
      due: today.addDays(4),
      expected: today.addDays(1),
    );
    final noDay = item(status: ItemStatus.waiting);
    final notWaiting = item(expected: today.addDays(1)); // waited before
    final h = of([both, noDay, notWaiting]);
    final entries = [for (final w in h.weeks) ...w.entries];
    expect(
      [for (final e in entries) e.mark],
      [HorizonMark.waiting, HorizonMark.deliver],
    );
    expect(h.itemCount, 1);
  });

  test('only open items: no done, archived or notes', () {
    final h = of([
      item(due: today, status: ItemStatus.done),
      item(due: today, status: ItemStatus.archived),
      item(due: today, type: ItemType.note),
    ]);
    expect(h.itemCount, 0);
  });

  test('busy counts what I deliver, overdue included, never waiting', () {
    final items = [
      for (var i = 0; i < 3; i++) item(due: today.addDays(1)),
      item(due: today.addDays(-5)),
      item(status: ItemStatus.waiting, expected: today.addDays(1)),
      item(status: ItemStatus.waiting, expected: today.addDays(-1)),
    ];
    final h = of(items, busyFrom: 4);
    expect(h.weeks.first.toDeliver, 4);
    expect(h.weeks.first.waiting, 2);
    expect(h.weeks.first.busy, isTrue);
    expect(of(items, busyFrom: 5).weeks.first.busy, isFalse);
  });

  test('lanes: top-level projects by the order given, no project last', () {
    final h = of([
      item(due: today, project: 'kitchen'),
      item(due: today),
      item(due: today, project: 'garden'),
      item(due: today, project: 'gone'),
    ]);
    expect(h.lanes, ['garden', 'house', null]);
    expect(h.weeks.first.inLane('house').single.item.projectId, 'kitchen');
    expect(h.weeks.first.inLane(null), hasLength(2));
  });

  test('BusyFrom: 3 to 15, 5 by default; the threshold itself is busy', () {
    expect(BusyFrom.parse('8'), 8);
    expect(BusyFrom.parse('2'), BusyFrom.standard);
    expect(BusyFrom.parse('16'), 5);
    expect(BusyFrom.parse(null), 5);
    expect(BusyFrom.isBusy(5, 5), isTrue);
    expect(BusyFrom.isBusy(4, 5), isFalse);
  });
}
