import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/handwriting/reading_image_preparer.dart';
import '../../domain/models/model_catalog.dart';
import '../../platform/handwriting/handwriting_reader.dart';
import '../../platform/handwriting/platform_handwriting_reader.dart';
import '../../platform/screen_awake/platform_screen_awake.dart';
import '../../platform/screen_awake/screen_awake.dart';
import '../models/model_providers.dart';

/// The on-device vision model that reads handwriting (T6a.2, DD-021).
final handwritingReaderProvider = Provider<HandwritingReader>(
  (ref) => createPlatformHandwritingReader(),
);

/// Keeps the device awake while a photo is read (T6a.4).
final screenAwakeProvider = Provider<ScreenAwake>(
  (ref) => createPlatformScreenAwake(),
);

/// Makes a photo ready for the model (T6a.4).
final readingImagePreparerProvider = Provider<ReadingImagePreparer>(
  (ref) => const ReadingImagePreparer(),
);

/// A clock that only goes forward, for the 5-minute stop; a test puts in
/// its own.
final readingTimeSourceProvider = Provider<Duration Function()>((ref) {
  final watch = Stopwatch()..start();
  return () => watch.elapsed;
});

/// The handwriting model when this device can read with it: the reader's
/// library is there and all model files are (AC REQ-064, *Only with a
/// model*); null otherwise. Kept for the app's life, so capture asks it
/// once; invalidated by Settings → *Models* after an import or a removal,
/// and by the photo screen when the model turned out unreadable.
final handwritingModelProvider = FutureProvider<HandwritingModel?>((ref) async {
  final spec = ref
      .watch(modelCatalogProvider)
      .where((s) => s.kind == ModelKind.handwriting)
      .firstOrNull;
  if (spec == null) return null;
  final paths = await ref.watch(modelStoreProvider).paths(spec);
  if (paths == null) return null;
  // Opens the native library: only once a model is there.
  if (!ref.watch(handwritingReaderProvider).isAvailable) return null;
  return HandwritingModel(
    languageModelPath: paths[ModelFileRole.languageModel]!,
    projectorPath: paths[ModelFileRole.projector]!,
  );
});
