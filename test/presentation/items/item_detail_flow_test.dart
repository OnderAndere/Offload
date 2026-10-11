import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/database/app_database.dart' hide SearchIndex;
import 'package:offload/data/items/drift_item_repository.dart';
import 'package:offload/data/projects/drift_project_repository.dart';
import 'package:offload/data/search/drift_search_index.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/data/tokens/drift_token_processor.dart';
import 'package:offload/domain/ids/uuid_v7.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/domain/time/local_date.dart';
import 'package:offload/domain/tokens/inline_token_registry.dart';
import 'package:offload/domain/tokens/token_processing.dart';
import 'package:offload/l10n/app_localizations.dart';
import 'package:offload/presentation/app.dart';
import 'package:offload/presentation/capture/pending_captures.dart';
import 'package:offload/presentation/items/item_detail_screen.dart';
import 'package:offload/presentation/startup/app_storage_provider.dart';
import 'package:offload/presentation/tokens/token_display.dart';

import '../../fakes/drift_widgets.dart';
import '../../fakes/fake_capture_channel.dart';
import '../../fakes/fake_desktop_shell.dart';
import '../../fakes/start_on_inbox.dart';
import '../../fakes/test_storage.dart';

/// The item detail (T2.3, REQ-018; design DD-018 point 1).
void main() {
  late AppStorage storage;
  late String itemId;

  Future<void> startApp(
    WidgetTester tester, {
    String text = 'Offerte renovatie opvragen',
    Future<void> Function(DriftItemRepository items)? more,
  }) async {
    tester.platformDispatcher.localesTestValue = const [Locale('nl')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    storage = await openTestStorage();
    addTearDown(storage.close);
    final items = DriftItemRepository(storage);
    itemId = await items.capture(text, source: ItemSource.app);
    if (more != null) await more(items);
    await DriftSearchIndex(storage.database).processPending();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          startOnInbox,
          appStorageProvider.overrideWith((ref) => storage),
          captureChannelProvider.overrideWith((ref) => FakeCaptureChannel()),
          desktopShellProvider.overrideWith((ref) => FakeDesktopShell()),
        ],
        child: const OffloadApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<Item> stored([String? id]) => (storage.database.select(
    storage.database.items,
  )..where((i) => i.id.equals(id ?? itemId))).getSingle();

  Future<void> openItem(WidgetTester tester, String text) async {
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  Finder textField() => find.byType(TextField).first;

  testDriftWidgets('tapping an inbox item opens it', (tester) async {
    await startApp(tester);

    await openItem(tester, 'Offerte renovatie opvragen');

    expect(find.byType(ItemDetailScreen), findsOneWidget);
    expect(find.text('Inbox'), findsOneWidget);
    expect(find.text('Geen type'), findsOneWidget);
    expect(find.text('Afronden'), findsOneWidget);
    expect(find.textContaining('via de app'), findsOneWidget);
  });

  testDriftWidgets('text is saved after a pause, not on every key', (
    tester,
  ) async {
    await startApp(tester);
    await openItem(tester, 'Offerte renovatie opvragen');

    await tester.enterText(textField(), 'Offerte renovatie opvragen bij Jan');
    await tester.pump(const Duration(seconds: 1));
    expect((await stored()).rawText, 'Offerte renovatie opvragen');

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect((await stored()).rawText, 'Offerte renovatie opvragen bij Jan');
  });

  testDriftWidgets('leaving saves at once, also the note', (tester) async {
    await startApp(tester);
    await openItem(tester, 'Offerte renovatie opvragen');

    await tester.enterText(textField(), 'Nieuwe tekst');
    await tester.enterText(find.byType(TextField).last, 'Vorige was 12k');
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    final item = await stored();
    expect(item.rawText, 'Nieuwe tekst');
    expect(item.body, 'Vorige was 12k');
  });

  testDriftWidgets('empty text is never saved', (tester) async {
    await startApp(tester);
    await openItem(tester, 'Offerte renovatie opvragen');

    await tester.enterText(textField(), '   ');
    await tester.pump();
    expect(
      find.text('Een item heeft tekst nodig. De vorige tekst blijft bewaard.'),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect((await stored()).rawText, 'Offerte renovatie opvragen');
  });

  testDriftWidgets('a ^project chosen from the list puts the item in it', (
    tester,
  ) async {
    late String schuur;
    await startApp(
      tester,
      text: 'Dak repareren',
      more: (_) async =>
          schuur = await DriftProjectRepository(storage).create('Oude schuur'),
    );
    await openItem(tester, 'Dak repareren');

    await tester.enterText(textField(), 'Dak repareren ^oud');
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(ListTile),
        matching: find.text('Oude schuur'),
      ),
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    final item = await stored();
    expect(item.rawText, 'Dak repareren ^Oude-schuur ');
    expect(item.contextId, schuur);
  });

  group('a ^word of no project (PO decision 03-10-2026)', () {
    final l10n = lookupAppLocalizations(const Locale('nl'));

    Future<List<Context>> projects() =>
        storage.database.select(storage.database.contexts).get();

    Future<void> tapNoProjectChip(WidgetTester tester, String word) async {
      await tester.tap(
        find.widgetWithText(ActionChip, l10n.tokenProjectNone(word)),
      );
      await tester.pumpAndSettle();
    }

    /// Cards leave the project token out of their text.
    Future<void> openCard(WidgetTester tester, String start) async {
      await tester.tap(find.textContaining(start).first);
      await tester.pumpAndSettle();
    }

    TextField nameField(WidgetTester tester) => tester.widget<TextField>(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
    );

    testDriftWidgets('the chip creates it and puts the item in it', (
      tester,
    ) async {
      await startApp(tester, text: 'Zaaien ^nieuwe-kas');
      await openCard(tester, 'Zaaien');

      await tapNoProjectChip(tester, 'nieuwe-kas');
      expect(nameField(tester).controller!.text, 'nieuwe kas');
      await tester.tap(find.text(l10n.projectCreate));
      await tester.pumpAndSettle();

      final created = (await projects()).single;
      expect(created.name, 'nieuwe kas');
      expect(created.parentId, isNull);
      expect((await stored()).contextId, created.id);
      // Now the word names it: the chip shows the project.
      expect(find.widgetWithText(Chip, 'nieuwe kas'), findsOneWidget);
      expect(find.text(l10n.tokenProjectNone('nieuwe-kas')), findsNothing);
    });

    testDriftWidgets('a path makes a sub-project of an existing project', (
      tester,
    ) async {
      late String tuin;
      await startApp(
        tester,
        text: 'Zaaien ^tuin/kas',
        more: (_) async =>
            tuin = await DriftProjectRepository(storage).create('Tuin'),
      );
      await openCard(tester, 'Zaaien');

      await tapNoProjectChip(tester, 'tuin/kas');
      await tester.tap(find.text(l10n.projectCreate));
      await tester.pumpAndSettle();

      final kas = (await projects()).singleWhere((p) => p.name == 'kas');
      expect(kas.parentId, tuin);
      expect((await stored()).contextId, kas.id);
    });

    testDriftWidgets('a Cyrillic name with spaces', (tester) async {
      await startApp(tester, text: 'Плитка ^нова-кухня');
      await openCard(tester, 'Плитка');

      await tapNoProjectChip(tester, 'нова-кухня');
      expect(nameField(tester).controller!.text, 'нова кухня');
      await tester.tap(find.text(l10n.projectCreate));
      await tester.pumpAndSettle();

      expect((await stored()).contextId, (await projects()).single.id);
    });

    testDriftWidgets('cancelling creates nothing', (tester) async {
      await startApp(tester, text: 'Zaaien ^kas');
      await openCard(tester, 'Zaaien');

      await tapNoProjectChip(tester, 'kas');
      await tester.tap(find.text(l10n.projectCancel));
      await tester.pumpAndSettle();

      expect(await projects(), isEmpty);
      expect((await stored()).contextId, isNull);
    });

    testDriftWidgets('a path whose parent does not exist only tells', (
      tester,
    ) async {
      await startApp(tester, text: 'Kast ^zolder/kast');
      await openCard(tester, 'Kast');

      expect(
        find.widgetWithText(Chip, l10n.tokenProjectNone('zolder/kast')),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(ActionChip, l10n.tokenProjectNone('zolder/kast')),
        findsNothing,
      );
    });
  });

  testDriftWidgets('the deadline follows the edited text', (tester) async {
    await startApp(tester);
    await openItem(tester, 'Offerte renovatie opvragen');

    await tester.enterText(textField(), 'Offerte renovatie opvragen !morgen');
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(
      (await stored()).dueAt,
      dateOnlyToStored(LocalDate.of(DateTime.now()).addDays(1)),
    );
  });

  testDriftWidgets('an existing date keeps its date in the chip (review)', (
    tester,
  ) async {
    final l10n = lookupAppLocalizations(const Locale('nl'));
    final tenDaysAgo = DateTime.now().subtract(const Duration(days: 10));
    late String old;
    await startApp(
      tester,
      more: (items) async {
        old = UuidV7Generator(
          now: () => tenDaysAgo.toUtc().millisecondsSinceEpoch,
        ).next();
        await items.captureWithId(
          old,
          'Bel !morgen',
          source: ItemSource.widget,
        );
        await DriftTokenProcessor(
          storage,
          registry: InlineTokenRegistry.standard(),
          dates: () => dateVocabularyOf(l10n),
        ).process(old);
      },
    );
    Finder chipText(LocalDate date) => find.descendant(
      of: find.byType(Chip),
      matching: find.text(l10n.tokenDateChip(date.toLocalDateTime())),
    );
    final captureDay = LocalDate.of(tenDaysAgo);
    final today = LocalDate.of(DateTime.now());

    // The inbox card shows the title without the date token (DD-018 point 2).
    await openItem(tester, 'Bel');

    // The day after capture, which is past: attention, not today + 1.
    expect(chipText(captureDay.addDays(1)), findsOneWidget);
    expect(chipText(today.addDays(1)), findsNothing);
    expect(find.byIcon(Icons.event_busy), findsOneWidget);

    // A date typed now counts from today.
    await tester.enterText(textField(), 'Bel !morgen !overmorgen');
    await tester.pump();
    expect(chipText(captureDay.addDays(1)), findsOneWidget);
    expect(chipText(today.addDays(2)), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });

  testDriftWidgets('complete and reopen', (tester) async {
    await startApp(tester);
    await openItem(tester, 'Offerte renovatie opvragen');

    await tester.tap(find.text('Afronden'));
    await tester.pumpAndSettle();
    expect((await stored()).status, ItemStatus.done);
    // The status chip, and the message with undo (T4.7).
    expect(find.text('Afgerond'), findsNWidgets(2));
    expect(find.text('Ongedaan maken'), findsOneWidget);

    await tester.tap(find.text('Heropenen'));
    await tester.pumpAndSettle();
    expect((await stored()).status, ItemStatus.active);

    // Completing again after reopening works (review T4.7).
    await tester.tap(find.text('Afronden'));
    await tester.pumpAndSettle();
    expect((await stored()).status, ItemStatus.done);
  });

  testDriftWidgets('the status chip offers only allowed statuses', (
    tester,
  ) async {
    await startApp(tester);
    await openItem(tester, 'Offerte renovatie opvragen');

    await tester.tap(find.byTooltip('Status wijzigen'));
    await tester.pumpAndSettle();
    final menu = find.byType(PopupMenuItem<ItemStatus>);
    // From the inbox: active, waiting, scheduled, done, and archived (PO
    // decision 01-10-2026: archiving does not require done).
    expect(menu, findsNWidgets(5));
    expect(
      find.descendant(of: menu, matching: find.text('Gearchiveerd')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: menu, matching: find.text('Inbox')),
      findsNothing,
    );

    // Scheduled asks for the day it comes back (DD-018 point 17).
    await tester.tap(find.text('Gepland'));
    await tester.pumpAndSettle();
    expect(find.text('Terugzien op'), findsOneWidget);
    await tester.tap(find.text('Morgen'));
    await tester.pumpAndSettle();
    expect((await stored()).status, ItemStatus.scheduled);
    expect((await stored()).revisitAt, isNotNull);
  });

  testDriftWidgets('"Wachten op…" asks who; skipping waits without one', (
    tester,
  ) async {
    await startApp(tester);
    await openItem(tester, 'Offerte renovatie opvragen');

    await tester.tap(find.text('Wachten op…'));
    await tester.pumpAndSettle();
    expect(find.text('Op wie wacht je?'), findsOneWidget);
    await tester.tap(find.text('Overslaan'));
    await tester.pumpAndSettle();

    expect((await stored()).status, ItemStatus.waiting);
    expect((await stored()).waitingOnId, isNull);
  });

  testDriftWidgets('the type can be set and cleared; no thought', (
    tester,
  ) async {
    await startApp(tester);
    await openItem(tester, 'Offerte renovatie opvragen');

    await tester.tap(find.byTooltip('Type wijzigen'));
    await tester.pumpAndSettle();
    expect(find.text('Gedachte'), findsNothing);
    await tester.tap(find.text('Taak').last);
    await tester.pumpAndSettle();
    expect((await stored()).type, ItemType.task);

    await tester.tap(find.byTooltip('Type wijzigen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Geen type').last);
    await tester.pumpAndSettle();
    expect((await stored()).type, isNull);
  });

  testDriftWidgets('to the trash, and undo', (tester) async {
    await startApp(tester);
    await openItem(tester, 'Offerte renovatie opvragen');

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Naar de prullenbak'));
    await tester.pumpAndSettle();

    expect(find.byType(ItemDetailScreen), findsNothing);
    expect(find.text('Naar de prullenbak verplaatst'), findsOneWidget);
    expect((await stored()).deletedAt, isNotNull);
    expect(find.text('Offerte renovatie opvragen'), findsNothing);

    await tester.tap(find.text('Ongedaan maken'));
    await tester.pumpAndSettle();
    expect((await stored()).deletedAt, isNull);
    expect(find.text('Offerte renovatie opvragen'), findsOneWidget);
  });

  testDriftWidgets('the duplicate hint opens the older item', (tester) async {
    late String newer;
    await startApp(
      tester,
      text: 'Offerte renovatie opvragen bij Jan',
      more: (items) async {
        await DriftSearchIndex(storage.database).processPending();
        newer = await items.capture(
          'offerte renovatie opvragen',
          source: ItemSource.app,
        );
      },
    );
    await openItem(tester, 'offerte renovatie opvragen');

    await tester.tap(find.text('Lijkt op een ander item'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Openen'));
    await tester.pumpAndSettle();

    final texts = tester
        .widgetList<TextField>(find.byType(TextField))
        .map((f) => f.controller!.text);
    expect(texts, contains('Offerte renovatie opvragen bij Jan'));
    expect(newer, isNot(itemId));
  });

  testDriftWidgets('a search result opens the item', (tester) async {
    await startApp(tester);

    await tester.tap(find.byTooltip('Zoeken'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'offerte');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Offerte renovatie opvragen').last);
    await tester.pumpAndSettle();

    expect(find.byType(ItemDetailScreen), findsOneWidget);
  });

  testDriftWidgets('"Kies een datum…" puts a fixed date in the text', (
    tester,
  ) async {
    await startApp(tester);
    await openItem(tester, 'Offerte renovatie opvragen');
    final field = textField();
    await tester.enterText(field, 'Klaar !');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Kies een datum…'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    final today = LocalDate.of(DateTime.now());
    expect(
      tester.widget<TextField>(field).controller!.text,
      'Klaar !${today.day}-${today.month}-${today.year} ',
    );
  });

  testDriftWidgets('a complete date typed by hand needs no calendar', (
    tester,
  ) async {
    await startApp(tester);
    await openItem(tester, 'Offerte renovatie opvragen');

    await tester.enterText(textField(), 'Klaar !12-10');
    await tester.pumpAndSettle();

    expect(find.text('Kies een datum…'), findsNothing);
  });

  group('keyboard on Windows (DD-018)', () {
    final windows = TargetPlatformVariant.only(TargetPlatform.windows);

    testDriftWidgets('Ctrl+Enter completes; Escape goes back', (tester) async {
      await startApp(tester);
      await openItem(tester, 'Offerte renovatie opvragen');
      await tester.tap(textField());
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect((await stored()).status, ItemStatus.done);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(ItemDetailScreen), findsNothing);
    }, variant: windows);

    testDriftWidgets('plain Enter does not leave or complete', (tester) async {
      await startApp(tester);
      await openItem(tester, 'Offerte renovatie opvragen');
      await tester.tap(textField());
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(find.byType(ItemDetailScreen), findsOneWidget);
      expect((await stored()).status, ItemStatus.inbox);
    }, variant: windows);
  });
}
