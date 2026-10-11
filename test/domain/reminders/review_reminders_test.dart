import 'package:flutter_test/flutter_test.dart';
import 'package:offload/domain/reminders/day_reminders.dart';
import 'package:offload/domain/reminders/review_reminders.dart';
import 'package:offload/domain/time/local_date.dart';

/// Planning the weekly-review reminder (T4.4, REQ-022, DD-005, DD-018
/// points 8 and 16).
void main() {
  // Monday 5 October 2026, 08:00.
  final monday = DateTime(2026, 10, 5, 8);
  const friday = DateTime.friday;
  const fourPm = 16 * 60;

  List<ReviewReminder> plan({
    DateTime? now,
    int weekday = friday,
    int minute = fourPm,
    DateTime? last,
    int dueAfter = 7,
  }) => planReviewReminders(
    now: now ?? monday,
    weekday: weekday,
    minuteOfDay: minute,
    lastCompleted: last,
    dueAfterDays: dueAfter,
  );

  group('the setting', () {
    test('Friday 16:00 unless a valid one is stored', () {
      expect(ReviewReminderSetting.parseWeekday(null), DateTime.friday);
      expect(ReviewReminderSetting.parseWeekday('0'), DateTime.friday);
      expect(ReviewReminderSetting.parseWeekday('8'), DateTime.friday);
      expect(ReviewReminderSetting.parseWeekday('7'), DateTime.sunday);
      expect(ReviewReminderSetting.parseMinute(null), 16 * 60);
      expect(ReviewReminderSetting.parseMinute('1440'), 16 * 60);
      expect(ReviewReminderSetting.parseMinute('600'), 600);
    });
  });

  test('never reviewed: every Friday in the plan, at 16:00', () {
    final reviews = plan();
    expect(reviews.first.day, LocalDate(2026, 10, 9));
    expect(reviews.first.at, DateTime(2026, 10, 9, 16));
    expect(reviews.map((r) => r.day.weekday).toSet(), {DateTime.friday});
    expect(reviews, hasLength(4));
    expect(reviews.every((r) => r.daysSince == null), isTrue);
    expect(
      reviews.last.day.compareTo(
        LocalDate(2026, 10, 5).addDays(reminderDaysAhead),
      ),
      lessThanOrEqualTo(0),
    );
  });

  test('only while due: a review last Sunday skips this Friday', () {
    // Sunday 4 October; due again after 7 days, so from Sunday 11 on.
    final reviews = plan(last: DateTime(2026, 10, 4, 20));
    expect(reviews.first.day, LocalDate(2026, 10, 16));
    expect(reviews.first.daysSince, 12);
    expect(reviews[1].daysSince, 19);
  });

  test('exactly due on the day counts; the time of day does not matter', () {
    // Friday 2 October 23:59: 7 days before Friday 9 October.
    final reviews = plan(last: DateTime(2026, 10, 2, 23, 59));
    expect(reviews.first.day, LocalDate(2026, 10, 9));
    expect(reviews.first.daysSince, 7);
  });

  test("today's time passed: next week", () {
    final fridayEvening = DateTime(2026, 10, 9, 17);
    expect(plan(now: fridayEvening).first.day, LocalDate(2026, 10, 16));
    expect(
      plan(now: DateTime(2026, 10, 9, 16)).first.day,
      LocalDate(2026, 10, 16),
    );
    expect(
      plan(now: DateTime(2026, 10, 9, 15, 59)).first.day,
      LocalDate(2026, 10, 9),
    );
  });

  test('another weekday and time', () {
    final reviews = plan(weekday: DateTime.monday, minute: 9 * 60);
    expect(reviews.first.at, DateTime(2026, 10, 5, 9));
  });

  test('its own ids, apart from the day reminders', () {
    final day = LocalDate(2026, 10, 9);
    expect(reviewReminderId(day), 120261009);
    expect(plan().first.id, 120261009);
  });
}
