import 'dart:io';

import 'android_app_directory.dart';
import 'app_directory.dart';
import 'windows_app_directory.dart';

/// The [AppDirectory] for the platform the app runs on.
AppDirectory createPlatformAppDirectory() {
  if (Platform.isAndroid) return AndroidAppDirectory();
  if (Platform.isWindows) return WindowsAppDirectory();
  throw UnsupportedError('Offload runs on Android and Windows only');
}
