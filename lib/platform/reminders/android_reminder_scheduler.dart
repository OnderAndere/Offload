import 'dart:async';

import 'package:flutter/services.dart';

import 'reminder_scheduler.dart';

/// [ReminderScheduler] on Android (`ReminderChannel.kt`): inexact alarms
/// with a window of ten minutes, no plugin (DD-005).
class AndroidReminderScheduler implements ReminderScheduler {
  AndroidReminderScheduler() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'opened') _opened.add(call.arguments as String? ?? '');
    });
  }

  static const _channel = MethodChannel('eu.marandos.offload/reminders');
  final _opened = StreamController<String>.broadcast();

  @override
  bool get supported => true;

  @override
  Future<void> replaceAll(
    List<PlannedReminder> reminders, {
    required List<int> cancel,
    required String channelName,
  }) => _channel.invokeMethod<void>('replaceAll', {
    'channelName': channelName,
    'cancel': cancel,
    'reminders': [
      for (final r in reminders)
        {
          'id': r.id,
          'at': r.at.millisecondsSinceEpoch,
          'title': r.title,
          'lines': r.lines,
          'publicTitle': r.publicTitle,
          'open': r.open,
        },
    ],
  });

  @override
  Future<bool> enabled() async =>
      await _channel.invokeMethod<bool>('enabled') ?? false;

  @override
  Future<bool> request() async =>
      await _channel.invokeMethod<bool>('request') ?? false;

  @override
  Future<void> openSettings() => _channel.invokeMethod<void>('openSettings');

  @override
  Future<String?> takeOpened() => _channel.invokeMethod<String>('takeOpened');

  @override
  Stream<String> get opened => _opened.stream;

  @override
  void dispose() {
    _channel.setMethodCallHandler(null);
    unawaited(_opened.close());
  }
}
