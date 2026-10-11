import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/database/app_database.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/presentation/app.dart';
import 'package:offload/presentation/capture/capture_screen.dart';
import 'package:offload/presentation/capture/pending_captures.dart';
import 'package:offload/presentation/startup/app_storage_provider.dart';

import '../../fakes/drift_widgets.dart';
import '../../fakes/fake_capture_channel.dart';
import '../../fakes/fake_desktop_shell.dart';
import '../../fakes/start_on_inbox.dart';
import '../../fakes/test_storage.dart';

/// The suggestion list in the capture screen (REQ-033; PO decisions
/// 27-09-2026).
void main() {
  late AppStorage storage;

  Future<void> startApp(WidgetTester tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('nl')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    storage = await openTestStorage();
    addTearDown(storage.close);
    for (final name in ['Jan', 'Janneke', 'Piet']) {
      await storage.writer.insert(
        storage.database.people,
        PeopleCompanion(name: Value(name)),
      );
    }
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
    // The capture button: extended on a phone, + in the rail on Windows.
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
  }

  Future<void> type(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.pumpAndSettle();
  }

  String fieldText(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField)).controller!.text;

  Finder suggestion(String label) =>
      find.descendant(of: find.byType(ListTile), matching: find.text(label));

  testDriftWidgets('@ lists the people, filtered while typing', (tester) async {
    await startApp(tester);

    await type(tester, 'bel @');
    expect(suggestion('Jan'), findsOneWidget);
    expect(suggestion('Piet'), findsOneWidget);

    await type(tester, 'bel @Ja');
    expect(suggestion('Jan'), findsOneWidget);
    expect(suggestion('Janneke'), findsOneWidget);
    expect(suggestion('Piet'), findsNothing);
  });

  testDriftWidgets('tapping a suggestion completes the token and a space', (
    tester,
  ) async {
    await startApp(tester);
    await type(tester, 'bel @Jann');

    await tester.tap(suggestion('Janneke'));
    await tester.pumpAndSettle();

    expect(fieldText(tester), 'bel @Janneke ');
    expect(find.byType(ListTile), findsNothing);
  });

  testDriftWidgets(
    'choosing inside the text keeps what follows, e.g. a bracket',
    (tester) async {
      await startApp(tester);
      await tester.showKeyboard(find.byType(TextField));
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'bel (@Jann) nu',
          selection: TextSelection.collapsed(offset: 10),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(suggestion('Janneke'));
      await tester.pumpAndSettle();

      expect(fieldText(tester), 'bel (@Janneke) nu');
      final selection = tester
          .widget<TextField>(find.byType(TextField))
          .controller!
          .selection;
      expect(selection.baseOffset, 'bel (@Janneke'.length);
      // Chosen: the list closes, also with the cursor still in the token.
      expect(find.byType(ListTile), findsNothing);
    },
  );

  testDriftWidgets('no "new" line behind punctuation of a known name', (
    tester,
  ) async {
    await startApp(tester);

    await type(tester, 'bel @Jan.');

    expect(find.textContaining('Nieuw'), findsNothing);
    expect(find.byType(ListTile), findsNothing);
  });

  testDriftWidgets('an unknown name is offered as new', (tester) async {
    await startApp(tester);

    await type(tester, 'bel @Kees');

    expect(find.text('Nieuw: Kees'), findsOneWidget);
    // Not created yet: only when the item is saved (PO decision).
    expect(
      await storage.database.select(storage.database.people).get(),
      hasLength(3),
    );
  });

  testDriftWidgets('a date suggestion inserts the full word', (tester) async {
    await startApp(tester);
    await type(tester, 'klaar !vr');

    expect(suggestion('vrijdag'), findsOneWidget);
    await tester.tap(suggestion('vrijdag'));
    await tester.pumpAndSettle();

    expect(fieldText(tester), 'klaar !vrijdag ');
  });

  testDriftWidgets('saving works with an unfinished token (REQ-001)', (
    tester,
  ) async {
    await startApp(tester);
    await type(tester, 'bel @Ja');

    await tester.tap(find.byTooltip('Opslaan'));
    await tester.pumpAndSettle();

    expect(find.byType(CaptureScreen), findsNothing);
    final item = await storage.database
        .select(storage.database.items)
        .getSingle();
    expect(item.rawText, 'bel @Ja');
  });

  group('keyboard on Windows (PO decision 27-09-2026)', () {
    final windows = TargetPlatformVariant.only(TargetPlatform.windows);

    testDriftWidgets('Enter chooses the top suggestion, then saves', (
      tester,
    ) async {
      await startApp(tester);
      await type(tester, 'bel @Pi');

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(fieldText(tester), 'bel @Piet ');
      expect(find.byType(CaptureScreen), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(CaptureScreen), findsNothing);
    }, variant: windows);

    testDriftWidgets('choosing mid-text with Enter, then Enter saves', (
      tester,
    ) async {
      await startApp(tester);
      await tester.showKeyboard(find.byType(TextField));
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'bel @Pi nu',
          selection: TextSelection.collapsed(offset: 7),
        ),
      );
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(fieldText(tester), 'bel @Piet nu');
      expect(find.byType(ListTile), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(CaptureScreen), findsNothing);
    }, variant: windows);

    testDriftWidgets('the arrows move the choice; Tab chooses', (tester) async {
      await startApp(tester);
      await type(tester, 'bel @Ja');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      expect(fieldText(tester), 'bel @Janneke ');
    }, variant: windows);

    testDriftWidgets('Escape closes only the list; Enter then saves', (
      tester,
    ) async {
      await startApp(tester);
      await type(tester, 'bel @Ja');

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(ListTile), findsNothing);
      expect(find.byType(CaptureScreen), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(CaptureScreen), findsNothing);
    }, variant: windows);
  });
}
