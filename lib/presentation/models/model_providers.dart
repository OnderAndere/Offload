import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/model_store.dart';
import '../../platform/model_files/model_file_source.dart';
import '../../platform/model_files/platform_model_file_source.dart';
import '../settings/storage_section.dart';

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
