import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../app_directory/windows_app_directory.dart';
import 'key_store.dart';

/// [KeyStore] backed by Windows DPAPI (`CryptProtectData`), called through
/// `dart:ffi`. The blob is bound to the Windows user account; other accounts
/// on the same machine cannot unwrap it.
class WindowsKeyStore implements KeyStore {
  WindowsKeyStore({Directory? directory, this.name = masterKeyName})
    : _directory = directory ?? _defaultDirectory();

  /// Name of the production master key.
  static const masterKeyName = 'master_key';

  /// First byte of the key file; bump when the file layout changes.
  static const _formatVersion = 1;

  final Directory _directory;

  /// Distinguishes the production key from keys used by tests.
  final String name;

  File get _file =>
      File('${_directory.path}${Platform.pathSeparator}$name.key');

  /// Binds the blob to this app and key name (DPAPI "optional entropy").
  Uint8List get _entropy =>
      Uint8List.fromList(utf8.encode('eu.marandos.offload/$name'));

  @override
  Future<Uint8List?> readMasterKey() async {
    final file = _file;
    if (!file.existsSync()) return null;
    final Uint8List bytes;
    try {
      bytes = file.readAsBytesSync();
    } on FileSystemException catch (e) {
      throw KeyStoreException(KeyStoreErrorCode.unavailable, e.message);
    }
    if (bytes.isEmpty || bytes[0] != _formatVersion) {
      throw KeyStoreException(
        KeyStoreErrorCode.unavailable,
        'Unknown key file format',
      );
    }
    final key = _Win32.instance.unprotect(bytes.sublist(1), _entropy);
    if (key.length != KeyStore.keyLength) {
      throw KeyStoreException(
        KeyStoreErrorCode.unavailable,
        'Stored key has the wrong length',
      );
    }
    return key;
  }

  @override
  Future<void> createMasterKey(Uint8List key) async {
    if (key.length != KeyStore.keyLength) {
      throw ArgumentError.value(key.length, 'key.length');
    }
    final file = _file;
    if (file.existsSync()) {
      throw KeyStoreException(
        KeyStoreErrorCode.alreadyExists,
        'A master key already exists',
      );
    }
    final blob = _Win32.instance.protect(key, _entropy);
    // Write to a temporary file first, so a crash never leaves a half key.
    // The name is unique per process, so two app instances never share it.
    final temp = File(
      '${file.path}.$pid.${DateTime.now().microsecondsSinceEpoch}.tmp',
    );
    try {
      _directory.createSync(recursive: true);
      temp.writeAsBytesSync([_formatVersion, ...blob], flush: true);
    } on FileSystemException catch (e) {
      _deleteQuietly(temp);
      throw KeyStoreException(KeyStoreErrorCode.unavailable, e.message);
    }
    // A move that fails if the target exists: if another instance created a
    // key in the meantime, that key wins and this one is discarded.
    final moved = _Win32.instance.moveWithoutReplace(temp.path, file.path);
    if (!moved) {
      _deleteQuietly(temp);
      throw KeyStoreException(
        file.existsSync()
            ? KeyStoreErrorCode.alreadyExists
            : KeyStoreErrorCode.unavailable,
        'The key file could not be put in place',
      );
    }
  }

  /// Removes a test key. Refuses to delete the production master key.
  @visibleForTesting
  Future<void> deleteForTesting() async {
    if (name == masterKeyName) {
      throw StateError('The production master key is never deleted');
    }
    if (_file.existsSync()) _file.deleteSync();
  }

  /// Best-effort cleanup: a leftover temporary file is harmless, and a
  /// cleanup error must not hide the real error.
  static void _deleteQuietly(File file) {
    try {
      if (file.existsSync()) file.deleteSync();
    } on FileSystemException {
      // Ignored on purpose.
    }
  }

  static Directory _defaultDirectory() {
    try {
      return WindowsAppDirectory.defaultDirectory();
    } on StateError catch (e) {
      throw KeyStoreException(KeyStoreErrorCode.unavailable, e.message);
    }
  }
}

/// `DATA_BLOB` from `dpapi.h`.
final class _DataBlob extends Struct {
  @Uint32()
  external int cbData;

  external Pointer<Uint8> pbData;
}

typedef _CryptNative =
    Int32 Function(
      Pointer<_DataBlob> dataIn,
      Pointer<Void> description,
      Pointer<_DataBlob> entropy,
      Pointer<Void> reserved,
      Pointer<Void> prompt,
      Uint32 flags,
      Pointer<_DataBlob> dataOut,
    );
typedef _CryptDart =
    int Function(
      Pointer<_DataBlob> dataIn,
      Pointer<Void> description,
      Pointer<_DataBlob> entropy,
      Pointer<Void> reserved,
      Pointer<Void> prompt,
      int flags,
      Pointer<_DataBlob> dataOut,
    );

/// Minimal binding for DPAPI and `MoveFileExW`. Memory comes from `LocalAlloc`,
/// the allocator DPAPI itself uses for its output, so no extra FFI package is
/// needed.
class _Win32 {
  _Win32._() {
    final crypt32 = DynamicLibrary.open('crypt32.dll');
    final kernel32 = DynamicLibrary.open('kernel32.dll');
    _protect = crypt32.lookupFunction<_CryptNative, _CryptDart>(
      'CryptProtectData',
    );
    _unprotect = crypt32.lookupFunction<_CryptNative, _CryptDart>(
      'CryptUnprotectData',
    );
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
    _moveFileEx = kernel32
        .lookupFunction<
          Int32 Function(Pointer<Uint16>, Pointer<Uint16>, Uint32),
          int Function(Pointer<Uint16>, Pointer<Uint16>, int)
        >('MoveFileExW');
  }

  static final instance = _Win32._();

  /// `LMEM_FIXED | LMEM_ZEROINIT`.
  static const _lptr = 0x40;

  /// `CRYPTPROTECT_UI_FORBIDDEN`: never show a prompt.
  static const _uiForbidden = 0x1;

  /// `MOVEFILE_WRITE_THROUGH`: return only after the move is on disk.
  static const _writeThrough = 0x8;

  late final _CryptDart _protect;
  late final _CryptDart _unprotect;
  late final Pointer<Void> Function(int, int) _localAlloc;
  late final Pointer<Void> Function(Pointer<Void>) _localFree;
  late final int Function(Pointer<Uint16>, Pointer<Uint16>, int) _moveFileEx;

  /// Moves [from] to [to]; fails (returns false) if [to] already exists,
  /// because `MOVEFILE_REPLACE_EXISTING` is not set.
  bool moveWithoutReplace(String from, String to) {
    final source = _wide(from);
    final target = _wide(to);
    try {
      return _moveFileEx(source, target, _writeThrough) != 0;
    } finally {
      _localFree(source.cast());
      _localFree(target.cast());
    }
  }

  Pointer<Uint16> _wide(String text) {
    final units = text.codeUnits;
    final pointer = _alloc((units.length + 1) * 2).cast<Uint16>();
    pointer.asTypedList(units.length).setAll(0, units);
    return pointer; // LPTR zero-fills, so the terminator is already there.
  }

  Uint8List protect(Uint8List data, Uint8List entropy) =>
      _run(_protect, data, entropy);

  Uint8List unprotect(Uint8List data, Uint8List entropy) =>
      _run(_unprotect, data, entropy);

  Uint8List _run(_CryptDart function, Uint8List data, Uint8List entropy) {
    final input = _blobOf(data);
    final extra = _blobOf(entropy);
    final output = _alloc(sizeOf<_DataBlob>()).cast<_DataBlob>();
    try {
      final ok = function(
        input,
        nullptr,
        extra,
        nullptr,
        nullptr,
        _uiForbidden,
        output,
      );
      if (ok == 0) {
        throw KeyStoreException(
          KeyStoreErrorCode.unavailable,
          'DPAPI could not process the key',
        );
      }
      final result = Uint8List.fromList(
        output.ref.pbData.asTypedList(output.ref.cbData),
      );
      _wipeAndFree(output.ref.pbData, output.ref.cbData);
      return result;
    } finally {
      _freeBlob(input);
      _freeBlob(extra);
      _localFree(output.cast());
    }
  }

  Pointer<Uint8> _alloc(int size) {
    final pointer = _localAlloc(_lptr, size);
    if (pointer == nullptr) throw StateError('LocalAlloc failed');
    return pointer.cast();
  }

  Pointer<_DataBlob> _blobOf(Uint8List bytes) {
    final blob = _alloc(sizeOf<_DataBlob>()).cast<_DataBlob>();
    final data = _alloc(bytes.isEmpty ? 1 : bytes.length);
    data.asTypedList(bytes.length).setAll(0, bytes);
    blob.ref
      ..cbData = bytes.length
      ..pbData = data;
    return blob;
  }

  void _freeBlob(Pointer<_DataBlob> blob) {
    _wipeAndFree(blob.ref.pbData, blob.ref.cbData);
    _localFree(blob.cast());
  }

  /// Overwrites key material before the memory is released.
  void _wipeAndFree(Pointer<Uint8> data, int length) {
    if (data == nullptr) return;
    data.asTypedList(length).fillRange(0, length, 0);
    _localFree(data.cast());
  }
}
