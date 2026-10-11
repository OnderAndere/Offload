import 'dart:async';

import 'package:flutter/services.dart';

import 'reminder_scheduler.dart';

/// The reminders handed over and not shown yet (T4.5, DD-005), with the
/// same rules as the alarms on Android: a new plan replaces the reminders
/// it may take away ([replace]'s `cancel`) and keeps one whose time passed
/// but that was not shown yet.
class ReminderQueue {
  final _pending = <int, PlannedReminder>{};

  /// The reminders still to show, earliest first.
  List<PlannedReminder> get pending =>
      _pending.values.toList()..sort((a, b) => a.at.compareTo(b.at));

  void replace(List<PlannedReminder> reminders, List<int> cancel) {
    final planned = {for (final r in reminders) r.id};
    for (final id in cancel) {
      if (!planned.contains(id)) _pending.remove(id);
    }
    for (final r in reminders) {
      _pending[r.id] = r;
    }
  }

  /// Takes out every reminder due at [now] and returns those of today,
  /// earliest first. One of an earlier day is dropped without showing:
  /// the PC slept past it, and its items are on *Today* (decision c).
  List<PlannedReminder> takeDue(DateTime now) {
    final due = [
      for (final r in pending)
        if (!r.at.isAfter(now)) r,
    ];
    for (final r in due) {
      _pending.remove(r.id);
    }
    return [
      for (final r in due)
        if (_sameDay(r.at, now)) r,
    ];
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

/// [ReminderScheduler] on Windows (T4.5, DD-005): a balloon of the
/// runner's tray icon (`windows_shell.cpp`) while the app runs, also hidden
/// in the tray. Nothing is scheduled with Windows; every half minute the
/// queue is checked against the clock, so sleep and a changed clock do no
/// harm. After *Exit* nothing comes (SPEC Q2, not for v1).
class WindowsReminderScheduler implements ReminderScheduler {
  WindowsReminderScheduler({
    this._channel = const MethodChannel(_channelName),
    this._now = DateTime.now,
    this._every = const Duration(seconds: 30),
  }) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'opened') _opened.add(call.arguments as String? ?? '');
    });
  }

  static const _channelName = 'eu.marandos.offload/reminders';

  final MethodChannel _channel;
  final DateTime Function() _now;
  final Duration _every;
  final _queue = ReminderQueue();
  final _opened = StreamController<String>.broadcast();
  Timer? _timer;

  @override
  bool get supported => true;

  @override
  Future<void> replaceAll(
    List<PlannedReminder> reminders, {
    required List<int> cancel,
    required String channelName,
  }) async {
    _queue.replace(reminders, cancel);
    _timer ??= Timer.periodic(_every, (_) => unawaited(check()));
    await check();
  }

  /// Shows what is due now; one at a time, as the tray has one balloon.
  Future<void> check() async {
    for (final r in _queue.takeDue(_now())) {
      try {
        await _channel.invokeMethod<void>('show', {
          'title': r.title,
          'text': r.lines.join('\n'),
          'open': r.open,
        });
      } on PlatformException {
        // No tray icon (yet): this one is not shown; Today has its items.
      } on MissingPluginException {
        // No runner channel (tests).
      }
    }
  }

  /// Windows has no permission to ask; whether notifications are on is the
  /// user's choice in Windows' settings.
  @override
  Future<bool> enabled() async => true;

  @override
  Future<bool> request() async => true;

  @override
  Future<void> openSettings() async {
    try {
      await _channel.invokeMethod<void>('openSettings');
    } on MissingPluginException {
      // No runner channel (tests).
    }
  }

  /// A click on a balloon reaches a running app only ([opened]).
  @override
  Future<String?> takeOpened() async => null;

  @override
  Stream<String> get opened => _opened.stream;

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    _channel.setMethodCallHandler(null);
    unawaited(_opened.close());
  }
}
