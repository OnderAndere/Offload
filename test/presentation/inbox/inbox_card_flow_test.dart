import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/items/drift_item_repository.dart';
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
import 'package:offload/presentation/startup/app_storage_provider.dart';
import 'package:offload/presentation/tokens/token_display.dart';
import 'package:offload/presentation/tokens/token_processor_provider.dart';

import '../../fakes/drift_widgets.dart';
import '../../fakes/fake_capture_channel.dart';
import '../../fakes/fake_desktop_shell.dart';
import '../../fakes/start_on_inbox.dart';
import '../../fakes/test_storage.dart';

/// The inbox row as a card (T2.8, DD-018 point 2) and swiping it to the
/// trash (T2.9, AC REQ-010).
/// Processes nothing, so an item stays unprocessed for the whole test.
class _NoProcessing implements ItemTokenProcessor {
  @override
  Future<void> process(String itemId) async {}

  @override
  Future<void> processOutdated() async {}
}

void main() {
  late AppStorage storage;
  late DriftItemRepository items;
  final l10n = lookupAppLocalizations(const Locale('nl'));
  final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));

  /// Captured three days ago, so relative dates count from then.
  late String oldId;
  late String mailId;

  Future<void> startApp(WidgetTester tester, {bool process = true}) async {
    tester.platformDispatcher.localesTestValue = const [Locale('nl')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    storage = await openTestStorage();
    addTearDown(storage.close);
    items = DriftItemRepository(storage);
    oldId = UuidV7Generator(
      now: () => threeDaysAgo.toUtc().millisecondsSinceEpoch,
    ).next();
    await items.captureWithId(
      oldId,
      'Bel Jan over de markt @Jan #renovatie !morgen',
      source: ItemSource.widget,
    );
    await DriftTokenProcessor(
      storage,
      registry: InlineTokenRegistry.standard(),
      dates: () => dateVocabularyOf(l10n),
    ).process(oldId);
    // Not processed yet: no chip for Piet.
    await items.capture('Mail @Piet', source: ItemSource.app);
    mailId = await items.capture(
      'RE: Keuring vrijdag\n\nHoi Sam,\nkun jij de ketel keuren?',
      source: ItemSource.share,
    );
    await DriftSearchIndex(storage.database).processPending();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          startOnInbox,
          appStorageProvider.overrideWith((ref) => storage),
          captureChannelProvider.overrideWith((ref) => FakeCaptureChannel()),
          desktopShellProvider.overrideWith((ref) => FakeDesktopShell()),
          if (!process)
            tokenProcessorProvider.overrideWith((ref) => _NoProcessing()),
        ],
        child: const OffloadApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Whether item [id] is in the trash; read directly, a watched query
  /// would wait on a timer in the test's fake time.
  Future<bool> trashed(String id) async =>
      (await (storage.database.select(
        storage.database.items,
      )..where((i) => i.id.equals(id))).getSingle()).deletedAt !=
      null;

  Finder chip(String text) =>
      find.descendant(of: find.byType(Chip), matching: find.text(text));

  testDriftWidgets('the title leaves the tokens out; they become chips', (
    tester,
  ) async {
    await startApp(tester);
    expect(find.text('Bel Jan over de markt'), findsOneWidget);
    expect(chip('Jan'), findsOneWidget);
    expect(chip('renovatie'), findsOneWidget);
    // The stored date: tomorrow as it was three days ago, so overdue now.
    final due = LocalDate.of(threeDaysAgo).addDays(1);
    expect(chip(l10n.tokenDateChip(due.toLocalDateTime())), findsOneWidget);
    expect(find.byIcon(Icons.event_busy), findsOneWidget);
    expect(find.text('3 d'), findsOneWidget);
  });

  testDriftWidgets('the type shows as the first chip once it is set (T2.10)', (
    tester,
  ) async {
    await startApp(tester);
    expect(chip('Idee'), findsNothing);
    await items.setType(oldId, ItemType.idea);
    await tester.pumpAndSettle();
    expect(chip('Idee'), findsOneWidget);
    expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
  });

  testDriftWidgets('an unprocessed token has no chip yet', (tester) async {
    await startApp(tester, process: false);
    expect(find.text('Mail'), findsOneWidget);
    expect(chip('Piet'), findsNothing);
  });

  testDriftWidgets('a text of several lines shows its first line and a count', (
    tester,
  ) async {
    await startApp(tester);
    expect(find.text('RE: Keuring vrijdag'), findsOneWidget);
    expect(find.text('+ 2 regels'), findsOneWidget);
    expect(find.textContaining('Hoi Sam'), findsNothing);
    expect(find.text('zojuist'), findsNWidgets(2));
  });

  testDriftWidgets('swiping a card left moves it to the trash, with undo', (
    tester,
  ) async {
    await startApp(tester);
    await tester.drag(find.text('RE: Keuring vrijdag'), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.text('RE: Keuring vrijdag'), findsNothing);
    expect(find.text(l10n.itemMovedToTrash), findsOneWidget);
    expect(await trashed(mailId), isTrue);

    await tester.tap(find.text(l10n.itemUndo));
    await tester.pumpAndSettle();
    expect(find.text('RE: Keuring vrijdag'), findsOneWidget);
    expect(await trashed(mailId), isFalse);
  });

  testDriftWidgets('the undo message goes away by itself', (tester) async {
    await startApp(tester);
    await tester.drag(find.text('RE: Keuring vrijdag'), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.text(l10n.itemMovedToTrash), findsOneWidget);
    // A message with an action would stay on screen until tapped (Flutter's
    // default); ours leaves after five seconds.
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    expect(find.text(l10n.itemMovedToTrash), findsNothing);
    expect(await trashed(mailId), isTrue);
  });

  testDriftWidgets(
    'with a screen reader a new undo message replaces the previous one',
    (tester) async {
      // TalkBack on: undo messages stay until tapped (REQ-016). A second
      // swipe must not queue its message behind the first one.
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(accessibleNavigation: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await startApp(tester);
      await tester.drag(
        find.text('Bel Jan over de markt'),
        const Offset(-600, 0),
      );
      await tester.pumpAndSettle();
      await tester.drag(
        find.text('RE: Keuring vrijdag'),
        const Offset(-600, 0),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsOneWidget);
      // It stays: reaching the button takes longer with a screen reader.
      await tester.pump(const Duration(seconds: 10));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsOneWidget);

      // The message left is the one of the last swipe.
      await tester.tap(find.text(l10n.itemUndo));
      await tester.pumpAndSettle();
      expect(await trashed(mailId), isFalse);
      expect(await trashed(oldId), isTrue);
      expect(find.byType(SnackBar), findsNothing);
    },
  );

  testDriftWidgets('swiping right does nothing', (tester) async {
    await startApp(tester);
    await tester.drag(find.text('RE: Keuring vrijdag'), const Offset(600, 0));
    await tester.pumpAndSettle();
    expect(find.text('RE: Keuring vrijdag'), findsOneWidget);
    expect(await trashed(mailId), isFalse);
  });

  testDriftWidgets(
    'no swiping on Windows (Del follows with the list pane, T2.6)',
    (tester) async {
      await startApp(tester);
      await tester.drag(
        find.text('RE: Keuring vrijdag'),
        const Offset(-600, 0),
      );
      await tester.pumpAndSettle();
      expect(find.text('RE: Keuring vrijdag'), findsOneWidget);
      expect(find.byType(Dismissible), findsNothing);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );
}
