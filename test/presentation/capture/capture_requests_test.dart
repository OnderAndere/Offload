import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/presentation/app.dart';
import 'package:offload/presentation/capture/capture_screen.dart';
import 'package:offload/presentation/capture/pending_captures.dart';
import 'package:offload/presentation/startup/app_storage_provider.dart';

import '../../fakes/drift_widgets.dart';
import '../../fakes/fake_capture_channel.dart';
import '../../fakes/fake_desktop_shell.dart';
import '../../fakes/start_on_inbox.dart';
import '../../fakes/test_storage.dart';

/// Quick capture from anywhere in Windows (REQ-017, DD-010, T1.7 step B):
/// the hotkey and the tray menu ask the running app for its capture screen.
void main() {
  late AppStorage storage;
  late FakeCaptureChannel channel;
  late FakeDesktopShell shell;

  Future<void> startApp(WidgetTester tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('nl')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    storage = await openTestStorage();
    addTearDown(storage.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          startOnInbox,
          appStorageProvider.overrideWith((ref) => storage),
          captureChannelProvider.overrideWith((ref) => channel),
          desktopShellProvider.overrideWith((ref) => shell),
        ],
        child: const OffloadApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<ItemSource> storedSource() async =>
      (await storage.database.select(storage.database.items).getSingle())
          .source;

  setUp(() {
    channel = FakeCaptureChannel();
    shell = FakeDesktopShell();
  });

  testDriftWidgets(
    'the hotkey opens capture; the item records the hotkey as source',
    (tester) async {
      await startApp(tester);

      channel.requestCapture(ItemSource.hotkey);
      await tester.pumpAndSettle();

      expect(find.byType(CaptureScreen), findsOneWidget);
      final field = tester.widget<EditableText>(find.byType(EditableText));
      expect(field.focusNode.hasFocus, isTrue);
      await tester.enterText(find.byType(TextField), 'Via de sneltoets');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(find.byType(CaptureScreen), findsNothing);
      expect(await storedSource(), ItemSource.hotkey);
      // The platform may now put back what was in front.
      expect(channel.requestsHandled, 1);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );

  testDriftWidgets('the tray menu records the tray as source', (tester) async {
    await startApp(tester);

    channel.requestCapture(ItemSource.tray);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Via het systeemvak');
    await tester.pump();
    await tester.tap(find.byTooltip('Opslaan'));
    await tester.pumpAndSettle();

    expect(await storedSource(), ItemSource.tray);
    expect(channel.requestsHandled, 1);
  });

  testDriftWidgets('closing without saving is reported too', (tester) async {
    await startApp(tester);
    channel.requestCapture(ItemSource.hotkey);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();

    expect(find.byType(CaptureScreen), findsNothing);
    expect(channel.requestsHandled, 1);
    expect(
      await storage.database.select(storage.database.items).get(),
      isEmpty,
    );
  });

  testDriftWidgets('a second request opens no second capture screen', (
    tester,
  ) async {
    await startApp(tester);
    channel.requestCapture(ItemSource.hotkey);
    await tester.pumpAndSettle();

    channel.requestCapture(ItemSource.hotkey);
    await tester.pumpAndSettle();

    expect(find.byType(CaptureScreen), findsOneWidget);
  });

  testDriftWidgets(
    'a request while capture is open from the button keeps the typed text',
    (tester) async {
      await startApp(tester);
      // The capture button: extended on a phone, + in the rail on Windows.
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Half getypt');

      channel.requestCapture(ItemSource.hotkey);
      await tester.pumpAndSettle();

      // No second screen over the unsaved text, and not yet handled.
      expect(find.byType(CaptureScreen), findsOneWidget);
      expect(find.text('Half getypt'), findsOneWidget);
      expect(channel.requestsHandled, 0);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(find.byType(CaptureScreen), findsNothing);
      expect(channel.requestsHandled, 1);
      expect(await storedSource(), ItemSource.app);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );

  testDriftWidgets('a hotkey taken by another program is reported', (
    tester,
  ) async {
    channel.hotkeyRegisteredValue = false;
    await startApp(tester);

    const text =
        'De sneltoets Win+Shift+B is al in gebruik door een ander programma. '
        'Vastleggen kan via het systeemvak of met de knop Vastleggen.';
    expect(find.text(text), findsOneWidget);

    await tester.tap(find.byTooltip('Sluiten'));
    await tester.pumpAndSettle();
    expect(find.text(text), findsNothing);
  });

  testDriftWidgets('no note when the hotkey works or does not exist', (
    tester,
  ) async {
    channel.hotkeyRegisteredValue = true;
    await startApp(tester);

    expect(find.textContaining('Win+Shift+B'), findsNothing);
  });

  testDriftWidgets('the tray gets its texts in the active language', (
    tester,
  ) async {
    await startApp(tester);

    expect(shell.sent.last.newItem, 'Nieuw item');
    expect(shell.sent.last.open, 'Openen');
    expect(shell.sent.last.quit, 'Afsluiten');
    expect(shell.sent.last.tooltip, 'Offload');

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(shell.sent.last.newItem, 'New item');
    expect(shell.sent.last.quit, 'Quit');
  });
}
