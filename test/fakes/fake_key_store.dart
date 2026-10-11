import 'dart:typed_data';

import 'package:offload/platform/key_store/key_store.dart';

/// In-memory [KeyStore] with the same contract as the platform versions.
class FakeKeyStore implements KeyStore {
  FakeKeyStore({this.key, this.unavailable = false});

  Uint8List? key;

  /// Simulates a stored key that cannot be unwrapped.
  bool unavailable;

  int createCalls = 0;

  @override
  Future<Uint8List?> readMasterKey() async {
    if (unavailable) {
      throw KeyStoreException(KeyStoreErrorCode.unavailable, 'fake');
    }
    return key == null ? null : Uint8List.fromList(key!);
  }

  @override
  Future<void> createMasterKey(Uint8List newKey) async {
    createCalls++;
    if (key != null) {
      throw KeyStoreException(KeyStoreErrorCode.alreadyExists, 'fake');
    }
    key = Uint8List.fromList(newKey);
  }
}
