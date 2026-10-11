/// The UI language the user picked and how it resolves to the language the
/// app shows (REQ-005, REQ-029, DD-009).
library;

/// Language shown when the choice follows the system and the app offers none
/// of the device's preferred languages (AC REQ-029, SPEC Q17).
const fallbackLanguageCode = 'en';

/// The language option chosen in Settings: follow the system, or one fixed
/// language identified by its language code (`nl`, `en`, later `uk`).
final class LanguageChoice {
  /// Follow the language of the device; the default (AC REQ-029).
  const LanguageChoice.system() : languageCode = null;

  /// Always use [languageCode], whatever the device language is.
  const LanguageChoice.language(String this.languageCode);

  /// Language code of a fixed choice; null when following the system.
  final String? languageCode;

  bool get followsSystem => languageCode == null;

  @override
  bool operator ==(Object other) =>
      other is LanguageChoice && other.languageCode == languageCode;

  @override
  int get hashCode => languageCode.hashCode;

  @override
  String toString() => 'LanguageChoice(${languageCode ?? 'system'})';
}

/// Returns the language code the UI is shown in.
///
/// A fixed [choice] wins when the app offers it. Otherwise the first of
/// [systemLanguageCodes] (the device's preferred languages, most preferred
/// first) that the app offers is used, and [fallbackLanguageCode] when it
/// offers none of them. This rule is explicit on purpose: it must not depend
/// on the order of the supported languages.
String resolveUiLanguage(
  LanguageChoice choice, {
  required List<String> systemLanguageCodes,
  required Iterable<String> supportedLanguageCodes,
}) {
  final chosen = choice.languageCode;
  if (chosen != null && supportedLanguageCodes.contains(chosen)) {
    return chosen;
  }
  return systemLanguageCodes.firstWhere(
    supportedLanguageCodes.contains,
    orElse: () => fallbackLanguageCode,
  );
}
