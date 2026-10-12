import 'package:flutter/services.dart';

import 'screen_awake.dart';

/// [ScreenAwake] on Android: `FLAG_KEEP_SCREEN_ON` on the app's window
/// (`MainActivity.kt`), which needs no permission. It holds only while the
/// app's window is on screen.
class AndroidScreenAwake implements ScreenAwake {
  static const _channel = MethodChannel('eu.marandos.offload/screen_awake');

  @override
  Future<void> keepAwake(bool on) =>
      _channel.invokeMethod<void>('keepScreenOn', {'on': on});
}
