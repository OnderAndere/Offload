import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/domain/ids/uuid_v7.dart';
import 'package:offload/domain/items/item.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/domain/overview/standstill.dart';
import 'package:offload/domain/projects/project.dart';
import 'package:offload/l10n/app_localizations.dart';
import 'package:offload/presentation/inbox/inbox_card.dart';
import 'package:offload/presentation/overview/overview_providers.dart';
import 'package:offload/presentation/overview/standstill_view.dart';
import 'package:offload/presentation/projects/project_providers.dart';
import 'package:offload/presentation/theme/app_theme.dart';

/// The Standstill (T10.7 step C, REQ-052, DD-018 point 12 (c)). The ages
/// need a last touch weeks ago, which the app cannot make: the view gets
/// a Standstill worked out from items in the test.
void main() {
  final l10n = lookupAppLocalizations(const Locale('nl'));
  final now = DateTime.utc(2026, 10, 2, 12);
  final windows = TargetPlatformVariant.only(TargetPlatform.windows);
  var n = 0;

  Item item(String text, int touchedDaysAgo, {String? project}) {
    final at = now.subtract(Duration(days: touchedDaysAgo, milliseconds: n++));
    return Item(
      id: UuidV7Generator(now: () => at.millisecondsSinceEpoch).next(),
      rawText: text,
      status: ItemStatus.active,
      source: ItemSource.app,
      type: ItemType.task,
      projectId: project,
      changedAt: at,
    );
  }

  const projects = [
    Project(id: 'club', name: 'Vereniging'),
    Project(id: 'house', name: 'Verbouwing'),
    Project(id: 'bike', name: 'Fiets'),
  ];

  final items = [
    for (var i = 0; i < 6; i++) item('Klus $i', 2 + i, project: 'house'),
    item('Jaarverslag herzien', 30, project: 'club'),
    item('Kascontrole regelen', 28, project: 'club'),
    item('Bandenplakset kopen', 51, project: 'bike'),
  ];

  /// The items the view works from; a test can change them.
  final testItems = StateProvider<List<Item>>((ref) => items);

  Future<void> start(
    WidgetTester tester, {
    List<Item>? data,
    bool inReview = false,
  }) async {
    tester.view.physicalSize = const Size(420, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          if (data != null) testItems.overrideWith((ref) => data),
          standstillProvider.overrideWith(
            (ref) => standstillOf(
              ref.watch(testItems),
              projects: projects,
              now: now,
            ),
          ),
          projectsProvider.overrideWith((ref) => Stream.value(projects)),
          minuteClockProvider.overrideWith((ref) => Stream.value(now)),
        ],
        child: MaterialApp(
          theme: offloadTheme(),
          locale: const Locale('nl'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: StandstillView(inReview: inReview)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('tiles with name, count and age; the three oldest below', (
    tester,
  ) async {
    await start(tester);
    expect(find.text('Verbouwing'), findsOneWidget);
    expect(find.text(l10n.standstillOpen(6)), findsOneWidget);
    expect(
      find.text(l10n.standstillStill(l10n.standstillAgeDays(2))),
      findsOneWidget,
    );
    expect(find.text(l10n.standstillOldest), findsOneWidget);
    expect(find.text('Bandenplakset kopen'), findsOneWidget);
    expect(find.text(l10n.standstillToReview), findsOneWidget);
    // The fourth oldest is not in the top 3.
    expect(find.text('Klus 5'), findsNothing);
  });

  testWidgets('a small tile still shows its name, count and age', (
    tester,
  ) async {
    await start(
      tester,
      data: [
        for (var i = 0; i < 40; i++) item('Klus $i', 2, project: 'house'),
        item('Bandenplakset kopen', 51, project: 'bike'),
      ],
    );
    // On the tile and as the project of the oldest item below.
    expect(find.text('Fiets'), findsNWidgets(2));
    expect(
      find.text(l10n.standstillTileShort(1, l10n.standstillAgeWeeks(7))),
      findsOneWidget,
    );
  });

  testWidgets('a tapped tile lists its items, then back to the oldest', (
    tester,
  ) async {
    await start(tester);
    await tester.tap(find.text('Verbouwing'));
    await tester.pumpAndSettle();
    expect(find.text(l10n.standstillProjectItems('Verbouwing', 6)), findsOne);
    expect(find.text('Klus 5'), findsOneWidget);
    expect(find.text(l10n.standstillOpenProject), findsOneWidget);
    await tester.tap(find.byTooltip(l10n.standstillShowOldest));
    await tester.pumpAndSettle();
    expect(find.text(l10n.standstillOldest), findsOneWidget);
  });

  testWidgets('the tapped tile stays when the tiles re-sort', (tester) async {
    // Vereniging and Verbouwing both 3: Vereniging first (project order).
    final club = [
      for (var i = 0; i < 3; i++) item('Club $i', 30 + i, project: 'club'),
    ];
    final house = [
      for (var i = 0; i < 3; i++) item('Huis $i', 2 + i, project: 'house'),
    ];
    await start(tester, data: [...club, ...house]);
    // The tile, not the project name in the list of the oldest.
    await tester.tap(find.bySemanticsLabel(RegExp('^Vereniging: ')));
    await tester.pumpAndSettle();
    expect(find.text(l10n.standstillProjectItems('Vereniging', 3)), findsOne);

    // One of Vereniging done: it now sorts after Verbouwing, and the list
    // still follows Vereniging.
    final container = ProviderScope.containerOf(
      tester.element(find.byType(StandstillView)),
    );
    container.read(testItems.notifier).state = [...club.skip(1), ...house];
    await tester.pumpAndSettle();
    expect(find.text(l10n.standstillProjectItems('Vereniging', 2)), findsOne);

    // Its last items gone: back to the oldest, and it stays forgotten.
    container.read(testItems.notifier).state = house;
    await tester.pumpAndSettle();
    expect(find.text(l10n.standstillOldest), findsOneWidget);
    container.read(testItems.notifier).state = [...club, ...house];
    await tester.pumpAndSettle();
    expect(find.text(l10n.standstillOldest), findsOneWidget);
  });

  testWidgets('a screen reader hears each tile as a sentence', (tester) async {
    await start(tester);
    expect(
      find.bySemanticsLabel(
        l10n.standstillTileSemantics(
          'Vereniging',
          2,
          l10n.standstillAgeSpokenWeeks(4),
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('inside the weekly review: no link to it', (tester) async {
    await start(tester, inReview: true);
    expect(find.text(l10n.standstillToReview), findsNothing);
  });

  testWidgets('nothing open: an explanation', (tester) async {
    await start(tester, data: const []);
    expect(find.text(l10n.standstillEmpty), findsOneWidget);
  });

  testWidgets('Windows: ← and → choose a tile', (tester) async {
    await start(tester);
    await tester.tap(find.text('Verbouwing'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(find.text(l10n.standstillProjectItems('Vereniging', 2)), findsOne);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(find.text(l10n.standstillProjectItems('Verbouwing', 6)), findsOne);
  }, variant: windows);
}
