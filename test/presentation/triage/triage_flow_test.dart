import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/database/app_database.dart';
import 'package:offload/data/items/drift_item_repository.dart';
import 'package:offload/data/people/drift_people_repository.dart';
import 'package:offload/data/search/drift_search_index.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/presentation/app.dart';
import 'package:offload/presentation/capture/pending_captures.dart';
import 'package:offload/presentation/startup/app_storage_provider.dart';

import '../../fakes/drift_widgets.dart';
import '../../fakes/fake_capture_channel.dart';
import '../../fakes/fake_desktop_shell.dart';
import '../../fakes/start_on_inbox.dart';
import '../../fakes/test_storage.dart';

/// Triage (T2.4, REQ-010; design DD-018 point 3).
void main() {
  late AppStorage storage;
  late String oldest;
  late String middle;
  late String newest;

  Future<void> startApp(WidgetTester tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('nl')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    storage = await openTestStorage();
    addTearDown(storage.close);
    final items = DriftItemRepository(storage);
    oldest = await items.capture('Offerte opvragen', source: ItemSource.app);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 2)),
    );
    middle = await items.capture('Logboek bijhouden', source: ItemSource.app);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 2)),
    );
    newest = await items.capture('Markt plannen', source: ItemSource.app);
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

  /// Read directly: a watched query would wait on a timer in fake time.
  Future<Item> stored(String id) => (storage.database.select(
    storage.database.items,
  )..where((i) => i.id.equals(id))).getSingle();

  Future<void> startTriage(WidgetTester tester) async {
    await tester.tap(find.text('Verwerken · 3'));
    await tester.pumpAndSettle();
  }

  testDriftWidgets('the inbox button starts triage at the first card', (
    tester,
  ) async {
    await startApp(tester);
    await startTriage(tester);
    expect(find.text('1 van 3'), findsOneWidget);
    expect(find.text('Markt plannen'), findsOneWidget);
  });

  testDriftWidgets('a button sorts the card; undo brings it back', (
    tester,
  ) async {
    await startApp(tester);
    await startTriage(tester);
    await tester.tap(find.text('Taak'));
    await tester.pumpAndSettle();
    expect((await stored(newest)).type, ItemType.task);
    expect((await stored(newest)).status, ItemStatus.active);
    expect(find.text('2 van 3'), findsOneWidget);
    expect(find.text('Naar Taak'), findsOneWidget);

    await tester.tap(find.text('Ongedaan maken'));
    await tester.pumpAndSettle();
    expect((await stored(newest)).status, ItemStatus.inbox);
    expect((await stored(newest)).type, isNull);
    expect(find.text('1 van 3'), findsOneWidget);
    expect(find.text('Markt plannen'), findsOneWidget);
  });

  testDriftWidgets('the undo message goes away by itself', (tester) async {
    await startApp(tester);
    await startTriage(tester);
    await tester.tap(find.text('Taak'));
    await tester.pumpAndSettle();
    expect(find.text('Naar Taak'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    expect(find.text('Naar Taak'), findsNothing);
  });

  testDriftWidgets('with a screen reader only the last undo message shows', (
    tester,
  ) async {
    // TalkBack on: undo messages stay until tapped (REQ-016); a new choice
    // replaces the message instead of queueing behind it.
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(accessibleNavigation: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await startApp(tester);
    await startTriage(tester);
    await tester.tap(find.text('Taak'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Idee'));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Naar Idee'), findsOneWidget);

    await tester.tap(find.text('Ongedaan maken'));
    await tester.pumpAndSettle();
    expect((await stored(middle)).status, ItemStatus.inbox);
    expect((await stored(newest)).type, ItemType.task);
  });

  testDriftWidgets('a new choice ends the undo of the previous one', (
    tester,
  ) async {
    await startApp(tester);
    await startTriage(tester);
    await tester.tap(find.text('Taak'));
    await tester.pumpAndSettle();
    expect(find.text('Ongedaan maken'), findsOneWidget);
    // Skipping the next card: the message for the task is gone, so its
    // undo can no longer step back over the skipped card.
    await tester.drag(find.text('Logboek bijhouden'), const Offset(600, 0));
    await tester.pumpAndSettle();
    expect(find.text('Ongedaan maken'), findsNothing);
    expect(find.text('3 van 3'), findsOneWidget);
    expect((await stored(newest)).type, ItemType.task);
  });

  testDriftWidgets('swipe right skips, swipe left sends to the trash', (
    tester,
  ) async {
    await startApp(tester);
    await startTriage(tester);
    await tester.drag(find.text('Markt plannen'), const Offset(600, 0));
    await tester.pumpAndSettle();
    expect((await stored(newest)).status, ItemStatus.inbox);
    expect(find.text('Logboek bijhouden'), findsOneWidget);

    await tester.drag(find.text('Logboek bijhouden'), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect((await stored(middle)).deletedAt, isNotNull);
    expect(find.text('Naar de prullenbak verplaatst'), findsOneWidget);
  });

  testDriftWidgets('a request asks who; a new name becomes a person', (
    tester,
  ) async {
    await startApp(tester);
    await startTriage(tester);
    await tester.tap(find.text('Verzoek'));
    await tester.pumpAndSettle();
    expect(find.text('Wie vroeg dit?'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Jan');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nieuw: Jan'));
    await tester.pumpAndSettle();

    final item = await stored(newest);
    expect(item.type, ItemType.request);
    expect(item.status, ItemStatus.active);
    final jan = await storage.database
        .select(storage.database.people)
        .getSingle();
    expect(jan.name, 'Jan');
    expect(item.requesterId, jan.id);
  });

  testDriftWidgets('Done takes the top suggestion, a known person first', (
    tester,
  ) async {
    await startApp(tester);
    final jan = await DriftPeopleRepository(storage).idFor('Jan');
    await startTriage(tester);
    await tester.tap(find.text('Verzoek'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Ja');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Klaar'));
    await tester.pumpAndSettle();
    expect((await stored(newest)).requesterId, jan);
    expect(
      await storage.database.select(storage.database.people).get(),
      hasLength(1),
    );
  });

  testDriftWidgets('waiting for without a person, and closing the sheet', (
    tester,
  ) async {
    await startApp(tester);
    await startTriage(tester);
    // Closing the sheet chooses nothing.
    await tester.tap(find.text('Wacht op'));
    await tester.pumpAndSettle();
    expect(find.text('Op wie wacht je?'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect((await stored(newest)).status, ItemStatus.inbox);
    expect(find.text('1 van 3'), findsOneWidget);

    // Skipping the person still sets the destination.
    await tester.tap(find.text('Wacht op'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Overslaan').last);
    await tester.pumpAndSettle();
    final item = await stored(newest);
    expect(item.status, ItemStatus.waiting);
    expect(item.type, isNull);
    expect(item.waitingOnId, isNull);
  });

  testDriftWidgets('the end says what was done and what was skipped', (
    tester,
  ) async {
    await startApp(tester);
    await startTriage(tester);
    await tester.tap(find.text('Idee'));
    await tester.pumpAndSettle();
    await tester.drag(find.text('Logboek bijhouden'), const Offset(600, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Notitie'));
    await tester.pumpAndSettle();
    expect(find.text('Alles heeft een plek'), findsOneWidget);
    expect(find.text('2 verwerkt'), findsOneWidget);
    expect(
      find.text('1 overgeslagen, die staat nog in je inbox'),
      findsOneWidget,
    );
    expect((await stored(oldest)).type, ItemType.note);

    await tester.tap(find.text('Terug naar de inbox'));
    await tester.pumpAndSettle();
    expect(find.text('Verwerken · 1'), findsOneWidget);
  });

  testDriftWidgets(
    'Windows: number keys, Delete, Space, Ctrl+Z and Escape',
    (tester) async {
      await startApp(tester);
      await startTriage(tester);
      expect(find.byType(Dismissible), findsNothing);
      expect(find.text('Taak  1'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
      await tester.pumpAndSettle();
      expect((await stored(newest)).type, ItemType.idea);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect((await stored(newest)).status, ItemStatus.inbox);
      expect(find.text('1 van 3'), findsOneWidget);

      // Ctrl+Z again: nothing left to undo, not one step too many.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(find.text('1 van 3'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(find.text('2 van 3'), findsOneWidget);

      // Undo a skip once; a second Ctrl+Z does not go back further.
      await tester.sendKeyEvent(LogicalKeyboardKey.numpad1);
      await tester.pumpAndSettle();
      expect((await stored(middle)).type, ItemType.task);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(find.text('3 van 3'), findsOneWidget);
      expect((await stored(middle)).type, ItemType.task);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(find.text('Alles heeft een plek'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Verwerken · 2'), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );

  testDriftWidgets(
    'Windows: Delete sends the current card to the trash',
    (tester) async {
      await startApp(tester);
      await startTriage(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(find.text('2 van 3'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await tester.pumpAndSettle();
      expect((await stored(middle)).deletedAt, isNotNull);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Verwerken · 2'), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );

  testDriftWidgets('Later… parks the card until a day; undo brings it back', (
    tester,
  ) async {
    await startApp(tester);
    await startTriage(tester);
    await tester.tap(find.text('Later…'));
    await tester.pumpAndSettle();
    expect(find.text('Terugzien op'), findsOneWidget);
    await tester.tap(find.text('Morgen'));
    await tester.pumpAndSettle();

    final parked = await stored(newest);
    expect(parked.status, ItemStatus.scheduled);
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    expect(parked.revisitAt!.toUtc().day, tomorrow.day);
    expect(find.text('2 van 3'), findsOneWidget);
    expect(find.textContaining('Terug op'), findsOneWidget);

    await tester.tap(find.text('Ongedaan maken'));
    await tester.pumpAndSettle();
    expect((await stored(newest)).status, ItemStatus.inbox);
    expect((await stored(newest)).revisitAt, isNull);
    expect(find.text('1 van 3'), findsOneWidget);
  });

  testDriftWidgets('Later… with the sheet closed changes nothing', (
    tester,
  ) async {
    await startApp(tester);
    await startTriage(tester);
    await tester.tap(find.text('Later…'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect((await stored(newest)).status, ItemStatus.inbox);
    expect(find.text('1 van 3'), findsOneWidget);
  });

  testDriftWidgets(
    'Windows: 6 opens Later… as a dialog',
    (tester) async {
      await startApp(tester);
      await startTriage(tester);
      expect(find.text('Later…  6'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit6);
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);
      await tester.tap(find.text('Volgende week'));
      await tester.pumpAndSettle();
      expect((await stored(newest)).status, ItemStatus.scheduled);
      expect(find.text('2 van 3'), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );
}
