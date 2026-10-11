import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/database/app_database.dart';
import 'package:offload/data/items/drift_item_repository.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/domain/time/local_date.dart';
import 'package:offload/domain/tokens/token_processing.dart';
import 'package:offload/l10n/app_localizations.dart';
import 'package:offload/presentation/app.dart';
import 'package:offload/presentation/capture/pending_captures.dart';
import 'package:offload/presentation/inbox/inbox_card.dart';
import 'package:offload/presentation/startup/app_storage_provider.dart';

import '../../fakes/drift_widgets.dart';
import '../../fakes/fake_capture_channel.dart';
import '../../fakes/fake_desktop_shell.dart';
import '../../fakes/test_storage.dart';

/// Today as the start screen and the navigation around it (T2.6, DD-011,
/// DD-018 points 4 and 5).
void main() {
  late AppStorage storage;
  late DriftItemRepository items;
  final l10n = lookupAppLocalizations(const Locale('nl'));

  /// Captures [text] with [status] and a deadline [due] days from today
  /// (none when null); returns its id.
  Future<String> add(
    String text, {
    int? due,
    ItemStatus status = ItemStatus.active,
  }) async {
    final id = await items.capture(text, source: ItemSource.app);
    // Worked out per item, so a run across midnight stays right.
    final today = LocalDate.of(DateTime.now());
    final db = storage.database;
    await (db.update(db.items)..where((i) => i.id.equals(id))).write(
      ItemsCompanion(
        status: Value(status),
        dueAt: Value(due == null ? null : dateOnlyToStored(today.addDays(due))),
      ),
    );
    return id;
  }

  Future<void> startApp(
    WidgetTester tester, {
    Future<void> Function()? seed,
  }) async {
    tester.platformDispatcher.localesTestValue = const [Locale('nl')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    storage = await openTestStorage();
    addTearDown(storage.close);
    items = DriftItemRepository(storage);
    await seed?.call();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appStorageProvider.overrideWith((ref) => storage),
          captureChannelProvider.overrideWith((ref) => FakeCaptureChannel()),
          desktopShellProvider.overrideWith((ref) => FakeDesktopShell()),
        ],
        child: const OffloadApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Item [id] as stored; read directly, a watched query would wait on a
  /// timer in the test's fake time.
  Future<Item> stored(String id) => (storage.database.select(
    storage.database.items,
  )..where((i) => i.id.equals(id))).getSingle();

  late String late;
  late String due;
  Future<void> seed() async {
    late = await add('Rapport afronden', due: -2, status: ItemStatus.waiting);
    due = await add('Ketel keuren', due: 0, status: ItemStatus.inbox);
    await add('Later', due: 3);
    await add('Zonder deadline');
    await add('Al klaar', due: -1, status: ItemStatus.done);
  }

  testDriftWidgets('the app starts on Today, with nothing due', (tester) async {
    await startApp(tester);
    expect(find.widgetWithText(AppBar, l10n.navToday), findsOneWidget);
    expect(find.text(l10n.todayEmptyTitle), findsOneWidget);
    expect(find.text(l10n.todayEmptyText), findsOneWidget);
    // An empty inbox has no line.
    expect(find.text(l10n.todayProcess), findsNothing);
  });

  testDriftWidgets('overdue and today in two sections, the inbox line above', (
    tester,
  ) async {
    await startApp(tester, seed: seed);
    expect(find.text(l10n.todayOverdue(1)), findsOneWidget);
    expect(find.text(l10n.todayDueToday(1)), findsOneWidget);
    expect(find.text('Rapport afronden'), findsOneWidget);
    expect(find.text('Ketel keuren'), findsOneWidget);
    expect(find.text('Later'), findsNothing);
    expect(find.text('Zonder deadline'), findsNothing);
    expect(find.text('Al klaar'), findsNothing);
    // The status shows, the inbox too: items from several places meet.
    Finder onCard(String text) =>
        find.descendant(of: find.byType(InboxCard), matching: find.text(text));
    expect(onCard(l10n.itemStatusWaiting), findsOneWidget);
    expect(onCard(l10n.itemStatusInbox), findsOneWidget);
    // Overdue comes first.
    expect(
      tester.getTopLeft(find.text('Rapport afronden')).dy,
      lessThan(tester.getTopLeft(find.text('Ketel keuren')).dy),
    );
    // One item in the inbox: the others were given another status.
    expect(find.text(l10n.todayInboxLine(1)), findsOneWidget);
  });

  testDriftWidgets('swiping right completes; undo puts back the status', (
    tester,
  ) async {
    await startApp(tester, seed: seed);
    await tester.drag(find.text('Rapport afronden'), const Offset(600, 0));
    await tester.pumpAndSettle();
    expect(find.text('Rapport afronden'), findsNothing);
    expect(find.text(l10n.itemCompleted), findsOneWidget);
    expect((await stored(late)).status, ItemStatus.done);

    await tester.tap(find.text(l10n.itemUndo));
    await tester.pumpAndSettle();
    expect(find.text('Rapport afronden'), findsOneWidget);
    // Back to waiting, not to active: the exact status it had.
    expect((await stored(late)).status, ItemStatus.waiting);
  });

  testDriftWidgets(
    'undo of completing an inbox item puts it back in the inbox',
    (tester) async {
      await startApp(tester, seed: seed);
      await tester.drag(find.text('Ketel keuren'), const Offset(600, 0));
      await tester.pumpAndSettle();
      expect((await stored(due)).status, ItemStatus.done);
      await tester.tap(find.text(l10n.itemUndo));
      await tester.pumpAndSettle();
      expect((await stored(due)).status, ItemStatus.inbox);
    },
  );

  testDriftWidgets('swiping left sends to the trash, with undo', (
    tester,
  ) async {
    await startApp(tester, seed: seed);
    await tester.drag(find.text('Ketel keuren'), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.text(l10n.itemMovedToTrash), findsOneWidget);
    expect((await stored(due)).deletedAt, isNotNull);
    await tester.tap(find.text(l10n.itemUndo));
    await tester.pumpAndSettle();
    expect((await stored(due)).deletedAt, isNull);
    expect(find.text('Ketel keuren'), findsOneWidget);
  });

  testDriftWidgets('the inbox line goes to the Inbox; back returns to Today', (
    tester,
  ) async {
    await startApp(tester, seed: seed);
    await tester.tap(find.text(l10n.todayInboxLine(1)));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, l10n.inboxTitle), findsOneWidget);

    // Android back: from the Inbox to Today, not out of the app.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, l10n.navToday), findsOneWidget);
  });

  testDriftWidgets('Process starts triage, which comes back to Today', (
    tester,
  ) async {
    await startApp(tester, seed: seed);
    await tester.tap(find.text(l10n.todayProcess));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.itemTypeTask));
    await tester.pumpAndSettle();
    expect(find.text(l10n.triageDoneTitle), findsOneWidget);
    await tester.tap(find.text(l10n.triageBack));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, l10n.navToday), findsOneWidget);
  });

  testDriftWidgets('the bottom bar: Today and Inbox, with the count', (
    tester,
  ) async {
    await startApp(tester, seed: seed);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp(l10n.navInboxBadge(1))),
      findsOneWidget,
    );
    await tester.tap(find.text(l10n.inboxTitle).last);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, l10n.inboxTitle), findsOneWidget);
  });

  testDriftWidgets(
    'Windows: a rail with capture and Settings; no swiping',
    (tester) async {
      await startApp(tester, seed: seed);
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.byTooltip(l10n.captureAction), findsOneWidget);
      expect(find.byTooltip(l10n.settingsTitle), findsOneWidget);
      // Settings sits in the rail, not in the top bar.
      expect(find.byTooltip(l10n.openSettingsTooltip), findsNothing);
      expect(find.byType(Dismissible), findsNothing);
      await tester.drag(find.text('Ketel keuren'), const Offset(600, 0));
      await tester.pumpAndSettle();
      expect((await stored(due)).status, ItemStatus.inbox);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );
}
