import 'dart:io';

import 'package:flutter/services.dart';

import 'app_directory.dart';

/// [AppDirectory] on Android: the app's private `filesDir`, asked from the
/// platform through a channel (`MainActivity.kt`), without `path_provider`.
class AndroidAppDirectory implements AppDirectory {
  static const _channel = MethodChannel('eu.marandos.offload/app_directory');

  @override
  Future<Directory> dataDirectory() async {
    final path = await _channel.invokeMethod<String>('dataDirectory');
    if (path == null || path.isEmpty) {
      throw StateError('The platform returned no data directory');
    }
    return Directory(path).create(recursive: true);
  }

  /// The share folder (`ShareChannel.kt`) and the picker's copies
  /// (`AndroidBackupFilePicker`), the only files Offload puts in its cache;
  /// the rest of the cache belongs to the system.
  @override
  Future<int?> temporaryFilesSize() async {
    final path = await _channel.invokeMethod<String>('cacheDirectory');
    if (path == null || path.isEmpty) return 0;
    var total = 0;
    final share = Directory('$path/share');
    if (share.existsSync()) {
      for (final entry in share.listSync(recursive: true)) {
        if (entry is File) total += entry.lengthSync();
      }
    }
    final cache = Directory(path);
    if (cache.existsSync()) {
      for (final entry in cache.listSync()) {
        if (entry is File && _copy.hasMatch(entry.uri.pathSegments.last)) {
          total += entry.lengthSync();
        }
      }
    }
    return total;
  }

  /// `StatFs.availableBytes`: what the app may use, without the space
  /// the system keeps for itself.
  @override
  Future<int?> freeBytes(Directory directory) =>
      _channel.invokeMethod<int>('freeBytes', {'path': directory.path});

  static final _copy = RegExp(r'^(save-out|backup-out|backup-in)\.');
}
