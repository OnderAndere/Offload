import 'dart:typed_data';

/// One message for [AeadCipher]: a 12-byte [nonce], the associated data
/// [aad] that is authenticated but not encrypted, and the [data].
class AeadMessage {
  AeadMessage({required this.nonce, required this.aad, required this.data}) {
    if (nonce.length != AeadCipher.nonceLength) {
      throw ArgumentError.value(nonce.length, 'nonce.length');
    }
  }

  final Uint8List nonce;
  final Uint8List aad;
  final Uint8List data;
}

/// AES-256-GCM with a 16-byte tag (DD-006, REQ-023), from the platform
/// itself: Android `javax.crypto`, Windows CNG (`BCrypt`). No crypto package
/// ships with the app (PO decision 09-10-2026, T5.1). Both follow the same
/// standard, so what one seals the other opens (checked with the GCM test
/// vectors and a reference file in the integration tests).
///
/// Messages travel in batches: on Android every call crosses to the
/// platform, so a batch of segments costs one crossing.
abstract class AeadCipher {
  static const keyLength = 32;
  static const nonceLength = 12;
  static const tagLength = 16;

  /// Encrypts every message with [key]: the ciphertext with the tag
  /// appended, in the order of [messages].
  Future<List<Uint8List>> seal(Uint8List key, List<AeadMessage> messages);

  /// Decrypts and verifies every message with [key] (data = ciphertext with
  /// the tag appended). Throws [AeadAuthenticationException] when any of
  /// them does not verify; then nothing is returned.
  Future<List<Uint8List>> open(Uint8List key, List<AeadMessage> messages);
}

/// A tag did not verify: wrong key, wrong associated data, or changed data.
class AeadAuthenticationException implements Exception {
  const AeadAuthenticationException();

  @override
  String toString() => 'AeadAuthenticationException';
}

/// The platform could not run the cipher at all.
class AeadUnavailableException implements Exception {
  const AeadUnavailableException(this.message);

  final String message;

  @override
  String toString() => 'AeadUnavailableException: $message';
}
