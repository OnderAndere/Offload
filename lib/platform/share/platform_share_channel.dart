import 'dart:io';

import 'android_share_channel.dart';
import 'share_channel.dart';
import 'windows_share_channel.dart';

/// The [ShareChannel] for the platform the app runs on (DD-014).
ShareChannel createPlatformShareChannel() {
  if (Platform.isAndroid) return AndroidShareChannel();
  if (Platform.isWindows) return WindowsShareChannel();
  throw UnsupportedError('Offload runs on Android and Windows only');
}
