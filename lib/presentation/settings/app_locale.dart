import 'package:flutter/widgets.dart';

import '../../domain/settings/language_choice.dart';
import '../../l10n/app_localizations.dart';

/// The locale of a fixed [choice] the app offers; null when the choice
/// follows the system or names a language the app does not offer, so the
/// system rule applies (DD-009).
Locale? fixedAppLocale(LanguageChoice choice) {
  final code = choice.languageCode;
  final offered = AppLocalizations.supportedLocales.any(
    (l) => l.languageCode == code,
  );
  return code != null && offered ? Locale(code) : null;
}

/// The locale the UI is shown in for [choice], given the device's preferred
/// [systemLocales] (DD-009, AC REQ-029).
Locale resolveAppLocale(LanguageChoice choice, List<Locale> systemLocales) =>
    Locale(
      resolveUiLanguage(
        choice,
        systemLanguageCodes: [for (final l in systemLocales) l.languageCode],
        supportedLanguageCodes: [
          for (final l in AppLocalizations.supportedLocales) l.languageCode,
        ],
      ),
    );
