import 'package:flutter_test/flutter_test.dart';
import 'package:offload/domain/time/local_date.dart';

void main() {
  test('refuses dates that do not exist', () {
    expect(() => LocalDate(2026, 2, 31), throwsArgumentError);
    expect(LocalDate.tryCreate(2026, 13, 1), isNull);
    expect(LocalDate.tryCreate(2028, 2, 29), LocalDate(2028, 2, 29));
  });

  test('adds days across months and years', () {
    expect(LocalDate(2026, 9, 30).addDays(2), LocalDate(2026, 10, 2));
    expect(LocalDate(2026, 12, 31).addDays(1), LocalDate(2027, 1, 1));
  });

  test('knows its weekday and order', () {
    expect(LocalDate(2026, 9, 27).weekday, DateTime.sunday);
    expect(LocalDate(2026, 9, 28).compareTo(LocalDate(2026, 9, 27)), 1);
    expect(LocalDate.of(DateTime(2026, 9, 27, 23, 59)), LocalDate(2026, 9, 27));
  });

  test('counts whole days between dates, also across DST and years', () {
    expect(LocalDate(2026, 10, 2).daysSince(LocalDate(2026, 9, 23)), 9);
    // The night the clocks go back in the Netherlands.
    expect(LocalDate(2026, 10, 26).daysSince(LocalDate(2026, 10, 24)), 2);
    expect(LocalDate(2027, 1, 1).daysSince(LocalDate(2026, 12, 31)), 1);
    expect(LocalDate(2026, 9, 1).daysSince(LocalDate(2026, 9, 3)), -2);
  });
}
