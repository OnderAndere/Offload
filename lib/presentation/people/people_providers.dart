import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/items/item.dart';
import '../../domain/people/person.dart';
import '../../domain/people/person_balance.dart';
import '../../domain/people/person_merge.dart';
import '../../domain/people/person_overview.dart';
import '../../domain/tokens/token_processing.dart';
import '../items/item_providers.dart';
import '../projects/project_providers.dart';
import '../startup/app_storage_provider.dart';

/// The live people with their aliases, by name (DD-018 point 7).
final peopleProvider = StreamProvider<List<Person>>(
  (ref) => ref.watch(peopleRepositoryProvider).watchPeople(),
);

/// The merged people, each with the person it was merged into (DD-015).
final mergedIntoProvider = StreamProvider<Map<String, String>>(
  (ref) => ref.watch(peopleRepositoryProvider).watchMergedInto(),
);

/// The live person a stored person id stands for: itself, or for someone
/// merged the person they went into (DD-015); null when there is none.
final personResolverProvider = Provider<String? Function(String id)>((ref) {
  // While the people load (or fail to), references count as they are.
  if (!ref.watch(peopleProvider).hasValue) return (id) => id;
  final live = {
    for (final p in ref.watch(peopleProvider).valueOrNull ?? <Person>[]) p.id,
  };
  final merged = ref.watch(mergedIntoProvider).valueOrNull ?? const {};
  return (id) => resolvePersonId(id, merged, live);
});

/// The live people by id; a merged person's id gives the person they went
/// into, so an old reference still shows a name (DD-015).
final peopleByIdProvider = Provider<Map<String, Person>>((ref) {
  final people = {
    for (final p in ref.watch(peopleProvider).valueOrNull ?? <Person>[])
      p.id: p,
  };
  final resolve = ref.watch(personResolverProvider);
  return {
    ...people,
    for (final id in (ref.watch(mergedIntoProvider).valueOrNull ?? {}).keys)
      // The merged map can arrive before the people: then nothing yet.
      id: ?people[resolve(id)],
  };
});

/// The person a name or alias stands for, by [nameKey]: how an `@name` in
/// a text is linked to a person on screen, as the token processor does
/// (DD-015, [personIdsByName]).
final personIdByNameProvider = Provider<Map<String, String>>(
  (ref) => personIdsByName(ref.watch(peopleProvider).valueOrNull ?? const []),
);

/// The commitment balance per person id (T10.2, DD-018 point 11): what I
/// deliver, what I wait for and the oldest day; people with nothing open
/// are left out.
final personBalancesProvider = Provider.autoDispose<Map<String, PersonBalance>>(
  (ref) => personBalances(
    ref.watch(liveItemsProvider).valueOrNull ?? const [],
    resolve: ref.watch(personResolverProvider),
  ),
);

/// "Old after" in days (DD-018 point 11): a setting of this device.
final oldAfterProvider = NotifierProvider<OldAfterNotifier, int>(
  OldAfterNotifier.new,
);

class OldAfterNotifier extends Notifier<int> {
  @override
  int build() => ref.watch(storageProvider).oldAfterDays;

  /// Applies [days] at once, then stores it. Throws when storing fails;
  /// the choice then still applies until the app restarts.
  Future<void> choose(int days) async {
    state = days;
    await ref.read(storageProvider).saveOldAfterDays(days);
  }
}

/// Every live item by id: the people of a search result (DD-018 point 7).
final liveItemsByIdProvider = Provider.autoDispose<Map<String, Item>>(
  (ref) => {
    for (final item in ref.watch(liveItemsProvider).valueOrNull ?? <Item>[])
      item.id: item,
  },
);

/// The items linked to person [id], with those named in their text.
final personItemsProvider = StreamProvider.autoDispose
    .family<PersonItems, String>(
      (ref, id) => ref.watch(itemRepositoryProvider).watchPersonItems(id),
    );

/// The person opened in the People destination, or null for the list. On
/// Windows it replaces the list in the list pane (DD-018 point 7, as point
/// 6).
final openPersonProvider = StateProvider<String?>((ref) => null);
