import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/domain/time/local_date.dart';
import 'package:offload/domain/tokens/token_processing.dart';
import 'package:offload/presentation/app.dart';
import 'package:offload/presentation/capture/capture_screen.dart';
import 'package:offload/presentation/capture/pending_captures.dart';
import 'package:offload/presentation/startup/app_storage_provider.dart';

import '../../fakes/drift_widgets.dart';
import '../../fakes/fake_capture_channel.dart';
import '../../fakes/fake_desktop_shell.dart';
import '../../fakes/start_on_inbox.dart';
import '../../fakes/test_storage.dart';

/// Quick capture and the live inbox through the real app (REQ-001, REQ-018,
/// T1.6), on an in-memory database.
void main() {
  late AppStorage storage;

  Future<void> startApp(
    WidgetTester tester, {
    Locale locale = const Locale('nl'),
  }) async {
    tester.platformDispatcher.localesTestValue = [locale];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    storage = await openTestStorage();
    addTearDown(storage.close);
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

  Future<void> openCapture(WidgetTester tester) async {
    // The capture button: extended on a phone, + in the rail on Windows.
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
  }

  Future<List<String>> storedTexts() async => [
    for (final row
        in await storage.database.select(storage.database.items).get())
      row.rawText,
  ];

  EditableText editable(WidgetTester tester) =>
      tester.widget<EditableText>(find.byType(EditableText));

  testDriftWidgets('the empty inbox says so', (tester) async {
    await startApp(tester);

    expect(find.widgetWithText(AppBar, 'Inbox'), findsOneWidget);
    expect(find.text('Nog geen items'), findsOneWidget);
  });

  testDriftWidgets('capture opens with the focus in the text field', (
    tester,
  ) async {
    await startApp(tester);
    await openCapture(tester);

    expect(find.byType(CaptureScreen), findsOneWidget);
    expect(editable(tester).focusNode.hasFocus, isTrue);
  });

  testDriftWidgets(
    'desktop: Enter saves, the screen closes and the inbox shows the item',
    (tester) async {
      await startApp(tester);
      await openCapture(tester);
      await tester.enterText(find.byType(TextField), 'Bel Jan over de markt');

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(find.byType(CaptureScreen), findsNothing);
      expect(find.text('Bel Jan over de markt'), findsOneWidget);
      expect(find.text('1 item'), findsOneWidget);
      final row = await storage.database
          .select(storage.database.items)
          .getSingle();
      expect(row.status, ItemStatus.inbox);
      expect(row.source, ItemSource.app);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );

  testDriftWidgets(
    'desktop: Shift+Enter does not save',
    (tester) async {
      await startApp(tester);
      await openCapture(tester);
      await tester.enterText(find.byType(TextField), 'eerste regel');

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();

      expect(find.byType(CaptureScreen), findsOneWidget);
      expect(await storedTexts(), isEmpty);
      expect(editable(tester).keyboardType, TextInputType.multiline);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );

  testDriftWidgets(
    'phone: the keyboard action saves and there are no line breaks',
    (tester) async {
      await startApp(tester);
      await openCapture(tester);
      expect(editable(tester).keyboardType, TextInputType.text);
      expect(editable(tester).textInputAction, TextInputAction.done);
      await tester.enterText(find.byType(TextField), 'Idee voor de afvoer');

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.byType(CaptureScreen), findsNothing);
      expect(await storedTexts(), ['Idee voor de afvoer']);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testDriftWidgets('recognised tokens show as chips while typing (REQ-019)', (
    tester,
  ) async {
    await startApp(tester);
    await openCapture(tester);

    await tester.enterText(
      find.byType(TextField),
      r'bel @Jan over #renovatie !morgen \@niet jan@example.org',
    );
    await tester.pump();

    expect(find.byType(Chip), findsNWidgets(4));
    expect(find.widgetWithText(Chip, 'Jan'), findsOneWidget);
    // The address goes to the one person in the text (T3.6).
    expect(find.widgetWithText(Chip, 'jan@example.org → Jan'), findsOneWidget);
    expect(find.widgetWithText(Chip, 'renovatie'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^datum: ')), findsOneWidget);
    expect(find.bySemanticsLabel('persoon: Jan'), findsOneWidget);
  });

  testDriftWidgets(
    'long text scrolls inside the field; the chips stay visible',
    (tester) async {
      await startApp(tester);
      await openCapture(tester);
      final lines = [for (var i = 0; i < 80; i++) 'regel $i'].join('\n');

      await tester.enterText(find.byType(TextField), '@Jan $lines');
      await tester.pump();

      expect(tester.takeException(), isNull);
      final screen = tester.getSize(find.byType(Scaffold).last);
      final chip = tester.getRect(find.widgetWithText(Chip, 'Jan'));
      expect(chip.bottom, lessThanOrEqualTo(screen.height));
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );

  testDriftWidgets(
    'long text on a phone: no overflow either',
    (tester) async {
      await startApp(tester);
      await openCapture(tester);
      final longText = List.filled(400, 'woord').join(' ');

      await tester.enterText(find.byType(TextField), '#renovatie $longText');
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.widgetWithText(Chip, 'renovatie'), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testDriftWidgets(
    'after saving, the person, tag and deadline are worked out (step B)',
    (tester) async {
      await startApp(tester);
      await openCapture(tester);
      await tester.enterText(
        find.byType(TextField),
        'Bel (@Jan) #renovatie !morgen',
      );
      await tester.pump();

      await tester.tap(find.byTooltip('Opslaan'));
      await tester.pumpAndSettle();

      final db = storage.database;
      expect((await db.select(db.people).getSingle()).name, 'Jan');
      expect((await db.select(db.tags).getSingle()).name, 'renovatie');
      final item = await db.select(db.items).getSingle();
      final tomorrow = LocalDate.of(DateTime.now()).addDays(1);
      expect(storedToDateOnly(item.dueAt!), tomorrow);
      expect(item.rawText, 'Bel (@Jan) #renovatie !morgen');
    },
  );

  testDriftWidgets('no chips for plain text', (tester) async {
    await startApp(tester);
    await openCapture(tester);

    await tester.enterText(find.byType(TextField), 'Gewoon een gedachte');
    await tester.pump();

    expect(find.byType(Chip), findsNothing);
  });

  testDriftWidgets('the save button stores the text as typed', (tester) async {
    await startApp(tester);
    await openCapture(tester);
    await tester.enterText(find.byType(TextField), '  @Jan !vr  ');
    await tester.pump();

    await tester.tap(find.byTooltip('Opslaan'));
    await tester.pumpAndSettle();

    expect(await storedTexts(), ['  @Jan !vr  ']);
  });

  testDriftWidgets(
    'empty text cannot be saved',
    (tester) async {
      await startApp(tester);
      await openCapture(tester);
      await tester.enterText(find.byType(TextField), '   ');
      await tester.pump();

      final save = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.check),
      );
      expect(save.onPressed, isNull);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(find.byType(CaptureScreen), findsOneWidget);
      expect(await storedTexts(), isEmpty);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );

  testDriftWidgets('when saving fails the text stays, with a message', (
    tester,
  ) async {
    await startApp(tester);
    await openCapture(tester);
    await tester.enterText(find.byType(TextField), 'Niet kwijtraken');
    await tester.pump();
    await tester.runAsync(storage.close); // every later write fails

    await tester.tap(find.byTooltip('Opslaan'));
    // Let the failing database call complete in real time.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CaptureScreen), findsOneWidget);
    expect(find.text('Niet kwijtraken'), findsOneWidget);
    expect(
      find.text(
        'Opslaan is mislukt. Je tekst staat er nog; probeer het opnieuw.',
      ),
      findsOneWidget,
    );
  });

  testDriftWidgets(
    'newest capture first, with the relative time in the active language',
    (tester) async {
      await startApp(tester);
      final repositoryInput = ['eerste', 'tweede'];
      for (final text in repositoryInput) {
        await openCapture(tester);
        await tester.enterText(find.byType(TextField), text);
        await tester.pump();
        await tester.tap(find.byTooltip('Opslaan'));
        await tester.pumpAndSettle();
        // Distinct milliseconds, so the UUIDv7 order is the capture order.
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 2)),
        );
      }

      final first = tester.getTopLeft(find.text('eerste')).dy;
      final second = tester.getTopLeft(find.text('tweede')).dy;
      expect(second, lessThan(first));
      expect(find.text('2 items'), findsOneWidget);
      // Relative time in Dutch (DD-018 point 2): both were just captured.
      expect(find.text('zojuist'), findsNWidgets(2));
    },
  );
}
