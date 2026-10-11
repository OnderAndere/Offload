import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/storage/app_storage.dart';
import '../../platform/app_directory/platform_app_directory.dart';
import '../../platform/key_store/platform_key_store.dart';

/// Opens the encrypted storage once at start (REQ-004, DD-007). Invalidate it
/// to try again after a start-up error.
final appStorageProvider = FutureProvider<AppStorage>((ref) async {
  final directory = await createPlatformAppDirectory().dataDirectory();
  final storage = await AppStorage.open(
    directory: directory,
    keyStore: createPlatformKeyStore(),
  );
  ref.onDispose(() => unawaited(storage.close()));
  return storage;
});

/// The opened storage. Only read below the started app, which is built once
/// [appStorageProvider] has a value.
final storageProvider = Provider<AppStorage>(
  (ref) => ref.watch(appStorageProvider).requireValue,
);
