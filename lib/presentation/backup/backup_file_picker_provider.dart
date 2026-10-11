import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../platform/backup_file/backup_file_picker.dart';
import '../../platform/backup_file/platform_backup_file_picker.dart';

/// Where backups and exports are saved and opened (T7.2, T7.3).
final backupFilePickerProvider = Provider<BackupFilePicker>(
  (ref) => createPlatformBackupFilePicker(),
);
