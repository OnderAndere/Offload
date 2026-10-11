import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/database/app_database.dart' hide SearchIndex;
import 'package:offload/data/items/drift_item_repository.dart';
import 'package:offload/data/search/drift_search_index.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/presentation/app.dart';
import 'package:offload/presentation/capture/pending_captures.dart';
import 'package:offload/presentation/search/search_screen.dart';
import 'package:offload/presentation/startup/app_storage_provider.dart';

import '../../fakes/drift_widgets.dart';
import '../../fakes/fake_capture_channel.dart';
import '../../fakes/fake_desktop_shell.dart';
import '../../fakes/test_storage.dart';

/// The plain search screen (REQ-011, T2.5 step B; PO decision 27-09-2026).
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
    await items.capture('Keuring van de afvoer', source: ItemSource.app);
    final gone = await items.capture('Keuring oud', source: ItemSource.app);
    await storage.writer.delete(storage.database.items, gone);
    await storage.writer.insert(
      storage.database.people,
      const PeopleCompanion(name: Value('Jan'), note: Value('Moestuin')),
    );
    await DriftSearchIndex(storage.database).processPending();
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

  Future<void> openSearch(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
  }

  Future<void> type(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.pumpAndSettle();
  }

  testDriftWidgets('the search button opens search with the field ready', (
    tester,
  ) async {
    await startApp(tester);

    expect(find.byTooltip('Zoeken'), findsOneWidget);
    await openSearch(tester);

    expect(find.byType(SearchScreen), findsOneWidget);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.focusNode?.hasFocus ?? field.autofocus, isTrue);
    expect(
      find.text('Typ een of meer woorden. Het begin van een woord is genoeg.'),
      findsOneWidget,
    );
  });

  testDriftWidgets('results while typing; the start of a word is enough', (
    tester,
  ) async {
    await startApp(tester);
    await openSearch(tester);

    await type(tester, 'keur');

    expect(find.text('Keuring van de afvoer'), findsOneWidget);
    expect(
      find.byWidgetPredicate((w) => w is Icon && w.semanticLabel == 'Item'),
      findsOneWidget,
    );
    // In the trash: not found.
    expect(find.text('Keuring oud'), findsNothing);
  });

  testDriftWidgets('people with their note', (tester) async {
    await startApp(tester);
    await openSearch(tester);

    await type(tester, 'moestu');

    expect(find.text('Jan'), findsOneWidget);
    expect(find.text('Moestuin'), findsOneWidget);
    expect(
      find.byWidgetPredicate((w) => w is Icon && w.semanticLabel == 'Persoon'),
      findsOneWidget,
    );
  });

  testDriftWidgets('nothing found, and clearing starts over', (tester) async {
    await startApp(tester);
    await openSearch(tester);

    await type(tester, 'xyz');
    expect(find.text('Niets gevonden voor „xyz”'), findsOneWidget);

    await tester.tap(find.byTooltip('Wissen'));
    await tester.pumpAndSettle();
    expect(
      find.text('Typ een of meer woorden. Het begin van een woord is genoeg.'),
      findsOneWidget,
    );
    expect(find.byTooltip('Wissen'), findsNothing);
  });

  testDriftWidgets('a new capture becomes findable by itself', (tester) async {
    await startApp(tester);

    await tester.tap(find.text('Vastleggen'));
    await tester.pumpAndSettle();
    await type(tester, 'Offerte renovatie');
    await tester.tap(find.byTooltip('Opslaan'));
    await tester.pumpAndSettle();

    await openSearch(tester);
    await type(tester, 'offerte');
    expect(
      find.descendant(
        of: find.byType(SearchScreen),
        matching: find.text('Offerte renovatie'),
      ),
      findsOneWidget,
    );
  });

  testDriftWidgets('in English', (tester) async {
    await startApp(tester, locale: const Locale('en'));
    await openSearch(tester);

    await type(tester, 'xyz');

    expect(find.text('Nothing found for “xyz”'), findsOneWidget);
  });
}
