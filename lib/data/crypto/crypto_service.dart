import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import '../../platform/key_store/key_store.dart';
import 'hkdf.dart';

/// What a derived key is used for. The label is part of the derivation, so
/// every purpose gets an independent key; never change an existing label.
enum KeyPurpose {
  database('eu.marandos.offload/database/v1'),

  /// The attachments (DD-006); each file derives its own key from this one.
  attachments('eu.marandos.offload/attachments/v1');

  const KeyPurpose(this.label);

  final String label;
}

/// The master key exists nowhere, but data encrypted with it does. Creating a
/// new key would make that data unreadable for good, so the app stops instead.
class MissingMasterKeyException implements Exception {
  @override
  String toString() =>
      'MissingMasterKeyException: existing data found, but no master key';
}

/// Holds the unlocked master key and derives purpose-bound keys from it with
/// HKDF-SHA256 (DD-007). The master key itself is never used directly.
class CryptoService {
  CryptoService._(this._masterKey);

  final Uint8List _masterKey;

  /// Reads the master key from [keyStore], or creates one on first start.
  ///
  /// A new key is only created when [existingDataFound] is false. If data
  /// exists but the key does not, this throws [MissingMasterKeyException] and
  /// never creates or overwrites anything. A key that exists but cannot be
  /// unwrapped surfaces as a [KeyStoreException].
  static Future<CryptoService> unlock(
    KeyStore keyStore, {
    required bool existingDataFound,
    Random? random,
  }) async {
    final stored = await keyStore.readMasterKey();
    if (stored != null) return CryptoService._(_checked(stored));
    if (existingDataFound) throw MissingMasterKeyException();

    final generator = random ?? Random.secure();
    final key = Uint8List.fromList(
      List.generate(KeyStore.keyLength, (_) => generator.nextInt(256)),
    );
    await keyStore.createMasterKey(key);
    // Read back, so data is only ever encrypted with a key that was stored.
    final persisted = await keyStore.readMasterKey();
    if (persisted == null || !_equal(persisted, key)) {
      throw KeyStoreException(
        KeyStoreErrorCode.unavailable,
        'The new master key could not be read back',
      );
    }
    return CryptoService._(key);
  }

  /// A 256-bit key for [purpose], derived from the master key.
  Uint8List deriveKey(KeyPurpose purpose) =>
      hkdfSha256(ikm: _masterKey, info: utf8.encode(purpose.label), length: 32);

  static Uint8List _checked(Uint8List key) {
    if (key.length != KeyStore.keyLength) {
      throw KeyStoreException(
        KeyStoreErrorCode.unavailable,
        'The stored master key has the wrong length',
      );
    }
    return key;
  }

  static bool _equal(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
