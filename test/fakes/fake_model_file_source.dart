import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:offload/platform/model_files/model_file_source.dart';

/// A [ModelFileSource] over files in memory: [picked] is what the window
/// answers (empty: cancelled), [contents] the bytes behind each ref. A copy
/// writes them for real and hashes them; [failNext] makes the next copy
/// fail after writing half; [onCopyStart] runs before each copy (to cancel
/// one). Throws [pickError] from the window when set.
class FakeModelFileSource implements ModelFileSource {
  List<PickedModelFile> picked = const [];
  final contents = <String, Uint8List>{};
  ModelFileFailure? failNext;
  ModelFileException? pickError;
  void Function(ModelFileCancel? cancel)? onCopyStart;

  /// When set, a copy waits for it before it reads the cancel: a test can
  /// press Stop meanwhile.
  Future<void>? gate;
  final copies = <String>[];

  /// Offers [bytes] as a file named [name]; returns it for [picked].
  PickedModelFile offer(String name, Uint8List bytes, {bool withSize = true}) {
    contents[name] = bytes;
    return PickedModelFile(
      ref: name,
      name: name,
      size: withSize ? bytes.length : null,
    );
  }

  @override
  Future<List<PickedModelFile>> pickFiles({
    required String fileTypeName,
  }) async {
    if (pickError case final error?) throw error;
    return picked;
  }

  @override
  Future<String> copy(
    PickedModelFile file,
    File target, {
    void Function(int copiedBytes)? onProgress,
    ModelFileCancel? cancel,
  }) async {
    copies.add(file.ref);
    onCopyStart?.call(cancel);
    if (gate case final wait?) await wait;
    final bytes = contents[file.ref]!;
    final failure = failNext;
    failNext = null;
    if (failure != null) {
      await target.writeAsBytes(bytes.sublist(0, bytes.length ~/ 2));
      throw ModelFileException(failure);
    }
    if (cancel?.isCancelled ?? false) {
      throw const ModelFileException(ModelFileFailure.cancelled);
    }
    await target.writeAsBytes(bytes);
    onProgress?.call(bytes.length);
    return sha256.convert(bytes).toString();
  }
}
