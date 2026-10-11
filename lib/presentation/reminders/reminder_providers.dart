import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/items/nudge.dart';
import '../../domain/reminders/day_reminders.dart';
import '../../domain/reminders/review_reminders.dart';
import '../../platform/reminders/platform_reminder_scheduler.dart';
import '../../platform/reminders/reminder_scheduler.dart';
import '../startup/app_storage_provider.dart';

/// Reminders through the platform (DD-005, T4.1, T4.5); stopped with the
/// app's providers.
final reminderSchedulerProvider = Provider<ReminderScheduler>((ref) {
  final scheduler = createPlatformReminderScheduler();
  ref.onDispose(scheduler.dispose);
  return scheduler;
});

/// Whether deadline reminders are on: a setting of this device, on unless
/// switched off (DD-018 point 16).
final remindersOnProvider = NotifierProvider<RemindersOnNotifier, bool>(
  RemindersOnNotifier.new,
);

class RemindersOnNotifier extends Notifier<bool> {
  @override
  bool build() => ref.watch(storageProvider).remindersOn;

  /// Applies [on] at once, then stores it. Throws when storing fails; the
  /// choice then still applies until the app restarts.
  Future<void> choose(bool on) async {
    state = on;
    await ref.read(storageProvider).saveRemindersOn(on);
  }
}

/// When the reminder of a day comes, in minutes after midnight (SPEC
/// Q24): a setting of this device, 09:00 by default.
final reminderMinuteProvider = NotifierProvider<ReminderMinuteNotifier, int>(
  ReminderMinuteNotifier.new,
);

class ReminderMinuteNotifier extends Notifier<int> {
  @override
  int build() => ref.watch(storageProvider).reminderMinute;

  /// Applies [minutes] at once, then stores it. Throws when storing fails.
  Future<void> choose(int minutes) async {
    state = ReminderTime.parse(minutes.toString());
    await ref.read(storageProvider).saveReminderMinute(state);
  }
}

/// Whether the platform shows notifications; read again when the app
/// comes back to the foreground (the user may have changed it).
final notificationsEnabledProvider = FutureProvider.autoDispose<bool>(
  (ref) => ref.watch(reminderSchedulerProvider).enabled(),
);

/// Whether the weekly-review reminder is on (REQ-022, T4.4): a setting of
/// this device, off unless switched on.
final reviewReminderOnProvider =
    NotifierProvider<ReviewReminderOnNotifier, bool>(
      ReviewReminderOnNotifier.new,
    );

class ReviewReminderOnNotifier extends Notifier<bool> {
  @override
  bool build() => ref.watch(storageProvider).reviewReminderOn;

  /// Applies [on] at once, then stores it. Throws when storing fails.
  Future<void> choose(bool on) async {
    state = on;
    await ref.read(storageProvider).saveReviewReminderOn(on);
  }
}

/// The weekday of the weekly-review reminder, Monday 1 ... Sunday 7.
final reviewReminderWeekdayProvider =
    NotifierProvider<ReviewReminderWeekdayNotifier, int>(
      ReviewReminderWeekdayNotifier.new,
    );

class ReviewReminderWeekdayNotifier extends Notifier<int> {
  @override
  int build() => ref.watch(storageProvider).reviewReminderWeekday;

  /// Applies [weekday] at once, then stores it. Throws when storing fails.
  Future<void> choose(int weekday) async {
    state = ReviewReminderSetting.parseWeekday(weekday.toString());
    await ref.read(storageProvider).saveReviewReminderWeekday(state);
  }
}

/// The time of the weekly-review reminder, in minutes after midnight.
final reviewReminderMinuteProvider =
    NotifierProvider<ReviewReminderMinuteNotifier, int>(
      ReviewReminderMinuteNotifier.new,
    );

class ReviewReminderMinuteNotifier extends Notifier<int> {
  @override
  int build() => ref.watch(storageProvider).reviewReminderMinute;

  /// Applies [minutes] at once, then stores it. Throws when storing fails.
  Future<void> choose(int minutes) async {
    state = ReviewReminderSetting.parseMinute(minutes.toString());
    await ref.read(storageProvider).saveReviewReminderMinute(state);
  }
}

/// Whether birthdays are reminded (REQ-031, T4.6): a setting of this
/// device, on unless switched off.
final birthdayRemindersOnProvider =
    NotifierProvider<BirthdayRemindersOnNotifier, bool>(
      BirthdayRemindersOnNotifier.new,
    );

class BirthdayRemindersOnNotifier extends Notifier<bool> {
  @override
  bool build() => ref.watch(storageProvider).birthdayRemindersOn;

  /// Applies [on] at once, then stores it. Throws when storing fails.
  Future<void> choose(bool on) async {
    state = on;
    await ref.read(storageProvider).saveBirthdayRemindersOn(on);
  }
}

/// Whether a silent waiting item gets a notification (AC REQ-047, T10.1).
final nudgeOnProvider = NotifierProvider<NudgeOnNotifier, bool>(
  NudgeOnNotifier.new,
);

class NudgeOnNotifier extends Notifier<bool> {
  @override
  bool build() => ref.watch(storageProvider).nudgeOn;

  /// Applies [on] at once, then stores it. Throws when storing fails.
  Future<void> choose(bool on) async {
    state = on;
    await ref.read(storageProvider).saveNudgeOn(on);
  }
}

/// After how many days without a touch a waiting item is silent; also the
/// group on *Today* (T10.1).
final nudgeAfterProvider = NotifierProvider<NudgeAfterNotifier, int>(
  NudgeAfterNotifier.new,
);

class NudgeAfterNotifier extends Notifier<int> {
  @override
  int build() => ref.watch(storageProvider).nudgeAfterDays;

  /// Applies [days] at once, then stores it. Throws when storing fails.
  Future<void> choose(int days) async {
    state = NudgeAfter.parse(days.toString());
    await ref.read(storageProvider).saveNudgeAfterDays(state);
  }
}
