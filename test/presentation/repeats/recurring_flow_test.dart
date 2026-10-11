import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/database/app_database.dart';
import 'package:offload/data/items/drift_item_repository.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/data/tokens/drift_token_processor.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/domain/repeats/repeat.dart';
import 'package:offload/domain/time/local_date.dart';
import 'package:offload/domain/tokens/inline_token_registry.dart';
import 'package:offload/domain/tokens/token_processing.dart';
import 'package:offload/l10n/app_localizations.dart';
import 'package:offload/presentation/app.dart';
import 'package:offload/presentation/capture/pending_captures.dart';
import 'package:offload/presentation/inbox/inbox_card.dart';
import 'package:offload/presentation/startup/app_storage_provider.dart';
import 'package:offload/presentation/tokens/token_display.dart';

import '../../fakes/drift_widgets.dart';
import '../../fakes/fake_capture_channel.dart';
import '../../fakes/fake_desktop_shell.dart';
import '../../fakes/test_storage.dart';

/// Recurring tasks on screen (T4.7, REQ-061, DD-018 point 18; sketch
/// `20-recurring-tasks`): the card, completing a time with undo, the item
/// with its rhythm and *Gedaan*, *Afronden en herhalen…* and *Herhaling
/// stoppen*, and the repeat button of the prefix bar.
void main() {
  late AppStorage storage;
  late DriftItemRepository items;
  final l10n = lookupAppLocalizations(const Locale('nl'));

  LocalDate today() => LocalDate.of(DateTime.now());

  /// Captures [text] (of [type]) and processes it, as after saving.
  Future<String> add(String text, {ItemType? type}) async {
    final id = await items.capture(text, source: ItemSource.app);
    if (type != null) await items.setType(id, type);
    await DriftTokenProcessor(
      storage,
      registry: InlineTokenRegistry.standard(),
      dates: () => dateVocabularyOf(l10n),
      priorities: () => priorityVocabularyOf(l10n),
      repeats: allRepeatWords,
    ).process(id);
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

  // Read directly: a watched query would wait on a timer in fake time.
  Future<Item> stored(String id) => (storage.database.select(
    storage.database.items,
  )..where((i) => i.id.equals(id))).getSingle();

  Future<List<ItemCompletion>> liveRecords() => (storage.database.select(
    storage.database.itemCompletions,
  )..where((c) => c.deletedAt.isNull())).get();

  Future<LocalDate?> dueOf(String id) async {
    final due = (await stored(id)).dueAt;
    return due == null ? null : storedToDateOnly(due);
  }

  late String run;
  Future<void> seedRun() async {
    run = await add('Hardlopen !wekelijks !vandaag');
  }

  Future<void> openItem(WidgetTester tester, String title) async {
    await tester.tap(find.text(title));
    await tester.pumpAndSettle();
  }

  Future<void> menu(WidgetTester tester, String entry) async {
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text(entry));
    await tester.pumpAndSettle();
  }

  testDriftWidgets('Today: one card with its rhythm; swiping completes this '
      'time and undo puts it back', (tester) async {
    await startApp(tester, seed: seedRun);
    final card = find.ancestor(
      of: find.text('Hardlopen'),
      matching: find.byType(InboxCard),
    );
    expect(
      find.descendant(of: card, matching: find.text('wekelijks')),
      findsOneWidget,
    );

    await tester.drag(find.text('Hardlopen'), const Offset(600, 0));
    await tester.pumpAndSettle();

    final next = today().addDays(7);
    expect(
      find.text(l10n.itemCompletedNextTime(next.toLocalDateTime())),
      findsOneWidget,
    );
    expect(find.text('Hardlopen'), findsNothing);
    expect(await dueOf(run), next);
    expect((await stored(run)).status, ItemStatus.active);
    expect(await liveRecords(), hasLength(1));

    await tester.tap(find.text(l10n.itemUndo));
    await tester.pumpAndSettle();
    expect(await dueOf(run), today());
    expect((await stored(run)).status, ItemStatus.inbox);
    expect(await liveRecords(), isEmpty);
    expect(find.text('Hardlopen'), findsOneWidget);
  });

  testDriftWidgets('the item shows its rhythm and this time; Afronden moves '
      'on and Gedaan lists it, with undo', (tester) async {
    await startApp(tester, seed: seedRun);
    await openItem(tester, 'Hardlopen');
    final t = today();
    expect(
      find.text(
        l10n.repeatSinceWeekly(t.toLocalDateTime(), t.toLocalDateTime()),
      ),
      findsOneWidget,
    );
    expect(find.text(l10n.repeatThisTime(t.toLocalDateTime())), findsOneWidget);
    expect(find.text(l10n.completionsTitle(1)), findsNothing);

    await tester.tap(find.text(l10n.itemComplete));
    await tester.pumpAndSettle();

    expect(await dueOf(run), t.addDays(7));
    expect(find.text(l10n.completionsTitle(1)), findsOneWidget);
    expect(find.text(l10n.completionOnTime), findsOneWidget);
    expect(
      find.text(l10n.repeatThisTime(t.addDays(7).toLocalDateTime())),
      findsOneWidget,
    );

    await tester.tap(find.text(l10n.itemUndo));
    await tester.pumpAndSettle();
    expect(await dueOf(run), t);
    expect(find.text(l10n.completionsTitle(1)), findsNothing);

    // After the undo the same time can be completed again.
    await tester.tap(find.text(l10n.itemComplete));
    await tester.pumpAndSettle();
    expect(await dueOf(run), t.addDays(7));
    expect(await liveRecords(), hasLength(1));
  });

  testDriftWidgets('Afronden en herhalen adds the word and completes this '
      'time; undo takes both back', (tester) async {
    late String filter;
    await startApp(
      tester,
      seed: () async {
        filter = await add('Filter schoonmaken !vandaag');
      },
    );
    await openItem(tester, 'Filter schoonmaken');

    await menu(tester, l10n.completeAndRepeat);
    expect(find.text(l10n.completeAndRepeatTitle), findsOneWidget);
    await tester.tap(find.text(l10n.repeatRhythmTitle('M')));
    await tester.pumpAndSettle();

    final next = seriesDate(today(), Rhythm.monthly, 1);
    expect(
      (await stored(filter)).rawText,
      'Filter schoonmaken !vandaag !maandelijks',
    );
    expect(await dueOf(filter), next);
    expect(await liveRecords(), hasLength(1));
    expect(
      find.text(l10n.itemCompletedNextTime(next.toLocalDateTime())),
      findsOneWidget,
    );

    await tester.tap(find.text(l10n.itemUndo));
    await tester.pumpAndSettle();
    expect((await stored(filter)).rawText, 'Filter schoonmaken !vandaag');
    expect(await liveRecords(), isEmpty);
    expect(await dueOf(filter), today());
  });

  testDriftWidgets('Herhaling stoppen removes the word and completes the '
      'item', (tester) async {
    await startApp(tester, seed: seedRun);
    await openItem(tester, 'Hardlopen');

    await menu(tester, l10n.stopRepeating);

    final item = await stored(run);
    expect(item.rawText, 'Hardlopen !vandaag');
    expect(item.status, ItemStatus.done);
    expect(find.text(l10n.repeatStopped), findsOneWidget);
    expect(await liveRecords(), isEmpty);
  });

  testDriftWidgets('an idea with the word does not repeat', (tester) async {
    late String idea;
    await startApp(
      tester,
      seed: () async {
        idea = await add(
          'Moestuinplan !maandelijks !vandaag',
          type: ItemType.idea,
        );
      },
    );
    await openItem(tester, 'Moestuinplan');
    expect(
      find.text(l10n.repeatNotForType(l10n.repeatRhythmTitle('M'))),
      findsOneWidget,
    );
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(find.text(l10n.completeAndRepeat), findsNothing);
    // Nor stop: it does not repeat (DD-018 point 18).
    expect(find.text(l10n.stopRepeating), findsNothing);
    await tester.tapAt(Offset.zero);
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.itemComplete));
    await tester.pumpAndSettle();
    expect((await stored(idea)).status, ItemStatus.done);
    expect(await liveRecords(), isEmpty);
  });

  testDriftWidgets('the repeat button offers only the rhythms', (tester) async {
    await startApp(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.tap(
      find.text(l10n.prefixBarButton('!', l10n.tokenRepeatLabel)),
    );
    await tester.pumpAndSettle();

    for (final word in ['dagelijks', 'wekelijks', 'maandelijks']) {
      expect(find.text(word), findsOneWidget, reason: word);
    }
    expect(find.text('vandaag'), findsNothing);
    expect(find.text(l10n.tokenSuggestionPickDate), findsNothing);

    await tester.tap(find.text('wekelijks'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '!wekelijks ',
    );
    expect(
      find.text(l10n.repeatRhythmTitle('W')),
      findsOneWidget,
      reason: 'the live chip',
    );
  });
}
