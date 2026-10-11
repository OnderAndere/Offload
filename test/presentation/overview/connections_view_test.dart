import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/items/drift_item_repository.dart';
import 'package:offload/data/projects/drift_project_repository.dart';
import 'package:offload/data/search/drift_search_index.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/data/tokens/drift_token_processor.dart';
import 'package:offload/domain/connections/connection_graph.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/domain/tokens/inline_token.dart';
import 'package:offload/domain/tokens/inline_token_registry.dart';
import 'package:offload/l10n/app_localizations.dart';
import 'package:offload/presentation/app.dart';
import 'package:offload/presentation/capture/pending_captures.dart';
import 'package:offload/presentation/home/destination.dart';
import 'package:offload/presentation/items/item_detail_screen.dart';
import 'package:offload/presentation/overview/connections_providers.dart';
import 'package:offload/presentation/overview/connections_view.dart';
import 'package:offload/presentation/overview/insights_screen.dart';
import 'package:offload/presentation/people/person_screen.dart';
import 'package:offload/presentation/startup/app_storage_provider.dart';

import '../../fakes/drift_widgets.dart';
import '../../fakes/fake_capture_channel.dart';
import '../../fakes/fake_desktop_shell.dart';
import '../../fakes/test_storage.dart';

/// Connections, the fourth segment of Insights (T10.14, REQ-059, DD-018
/// point 15).
void main() {
  late AppStorage storage;
  late String coopId;
  late String meshId;
  const coopTitle = 'Kippenhok bouwen, eerst Gaas kopen';
  final l10n = lookupAppLocalizations(const Locale('nl'));
  final windows = TargetPlatformVariant.only(TargetPlatform.windows);

  Future<void> startApp(
    WidgetTester tester, {
    Destination start = Destination.insights,
    double width = 400,
  }) async {
    tester.view.physicalSize = Size(width, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.localesTestValue = const [Locale('nl')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    storage = await openTestStorage();
    addTearDown(storage.close);
    final items = DriftItemRepository(storage);
    final projects = DriftProjectRepository(storage);
    final processor = DriftTokenProcessor(
      storage,
      registry: InlineTokenRegistry.standard(),
      dates: () => DateVocabulary.empty,
    );
    final gardenId = await projects.create('Tuin');
    meshId = await items.capture('Gaas kopen', source: ItemSource.app);
    coopId = await items.capture(
      'Kippenhok bouwen, eerst [[Gaas kopen]] @Sanne',
      source: ItemSource.app,
      links: {'Gaas kopen': meshId},
    );
    final postId = await items.capture('Paal zetten', source: ItemSource.app);
    await items.setProject(coopId, gardenId);
    await items.setProject(postId, gardenId);
    for (final id in [meshId, coopId, postId]) {
      await processor.process(id);
    }
    await DriftSearchIndex(storage.database).processPending();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          destinationProvider.overrideWith((ref) => start),
          insightsSegmentProvider.overrideWith(
            (ref) => InsightsSegment.connections,
          ),
          appStorageProvider.overrideWith((ref) => storage),
          captureChannelProvider.overrideWith((ref) => FakeCaptureChannel()),
          desktopShellProvider.overrideWith((ref) => FakeDesktopShell()),
        ],
        child: const OffloadApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder inGraph(String text) => find.descendant(
    of: find.byType(ConnectionsView),
    matching: find.text(text),
  );

  Future<void> chooseFocus(WidgetTester tester, String query) async {
    await tester.tap(find.widgetWithText(FilledButton, l10n.connectionsChoose));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, query);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    await tester.tap(find.text(coopTitle));
    await tester.pumpAndSettle();
  }

  testDriftWidgets('phone: no focus yet, then choose one', (tester) async {
    await startApp(tester);
    expect(find.text(l10n.connectionsEmptyTitle), findsOneWidget);
    await chooseFocus(tester, 'kippen');

    expect(find.text(l10n.connectionsEmptyTitle), findsNothing);
    // The focus, and around it its link, its person and its project.
    expect(inGraph('Gaas kopen'), findsOneWidget);
    expect(inGraph('Sanne'), findsOneWidget);
    expect(inGraph('Tuin'), findsOneWidget);
    // On one step the project's other item is not drawn.
    expect(inGraph('Paal zetten'), findsNothing);

    await tester.tap(find.text(l10n.connectionsTwoSteps));
    await tester.pumpAndSettle();
    expect(inGraph('Paal zetten'), findsOneWidget);
    expect(find.text(l10n.connectionsLegendThrough), findsOneWidget);
  });

  testDriftWidgets('phone: a tap focuses, back returns', (tester) async {
    await startApp(tester);
    await chooseFocus(tester, 'kippen');
    await tester.tap(inGraph('Gaas kopen'));
    await tester.pumpAndSettle();
    // Gaas kopen is the focus now: its only line goes back to the coop item.
    expect(inGraph(coopTitle), findsWidgets);
    expect(inGraph('Sanne'), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(inGraph('Sanne'), findsOneWidget);
    expect(find.byType(InsightsScreen), findsOneWidget);
  });

  testDriftWidgets('phone: long press previews, Openen opens', (tester) async {
    await startApp(tester);
    await chooseFocus(tester, 'kippen');
    await tester.longPress(inGraph('Sanne'));
    await tester.pumpAndSettle();
    expect(find.text(l10n.connectionsFocusAction), findsOneWidget);
    expect(find.text(l10n.connectionsPreviewOpenItems(1)), findsOneWidget);
    await tester.tap(find.text(l10n.connectionsOpenAction));
    await tester.pumpAndSettle();
    expect(find.byType(PersonScreen), findsOneWidget);
  });

  testDriftWidgets('phone: an item opened last is the start focus, and '
      'Verbanden tonen in its menu', (tester) async {
    await startApp(tester, start: Destination.inbox);
    await tester.tap(find.text('Gaas kopen'));
    await tester.pumpAndSettle();
    expect(find.byType(ItemDetailScreen), findsOneWidget);
    await tester.tap(find.byType(PopupMenuButton<void>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.connectionsShow));
    await tester.pumpAndSettle();

    expect(find.byType(ItemDetailScreen), findsNothing);
    expect(find.byType(ConnectionsView), findsOneWidget);
    expect(find.text(l10n.connectionsEmptyTitle), findsNothing);
    expect(inGraph(coopTitle), findsOneWidget);
  });

  testDriftWidgets('the weekly review has no Connections', (tester) async {
    expect(
      shownSegment(InsightsSegment.connections, inReview: true),
      InsightsSegment.horizon,
    );
    expect(
      shownSegment(InsightsSegment.connections, inReview: false),
      InsightsSegment.connections,
    );
  });

  testDriftWidgets('Windows: the focus in the right pane; arrows and Enter', (
    tester,
  ) async {
    await startApp(tester, width: 1280);
    await chooseFocus(tester, 'kippen');
    // The item focus is in the right pane.
    expect(find.byType(ItemDetailScreen), findsOneWidget);

    // A person as the focus: the person in the right pane.
    await tester.tap(inGraph('Sanne'));
    await tester.pumpAndSettle();
    expect(find.byType(PersonScreen), findsOneWidget);

    // Escape in the graph goes back to the previous focus.
    await tester.tap(find.byKey(connectionsGraphKey), warnIfMissed: false);
    await tester.pumpAndSettle();
    final graphFocus = Focus.of(
      tester.element(find.byKey(connectionsGraphKey)),
    );
    graphFocus.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(PersonScreen), findsNothing);
    expect(inGraph('Sanne'), findsOneWidget);

    // An arrow selects a node, Enter makes it the focus.
    Focus.of(tester.element(find.byKey(connectionsGraphKey))).requestFocus();
    await tester.pump();
    for (final key in [
      LogicalKeyboardKey.arrowUp,
      LogicalKeyboardKey.arrowRight,
      LogicalKeyboardKey.arrowDown,
      LogicalKeyboardKey.arrowLeft,
    ]) {
      await tester.sendKeyEvent(key);
      await tester.pump();
      if (find
          .descendant(
            of: find.byType(ConnectionsView),
            matching: find.byWidgetPredicate(
              (w) => w is Semantics && w.properties.selected == true,
            ),
          )
          .evaluate()
          .isNotEmpty) {
        break;
      }
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ConnectionsView)),
    );
    expect(container.read(connectionsFocusProvider), isNotNull);
    expect(
      container.read(connectionsFocusProvider),
      isNot(NodeRef.item(coopId)),
    );
  }, variant: windows);
}
