import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/items/drift_item_repository.dart';
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

/// "Bestaat dit al?" in the inbox (REQ-053, T2.5 step C; PO decisions
/// 27-09-2026).
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
    final items = DriftItemRepository(storage);
    await items.capture(
      'Offerte renovatie opvragen bij Jan',
      source: ItemSource.app,
    );
    await items.capture('Bel Piet', source: ItemSource.app);
    await DriftSearchIndex(storage.database).processPending();
    await items.capture('offerte renovatie opvragen', source: ItemSource.app);
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

  testDriftWidgets('one hint, on the newer item of the pair', (tester) async {
    await startApp(tester);

    expect(find.text('Lijkt op een ander item'), findsOneWidget);
    // The hint sits right under the newer item (the list is newest first).
    final newer = tester.getRect(find.text('offerte renovatie opvragen'));
    final hint = tester.getRect(find.text('Lijkt op een ander item'));
    final older = tester.getRect(
      find.text('Offerte renovatie opvragen bij Jan'),
    );
    expect(hint.top, greaterThan(newer.top));
    expect(hint.top, lessThan(older.top));
  });

  testDriftWidgets('the comparison shows both; closing changes nothing', (
    tester,
  ) async {
    await startApp(tester);

    await tester.tap(find.text('Lijkt op een ander item'));
    await tester.pumpAndSettle();

    final dialog = find.byType(AlertDialog);
    expect(
      find.descendant(of: dialog, matching: find.text('Bestaat dit al?')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: dialog,
        matching: find.text('offerte renovatie opvragen'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: dialog,
        matching: find.text('Offerte renovatie opvragen bij Jan'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Sluiten'));
    await tester.pumpAndSettle();
    expect(find.text('Lijkt op een ander item'), findsOneWidget);
    expect(
      await storage.database.select(storage.database.duplicateDismissals).get(),
      isEmpty,
    );
  });

  testDriftWidgets('ignoring removes the hint and is stored', (tester) async {
    await startApp(tester);

    await tester.tap(find.text('Lijkt op een ander item'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Negeren'));
    await tester.pumpAndSettle();

    expect(find.text('Lijkt op een ander item'), findsNothing);
    expect(
      await storage.database.select(storage.database.duplicateDismissals).get(),
      hasLength(1),
    );
    // Nothing merged or deleted.
    expect(find.text('Offerte renovatie opvragen bij Jan'), findsOneWidget);
    expect(find.text('offerte renovatie opvragen'), findsOneWidget);
  });

  testDriftWidgets('a new capture that repeats an item gets the hint', (
    tester,
  ) async {
    await startApp(tester);
    await tester.tap(find.text('Lijkt op een ander item'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Negeren'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Vastleggen'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Bel Piet');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Opslaan'));
    await tester.pumpAndSettle();

    expect(find.text('Lijkt op een ander item'), findsOneWidget);
  });

  testDriftWidgets('in English', (tester) async {
    await startApp(tester, locale: const Locale('en'));

    await tester.tap(find.text('Looks like another item'));
    await tester.pumpAndSettle();

    expect(find.text('Is this already there?'), findsOneWidget);
    expect(find.text('Ignore'), findsOneWidget);
  });
}
