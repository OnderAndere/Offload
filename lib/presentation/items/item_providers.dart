import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/items/drift_item_repository.dart';
import '../../data/links/drift_item_link_repository.dart';
import '../../data/people/drift_people_repository.dart';
import '../../data/tokens/drift_item_dates.dart';
import '../../domain/items/item.dart';
import '../../domain/items/item_repository.dart';
import '../../domain/links/item_link.dart';
import '../../domain/people/people_repository.dart';
import '../../domain/time/local_date.dart';
import '../../domain/tokens/stored_token.dart';
import '../startup/app_storage_provider.dart';

/// The item store of the opened storage.
final itemRepositoryProvider = Provider<ItemRepository>(
  (ref) => DriftItemRepository(ref.watch(storageProvider)),
);

/// Links between items (T10.9, REQ-054).
final itemLinkRepositoryProvider = Provider<ItemLinkRepository>(
  (ref) => DriftItemLinkRepository(ref.watch(storageProvider)),
);

/// The items item [id] links to, by label key (DD-018 point 14).
final linksFromProvider = StreamProvider.autoDispose
    .family<Map<String, LinkedItem>, String>(
      (ref, id) => ref
          .watch(itemLinkRepositoryProvider)
          .watchLinksFrom(id)
          .map(
            (links) => {
              for (final link in links)
                if (link.label case final label?) linkKey(label): link,
            },
          ),
    );

/// The labels in the text of item [id] that name no item (DD-004 point 13).
final unlinkedLabelsProvider = StreamProvider.autoDispose
    .family<Set<String>, String>(
      (ref, id) =>
          ref.watch(itemLinkRepositoryProvider).watchUnlinkedLabels(id),
    );

/// The live items that link to item [id]: its backlinks.
final backlinksProvider = StreamProvider.autoDispose
    .family<List<LinkedItem>, String>(
      (ref, id) => ref.watch(itemLinkRepositoryProvider).watchBacklinks(id),
    );

/// Live inbox, newest capture first.
final inboxProvider = StreamProvider<List<Item>>(
  (ref) => ref.watch(itemRepositoryProvider).watchInbox(),
);

/// One item as it changes; null when it is gone or in the trash.
final itemProvider = StreamProvider.autoDispose.family<Item?, String>(
  (ref, id) => ref.watch(itemRepositoryProvider).watchItem(id),
);

/// The dates worked out for the date words in item [id]'s saved text
/// (DD-018 point 1), for the chips in the item detail.
final storedDatesProvider = StreamProvider.autoDispose
    .family<Map<String, LocalDate>, String>(
      (ref, id) => watchStoredDates(ref.watch(storageProvider).database, id),
    );

/// The processed tokens of every live item, by item id, for the chips on
/// the inbox cards (DD-018 point 2). One query for the whole list.
final liveItemTokensProvider = StreamProvider<Map<String, List<StoredToken>>>(
  (ref) => watchLiveItemTokens(ref.watch(storageProvider).database),
);

/// People, found by name or created (DD-015): for the person sheet of
/// triage.
final peopleRepositoryProvider = Provider<PeopleRepository>(
  (ref) => DriftPeopleRepository(ref.watch(storageProvider)),
);
