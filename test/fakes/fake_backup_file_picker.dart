import 'dart:io';

import 'package:offload/platform/backup_file/backup_file_picker.dart';

/// A [BackupFilePicker] on files in [directory]: saving writes to
/// [savedName], opening reads [openName]; [cancel] answers as if the user
/// closed the window.
class FakeBackupFilePicker implements BackupFilePicker {
  FakeBackupFilePicker(this.directory);

  final Directory directory;
  String savedName = 'saved.offload';
  String openName = 'saved.offload';
  bool cancel = false;
  final suggestedNames = <String>[];

  File get saved => File('${directory.path}/$savedName');

  @override
  Future<bool> saveBackup({
    required String suggestedName,
    required String fileTypeName,
    required Future<void> Function(File target) write,
  }) async {
    suggestedNames.add(suggestedName);
    if (cancel) return false;
    await write(saved);
    return true;
  }

  /// Every [saveFile]: the name with its extension, and the type.
  final savedFiles = <({String name, String mimeType})>[];

  @override
  Future<bool> saveFile({
    required String suggestedName,
    required String extension,
    required String mimeType,
    required String fileTypeName,
    required Future<void> Function(File target) write,
  }) async {
    savedFiles.add((name: '$suggestedName.$extension', mimeType: mimeType));
    if (cancel) return false;
    await write(saved);
    return true;
  }

  @override
  Future<bool> openBackup({
    required String fileTypeName,
    required Future<void> Function(File source) read,
  }) async {
    if (cancel) return false;
    await read(File('${directory.path}/$openName'));
    return true;
  }
}
