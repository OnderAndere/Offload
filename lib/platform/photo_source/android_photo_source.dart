import 'package:flutter/services.dart';

import 'photo_source.dart';

/// [PhotoSource] on Android (`PhotoChannel.kt`): the camera app through
/// `ACTION_IMAGE_CAPTURE` and the photo picker through `ACTION_PICK_IMAGES`.
/// The camera app's file in the app's cache is removed right after reading.
class AndroidPhotoSource implements PhotoSource {
  static const _channel = MethodChannel('eu.marandos.offload/photo');

  @override
  bool get canTakePhoto => true;

  @override
  Future<Uint8List?> takePhoto() => _invoke('takePhoto');

  @override
  Future<Uint8List?> pickPhoto({required String fileTypeName}) =>
      _invoke('pickPhoto');

  Future<Uint8List?> _invoke(String method) async {
    try {
      return await _channel.invokeMethod<Uint8List>(method, {
        'maxBytes': maxPhotoSourceBytes,
      });
    } on PlatformException catch (e) {
      throw PhotoSourceException(
        e.code == 'tooLarge'
            ? PhotoSourceFailure.tooLarge
            : PhotoSourceFailure.unavailable,
        e.message ?? e.code,
      );
    }
  }
}
