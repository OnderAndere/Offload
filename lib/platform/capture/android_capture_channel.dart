import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../domain/items/item_enums.dart';
import 'capture_channel.dart';

/// [CaptureChannel] on the encrypted queue of the home-screen widget
/// (`CaptureQueueChannel.kt`, spike S3 variant A).
class AndroidCaptureChannel implements CaptureChannel {
  static const _channel = MethodChannel('eu.marandos.offload/capture_queue');

  @override
  Future<PendingCaptures> pending() async {
    final result = await _call(
      () => _channel.invokeMapMethod<String, Object?>('drain'),
    );
    if (result == null) throw CaptureChannelException('No answer');
    final captures = result['captures'];
    final quarantined = result['newlyQuarantined'];
    if (captures is! List || quarantined is! int) {
      throw CaptureChannelException('Unexpected answer');
    }
    return PendingCaptures([
      for (final capture in captures) _parse(capture),
    ], newlyQuarantined: quarantined);
  }

  @override
  Future<void> acknowledge(List<String> ids) =>
      _call(() => _channel.invokeMethod<void>('acknowledge', {'ids': ids}));

  @override
  Future<int> setAside(List<String> ids) async =>
      await _call<int?>(
        () => _channel.invokeMethod<int>('setAside', {'ids': ids}),
      ) ??
      0;

  /// Android has no hotkey or tray; the widget goes through the queue.
  @override
  Stream<ItemSource> get captureRequests => const Stream.empty();

  @override
  Future<void> captureRequestHandled() async {}

  @override
  Future<bool?> hotkeyRegistered() async => null;

  /// Puts a capture in the queue as the widget would. Debug builds only; the
  /// native side refuses it in a release build.
  @visibleForTesting
  Future<String> enqueueForTesting(String text, ItemSource source) async {
    final id = await _call(
      () => _channel.invokeMethod<String>('enqueueForTesting', {
        'text': text,
        'source': source.name,
      }),
    );
    if (id == null) throw CaptureChannelException('No id');
    return id;
  }

  static PendingCapture _parse(Object? capture) {
    if (capture is! Map) throw CaptureChannelException('Unexpected capture');
    final id = capture['id'];
    final text = capture['text'];
    final source = ItemSource.values.asNameMap()[capture['source']];
    if (id is! String || text is! String || source == null) {
      // Stays in the queue: nothing is acknowledged when reading fails.
      throw CaptureChannelException('Unexpected capture');
    }
    return PendingCapture(id: id, rawText: text, source: source);
  }

  static Future<T> _call<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on PlatformException catch (e) {
      throw CaptureChannelException('${e.code}: ${e.message}');
    } on MissingPluginException {
      throw CaptureChannelException('Capture channel not registered');
    }
  }
}
