import 'dart:async';

import 'package:flutter/services.dart';

import '../../domain/items/item_enums.dart';
import '../desktop_shell/windows_desktop_shell.dart';
import 'capture_channel.dart';

/// [CaptureChannel] on Windows: the hotkey Win+Shift+B and the tray menu
/// of the runner (`windows/runner/windows_shell.cpp`) ask the running app to
/// open its capture screen. Captures there go straight into the app, so
/// nothing ever waits outside it.
class WindowsCaptureChannel implements CaptureChannel {
  WindowsCaptureChannel() {
    _controller = StreamController<ItemSource>.broadcast(onListen: _connect);
  }

  late final StreamController<ItemSource> _controller;
  bool _connected = false;

  static const _channel = windowsShellChannel;

  @override
  Future<PendingCaptures> pending() async => PendingCaptures.none;

  @override
  Future<void> acknowledge(List<String> ids) async {}

  @override
  Future<int> setAside(List<String> ids) async => 0;

  @override
  Stream<ItemSource> get captureRequests => _controller.stream;

  /// Starts listening to the runner and takes over a request that came in
  /// while the app was still starting.
  Future<void> _connect() async {
    if (_connected) return;
    _connected = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'captureRequested') _emit(call.arguments);
    });
    try {
      _emit(await _channel.invokeMethod<String>('ready'));
    } on MissingPluginException {
      // No runner channel (tests): no requests.
    } on PlatformException {
      // The runner could not answer: later requests still arrive.
    }
  }

  void _emit(Object? source) {
    final parsed = ItemSource.values.asNameMap()[source];
    if (parsed != null) _controller.add(parsed);
  }

  @override
  Future<void> captureRequestHandled() =>
      _call(() => _channel.invokeMethod<void>('captureHandled'));

  @override
  Future<bool?> hotkeyRegistered() =>
      _call(() => _channel.invokeMethod<bool>('hotkeyStatus'));

  static Future<T?> _call<T>(Future<T?> Function() call) async {
    try {
      return await call();
    } on PlatformException catch (e) {
      throw CaptureChannelException('${e.code}: ${e.message}');
    } on MissingPluginException {
      return null;
    }
  }
}
