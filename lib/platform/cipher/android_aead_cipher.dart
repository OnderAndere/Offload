import 'package:flutter/services.dart';

import 'aead_cipher.dart';

/// [AeadCipher] on Android's own `javax.crypto` (`AeadChannel.kt`): one
/// platform call per batch of messages.
class AndroidAeadCipher implements AeadCipher {
  static const _channel = MethodChannel('eu.marandos.offload/aead');

  @override
  Future<List<Uint8List>> seal(Uint8List key, List<AeadMessage> messages) =>
      _call('seal', key, messages);

  @override
  Future<List<Uint8List>> open(Uint8List key, List<AeadMessage> messages) =>
      _call('open', key, messages);

  Future<List<Uint8List>> _call(
    String method,
    Uint8List key,
    List<AeadMessage> messages,
  ) async {
    if (key.length != AeadCipher.keyLength) {
      throw ArgumentError.value(key.length, 'key.length');
    }
    try {
      final result = await _channel.invokeListMethod<Uint8List>(method, {
        'key': key,
        'nonces': [for (final m in messages) m.nonce],
        'aads': [for (final m in messages) m.aad],
        'data': [for (final m in messages) m.data],
      });
      if (result == null || result.length != messages.length) {
        throw const AeadUnavailableException('unexpected answer');
      }
      return result;
    } on PlatformException catch (e) {
      if (e.code == 'auth') throw const AeadAuthenticationException();
      throw AeadUnavailableException(e.message ?? e.code);
    }
  }
}
