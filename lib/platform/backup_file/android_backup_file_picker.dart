import 'dart:io';

import 'package:flutter/services.dart';

import 'backup_file_picker.dart';

/// [BackupFilePicker] on Android: the system document picker
/// (`BackupFileChannel.kt`), no storage permission. The backup is written to,
/// or read from, a copy in the app's own cache, which is removed right after
/// (CLAUDE.md rule 2: an encrypted temporary copy in the own cache).
class AndroidBackupFilePicker implements BackupFilePicker {
  static const _channel = MethodChannel('eu.marandos.offload/backup_file');
  static const _directories = MethodChannel(
    'eu.marandos.offload/app_directory',
  );

  @override
  Future<bool> saveBackup({
    required String suggestedName,
    required String fileTypeName,
    required Future<void> Function(File target) write,
  }) => saveFile(
    suggestedName: suggestedName,
    extension: backupFileExtension,
    mimeType: backupMimeType,
    fileTypeName: fileTypeName,
    write: write,
  );

  @override
  Future<bool> saveFile({
    required String suggestedName,
    required String extension,
    required String mimeType,
    required String fileTypeName,
    required Future<void> Function(File target) write,
  }) async {
    // The document picker adds no extension by itself.
    final uri = await _invoke<String>('pickSaveTarget', {
      'suggestedName': '$suggestedName.$extension',
      'mimeType': mimeType,
    });
    if (uri == null) return false;
    // Removed right after, also an unencrypted export (CLAUDE.md rule 2).
    // The picker makes a new, empty document, or hands back an existing one
    // the user chose to overwrite (review): only the first may go when the
    // save fails before copying. Unknown counts as existing.
    int? sizeAtPick;
    try {
      sizeAtPick = await _invoke<int>('documentSize', {'uri': uri});
    } catch (_) {
      // Unknown: kept on failure.
    }
    final temporary = await _temporary('save-out.$extension');
    var copying = false;
    try {
      await write(temporary);
      copying = true;
      await _invoke<void>('copyToUri', {'source': temporary.path, 'uri': uri});
    } catch (_) {
      // No empty or half file that looks like a backup stays where the user
      // chose (T7.2 follow-up): a document the picker made, or one whose
      // old content the copy already cut off. Best effort: the first error
      // is the one to report.
      if (sizeAtPick == 0 || copying) {
        try {
          await _invoke<void>('deleteDocument', {'uri': uri});
        } catch (_) {}
      }
      rethrow;
    } finally {
      if (temporary.existsSync()) temporary.deleteSync();
    }
    return true;
  }

  @override
  Future<bool> openBackup({
    required String fileTypeName,
    required Future<void> Function(File source) read,
  }) async {
    final uri = await _invoke<String>('pickOpenFile', const {});
    if (uri == null) return false;
    final temporary = await _temporary('backup-in.$backupFileExtension');
    try {
      await _invoke<void>('copyFromUri', {
        'uri': uri,
        'target': temporary.path,
      });
      await read(temporary);
    } finally {
      if (temporary.existsSync()) temporary.deleteSync();
    }
    return true;
  }

  Future<File> _temporary(String name) async {
    final path = await _directories.invokeMethod<String>('cacheDirectory');
    if (path == null || path.isEmpty) {
      throw const BackupFilePickerException('No cache directory');
    }
    final directory = await Directory(path).create(recursive: true);
    return File('${directory.path}/$name');
  }

  Future<T?> _invoke<T>(String method, Map<String, String> arguments) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on PlatformException catch (e) {
      throw BackupFilePickerException(e.message ?? e.code);
    }
  }
}
