import 'package:flutter_test/flutter_test.dart';
import 'package:offload/domain/ids/uuid_v7.dart';
import 'package:offload/domain/items/item.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/domain/reminders/day_reminders.dart';
import 'package:offload/domain/repeats/repeat.dart';
import 'package:offload/domain/time/local_date.dart';
import 'package:offload/domain/tokens/token_processing.dart';

/// Planning the day's reminders: deadlines (T4.1, REQ-020) and items
/// back from "revisit on" (T4.2, REQ-021); DD-005, DD-018 points 16 and 17.
void main() {
  var n = 0;

  /// An item due on [due] (a date: midnight UTC, DD-004 point 8), parked
  /// until [revisit] when given.
  Item item(
    LocalDate? due, {
    ItemStatus status = ItemStatus.active,
    LocalDate? revisit,
    ItemType? type = ItemType.task,
  }) {
    final at = DateTime.utc(2026, 9, 1).add(Duration(minutes: n++));
    return Item(
      id: UuidV7Generator(now: () => at.millisecondsSinceEpoch).next(),
      rawText: 'item $n',
      status: status,
      source: ItemSource.app,
      type: type,
      dueAt: due == null ? null : DateTime.utc(due.year, due.month, due.day),
      revisitAt: revisit == null ? null : dateOnlyToStored(revisit),
    );
  }

  final friday = LocalDate(2026, 10, 9);
  final morning = DateTime(2026, 10, 9, 7, 30);

  List<ReminderDay> plan(
    List<Item> items, {
    DateTime? now,
    int minute = 540,
    Map<String, ItemRepeat> repeats = const {},
  }) => planDayReminders(
    items,
    now: now ?? morning,
    minuteOfDay: minute,
    repeats: repeats,
  );

  group('ReminderTime', () {
    test('09:00 unless a valid time is stored', () {
      expect(ReminderTime.parse(null), 540);
      expect(ReminderTime.parse('x'), 540);
      expect(ReminderTime.parse('-1'), 540);
      expect(ReminderTime.parse('1440'), 540);
      expect(ReminderTime.parse('0'), 0);
      expect(ReminderTime.parse('1439'), 1439);
      expect(ReminderTime.parse('450'), 450);
    });
  });

  group('repeating tasks (T4.7, DD-005)', () {
    final daily = ItemRepeat(Rhythm.daily, LocalDate(2026, 10, 1));

    test('every series date in the plan has a line, also while overdue', () {
      // Due on 6 October, not done: still reminded on 9, 10, 11 … October.
      final run = item(LocalDate(2026, 10, 6), type: null);
      final days = plan([run], repeats: {run.id: daily});
      expect(days.first.day, friday);
      expect(days.length, reminderDaysAhead + 1);
      expect(days.every((d) => d.deadlineIds.single == run.id), isTrue);
    });

    test('weekly: only its weekday', () {
      final weekly = ItemRepeat(Rhythm.weekly, LocalDate(2026, 10, 6));
      final run = item(LocalDate(2026, 10, 13));
      final days = plan([run], repeats: {run.id: weekly});
      expect(days.map((d) => d.day), [
        LocalDate(2026, 10, 13),
        LocalDate(2026, 10, 20),
        LocalDate(2026, 10, 27),
        LocalDate(2026, 11, 3),
      ]);
    });

    test('an idea with the word, or a done task, gets no series', () {
      final idea = item(LocalDate(2026, 10, 6), type: ItemType.idea);
      final done = item(friday, status: ItemStatus.done);
      expect(
        plan([idea, done], repeats: {idea.id: daily, done.id: daily}),
        isEmpty,
      );
    });
  });

  test('one reminder per day, at the time set, items in capture order', () {
    final a = item(friday);
    final b = item(friday.addDays(3));
    final c = item(friday);
    final days = plan([b, c, a]);
    expect(days.map((d) => d.day), [friday, friday.addDays(3)]);
    expect(days.first.at, DateTime(2026, 10, 9, 9));
    expect(days.first.itemIds, [a.id, c.id]);
    expect(days.last.itemIds, [b.id]);
    expect(days.first.id, 20261009);
  });

  test('only open items with a deadline', () {
    final days = plan([
      item(null),
      item(friday, status: ItemStatus.done),
      item(friday, status: ItemStatus.archived),
      item(friday, status: ItemStatus.inbox),
      item(friday, status: ItemStatus.waiting),
    ]);
    expect(days.single.itemIds, hasLength(2));
  });

  test('a day whose time has passed gets none; overdue is never reminded', () {
    final late = DateTime(2026, 10, 9, 10);
    expect(plan([item(friday)], now: late), isEmpty);
    expect(plan([item(friday.addDays(-2))]), isEmpty);
    // Exactly at the time is passed too.
    expect(plan([item(friday)], now: DateTime(2026, 10, 9, 9)), isEmpty);
  });

  test('a month ahead, no further', () {
    final days = plan([
      item(friday.addDays(reminderDaysAhead)),
      item(friday.addDays(reminderDaysAhead + 1)),
    ]);
    expect(days.single.day, friday.addDays(reminderDaysAhead));
  });

  test('the deadline day is its UTC date, wherever the device is', () {
    // Stored as midnight UTC of 9 October: still the 9th, also where local
    // time is behind UTC (DateTime.utc keeps the calendar date).
    final days = plan(
      [item(friday)],
      minute: 0,
      now: DateTime(2026, 10, 8, 23),
    );
    expect(days.single.day, friday);
    expect(days.single.at, DateTime(2026, 10, 9));
  });

  test('the time set: early and late in the day', () {
    expect(
      plan([item(friday)], minute: 23 * 60 + 59).single.at,
      DateTime(2026, 10, 9, 23, 59),
    );
    expect(
      plan([item(friday.addDays(1))], minute: 0).single.at,
      DateTime(2026, 10, 10),
    );
  });

  group('revisit on', () {
    Item parked(LocalDate day, {ItemStatus status = ItemStatus.scheduled}) =>
        item(null, status: status, revisit: day);

    test('a parked item is reminded on its day, after the deadlines', () {
      final due = item(friday.addDays(3));
      final back = parked(friday.addDays(3));
      final alone = parked(friday.addDays(5));
      final days = plan([back, alone, due]);
      expect(days.map((d) => d.day), [friday.addDays(3), friday.addDays(5)]);
      expect(days.first.deadlineIds, [due.id]);
      expect(days.first.returningIds, [back.id]);
      expect(days.first.itemIds, [due.id, back.id]);
      expect(days.last.deadlineIds, isEmpty);
      expect(days.last.returningIds, [alone.id]);
      expect(days.last.id, 20261014);
    });

    test('today: also one already back in the inbox before the time', () {
      final back = parked(friday, status: ItemStatus.inbox);
      final processed = parked(friday, status: ItemStatus.active);
      final stillParked = parked(friday);
      final days = plan([back, processed, stillParked]);
      expect(
        days.single.returningIds..sort(),
        [back.id, stillParked.id]..sort(),
      );
      // An inbox item with an old date is not reminded again.
      expect(
        plan([parked(friday.addDays(-1), status: ItemStatus.inbox)]),
        isEmpty,
      );
    });

    test('an item due and returning the same day is a deadline only', () {
      final both = item(
        friday.addDays(2),
        revisit: friday.addDays(2),
        status: ItemStatus.scheduled,
      );
      final day = plan([both]).single;
      expect(day.deadlineIds, [both.id]);
      expect(day.returningIds, isEmpty);
    });

    test('a passed time, the past and beyond the plan get none', () {
      expect(plan([parked(friday)], now: DateTime(2026, 10, 9, 10)), isEmpty);
      expect(plan([parked(friday.addDays(-3))]), isEmpty);
      expect(plan([parked(friday.addDays(reminderDaysAhead + 1))]), isEmpty);
      // Scheduled without a date never returns, so never reminds.
      expect(plan([item(null, status: ItemStatus.scheduled)]), isEmpty);
    });
  });
}
