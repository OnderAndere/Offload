/// Birthday reminders (REQ-031, T4.6, DD-005, DD-012; PO decisions
/// 04-10-2026): on the day itself, at the time of the day's reminder, a
/// notification of its own; a line on *Today*.
library;

import '../people/birthday.dart';
import '../people/person.dart';
import '../time/local_date.dart';
import 'day_reminders.dart';

/// Whether [birthday] falls on [day]. In a year without 29 February a
/// birthday on that date falls on 28 February (decision e).
bool isBirthdayOn(Birthday birthday, LocalDate day) {
  if (birthday.month != day.month) return false;
  if (birthday.day == day.day) return true;
  final leapDay = birthday.month == 2 && birthday.day == 29;
  return leapDay &&
      day.day == 28 &&
      LocalDate.tryCreate(day.year, 2, 29) == null;
}

/// The age [birthday] reaches on [day], a day it falls on
/// ([isBirthdayOn]); null without a year. Unlike `Birthday.ageOn` it also
/// counts the moved 29 February (28 February in other years) as reached.
int? ageTurningOn(Birthday birthday, LocalDate day) {
  final year = birthday.year;
  if (year == null) return null;
  final age = day.year - year;
  return age < 0 ? null : age;
}

/// The people with a birthday on [day], by name.
List<Person> birthdaysOn(Iterable<Person> people, LocalDate day) => [
  for (final person in people)
    if (person.birthday case final birthday?)
      if (isBirthdayOn(birthday, day)) person,
]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

/// The birthday reminder of one day: its own notification (decision b).
class BirthdayDay {
  const BirthdayDay({
    required this.day,
    required this.at,
    required this.personIds,
  });

  final LocalDate day;

  /// When it comes, in local time.
  final DateTime at;

  /// Whose birthday it is, by name.
  final List<String> personIds;

  /// A stable number, apart from the other reminders: `2yyyymmdd`.
  int get id =>
      birthdayReminderIdOffset + day.year * 10000 + day.month * 100 + day.day;
}

/// Where the ids of the birthday reminders start (`2yyyymmdd`).
const birthdayReminderIdOffset = 200000000;

/// What a tap on a birthday reminder for one person opens: this prefix and
/// the person's id. An item id is a UUID and never looks like this.
const personReminderOpenPrefix = '#person:';

/// What a tap on the birthday reminder of person [personId] opens.
String personReminderOpen(String personId) =>
    '$personReminderOpenPrefix$personId';

/// The person a tap target [open] stands for, or null when it is none.
String? personOfReminderOpen(String open) =>
    open.startsWith(personReminderOpenPrefix)
    ? open.substring(personReminderOpenPrefix.length)
    : null;

/// The birthday reminders for [people] from [now] (local time): per day
/// with birthdays, from today up to [reminderDaysAhead] ahead, one at
/// [minuteOfDay]; a day whose time has passed gets none (the line on
/// *Today* shows it).
List<BirthdayDay> planBirthdayReminders(
  Iterable<Person> people, {
  required DateTime now,
  required int minuteOfDay,
}) {
  final today = LocalDate.of(now);
  final withBirthday = [
    for (final person in people)
      if (person.birthday != null) person,
  ];
  if (withBirthday.isEmpty) return const [];
  final days = <BirthdayDay>[];
  for (var d = 0; d <= reminderDaysAhead; d++) {
    final day = today.addDays(d);
    final at = DateTime(
      day.year,
      day.month,
      day.day,
      minuteOfDay ~/ 60,
      minuteOfDay % 60,
    );
    if (!at.isAfter(now)) continue;
    final born = birthdaysOn(withBirthday, day);
    if (born.isEmpty) continue;
    days.add(
      BirthdayDay(day: day, at: at, personIds: [for (final p in born) p.id]),
    );
  }
  return days;
}
