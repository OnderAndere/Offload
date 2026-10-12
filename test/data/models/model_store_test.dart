import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/models/model_store.dart';
import 'package:offload/domain/models/model_catalog.dart';
import 'package:offload/platform/model_files/model_file_source.dart';

import '../../fakes/fake_model_file_source.dart';

/// Importing, checking and removing a model's files (T6a.3, DD-002,
/// PO 11-10-2026), with a small model made up for the test.
void main() {
  final language = Uint8List.fromList(List.generate(1000, (i) => i % 251));
  final projector = Uint8List.fromList(List.generate(400, (i) => i % 7));
  final spec = ModelSpec(
    id: 'test-model',
    kind: ModelKind.handwriting,
    name: 'Test',
    source: 'here',
    licence: 'MIT',
    files: [
      ModelFileSpec(
        name: 'model.gguf',
        role: ModelFileRole.languageModel,
        sizeBytes: language.length,
        sha256: sha256.convert(language).toString(),
      ),
      ModelFileSpec(
        name: 'mmproj.gguf',
        role: ModelFileRole.projector,
        sizeBytes: projector.length,
        sha256: sha256.convert(projector).toString(),
      ),
    ],
  );

  late Directory dir;
  late FakeModelFileSource source;
  int? free;
  late ModelStore store;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('model_store_');
    source = FakeModelFileSource();
    free = null;
    store = ModelStore(
      dataDirectory: () async => dir,
      source: source,
      freeBytes: (_) async => free,
    );
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Directory folder() => Directory('${dir.path}/models/test-model');
  List<String> filesIn(Directory d) => d.existsSync()
      ? (d.listSync().map((e) => e.uri.pathSegments.last).toList()..sort())
      : [];

  test('both files in one pick, renamed by the user, make the model', () async {
    final result = await store.import(spec, [
      source.offer('Downloaded A.bin', projector),
      source.offer('Downloaded B.bin', language),
    ]);
    expect(result.imported, unorderedEquals(['model.gguf', 'mmproj.gguf']));
    expect(result.status.isComplete, isTrue);
    expect(filesIn(folder()), ['mmproj.gguf', 'model.gguf']);
    final paths = await store.paths(spec);
    expect(paths![ModelFileRole.projector], endsWith('mmproj.gguf'));
    expect(await store.totalBytes(catalog: [spec]), 1400);
  });

  test('one file: the model is incomplete and names what is missing', () async {
    final result = await store.import(spec, [
      source.offer('model.gguf', language),
    ]);
    expect(result.status.isComplete, isFalse);
    expect(result.status.missing.single.name, 'mmproj.gguf');
    expect(await store.paths(spec), isNull);
  });

  test('a file of the right size but other content is refused', () async {
    final damaged = Uint8List.fromList(language)..[10] ^= 1;
    final result = await store.import(spec, [
      source.offer('model.gguf', damaged),
    ]);
    expect(result.imported, isEmpty);
    expect(result.unknown, ['model.gguf']);
    expect(filesIn(folder()), isEmpty);
  });

  test('a file of another size is refused without copying', () async {
    final result = await store.import(spec, [
      source.offer('photo.jpg', Uint8List(77)),
    ]);
    expect(result.unknown, ['photo.jpg']);
    expect(source.copies, isEmpty);
  });

  test('a file of unknown size is judged by its hash', () async {
    final result = await store.import(spec, [
      source.offer('nas file', projector, withSize: false),
    ]);
    expect(result.imported, ['mmproj.gguf']);
  });

  test('too little room: nothing is copied', () async {
    free = 1400 + importMarginBytes - 1;
    await expectLater(
      store.import(spec, [
        source.offer('a', language),
        source.offer('b', projector),
      ]),
      throwsA(
        isA<ModelImportNoRoom>()
            .having((e) => e.needed, 'needed', 1400 + importMarginBytes)
            .having((e) => e.free, 'free', 1400 + importMarginBytes - 1),
      ),
    );
    expect(source.copies, isEmpty);
  });

  test('a full drive: the half copy goes, the good file stays', () async {
    final first = source.offer('a', projector);
    final second = source.offer('b', language);
    source.onCopyStart = (_) {
      if (source.copies.length == 2) source.failNext = ModelFileFailure.noSpace;
    };
    await expectLater(
      store.import(spec, [first, second]),
      throwsA(_failure(ModelFileFailure.noSpace)),
    );
    expect(filesIn(folder()), ['mmproj.gguf']);
  });

  test('a copy that ended after a cancel is not kept', () async {
    final cancel = _CancelledAfterCopy();
    await expectLater(
      store.import(spec, [source.offer('a', language)], cancel: cancel),
      throwsA(_failure(ModelFileFailure.cancelled)),
    );
    expect(filesIn(folder()), isEmpty);
  });

  test('a file already there is not copied again', () async {
    await store.import(spec, [source.offer('a', language)]);
    source.copies.clear();
    final result = await store.import(spec, [source.offer('b', language)]);
    expect(result.alreadyPresent, ['b']);
    expect(source.copies, isEmpty);
  });

  test('a file that changed size no longer counts', () async {
    await store.import(spec, [source.offer('a', language)]);
    File('${folder().path}/model.gguf').writeAsBytesSync([1, 2, 3]);
    expect((await store.status(spec)).present, isEmpty);
  });

  test('remove deletes the files of the model', () async {
    await store.import(spec, [
      source.offer('a', language),
      source.offer('b', projector),
    ]);
    await store.remove(spec);
    expect(folder().existsSync(), isFalse);
    expect((await store.status(spec)).isEmpty, isTrue);
  });

  test('a file still open cannot be removed: that is said, the rest of '
      'the model is gone', () async {
    await store.import(spec, [
      source.offer('a', language),
      source.offer('b', projector),
    ]);
    final open = File('${folder().path}/model.gguf').openSync();
    addTearDown(open.closeSync);
    await expectLater(store.remove(spec), throwsA(isA<ModelRemoveFailed>()));
    expect(filesIn(folder()), ['model.gguf']);
  }, skip: Platform.isWindows ? null : 'only Windows keeps an open file');

  test('leftover half copies are removed at start', () async {
    folder().createSync(recursive: true);
    File('${folder().path}/import-0.partial').writeAsBytesSync([1]);
    File('${folder().path}/model.gguf').writeAsBytesSync(language);
    await store.removeLeftovers();
    expect(filesIn(folder()), ['model.gguf']);
  });
}

Matcher _failure(ModelFileFailure failure) =>
    isA<ModelFileException>().having((e) => e.failure, 'failure', failure);

/// A cancel the copy did not see in time: the copy finishes, and only then
/// is it cancelled (review T6a.3 step A).
class _CancelledAfterCopy extends ModelFileCancel {
  var _asked = 0;

  @override
  bool get isCancelled => _asked++ > 0;
}
