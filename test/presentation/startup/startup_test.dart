import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/presentation/app.dart';
import 'package:offload/presentation/capture/pending_captures.dart';
import 'package:offload/presentation/startup/app_storage_provider.dart';

import '../../fakes/drift_widgets.dart';
import '../../fakes/fake_capture_channel.dart';
import '../../fakes/fake_desktop_shell.dart';
import '../../fakes/start_on_inbox.dart';
import '../../fakes/test_storage.dart';

void main() {
  Future<void> startApp(
    WidgetTester tester,
    FutureOr<AppStorage> Function() open,
  ) async {
    tester.platformDispatcher.localesTestValue = const [Locale('nl')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          startOnInbox,
          appStorageProvider.overrideWith((ref) => open()),
          captureChannelProvider.overrideWith((ref) => FakeCaptureChannel()),
          desktopShellProvider.overrideWith((ref) => FakeDesktopShell()),
        ],
        child: const OffloadApp(),
      ),
    );
  }

  testDriftWidgets('shows progress while the storage opens', (tester) async {
    await startApp(tester, () => Completer<AppStorage>().future);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.bySemanticsLabel('Offload wordt gestart'), findsOneWidget);
  });

  group('start-up errors say what happened and change nothing (DD-007)', () {
    final cases = {
      StorageFailure.missingKey: 'Sleutel ontbreekt',
      StorageFailure.keyUnavailable: 'Sleutel niet leesbaar',
      StorageFailure.databaseUnavailable: 'Gegevens niet te openen',
    };
    for (final MapEntry(key: failure, value: title) in cases.entries) {
      testDriftWidgets(failure.name, (tester) async {
        await startApp(
          tester,
          () => throw StorageOpenException(failure, 'cause'),
        );
        await tester.pumpAndSettle();

        expect(find.text(title), findsOneWidget);
        expect(find.text('Opnieuw proberen'), findsOneWidget);
        expect(find.textContaining('Technische details:'), findsOneWidget);
      });
    }

    testDriftWidgets('an unexpected error', (tester) async {
      await startApp(tester, () => throw StateError('no directory'));
      await tester.pumpAndSettle();

      expect(find.text('Offload kan niet starten'), findsOneWidget);
      expect(find.textContaining('no directory'), findsOneWidget);
    });

    testDriftWidgets('the missing-key text says no new key is made', (
      tester,
    ) async {
      await startApp(
        tester,
        () => throw StorageOpenException(StorageFailure.missingKey, 'cause'),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Offload maakt geen nieuwe sleutel aan'),
        findsOneWidget,
      );
    });
  });

  testDriftWidgets('retry opens the storage again', (tester) async {
    var attempts = 0;
    final storage = await openTestStorage();
    addTearDown(storage.close);
    await startApp(tester, () {
      attempts++;
      if (attempts == 1) {
        throw StorageOpenException(StorageFailure.keyUnavailable, 'busy');
      }
      return storage;
    });
    await tester.pumpAndSettle();

    await tester.tap(find.text('Opnieuw proberen'));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.text('Nog geen items'), findsOneWidget);
  });
}
