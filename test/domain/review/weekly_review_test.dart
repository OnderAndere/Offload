import 'package:flutter_test/flutter_test.dart';
import 'package:offload/domain/items/item.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/domain/repeats/repeat.dart';
import 'package:offload/domain/review/weekly_review.dart';
import 'package:offload/domain/time/local_date.dart';
import 'package:offload/domain/tokens/token_processing.dart';

/// The weekly review (T3.4 + T10.6, REQ-013, AC REQ-051, DD-018 point 8).
void main() {
  final now = DateTime.utc(2026, 10, 1, 12);
  final today = LocalDate(2026, 10, 1);
  var next = 0;
  Item item({
    ItemStatus status = ItemStatus.active,
    ItemType? type = ItemType.task,
    int changedDaysAgo = 0,
    int? reviewedDaysAgo,
    LocalDate? due,
    DateTime? revisitAt,
  }) => Item(
    id: 'i${(next++).toString().padLeft(3, '0')}',
    rawText: 'x',
    status: status,
    source: ItemSource.app,
    type: type,
    dueAt: due == null ? null : dateOnlyToStored(due),
    revisitAt: revisitAt,
    changedAt: now.subtract(Duration(days: changedDaysAgo)),
    reviewedAt: reviewedDaysAgo == null
        ? null
        : now.subtract(Duration(days: reviewedDaysAgo)),
  );

  test('StaleAfter: 3 by default, kept within 1 to 12', () {
    expect(StaleAfter.parse(null), 3);
    expect(StaleAfter.parse('x'), 3);
    expect(StaleAfter.parse('5'), 5);
    expect(StaleAfter.parse('0'), 1);
    expect(StaleAfter.parse('40'), 12);
  });

  test('the last touch is the later of the change and the review', () {
    expect(
      item(changedDaysAgo: 30, reviewedDaysAgo: 2).lastTouch,
      now.subtract(const Duration(days: 2)),
    );
    expect(
      item(changedDaysAgo: 3, reviewedDaysAgo: 20).lastTouch,
      now.subtract(const Duration(days: 3)),
    );
    expect(
      item(changedDaysAgo: 4).lastTouch,
      now.subtract(const Duration(days: 4)),
    );
  });

  group('staleItems', () {
    test('open items untouched X weeks or longer, oldest first', () {
      final old = item(changedDaysAgo: 50);
      final older = item(changedDaysAgo: 60);
      final edge = item(changedDaysAgo: 21);
      final recent = item(changedDaysAgo: 20);
      final note = item(type: ItemType.note, changedDaysAgo: 30);
      final waiting = item(status: ItemStatus.waiting, changedDaysAgo: 30);
      final done = item(status: ItemStatus.done, changedDaysAgo: 90);
      final archived = item(status: ItemStatus.archived, changedDaysAgo: 90);
      expect(
        staleItems(
          [old, older, edge, recent, note, waiting, done, archived],
          now,
          3,
        ),
        [older, old, note, waiting, edge],
      );
    });

    test('an unknown last touch counts as oldest', () {
      final unknown = Item(
        id: 'u',
        rawText: 'x',
        status: ItemStatus.active,
        source: ItemSource.app,
      );
      final old = item(changedDaysAgo: 90);
      expect(staleItems([old, unknown], now, 3), [unknown, old]);
    });

    test('a repeating task is never stale; an idea with the word is', () {
      final run = item(changedDaysAgo: 60);
      final untyped = item(type: null, changedDaysAgo: 60);
      final idea = item(type: ItemType.idea, changedDaysAgo: 60);
      final plain = item(changedDaysAgo: 60);
      final weekly = ItemRepeat(Rhythm.weekly, LocalDate(2026, 8, 4));
      expect(
        staleItems(
          [run, untyped, idea, plain],
          now,
          3,
          repeats: {run.id: weekly, untyped.id: weekly, idea.id: weekly},
        ),
        [idea, plain],
      );
    });

    test('a recent keep makes it fresh again', () {
      final kept = item(changedDaysAgo: 60, reviewedDaysAgo: 5);
      expect(staleItems([kept], now, 3), isEmpty);
      expect(staleItems([kept], now.add(const Duration(days: 17)), 3), [kept]);
    });

    test('a parked item does not count; a returned one and a leftover '
        'date do', () {
      final later = item(
        status: ItemStatus.scheduled,
        changedDaysAgo: 60,
        revisitAt: now.add(const Duration(days: 3)),
      );
      final past = item(
        status: ItemStatus.inbox,
        changedDaysAgo: 60,
        revisitAt: now.subtract(const Duration(days: 3)),
      );
      // Only a scheduled item is parked (DD-005).
      final notParked = item(
        changedDaysAgo: 60,
        revisitAt: now.add(const Duration(days: 3)),
      );
      expect(staleItems([later, past, notParked], now, 3), [past, notParked]);
    });
  });

  test('waitingForReview: waiting items, longest untouched first', () {
    final a = item(status: ItemStatus.waiting, changedDaysAgo: 2);
    final b = item(status: ItemStatus.waiting, changedDaysAgo: 9);
    final c = item(changedDaysAgo: 30);
    expect(waitingForReview([a, b, c]), [b, a]);
  });

  test('deadlinesForReview: overdue, then today up to 14 days ahead', () {
    final late = item(due: today.addDays(-2));
    final todays = item(due: today);
    final edge = item(due: today.addDays(14));
    final beyond = item(due: today.addDays(15));
    final doneLate = item(status: ItemStatus.done, due: today.addDays(-1));
    final archivedSoon = item(status: ItemStatus.archived, due: today);
    final none = item();
    final result = deadlinesForReview([
      edge,
      beyond,
      todays,
      late,
      doneLate,
      archivedSoon,
      none,
    ], today);
    expect(result.overdue, [late]);
    expect(result.upcoming, [todays, edge]);
  });

  group('when a review is due (DD-018 point 8)', () {
    final friday = LocalDate(2026, 10, 2);
    DateTime at(int day, int hour) => DateTime(2026, 9, day, hour);

    test('ReviewDueAfter: 7 by default, only the offered choices', () {
      expect(ReviewDueAfter.parse(null), 7);
      expect(ReviewDueAfter.parse('x'), 7);
      expect(ReviewDueAfter.parse('6'), 7);
      expect(ReviewDueAfter.parse('14'), 14);
      expect(ReviewDueAfter.choices, contains(ReviewDueAfter.standard));
    });

    test('never reviewed: due, with no age', () {
      expect(daysSinceReview(null, friday), isNull);
      expect(reviewDue(null, friday, 7), isTrue);
    });

    test('counts calendar days, not hours', () {
      // Late on 25 September is still 7 days before 2 October.
      expect(daysSinceReview(at(25, 23), friday), 7);
      expect(reviewDue(at(25, 23), friday, 7), isTrue);
      expect(reviewDue(at(26, 0), friday, 7), isFalse);
      expect(reviewDue(at(26, 0), friday, 5), isTrue);
    });

    test('a review dated after today counts as today', () {
      final later = DateTime(2026, 10, 5, 9);
      expect(daysSinceReview(later, friday), 0);
      expect(reviewDue(later, friday, 3), isFalse);
    });
  });
}
