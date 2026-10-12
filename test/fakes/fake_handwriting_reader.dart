import 'dart:async';

import 'package:offload/domain/handwriting/reading_policy.dart';
import 'package:offload/platform/handwriting/handwriting_reader.dart';

/// A [HandwritingReader] that answers with [next]: the text read, or a
/// [HandwritingReaderException] to throw. [progress] is reported first; a
/// [ReadingCancel] cancelled by then ends the reading as cancelled. [hold]
/// keeps the answer back until [release], to look at the screen while it
/// reads; a cancel meanwhile is looked at after the release.
class FakeHandwritingReader implements HandwritingReader {
  FakeHandwritingReader({
    this.isAvailable = true,
    this.pausesOutsideApp = true,
  });

  @override
  final bool isAvailable;

  @override
  final bool pausesOutsideApp;

  Object next = '';
  List<ReadingProgress> progress = const [];
  final calls = <({ReadingImage image, ReadingSpeed speed})>[];
  bool hold = false;
  Completer<void>? _held;

  /// Whether a reading waits for [release].
  bool get holding => _held != null && !_held!.isCompleted;

  void release() => _held?.complete();

  @override
  Future<HandwritingReading> read({
    required HandwritingModel model,
    required ReadingImage image,
    ReadingSpeed speed = ReadingSpeed.accurate,
    ReadingPolicy policy = ReadingPolicy.standard,
    void Function(ReadingProgress progress)? onProgress,
    ReadingCancel? cancel,
  }) async {
    if (!isAvailable) {
      throw const HandwritingReaderException(HandwritingFailure.unavailable);
    }
    calls.add((image: image, speed: speed));
    for (final p in progress) {
      onProgress?.call(p);
    }
    if (hold) await (_held = Completer<void>()).future;
    if (cancel?.isCancelled ?? false) {
      throw const HandwritingReaderException(HandwritingFailure.cancelled);
    }
    final answer = next;
    if (answer is HandwritingReaderException) throw answer;
    return HandwritingReading(
      text: answer as String,
      loadTime: Duration.zero,
      encodeTime: Duration.zero,
      totalTime: Duration.zero,
    );
  }
}
