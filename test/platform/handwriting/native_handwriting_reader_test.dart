import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:offload/platform/handwriting/handwriting_reader.dart';
import 'package:offload/platform/handwriting/native_handwriting_reader.dart';

/// The native handwriting reader (T6a.2, DD-021). Without the library only
/// the absent case runs; with it (OFFLOAD_LLAMA_LIBRARY, the path of a
/// built `offload_llama.dll`) also the failures; with the model too
/// (OFFLOAD_VISION_MODEL_DIR, a folder with the two `.gguf` files of
/// Qwen3-VL-2B) a real reading and a cancel. The model is never in the
/// repository (DD-021).
void main() {
  final library = Platform.environment['OFFLOAD_LLAMA_LIBRARY'];
  final modelDir = Platform.environment['OFFLOAD_VISION_MODEL_DIR'];
  final model = modelDir == null ? null : _modelIn(modelDir);
  final noLibrary = library == null
      ? 'set OFFLOAD_LLAMA_LIBRARY to a built offload_llama library'
      : null;
  final noModel =
      noLibrary ??
      (model == null
          ? 'set OFFLOAD_VISION_MODEL_DIR to the folder with the model'
          : null);

  NativeHandwritingReader reader() =>
      NativeHandwritingReader(libraryName: library!, threads: 4);

  test('without its library the reader is unavailable', () async {
    final absent = NativeHandwritingReader(
      libraryName: 'no_such_offload_llama.dll',
      threads: 1,
    );
    expect(absent.isAvailable, isFalse);
    await expectLater(
      absent.read(model: _missingModel, image: _line('x')),
      throwsA(_failure(HandwritingFailure.unavailable)),
    );
  });

  test('pixels that do not match the size are refused', () async {
    final image = ReadingImage(width: 10, height: 10, rgb: Uint8List(299));
    await expectLater(
      reader().read(model: _missingModel, image: image),
      throwsA(_failure(HandwritingFailure.badImage)),
    );
  }, skip: noLibrary);

  test('a missing model file is unreadable', () async {
    await expectLater(
      reader().read(model: _missingModel, image: _line('x')),
      throwsA(_failure(HandwritingFailure.modelUnreadable)),
    );
  }, skip: noLibrary);

  test(
    'reads a line of text, through all phases in order',
    () async {
      final phases = <ReadingPhase>[];
      final reading = await reader().read(
        model: model!,
        image: _line('- @Anna bellen !vr #thuis'),
        onProgress: (p) {
          if (phases.isEmpty || phases.last != p.phase) phases.add(p.phase);
        },
      );
      expect(reading.text, contains('@Anna'));
      expect(reading.text, contains('#thuis'));
      expect(phases, [
        ReadingPhase.loading,
        ReadingPhase.encoding,
        ReadingPhase.writing,
      ]);
      expect(reading.totalTime, greaterThan(reading.encodeTime));
    },
    skip: noModel,
    timeout: const Timeout(Duration(minutes: 5)),
  );

  test(
    'a cancel while the model looks at the image ends the reading soon',
    () async {
      final cancel = ReadingCancel();
      final watch = Stopwatch();
      final reading = reader().read(
        model: model!,
        image: _line('- @Anna bellen !vr #thuis'),
        onProgress: (p) {
          if (p.phase == ReadingPhase.encoding && !cancel.isCancelled) {
            cancel.cancel();
            watch.start();
          }
        },
        cancel: cancel,
      );
      await expectLater(
        reading,
        throwsA(_failure(HandwritingFailure.cancelled)),
      );
      expect(watch.elapsed, lessThan(const Duration(seconds: 5)));
    },
    skip: noModel,
    timeout: const Timeout(Duration(minutes: 5)),
  );
}

const _missingModel = HandwritingModel(
  languageModelPath: 'no_such_model.gguf',
  projectorPath: 'no_such_mmproj.gguf',
);

HandwritingModel? _modelIn(String dir) {
  final files = Directory(dir).listSync().whereType<File>().map((f) => f.path);
  final projector = files.where((p) => _name(p).startsWith('mmproj-'));
  final language = files.where(
    (p) => p.endsWith('.gguf') && !_name(p).startsWith('mmproj-'),
  );
  if (projector.length != 1 || language.length != 1) return null;
  return HandwritingModel(
    languageModelPath: language.single,
    projectorPath: projector.single,
  );
}

String _name(String path) => path.split(RegExp(r'[\\/]')).last;

/// One line of printed text, black on white: fictional sample data.
ReadingImage _line(String text) {
  final image = img.Image(width: 900, height: 160);
  img.fill(image, color: img.ColorRgb8(255, 255, 255));
  img.drawString(
    image,
    text,
    font: img.arial48,
    x: 30,
    y: 50,
    color: img.ColorRgb8(0, 0, 0),
  );
  return ReadingImage(
    width: image.width,
    height: image.height,
    rgb: image.getBytes(order: img.ChannelOrder.rgb),
  );
}

Matcher _failure(HandwritingFailure failure) =>
    isA<HandwritingReaderException>().having(
      (e) => e.failure,
      'failure',
      failure,
    );
