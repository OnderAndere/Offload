import 'dart:io';

import '../../domain/models/model_catalog.dart';
import '../../domain/models/model_import_plan.dart';
import '../../platform/model_files/model_file_source.dart';

/// Where the files of a model are on this device (T6a.3, DD-002, DD-021):
/// `<data>/models/<model id>/<file name>`, in the app's own storage, never
/// in a backup (DD-007). A model's files are public downloads, not the
/// user's data, so they are kept as they are (not encrypted, unlike
/// attachments). A file is only kept when its SHA-256 is in the
/// [modelCatalog]; it is copied to a `.partial` name first and renamed when
/// it checks out, so a half copy never counts.
class ModelStore {
  ModelStore({
    required this._dataDirectory,
    required this._source,
    required this._freeBytes,
  });

  final Future<Directory> Function() _dataDirectory;
  final ModelFileSource _source;
  final Future<int?> Function(Directory directory) _freeBytes;

  /// The folder of all models.
  Future<Directory> _root() async => Directory(
    '${(await _dataDirectory()).path}${Platform.pathSeparator}'
    '$modelsFolderName',
  );

  Future<Directory> _folder(ModelSpec spec) async =>
      Directory('${(await _root()).path}${Platform.pathSeparator}${spec.id}');

  File _file(Directory folder, String name) =>
      File('${folder.path}${Platform.pathSeparator}$name');

  /// Which files of [spec] this device has: present with the size they
  /// were imported with (checked by hash then; the size is cheap to check
  /// again).
  Future<ModelStatus> status(ModelSpec spec) async {
    final folder = await _folder(spec);
    final present = <String>{};
    for (final file in spec.files) {
      final f = _file(folder, file.name);
      try {
        if (await f.length() == file.sizeBytes) present.add(file.name);
      } on FileSystemException {
        // Not there.
      }
    }
    return ModelStatus(spec: spec, present: present);
  }

  /// The path of each file of [spec] by its role, or null unless all are
  /// there.
  Future<Map<ModelFileRole, String>?> paths(ModelSpec spec) async {
    if (!(await status(spec)).isComplete) return null;
    final folder = await _folder(spec);
    return {
      for (final file in spec.files) file.role: _file(folder, file.name).path,
    };
  }

  /// The bytes of all imported model files on this device: for Settings →
  /// *Storage* (T7.5).
  Future<int> totalBytes({List<ModelSpec> catalog = modelCatalog}) async {
    var total = 0;
    for (final spec in catalog) {
      final s = await status(spec);
      for (final file in spec.files) {
        if (s.present.contains(file.name)) total += file.sizeBytes;
      }
    }
    return total;
  }

  /// Imports [picked] into [spec] (PO 11-10-2026): files are recognised by
  /// their content; the room is checked before anything is copied; a copy
  /// that fails, is cancelled or does not check out is removed at once.
  /// Files that checked out before a failure stay. [onProgress] hears the
  /// bytes copied of all files and the total to copy.
  ///
  /// Throws [ModelImportNoRoom] before copying, or [ModelFileException]
  /// (cancelled, noSpace, unavailable) while copying.
  Future<ModelImportResult> import(
    ModelSpec spec,
    List<PickedModelFile> picked, {
    void Function(int copied, int total)? onProgress,
    ModelFileCancel? cancel,
  }) async {
    final folder = await _folder(spec);
    final before = await status(spec);
    final infos = [for (final p in picked) (name: p.name, size: p.size)];
    final plan = planModelImport(spec, infos, present: before.present);
    final total = plan.bytesToCopy(infos, spec);
    if (plan.toCopy.isNotEmpty) {
      await folder.create(recursive: true);
      final free = await _freeBytes(folder);
      if (free != null && free < plan.neededBytes) {
        throw ModelImportNoRoom(needed: plan.neededBytes, free: free);
      }
    }
    final imported = <String>[];
    final wrong = <String>[];
    final alreadyPresent = [...plan.alreadyPresent];
    var done = 0;
    for (final (n, index) in plan.toCopy.indexed) {
      final file = picked[index];
      final partial = _file(folder, 'import-$n$partialSuffix');
      final String hash;
      try {
        hash = await _source.copy(
          file,
          partial,
          onProgress: (copied) => onProgress?.call(done + copied, total),
          cancel: cancel,
        );
        // A copy that ended while the user cancelled does not count.
        if (cancel?.isCancelled ?? false) {
          throw const ModelFileException(ModelFileFailure.cancelled);
        }
      } catch (_) {
        await _delete(partial);
        rethrow;
      }
      done += file.size ?? await partial.length();
      final match = spec.fileWithHash(hash);
      if (match == null) {
        wrong.add(file.name);
        await _delete(partial);
      } else if (before.present.contains(match.name) ||
          imported.contains(match.name)) {
        alreadyPresent.add(file.name);
        await _delete(partial);
      } else {
        await partial.rename(_file(folder, match.name).path);
        imported.add(match.name);
      }
    }
    return ModelImportResult(
      imported: imported,
      alreadyPresent: alreadyPresent,
      unknown: [...plan.unknown, ...wrong],
      status: await status(spec),
    );
  }

  /// Removes the files of [spec] from this device.
  Future<void> remove(ModelSpec spec) async {
    final folder = await _folder(spec);
    if (await folder.exists()) await folder.delete(recursive: true);
  }

  /// Removes copies an import left behind when the app stopped during it
  /// (they never counted). At start, when no import runs.
  Future<void> removeLeftovers() async {
    final root = await _root();
    if (!await root.exists()) return;
    await for (final entity in root.list(recursive: true)) {
      if (entity is File && entity.path.endsWith(partialSuffix)) {
        await _delete(entity);
      }
    }
  }

  static Future<void> _delete(File file) async {
    try {
      await file.delete();
    } on FileSystemException {
      // Gone already, or a later start removes it.
    }
  }

  /// The folder of all models in the app's data directory.
  static const modelsFolderName = 'models';

  static const partialSuffix = '.partial';
}

/// The files of a model this device has.
class ModelStatus {
  const ModelStatus({required this.spec, required this.present});

  final ModelSpec spec;

  /// Names of the files that are there.
  final Set<String> present;

  bool get isComplete => spec.files.every((f) => present.contains(f.name));

  bool get isEmpty => present.isEmpty;

  /// The files still needed.
  List<ModelFileSpec> get missing => [
    for (final f in spec.files)
      if (!present.contains(f.name)) f,
  ];

  int get presentBytes => spec.files
      .where((f) => present.contains(f.name))
      .fold(0, (sum, f) => sum + f.sizeBytes);
}

/// What an import did: [imported] files checked out and are kept,
/// [alreadyPresent] were there before, [unknown] are no file of the model
/// (by size before copying, or by hash after). [status] is the model now.
class ModelImportResult {
  const ModelImportResult({
    required this.imported,
    required this.alreadyPresent,
    required this.unknown,
    required this.status,
  });

  final List<String> imported;
  final List<String> alreadyPresent;
  final List<String> unknown;
  final ModelStatus status;
}

/// Too little room for the copies (PO 11-10-2026): nothing was copied.
class ModelImportNoRoom implements Exception {
  const ModelImportNoRoom({required this.needed, required this.free});

  final int needed;
  final int free;

  @override
  String toString() => 'ModelImportNoRoom(needed $needed, free $free)';
}
