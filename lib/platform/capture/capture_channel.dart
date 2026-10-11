import '../../domain/items/item_enums.dart';

/// A capture made outside the app, for example in the Android widget, that
/// waits in the platform's queue until the app has stored it (DD-010).
class PendingCapture {
  const PendingCapture({
    required this.id,
    required this.rawText,
    required this.source,
  });

  /// Version 7 UUID from the moment of capture.
  final String id;

  /// Text exactly as typed.
  final String rawText;
  final ItemSource source;
}

/// What the platform queue holds right now.
class PendingCaptures {
  const PendingCaptures(this.captures, {this.newlyQuarantined = 0});

  static const none = PendingCaptures([]);

  /// Oldest first.
  final List<PendingCapture> captures;

  /// Captures that could not be read this time and were set aside,
  /// never deleted (AC REQ-001).
  final int newlyQuarantined;
}

/// Capture channels outside the app (DD-010).
///
/// Lossless hand-off (AC REQ-001): [pending] never removes anything; the app
/// stores the captures first and only then calls [acknowledge]. If the app
/// stops in between, the captures come back, under the same ids.
abstract class CaptureChannel {
  /// The captures waiting outside the app. Throws [CaptureChannelException]
  /// when the queue cannot be read.
  Future<PendingCaptures> pending();

  /// Removes the captures [ids]; only for captures the app has stored.
  Future<void> acknowledge(List<String> ids);

  /// Sets the captures [ids] aside (quarantine): readable, but refused by
  /// the app. Kept, never deleted, so they cannot block later captures.
  /// Returns how many were set aside.
  Future<int> setAside(List<String> ids);

  /// Requests from outside the app window to open the capture screen, with
  /// the source to record: the Windows hotkey and the tray menu (REQ-017).
  /// Never emits on platforms without them.
  Stream<ItemSource> get captureRequests;

  /// The capture screen opened for a request has closed; the platform puts
  /// back what was in front before (PO decision 27-09-2026).
  Future<void> captureRequestHandled();

  /// Whether the global capture hotkey could be registered; null on
  /// platforms without one.
  Future<bool?> hotkeyRegistered();
}

class CaptureChannelException implements Exception {
  CaptureChannelException(this.message);

  final String message;

  @override
  String toString() => 'CaptureChannelException: $message';
}
