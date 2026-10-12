import 'dart:typed_data';

import '../../domain/handwriting/reading_policy.dart';

/// Reads the handwriting in an image with the on-device vision model
/// (REQ-064, DD-021): llama.cpp in the app's own native library, on the CPU,
/// in a background isolate. The image is given as pixels in memory and is
/// never written to disk (CLAUDE.md rule 2, AC REQ-064 d); nothing reaches
/// the network (AC REQ-064 e). Android and Windows share one implementation
/// (`NativeHandwritingReader`); tests use a fake.
abstract class HandwritingReader {
  /// Whether this device can read handwriting: the native library is there
  /// (not on 32-bit Android).
  bool get isAvailable;

  /// Whether a reading pauses while the user is outside the app: Android
  /// freezes an app about 70 s after it is left (T6a.1), Windows does not.
  /// Only time in the app then counts towards the stop (DD-021).
  bool get pausesOutsideApp;

  /// Reads [image] with [model]: loads the model, reads, and frees the memory
  /// again. Takes tens of seconds to minutes; [onProgress] hears each change
  /// of phase and the number of text tokens written, [cancel] stops it.
  /// One reading at a time. Throws [HandwritingReaderException].
  Future<HandwritingReading> read({
    required HandwritingModel model,
    required ReadingImage image,
    ReadingSpeed speed = ReadingSpeed.accurate,
    ReadingPolicy policy = ReadingPolicy.standard,
    void Function(ReadingProgress progress)? onProgress,
    ReadingCancel? cancel,
  });
}

/// The two files of the vision model, local paths in the app's own storage
/// (imported in T6a.3).
class HandwritingModel {
  const HandwritingModel({
    required this.languageModelPath,
    required this.projectorPath,
  });

  /// The language model (`…Q4_K_M.gguf`).
  final String languageModelPath;

  /// The image projector (`mmproj-….gguf`).
  final String projectorPath;
}

/// An upright image as pixels: [width] × [height], three bytes (R, G, B) per
/// pixel, row by row; at most [ReadingPolicy.maxSide] on its longest side.
/// A reader refuses one whose [rgb] does not have exactly that size
/// ([HandwritingFailure.badImage]), also in a release build.
class ReadingImage {
  const ReadingImage({
    required this.width,
    required this.height,
    required this.rgb,
  });

  final int width;
  final int height;
  final Uint8List rgb;
}

/// What a reading is doing.
enum ReadingPhase {
  /// Reading the model files into memory (seconds).
  loading,

  /// The model looks at the image: most of the time.
  encoding,

  /// The model writes the text, token by token.
  writing,
}

class ReadingProgress {
  const ReadingProgress(this.phase, this.tokens);

  final ReadingPhase phase;

  /// Text tokens written so far.
  final int tokens;

  @override
  bool operator ==(Object other) =>
      other is ReadingProgress &&
      other.phase == phase &&
      other.tokens == tokens;

  @override
  int get hashCode => Object.hash(phase, tokens);

  @override
  String toString() => 'ReadingProgress(${phase.name}, $tokens)';
}

/// Stops a reading: [cancel] at any moment; the reading then ends soon with
/// [HandwritingFailure.cancelled] (after the current step of the model).
class ReadingCancel {
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() => _cancelled = true;
}

/// The text the model read, as it wrote it (the clean-up of DD-021 comes
/// after), and how long the steps took.
class HandwritingReading {
  const HandwritingReading({
    required this.text,
    required this.loadTime,
    required this.encodeTime,
    required this.totalTime,
  });

  final String text;
  final Duration loadTime;
  final Duration encodeTime;
  final Duration totalTime;
}

class HandwritingReaderException implements Exception {
  const HandwritingReaderException(this.failure, [this.message]);

  final HandwritingFailure failure;
  final String? message;

  @override
  String toString() => 'HandwritingReaderException: ${failure.name} $message';
}

enum HandwritingFailure {
  /// No native library on this device ([HandwritingReader.isAvailable]).
  unavailable,

  /// A model file could not be read: missing or damaged.
  modelUnreadable,

  /// Too little memory for the model's context.
  outOfMemory,

  /// The image was not usable.
  badImage,

  /// The model failed while reading.
  failed,

  /// [ReadingCancel.cancel] was called.
  cancelled,
}
