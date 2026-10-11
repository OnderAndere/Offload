import '../review/weekly_review.dart';
import '../time/local_date.dart';
import 'day_reminders.dart';

/// The weekly-review reminder (REQ-022, T4.4, DD-005, DD-018 points 8 and
/// 16): on a chosen weekday at a chosen time, only while a review is due.
/// Off by default; Friday 16:00 once switched on (PO 04-10-2026).
abstract final class ReviewReminderSetting {
  /// Friday.
  static const standardWeekday = DateTime.friday;

  /// 16:00.
  static const standardMinute = 16 * 60;

  /// The stored weekday (Monday 1 ... Sunday 7), or [standardWeekday] for
  /// a missing or unknown one.
  static int parseWeekday(String? stored) {
    final day = int.tryParse(stored ?? '');
    return day != null && day >= DateTime.monday && day <= DateTime.sunday
        ? day
        : standardWeekday;
  }

  /// The stored time of day, or [standardMinute].
  static int parseMinute(String? stored) =>
      ReminderTime.parse(stored, fallback: standardMinute);
}

/// The weekly-review reminder of one day: its own notification, next to
/// the day's reminder of deadlines (decision e).
class ReviewReminder {
  const ReviewReminder({
    required this.day,
    required this.at,
    required this.daysSince,
  });

  final LocalDate day;

  /// When it comes, in local time.
  final DateTime at;

  /// Calendar days since the last completed review on [day]; null when
  /// none was ever completed.
  final int? daysSince;

  /// A stable number, apart from the day reminders' `yyyymmdd`.
  int get id => reviewReminderId(day);
}

/// The id of the weekly-review reminder on [day]: `1yyyymmdd`, never equal
/// to a day reminder's `yyyymmdd`.
int reviewReminderId(LocalDate day) =>
    reviewReminderIdOffset + day.year * 10000 + day.month * 100 + day.day;

const reviewReminderIdOffset = 100000000;

/// What a tap on the weekly-review reminder opens: the weekly review. An
/// item id is a UUID and never looks like this.
const reviewReminderOpen = '#review';

/// The weekly-review reminders from [now] (local time): each [weekday] up
/// to [reminderDaysAhead] ahead whose time is still to come and on which a
/// review is due ([reviewDue], the rule of the line on *Today*), counting
/// from [lastCompleted] as if no review is done in between. A new plan
/// follows every completed review, so a review done meanwhile takes the
/// coming ones away.
List<ReviewReminder> planReviewReminders({
  required DateTime now,
  required int weekday,
  required int minuteOfDay,
  required DateTime? lastCompleted,
  required int dueAfterDays,
}) {
  final today = LocalDate.of(now);
  final reminders = <ReviewReminder>[];
  for (var d = 0; d <= reminderDaysAhead; d++) {
    final day = today.addDays(d);
    if (day.weekday != weekday) continue;
    final at = DateTime(
      day.year,
      day.month,
      day.day,
      minuteOfDay ~/ 60,
      minuteOfDay % 60,
    );
    if (!at.isAfter(now) || !reviewDue(lastCompleted, day, dueAfterDays)) {
      continue;
    }
    reminders.add(
      ReviewReminder(
        day: day,
        at: at,
        daysSince: daysSinceReview(lastCompleted, day),
      ),
    );
  }
  return reminders;
}
