import 'dart:ffi';
import 'dart:io';

import 'app_directory.dart';

/// [AppDirectory] on Windows: `%LOCALAPPDATA%\eu.marandos.offload`, next to
/// the master key file (`WindowsKeyStore`).
class WindowsAppDirectory implements AppDirectory {
  @override
  Future<Directory> dataDirectory() =>
      defaultDirectory().create(recursive: true);

  /// None: "Save as" writes where the user chose, and nothing is shared
  /// from a copy.
  @override
  Future<int?> temporaryFilesSize() async => null;

  /// `GetDiskFreeSpaceExW` (kernel32, part of Windows) through `dart:ffi`:
  /// the bytes free to this user, quotas included.
  @override
  Future<int?> freeBytes(Directory directory) async =>
      _DiskSpace.instance.freeBytes(directory.absolute.path);

  /// The directory, not yet created. Throws [StateError] when `LOCALAPPDATA`
  /// is not set.
  static Directory defaultDirectory() {
    final base = Platform.environment['LOCALAPPDATA'];
    if (base == null || base.isEmpty) {
      throw StateError('LOCALAPPDATA is not set');
    }
    return Directory('$base\\eu.marandos.offload');
  }
}

class _DiskSpace {
  _DiskSpace._() {
    final kernel32 = DynamicLibrary.open('kernel32.dll');
    _freeSpace = kernel32
        .lookupFunction<
          Int32 Function(
            Pointer<Uint16>,
            Pointer<Uint64>,
            Pointer<Uint64>,
            Pointer<Uint64>,
          ),
          int Function(
            Pointer<Uint16>,
            Pointer<Uint64>,
            Pointer<Uint64>,
            Pointer<Uint64>,
          )
        >('GetDiskFreeSpaceExW');
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
  }

  static final instance = _DiskSpace._();

  /// `LMEM_FIXED | LMEM_ZEROINIT`.
  static const _lptr = 0x40;

  late final int Function(
    Pointer<Uint16>,
    Pointer<Uint64>,
    Pointer<Uint64>,
    Pointer<Uint64>,
  )
  _freeSpace;
  late final Pointer<Void> Function(int, int) _localAlloc;
  late final Pointer<Void> Function(Pointer<Void>) _localFree;

  /// Null when Windows cannot tell (a path that does not exist, or a
  /// network share named without its trailing backslash): then the caller
  /// goes on without the check.
  int? freeBytes(String path) {
    final units = path.codeUnits;
    // Zero-filled, so the terminator is already there.
    final name = _localAlloc(_lptr, (units.length + 1) * 2).cast<Uint16>();
    final free = _localAlloc(_lptr, sizeOf<Uint64>()).cast<Uint64>();
    if (name == nullptr || free == nullptr) {
      if (name != nullptr) _localFree(name.cast());
      if (free != nullptr) _localFree(free.cast());
      return null;
    }
    try {
      name.asTypedList(units.length).setAll(0, units);
      if (_freeSpace(name, free, nullptr, nullptr) == 0) return null;
      return free.value;
    } finally {
      _localFree(name.cast());
      _localFree(free.cast());
    }
  }
}
