import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/settings/language_choice.dart';
import '../startup/app_storage_provider.dart';

/// The UI language picked in Settings (REQ-029), stored in `local_state`
/// and read at start before the first screen, so no other language flashes.
final languageChoiceProvider =
    NotifierProvider<LanguageChoiceNotifier, LanguageChoice>(
      LanguageChoiceNotifier.new,
    );

class LanguageChoiceNotifier extends Notifier<LanguageChoice> {
  @override
  LanguageChoice build() => ref.watch(storageProvider).languageChoice;

  /// Applies [choice] at once, then stores it. Throws when storing fails;
  /// the choice then still applies until the app restarts.
  Future<void> choose(LanguageChoice choice) async {
    state = choice;
    await ref.read(storageProvider).saveLanguageChoice(choice);
  }
}
