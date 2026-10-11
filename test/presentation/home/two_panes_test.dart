import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/database/app_database.dart';
import 'package:offload/data/items/drift_item_repository.dart';
import 'package:offload/data/search/drift_search_index.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/domain/ids/uuid_v7.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/domain/time/local_date.dart';
import 'package:offload/domain/tokens/token_processing.dart';
import 'package:offload/l10n/app_localizations.dart';
import 'package:offload/presentation/app.dart';
import 'package:offload/presentation/capture/capture_screen.dart';
import 'package:offload/presentation/capture/pending_captures.dart';
import 'package:offload/presentation/home/list_keys.dart';
import 'package:offload/presentation/items/item_detail_screen.dart';
import 'package:offload/presentation/startup/app_storage_provider.dart';
import 'package:offload/presentation/triage/triage_screen.dart';

import '../../fakes/drift_widgets.dart';
import '../../fakes/fake_capture_channel.dart';
import '../../fakes/fake_desktop_shell.dart';
import '../../fakes/test_storage.dart';

/// The Windows two panes, the search field and the keys (T2.6 step B,
/// DD-018 point 5).
void main() {
  late AppStorage storage;
  late DriftItemRepository items;
  late FakeCaptureChannel channel;
  final l10n = lookupAppLocalizations(const Locale('nl'));

  /// Captured one minute apart, in this order; ids by text.
  final ids = <String, String>{};

  Future<void> add(String text, {int? due, ItemStatus? status}) async {
    final at = DateTime.now().subtract(Duration(minutes: 10 - ids.length));
    final id = UuidV7Generator(now: () => at.millisecondsSinceEpoch).next();
    await items.captureWithId(id, text, source: ItemSource.app);
    final db = storage.database;
    final today = LocalDate.of(DateTime.now());
    await (db.update(db.items)..where((i) => i.id.equals(id))).write(
      ItemsCompanion(
        status: status == null ? const Value.absent() : Value(status),
        dueAt: due == null
            ? const Value.absent()
            : Value(dateOnlyToStored(today.addDays(due))),
      ),
    );
    ids[text] = id;
  }

  Future<void> startApp(
    WidgetTester tester, {
    double width = 1280,
    int extraInbox = 0,
  }) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.localesTestValue = const [Locale('nl')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    storage = await openTestStorage();
    addTearDown(storage.close);
    items = DriftItemRepository(storage);
    channel = FakeCaptureChannel();
    ids.clear();
    // Today: overdue first, then today. The inbox: newest first.
    await add('Rapport afronden', due: -1, status: ItemStatus.active);
    await add('Offerte nakijken', due: 0, status: ItemStatus.active);
    await add('Bel Jan');
    await add('Markt plannen');
    for (var i = 0; i < extraInbox; i++) {
      await add('Extra $i');
    }
    await DriftSearchIndex(storage.database).processPending();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appStorageProvider.overrideWith((ref) => storage),
          captureChannelProvider.overrideWith((ref) => channel),
          desktopShellProvider.overrideWith((ref) => FakeDesktopShell()),
        ],
        child: const OffloadApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<Item> stored(String text) => (storage.database.select(
    storage.database.items,
  )..where((i) => i.id.equals(ids[text]!))).getSingle();

  /// The item the detail pane shows, or null when it shows none.
  String? detail(WidgetTester tester) {
    final panes = find.byWidgetPredicate(
      (w) => w is ItemDetailScreen && w.embedded,
    );
    if (panes.evaluate().isEmpty) return null;
    return tester.widget<ItemDetailScreen>(panes).itemId;
  }

  Future<void> key(
    WidgetTester tester,
    LogicalKeyboardKey key, {
    bool control = false,
  }) async {
    if (control) await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
    await tester.sendKeyEvent(key);
    if (control) await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
    await tester.pumpAndSettle();
  }

  /// The text field with the focus, or null when no text field has it.
  EditableText? focusedText() => FocusManager.instance.primaryFocus?.context
      ?.findAncestorWidgetOfExactType<EditableText>();

  final windows = TargetPlatformVariant.only(TargetPlatform.windows);

  testDriftWidgets(
    'wide: the list with the detail beside it, nothing chosen at first',
    (tester) async {
      await startApp(tester);
      expect(find.text(l10n.panesChooseItem), findsOneWidget);
      expect(find.widgetWithText(TextField, l10n.searchHint), findsOneWidget);
      await tester.tap(find.text('Offerte nakijken'));
      await tester.pumpAndSettle();
      expect(detail(tester), ids['Offerte nakijken']);
      // The list stays beside it.
      expect(find.text('Rapport afronden'), findsOneWidget);
      expect(find.text(l10n.panesChooseItem), findsNothing);
    },
    variant: windows,
  );

  testDriftWidgets(
    'arrows select, Enter goes to the text, Escape back to the list',
    (tester) async {
      await startApp(tester);
      await key(tester, LogicalKeyboardKey.arrowDown);
      expect(detail(tester), ids['Rapport afronden']);
      await key(tester, LogicalKeyboardKey.arrowDown);
      expect(detail(tester), ids['Offerte nakijken']);
      await key(tester, LogicalKeyboardKey.arrowUp);
      expect(detail(tester), ids['Rapport afronden']);

      await key(tester, LogicalKeyboardKey.enter);
      expect(focusedText()?.controller.text, 'Rapport afronden');

      await key(tester, LogicalKeyboardKey.escape);
      expect(focusedText(), isNull);
      // The list keys work again.
      await key(tester, LogicalKeyboardKey.arrowDown);
      expect(detail(tester), ids['Offerte nakijken']);
    },
    variant: windows,
  );

  testDriftWidgets(
    'Delete trashes the selected card, with undo; the next is selected',
    (tester) async {
      await startApp(tester);
      await key(tester, LogicalKeyboardKey.arrowDown);
      await key(tester, LogicalKeyboardKey.delete);
      expect((await stored('Rapport afronden')).deletedAt, isNotNull);
      expect(find.text(l10n.itemMovedToTrash), findsOneWidget);
      expect(detail(tester), ids['Offerte nakijken']);
      await tester.tap(find.text(l10n.itemUndo));
      await tester.pumpAndSettle();
      expect((await stored('Rapport afronden')).deletedAt, isNull);
    },
    variant: windows,
  );

  testDriftWidgets(
    'Ctrl+Enter completes from the list on Today, not in the Inbox',
    (tester) async {
      await startApp(tester);
      await key(tester, LogicalKeyboardKey.arrowDown);
      await key(tester, LogicalKeyboardKey.enter, control: true);
      expect((await stored('Rapport afronden')).status, ItemStatus.done);
      expect(find.text(l10n.itemCompleted), findsOneWidget);
      expect(detail(tester), ids['Offerte nakijken']);

      await key(tester, LogicalKeyboardKey.digit2, control: true);
      expect(find.widgetWithText(AppBar, l10n.inboxTitle), findsOneWidget);
      // Switching clears the selection.
      expect(detail(tester), isNull);
      await key(tester, LogicalKeyboardKey.arrowDown);
      expect(detail(tester), ids['Markt plannen']);
      await key(tester, LogicalKeyboardKey.enter, control: true);
      expect((await stored('Markt plannen')).status, ItemStatus.inbox);
    },
    variant: windows,
  );

  testDriftWidgets('Ctrl+1/2 switch destination, also from a text field', (
    tester,
  ) async {
    await startApp(tester);
    await tester.tap(find.widgetWithText(TextField, l10n.searchHint));
    await tester.pumpAndSettle();
    await key(tester, LogicalKeyboardKey.digit2, control: true);
    expect(find.widgetWithText(AppBar, l10n.inboxTitle), findsOneWidget);
    await key(tester, LogicalKeyboardKey.digit1, control: true);
    expect(find.widgetWithText(AppBar, l10n.navToday), findsOneWidget);
  }, variant: windows);

  test('equal ids give equal card keys, so cards keep their element', () {
    expect(ListKeys.cardKey('a'), ListKeys.cardKey('a'));
    expect(ListKeys.cardKey('a').hashCode, ListKeys.cardKey('a').hashCode);
    expect(ListKeys.cardKey('a'), isNot(ListKeys.cardKey('b')));
  });

  testDriftWidgets('a card selected below the window scrolls into view', (
    tester,
  ) async {
    await startApp(tester, extraInbox: 20);
    await key(tester, LogicalKeyboardKey.digit2, control: true);
    for (var i = 0; i < 18; i++) {
      await key(tester, LogicalKeyboardKey.arrowDown);
    }
    final id = detail(tester);
    final text = ids.entries.firstWhere((e) => e.value == id).key;
    final card = find.descendant(
      of: find.byType(ListView),
      matching: find.text(text),
    );
    expect(card.hitTestable(), findsOneWidget);
  }, variant: windows);

  testDriftWidgets(
    'an item opened in a narrow window closes when the window gets wide',
    (tester) async {
      await startApp(tester, width: 800);
      await key(tester, LogicalKeyboardKey.arrowDown);
      await key(tester, LogicalKeyboardKey.enter);
      expect(find.byType(ItemDetailScreen), findsOneWidget);
      expect(detail(tester), isNull);

      tester.view.physicalSize = const Size(1280, 800);
      await tester.pumpAndSettle();
      // One editor: the pane, not the screen over the list as well.
      expect(find.byType(ItemDetailScreen), findsOneWidget);
      expect(detail(tester), ids['Rapport afronden']);
    },
    variant: windows,
  );

  testDriftWidgets(
    'an item opened from triage stays open when a wide window is resized',
    (tester) async {
      await startApp(tester);
      await tester.tap(find.text(l10n.todayProcess));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.triageOpen));
      await tester.pumpAndSettle();
      expect(find.byType(ItemDetailScreen), findsOneWidget);

      tester.view.physicalSize = const Size(1400, 800);
      await tester.pumpAndSettle();
      expect(find.byType(ItemDetailScreen), findsOneWidget);
      expect(find.byType(TriageScreen), findsNothing);
    },
    variant: windows,
  );

  testDriftWidgets('Ctrl+N captures', (tester) async {
    await startApp(tester);
    await key(tester, LogicalKeyboardKey.keyN, control: true);
    expect(find.byType(CaptureScreen), findsOneWidget);
  }, variant: windows);

  testDriftWidgets(
    'Ctrl+F searches; a result opens in the detail pane; Escape empties',
    (tester) async {
      await startApp(tester);
      await key(tester, LogicalKeyboardKey.keyF, control: true);
      expect(focusedText(), isNotNull);
      await tester.enterText(
        find.widgetWithText(TextField, l10n.searchHint),
        'markt',
      );
      await tester.pumpAndSettle();
      // The results take the place of the list.
      expect(find.text('Rapport afronden'), findsNothing);
      await tester.tap(find.text('Markt plannen'));
      await tester.pumpAndSettle();
      expect(detail(tester), ids['Markt plannen']);

      await tester.tap(find.widgetWithText(TextField, 'markt'));
      await key(tester, LogicalKeyboardKey.escape);
      expect(find.text('Rapport afronden'), findsOneWidget);
    },
    variant: windows,
  );

  testDriftWidgets(
    'narrow: one pane; an item opens over the list, the rail stays',
    (tester) async {
      await startApp(tester, width: 800);
      expect(find.text(l10n.panesChooseItem), findsNothing);
      await tester.tap(find.text('Offerte nakijken'));
      await tester.pumpAndSettle();
      expect(find.byType(ItemDetailScreen), findsOneWidget);
      expect(detail(tester), isNull);
      expect(find.byType(NavigationRail), findsOneWidget);
      // Switching destination closes the item.
      await tester.tap(find.text(l10n.inboxTitle).first);
      await tester.pumpAndSettle();
      expect(find.byType(ItemDetailScreen), findsNothing);
      expect(find.widgetWithText(AppBar, l10n.inboxTitle), findsOneWidget);
    },
    variant: windows,
  );

  testDriftWidgets('during triage Ctrl+2 does nothing; the rail stays', (
    tester,
  ) async {
    await startApp(tester);
    await tester.tap(find.text(l10n.todayProcess));
    await tester.pumpAndSettle();
    expect(find.byType(TriageScreen), findsOneWidget);
    expect(find.byType(NavigationRail), findsOneWidget);
    await key(tester, LogicalKeyboardKey.digit2, control: true);
    expect(find.byType(TriageScreen), findsOneWidget);
    await key(tester, LogicalKeyboardKey.escape);
    expect(find.byType(TriageScreen), findsNothing);
    expect(find.widgetWithText(AppBar, l10n.navToday), findsOneWidget);
  }, variant: windows);

  testDriftWidgets(
    'the hotkey opens capture over Today at once (hard rule 7)',
    (tester) async {
      await startApp(tester);
      channel.requestCapture(ItemSource.hotkey);
      await tester.pumpAndSettle();
      expect(find.byType(CaptureScreen), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Via de sneltoets');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      // Back where it was: Today, not another destination.
      expect(find.byType(CaptureScreen), findsNothing);
      expect(find.widgetWithText(AppBar, l10n.navToday), findsOneWidget);
    },
    variant: windows,
  );
}
