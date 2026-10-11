import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/domain/time/local_date.dart';
import 'package:offload/l10n/app_localizations.dart';
import 'package:offload/presentation/tokens/token_display.dart';

/// The date words of the inline syntax come from the ARB files (DD-004
/// point 5); every language must supply a usable set.
void main() {
  final sunday = LocalDate(2026, 9, 27);

  test('every language has seven weekdays and the relative words', () {
    for (final locale in AppLocalizations.supportedLocales) {
      final l10n = lookupAppLocalizations(Locale(locale.languageCode));
      final dates = dateVocabularyOf(l10n);
      final reason = locale.languageCode;

      expect(
        dates.resolve(l10n.tokenDateToday.split(',').first, sunday),
        sunday,
        reason: reason,
      );
      expect(
        dates.resolve(l10n.tokenDateTomorrow.split(',').first, sunday),
        LocalDate(2026, 9, 28),
        reason: reason,
      );
      final fridayShort = l10n.tokenWeekdaysShort.split(',')[4];
      final fridayLong = l10n.tokenWeekdaysLong.split(',')[4];
      expect(dates.resolve(fridayShort, sunday), LocalDate(2026, 10, 2));
      expect(dates.resolve(fridayLong, sunday), LocalDate(2026, 10, 2));
    }
  });

  test('each date word means one thing per language', () {
    for (final locale in AppLocalizations.supportedLocales) {
      final l10n = lookupAppLocalizations(Locale(locale.languageCode));
      final words = [
        for (final list in [
          l10n.tokenDateToday,
          l10n.tokenDateTomorrow,
          l10n.tokenDateDayAfterTomorrow,
          l10n.tokenDateNextWeek,
          l10n.tokenWeekdaysShort,
          l10n.tokenWeekdaysLong,
        ])
          for (final word in list.split(','))
            if (word.trim().isNotEmpty) word.trim().toLowerCase(),
      ];

      expect(
        words.toSet(),
        hasLength(words.length),
        reason: locale.languageCode,
      );
    }
  });

  test('the Dutch and English words of the PO decision', () {
    final nl = dateVocabularyOf(lookupAppLocalizations(const Locale('nl')));
    final en = dateVocabularyOf(lookupAppLocalizations(const Locale('en')));

    expect(nl.resolve('overmorgen', sunday), LocalDate(2026, 9, 29));
    expect(nl.resolve('volgendeweek', sunday), LocalDate(2026, 9, 28));
    expect(nl.resolve('vr', sunday), LocalDate(2026, 10, 2));
    expect(en.resolve('fri', sunday), LocalDate(2026, 10, 2));
    expect(en.resolve('nextweek', sunday), LocalDate(2026, 9, 28));
    // Only the active language counts (SPEC Q19): no Dutch words in English.
    expect(en.resolve('morgen', sunday), isNull);
  });
}
