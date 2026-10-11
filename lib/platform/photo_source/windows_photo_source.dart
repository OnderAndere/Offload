import 'dart:io';

import 'package:flutter/services.dart';

import 'photo_source.dart';

/// [PhotoSource] on Windows: the runner's Open window (`save_dialog.cpp`)
/// with a filter on pictures, then the chosen file read into memory. No
/// camera.
class WindowsPhotoSource implements PhotoSource {
  static const _channel = MethodChannel('eu.marandos.offload/save_dialog');

  @override
  bool get canTakePhoto => false;

  @override
  Future<Uint8List?> takePhoto() =>
      throw UnsupportedError('No camera on Windows');

  @override
  Future<Uint8List?> pickPhoto({required String fileTypeName}) async {
    final String? path;
    try {
      path = await _channel.invokeMethod<String>('pickOpenFile', {
        'fileTypeName': fileTypeName,
        'extension': photoFileExtensions.join(';'),
      });
    } on PlatformException catch (e) {
      throw PhotoSourceException(
        PhotoSourceFailure.unavailable,
        e.message ?? e.code,
      );
    }
    if (path == null) return null;
    final file = File(path);
    try {
      if (await file.length() > maxPhotoSourceBytes) {
        throw const PhotoSourceException(PhotoSourceFailure.tooLarge);
      }
      return await file.readAsBytes();
    } on FileSystemException catch (e) {
      throw PhotoSourceException(PhotoSourceFailure.unavailable, e.message);
    }
  }
}
