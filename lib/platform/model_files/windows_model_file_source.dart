import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';

import 'model_file_source.dart';

/// [ModelFileSource] on Windows: the runner's Open window with several
/// files at once (`save_dialog.cpp`), network drives included. The copy
/// runs in an isolate of its own, reading, hashing and writing block by
/// block, so the app keeps drawing.
class WindowsModelFileSource implements ModelFileSource {
  static const _channel = MethodChannel('eu.marandos.offload/save_dialog');

  @override
  Future<List<PickedModelFile>> pickFiles({
    required String fileTypeName,
  }) async {
    final List<String>? paths;
    try {
      paths = await _channel.invokeListMethod<String>('pickOpenFiles', {
        'fileTypeName': fileTypeName,
        'extension': modelFileExtension,
      });
    } on PlatformException catch (e) {
      throw ModelFileException(ModelFileFailure.unavailable, e.message);
    }
    return [
      for (final path in paths ?? const <String>[])
        PickedModelFile(
          ref: path,
          name: path.split(RegExp(r'[\\/]')).last,
          size: await _sizeOf(path),
        ),
    ];
  }

  static Future<int?> _sizeOf(String path) async {
    try {
      return await File(path).length();
    } on FileSystemException {
      return null;
    }
  }

  @override
  Future<String> copy(
    PickedModelFile file,
    File target, {
    void Function(int copiedBytes)? onProgress,
    ModelFileCancel? cancel,
  }) async {
    final messages = ReceivePort();
    final done = Completer<String>();
    SendPort? control;
    Timer? watch;
    final subscription = messages.listen((message) {
      if (done.isCompleted) return;
      switch (message) {
        case final SendPort port:
          control = port;
        case final int copied:
          onProgress?.call(copied);
        case final String hash:
          done.complete(hash);
        case final ModelFileFailure failure:
          done.completeError(ModelFileException(failure));
        default:
          // An uncaught error ([error, stack]) or the isolate's exit (null)
          // before an answer.
          done.completeError(
            ModelFileException(ModelFileFailure.unavailable, '$message'),
          );
      }
    });
    try {
      await Isolate.spawn(
        copyInIsolate,
        (messages.sendPort, file.ref, target.path),
        onError: messages.sendPort,
        onExit: messages.sendPort,
        errorsAreFatal: true,
      );
      watch = Timer.periodic(const Duration(milliseconds: 100), (_) {
        if (cancel?.isCancelled ?? false) control?.send(true);
      });
      return await done.future;
    } finally {
      watch?.cancel();
      await subscription.cancel();
      messages.close();
    }
  }
}

/// Runs in the copy's isolate: reads [source] in blocks, hashes and writes
/// them to [target], and reports to [reply]: its control port first, then
/// the bytes copied after each block, then the hash or a failure. A message
/// on the control port cancels. Public for the isolate entry only.
Future<void> copyInIsolate((SendPort, String, String) job) async {
  final (reply, source, target) = job;
  final control = ReceivePort();
  var cancelled = false;
  control.listen((_) => cancelled = true);
  reply.send(control.sendPort);
  RandomAccessFile? input;
  RandomAccessFile? output;
  try {
    input = await File(source).open();
    output = await File(target).open(mode: FileMode.writeOnly);
    final digest = _DigestSink();
    final hashing = sha256.startChunkedConversion(digest);
    var copied = 0;
    while (true) {
      if (cancelled) throw const ModelFileException(ModelFileFailure.cancelled);
      final block = await input.read(_block);
      if (block.isEmpty) break;
      hashing.add(block);
      await output.writeFrom(block);
      copied += block.length;
      reply.send(copied);
    }
    await output.flush();
    hashing.close();
    reply.send(digest.value.toString());
  } on ModelFileException catch (e) {
    reply.send(e.failure);
  } on FileSystemException catch (e) {
    reply.send(
      _diskFull.contains(e.osError?.errorCode)
          ? ModelFileFailure.noSpace
          : ModelFileFailure.unavailable,
    );
  } finally {
    await input?.close();
    await output?.close();
    control.close();
  }
}

/// ERROR_HANDLE_DISK_FULL and ERROR_DISK_FULL.
const _diskFull = {39, 112};

const _block = 1 << 20;

class _DigestSink implements Sink<Digest> {
  late Digest value;

  @override
  void add(Digest data) => value = data;

  @override
  void close() {}
}
