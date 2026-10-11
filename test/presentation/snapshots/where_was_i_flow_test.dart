import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/database/app_database.dart';
import 'package:offload/data/items/drift_item_repository.dart';
import 'package:offload/data/projects/drift_project_repository.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/l10n/app_localizations.dart';
import 'package:offload/presentation/app.dart';
import 'package:offload/presentation/capture/pending_captures.dart';
import 'package:offload/presentation/home/destination.dart';
import 'package:offload/presentation/snapshots/where_was_i.dart';
import 'package:offload/presentation/startup/app_storage_provider.dart';

import '../../fakes/drift_widgets.dart';
import '../../fakes/fake_capture_channel.dart';
import '../../fakes/fake_desktop_shell.dart';
import '../../fakes/test_storage.dart';

/// "Where was I" (T10.3 step B, REQ-049, DD-018 point 13): the button, the
/// form, the resume card, in an item and a project; Ctrl+Shift+P.
void main() {
  late AppStorage storage;
  late String item;
  final l10n = lookupAppLocalizations(const Locale('nl'));
  final windows = TargetPlatformVariant.only(TargetPlatform.windows);

  Future<void> startApp(
    WidgetTester tester, {
    Destination start = Destination.inbox,
    double width = 400,
  }) async {
    tester.view.physicalSize = Size(width, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.localesTestValue = const [Locale('nl')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    storage = await openTestStorage();
    addTearDown(storage.close);
    item = await DriftItemRepository(
      storage,
    ).capture('Offerte kozijnen vergelijken', source: ItemSource.app);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          destinationProvider.overrideWith((ref) => start),
          appStorageProvider.overrideWith((ref) => storage),
          captureChannelProvider.overrideWith((ref) => FakeCaptureChannel()),
          desktopShellProvider.overrideWith((ref) => FakeDesktopShell()),
        ],
        child: const OffloadApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The rows, read once (never a watched stream in a widget test).
  Future<List<SnapshotRow>> rows() =>
      storage.database.select(storage.database.snapshots).get();

  Finder field(String label) => find.widgetWithText(TextField, label);

  Future<void> openItem(WidgetTester tester) async {
    await tester.tap(find.text('Offerte kozijnen vergelijken'));
    await tester.pumpAndSettle();
  }

  Future<void> openForm(WidgetTester tester) async {
    final button = find.widgetWithText(OutlinedButton, l10n.whereWasI);
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  testDriftWidgets('the button opens the form; saving shows the card', (
    tester,
  ) async {
    await startApp(tester);
    await openItem(tester);
    await openForm(tester);
    expect(find.text(l10n.whereWasINextStep), findsOneWidget);
    await tester.enterText(
      field(l10n.whereWasINextStep),
      'Prijzen in tabel zetten',
    );
    await tester.enterText(field(l10n.whereWasIInMind), 'B is goedkoper');
    await tester.pump();
    await tester.tap(find.text(l10n.whereWasISave));
    await tester.pumpAndSettle();

    final row = (await rows()).single;
    expect(row.itemId, item);
    expect(row.nextStep, 'Prijzen in tabel zetten');
    // The card on top of the item, both fields.
    expect(find.byType(ResumeCard), findsOneWidget);
    expect(find.text('Prijzen in tabel zetten'), findsOneWidget);
    expect(find.text('B is goedkoper'), findsOneWidget);
    // A touch of the item (point 13 (f)).
    final stored = await (storage.database.select(
      storage.database.items,
    )..where((i) => i.id.equals(item))).getSingle();
    expect(stored.reviewedAt, isNotNull);
  });

  testDriftWidgets('Close keeps what was typed; Update is filled in', (
    tester,
  ) async {
    await startApp(tester);
    await openItem(tester);
    await openForm(tester);
    await tester.enterText(field(l10n.whereWasINextStep), 'Leverancier bellen');
    await tester.pump();
    await tester.tap(find.text(l10n.whereWasIClose));
    await tester.pumpAndSettle();
    expect((await rows()).single.nextStep, 'Leverancier bellen');

    await tester.tap(find.text(l10n.resumeUpdate));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: field(l10n.whereWasINextStep),
        matching: find.text('Leverancier bellen'),
      ),
      findsOneWidget,
    );
    await tester.enterText(field(l10n.whereWasINextStep), 'Eerst mailen');
    await tester.pump();
    await tester.tap(find.text(l10n.whereWasISave));
    await tester.pumpAndSettle();
    // Updated: still one note.
    expect((await rows()).single.nextStep, 'Eerst mailen');
  });

  testDriftWidgets('Resume closes the card; empty and save does too', (
    tester,
  ) async {
    await startApp(tester);
    await openItem(tester);
    await openForm(tester);
    await tester.enterText(field(l10n.whereWasINextStep), 'Bellen');
    await tester.pump();
    await tester.tap(find.text(l10n.whereWasISave));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.resumeResume));
    await tester.pumpAndSettle();
    expect(find.byType(ResumeCard), findsOneWidget); // empty now
    expect(find.text(l10n.resumeResume), findsNothing);
    expect((await rows()).single.resumedAt, isNotNull);

    await openForm(tester);
    await tester.enterText(field(l10n.whereWasIInMind), 'Nog iets');
    await tester.pump();
    await tester.tap(find.text(l10n.whereWasISave));
    await tester.pumpAndSettle();
    expect(find.text('Nog iets'), findsOneWidget);
    await tester.tap(find.text(l10n.resumeUpdate));
    await tester.pumpAndSettle();
    await tester.enterText(field(l10n.whereWasIInMind), '');
    await tester.pump();
    await tester.tap(find.text(l10n.whereWasISave));
    await tester.pumpAndSettle();
    expect(find.text(l10n.resumeResume), findsNothing);
  });

  testDriftWidgets('a project has the button and the card too', (tester) async {
    late String project;
    await startApp(tester, start: Destination.projects);
    project = await DriftProjectRepository(storage).create('Verbouwing');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Verbouwing'));
    await tester.pumpAndSettle();
    await openForm(tester);
    await tester.enterText(
      field(l10n.whereWasINextStep),
      'Kozijnen kiezen, dan tegels',
    );
    await tester.pump();
    await tester.tap(find.text(l10n.whereWasISave));
    await tester.pumpAndSettle();
    expect((await rows()).single.contextId, project);
    expect(find.text('Kozijnen kiezen, dan tegels'), findsOneWidget);
  });

  testDriftWidgets(
    'Windows: Ctrl+Shift+P on the selected item; Enter saves, Shift+Enter '
    'is a new line',
    (tester) async {
      await startApp(tester, width: 1280);
      await tester.tap(find.text('Offerte kozijnen vergelijken'));
      await tester.pumpAndSettle();
      // The list has the focus again, as after a click in it.
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);

      await tester.enterText(field(l10n.whereWasINextStep), 'Bellen');
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect((await rows()).single.nextStep, 'Bellen');
    },
    variant: windows,
  );
}
