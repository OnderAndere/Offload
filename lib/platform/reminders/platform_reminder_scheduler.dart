import 'dart:io';

import 'android_reminder_scheduler.dart';
import 'reminder_scheduler.dart';
import 'windows_reminder_scheduler.dart';

/// The [ReminderScheduler] for the platform the app runs on: alarms on
/// Android (T4.1), tray notifications on Windows (T4.5).
ReminderScheduler createPlatformReminderScheduler() => Platform.isAndroid
    ? AndroidReminderScheduler()
    : Platform.isWindows
    ? WindowsReminderScheduler()
    : NoReminderScheduler();

/// A platform without reminders: plans nothing, shows nothing.
class NoReminderScheduler implements ReminderScheduler {
  @override
  bool get supported => false;

  @override
  Future<void> replaceAll(
    List<PlannedReminder> reminders, {
    required List<int> cancel,
    required String channelName,
  }) async {}

  @override
  Future<bool> enabled() async => false;

  @override
  Future<bool> request() async => false;

  @override
  Future<void> openSettings() async {}

  @override
  Future<String?> takeOpened() async => null;

  @override
  Stream<String> get opened => const Stream.empty();

  @override
  void dispose() {}
}
