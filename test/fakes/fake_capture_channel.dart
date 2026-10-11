import 'dart:async';

import 'package:offload/domain/ids/uuid_v7.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/platform/capture/capture_channel.dart';

/// In-memory [CaptureChannel] with the same contract as the Android queue:
/// [pending] never removes, only [acknowledge] does.
class FakeCaptureChannel implements CaptureChannel {
  final _queue = <String, PendingCapture>{};
  final _ids = UuidV7Generator();

  /// Unreadable captures to report once at the next [pending].
  int quarantineNext = 0;

  /// Makes [pending] fail, as an unreadable queue would.
  bool failPending = false;

  /// Makes [acknowledge] fail, after nothing was removed.
  bool failAcknowledge = false;

  final acknowledged = <String>[];

  /// Captures moved to quarantine by [setAside].
  final setAsideIds = <String>[];

  final _requests = StreamController<ItemSource>.broadcast();

  /// What [hotkeyRegistered] answers; null as on a platform without one.
  bool? hotkeyRegisteredValue;

  /// How often the app reported a requested capture screen as closed.
  int requestsHandled = 0;

  /// Asks the app to open its capture screen, as the Windows hotkey or tray
  /// menu does.
  void requestCapture(ItemSource source) => _requests.add(source);

  /// Captures still waiting.
  List<PendingCapture> get waiting => _queue.values.toList();

  /// Adds a capture as the widget would and returns its id.
  String add(String text, {ItemSource source = ItemSource.widget}) {
    final id = _ids.next();
    _queue[id] = PendingCapture(id: id, rawText: text, source: source);
    return id;
  }

  @override
  Future<PendingCaptures> pending() async {
    if (failPending) throw CaptureChannelException('failing on purpose');
    final quarantined = quarantineNext;
    quarantineNext = 0;
    final captures = _queue.values.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    return PendingCaptures(captures, newlyQuarantined: quarantined);
  }

  @override
  Future<void> acknowledge(List<String> ids) async {
    if (failAcknowledge) throw CaptureChannelException('failing on purpose');
    acknowledged.addAll(ids);
    ids.forEach(_queue.remove);
  }

  @override
  Future<int> setAside(List<String> ids) async {
    final moved = ids.where(_queue.containsKey).toList();
    setAsideIds.addAll(moved);
    moved.forEach(_queue.remove);
    return moved.length;
  }

  @override
  Stream<ItemSource> get captureRequests => _requests.stream;

  @override
  Future<void> captureRequestHandled() async => requestsHandled++;

  @override
  Future<bool?> hotkeyRegistered() async => hotkeyRegisteredValue;
}
