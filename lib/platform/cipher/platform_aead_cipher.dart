import 'dart:io';

import 'package:flutter/services.dart';

import 'aead_cipher.dart';
import 'android_aead_cipher.dart';
import 'windows_aead_cipher.dart';

/// The [AeadCipher] of the platform the app runs on (DD-006).
AeadCipher createPlatformAeadCipher() {
  if (Platform.isAndroid) return AndroidAeadCipher();
  if (Platform.isWindows) return WindowsAeadCipher();
  throw UnsupportedError('Offload runs on Android and Windows only');
}

/// Makes the platform cipher inside a background isolate (T7.2b): call it
/// on the root isolate, send the result along, call that in the isolate. On
/// Android the isolate's method channel first needs the root isolate's
/// token; without one (tests) the cipher is made as is.
AeadCipher Function() backgroundAeadCipherFactory() {
  final token = RootIsolateToken.instance;
  return () {
    if (token != null) {
      BackgroundIsolateBinaryMessenger.ensureInitialized(token);
    }
    return createPlatformAeadCipher();
  };
}
