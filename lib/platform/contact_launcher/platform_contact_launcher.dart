import 'dart:io';

import 'android_contact_launcher.dart';
import 'contact_launcher.dart';
import 'windows_contact_launcher.dart';

/// The [ContactLauncher] for the platform the app runs on.
ContactLauncher createPlatformContactLauncher() {
  if (Platform.isAndroid) return AndroidContactLauncher();
  if (Platform.isWindows) return WindowsContactLauncher();
  throw UnsupportedError('Offload runs on Android and Windows only');
}
