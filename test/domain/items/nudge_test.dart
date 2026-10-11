import 'package:flutter_test/flutter_test.dart';
import 'package:offload/domain/ids/uuid_v7.dart';
import 'package:offload/domain/items/item.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/domain/items/nudge.dart';
import 'package:offload/domain/reminders/nudge_reminders.dart';
import 'package:offload/domain/time/local_date.dart';

/// The nudge of waiting items that stay silent (T10.1, AC REQ-047, DD-005).
void main() {
  // Friday 9 October 2026.
  final today = LocalDate(2026, 10, 9);
  var n = 0;

  /// An item touched [touchedDaysAgo] days before today (its HLC moment).
  Item item({
    ItemStatus status = ItemStatus.waiting,
    int touchedDaysAgo = 0,
    LocalDate? expected,
    DateTime? reviewedAt,
  }) {
    final captured = DateTime.utc(2026, 8, 1).add(Duration(minutes: n++));
    return Item(
      id: UuidV7Generator(now: () => captured.millisecondsSinceEpoch).next(),
      rawText: 'item $n',
      status: status,
      source: ItemSource.app,
      changedAt: DateTime(
        2026,
        10,
        9,
        12,
      ).subtract(Duration(days: touchedDaysAgo)).toUtc(),
      reviewedAt: reviewedAt,
      expectedAt: expected,
    );
  }

  test('NudgeAfter: 7 unless a valid choice is stored', () {
    expect(NudgeAfter.parse(null), 7);
    expect(NudgeAfter.parse('4'), 7);
    expect(NudgeAfter.parse('14'), 14);
  });

  group('silent', () {
    test('waiting, no expected date, untouched for X days or longer', () {
      expect(silentDays(item(touchedDaysAgo: 7), today, 7), 7);
      expect(silentDays(item(touchedDaysAgo: 12), today, 7), 12);
      expect(silentDays(item(touchedDaysAgo: 6), today, 7), isNull);
    });

    test('an expected date or another status is never silent', () {
      expect(
        silentDays(
          item(touchedDaysAgo: 30, expected: today.addDays(-3)),
          today,
          7,
        ),
        isNull,
      );
      expect(
        silentDays(
          item(touchedDaysAgo: 30, status: ItemStatus.active),
          today,
          7,
        ),
        isNull,
      );
    });

    test('Chased (reviewed_at) is a touch: the period starts again', () {
      final chased = item(
        touchedDaysAgo: 20,
        reviewedAt: DateTime(2026, 10, 7, 10).toUtc(),
      );
      expect(silentDays(chased, today, 7), isNull);
      expect(silentFrom(chased, 7), LocalDate(2026, 10, 14));
    });

    test('the group: longest silent first', () {
      final a = item(touchedDaysAgo: 8);
      final b = item(touchedDaysAgo: 15);
      final c = item(touchedDaysAgo: 2);
      expect(silentItems([a, b, c], today, 7), [b, a]);
    });
  });

  group('the plan', () {
    final morning = DateTime(2026, 10, 9, 8);

    test('one notification on the day an item becomes silent', () {
      final today7 = item(touchedDaysAgo: 7);
      final in3 = item(touchedDaysAgo: 4);
      final days = planNudgeReminders(
        [today7, in3],
        now: morning,
        minuteOfDay: 540,
        afterDays: 7,
      );
      expect(days.map((d) => d.day), [today, today.addDays(3)]);
      expect(days.first.itemIds, [today7.id]);
      expect(days.first.at, DateTime(2026, 10, 9, 9));
      expect(days.first.id, 320261009);
    });

    test('silent before today, or today after the time: no repeat', () {
      expect(
        planNudgeReminders(
          [item(touchedDaysAgo: 12)],
          now: morning,
          minuteOfDay: 540,
          afterDays: 7,
        ),
        isEmpty,
      );
      expect(
        planNudgeReminders(
          [item(touchedDaysAgo: 7)],
          now: DateTime(2026, 10, 9, 10),
          minuteOfDay: 540,
          afterDays: 7,
        ),
        isEmpty,
      );
    });

    test('an item with an expected date gets no nudge', () {
      expect(
        planNudgeReminders(
          [item(touchedDaysAgo: 7, expected: today.addDays(5))],
          now: morning,
          minuteOfDay: 540,
          afterDays: 7,
        ),
        isEmpty,
      );
    });
  });
}
