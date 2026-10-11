import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/people/drift_people_repository.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/domain/people/birthday.dart';
import 'package:offload/domain/people/person.dart';
import 'package:offload/domain/reminders/birthday_reminders.dart';
import 'package:offload/domain/time/local_date.dart';
import 'package:offload/l10n/app_localizations.dart';
import 'package:offload/presentation/app.dart';
import 'package:offload/presentation/capture/pending_captures.dart';
import 'package:offload/presentation/home/destination.dart';
import 'package:offload/presentation/people/people_providers.dart';
import 'package:offload/presentation/people/person_screen.dart';
import 'package:offload/presentation/reminders/reminder_providers.dart';
import 'package:offload/presentation/reminders/reminder_sync.dart';
import 'package:offload/presentation/startup/app_storage_provider.dart';

import '../../fakes/drift_widgets.dart';
import '../../fakes/fake_capture_channel.dart';
import '../../fakes/fake_desktop_shell.dart';
import '../../fakes/fake_reminder_scheduler.dart';
import '../../fakes/test_storage.dart';

/// Birthday reminders in the app (T4.6, REQ-031, DD-005).
void main() {
  late AppStorage storage;
  late FakeReminderScheduler scheduler;
  final l10n = lookupAppLocalizations(const Locale('nl'));

  group('the notifications', () {
    final day = LocalDate(2026, 10, 9);
    final anna = Person(
      id: 'a',
      name: 'Anna de Vries',
      birthday: Birthday.tryCreate(9, 10, 1980),
    );
    final bram = Person(
      id: 'b',
      name: 'Bram',
      birthday: Birthday.tryCreate(9, 10),
    );

    test('one person: the name in the title, the age below; the lock screen '
        'never names', () {
      final r = birthdayRemindersOf(
        [
          BirthdayDay(
            day: day,
            at: DateTime(2026, 10, 9, 9),
            personIds: const ['a'],
          ),
        ],
        people: {'a': anna},
        l10n: l10n,
      ).single;
      expect(r.title, 'Anna de Vries is vandaag jarig');
      expect(r.lines, ['wordt 46']);
      expect(r.publicTitle, l10n.birthdayReminderPublic);
      expect(r.open, '${personReminderOpenPrefix}a');
      expect(r.id, 220261009);
    });

    test('more people: the count, the names with an age where known', () {
      final r = birthdayRemindersOf(
        [
          BirthdayDay(
            day: day,
            at: DateTime(2026, 10, 9, 9),
            personIds: const ['a', 'b'],
          ),
        ],
        people: {'a': anna, 'b': bram},
        l10n: l10n,
      ).single;
      expect(r.title, '2 verjaardagen vandaag');
      expect(r.lines, ['Anna de Vries (46)', 'Bram']);
      expect(r.publicTitle, r.title);
      expect(r.open, isEmpty);
    });
  });

  Future<String> startApp(
    WidgetTester tester, {
    bool birthdayToday = true,
    double width = 400,
  }) async {
    tester.view.physicalSize = Size(width, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.localesTestValue = const [Locale('nl')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    storage = await openTestStorage();
    addTearDown(storage.close);
    scheduler = FakeReminderScheduler(granted: true);
    final people = DriftPeopleRepository(storage);
    final id = await people.idFor('Anna de Vries');
    final day = birthdayToday
        ? DateTime.now()
        : DateTime.now().add(const Duration(days: 2));
    await people.setBirthday(id, Birthday.tryCreate(day.day, day.month, 1980));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          destinationProvider.overrideWith((ref) => Destination.today),
          appStorageProvider.overrideWith((ref) => storage),
          captureChannelProvider.overrideWith((ref) => FakeCaptureChannel()),
          desktopShellProvider.overrideWith((ref) => FakeDesktopShell()),
          reminderSchedulerProvider.overrideWithValue(scheduler),
        ],
        child: const OffloadApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    return id;
  }

  testDriftWidgets('Today: a line for a birthday today opens the person', (
    tester,
  ) async {
    await startApp(tester);
    final today = LocalDate.of(DateTime.now());
    final age = today.year - 1980;
    final line = find.text(l10n.todayBirthdayAge('Anna de Vries', age));
    expect(line, findsOneWidget);
    await tester.tap(line);
    await tester.pumpAndSettle();
    expect(find.byType(PersonScreen), findsOneWidget);
  });

  testDriftWidgets('a coming birthday is planned; a tap opens the person; '
      'switched off, nothing', (tester) async {
    final id = await startApp(tester, birthdayToday: false);
    expect(find.textContaining('vandaag jarig'), findsNothing);
    final planned = scheduler.planned.single;
    expect(planned.title, l10n.birthdayReminderOne('Anna de Vries'));
    expect(planned.open, '$personReminderOpenPrefix$id');

    scheduler.tap(planned.open);
    await tester.pumpAndSettle();
    expect(find.byType(PersonScreen), findsOneWidget);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(ReminderSync)),
    );
    await container.read(birthdayRemindersOnProvider.notifier).choose(false);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(scheduler.planned, isEmpty);
    expect(storage.birthdayRemindersOn, isFalse);
  });

  testDriftWidgets(
    'Windows: a tap opens the person in the right pane',
    (tester) async {
      final id = await startApp(tester, birthdayToday: false, width: 1280);
      scheduler.tap(personReminderOpen(id));
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(ReminderSync)),
      );
      expect(container.read(openPersonProvider), id);
      expect(container.read(destinationProvider), Destination.people);
      expect(find.byType(PersonScreen), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );
}
