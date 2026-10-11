import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/domain/repeats/repeat.dart';
import 'package:offload/domain/time/local_date.dart';
import 'package:offload/l10n/app_localizations.dart';
import 'package:offload/presentation/tokens/token_display.dart';

/// The repeat words of the inline syntax (DD-004 point 14): every language
/// has three, and the parser knows those of all languages, so none may be
/// a date or priority word of any language, or a series could stop after a
/// change of language.
void main() {
  final languages = [
    for (final locale in AppLocalizations.supportedLocales)
      lookupAppLocalizations(Locale(locale.languageCode)),
  ];

  test('every language has a daily, weekly and monthly word', () {
    for (final l10n in languages) {
      final words = repeatVocabularyOf(l10n);
      expect(words.daily, isNotEmpty, reason: l10n.localeName);
      expect(words.weekly, isNotEmpty, reason: l10n.localeName);
      expect(words.monthly, isNotEmpty, reason: l10n.localeName);
      expect(allRepeatWords.resolve(words.weekly.first), Rhythm.weekly);
    }
  });

  test('no repeat word of any language is a date or priority word', () {
    final today = LocalDate(2026, 10, 6);
    final repeatWords = [
      for (final l10n in languages) ...[
        ...repeatVocabularyOf(l10n).daily,
        ...repeatVocabularyOf(l10n).weekly,
        ...repeatVocabularyOf(l10n).monthly,
      ],
    ];
    for (final l10n in languages) {
      final dates = dateVocabularyOf(l10n);
      final priorities = priorityVocabularyOf(l10n);
      for (final word in repeatWords) {
        expect(dates.resolve(word, today), isNull, reason: word);
        expect(priorities.resolve(word), isNull, reason: word);
      }
    }
  });

  test('each repeat word means one rhythm', () {
    final seen = <String, Rhythm>{};
    for (final l10n in languages) {
      final words = repeatVocabularyOf(l10n);
      for (final (list, rhythm) in [
        (words.daily, Rhythm.daily),
        (words.weekly, Rhythm.weekly),
        (words.monthly, Rhythm.monthly),
      ]) {
        for (final word in list) {
          expect(seen.putIfAbsent(word, () => rhythm), rhythm, reason: word);
        }
      }
    }
  });
}
