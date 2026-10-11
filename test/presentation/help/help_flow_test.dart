import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/items/drift_item_repository.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/l10n/app_localizations.dart';
import 'package:offload/presentation/app.dart';
import 'package:offload/presentation/capture/pending_captures.dart';
import 'package:offload/presentation/help/help_screen.dart';
import 'package:offload/presentation/home/destination.dart';
import 'package:offload/presentation/inbox/inbox_card.dart';
import 'package:offload/presentation/settings/settings_screen.dart';
import 'package:offload/presentation/startup/app_storage_provider.dart';

import '../../fakes/drift_widgets.dart';
import '../../fakes/fake_capture_channel.dart';
import '../../fakes/fake_desktop_shell.dart';
import '../../fakes/test_storage.dart';

/// Help in the app (REQ-065, DD-020): Settings → Help, a "?" per screen,
/// F1 on Windows, and the date on Today making room for the "?".
void main() {
  late AppStorage storage;
  final l10n = lookupAppLocalizations(const Locale('nl'));
  final windows = TargetPlatformVariant.only(TargetPlatform.windows);
  // A Monday, so the Dutch date is a known length.
  final now = DateTime(2026, 10, 12, 9);

  Future<void> startApp(
    WidgetTester tester, {
    double width = 420,
    double height = 900,
    double textScale = 1,
    Destination start = Destination.today,
    bool withItem = false,
  }) async {
    tester.view
      ..physicalSize = Size(width, height)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.localesTestValue = const [Locale('nl')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    storage = await openTestStorage();
    addTearDown(storage.close);
    if (withItem) {
      await DriftItemRepository(
        storage,
      ).capture('Offerte opvragen', source: ItemSource.app);
    }
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          destinationProvider.overrideWith((ref) => start),
          appStorageProvider.overrideWith((ref) => storage),
          captureChannelProvider.overrideWith((ref) => FakeCaptureChannel()),
          desktopShellProvider.overrideWith((ref) => FakeDesktopShell()),
          minuteClockProvider.overrideWith((ref) => Stream.value(now)),
        ],
        child: const OffloadApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The help screen is open at the chapter whose title is [title].
  void expectHelpAt(String title) {
    expect(find.byType(HelpScreen), findsOneWidget);
    expect(find.text(title), findsWidgets);
    // A Dutch app gets the English manual, and is told so.
    expect(find.text(l10n.helpInEnglish), findsOneWidget);
  }

  testDriftWidgets('the "?" on Today opens the chapter Today', (tester) async {
    await startApp(tester);
    await tester.tap(find.byTooltip(l10n.helpTooltip));
    await tester.pumpAndSettle();
    expectHelpAt('Today');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(HelpScreen), findsNothing);
  });

  testDriftWidgets('Settings → Help opens the table of contents', (
    tester,
  ) async {
    await startApp(tester);
    await tester.tap(find.byTooltip(l10n.openSettingsTooltip));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
    await tester.tap(find.text(l10n.helpOpenRow));
    await tester.pumpAndSettle();
    expectHelpAt('Offload — user manual');
  });

  testDriftWidgets('the syntax overview leads to the signs in the manual', (
    tester,
  ) async {
    await startApp(tester);
    await tester.tap(
      find.widgetWithText(FloatingActionButton, l10n.captureAction),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(l10n.prefixBarHelp));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.syntaxOverviewManual));
    await tester.pumpAndSettle();
    expectHelpAt('People, tags, dates, projects and priority in your text');
    expect(find.text(l10n.syntaxOverviewTitle), findsNothing);
  });

  testDriftWidgets('Windows: F1 opens help; the "?" teaches the key', (
    tester,
  ) async {
    await startApp(tester, width: 1200);
    expect(find.byTooltip(l10n.helpTooltipWithKey), findsWidgets);
    await tester.sendKeyEvent(LogicalKeyboardKey.f1);
    await tester.pumpAndSettle();
    expect(find.byType(HelpScreen), findsOneWidget);
  }, variant: windows);

  group('Windows: F1 on a screen with its own focus opens its chapter', () {
    Future<void> pressF1(WidgetTester tester) async {
      await tester.sendKeyEvent(LogicalKeyboardKey.f1);
      await tester.pumpAndSettle();
      expect(find.byType(HelpScreen), findsOneWidget);
    }

    testDriftWidgets('processing the inbox', (tester) async {
      await startApp(tester, width: 1200, withItem: true);
      await tester.tap(find.text(l10n.todayProcess));
      await tester.pumpAndSettle();
      await pressF1(tester);
      expect(find.text('Processing your inbox'), findsWidgets);
    }, variant: windows);

    testDriftWidgets('the weekly review', (tester) async {
      await startApp(tester, width: 1200);
      await tester.tap(find.byTooltip(l10n.reviewStartTooltipWithKey));
      await tester.pumpAndSettle();
      await pressF1(tester);
      expect(find.text('Weekly review'), findsWidgets);
    }, variant: windows);

    testDriftWidgets('an item opened as its own screen (narrow window)', (
      tester,
    ) async {
      await startApp(
        tester,
        width: 500,
        start: Destination.inbox,
        withItem: true,
      );
      await tester.tap(find.text('Offerte opvragen'));
      await tester.pumpAndSettle();
      await pressF1(tester);
      expect(find.text('Viewing and editing an item'), findsWidgets);
    }, variant: windows);
  });

  group('the date on Today', () {
    Finder dateInBar() => find.descendant(
      of: find.byType(AppBar),
      matching: find.text(l10n.todayDate(now)),
    );

    testDriftWidgets('stays in the title bar when it fits', (tester) async {
      // Wide: the test font is much wider than IBM Plex (checked for real
      // on the emulator).
      await startApp(tester, width: 800);
      expect(dateInBar(), findsOneWidget);
    });

    testDriftWidgets('moves to the page on a narrow screen', (tester) async {
      await startApp(tester, width: 340);
      expect(dateInBar(), findsNothing);
      expect(find.text(l10n.todayDate(now)), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testDriftWidgets('moves to the page with large text', (tester) async {
      await startApp(tester, textScale: 1.6);
      expect(dateInBar(), findsNothing);
      expect(find.text(l10n.todayDate(now)), findsOneWidget);
    });
  });
}
