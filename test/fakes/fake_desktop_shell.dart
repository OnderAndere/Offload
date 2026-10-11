import 'package:offload/platform/desktop_shell/desktop_shell.dart';

/// Records the tray texts the app hands to the platform.
class FakeDesktopShell implements DesktopShell {
  final sent = <TrayTexts>[];

  @override
  Future<void> setTrayTexts(TrayTexts texts) async => sent.add(texts);
}
