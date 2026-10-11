import 'model_catalog.dart';

/// A file the user picked to import: what the platform could tell about it.
typedef PickedFileInfo = ({String name, int? size});

/// What an import of picked files into [ModelSpec] will do, decided before
/// anything is copied (T6a.3, PO 11-10-2026): files are recognised by their
/// content, not their name. A known size that fits no missing file of the
/// model is refused at once; a file of unknown size is copied and judged by
/// its hash.
class ModelImportPlan {
  const ModelImportPlan({
    required this.toCopy,
    required this.alreadyPresent,
    required this.unknown,
    required this.neededBytes,
  });

  /// Indexes into the picked files that are copied and hashed.
  final List<int> toCopy;

  /// Picked files of the size of a file this device has already.
  final List<String> alreadyPresent;

  /// Picked files of a size no file of the model has.
  final List<String> unknown;

  /// Room needed for the copies, with [importMarginBytes].
  final int neededBytes;

  /// Bytes to copy, as far as known: for the progress bar.
  int bytesToCopy(List<PickedFileInfo> picked, ModelSpec spec) =>
      toCopy.fold(0, (sum, i) => sum + (picked[i].size ?? _largest(spec)));
}

/// Plans importing [picked] into [spec] when the files named [present] are
/// there already.
ModelImportPlan planModelImport(
  ModelSpec spec,
  List<PickedFileInfo> picked, {
  required Set<String> present,
}) {
  final toCopy = <int>[];
  final alreadyPresent = <String>[];
  final unknown = <String>[];
  final claimed = <String>{};
  var bytes = 0;
  for (var i = 0; i < picked.length; i++) {
    final file = picked[i];
    final size = file.size;
    if (size == null) {
      toCopy.add(i);
      bytes += _largest(spec);
      continue;
    }
    final matches = spec.files.where((f) => f.sizeBytes == size);
    if (matches.isEmpty) {
      unknown.add(file.name);
    } else if (matches.every((f) => present.contains(f.name))) {
      alreadyPresent.add(file.name);
    } else if (matches.every((f) => claimed.contains(f.name))) {
      // The same file picked twice: one copy is enough.
      alreadyPresent.add(file.name);
    } else {
      claimed.add(matches.firstWhere((f) => !claimed.contains(f.name)).name);
      toCopy.add(i);
      bytes += size;
    }
  }
  return ModelImportPlan(
    toCopy: toCopy,
    alreadyPresent: alreadyPresent,
    unknown: unknown,
    neededBytes: toCopy.isEmpty ? 0 : bytes + importMarginBytes,
  );
}

int _largest(ModelSpec spec) =>
    spec.files.fold(0, (max, f) => f.sizeBytes > max ? f.sizeBytes : max);
