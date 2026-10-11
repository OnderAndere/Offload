import 'dart:io';

import 'android_photo_source.dart';
import 'photo_source.dart';
import 'windows_photo_source.dart';

/// The [PhotoSource] for the platform the app runs on (T5.3).
PhotoSource createPlatformPhotoSource() {
  if (Platform.isAndroid) return AndroidPhotoSource();
  if (Platform.isWindows) return WindowsPhotoSource();
  throw UnsupportedError('Offload runs on Android and Windows only');
}
