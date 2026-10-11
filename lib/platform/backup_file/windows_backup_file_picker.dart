import 'dart:io';

import 'package:flutter/services.dart';

import 'backup_file_picker.dart';

/// [BackupFilePicker] on Windows: the runner's save and open windows
/// (`save_dialog.cpp`). The chosen path is used directly, so no copy is
/// made anywhere else.
class WindowsBackupFilePicker implements BackupFilePicker {
  static const _channel = MethodChannel('eu.marandos.offload/save_dialog');

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
    final path = await _pick('pickSaveFile', {
      'suggestedName': suggestedName,
      'fileTypeName': fileTypeName,
      'extension': extension,
    });
    if (path == null) return false;
    await write(File(path));
    return true;
  }

  @override
  Future<bool> openBackup({
    required String fileTypeName,
    required Future<void> Function(File source) read,
  }) async {
    final path = await _pick('pickOpenFile', {
      'fileTypeName': fileTypeName,
      'extension': backupFileExtension,
    });
    if (path == null) return false;
    await read(File(path));
    return true;
  }

  Future<String?> _pick(String method, Map<String, String> arguments) async {
    try {
      return await _channel.invokeMethod<String>(method, arguments);
    } on PlatformException catch (e) {
      throw BackupFilePickerException(e.message ?? e.code);
    }
  }
}
