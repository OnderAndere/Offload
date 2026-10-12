import 'package:offload/platform/screen_awake/screen_awake.dart';

/// A [ScreenAwake] that remembers each request.
class FakeScreenAwake implements ScreenAwake {
  final requests = <bool>[];

  /// Whether the device is kept awake now.
  bool get isAwake => requests.isNotEmpty && requests.last;

  @override
  Future<void> keepAwake(bool on) async => requests.add(on);
}
