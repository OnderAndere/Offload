import 'package:flutter_test/flutter_test.dart';
import 'package:offload/domain/ids/uuid_v7.dart';
import 'package:offload/domain/items/item.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/domain/items/revisit.dart';
import 'package:offload/domain/overview/standstill.dart';
import 'package:offload/domain/review/weekly_review.dart';
import 'package:offload/domain/time/local_date.dart';
import 'package:offload/domain/tokens/token_processing.dart';
import 'package:offload/domain/triage/triage.dart';

/// "Revisit on" in the domain (T4.2, REQ-021, DD-005, DD-018 point 17).
void main() {
  // Friday 9 October 2026.
  final today = LocalDate(2026, 10, 9);
  var clock = DateTime.utc(2026, 8, 1).millisecondsSinceEpoch;
  final ids = UuidV7Generator(now: () => clock++);

  Item item(
    String text, {
    ItemStatus status = ItemStatus.scheduled,
    LocalDate? revisit,
  }) => Item(
    id: ids.next(),
    rawText: text,
    status: status,
    source: ItemSource.app,
    revisitAt: revisit == null ? null : dateOnlyToStored(revisit),
  );

  group('the quick choices', () {
    test('tomorrow, next Monday and the same day next month', () {
      final c = revisitChoices(today);
      expect(c.tomorrow, LocalDate(2026, 10, 10));
      expect(c.nextWeek, LocalDate(2026, 10, 12));
      expect(c.inAMonth, LocalDate(2026, 11, 9));
    });

    test('on a Monday next week is the Monday after; on a Sunday the '
        'Sunday after', () {
      expect(
        revisitChoices(LocalDate(2026, 10, 12)).nextWeek,
        LocalDate(2026, 10, 19),
      );
      // Sunday 11 October: not tomorrow, the Sunday a week later.
      expect(
        revisitChoices(LocalDate(2026, 10, 11)).nextWeek,
        LocalDate(2026, 10, 18),
      );
      // Saturday: still the Monday after.
      expect(
        revisitChoices(LocalDate(2026, 10, 10)).nextWeek,
        LocalDate(2026, 10, 12),
      );
    });

    test('in a month falls back to the last day of a shorter month', () {
      expect(
        revisitChoices(LocalDate(2027, 1, 31)).inAMonth,
        LocalDate(2027, 2, 28),
      );
      expect(
        revisitChoices(LocalDate(2028, 1, 30)).inAMonth,
        LocalDate(2028, 2, 29),
      );
      expect(
        revisitChoices(LocalDate(2026, 12, 15)).inAMonth,
        LocalDate(2027, 1, 15),
      );
      expect(
        revisitChoices(LocalDate(2026, 10, 31)).inAMonth,
        LocalDate(2026, 11, 30),
      );
    });

    test('the date picker starts tomorrow', () {
      expect(firstRevisitDay(today), LocalDate(2026, 10, 10));
    });
  });

  group('parked and returning', () {
    test('parked: scheduled with a date after today', () {
      expect(isParked(item('a', revisit: today.addDays(1)), today), isTrue);
      expect(isParked(item('b', revisit: today), today), isFalse);
      expect(isParked(item('c'), today), isFalse);
      expect(
        isParked(
          item('d', status: ItemStatus.active, revisit: today.addDays(3)),
          today,
        ),
        isFalse,
      );
    });

    test('returns: scheduled with a date of today or earlier', () {
      expect(returnsBy(item('a', revisit: today), today), isTrue);
      expect(returnsBy(item('b', revisit: today.addDays(-4)), today), isTrue);
      expect(returnsBy(item('c', revisit: today.addDays(1)), today), isFalse);
      // Scheduled without a date (before T4.2) never returns by itself.
      expect(returnsBy(item('d'), today), isFalse);
      // A returned item that was processed does not return twice.
      expect(
        returnsBy(
          item('e', status: ItemStatus.active, revisit: today.addDays(-2)),
          today,
        ),
        isFalse,
      );
    });

    test('back in the inbox: inbox items whose date came, earliest first', () {
      final late = item('late', status: ItemStatus.inbox, revisit: today);
      final early = item(
        'early',
        status: ItemStatus.inbox,
        revisit: today.addDays(-3),
      );
      final back = backInInbox([
        late,
        item('new capture', status: ItemStatus.inbox),
        item('still parked', revisit: today.addDays(2)),
        item('processed', status: ItemStatus.active, revisit: today),
        early,
      ], today);
      expect([for (final i in back) i.rawText], ['early', 'late']);
    });
  });

  test('triage keeps the date of a returned item', () {
    final back = item('a', status: ItemStatus.inbox, revisit: today);
    expect(
      sortInto(back, TriageDestination.task).revisitAt,
      dateOnlyToStored(today),
    );
    expect(
      sortInto(back, TriageDestination.waitingFor).revisitAt,
      back.revisitAt,
    );
  });

  test('a parked item is neither stale nor standing still', () {
    final now = DateTime(2026, 10, 9, 12);
    final parked = item('parked', revisit: today.addDays(5));
    final returning = item('returning', revisit: today);
    final stale = staleItems([parked, returning], now, 3);
    // Neither has a known touch, so both would be stale; only the parked
    // one stays out.
    expect([for (final i in stale) i.rawText], ['returning']);
    final still = standstillOf([parked, returning], projects: [], now: now);
    expect([for (final s in still.items) s.item.rawText], ['returning']);
  });
}
