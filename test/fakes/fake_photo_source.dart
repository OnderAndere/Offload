import 'dart:async';
import 'dart:typed_data';

import 'package:offload/platform/photo_source/photo_source.dart';

/// A [PhotoSource] that answers with [next]: the bytes of a picture, null
/// (cancelled), or a [PhotoSourceException] to throw. [hold] keeps the answer
/// back until [release], to look at the screen meanwhile.
class FakePhotoSource implements PhotoSource {
  FakePhotoSource({this.canTakePhoto = true});

  @override
  final bool canTakePhoto;

  Object? next;
  bool hold = false;
  final calls = <String>[];
  Completer<void>? _held;

  void release() => _held?.complete();

  @override
  Future<Uint8List?> takePhoto() => _answer('take');

  @override
  Future<Uint8List?> pickPhoto({required String fileTypeName}) =>
      _answer('pick');

  Future<Uint8List?> _answer(String call) async {
    calls.add(call);
    if (hold) await (_held = Completer<void>()).future;
    final answer = next;
    if (answer is PhotoSourceException) throw answer;
    return answer as Uint8List?;
  }
}
