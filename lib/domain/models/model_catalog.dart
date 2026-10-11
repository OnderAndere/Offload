/// The models Offload can use and the exact files they consist of (T6a.3,
/// DD-002, DD-021). A model is never downloaded by the app: the user imports
/// its files, and the app accepts a file only when its SHA-256 is in this
/// list. The speech model joins with T6.1.
library;

/// What a model is for.
enum ModelKind {
  /// Reading handwriting from a photo (REQ-064, DD-021).
  handwriting,
}

/// The part a file plays in its model.
enum ModelFileRole {
  /// The language model itself.
  languageModel,

  /// The image projector (`mmproj`) of a vision model.
  projector,
}

/// One file of a model, as published.
class ModelFileSpec {
  const ModelFileSpec({
    required this.name,
    required this.role,
    required this.sizeBytes,
    required this.sha256,
  });

  /// The file name as published; also the name the app stores it under.
  final String name;
  final ModelFileRole role;
  final int sizeBytes;

  /// Lowercase hex.
  final String sha256;
}

class ModelSpec {
  const ModelSpec({
    required this.id,
    required this.kind,
    required this.name,
    required this.source,
    required this.licence,
    required this.files,
  });

  /// Stable and file-system safe: the folder the files are kept in.
  final String id;
  final ModelKind kind;

  /// The model's own name, as its makers publish it (not translated).
  final String name;

  /// Where the files are published, with the exact version.
  final String source;

  /// The licence's short name (SPDX).
  final String licence;
  final List<ModelFileSpec> files;

  int get sizeBytes => files.fold(0, (sum, f) => sum + f.sizeBytes);

  /// The file of this model with [hash], or null.
  ModelFileSpec? fileWithHash(String hash) {
    final lower = hash.toLowerCase();
    for (final file in files) {
      if (file.sha256 == lower) return file;
    }
    return null;
  }
}

/// Qwen3-VL-2B-Instruct, the handwriting model chosen in spike S6
/// (DD-021): the same files on Android and Windows.
const handwritingModel = ModelSpec(
  id: 'qwen3-vl-2b-instruct',
  kind: ModelKind.handwriting,
  name: 'Qwen3-VL-2B-Instruct',
  source: 'Hugging Face, Qwen/Qwen3-VL-2B-Instruct-GGUF @ 52d6c8f',
  licence: 'Apache-2.0',
  files: [
    ModelFileSpec(
      name: 'Qwen3VL-2B-Instruct-Q4_K_M.gguf',
      role: ModelFileRole.languageModel,
      sizeBytes: 1107409952,
      sha256:
          '089d75c52f4b7ffc56ba998ffc50aae89fcafc755f9e7208aacca281dca6c2ae',
    ),
    ModelFileSpec(
      name: 'mmproj-Qwen3VL-2B-Instruct-Q8_0.gguf',
      role: ModelFileRole.projector,
      sizeBytes: 445053216,
      sha256:
          'f9a68fabba69c3b81e153367b2c7521030b0fa8bb0de400c9599c8e6725f9c82',
    ),
  ],
);

/// Every model the app knows.
const modelCatalog = [handwritingModel];

/// Room kept free on top of the files while importing (PO 11-10-2026).
const importMarginBytes = 200 * 1000 * 1000;
