import 'package:flutter/services.dart';

import 'desktop_shell.dart';

/// Method channel of the Windows runner's shell (`windows_shell.cpp`):
/// hotkey, tray and capture requests.
const windowsShellChannel = MethodChannel('eu.marandos.offload/windows_shell');

/// [DesktopShell] on the tray icon of the Windows runner.
class WindowsDesktopShell implements DesktopShell {
  @override
  Future<void> setTrayTexts(TrayTexts texts) async {
    try {
      await windowsShellChannel.invokeMethod<void>('setTrayTexts', {
        'tooltip': texts.tooltip,
        'newItem': texts.newItem,
        'open': texts.open,
        'quit': texts.quit,
      });
    } on MissingPluginException {
      // No runner channel (tests): nothing to label.
    }
  }
}

/// [DesktopShell] where there is no tray.
class NoDesktopShell implements DesktopShell {
  @override
  Future<void> setTrayTexts(TrayTexts texts) async {}
}
