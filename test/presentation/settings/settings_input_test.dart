import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/domain/settings/prefix_bar_mode.dart';
import 'package:offload/presentation/app.dart';
import 'package:offload/presentation/capture/pending_captures.dart';
import 'package:offload/presentation/startup/app_storage_provider.dart';
import 'package:offload/presentation/tokens/prefix_bar.dart';

import '../../fakes/drift_widgets.dart';
import '../../fakes/fake_capture_channel.dart';
import '../../fakes/fake_desktop_shell.dart';
import '../../fakes/test_storage.dart';

/// Settings → Input: the prefix bar (REQ-034).
void main() {
  late AppStorage storage;

  Future<void> openSettings(WidgetTester tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('nl')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    storage = await openTestStorage();
    addTearDown(storage.close);
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
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
  }

  RadioListTile<PrefixBarMode> option(WidgetTester tester, String title) =>
      tester.widget<RadioListTile<PrefixBarMode>>(
        find.widgetWithText(RadioListTile<PrefixBarMode>, title),
      );

  testDriftWidgets('three options, always visible by default', (tester) async {
    await openSettings(tester);
    // The list is long: each line is scrolled into view before it is
    // looked for (a list only builds what is near the screen).
    for (final text in [
      'Invoer',
      'Prefix-balk',
      'Altijd zichtbaar',
      'Ingeklapt',
      'Uit',
    ]) {
      await tester.scrollUntilVisible(find.text(text), 100);
      expect(find.text(text), findsOneWidget);
    }
    final group = tester.widget<RadioGroup<PrefixBarMode>>(
      find.byType(RadioGroup<PrefixBarMode>),
    );
    expect(group.groupValue, PrefixBarMode.always);
    expect(option(tester, 'Altijd zichtbaar').value, PrefixBarMode.always);
  });

  testDriftWidgets('choosing off stores it and hides the bar', (tester) async {
    await openSettings(tester);
    // The list is built lazily: scroll until the choice exists.
    await tester.scrollUntilVisible(
      find.text('Uit'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Uit'));
    await tester.pumpAndSettle();
    expect(storage.prefixBarMode, PrefixBarMode.off);

    // pageBack() looks for the English tooltip; this test runs in Dutch.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vastleggen'));
    await tester.pumpAndSettle();
    expect(find.byType(PrefixBar), findsNothing);
  });

  testDriftWidgets('the language choice still works beside it', (tester) async {
    await openSettings(tester);

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(storage.prefixBarMode, PrefixBarMode.always);
  });
}
