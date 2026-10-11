import 'dart:io';

import 'android_model_file_source.dart';
import 'model_file_source.dart';
import 'windows_model_file_source.dart';

/// The [ModelFileSource] for the platform the app runs on (T6a.3).
ModelFileSource createPlatformModelFileSource() {
  if (Platform.isAndroid) return AndroidModelFileSource();
  if (Platform.isWindows) return WindowsModelFileSource();
  throw UnsupportedError('Offload runs on Android and Windows only');
}
