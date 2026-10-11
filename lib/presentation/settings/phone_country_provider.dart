import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/people/calling_country.dart';
import '../search/search_providers.dart';
import '../startup/app_storage_provider.dart';

/// The country of phone numbers typed without a country code (T3.6,
/// DD-012): a setting of this device, the Netherlands by default.
final phoneCountryProvider =
    NotifierProvider<PhoneCountryNotifier, CallingCountry>(
      PhoneCountryNotifier.new,
    );

class PhoneCountryNotifier extends Notifier<CallingCountry> {
  @override
  CallingCountry build() => ref.watch(storageProvider).phoneCountry;

  /// Stores [country] and indexes the people again, so a search finds
  /// their numbers in the international form of the new country. Throws
  /// when storing fails; nothing changed then.
  Future<void> choose(CallingCountry country) async {
    await ref.read(storageProvider).savePhoneCountry(country);
    state = country;
    try {
      await ref.read(searchIndexProvider).rebuild();
    } catch (_) {
      // The choice is stored; only the international forms in the index
      // are behind until the next rebuild. Not worth a failure message.
    }
  }
}
