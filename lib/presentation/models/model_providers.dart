import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/model_store.dart';
import '../../domain/handwriting/reading_policy.dart';
import '../../domain/models/model_catalog.dart';
import '../../platform/model_files/model_file_source.dart';
import '../../platform/model_files/platform_model_file_source.dart';
import '../app_directory_provider.dart';
import '../startup/app_storage_provider.dart';

/// The models the app knows ([modelCatalog]); a test puts a small one in.
final modelCatalogProvider = Provider<List<ModelSpec>>((ref) => modelCatalog);

/// Where the files of a model come from: the platform's file window
/// (T6a.3).
final modelFileSourceProvider = Provider<ModelFileSource>(
  (ref) => createPlatformModelFileSource(),
);

/// The models on this device (T6a.3, DD-002, DD-021).
final modelStoreProvider = Provider<ModelStore>((ref) {
  final directory = ref.watch(appDirectoryProvider);
  return ModelStore(
    dataDirectory: directory.dataDirectory,
    source: ref.watch(modelFileSourceProvider),
    freeBytes: directory.freeBytes,
  );
});

/// Which files of a model this device has; invalidated after an import or
/// a removal.
final modelStatusProvider = FutureProvider.autoDispose
    .family<ModelStatus, ModelSpec>(
      (ref, spec) => ref.watch(modelStoreProvider).status(spec),
    );

/// *Accurate / Faster* on this device (DD-021): read when Settings → Models
/// opens or a photo is read, not at start (REQ-001).
final readingSpeedProvider =
    AsyncNotifierProvider<ReadingSpeedNotifier, ReadingSpeed>(
      ReadingSpeedNotifier.new,
    );

class ReadingSpeedNotifier extends AsyncNotifier<ReadingSpeed> {
  @override
  Future<ReadingSpeed> build() => ref.watch(storageProvider).readingSpeed();

  /// Applies [speed] at once, then stores it; a failure to store puts the
  /// stored value back.
  Future<void> choose(ReadingSpeed speed) async {
    final before = state;
    state = AsyncData(speed);
    try {
      await ref.read(storageProvider).saveReadingSpeed(speed);
    } catch (_) {
      state = before;
    }
  }
}
