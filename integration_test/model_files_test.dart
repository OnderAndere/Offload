import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:offload/platform/model_files/model_file_source.dart';
import 'package:offload/platform/model_files/platform_model_file_source.dart';

/// Copying a model file with the platform's own code (T6a.3): on Android
/// through the content resolver (`ModelFileChannel.kt`, here with a file
/// address instead of a picked document), on Windows in an isolate. The
/// window itself needs a person and is checked by hand. Prints the speed.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final source = createPlatformModelFileSource();

  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('model_files_'));
  tearDown(() => dir.deleteSync(recursive: true));

  PickedModelFile offered(File file) => PickedModelFile(
    ref: Platform.isAndroid ? Uri.file(file.path).toString() : file.path,
    name: file.uri.pathSegments.last,
    size: file.lengthSync(),
  );

  File sourceFile(int length) {
    final bytes = Uint8List(length);
    final random = Random(11);
    for (var i = 0; i < length; i += 97) {
      bytes[i] = random.nextInt(256);
    }
    return File('${dir.path}/source.gguf')..writeAsBytesSync(bytes);
  }

  testWidgets('copies a file with its SHA-256 and progress', (tester) async {
    final from = sourceFile(200 * 1024 * 1024);
    final to = File('${dir.path}/target.partial');
    var last = 0;
    final watch = Stopwatch()..start();
    final hash = await source.copy(
      offered(from),
      to,
      onProgress: (copied) => last = copied,
    );
    watch.stop();
    // ignore: avoid_print
    print(
      'copied 200 MB in ${watch.elapsedMilliseconds} ms '
      '(${(200 * 1000 / watch.elapsedMilliseconds).round()} MB/s)',
    );
    expect(hash, sha256.convert(from.readAsBytesSync()).toString());
    expect(to.lengthSync(), from.lengthSync());
    expect(last, lessThanOrEqualTo(from.lengthSync()));
  });

  testWidgets('a cancel stops the copy', (tester) async {
    final from = sourceFile(200 * 1024 * 1024);
    final cancel = ModelFileCancel()..cancel();
    await expectLater(
      source.copy(
        offered(from),
        File('${dir.path}/target.partial'),
        cancel: cancel,
      ),
      throwsA(
        isA<ModelFileException>().having(
          (e) => e.failure,
          'failure',
          ModelFileFailure.cancelled,
        ),
      ),
    );
  });

  testWidgets('a missing file is unavailable', (tester) async {
    final missing = File('${dir.path}/missing.gguf');
    await expectLater(
      source.copy(
        PickedModelFile(
          ref: Platform.isAndroid
              ? Uri.file(missing.path).toString()
              : missing.path,
          name: 'missing.gguf',
        ),
        File('${dir.path}/target.partial'),
      ),
      throwsA(
        isA<ModelFileException>().having(
          (e) => e.failure,
          'failure',
          ModelFileFailure.unavailable,
        ),
      ),
    );
  });
}
