import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/l10n/app_localizations.dart';
import 'package:offload/presentation/app.dart';
import 'package:offload/presentation/capture/pending_captures.dart';
import 'package:offload/presentation/startup/app_storage_provider.dart';

import '../fakes/drift_widgets.dart';
import '../fakes/fake_capture_channel.dart';
import '../fakes/fake_desktop_shell.dart';
import '../fakes/test_storage.dart';

/// A restored backup that did not open: the previous data came back, and the
/// app says so once after start (T7.2 follow-up, DD-007).
void main() {
  final l10n = lookupAppLocalizations(const Locale('nl'));

  Future<void> start(WidgetTester tester, {required bool undone}) async {
    tester.platformDispatcher.localesTestValue = const [Locale('nl')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final AppStorage storage = await openTestStorage()
      ..restoreUndoneForTest = undone;
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
  }

  testDriftWidgets('after an undone restore the app says so, once', (
    tester,
  ) async {
    await start(tester, undone: true);
    expect(find.text(l10n.restoreUndoneTitle), findsOneWidget);
    expect(find.text(l10n.restoreUndoneBody), findsOneWidget);

    await tester.tap(find.text(l10n.restoreUndoneOk));
    await tester.pumpAndSettle();
    expect(find.text(l10n.restoreUndoneTitle), findsNothing);
  });

  testDriftWidgets('a normal start says nothing', (tester) async {
    await start(tester, undone: false);
    expect(find.text(l10n.restoreUndoneTitle), findsNothing);
  });
}
