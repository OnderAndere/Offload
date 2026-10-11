import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:offload/platform/cipher/aead_cipher.dart';

/// A stand-in for [AeadCipher] in tests of what is built around it: NOT
/// secure, but it hides the data (a SHA-256 key stream) and rejects any
/// change to key, nonce, associated data or data (an HMAC tag), like GCM.
/// The real ciphers are tested against the GCM test vectors.
class FakeAeadCipher implements AeadCipher {
  /// Calls to [seal] and [open]: a batch is one call.
  int calls = 0;

  @override
  Future<List<Uint8List>> seal(
    Uint8List key,
    List<AeadMessage> messages,
  ) async {
    calls++;
    return [
      for (final m in messages)
        () {
          final cipher = _xor(key, m.nonce, m.data);
          return Uint8List.fromList([...cipher, ..._tag(key, m, cipher)]);
        }(),
    ];
  }

  @override
  Future<List<Uint8List>> open(
    Uint8List key,
    List<AeadMessage> messages,
  ) async {
    calls++;
    final out = <Uint8List>[];
    for (final m in messages) {
      final sealed = m.data;
      if (sealed.length < AeadCipher.tagLength) {
        throw const AeadAuthenticationException();
      }
      final split = sealed.length - AeadCipher.tagLength;
      final cipher = Uint8List.sublistView(sealed, 0, split);
      final tag = _tag(key, m, cipher);
      for (var i = 0; i < AeadCipher.tagLength; i++) {
        if (tag[i] != sealed[split + i]) {
          throw const AeadAuthenticationException();
        }
      }
      out.add(_xor(key, m.nonce, cipher));
    }
    return out;
  }

  static Uint8List _tag(Uint8List key, AeadMessage m, List<int> cipher) =>
      Uint8List.fromList(
        Hmac(sha256, key)
            .convert([...m.nonce, ...m.aad, ...cipher])
            .bytes
            .sublist(0, AeadCipher.tagLength),
      );

  static Uint8List _xor(Uint8List key, Uint8List nonce, List<int> data) {
    final out = Uint8List(data.length);
    for (var block = 0; block * 32 < data.length; block++) {
      final stream = sha256.convert([
        ...key,
        ...nonce,
        for (final shift in [24, 16, 8, 0]) (block >> shift) & 0xFF,
      ]).bytes;
      for (var i = 0; i < 32 && block * 32 + i < data.length; i++) {
        out[block * 32 + i] = data[block * 32 + i] ^ stream[i];
      }
    }
    return out;
  }
}
