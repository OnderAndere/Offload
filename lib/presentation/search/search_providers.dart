import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/search/drift_search_index.dart';
import '../../domain/search/search_index.dart';
import '../startup/app_storage_provider.dart';

final _driftSearchIndexProvider = Provider<DriftSearchIndex>((ref) {
  final storage = ref.watch(storageProvider);
  return DriftSearchIndex(
    storage.database,
    phoneCountry: () => storage.phoneCountry,
  );
});

/// Full-text search over items and people (REQ-011, DD-016).
final searchIndexProvider = Provider<SearchIndex>(
  (ref) => ref.watch(_driftSearchIndexProvider),
);

/// Keeps the search index up to date while the app runs: once at start
/// (also after the migration that added it) and after every saved change,
/// never during saving (hard rule 7). Read once when the app has started.
final searchIndexingProvider = Provider<void>((ref) {
  final subscription = ref.watch(_driftSearchIndexProvider).keepUpToDate();
  ref.onDispose(subscription.cancel);
});
