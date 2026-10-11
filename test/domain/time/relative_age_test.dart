import 'package:flutter_test/flutter_test.dart';
import 'package:offload/domain/time/local_date.dart';
import 'package:offload/domain/time/relative_age.dart';

/// The relative time of an inbox row (DD-018 point 2).
void main() {
  final now = DateTime(2026, 9, 28, 14, 30);
  RelativeAge ago(Duration d) => relativeAge(now.subtract(d), now);

  test('under a minute, or in the future, is just now', () {
    expect(ago(const Duration(seconds: 59)), isA<JustNow>());
    expect(
      relativeAge(now.add(const Duration(minutes: 5)), now),
      isA<JustNow>(),
    );
  });

  test('minutes up to an hour', () {
    expect((ago(const Duration(minutes: 1)) as MinutesAgo).minutes, 1);
    expect((ago(const Duration(minutes: 59)) as MinutesAgo).minutes, 59);
  });

  test('hours earlier today', () {
    expect((ago(const Duration(minutes: 60)) as HoursAgo).hours, 1);
    expect(
      (relativeAge(DateTime(2026, 9, 28, 0, 5), now) as HoursAgo).hours,
      14,
    );
  });

  test('yesterday is the previous calendar day, not 24 hours', () {
    expect(relativeAge(DateTime(2026, 9, 27, 23, 50), now), isA<Yesterday>());
    expect(relativeAge(DateTime(2026, 9, 27, 0, 1), now), isA<Yesterday>());
    // Just after midnight, an item from before midnight is still minutes.
    expect(
      relativeAge(DateTime(2026, 9, 27, 23, 50), DateTime(2026, 9, 28, 0, 10)),
      isA<MinutesAgo>(),
    );
  });

  test('days up to a week, counted in calendar days', () {
    expect((relativeAge(DateTime(2026, 9, 26, 23, 0), now) as DaysAgo).days, 2);
    expect((relativeAge(DateTime(2026, 9, 22, 8, 0), now) as DaysAgo).days, 6);
  });

  test('a week or longer shows the date', () {
    expect(
      (relativeAge(DateTime(2026, 9, 21, 9, 0), now) as OnDate).date,
      LocalDate(2026, 9, 21),
    );
  });

  test('summer time does not shift the days', () {
    // Around the end of summer time (25-10-2026) in Europe.
    expect(
      (relativeAge(DateTime(2026, 10, 24, 12, 0), DateTime(2026, 10, 26, 9, 0))
              as DaysAgo)
          .days,
      2,
    );
  });
}
