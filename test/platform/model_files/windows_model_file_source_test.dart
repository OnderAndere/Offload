@TestOn('windows')
library;

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/platform/model_files/model_file_source.dart';
import 'package:offload/platform/model_files/windows_model_file_source.dart';

/// Copying a model file on Windows (T6a.3): the copy, its SHA-256 computed
/// on the way, progress, and a cancel.
void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('model_files_'));
  tearDown(() => dir.deleteSync(recursive: true));

  File source(int length) {
    final bytes = Uint8List(length);
    final random = Random(7);
    for (var i = 0; i < length; i++) {
      bytes[i] = random.nextInt(256);
    }
    return File('${dir.path}/source.gguf')..writeAsBytesSync(bytes);
  }

  test('copies the file and returns its SHA-256, with progress', () async {
    final from = source(3 * 1024 * 1024 + 17);
    final to = File('${dir.path}/target.partial');
    final progress = <int>[];
    final hash = await WindowsModelFileSource().copy(
      PickedModelFile(ref: from.path, name: 'source.gguf'),
      to,
      onProgress: progress.add,
    );
    expect(hash, sha256.convert(from.readAsBytesSync()).toString());
    expect(to.readAsBytesSync(), from.readAsBytesSync());
    expect(progress.last, from.lengthSync());
    expect(progress, orderedEquals([...progress]..sort()));
  });

  test('a cancel stops the copy', () async {
    final from = source(64 * 1024 * 1024);
    final cancel = ModelFileCancel();
    await expectLater(
      WindowsModelFileSource().copy(
        PickedModelFile(ref: from.path, name: 'source.gguf'),
        File('${dir.path}/target.partial'),
        onProgress: (_) => cancel.cancel(),
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

  test('a file that cannot be read fails as unavailable', () async {
    await expectLater(
      WindowsModelFileSource().copy(
        PickedModelFile(ref: '${dir.path}/missing.gguf', name: 'missing'),
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
