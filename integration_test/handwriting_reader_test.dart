import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';
import 'package:offload/platform/handwriting/handwriting_reader.dart';
import 'package:offload/platform/handwriting/platform_handwriting_reader.dart';

/// The handwriting reader inside the app (T6a.2, DD-021): the library that
/// the app's own build made (Android arm64-v8a and x86_64, Windows), loaded
/// by the platform's reader. Reads a printed line when the model is there,
/// else only checks that the library loads. The model is never in the
/// repository: pass its folder with
/// `--dart-define=OFFLOAD_VISION_MODEL_DIR=<folder>`; on Android it must be
/// a folder the app may read, such as its own
/// `/sdcard/Android/data/eu.marandos.offload/files/…` (adb push).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const modelDir = String.fromEnvironment('OFFLOAD_VISION_MODEL_DIR');
  final reader = createPlatformHandwritingReader();

  testWidgets('the app ships its handwriting library', (tester) async {
    expect(reader.isAvailable, isTrue);
  });

  testWidgets(
    'reads a printed line with the model',
    (tester) async {
      final model = _modelIn(modelDir)!;
      final phases = <ReadingPhase>[];
      final reading = await reader.read(
        model: model,
        image: _line('- @Anna bellen !vr #thuis'),
        onProgress: (p) {
          if (phases.isEmpty || phases.last != p.phase) phases.add(p.phase);
        },
      );
      // ignore: avoid_print
      print(
        'read "${reading.text}" in ${reading.totalTime.inMilliseconds} ms '
        '(load ${reading.loadTime.inMilliseconds}, '
        'encode ${reading.encodeTime.inMilliseconds})',
      );
      expect(reading.text, contains('@Anna'));
      expect(phases, [
        ReadingPhase.loading,
        ReadingPhase.encoding,
        ReadingPhase.writing,
      ]);
    },
    skip: modelDir.isEmpty || _modelIn(modelDir) == null,
    timeout: const Timeout(Duration(minutes: 10)),
  );
}

HandwritingModel? _modelIn(String dir) {
  if (dir.isEmpty || !Directory(dir).existsSync()) return null;
  final files = Directory(dir).listSync().whereType<File>().map((f) => f.path);
  bool projector(String p) =>
      p.split(RegExp(r'[\\/]')).last.startsWith('mmproj-');
  final projectors = files.where((p) => p.endsWith('.gguf') && projector(p));
  final models = files.where((p) => p.endsWith('.gguf') && !projector(p));
  if (projectors.length != 1 || models.length != 1) return null;
  return HandwritingModel(
    languageModelPath: models.single,
    projectorPath: projectors.single,
  );
}

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
