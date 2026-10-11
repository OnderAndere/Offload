import 'dart:io';

/// Where a backup or an export goes and where a backup comes from (T7.2,
/// T7.3, DD-007): the system window of the platform, so the user chooses the
/// place and the app needs no permission and never connects anywhere. The
/// backup is encrypted before it is handed over; an export is the user's
/// explicit choice to take the data out unencrypted. Nothing here reads it.
abstract class BackupFilePicker {
  /// Asks where to save a backup, proposing [suggestedName], then lets
  /// [write] write it to a local file that ends up there. False when the
  /// user cancelled; then [write] does not run. [fileTypeName] names the
  /// file type in the window (Windows).
  Future<bool> saveBackup({
    required String suggestedName,
    required String fileTypeName,
    required Future<void> Function(File target) write,
  });

  /// Asks where to save a file of [mimeType], proposing [suggestedName] with
  /// [extension] (no dot), then lets [write] write it to a local file that
  /// ends up there. False when the user cancelled; then [write] does not
  /// run. [fileTypeName] names the file type in the window (Windows).
  Future<bool> saveFile({
    required String suggestedName,
    required String extension,
    required String mimeType,
    required String fileTypeName,
    required Future<void> Function(File target) write,
  });

  /// Asks for a backup, then lets [read] read it from a local file. False
  /// when the user cancelled; then [read] does not run.
  Future<bool> openBackup({
    required String fileTypeName,
    required Future<void> Function(File source) read,
  });
}

/// The window or the copy failed; nothing was written.
class BackupFilePickerException implements Exception {
  const BackupFilePickerException(this.message);

  final String message;

  @override
  String toString() => 'BackupFilePickerException: $message';
}

/// The extension of a backup file, without the dot.
const backupFileExtension = 'offload';

/// The type a backup file is shared as (DD-014): an encrypted file only
/// Offload opens.
const backupMimeType = 'application/octet-stream';
