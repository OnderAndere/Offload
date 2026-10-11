import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/database/app_database.dart';
import 'package:offload/data/items/drift_item_repository.dart';
import 'package:offload/data/people/drift_people_repository.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/domain/items/item_classification.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/domain/sync/hlc.dart';
import 'package:offload/l10n/app_localizations.dart';
import 'package:offload/presentation/app.dart';
import 'package:offload/presentation/capture/pending_captures.dart';
import 'package:offload/presentation/home/destination.dart';
import 'package:offload/presentation/inbox/inbox_card.dart';
import 'package:offload/presentation/review/weekly_review_screen.dart';
import 'package:offload/presentation/settings/settings_screen.dart';
import 'package:offload/presentation/startup/app_storage_provider.dart';

import '../../fakes/drift_widgets.dart';
import '../../fakes/fake_capture_channel.dart';
import '../../fakes/fake_desktop_shell.dart';
import '../../fakes/test_storage.dart';

/// The weekly review (T3.4 + T10.6 step B, REQ-013, AC REQ-051, DD-018
/// point 8).
void main() {
  late AppStorage storage;
  late DriftItemRepository items;
  final l10n = lookupAppLocalizations(const Locale('nl'));
  final windows = TargetPlatformVariant.only(TargetPlatform.windows);

  Future<void> startApp(
    WidgetTester tester, {
    Future<void> Function()? data,
    double width = 400,
    double height = 1000,
    Destination start = Destination.today,
    DateTime? now,
  }) async {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.localesTestValue = const [Locale('nl')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    storage = await openTestStorage();
    addTearDown(storage.close);
    items = DriftItemRepository(storage);
    if (data != null) await data();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          destinationProvider.overrideWith((ref) => start),
          appStorageProvider.overrideWith((ref) => storage),
          captureChannelProvider.overrideWith((ref) => FakeCaptureChannel()),
          desktopShellProvider.overrideWith((ref) => FakeDesktopShell()),
          // A fixed day for Today, so an age in days never moves at midnight.
          if (now != null)
            minuteClockProvider.overrideWith((ref) => Stream.value(now)),
        ],
        child: const OffloadApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// An item in [status], last changed [daysAgo] days ago: its HLC says so.
  Future<String> add(
    String text, {
    ItemStatus status = ItemStatus.active,
    int daysAgo = 0,
    String? waitingOn,
  }) async {
    final id = await items.capture(text, source: ItemSource.app);
    await items.classify(
      id,
      ItemClassification(
        type: ItemType.task,
        status: status,
        requesterId: null,
        waitingOnId: waitingOn,
      ),
    );
    final then = DateTime.now().toUtc().subtract(Duration(days: daysAgo));
    final db = storage.database;
    await (db.update(db.items)..where((i) => i.id.equals(id))).write(
      ItemsCompanion(
        hlc: Value(Hlc(then.millisecondsSinceEpoch, 0, 'test').pack()),
      ),
    );
    return id;
  }

  /// The item row, read once (never a watched stream in a widget test).
  Future<Item> row(String id) => (storage.database.select(
    storage.database.items,
  )..where((i) => i.id.equals(id))).getSingle();

  Future<void> openReview(WidgetTester tester) async {
    await tester.tap(
      find.widgetWithIcon(IconButton, Icons.fact_check_outlined),
    );
    await tester.pumpAndSettle();
  }

  /// The first step is the Overview (DD-018 point 12 (g)): Continue.
  Future<void> pastInsights(WidgetTester tester) async {
    expect(find.text(l10n.reviewStepInsights), findsWidgets);
    await tester.tap(find.text(l10n.reviewContinue));
    await tester.pumpAndSettle();
  }

  testDriftWidgets('the start screen: five steps with what is there', (
    tester,
  ) async {
    await startApp(
      tester,
      data: () async {
        await items.capture('Nieuw', source: ItemSource.app);
        await add('Oud idee', daysAgo: 40);
      },
    );
    await openReview(tester);
    expect(find.byType(WeeklyReviewScreen), findsOneWidget);
    // The Overview first, always with its summary.
    expect(find.text(l10n.reviewStepInsights), findsOneWidget);
    expect(find.text(l10n.reviewInsightsSummary), findsOneWidget);
    expect(find.text(l10n.reviewInboxCount(1)), findsOneWidget);
    // Waiting for and deadlines have nothing to do.
    expect(find.text(l10n.reviewNothing), findsNWidgets(2));
    // The new inbox item is not stale; the old idea is.
    expect(find.text(l10n.reviewStaleCount(1, 3)), findsOneWidget);
  });

  testDriftWidgets('waiting for: still waiting and done; the card stays', (
    tester,
  ) async {
    late String rapport;
    late String offerte;
    await startApp(
      tester,
      data: () async {
        final petra = await DriftPeopleRepository(storage).idFor('Petra');
        rapport = await add(
          'Rapport',
          status: ItemStatus.waiting,
          waitingOn: petra,
          daysAgo: 9,
        );
        offerte = await add(
          'Offerte',
          status: ItemStatus.waiting,
          waitingOn: petra,
          daysAgo: 2,
        );
      },
    );
    await openReview(tester);
    await tester.tap(find.text(l10n.reviewStart));
    await tester.pumpAndSettle();
    await pastInsights(tester);
    expect(find.text(l10n.reviewStepWaiting), findsOneWidget);
    expect(find.text(l10n.reviewAgeDays(9)), findsOneWidget);

    await tester.tap(find.text(l10n.reviewStillWaiting).first);
    await tester.pumpAndSettle();
    expect((await row(rapport)).reviewedAt, isNotNull);
    expect(find.text(l10n.reviewHandledWaiting), findsOneWidget);

    await tester.tap(find.text(l10n.itemComplete));
    await tester.pumpAndSettle();
    expect((await row(offerte)).status, ItemStatus.done);
    expect(find.text(l10n.reviewHandledDone), findsOneWidget);
    // Both cards stay in view.
    expect(find.text('Rapport'), findsOneWidget);
    expect(find.text('Offerte'), findsOneWidget);
  });

  testDriftWidgets('stale: keep, archive with undo; empty steps skipped', (
    tester,
  ) async {
    late String keep;
    late String archive;
    await startApp(
      tester,
      data: () async {
        keep = await add('Cursus bekijken', daysAgo: 50);
        archive = await add('Oud idee', daysAgo: 30);
      },
    );
    await openReview(tester);
    await tester.tap(find.text(l10n.reviewStart));
    await tester.pumpAndSettle();
    await pastInsights(tester);
    // Straight to step 4: the others have nothing.
    expect(find.text(l10n.reviewStepStale), findsOneWidget);
    expect(
      find.text(l10n.reviewStaleHeader(3, 2).toUpperCase()),
      findsOneWidget,
    );
    expect(find.text(l10n.reviewAgeWeeks(7)), findsOneWidget);

    await tester.tap(find.text(l10n.reviewKeep).first);
    await tester.pumpAndSettle();
    expect((await row(keep)).reviewedAt, isNotNull);

    await tester.tap(find.text(l10n.reviewArchive));
    await tester.pumpAndSettle();
    expect((await row(archive)).status, ItemStatus.archived);
    await tester.tap(find.text(l10n.itemUndo));
    await tester.pumpAndSettle();
    expect((await row(archive)).status, ItemStatus.active);

    await tester.tap(find.text(l10n.reviewFinish));
    await tester.pumpAndSettle();
    expect(find.text(l10n.reviewEndTitle), findsOneWidget);
    expect(find.text(l10n.reviewEndKept(1)), findsOneWidget);
    await tester.tap(find.text(l10n.reviewEndBack));
    await tester.pumpAndSettle();
    expect(find.byType(WeeklyReviewScreen), findsNothing);
  });

  testDriftWidgets('Settings: stale after is a choice of weeks', (
    tester,
  ) async {
    await startApp(tester, height: 1800);
    await tester.tap(find.byTooltip(l10n.openSettingsTooltip));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
    await tester.tap(find.byType(DropdownButton<int>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.settingsWeeks(5)).last);
    await tester.pumpAndSettle();
    expect(storage.staleAfterWeeks, 5);
  });

  testDriftWidgets('Settings: due again after is a choice of days', (
    tester,
  ) async {
    await startApp(tester, height: 1800);
    await tester.tap(find.byTooltip(l10n.openSettingsTooltip));
    await tester.pumpAndSettle();
    expect(find.text(l10n.settingsReviewDueAfter), findsOneWidget);
    // The dropdown of this setting, not the one of "Oud na" below it.
    final dropdown = find.descendant(
      of: find.widgetWithText(ListTile, l10n.settingsReviewDueAfter),
      matching: find.byType(DropdownButton<int>),
    );
    await tester.ensureVisible(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.settingsDays(14)).last);
    await tester.pumpAndSettle();
    expect(storage.reviewDueAfterDays, 14);
  });

  group('the entry on Today (DD-018 points 4 and 8)', () {
    Finder reviewIcon() =>
        find.widgetWithIcon(IconButton, Icons.fact_check_outlined);

    testDriftWidgets('an icon with a tooltip, and no menu any more', (
      tester,
    ) async {
      await startApp(tester);
      expect(reviewIcon(), findsOneWidget);
      expect(find.byTooltip(l10n.reviewTitle), findsOneWidget);
      expect(find.byType(PopupMenuButton<void>), findsNothing);
      await tester.tap(reviewIcon());
      await tester.pumpAndSettle();
      expect(find.byType(WeeklyReviewScreen), findsOneWidget);
    });

    testDriftWidgets('never reviewed: the line says so and starts the '
        'review; the end screen completes it and the line goes', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await startApp(tester);
      expect(find.text(l10n.todayReviewLineNever), findsOneWidget);
      expect(
        find.bySemanticsLabel(l10n.todayReviewLineNeverLabel),
        findsOneWidget,
      );
      await tester.tap(find.text(l10n.todayReviewLineNever));
      await tester.pumpAndSettle();
      expect(find.byType(WeeklyReviewScreen), findsOneWidget);
      // Nothing to do anywhere: Start goes straight to the end screen.
      await tester.tap(find.text(l10n.reviewStart));
      await tester.pumpAndSettle();
      await pastInsights(tester);
      expect(find.text(l10n.reviewEndTitle), findsOneWidget);
      expect(storage.lastReviewCompletedAt, isNotNull);
      await tester.tap(find.text(l10n.reviewEndBack));
      await tester.pumpAndSettle();
      expect(find.text(l10n.todayReviewLineNever), findsNothing);
      semantics.dispose();
    });

    testDriftWidgets('ending halfway does not complete the review', (
      tester,
    ) async {
      await startApp(tester);
      await tester.tap(reviewIcon());
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(l10n.reviewClose));
      await tester.pumpAndSettle();
      expect(storage.lastReviewCompletedAt, isNull);
      expect(find.text(l10n.todayReviewLineNever), findsOneWidget);
    });

    testDriftWidgets('9 days ago: the line gives the age', (tester) async {
      final semantics = tester.ensureSemantics();
      await startApp(
        tester,
        now: DateTime(2025, 3, 10, 9),
        data: () => storage.saveLastReviewCompletedAt(DateTime(2025, 3, 1, 12)),
      );
      expect(find.text(l10n.todayReviewLine(9)), findsOneWidget);
      expect(
        find.bySemanticsLabel(l10n.todayReviewLineLabel(9)),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testDriftWidgets('reviewed 3 days ago: no line', (tester) async {
      await startApp(
        tester,
        now: DateTime(2025, 3, 10, 9),
        data: () => storage.saveLastReviewCompletedAt(DateTime(2025, 3, 7, 12)),
      );
      // No line with any age: its icon is missing, only the top bar has one.
      expect(find.byIcon(Icons.fact_check_outlined), findsOneWidget);
      expect(reviewIcon(), findsOneWidget);
    });

    testDriftWidgets('Windows: the tooltip names the key', (tester) async {
      await startApp(tester, width: 1280);
      expect(find.byTooltip(l10n.reviewStartTooltipWithKey), findsOneWidget);
    }, variant: windows);
  });

  testDriftWidgets(
    'Windows: Ctrl+Shift+W opens the review; it is a mode; Esc ends it',
    (tester) async {
      await startApp(
        tester,
        width: 1280,
        data: () async => add('Oud idee', daysAgo: 30),
      );
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyW);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pumpAndSettle();
      expect(find.byType(WeeklyReviewScreen), findsOneWidget);

      // Ctrl+2 does nothing while the review is open.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pumpAndSettle();
      expect(find.byType(WeeklyReviewScreen), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(WeeklyReviewScreen), findsNothing);
    },
    variant: windows,
  );

  testDriftWidgets(
    'Windows: in a step the keys work at once; 1 keeps, Del trashes',
    (tester) async {
      late String keep;
      late String trash;
      await startApp(
        tester,
        width: 1280,
        data: () async {
          keep = await add('Cursus bekijken', daysAgo: 50);
          trash = await add('Oud idee', daysAgo: 30);
        },
      );
      await openReview(tester);
      await tester.tap(find.text(l10n.reviewStart));
      await tester.pumpAndSettle();
      await pastInsights(tester);
      expect(find.text(l10n.reviewStepStale), findsOneWidget);

      // No click first: the list has the focus.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
      await tester.pumpAndSettle();
      expect((await row(keep)).reviewedAt, isNotNull);

      // The selection moved to the next card.
      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await tester.pumpAndSettle();
      expect((await row(trash)).deletedAt, isNotNull);

      // The search field is off during the review.
      final search = tester.widget<TextField>(
        find.widgetWithText(TextField, l10n.searchHint),
      );
      expect(search.enabled, isFalse);
    },
    variant: windows,
  );

  testDriftWidgets(
    'Windows: → and Esc work in a step without a list and on the end screen',
    (tester) async {
      await startApp(
        tester,
        width: 1280,
        data: () async {
          await items.capture('Nieuw', source: ItemSource.app);
          await add('Oud idee', daysAgo: 30);
        },
      );
      await openReview(tester);
      await tester.tap(find.text(l10n.reviewStart));
      await tester.pumpAndSettle();
      // The Overview first (DD-018 point 12 (g)); → goes on from there.
      // In the review, not the rail.
      expect(
        find.descendant(
          of: find.byType(WeeklyReviewScreen),
          matching: find.text(l10n.reviewStepInsights),
        ),
        findsOneWidget,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(find.text(l10n.reviewStepInbox), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(find.text(l10n.reviewStepStale), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(find.text(l10n.reviewEndTitle), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(WeeklyReviewScreen), findsNothing);
    },
    variant: windows,
  );

  testDriftWidgets(
    'Windows: opened with Ctrl+Shift+W while the Today list has the focus',
    (tester) async {
      await startApp(
        tester,
        width: 1280,
        data: () async {
          final id = await add('Vandaag doen');
          final db = storage.database;
          await (db.update(db.items)..where((i) => i.id.equals(id))).write(
            ItemsCompanion(dueAt: Value(DateTime.now().toUtc())),
          );
        },
      );
      // The Today list has the focus: ↓ selects its card.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyW);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pumpAndSettle();
      expect(find.byType(WeeklyReviewScreen), findsOneWidget);
      final focus = FocusManager.instance.primaryFocus?.context;
      expect(
        focus != null &&
            focus.findAncestorWidgetOfExactType<WeeklyReviewScreen>() != null,
        isTrue,
        reason: 'the review has the focus',
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(WeeklyReviewScreen), findsNothing);
    },
    variant: windows,
  );

  testDriftWidgets('stale: Later… parks with undo; the end counts it', (
    tester,
  ) async {
    late String later;
    await startApp(
      tester,
      data: () async {
        later = await add('Moestuinbak bijvullen', daysAgo: 50);
      },
    );
    await openReview(tester);
    await tester.tap(find.text(l10n.reviewStart));
    await tester.pumpAndSettle();
    await pastInsights(tester);
    expect(find.text(l10n.reviewStepStale), findsOneWidget);

    await tester.tap(find.text(l10n.revisitLater));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.revisitNextWeek));
    await tester.pumpAndSettle();
    expect((await row(later)).status, ItemStatus.scheduled);
    expect(find.textContaining('✓ Terug op'), findsOneWidget);

    await tester.tap(find.text(l10n.itemUndo));
    await tester.pumpAndSettle();
    expect((await row(later)).status, ItemStatus.active);
    expect((await row(later)).revisitAt, isNull);
    expect(find.text(l10n.revisitLater), findsOneWidget);

    await tester.tap(find.text(l10n.revisitLater));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.revisitTomorrow));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.reviewFinish));
    await tester.pumpAndSettle();
    expect(find.text(l10n.reviewEndParked(1)), findsOneWidget);
  });
}
