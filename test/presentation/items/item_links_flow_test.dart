import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/database/app_database.dart' hide SearchIndex;
import 'package:offload/data/items/drift_item_repository.dart';
import 'package:offload/data/search/drift_search_index.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/data/tokens/drift_token_processor.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/domain/tokens/inline_token.dart';
import 'package:offload/domain/tokens/inline_token_registry.dart';
import 'package:offload/l10n/app_localizations.dart';
import 'package:offload/presentation/app.dart';
import 'package:offload/presentation/capture/capture_screen.dart';
import 'package:offload/presentation/capture/pending_captures.dart';
import 'package:offload/presentation/items/item_detail_screen.dart';
import 'package:offload/presentation/startup/app_storage_provider.dart';

import '../../fakes/drift_widgets.dart';
import '../../fakes/fake_capture_channel.dart';
import '../../fakes/fake_desktop_shell.dart';
import '../../fakes/start_on_inbox.dart';
import '../../fakes/test_storage.dart';

/// Links between items on screen (T10.9 step B, REQ-054, AC REQ-053; DD-018
/// point 14, sketch 14).
void main() {
  late AppStorage storage;
  late DriftItemRepository items;
  final l10n = lookupAppLocalizations(const Locale('nl'));

  /// Opens the app on the inbox after [seed] stored items; the search index
  /// and the tokens are worked out first, as after a start.
  Future<void> startApp(
    WidgetTester tester, [
    Future<void> Function()? seed,
  ]) async {
    tester.platformDispatcher.localesTestValue = const [Locale('nl')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    storage = await openTestStorage();
    addTearDown(storage.close);
    items = DriftItemRepository(storage);
    await seed?.call();
    await DriftSearchIndex(storage.database).processPending();
    await DriftTokenProcessor(
      storage,
      registry: InlineTokenRegistry.standard(),
      dates: () => DateVocabulary.empty,
    ).processOutdated();
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

  Future<String> capture(String text, {Map<String, String> links = const {}}) =>
      items.capture(text, source: ItemSource.app, links: links);

  Future<void> openCard(WidgetTester tester, String start) async {
    await tester.tap(find.textContaining(start).first);
    await tester.pumpAndSettle();
  }

  Finder suggestion(String label) =>
      find.descendant(of: find.byType(ListTile), matching: find.text(label));

  TextField firstField(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField).first);

  Future<List<ItemLink>> liveLinks() => (storage.database.select(
    storage.database.itemLinks,
  )..where((l) => l.deletedAt.isNull())).get();

  group('quick capture', () {
    testDriftWidgets('[[ lists items; choosing links on saving', (
      tester,
    ) async {
      late String offer;
      await startApp(tester, () async {
        offer = await capture('Offerte kozijnen vergelijken');
      });
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Bestellen, zie [[offer');
      await tester.pumpAndSettle();
      expect(suggestion('Offerte kozijnen vergelijken'), findsOneWidget);
      expect(find.text(l10n.itemStatusInbox), findsOneWidget);

      await tester.tap(suggestion('Offerte kozijnen vergelijken'));
      await tester.pumpAndSettle();
      expect(
        firstField(tester).controller!.text,
        'Bestellen, zie [[Offerte kozijnen vergelijken]] ',
      );
      // The chosen item's chip, without reading anything (REQ-001).
      expect(
        find.widgetWithText(Chip, 'Offerte kozijnen vergelijken'),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip(l10n.captureSave));
      await tester.pumpAndSettle();
      expect(find.byType(CaptureScreen), findsNothing);
      final link = (await liveLinks()).single;
      expect(link.toItemId, offer);
      expect(link.label, 'Offerte kozijnen vergelijken');
    });

    testDriftWidgets('the [[ button lists the newest items, Cyrillic too', (
      tester,
    ) async {
      await startApp(tester, () async {
        await capture('Нова кухня');
      });
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // The sixth button: the bar scrolls sideways.
      final button = find.textContaining('[[');
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(firstField(tester).controller!.text, '[[');
      expect(suggestion('Нова кухня'), findsOneWidget);
    });
  });

  group('item detail', () {
    late String offer;
    late String from;

    Future<void> seedLinked() async {
      offer = await capture('Offerte');
      from = await capture(
        'Zie [[Offerte]] en [[Container]]',
        links: {'Offerte': offer},
      );
    }

    testDriftWidgets('a link chip shows the current title and opens it', (
      tester,
    ) async {
      await startApp(tester, () async {
        await seedLinked();
        await items.editText(offer, 'Offertes vergelijken');
      });
      await openCard(tester, 'Zie Offerte');

      final chip = find.widgetWithText(ActionChip, 'Offertes vergelijken');
      expect(chip, findsOneWidget);
      await tester.tap(chip);
      await tester.pumpAndSettle();

      final texts = tester
          .widgetList<TextField>(find.byType(TextField))
          .map((f) => f.controller!.text);
      expect(texts, contains('Offertes vergelijken'));
    });

    testDriftWidgets('a target in the trash says so', (tester) async {
      await startApp(tester, () async {
        await seedLinked();
        await items.moveToTrash(offer);
      });
      await openCard(tester, 'Zie Offerte');

      expect(
        find.widgetWithText(ActionChip, l10n.tokenLinkTrashed('Offerte')),
        findsOneWidget,
      );
    });

    testDriftWidgets('"no item" creates the item and links it', (tester) async {
      await startApp(tester, seedLinked);
      await openCard(tester, 'Zie Offerte');

      await tester.tap(
        find.widgetWithText(ActionChip, l10n.tokenLinkNone('Container')),
      );
      await tester.pumpAndSettle();

      final made = await (storage.database.select(
        storage.database.items,
      )..where((i) => i.rawText.equals('Container'))).getSingle();
      expect(made.status, ItemStatus.inbox);
      final links = await liveLinks();
      expect(
        links.any((l) => l.fromItemId == from && l.toItemId == made.id),
        isTrue,
      );
      expect(find.widgetWithText(ActionChip, 'Container'), findsOneWidget);
    });

    testDriftWidgets('"Linked from" lists and opens the backlinks', (
      tester,
    ) async {
      await startApp(tester, seedLinked);
      await tester.tap(find.text('Offerte'));
      await tester.pumpAndSettle();

      expect(find.text(l10n.itemLinkedFrom(1)), findsOneWidget);
      await tester.tap(find.text('Zie Offerte en Container').last);
      await tester.pumpAndSettle();

      final texts = tester
          .widgetList<TextField>(find.byType(TextField))
          .map((f) => f.controller!.text);
      expect(texts, contains('Zie [[Offerte]] en [[Container]]'));
    });

    testDriftWidgets('no backlinks, no section', (tester) async {
      await startApp(tester, () async {
        await capture('Los item');
      });
      await openCard(tester, 'Los item');
      expect(find.textContaining('Verwijst hiernaar'), findsNothing);
    });

    testDriftWidgets('Link in the duplicate hint writes the link', (
      tester,
    ) async {
      late String older;
      late String newer;
      await startApp(tester, () async {
        older = await capture('Offerte renovatie opvragen bij Jan');
        await DriftSearchIndex(storage.database).processPending();
        newer = await capture('offerte renovatie opvragen');
      });
      await openCard(tester, 'offerte renovatie opvragen');

      await tester.tap(find.text(l10n.duplicateHint));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.duplicateLink));
      await tester.pumpAndSettle();

      expect(
        firstField(tester).controller!.text,
        'offerte renovatie opvragen [[Offerte renovatie opvragen bij Jan]]',
      );
      final link = (await liveLinks()).single;
      expect(link.fromItemId, newer);
      expect(link.toItemId, older);
    });

    testDriftWidgets(
      'Windows: Enter chooses from the [[ list',
      (tester) async {
        await startApp(tester, () async {
          await capture('Offerte kozijnen');
          await capture('Bestellen');
        });
        await openCard(tester, 'Bestellen');
        await tester.enterText(find.byType(TextField).first, 'Bestellen [[off');
        await tester.pumpAndSettle();

        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();

        expect(
          firstField(tester).controller!.text,
          'Bestellen [[Offerte kozijnen]] ',
        );
        expect(find.byType(ItemDetailScreen), findsOneWidget);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.windows),
    );
  });

  testDriftWidgets('cards show a link as its text, without a chip', (
    tester,
  ) async {
    await startApp(tester, () async {
      final offer = await capture('Offerte');
      await capture('Zie [[Offerte]]', links: {'Offerte': offer});
    });
    expect(find.text('Zie Offerte'), findsOneWidget);
    expect(find.widgetWithText(Chip, 'Offerte'), findsNothing);
  });
}
