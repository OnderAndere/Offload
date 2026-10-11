import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/platform/reminders/reminder_scheduler.dart';
import 'package:offload/platform/reminders/windows_reminder_scheduler.dart';

/// Reminders on Windows: tray notifications while the app runs (T4.5,
/// REQ-020, DD-005).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  PlannedReminder reminder(int id, DateTime at, {String open = ''}) =>
      PlannedReminder(
        id: id,
        at: at,
        title: 'Deadline vandaag',
        lines: ['Offerte dakgoot', 'Tegels bestellen'],
        publicTitle: 'Deadline vandaag',
        open: open,
      );

  group('the queue', () {
    final nine = DateTime(2026, 10, 9, 9);

    test('due ones of today come out once, earliest first', () {
      final queue = ReminderQueue()
        ..replace([
          reminder(2, nine.add(const Duration(hours: 7))),
          reminder(1, nine),
          reminder(3, nine.add(const Duration(days: 1))),
        ], const []);
      expect(queue.takeDue(nine.subtract(const Duration(minutes: 1))), isEmpty);
      expect(queue.takeDue(DateTime(2026, 10, 9, 17)).map((r) => r.id), [1, 2]);
      expect(queue.takeDue(DateTime(2026, 10, 9, 17)), isEmpty);
      expect(queue.pending.map((r) => r.id), [3]);
    });

    test('one of an earlier day is dropped: the PC slept past it', () {
      final queue = ReminderQueue()..replace([reminder(1, nine)], const []);
      expect(queue.takeDue(DateTime(2026, 10, 12, 8)), isEmpty);
      expect(queue.pending, isEmpty);
    });

    test('a new plan replaces what it may take away and keeps a passed one '
        'not shown yet', () {
      final queue = ReminderQueue()
        ..replace([
          reminder(1, nine),
          reminder(2, nine.add(const Duration(days: 1))),
        ], const []);
      // After 09:00 the app plans again without today's: it may only take
      // away tomorrow onwards.
      queue.replace([reminder(3, nine.add(const Duration(days: 2)))], [2, 3]);
      expect(queue.pending.map((r) => r.id), [1, 3]);
    });
  });

  group('the scheduler', () {
    const channel = MethodChannel('eu.marandos.offload/reminders');
    final calls = <MethodCall>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    setUp(() {
      calls.clear();
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return null;
      });
    });
    tearDown(() => messenger.setMockMethodCallHandler(channel, null));

    test('shows a due reminder as a tray balloon with its lines', () async {
      var now = DateTime(2026, 10, 9, 8, 59);
      final scheduler = WindowsReminderScheduler(
        now: () => now,
        every: const Duration(days: 1),
      );
      await scheduler.replaceAll(
        [reminder(20261009, DateTime(2026, 10, 9, 9), open: 'abc')],
        cancel: const [],
        channelName: 'Herinneringen',
      );
      expect(calls, isEmpty);

      now = DateTime(2026, 10, 9, 9, 0, 30);
      await scheduler.check();
      expect(calls.single.method, 'show');
      expect(calls.single.arguments, {
        'title': 'Deadline vandaag',
        'text': 'Offerte dakgoot\nTegels bestellen',
        'open': 'abc',
      });
      await scheduler.check();
      expect(calls, hasLength(1));
    });

    test(
      'a click on the balloon reaches the app; no permission to ask',
      () async {
        final scheduler = WindowsReminderScheduler(
          every: const Duration(days: 1),
        );
        final opened = scheduler.opened.first;
        await messenger.handlePlatformMessage(
          channel.name,
          const StandardMethodCodec().encodeMethodCall(
            const MethodCall('opened', 'abc'),
          ),
          (_) {},
        );
        expect(await opened, 'abc');
        expect(scheduler.supported, isTrue);
        expect(await scheduler.enabled(), isTrue);
        expect(await scheduler.takeOpened(), isNull);
      },
    );
  });
}
