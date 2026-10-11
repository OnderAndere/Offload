import 'dart:io';

import 'android_key_store.dart';
import 'key_store.dart';
import 'windows_key_store.dart';

/// The [KeyStore] for the platform the app runs on (DD-007).
KeyStore createPlatformKeyStore() {
  if (Platform.isAndroid) return AndroidKeyStore();
  if (Platform.isWindows) return WindowsKeyStore();
  throw UnsupportedError('Offload runs on Android and Windows only');
}
