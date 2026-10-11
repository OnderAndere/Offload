import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/domain/app/build_info.dart';
import 'package:offload/l10n/app_localizations.dart';
import 'package:offload/presentation/about/about_screen.dart';
import 'package:offload/presentation/app.dart';
import 'package:offload/presentation/capture/pending_captures.dart';
import 'package:offload/presentation/settings/build_info_provider.dart';
import 'package:offload/presentation/startup/app_storage_provider.dart';

import '../../fakes/drift_widgets.dart';
import '../../fakes/fake_capture_channel.dart';
import '../../fakes/fake_desktop_shell.dart';
import '../../fakes/test_storage.dart';

/// Version and build moment at the top of Settings (REQ-060).
void main() {
  // 16:30 local time, whatever the time zone of the test machine.
  final builtAt = DateTime(2026, 9, 27, 16, 30).toUtc();
  final build = BuildInfo(version: '0.1.0', buildNumber: '7', builtAt: builtAt);

  Future<void> openSettings(
    WidgetTester tester, {
    required Locale locale,
    required BuildInfo? info,
  }) async {
    tester.platformDispatcher.localesTestValue = [locale];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final storage = await openTestStorage();
    addTearDown(storage.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appStorageProvider.overrideWith((ref) => storage),
          captureChannelProvider.overrideWith((ref) => FakeCaptureChannel()),
          desktopShellProvider.overrideWith((ref) => FakeDesktopShell()),
          buildInfoProvider.overrideWith((ref) => info),
        ],
        child: const OffloadApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
  }

  testDriftWidgets('shows version and build moment in Dutch', (tester) async {
    await openSettings(tester, locale: const Locale('nl'), info: build);

    expect(find.text('Over Offload'), findsOneWidget);
    expect(find.text('Versie 0.1.0 (build 7)'), findsOneWidget);
    expect(find.text('Gebouwd op 27 sep 2026, 16:30'), findsOneWidget);
  });

  testDriftWidgets('shows version and build moment in English', (tester) async {
    await openSettings(tester, locale: const Locale('en'), info: build);

    expect(find.text('About Offload'), findsOneWidget);
    expect(find.text('Version 0.1.0 (build 7)'), findsOneWidget);
    expect(find.textContaining('Built on Sep 27, 2026'), findsOneWidget);
  });

  testDriftWidgets('the version comes before the language choice', (
    tester,
  ) async {
    await openSettings(tester, locale: const Locale('nl'), info: build);

    expect(
      tester.getTopLeft(find.text('Over Offload')).dy,
      lessThan(tester.getTopLeft(find.text('Taal')).dy),
    );
  });

  testDriftWidgets('a development build says so', (tester) async {
    await openSettings(tester, locale: const Locale('nl'), info: null);

    expect(find.text('Ontwikkelversie'), findsOneWidget);
    expect(find.textContaining('Versie'), findsNothing);
  });

  group('the screen About Offload (T8.10, REQ-062)', () {
    final l10n = lookupAppLocalizations(const Locale('nl'));

    Future<void> openAbout(WidgetTester tester) async {
      await openSettings(tester, locale: const Locale('nl'), info: build);
      await tester.tap(find.text(l10n.aboutOpen));
      await tester.pumpAndSettle();
    }

    testDriftWidgets('purpose, version and licence', (tester) async {
      await openAbout(tester);

      expect(find.byType(AboutScreen), findsOneWidget);
      expect(find.text(l10n.aboutPurpose), findsOneWidget);
      expect(find.text('Versie 0.1.0 (build 7)'), findsOneWidget);
      expect(find.text('GNU GPL 3.0 of later'), findsOneWidget);
    });

    testDriftWidgets('the licence text is the bundled GPL 3.0', (tester) async {
      await openAbout(tester);
      await tester.tap(find.text(l10n.aboutLicenceTitle));
      await tester.pumpAndSettle();

      expect(find.textContaining('GNU GENERAL PUBLIC LICENSE'), findsOneWidget);
    });

    testDriftWidgets('the licences of components open', (tester) async {
      await openAbout(tester);
      await tester.tap(find.text(l10n.aboutComponentsTitle));
      await tester.pumpAndSettle();

      expect(find.byType(LicensePage), findsOneWidget);
    });

    testDriftWidgets(
      'Windows: Escape goes back to Settings',
      (tester) async {
        await openAbout(tester);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();

        expect(find.byType(AboutScreen), findsNothing);
        expect(find.text(l10n.aboutOpen), findsOneWidget);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.windows),
    );
  });
}
