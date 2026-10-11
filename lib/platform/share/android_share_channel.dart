import 'dart:io';

import 'package:flutter/services.dart';

import 'share_channel.dart';

/// [ShareChannel] on the Android share menu (`ShareChannel.kt`): an own thin
/// `ACTION_SEND`, no plugin and no permission (DD-014). A file goes out from
/// the share folder in the app's cache through a `FileProvider`.
class AndroidShareChannel implements ShareChannel {
  static const _channel = MethodChannel('eu.marandos.offload/share');

  @override
  List<ShareTarget> get textTargets => const [ShareTarget.system];

  @override
  Future<ShareResult> shareText(
    String text, {
    required ShareTarget target,
    String subject = '',
    String fileTypeName = '',
  }) async {
    if (target != ShareTarget.system) {
      throw ArgumentError.value(target, 'target');
    }
    try {
      await _channel.invokeMethod<void>('shareText', {
        'text': text,
        'subject': subject,
      });
      return ShareResult.done;
    } on PlatformException catch (e) {
      throw ShareChannelException(e.message ?? e.code);
    }
  }

  @override
  List<ShareTarget> get fileTargets => const [ShareTarget.system];

  @override
  Future<ShareResult> shareFile({
    required String fileName,
    required String mimeType,
    required ShareTarget target,
    required Future<void> Function(File file) write,
    String subject = '',
  }) async {
    if (target != ShareTarget.system) {
      throw ArgumentError.value(target, 'target');
    }
    // Emptied by the platform side, so it holds this file only.
    final directory = await _invoke<String>('prepareShareDirectory', const {});
    if (directory == null || directory.isEmpty) {
      throw const ShareChannelException('No share directory');
    }
    final file = File('$directory/$fileName');
    try {
      await write(file);
    } catch (_) {
      if (file.existsSync()) file.deleteSync();
      rethrow;
    }
    await _invoke<void>('shareFile', {
      'path': file.path,
      'mimeType': mimeType,
      'subject': subject,
    });
    return ShareResult.done;
  }

  Future<T?> _invoke<T>(String method, Map<String, String> arguments) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on PlatformException catch (e) {
      throw ShareChannelException(e.message ?? e.code);
    }
  }
}
