import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/tokens/drift_token_processor.dart';
import '../../domain/tokens/token_processing.dart';
import '../../l10n/app_localizations.dart';
import '../settings/app_locale.dart';
import '../settings/language_choice_provider.dart';
import '../startup/app_storage_provider.dart';
import 'token_display.dart';

/// Works out the tokens of saved items, after saving (T2.2 step B). Uses the
/// date and priority words of the language the UI is shown in at that
/// moment, and the repeat words of every language (DD-004 point 14).
final tokenProcessorProvider = Provider<ItemTokenProcessor>((ref) {
  // The same source as the screens (MaterialApp), so the chips and the
  // stored tokens use the same words.
  AppLocalizations l10n() => lookupAppLocalizations(
    resolveAppLocale(
      ref.read(languageChoiceProvider),
      WidgetsBinding.instance.platformDispatcher.locales,
    ),
  );
  return DriftTokenProcessor(
    ref.watch(storageProvider),
    registry: ref.watch(inlineTokenRegistryProvider),
    dates: () => dateVocabularyOf(l10n()),
    priorities: () => priorityVocabularyOf(l10n()),
    repeats: allRepeatWords,
  );
});
