import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/database/app_database.dart';
import 'package:offload/data/items/drift_item_repository.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/domain/app/open_targets.dart';
import 'package:offload/domain/items/item.dart' as domain;
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/domain/reminders/day_reminders.dart';
import 'package:offload/domain/reminders/review_reminders.dart';
import 'package:offload/domain/time/local_date.dart';
import 'package:offload/l10n/app_localizations.dart';
import 'package:offload/presentation/app.dart';
import 'package:offload/presentation/capture/capture_screen.dart';
import 'package:offload/presentation/capture/pending_captures.dart';
import 'package:offload/presentation/home/destination.dart';
import 'package:offload/presentation/home/item_panes.dart';
import 'package:offload/presentation/items/item_detail_screen.dart';
import 'package:offload/presentation/reminders/reminder_providers.dart';
import 'package:offload/presentation/reminders/reminder_sync.dart';
import 'package:offload/presentation/review/weekly_review_screen.dart';
import 'package:offload/presentation/settings/settings_screen.dart';
import 'package:offload/presentation/startup/app_storage_provider.dart';

import '../../fakes/drift_widgets.dart';
import '../../fakes/fake_capture_channel.dart';
import '../../fakes/fake_desktop_shell.dart';
import '../../fakes/fake_reminder_scheduler.dart';
import '../../fakes/test_storage.dart';

/// Deadline reminders in the app (T4.1, REQ-020, DD-005, DD-018 point 16).
void main() {
  late AppStorage storage;
  late FakeReminderScheduler scheduler;
  final l10n = lookupAppLocalizations(const Locale('nl'));

  group('the notifications of a plan', () {
    String title(String raw) => raw;
    domain.Item item(String id, String text) => domain.Item(
      id: id,
      rawText: text,
      status: ItemStatus.active,
      source: ItemSource.app,
    );
    final day = LocalDate(2026, 10, 9);

    test('one item: its title; a tap opens it', () {
      final reminders = remindersOf(
        [
          ReminderDay(
            day: day,
            at: DateTime(2026, 10, 9, 9),
            deadlineIds: ['a'],
          ),
        ],
        items: {'a': item('a', 'Offerte dakgoot')},
        title: title,
        l10n: l10n,
      );
      expect(reminders.single.title, l10n.reminderTitleOne);
      expect(reminders.single.lines, ['Offerte dakgoot']);
      expect(reminders.single.publicTitle, l10n.reminderTitleOne);
      expect(reminders.single.open, 'a');
      expect(reminders.single.id, 20261009);
    });

    test('more items: the count, five titles and the rest; a tap opens '
        'Today', () {
      final ids = [for (var i = 0; i < 7; i++) 'i$i'];
      final reminders = remindersOf(
        [ReminderDay(day: day, at: DateTime(2026, 10, 9, 9), deadlineIds: ids)],
        items: {for (final id in ids) id: item(id, 'Taak $id')},
        title: title,
        l10n: l10n,
      );
      final r = reminders.single;
      expect(r.title, l10n.reminderTitleMany(7));
      expect(r.lines, [
        for (final id in ids.take(5)) 'Taak $id',
        l10n.reminderMore(2),
      ]);
      expect(r.publicTitle, r.title);
      expect(r.open, isEmpty);
    });

    test('one item back in the inbox: its title; a tap opens it', () {
      final r = remindersOf(
        [
          ReminderDay(
            day: day,
            at: DateTime(2026, 10, 9, 9),
            returningIds: const ['a'],
          ),
        ],
        items: {'a': item('a', 'Fietsenrek ophangen')},
        title: title,
        l10n: l10n,
      ).single;
      expect(r.title, l10n.reminderBackOne);
      expect(r.lines, ['Fietsenrek ophangen']);
      expect(r.publicTitle, l10n.reminderBackOne);
      expect(r.open, 'a');
    });

    test(
      'more back: the count; with deadlines both counts, deadlines first',
      () {
        final back = remindersOf(
          [
            ReminderDay(
              day: day,
              at: DateTime(2026, 10, 9, 9),
              returningIds: const ['b', 'c'],
            ),
          ],
          items: {'b': item('b', 'Cursus'), 'c': item('c', 'Moestuin')},
          title: title,
          l10n: l10n,
        ).single;
        expect(back.title, l10n.reminderBackMany(2));
        expect(back.lines, [
          l10n.reminderBackLine('Cursus'),
          l10n.reminderBackLine('Moestuin'),
        ]);
        expect(back.open, isEmpty);

        final both = remindersOf(
          [
            ReminderDay(
              day: day,
              at: DateTime(2026, 10, 9, 9),
              deadlineIds: const ['a'],
              returningIds: const ['b', 'c'],
            ),
          ],
          items: {
            'a': item('a', 'Contributie overmaken'),
            'b': item('b', 'Cursus'),
            'c': item('c', 'Moestuin'),
          },
          title: title,
          l10n: l10n,
        ).single;
        expect(both.title, l10n.reminderTitleBoth(1, 2));
        expect(both.title, '1 deadline · 2 terug in je inbox');
        expect(both.publicTitle, both.title);
        expect(both.lines, [
          'Contributie overmaken',
          l10n.reminderBackLine('Cursus'),
          l10n.reminderBackLine('Moestuin'),
        ]);
        expect(both.open, isEmpty);
      },
    );

    test('the weekly-review reminder: its title, how long ago, a tap opens '
        'the review', () {
      final reviews = reviewRemindersOf([
        ReviewReminder(day: day, at: DateTime(2026, 10, 9, 16), daysSince: 9),
        ReviewReminder(
          day: day.addDays(7),
          at: DateTime(2026, 10, 16, 16),
          daysSince: null,
        ),
      ], l10n: l10n);
      expect(reviews.first.id, 120261009);
      expect(reviews.first.title, l10n.reviewReminderTitle);
      expect(reviews.first.title, 'Weekoverzicht aan de beurt');
      expect(reviews.first.lines, ['Laatste keer 9 dagen geleden']);
      expect(reviews.first.publicTitle, reviews.first.title);
      expect(reviews.first.open, reviewReminderOpen);
      expect(reviews.last.lines, [l10n.reviewReminderNever]);
    });

    test('its ids to take away have their own range', () {
      final ids = reminderIdsToCancel(
        DateTime(2026, 10, 9, 8),
        16 * 60,
        offset: reviewReminderIdOffset,
      );
      expect(ids.first, 120261009);
    });

    test('a plan takes away only reminders still to come', () {
      // Before 09:00: today's may go, up to a day past the plan.
      final early = reminderIdsToCancel(DateTime(2026, 10, 9, 8), 540);
      expect(early.first, 20261009);
      expect(early.last, 20261109);
      expect(early, hasLength(reminderDaysAhead + 2));
      // After 09:00 today's stays, even if Android has not shown it yet;
      // yesterday's never goes.
      final late = reminderIdsToCancel(DateTime(2026, 10, 9, 9, 5), 540);
      expect(late, isNot(contains(20261009)));
      expect(late, isNot(contains(20261008)));
      expect(late.first, 20261010);
      // Exactly at the time counts as passed.
      expect(
        reminderIdsToCancel(DateTime(2026, 10, 9, 9), 540),
        isNot(contains(20261009)),
      );
    });

    test('a coming deadline or parked item: today or later, open', () {
      domain.Item due(LocalDate d, {ItemStatus status = ItemStatus.active}) =>
          domain.Item(
            id: 'x',
            rawText: 'x',
            status: status,
            source: ItemSource.app,
            dueAt: DateTime.utc(d.year, d.month, d.day),
          );
      final now = DateTime(2026, 10, 9, 10);
      expect(hasComingReminder([due(day)], now), isTrue);
      expect(hasComingReminder([due(day.addDays(90))], now), isTrue);
      expect(hasComingReminder([due(day.addDays(-1))], now), isFalse);
      expect(
        hasComingReminder([due(day, status: ItemStatus.done)], now),
        isFalse,
      );
      expect(hasComingReminder([item('a', 'no deadline')], now), isFalse);
      // Parked until today or later asks too (AC REQ-021).
      domain.Item parked(LocalDate d, ItemStatus status) => domain.Item(
        id: 'p',
        rawText: 'p',
        status: status,
        source: ItemSource.app,
        revisitAt: DateTime.utc(d.year, d.month, d.day),
      );
      expect(
        hasComingReminder([parked(day.addDays(60), ItemStatus.scheduled)], now),
        isTrue,
      );
      expect(
        hasComingReminder([parked(day.addDays(-1), ItemStatus.scheduled)], now),
        isFalse,
      );
      expect(
        hasComingReminder([parked(day.addDays(2), ItemStatus.inbox)], now),
        isFalse,
      );
    });
  });

  Future<String> startApp(
    WidgetTester tester, {
    bool supported = true,
    bool granted = false,
    bool grantOnRequest = false,
    Destination start = Destination.today,
    bool deadline = true,
    double width = 400,
    String? launch,
  }) async {
    tester.view.physicalSize = Size(width, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.localesTestValue = const [Locale('nl')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    storage = await openTestStorage();
    addTearDown(storage.close);
    scheduler = FakeReminderScheduler(
      supported: supported,
      granted: granted,
      grantOnRequest: grantOnRequest,
    )..launchOpened = launch;
    final id = await DriftItemRepository(
      storage,
    ).capture('Offerte dakgoot opvragen', source: ItemSource.app);
    if (deadline) {
      final tomorrow = LocalDate.of(DateTime.now()).addDays(1);
      final db = storage.database;
      await (db.update(db.items)..where((i) => i.id.equals(id))).write(
        ItemsCompanion(
          dueAt: Value(
            DateTime.utc(tomorrow.year, tomorrow.month, tomorrow.day),
          ),
        ),
      );
    }
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          destinationProvider.overrideWith((ref) => start),
          appStorageProvider.overrideWith((ref) => storage),
          captureChannelProvider.overrideWith((ref) => FakeCaptureChannel()),
          desktopShellProvider.overrideWith((ref) => FakeDesktopShell()),
          reminderSchedulerProvider.overrideWithValue(scheduler),
        ],
        child: const OffloadApp(),
      ),
    );
    await tester.pumpAndSettle();
    // The plan follows a moment after the last change.
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    return id;
  }

  testDriftWidgets('a deadline is planned, and the permission asked once', (
    tester,
  ) async {
    final id = await startApp(tester, grantOnRequest: true);
    final planned = scheduler.planned.single;
    expect(planned.title, l10n.reminderTitleOne);
    expect(planned.lines, ['Offerte dakgoot opvragen']);
    expect(planned.open, id);
    expect(planned.at.hour, 9);
    expect(scheduler.channelName, l10n.reminderChannelName);
    expect(scheduler.requests, 1);
    expect(storage.notificationsAsked, isTrue);
    expect(find.text(l10n.reminderRefused), findsNothing);
  });

  testDriftWidgets('after a refusal one message; never asked again', (
    tester,
  ) async {
    await startApp(tester);
    expect(scheduler.requests, 1);
    expect(find.text(l10n.reminderRefused), findsOneWidget);
    await tester.tap(find.text(l10n.reminderRefusedAction));
    await tester.pumpAndSettle();
    expect(scheduler.settingsOpened, 1);

    // A new day of planning asks nothing.
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ReminderSync)),
    );
    await container.read(reminderMinuteProvider.notifier).choose(8 * 60);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(scheduler.planned.single.at.hour, 8);
    expect(scheduler.requests, 1);
  });

  testDriftWidgets('no deadline: nothing planned, nothing asked', (
    tester,
  ) async {
    await startApp(tester, deadline: false);
    expect(scheduler.planned, isEmpty);
    expect(scheduler.requests, 0);
  });

  testDriftWidgets('a tap on a notification opens the item', (tester) async {
    final id = await startApp(tester, granted: true);
    scheduler.tap(id);
    await tester.pumpAndSettle();
    expect(find.byType(ItemDetailScreen), findsOneWidget);
  });

  Destination destination(WidgetTester tester) => ProviderScope.containerOf(
    tester.element(find.byType(ReminderSync)),
  ).read(destinationProvider);

  group('the Offload bar and the app shortcuts (REQ-063)', () {
    testDriftWidgets('Insights opens over an open item', (tester) async {
      final id = await startApp(tester, granted: true);
      scheduler.tap(id);
      await tester.pumpAndSettle();
      expect(find.byType(ItemDetailScreen), findsOneWidget);

      scheduler.tap(openInsightsTarget);
      await tester.pumpAndSettle();
      expect(find.byType(ItemDetailScreen), findsNothing);
      expect(destination(tester), Destination.insights);

      scheduler.tap(openTodayTarget);
      await tester.pumpAndSettle();
      expect(destination(tester), Destination.today);
    });

    testDriftWidgets('a cold start opens on Insights when asked', (
      tester,
    ) async {
      await startApp(tester, granted: true, launch: openInsightsTarget);
      expect(destination(tester), Destination.insights);
    });

    testDriftWidgets('a capture screen with typed text stays on top; an '
        'empty one closes', (tester) async {
      await startApp(tester, granted: true, start: Destination.inbox);
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Fietsband plakken');
      await tester.pump();

      scheduler.tap(openTodayTarget);
      await tester.pumpAndSettle();
      expect(find.byType(CaptureScreen), findsOneWidget);
      expect(find.text('Fietsband plakken'), findsOneWidget);
      // The destination is set underneath.
      expect(destination(tester), Destination.today);

      // So does a reminder for an item: the typed text comes first.
      await tester.enterText(find.byType(TextField), '');
      await tester.pump();
      scheduler.tap(openInsightsTarget);
      await tester.pumpAndSettle();
      expect(find.byType(CaptureScreen), findsNothing);
      expect(destination(tester), Destination.insights);
    });
  });

  testDriftWidgets('Settings: switching off plans nothing; the state of '
      'Android shows', (tester) async {
    await startApp(tester);
    // Close the refusal message, then open Settings.
    ScaffoldMessenger.of(
      tester.element(find.byType(Scaffold).first),
    ).removeCurrentSnackBar();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(l10n.openSettingsTooltip));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text(l10n.settingsRemindersAllow),
      200,
      scrollable: find
          .descendant(
            of: find.byType(SettingsScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    expect(find.text(l10n.settingsRemindersBlocked), findsOneWidget);
    await tester.tap(find.text(l10n.settingsRemindersAllow));
    await tester.pumpAndSettle();
    expect(scheduler.settingsOpened, 1);

    await tester.ensureVisible(find.text(l10n.settingsRemindersOn));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.settingsRemindersOn));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(storage.remindersOn, isFalse);
    expect(scheduler.planned, isEmpty);
  });

  testDriftWidgets('Settings: no section where reminders are not there yet', (
    tester,
  ) async {
    await startApp(tester, supported: false);
    await tester.tap(find.byTooltip(l10n.openSettingsTooltip));
    await tester.pumpAndSettle();
    expect(find.text(l10n.settingsRemindersHeader), findsNothing);
    expect(scheduler.plans, isEmpty);
  });

  testDriftWidgets('Settings: the weekly-review reminder plans its own '
      'notification and asks the permission', (tester) async {
    await startApp(tester, deadline: false, grantOnRequest: true);
    expect(scheduler.requests, 0);
    await tester.tap(find.byTooltip(l10n.openSettingsTooltip));
    await tester.pumpAndSettle();
    final scrollable = find
        .descendant(
          of: find.byType(SettingsScreen),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text(l10n.settingsReviewReminderOn),
      200,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.settingsReviewReminderOn));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(storage.reviewReminderOn, isTrue);
    // Every coming Friday while due; never reviewed, so all of them.
    expect(scheduler.planned.length, greaterThanOrEqualTo(4));
    final review = scheduler.planned.first;
    expect(review.title, l10n.reviewReminderTitle);
    expect(review.open, reviewReminderOpen);
    expect(review.at.weekday, DateTime.friday);
    expect(review.at.hour, 16);
    expect(scheduler.requests, 1);
  });

  testDriftWidgets('a tap on the weekly-review reminder opens the review', (
    tester,
  ) async {
    await startApp(tester, deadline: false, granted: true);
    scheduler.tap(reviewReminderOpen);
    await tester.pumpAndSettle();
    expect(find.byType(WeeklyReviewScreen), findsOneWidget);
  });

  testDriftWidgets(
    'Windows: a click opens the item in the right pane, the review in the '
    'list pane (T4.5)',
    (tester) async {
      final id = await startApp(tester, granted: true, width: 1280);
      scheduler.tap(id);
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(ReminderSync)),
      );
      expect(container.read(selectedItemProvider), id);
      expect(find.byType(ItemDetailScreen), findsOneWidget);

      scheduler.tap(reviewReminderOpen);
      await tester.pumpAndSettle();
      expect(find.byType(WeeklyReviewScreen), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );
}
