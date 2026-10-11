import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'share_channel.dart';

/// [ShareChannel] on Windows (DD-014): the clipboard, and "Save as…" through
/// the runner's save window (`save_dialog.cpp`). The Windows share window
/// needs package identity (MSIX), which Offload does not have.
class WindowsShareChannel implements ShareChannel {
  static const _channel = MethodChannel('eu.marandos.offload/save_dialog');

  @override
  List<ShareTarget> get textTargets => const [
    ShareTarget.clipboard,
    ShareTarget.file,
  ];

  @override
  Future<ShareResult> shareText(
    String text, {
    required ShareTarget target,
    String subject = '',
    String fileTypeName = '',
  }) async {
    switch (target) {
      case ShareTarget.clipboard:
        try {
          await Clipboard.setData(ClipboardData(text: text));
        } on PlatformException catch (e) {
          throw ShareChannelException(e.message ?? e.code);
        }
        return ShareResult.done;
      case ShareTarget.file:
        return _saveAs(text, subject, fileTypeName);
      case ShareTarget.system:
        throw ArgumentError.value(target, 'target');
    }
  }

  /// None: a file is saved with "Save as…" by the feature itself (for a
  /// backup the `BackupFilePicker`).
  @override
  List<ShareTarget> get fileTargets => const [];

  @override
  Future<ShareResult> shareFile({
    required String fileName,
    required String mimeType,
    required ShareTarget target,
    required Future<void> Function(File file) write,
    String subject = '',
  }) async => throw ArgumentError.value(target, 'target');

  Future<ShareResult> _saveAs(
    String text,
    String subject,
    String fileTypeName,
  ) async {
    final String? path;
    try {
      path = await _channel.invokeMethod<String>('pickSaveFile', {
        'suggestedName': suggestedFileName(subject),
        'fileTypeName': fileTypeName,
        'extension': 'txt',
      });
    } on PlatformException catch (e) {
      throw ShareChannelException(e.message ?? e.code);
    }
    if (path == null) return ShareResult.cancelled;
    try {
      // Windows line ends, so every editor shows the lines.
      await File(path).writeAsString(
        text.replaceAll(_lineBreak, '\r\n'),
        encoding: utf8,
        flush: true,
      );
    } on FileSystemException catch (e) {
      throw ShareChannelException(e.message);
    }
    return ShareResult.done;
  }

  static final _lineBreak = RegExp(r'\r\n|\r|\n');
}

/// A file name Windows accepts, made from [subject]: without the characters
/// Windows forbids, at most [maxLength] characters, not a reserved device
/// name. The app name when nothing is left.
@visibleForTesting
String suggestedFileName(String subject, {int maxLength = 60}) {
  var name = subject
      .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (name.length > maxLength) name = name.substring(0, maxLength);
  // No dot or space at the end; Windows drops them silently.
  name = name.replaceFirst(RegExp(r'[. ]+$'), '');
  if (name.isEmpty) return _appName;
  // Windows reserves the device name before the first dot.
  if (_reserved.hasMatch(name)) {
    final dot = name.indexOf('.');
    return dot < 0
        ? '${name}_'
        : '${name.substring(0, dot)}_${name.substring(dot)}';
  }
  return name;
}

/// The app name; not translated.
const _appName = 'Offload';

final _reserved = RegExp(
  r'^(con|prn|aux|nul|com[0-9]|lpt[0-9])(\..*)?$',
  caseSensitive: false,
);
