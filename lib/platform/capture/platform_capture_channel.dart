import 'dart:io';

import 'android_capture_channel.dart';
import 'capture_channel.dart';
import 'windows_capture_channel.dart';

/// The [CaptureChannel] for the platform the app runs on (DD-010).
CaptureChannel createPlatformCaptureChannel() {
  if (Platform.isAndroid) return AndroidCaptureChannel();
  if (Platform.isWindows) return WindowsCaptureChannel();
  throw UnsupportedError('Offload runs on Android and Windows only');
}
