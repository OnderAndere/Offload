import 'package:offload/domain/handwriting/reading_policy.dart';
import 'package:offload/platform/handwriting/handwriting_reader.dart';

/// A [HandwritingReader] that answers with [next]: the text read, or a
/// [HandwritingReaderException] to throw. [progress] is reported first; a
/// [ReadingCancel] cancelled by then ends the reading as cancelled.
class FakeHandwritingReader implements HandwritingReader {
  FakeHandwritingReader({this.isAvailable = true});

  @override
  final bool isAvailable;

  Object next = '';
  List<ReadingProgress> progress = const [];
  final calls = <({ReadingImage image, ReadingSpeed speed})>[];

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
