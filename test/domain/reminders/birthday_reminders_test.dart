import 'package:flutter_test/flutter_test.dart';
import 'package:offload/domain/people/birthday.dart';
import 'package:offload/domain/people/person.dart';
import 'package:offload/domain/reminders/birthday_reminders.dart';
import 'package:offload/domain/time/local_date.dart';

/// Birthday reminders (T4.6, REQ-031, DD-005, DD-012).
void main() {
  Person person(String id, String name, Birthday? birthday) =>
      Person(id: id, name: name, birthday: birthday);

  group('on which day', () {
    test('day and month count, the year does not', () {
      final b = Birthday.tryCreate(3, 4, 1980)!;
      expect(isBirthdayOn(b, LocalDate(2026, 4, 3)), isTrue);
      expect(isBirthdayOn(b, LocalDate(2026, 4, 4)), isFalse);
      expect(isBirthdayOn(b, LocalDate(2026, 3, 3)), isFalse);
    });

    test('29 February falls on 28 February in a year without it', () {
      final leap = Birthday.tryCreate(29, 2)!;
      expect(isBirthdayOn(leap, LocalDate(2027, 2, 28)), isTrue);
      expect(isBirthdayOn(leap, LocalDate(2028, 2, 28)), isFalse);
      expect(isBirthdayOn(leap, LocalDate(2028, 2, 29)), isTrue);
      // A birthday on 28 February is not moved.
      expect(
        isBirthdayOn(Birthday.tryCreate(28, 2)!, LocalDate(2028, 2, 28)),
        isTrue,
      );
    });

    test('the age reached on the day, also on the moved 29 February', () {
      final leap = Birthday.tryCreate(29, 2, 2000)!;
      expect(ageTurningOn(leap, LocalDate(2027, 2, 28)), 27);
      expect(ageTurningOn(leap, LocalDate(2028, 2, 29)), 28);
      expect(
        ageTurningOn(Birthday.tryCreate(3, 4)!, LocalDate(2026, 4, 3)),
        isNull,
      );
    });

    test('who has a birthday on a day, by name', () {
      final day = LocalDate(2026, 10, 9);
      final people = [
        person('b', 'jan Bakker', Birthday.tryCreate(9, 10)),
        person('a', 'Anna de Vries', Birthday.tryCreate(9, 10, 1990)),
        person('c', 'Petra', Birthday.tryCreate(10, 10)),
        person('d', 'Zonder', null),
      ];
      expect(birthdaysOn(people, day).map((p) => p.id), ['a', 'b']);
    });
  });

  group('the plan', () {
    final now = DateTime(2026, 10, 9, 8);
    final people = [
      person('a', 'Anna', Birthday.tryCreate(9, 10, 1990)),
      person('b', 'Bram', Birthday.tryCreate(9, 10)),
      person('c', 'Cor', Birthday.tryCreate(20, 10)),
      person('d', 'Dirk', Birthday.tryCreate(1, 12)),
    ];

    test('per day with birthdays, at the day\'s time, a month ahead', () {
      final days = planBirthdayReminders(people, now: now, minuteOfDay: 540);
      expect(days.map((d) => d.day), [
        LocalDate(2026, 10, 9),
        LocalDate(2026, 10, 20),
      ]);
      expect(days.first.at, DateTime(2026, 10, 9, 9));
      expect(days.first.personIds, ['a', 'b']);
      expect(days.first.id, 220261009);
    });

    test("today's time passed: today's goes to the line on Today", () {
      final days = planBirthdayReminders(
        people,
        now: DateTime(2026, 10, 9, 9),
        minuteOfDay: 540,
      );
      expect(days.first.day, LocalDate(2026, 10, 20));
    });

    test('no birthdays, no plan', () {
      expect(
        planBirthdayReminders(
          [person('x', 'X', null)],
          now: now,
          minuteOfDay: 540,
        ),
        isEmpty,
      );
    });
  });
}
