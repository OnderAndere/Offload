import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/items/drift_item_repository.dart';
import 'package:offload/data/people/drift_people_repository.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/domain/items/item_classification.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/l10n/app_localizations.dart';
import 'package:offload/presentation/app.dart';
import 'package:offload/presentation/capture/pending_captures.dart';
import 'package:offload/presentation/home/destination.dart';
import 'package:offload/presentation/overview/horizon_view.dart';
import 'package:offload/presentation/overview/insights_screen.dart';
import 'package:offload/presentation/overview/standstill_view.dart';
import 'package:offload/presentation/people/people_screen.dart';
import 'package:offload/presentation/people/person_screen.dart';
import 'package:offload/presentation/review/weekly_review_screen.dart';
import 'package:offload/presentation/settings/settings_screen.dart';
import 'package:offload/presentation/startup/app_storage_provider.dart';

import '../../fakes/drift_widgets.dart';
import '../../fakes/fake_capture_channel.dart';
import '../../fakes/fake_desktop_shell.dart';
import '../../fakes/test_storage.dart';

/// The Overview destination, NL "Inzicht" (T10.7 step D, REQ-052, DD-018
/// point 12): the tab, its segments, the first step of the weekly review,
/// the setting; Windows with both panes.
void main() {
  late AppStorage storage;
  final l10n = lookupAppLocalizations(const Locale('nl'));
  final windows = TargetPlatformVariant.only(TargetPlatform.windows);

  Future<void> startApp(
    WidgetTester tester, {
    Destination start = Destination.today,
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
    final jan = await DriftPeopleRepository(storage).idFor('Jan Bakker');
    final id = await items.capture('Offerte nakijken', source: ItemSource.app);
    await items.classify(
      id,
      ItemClassification(
        type: ItemType.request,
        status: ItemStatus.active,
        requesterId: jan,
        waitingOnId: null,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          destinationProvider.overrideWith((ref) => start),
          appStorageProvider.overrideWith((ref) => storage),
          captureChannelProvider.overrideWith((ref) => FakeCaptureChannel()),
          desktopShellProvider.overrideWith((ref) => FakeDesktopShell()),
        ],
        child: const OffloadApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// A segment of the Overview (its name can also be a destination's).
  Finder segment(String key) => find.descendant(
    of: find.byType(SegmentedButton<String>),
    matching: find.text(l10n.insightsSegment(key)),
  );

  testDriftWidgets('phone: the fifth tab, three segments, a person over it', (
    tester,
  ) async {
    await startApp(tester);
    await tester.tap(find.text(l10n.navInsights));
    await tester.pumpAndSettle();
    expect(find.byType(InsightsScreen), findsOneWidget);
    expect(find.byType(HorizonView), findsOneWidget);

    await tester.tap(segment('standstill'));
    await tester.pumpAndSettle();
    expect(find.byType(StandstillView), findsOneWidget);
    expect(find.byType(HorizonView), findsNothing);

    await tester.tap(segment('people'));
    await tester.pumpAndSettle();
    expect(find.byType(PeopleBalance), findsOneWidget);
    // The balance without its filter field.
    expect(find.text(l10n.peopleFilterHint), findsNothing);
    await tester.tap(find.text('Jan Bakker'));
    await tester.pumpAndSettle();
    expect(find.byType(PersonScreen), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(PersonScreen), findsNothing);
    expect(find.byType(InsightsScreen), findsOneWidget);
  });

  testDriftWidgets(
    'Windows: Ctrl+5; Horizon and Standstill side by side; a person on '
    'the right',
    (tester) async {
      await startApp(tester, width: 1280);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit5);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pumpAndSettle();
      expect(find.byType(InsightsScreen), findsOneWidget);
      // Both panes: no detail pane beside it.
      expect(find.byType(HorizonView), findsOneWidget);
      expect(find.byType(StandstillView), findsOneWidget);
      expect(find.text(l10n.panesChooseItem), findsNothing);

      await tester.tap(segment('people'));
      await tester.pumpAndSettle();
      expect(find.text(l10n.panesChooseItem), findsOneWidget);
      await tester.tap(find.text('Jan Bakker'));
      await tester.pumpAndSettle();
      // In the right pane, the balance stays beside it.
      expect(find.byType(PersonScreen), findsOneWidget);
      expect(find.byType(PeopleBalance), findsOneWidget);
    },
    variant: windows,
  );

  testDriftWidgets(
    'Windows: the review starts with the Overview on both panes',
    (tester) async {
      await startApp(tester, width: 1280);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyW);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.reviewStart));
      await tester.pumpAndSettle();

      final inReview = find.descendant(
        of: find.byType(WeeklyReviewScreen),
        matching: find.byType(InsightsView),
      );
      expect(inReview, findsOneWidget);
      expect(find.byType(HorizonView), findsOneWidget);
      expect(find.byType(StandstillView), findsOneWidget);
      expect(find.text(l10n.panesChooseItem), findsNothing);
      // No link to the review inside the review.
      expect(find.text(l10n.standstillToReview), findsNothing);

      // People keeps two panes, as in the tab.
      await tester.tap(segment('people'));
      await tester.pumpAndSettle();
      expect(find.text(l10n.panesChooseItem), findsOneWidget);
      await tester.tap(segment('both'));
      await tester.pumpAndSettle();
      expect(find.text(l10n.panesChooseItem), findsNothing);

      await tester.tap(find.text(l10n.reviewContinue));
      await tester.pumpAndSettle();
      // The next step is in the list pane again, the detail beside it.
      expect(find.byType(InsightsView), findsNothing);
      expect(find.text(l10n.panesChooseItem), findsOneWidget);
    },
    variant: windows,
  );

  testDriftWidgets('Settings: busy from is a choice of 3 to 15 items', (
    tester,
  ) async {
    await startApp(tester);
    await tester.tap(find.byTooltip(l10n.openSettingsTooltip));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
    final tile = find.widgetWithText(ListTile, l10n.settingsBusyFrom);
    await tester.scrollUntilVisible(tile, 300);
    await tester.tap(
      find.descendant(of: tile, matching: find.byType(DropdownButton<int>)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.settingsItemCount(8)).last);
    await tester.pumpAndSettle();
    expect(storage.busyFromItems, 8);
  });
}
