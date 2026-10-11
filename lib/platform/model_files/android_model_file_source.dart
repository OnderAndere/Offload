import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

import 'model_file_source.dart';

/// [ModelFileSource] on Android: the system document picker with several
/// files at once (`ModelFileChannel.kt`), no storage permission. The copy
/// streams the document straight into the target and hashes it on the way,
/// on a thread of its own; progress is asked for now and then.
class AndroidModelFileSource implements ModelFileSource {
  AndroidModelFileSource({
    this.pollInterval = const Duration(milliseconds: 250),
  });

  static const _channel = MethodChannel('eu.marandos.offload/model_files');

  /// How often progress and [ModelFileCancel] are looked at while copying.
  final Duration pollInterval;

  static int _nextJob = 0;

  @override
  Future<List<PickedModelFile>> pickFiles({
    required String fileTypeName,
  }) async {
    final List<Object?>? picked;
    try {
      picked = await _channel.invokeListMethod<Object?>('pickFiles');
    } on PlatformException catch (e) {
      throw ModelFileException(ModelFileFailure.unavailable, e.message);
    }
    return [
      for (final entry in picked ?? const <Object?>[])
        if (entry case {
          'uri': final String uri,
          'name': final String name,
          'size': final int? size,
        })
          PickedModelFile(ref: uri, name: name, size: size),
    ];
  }

  @override
  Future<String> copy(
    PickedModelFile file,
    File target, {
    void Function(int copiedBytes)? onProgress,
    ModelFileCancel? cancel,
  }) async {
    final job = _nextJob++;
    final copying = _channel.invokeMethod<String>('copy', {
      'job': job,
      'uri': file.ref,
      'target': target.path,
    });
    var asking = false;
    final timer = Timer.periodic(pollInterval, (_) async {
      if (asking) return;
      asking = true;
      try {
        if (cancel?.isCancelled ?? false) {
          await _channel.invokeMethod<void>('cancel', {'job': job});
        }
        final copied = await _channel.invokeMethod<int>('progress', {
          'job': job,
        });
        if (copied != null) onProgress?.call(copied);
      } on PlatformException {
        // Progress is a nicety; the copy itself reports its failure.
      } finally {
        asking = false;
      }
    });
    try {
      final hash = await copying;
      if (hash == null) {
        throw const ModelFileException(ModelFileFailure.unavailable);
      }
      return hash;
    } on PlatformException catch (e) {
      throw ModelFileException(switch (e.code) {
        'cancelled' => ModelFileFailure.cancelled,
        'noSpace' => ModelFileFailure.noSpace,
        _ => ModelFileFailure.unavailable,
      }, e.message);
    } finally {
      timer.cancel();
    }
  }
}
