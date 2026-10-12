import 'dart:io';

import 'android_screen_awake.dart';
import 'screen_awake.dart';
import 'windows_screen_awake.dart';

/// The [ScreenAwake] for the platform the app runs on.
ScreenAwake createPlatformScreenAwake() {
  if (Platform.isAndroid) return AndroidScreenAwake();
  if (Platform.isWindows) return WindowsScreenAwake();
  throw UnsupportedError('Offload runs on Android and Windows only');
}
