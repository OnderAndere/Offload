import 'package:flutter_test/flutter_test.dart';
import 'package:offload/domain/people/birthday.dart';
import 'package:offload/domain/time/local_date.dart';

/// The birthday of a person (T3.3, REQ-031).
void main() {
  test('day and month must exist; 29 February only with a leap year', () {
    expect(Birthday.tryCreate(3, 4), isNotNull);
    expect(Birthday.tryCreate(29, 2), isNotNull);
    expect(Birthday.tryCreate(29, 2, 2024), isNotNull);
    expect(Birthday.tryCreate(29, 2, 2023), isNull);
    expect(Birthday.tryCreate(31, 4), isNull);
    expect(Birthday.tryCreate(0, 4), isNull);
    expect(Birthday.tryCreate(3, 13), isNull);
    expect(Birthday.tryCreate(3, 4, 0), isNull);
  });

  test('the age counts from the birthday in this year', () {
    final born = Birthday.tryCreate(3, 4, 1980)!;
    expect(born.ageOn(LocalDate(2026, 4, 2)), 45);
    expect(born.ageOn(LocalDate(2026, 4, 3)), 46);
    expect(born.ageOn(LocalDate(2026, 10, 1)), 46);
    expect(Birthday.tryCreate(3, 4)!.ageOn(LocalDate(2026, 10, 1)), isNull);
    expect(
      Birthday.tryCreate(3, 4, 2030)!.ageOn(LocalDate(2026, 10, 1)),
      isNull,
    );
  });

  test('a date to show, also for 29 February without a year', () {
    expect(Birthday.tryCreate(29, 2)!.displayDate, LocalDate(2000, 2, 29));
    expect(Birthday.tryCreate(3, 4, 1980)!.displayDate, LocalDate(1980, 4, 3));
  });
}
