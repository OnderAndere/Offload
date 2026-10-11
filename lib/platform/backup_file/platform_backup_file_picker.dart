import 'dart:io';

import 'android_backup_file_picker.dart';
import 'backup_file_picker.dart';
import 'windows_backup_file_picker.dart';

/// The [BackupFilePicker] for the platform the app runs on (T7.2).
BackupFilePicker createPlatformBackupFilePicker() {
  if (Platform.isAndroid) return AndroidBackupFilePicker();
  if (Platform.isWindows) return WindowsBackupFilePicker();
  throw UnsupportedError('Offload runs on Android and Windows only');
}
