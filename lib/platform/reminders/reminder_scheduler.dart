/// One planned notification (DD-005): when, and what it says, already in
/// the UI language.
class PlannedReminder {
  const PlannedReminder({
    required this.id,
    required this.at,
    required this.title,
    required this.lines,
    required this.publicTitle,
    required this.open,
  });

  /// Stable per day (`yyyymmdd`), so a new plan replaces it.
  final int id;

  /// When it comes, in local time; the platform may deliver it up to ten
  /// minutes later (SPEC Q38).
  final DateTime at;

  /// "Deadline vandaag", or "3 deadlines vandaag".
  final String title;

  /// The titles, at most five, and "en nog n".
  final List<String> lines;

  /// What the lock screen shows: never a title (DD-018 point 16).
  final String publicTitle;

  /// What a tap opens: an item id, or empty for *Today*.
  final String open;
}

/// Reminders through the platform (DD-005, T4.1). The app hands over the
/// whole plan each time; the scheduler replaces what was planned before.
/// No item title is kept on disk: on Android only the dates, times and
/// count lines are, encrypted, to plan them again after a restart (T4.3).
abstract class ReminderScheduler {
  /// Whether this platform has reminders yet: Android now, Windows in T4.5.
  bool get supported;

  /// Plans exactly [reminders]; any earlier reminder whose id is in
  /// [cancel] and not in [reminders] goes. [channelName] names the
  /// notifications in the system settings.
  Future<void> replaceAll(
    List<PlannedReminder> reminders, {
    required List<int> cancel,
    required String channelName,
  });

  /// Whether notifications may be shown.
  Future<bool> enabled();

  /// Asks the user for the notification permission (Android's own
  /// question); answers whether it is granted.
  Future<bool> request();

  /// Opens the system settings of the app's notifications.
  Future<void> openSettings();

  /// What a tap on a notification, the Offload bar or an app shortcut that
  /// started the app opens, once: an item id, empty for *Today*, `#review`,
  /// `#person:<id>`, `#today` or `#insights` (REQ-063); or null.
  Future<String?> takeOpened();

  /// What taps on a notification open while the app runs.
  Stream<String> get opened;

  /// Stops what runs in the app for it (the check on Windows); planned
  /// alarms on Android stay.
  void dispose();
}
