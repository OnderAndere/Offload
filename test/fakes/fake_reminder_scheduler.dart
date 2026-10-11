import 'dart:async';

import 'package:offload/platform/reminders/reminder_scheduler.dart';

/// A [ReminderScheduler] for tests: remembers the last plan, answers the
/// permission question as told.
class FakeReminderScheduler implements ReminderScheduler {
  FakeReminderScheduler({
    this.supported = true,
    this.granted = false,
    this.grantOnRequest = true,
  });

  @override
  final bool supported;

  /// Whether notifications are on now.
  bool granted;

  /// What the user answers when asked.
  bool grantOnRequest;

  /// How often the permission was asked.
  int requests = 0;
  int settingsOpened = 0;

  /// The plans handed over, the last one last.
  final plans = <List<PlannedReminder>>[];
  String? channelName;
  String? launchOpened;
  final _opened = StreamController<String>.broadcast();

  List<PlannedReminder> get planned => plans.isEmpty ? const [] : plans.last;

  /// A tap on a notification while the app runs.
  void tap(String open) => _opened.add(open);

  @override
  Future<void> replaceAll(
    List<PlannedReminder> reminders, {
    required List<int> cancel,
    required String channelName,
  }) async {
    plans.add(List.of(reminders));
    this.channelName = channelName;
  }

  @override
  Future<bool> enabled() async => granted;

  @override
  Future<bool> request() async {
    requests++;
    granted = grantOnRequest;
    return granted;
  }

  @override
  Future<void> openSettings() async => settingsOpened++;

  @override
  Future<String?> takeOpened() async {
    final open = launchOpened;
    launchOpened = null;
    return open;
  }

  @override
  Stream<String> get opened => _opened.stream;

  @override
  void dispose() {}
}
