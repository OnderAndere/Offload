import 'dart:ffi';

import 'screen_awake.dart';

/// [ScreenAwake] on Windows: `SetThreadExecutionState` (kernel32, part of
/// Windows) through `dart:ffi`, so the PC does not sleep while a reading
/// runs. The state belongs to the calling thread, the app's UI thread,
/// which lives as long as the app.
class WindowsScreenAwake implements ScreenAwake {
  @override
  Future<void> keepAwake(bool on) async {
    // The previous state, or 0 when Windows refused.
    if (_setState(on ? _esContinuous | _esSystemRequired : _esContinuous) ==
        0) {
      throw StateError('SetThreadExecutionState failed');
    }
  }

  static final _setState = DynamicLibrary.open('kernel32.dll')
      .lookupFunction<Uint32 Function(Uint32), int Function(int)>(
        'SetThreadExecutionState',
      );

  static const _esContinuous = 0x80000000;
  static const _esSystemRequired = 0x00000001;
}
