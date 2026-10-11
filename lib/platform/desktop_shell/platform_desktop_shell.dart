import 'dart:io';

import 'desktop_shell.dart';
import 'windows_desktop_shell.dart';

/// The [DesktopShell] for the platform the app runs on.
DesktopShell createPlatformDesktopShell() {
  if (Platform.isWindows) return WindowsDesktopShell();
  if (Platform.isAndroid) return NoDesktopShell();
  throw UnsupportedError('Offload runs on Android and Windows only');
}
