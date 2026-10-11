import 'dart:typed_data';

/// Where a photo for an item comes from (T5.3, REQ-024): the device's camera
/// app or the system's photo picker on Android, the Open window on Windows.
/// No permission is needed for either. The answer is the picture's bytes in
/// memory; `PhotoStorageService` makes them small, upright and without EXIF,
/// and encrypts them. Nothing here keeps a copy.
abstract class PhotoSource {
  /// Whether a photo can be taken here: Android, through the camera app.
  bool get canTakePhoto;

  /// Takes a photo with the device's camera app; its bytes, or null when the
  /// user cancelled. Only when [canTakePhoto].
  Future<Uint8List?> takePhoto();

  /// Lets the user choose one picture; its bytes, or null when the user
  /// cancelled. [fileTypeName] names the pictures in the window (Windows).
  Future<Uint8List?> pickPhoto({required String fileTypeName});
}

/// Why no photo came: the window or the camera app could not be opened or
/// read ([PhotoSourceFailure.unavailable]), or the picture is larger than
/// [maxPhotoSourceBytes] ([PhotoSourceFailure.tooLarge]).
class PhotoSourceException implements Exception {
  const PhotoSourceException(this.failure, [this.message]);

  final PhotoSourceFailure failure;
  final String? message;

  @override
  String toString() => 'PhotoSourceException: ${failure.name} $message';
}

enum PhotoSourceFailure { unavailable, tooLarge }

/// The largest picture read into memory: far above a photo of a 200 MP phone
/// camera, well below what a phone has to spare.
const maxPhotoSourceBytes = 100 * 1024 * 1024;

/// The extensions the Open window offers as pictures (Windows): what the
/// engine's codec decodes there.
const photoFileExtensions = ['jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp'];
