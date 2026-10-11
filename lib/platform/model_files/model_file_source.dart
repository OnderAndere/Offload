import 'dart:io';

/// Where the files of a model come from (T6a.3, DD-002, DD-021): the
/// system's document picker on Android (the Storage Access Framework, so a
/// NAS or cloud app that offers documents works too) and the Open window on
/// Windows (network drives too). No permission is needed and the app never
/// connects anywhere itself. A picked file is copied into the app's own
/// storage, its SHA-256 computed while copying, so a wrong or damaged file is
/// known at once without reading it twice.
abstract class ModelFileSource {
  /// Lets the user choose one or more files; empty when cancelled.
  /// [fileTypeName] names the model files in the window (Windows).
  /// Throws [ModelFileException] ([ModelFileFailure.unavailable]).
  Future<List<PickedModelFile>> pickFiles({required String fileTypeName});

  /// Copies [file] to [target], a new file in the app's own storage, and
  /// returns the SHA-256 of what was copied (lowercase hex). [onProgress]
  /// hears the bytes copied so far now and then; [cancel] stops the copy.
  /// [target] may be left half written when it throws: the caller removes
  /// it. Throws [ModelFileException].
  Future<String> copy(
    PickedModelFile file,
    File target, {
    void Function(int copiedBytes)? onProgress,
    ModelFileCancel? cancel,
  });
}

/// A file the user picked: [ref] is the platform's handle (a document
/// address on Android, a path on Windows), [name] what the user sees,
/// [size] in bytes when the platform tells it.
class PickedModelFile {
  const PickedModelFile({required this.ref, required this.name, this.size});

  final String ref;
  final String name;
  final int? size;

  @override
  String toString() => 'PickedModelFile($name, $size)';
}

/// Stops a copy at the next block.
class ModelFileCancel {
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() => _cancelled = true;
}

class ModelFileException implements Exception {
  const ModelFileException(this.failure, [this.message]);

  final ModelFileFailure failure;
  final String? message;

  @override
  String toString() => 'ModelFileException: ${failure.name} $message';
}

enum ModelFileFailure {
  /// The window could not be opened, or the file could not be read.
  unavailable,

  /// The drive filled up while copying.
  noSpace,

  /// [ModelFileCancel.cancel] was called.
  cancelled,
}

/// The extension of model files (GGUF), without the dot.
const modelFileExtension = 'gguf';
