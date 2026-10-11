import 'dart:typed_data';

/// Keeps the device master key, protected by the platform (DD-007).
///
/// The master key is 32 random bytes. It is stored wrapped: on Android by an
/// AES-GCM key that never leaves the Android Keystore, on Windows as a DPAPI
/// blob bound to the user account. It never leaves the device.
abstract class KeyStore {
  /// Length of the master key in bytes.
  static const keyLength = 32;

  /// Returns the stored master key, or `null` if none has been stored yet.
  ///
  /// Throws [KeyStoreException] if a key is stored but cannot be unwrapped.
  /// That is never the same as "no key": the caller must not create a new one.
  Future<Uint8List?> readMasterKey();

  /// Stores [key] as the master key.
  ///
  /// Throws [KeyStoreException] with [KeyStoreErrorCode.alreadyExists] if a
  /// master key is already stored; an existing key is never overwritten.
  Future<void> createMasterKey(Uint8List key);
}

enum KeyStoreErrorCode {
  /// A master key already exists.
  alreadyExists,

  /// A master key is stored but could not be read or unwrapped.
  unavailable,
}

class KeyStoreException implements Exception {
  KeyStoreException(this.code, this.message);

  final KeyStoreErrorCode code;
  final String message;

  @override
  String toString() => 'KeyStoreException(${code.name}): $message';
}
