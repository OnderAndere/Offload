import 'package:flutter_test/flutter_test.dart';
import 'package:offload/domain/models/model_catalog.dart';
import 'package:offload/domain/models/model_import_plan.dart';

/// Planning an import before anything is copied (T6a.3, PO 11-10-2026).
void main() {
  const spec = ModelSpec(
    id: 'test',
    kind: ModelKind.handwriting,
    name: 'Test',
    source: 'here',
    licence: 'MIT',
    files: [
      ModelFileSpec(
        name: 'model.gguf',
        role: ModelFileRole.languageModel,
        sizeBytes: 1000,
        sha256: 'aa',
      ),
      ModelFileSpec(
        name: 'mmproj.gguf',
        role: ModelFileRole.projector,
        sizeBytes: 400,
        sha256: 'bb',
      ),
    ],
  );

  test('both files, whatever their names, are copied', () {
    final plan = planModelImport(spec, [
      (name: 'a.gguf', size: 400),
      (name: 'b.bin', size: 1000),
    ], present: {});
    expect(plan.toCopy, [0, 1]);
    expect(plan.neededBytes, 1400 + importMarginBytes);
    expect(plan.unknown, isEmpty);
  });

  test('a size of no file of the model is refused before copying', () {
    final plan = planModelImport(spec, [
      (name: 'photo.jpg', size: 12345),
      (name: 'model.gguf', size: 1000),
    ], present: {});
    expect(plan.unknown, ['photo.jpg']);
    expect(plan.toCopy, [1]);
  });

  test('a file this device has already is not copied again', () {
    final plan = planModelImport(
      spec,
      [(name: 'model.gguf', size: 1000)],
      present: {'model.gguf'},
    );
    expect(plan.toCopy, isEmpty);
    expect(plan.alreadyPresent, ['model.gguf']);
    expect(plan.neededBytes, 0);
  });

  test('the same file picked twice is copied once', () {
    final plan = planModelImport(spec, [
      (name: 'model.gguf', size: 1000),
      (name: 'model (1).gguf', size: 1000),
    ], present: {});
    expect(plan.toCopy, [0]);
    expect(plan.alreadyPresent, ['model (1).gguf']);
  });

  test('a file of unknown size is copied, counted as the largest', () {
    final plan = planModelImport(spec, [(name: 'x', size: null)], present: {});
    expect(plan.toCopy, [0]);
    expect(plan.neededBytes, 1000 + importMarginBytes);
    expect(plan.bytesToCopy([(name: 'x', size: null)], spec), 1000);
  });

  test('the catalogue knows the handwriting model by its hashes', () {
    expect(handwritingModel.files, hasLength(2));
    expect(handwritingModel.sizeBytes, 1552463168);
    for (final file in handwritingModel.files) {
      expect(handwritingModel.fileWithHash(file.sha256.toUpperCase()), file);
      expect(file.sha256, matches(RegExp(r'^[0-9a-f]{64}$')));
    }
    expect(handwritingModel.fileWithHash('00'), isNull);
  });
}
