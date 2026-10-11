import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/database/app_database.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/domain/settings/language_choice.dart';
import 'package:offload/l10n/app_localizations.dart';
import 'package:offload/presentation/app.dart';
import 'package:offload/presentation/capture/pending_captures.dart';
import 'package:offload/presentation/settings/language_choice_provider.dart';
import 'package:offload/presentation/startup/app_storage_provider.dart';

import '../fakes/drift_widgets.dart';
import '../fakes/fake_capture_channel.dart';
import '../fakes/fake_desktop_shell.dart';
import '../fakes/start_on_inbox.dart';
import '../fakes/test_storage.dart';

void main() {
  /// Starts the app with [systemLocales] as the device's preferred languages.
  Future<void> startApp(
    WidgetTester tester,
    List<Locale> systemLocales, {
    LanguageChoice? initialChoice,
    AppStorage? storage,
  }) async {
    tester.platformDispatcher.localesTestValue = systemLocales;
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final opened = storage ?? await openTestStorage();
    if (storage == null) addTearDown(opened.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          startOnInbox,
          appStorageProvider.overrideWith((ref) => opened),
          captureChannelProvider.overrideWith((ref) => FakeCaptureChannel()),
          desktopShellProvider.overrideWith((ref) => FakeDesktopShell()),
          if (initialChoice != null)
            languageChoiceProvider.overrideWith(
              () => _FixedLanguageChoice(initialChoice),
            ),
        ],
        child: const OffloadApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openSettings(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
  }

  group('default language follows the system (AC REQ-029)', () {
    testDriftWidgets('Dutch system language shows Dutch', (tester) async {
      await startApp(tester, const [Locale('nl', 'NL')]);

      expect(find.text('Nog geen items'), findsOneWidget);
    });

    testDriftWidgets('English system language shows English', (tester) async {
      await startApp(tester, const [Locale('en', 'US')]);

      expect(find.text('No items yet'), findsOneWidget);
    });

    testDriftWidgets('a system language that is not offered shows English', (
      tester,
    ) async {
      await startApp(tester, const [Locale('de', 'DE')]);

      expect(find.text('No items yet'), findsOneWidget);
    });

    testDriftWidgets('the first offered preferred language is used', (
      tester,
    ) async {
      await startApp(tester, const [Locale('de'), Locale('nl')]);

      expect(find.text('Nog geen items'), findsOneWidget);
    });

    testDriftWidgets('a change of the system language is followed', (
      tester,
    ) async {
      await startApp(tester, const [Locale('en')]);

      tester.platformDispatcher.localesTestValue = const [Locale('nl')];
      await tester.pumpAndSettle();

      expect(find.text('Nog geen items'), findsOneWidget);
    });
  });

  group('language choice in Settings (REQ-029)', () {
    testDriftWidgets('lists system plus one option per supported language', (
      tester,
    ) async {
      await startApp(tester, const [Locale('nl')]);
      await openSettings(tester);

      expect(
        find.byWidgetPredicate((w) => w is RadioListTile<LanguageChoice>),
        findsNWidgets(AppLocalizations.supportedLocales.length + 1),
      );
      expect(find.text('Instellingen'), findsOneWidget);
      expect(find.text('Systeemtaal'), findsOneWidget);
      for (final locale in AppLocalizations.supportedLocales) {
        expect(
          find.text(lookupAppLocalizations(locale).languageName),
          findsOneWidget,
        );
      }
    });

    testDriftWidgets(
      'system first, then languages alphabetically by own name',
      (tester) async {
        await startApp(tester, const [Locale('nl')]);
        await openSettings(tester);

        final titles = [
          for (final tile in tester.widgetList<RadioListTile<Object?>>(
            find.byWidgetPredicate((w) => w is RadioListTile<LanguageChoice>),
          ))
            (tile.title! as Text).data!,
        ];
        final names = [
          for (final l in AppLocalizations.supportedLocales)
            lookupAppLocalizations(l).languageName,
        ]..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
        expect(titles, ['Systeemtaal', ...names]);
        expect(titles, containsAllInOrder(['English', 'Nederlands']));
      },
    );

    testDriftWidgets('choosing English overrides a Dutch system language', (
      tester,
    ) async {
      await startApp(tester, const [Locale('nl')]);
      await openSettings(tester);

      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('System language'), findsOneWidget);
      // Language names stay in their own language.
      expect(find.text('Nederlands'), findsOneWidget);
    });

    testDriftWidgets(
      'choosing Dutch overrides an unsupported system language',
      (tester) async {
        await startApp(tester, const [Locale('de')]);
        await openSettings(tester);

        await tester.tap(find.text('Nederlands'));
        await tester.pumpAndSettle();

        expect(find.text('Instellingen'), findsOneWidget);
      },
    );

    testDriftWidgets('choosing system again follows the system language', (
      tester,
    ) async {
      await startApp(tester, const [Locale('nl')]);
      await openSettings(tester);
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('System language'));
      await tester.pumpAndSettle();

      expect(find.text('Instellingen'), findsOneWidget);
    });

    testDriftWidgets('a choice the app does not offer follows the system', (
      tester,
    ) async {
      // E.g. a stored choice for a language that is no longer offered.
      await startApp(tester, const [
        Locale('nl'),
      ], initialChoice: const LanguageChoice.language('xx'));

      expect(find.text('Nog geen items'), findsOneWidget);
    });

    testDriftWidgets('the choice is stored and used at the next start', (
      tester,
    ) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final first = await openTestStorage(db);
      await startApp(tester, const [Locale('nl')], storage: first);
      await openSettings(tester);
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();
      expect(first.languageChoice, const LanguageChoice.language('en'));

      await tester.pumpWidget(const SizedBox());
      final second = await openTestStorage(db);
      await startApp(tester, const [Locale('nl')], storage: second);

      expect(second.languageChoice, const LanguageChoice.language('en'));
      expect(find.text('No items yet'), findsOneWidget);
    });

    testDriftWidgets(
      'a choice that cannot be stored still applies, with a note',
      (tester) async {
        final storage = await openTestStorage();
        await startApp(tester, const [Locale('nl')], storage: storage);
        await openSettings(tester);
        await tester.runAsync(storage.close); // every later write fails

        await tester.tap(find.text('English'));
        // Let the failing database call complete in real time.
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pumpAndSettle();

        expect(find.text('Settings'), findsOneWidget);
        expect(
          find.text('The language choice could not be saved'),
          findsOneWidget,
        );
      },
    );

    testDriftWidgets('the choice is visible on the start screen', (
      tester,
    ) async {
      await startApp(tester, const [Locale('nl')]);
      await openSettings(tester);
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('No items yet'), findsOneWidget);
    });
  });
}

/// Starts with [initial] instead of the default, as a stored choice would.
class _FixedLanguageChoice extends LanguageChoiceNotifier {
  _FixedLanguageChoice(this.initial);

  final LanguageChoice initial;

  @override
  LanguageChoice build() => initial;
}
