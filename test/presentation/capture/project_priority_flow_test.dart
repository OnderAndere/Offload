import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/projects/drift_project_repository.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/l10n/app_localizations.dart';
import 'package:offload/presentation/app.dart';
import 'package:offload/presentation/capture/capture_screen.dart';
import 'package:offload/presentation/capture/pending_captures.dart';
import 'package:offload/presentation/inbox/inbox_card.dart';
import 'package:offload/presentation/startup/app_storage_provider.dart';

import '../../fakes/drift_widgets.dart';
import '../../fakes/fake_capture_channel.dart';
import '../../fakes/fake_desktop_shell.dart';
import '../../fakes/start_on_inbox.dart';
import '../../fakes/test_storage.dart';

/// `^project` and `*priority` while capturing (T10.5 step B, REQ-050,
/// DD-004 point 11; PO decisions 02-10-2026).
void main() {
  late AppStorage storage;
  late String keuken;
  final l10n = lookupAppLocalizations(const Locale('nl'));

  Future<void> startApp(WidgetTester tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('nl')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    storage = await openTestStorage();
    addTearDown(storage.close);
    final projects = DriftProjectRepository(storage);
    final verbouwing = await projects.create('Verbouwing');
    keuken = await projects.create('Keuken', parentId: verbouwing);
    await projects.create('Oude schuur');
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

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.byTooltip(l10n.captureSave));
    await tester.pumpAndSettle();
    expect(find.byType(CaptureScreen), findsNothing);
  }

  Future<String?> projectOfOnlyItem() async =>
      (await storage.database.select(storage.database.items).getSingle())
          .contextId;

  testDriftWidgets('^ lists the projects; a sub-project shows where it is', (
    tester,
  ) async {
    await startApp(tester);

    await type(tester, 'tegels ^k');
    expect(suggestion('Keuken'), findsOneWidget);
    expect(find.text(l10n.projectPath('Verbouwing', 'Keuken')), findsOneWidget);

    await tester.tap(suggestion('Keuken'));
    await tester.pumpAndSettle();
    expect(fieldText(tester), 'tegels ^Keuken ');
  });

  testDriftWidgets('a name with spaces goes in with a dash', (tester) async {
    await startApp(tester);
    await type(tester, 'dak ^oud');

    await tester.tap(suggestion('Oude schuur'));
    await tester.pumpAndSettle();

    expect(fieldText(tester), 'dak ^Oude-schuur ');
    // The live chip names the project.
    expect(find.widgetWithText(Chip, 'Oude schuur'), findsOneWidget);
  });

  testDriftWidgets('saving puts the item in the project', (tester) async {
    await startApp(tester);
    await type(tester, 'tegels ^verbouwing/keuken');

    await save(tester);

    expect(await projectOfOnlyItem(), keuken);
  });

  testDriftWidgets('"Create project" makes it at once; saving uses it', (
    tester,
  ) async {
    await startApp(tester);
    await type(tester, 'zaaien ^kas');

    expect(find.text(l10n.tokenSuggestionNewProject('kas')), findsOneWidget);
    await tester.tap(find.text(l10n.tokenSuggestionNewProject('kas')));
    await tester.pumpAndSettle();

    expect(fieldText(tester), 'zaaien ^kas ');
    final created = await (storage.database.select(
      storage.database.contexts,
    )..where((c) => c.name.equals('kas'))).getSingle();
    expect(created.parentId, isNull);

    await save(tester);
    expect(await projectOfOnlyItem(), created.id);
  });

  testDriftWidgets('an unknown name says so, and gets no project', (
    tester,
  ) async {
    await startApp(tester);
    await type(tester, 'zaaien ^onbekend');

    // Only telling: creating is "Create project" in the list (PO decision
    // 03-10-2026).
    expect(
      find.widgetWithText(Chip, l10n.tokenProjectNone('onbekend')),
      findsOneWidget,
    );
    expect(find.byType(ActionChip), findsNothing);
    await save(tester);
    expect(await projectOfOnlyItem(), isNull);
    expect(
      await storage.database.select(storage.database.contexts).get(),
      hasLength(3),
    );
  });

  testDriftWidgets('a name of sub-projects under two parents says so', (
    tester,
  ) async {
    await startApp(tester);
    final projects = DriftProjectRepository(storage);
    final tuin = await projects.create('Tuin');
    await projects.create('Keuken', parentId: tuin);
    await type(tester, 'tegels ^keuken');

    expect(
      find.widgetWithText(Chip, l10n.tokenProjectSeveral('keuken')),
      findsOneWidget,
    );
  });

  testDriftWidgets('* offers the priority words with their meaning', (
    tester,
  ) async {
    await startApp(tester);
    await type(tester, 'offerte *h');

    expect(suggestion('hoog'), findsOneWidget);
    expect(find.text(l10n.tokenPriorityChip('high')), findsWidgets);
    await tester.tap(suggestion('hoog'));
    await tester.pumpAndSettle();

    expect(fieldText(tester), 'offerte *hoog ');
    expect(
      find.widgetWithText(Chip, l10n.tokenPriorityChip('high')),
      findsOneWidget,
    );
  });

  testDriftWidgets('the card shows the priority, normal too', (tester) async {
    await startApp(tester);
    await type(tester, 'Offerte nakijken *hoog');
    await save(tester);

    expect(
      (await storage.database.select(storage.database.items).getSingle())
          .priority,
      ItemPriority.high,
    );
    expect(
      find.widgetWithText(Chip, l10n.tokenPriorityChip('high')),
      findsOneWidget,
    );

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await type(tester, 'Gras maaien *2');
    await save(tester);
    // Normal too (PO decision 02-10-2026, for consistency).
    expect(
      find.widgetWithText(Chip, l10n.tokenPriorityChip('normal')),
      findsOneWidget,
    );
    // The title leaves the tokens out.
    expect(find.text('Gras maaien'), findsOneWidget);

    // Without a priority word: no chip.
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await type(tester, 'Hek verven');
    await save(tester);
    expect(
      find.descendant(
        of: find.ancestor(
          of: find.text('Hek verven'),
          matching: find.byType(InboxCard),
        ),
        matching: find.byType(Chip),
      ),
      findsNothing,
    );
  });
}
