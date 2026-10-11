import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'key_store.dart';

/// [KeyStore] backed by the Android Keystore through a platform channel
/// (`KeyStoreChannel.kt`). The wrapped key lives in `noBackupFilesDir`.
class AndroidKeyStore implements KeyStore {
  AndroidKeyStore({this.name = masterKeyName});

  /// Name of the production master key.
  static const masterKeyName = 'master_key';

  static const _channel = MethodChannel('eu.marandos.offload/key_store');

  /// Distinguishes the production key from keys used by integration tests.
  final String name;

  @override
  Future<Uint8List?> readMasterKey() =>
      _call(() => _channel.invokeMethod<Uint8List>('read', {'name': name}));

  @override
  Future<void> createMasterKey(Uint8List key) {
    if (key.length != KeyStore.keyLength) {
      throw ArgumentError.value(key.length, 'key.length');
    }
    return _call(
      () => _channel.invokeMethod<void>('create', {'name': name, 'key': key}),
    );
  }

  /// Removes a test key. The platform side refuses to delete [masterKeyName].
  @visibleForTesting
  Future<void> deleteForTesting() => _call(
    () => _channel.invokeMethod<void>('deleteForTesting', {'name': name}),
  );

  static Future<T> _call<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on PlatformException catch (e) {
      final code = e.code == 'exists'
          ? KeyStoreErrorCode.alreadyExists
          : KeyStoreErrorCode.unavailable;
      throw KeyStoreException(code, '${e.code}: ${e.message}');
    } on MissingPluginException {
      // The channel is not registered in this engine: unknown, never "no key".
      throw KeyStoreException(
        KeyStoreErrorCode.unavailable,
        'Key store channel not registered',
      );
    }
  }
}
