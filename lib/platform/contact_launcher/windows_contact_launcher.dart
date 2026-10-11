import 'dart:ffi';

import 'contact_launcher.dart';

/// [ContactLauncher] on Windows: `mailto:` through the shell
/// (`ShellExecuteW`), which opens the user's mail app. No dialling: a
/// number is copied instead (DD-018 point 9).
class WindowsContactLauncher implements ContactLauncher {
  @override
  bool get canDial => false;

  @override
  Future<void> dial(String number) async =>
      throw UnsupportedError('No dialler on Windows');

  @override
  Future<void> mail(String address) async {
    if (!_Shell.instance.open(mailtoUri(address).toString())) {
      throw const ContactLauncherException('No mail app');
    }
  }
}

/// Minimal binding for `ShellExecuteW`. Memory comes from `LocalAlloc`, as
/// in the Windows key store, so no extra FFI package is needed.
class _Shell {
  _Shell._() {
    final shell32 = DynamicLibrary.open('shell32.dll');
    final kernel32 = DynamicLibrary.open('kernel32.dll');
    _shellExecute = shell32
        .lookupFunction<
          IntPtr Function(
            IntPtr,
            Pointer<Uint16>,
            Pointer<Uint16>,
            Pointer<Uint16>,
            Pointer<Uint16>,
            Int32,
          ),
          int Function(
            int,
            Pointer<Uint16>,
            Pointer<Uint16>,
            Pointer<Uint16>,
            Pointer<Uint16>,
            int,
          )
        >('ShellExecuteW');
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

  static final instance = _Shell._();

  /// `LMEM_FIXED | LMEM_ZEROINIT`.
  static const _lptr = 0x40;

  /// `SW_SHOWNORMAL`.
  static const _showNormal = 1;

  late final int Function(
    int,
    Pointer<Uint16>,
    Pointer<Uint16>,
    Pointer<Uint16>,
    Pointer<Uint16>,
    int,
  )
  _shellExecute;
  late final Pointer<Void> Function(int, int) _localAlloc;
  late final Pointer<Void> Function(Pointer<Void>) _localFree;

  /// Opens [target] with its registered handler; false when none took it
  /// (`ShellExecuteW` returns a value of 32 or less on failure).
  bool open(String target) {
    final verb = _wide('open');
    final file = _wide(target);
    try {
      return _shellExecute(0, verb, file, nullptr, nullptr, _showNormal) > 32;
    } finally {
      _localFree(verb.cast());
      _localFree(file.cast());
    }
  }

  Pointer<Uint16> _wide(String text) {
    final units = text.codeUnits;
    final pointer = _localAlloc(_lptr, (units.length + 1) * 2).cast<Uint16>();
    if (pointer == nullptr) throw StateError('LocalAlloc failed');
    pointer.asTypedList(units.length).setAll(0, units);
    return pointer; // LPTR zero-fills, so the terminator is already there.
  }
}
