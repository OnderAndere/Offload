import 'dart:ffi';
import 'dart:typed_data';

import 'aead_cipher.dart';

/// [AeadCipher] on Windows CNG (`bcrypt.dll`, part of Windows), called
/// through `dart:ffi`: no library ships with the app.
class WindowsAeadCipher implements AeadCipher {
  @override
  Future<List<Uint8List>> seal(
    Uint8List key,
    List<AeadMessage> messages,
  ) async => _Cng.instance.run(key, messages, encrypt: true);

  @override
  Future<List<Uint8List>> open(
    Uint8List key,
    List<AeadMessage> messages,
  ) async => _Cng.instance.run(key, messages, encrypt: false);
}

/// `BCRYPT_AUTHENTICATED_CIPHER_MODE_INFO` (bcrypt.h); 88 bytes on x64.
final class _AuthInfo extends Struct {
  @Uint32()
  external int cbSize;
  @Uint32()
  external int dwInfoVersion;
  external Pointer<Uint8> pbNonce;
  @Uint32()
  external int cbNonce;
  external Pointer<Uint8> pbAuthData;
  @Uint32()
  external int cbAuthData;
  external Pointer<Uint8> pbTag;
  @Uint32()
  external int cbTag;
  external Pointer<Uint8> pbMacContext;
  @Uint32()
  external int cbMacContext;
  @Uint32()
  external int cbAAD;
  @Uint64()
  external int cbData;
  @Uint32()
  external int dwFlags;
}

typedef _OpenNative =
    Int32 Function(
      Pointer<Pointer<Void>>,
      Pointer<Uint16>,
      Pointer<Uint16>,
      Uint32,
    );
typedef _OpenDart =
    int Function(Pointer<Pointer<Void>>, Pointer<Uint16>, Pointer<Uint16>, int);
typedef _SetPropertyNative =
    Int32 Function(
      Pointer<Void>,
      Pointer<Uint16>,
      Pointer<Uint8>,
      Uint32,
      Uint32,
    );
typedef _SetPropertyDart =
    int Function(Pointer<Void>, Pointer<Uint16>, Pointer<Uint8>, int, int);
typedef _GenerateKeyNative =
    Int32 Function(
      Pointer<Void>,
      Pointer<Pointer<Void>>,
      Pointer<Uint8>,
      Uint32,
      Pointer<Uint8>,
      Uint32,
      Uint32,
    );
typedef _GenerateKeyDart =
    int Function(
      Pointer<Void>,
      Pointer<Pointer<Void>>,
      Pointer<Uint8>,
      int,
      Pointer<Uint8>,
      int,
      int,
    );
typedef _CryptNative =
    Int32 Function(
      Pointer<Void>,
      Pointer<Uint8>,
      Uint32,
      Pointer<_AuthInfo>,
      Pointer<Uint8>,
      Uint32,
      Pointer<Uint8>,
      Uint32,
      Pointer<Uint32>,
      Uint32,
    );
typedef _CryptDart =
    int Function(
      Pointer<Void>,
      Pointer<Uint8>,
      int,
      Pointer<_AuthInfo>,
      Pointer<Uint8>,
      int,
      Pointer<Uint8>,
      int,
      Pointer<Uint32>,
      int,
    );

class _Cng {
  _Cng._() {
    final bcrypt = DynamicLibrary.open('bcrypt.dll');
    final kernel32 = DynamicLibrary.open('kernel32.dll');
    _openProvider = bcrypt.lookupFunction<_OpenNative, _OpenDart>(
      'BCryptOpenAlgorithmProvider',
    );
    _setProperty = bcrypt.lookupFunction<_SetPropertyNative, _SetPropertyDart>(
      'BCryptSetProperty',
    );
    _generateKey = bcrypt.lookupFunction<_GenerateKeyNative, _GenerateKeyDart>(
      'BCryptGenerateSymmetricKey',
    );
    _encrypt = bcrypt.lookupFunction<_CryptNative, _CryptDart>('BCryptEncrypt');
    _decrypt = bcrypt.lookupFunction<_CryptNative, _CryptDart>('BCryptDecrypt');
    _destroyKey = bcrypt
        .lookupFunction<
          Int32 Function(Pointer<Void>),
          int Function(Pointer<Void>)
        >('BCryptDestroyKey');
    _localAlloc = kernel32
        .lookupFunction<
          Pointer<Void> Function(Uint32, IntPtr),
          Pointer<Void> Function(int, int)
        >('LocalAlloc');
    _localFree = kernel32
        .lookupFunction<
          Pointer<Void> Function(Pointer<Void>),
          Pointer<Void> Function(Pointer<Void>)
        >('LocalFree');
    _algorithm = _openAesGcm();
  }

  static final instance = _Cng._();

  /// `LMEM_FIXED | LMEM_ZEROINIT`.
  static const _lptr = 0x40;

  /// `STATUS_AUTH_TAG_MISMATCH`.
  static const _authTagMismatch = 0xC000A002;

  late final _OpenDart _openProvider;
  late final _SetPropertyDart _setProperty;
  late final _GenerateKeyDart _generateKey;
  late final _CryptDart _encrypt;
  late final _CryptDart _decrypt;
  late final int Function(Pointer<Void>) _destroyKey;
  late final Pointer<Void> Function(int, int) _localAlloc;
  late final Pointer<Void> Function(Pointer<Void>) _localFree;

  /// The AES provider in GCM mode, open for the life of the process.
  late final Pointer<Void> _algorithm;

  Pointer<Void> _openAesGcm() {
    final handle = _alloc(sizeOf<Pointer<Void>>()).cast<Pointer<Void>>();
    final aes = _wide('AES');
    final property = _wide('ChainingMode');
    final gcm = _wide('ChainingModeGCM');
    try {
      _check(_openProvider(handle, aes, nullptr, 0));
      final algorithm = handle.value;
      // The value is the wide string with its terminator, in bytes.
      _check(
        _setProperty(
          algorithm,
          property,
          gcm.cast(),
          ('ChainingModeGCM'.length + 1) * 2,
          0,
        ),
      );
      return algorithm;
    } finally {
      _localFree(handle.cast());
      _localFree(aes.cast());
      _localFree(property.cast());
      _localFree(gcm.cast());
    }
  }

  List<Uint8List> run(
    Uint8List key,
    List<AeadMessage> messages, {
    required bool encrypt,
  }) {
    if (key.length != AeadCipher.keyLength) {
      throw ArgumentError.value(key.length, 'key.length');
    }
    final keyHandle = _alloc(sizeOf<Pointer<Void>>()).cast<Pointer<Void>>();
    final secret = _copy(key);
    try {
      _check(
        _generateKey(_algorithm, keyHandle, nullptr, 0, secret, key.length, 0),
      );
      try {
        return [
          for (final message in messages)
            encrypt
                ? _seal(keyHandle.value, message)
                : _open(keyHandle.value, message),
        ];
      } finally {
        _destroyKey(keyHandle.value);
      }
    } finally {
      // The secret goes back zeroed, not just freed.
      secret.asTypedList(key.length).fillRange(0, key.length, 0);
      _localFree(secret.cast());
      _localFree(keyHandle.cast());
    }
  }

  Uint8List _seal(Pointer<Void> key, AeadMessage message) {
    final length = message.data.length;
    final input = _copy(message.data);
    final output = _alloc(length == 0 ? 1 : length).cast<Uint8>();
    final tag = _alloc(AeadCipher.tagLength).cast<Uint8>();
    final info = _info(message, tag);
    final written = _alloc(sizeOf<Uint32>()).cast<Uint32>();
    try {
      _check(
        _encrypt(
          key,
          input,
          length,
          info,
          nullptr,
          0,
          output,
          length,
          written,
          0,
        ),
      );
      return Uint8List(length + AeadCipher.tagLength)
        ..setRange(0, length, output.asTypedList(length))
        ..setRange(
          length,
          length + AeadCipher.tagLength,
          tag.asTypedList(AeadCipher.tagLength),
        );
    } finally {
      // The native copy of the plaintext goes back zeroed.
      if (length > 0) input.asTypedList(length).fillRange(0, length, 0);
      _freeInfo(info);
      for (final p in [input, output, tag, written]) {
        _localFree(p.cast());
      }
    }
  }

  Uint8List _open(Pointer<Void> key, AeadMessage message) {
    final sealed = message.data;
    if (sealed.length < AeadCipher.tagLength) {
      throw const AeadAuthenticationException();
    }
    final length = sealed.length - AeadCipher.tagLength;
    final input = _copy(Uint8List.sublistView(sealed, 0, length));
    final tag = _copy(Uint8List.sublistView(sealed, length));
    final output = _alloc(length == 0 ? 1 : length).cast<Uint8>();
    final info = _info(message, tag);
    final written = _alloc(sizeOf<Uint32>()).cast<Uint32>();
    try {
      final status = _decrypt(
        key,
        input,
        length,
        info,
        nullptr,
        0,
        output,
        length,
        written,
        0,
      );
      if (status.toUnsigned(32) == _authTagMismatch) {
        throw const AeadAuthenticationException();
      }
      _check(status);
      return Uint8List.fromList(output.asTypedList(length));
    } finally {
      // Plaintext from a failed check must not linger in native memory.
      if (length > 0) output.asTypedList(length).fillRange(0, length, 0);
      _freeInfo(info);
      for (final p in [input, output, tag, written]) {
        _localFree(p.cast());
      }
    }
  }

  Pointer<_AuthInfo> _info(AeadMessage message, Pointer<Uint8> tag) {
    final info = _alloc(sizeOf<_AuthInfo>()).cast<_AuthInfo>();
    info.ref
      ..cbSize = sizeOf<_AuthInfo>()
      ..dwInfoVersion = 1
      ..pbNonce = _copy(message.nonce)
      ..cbNonce = message.nonce.length
      ..pbAuthData = message.aad.isEmpty ? nullptr : _copy(message.aad)
      ..cbAuthData = message.aad.length
      ..pbTag = tag
      ..cbTag = AeadCipher.tagLength;
    return info;
  }

  void _freeInfo(Pointer<_AuthInfo> info) {
    _localFree(info.ref.pbNonce.cast());
    if (info.ref.pbAuthData != nullptr) {
      _localFree(info.ref.pbAuthData.cast());
    }
    _localFree(info.cast());
  }

  Pointer<Uint8> _copy(Uint8List bytes) {
    final pointer = _alloc(bytes.isEmpty ? 1 : bytes.length).cast<Uint8>();
    if (bytes.isNotEmpty) pointer.asTypedList(bytes.length).setAll(0, bytes);
    return pointer;
  }

  Pointer<Uint16> _wide(String text) {
    final units = text.codeUnits;
    final pointer = _alloc((units.length + 1) * 2).cast<Uint16>();
    pointer.asTypedList(units.length).setAll(0, units);
    return pointer; // LPTR zero-fills, so the terminator is already there.
  }

  Pointer<Void> _alloc(int bytes) {
    final pointer = _localAlloc(_lptr, bytes);
    if (pointer == nullptr) {
      throw const AeadUnavailableException('out of memory');
    }
    return pointer;
  }

  static void _check(int status) {
    if (status < 0) {
      throw AeadUnavailableException(
        'CNG failed: 0x${status.toUnsigned(32).toRadixString(16)}',
      );
    }
  }
}
