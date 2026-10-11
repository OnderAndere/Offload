/// The texts of the Windows tray icon and its menu, in the active UI
/// language (DD-009): the native runner has no translations of its own.
class TrayTexts {
  const TrayTexts({
    required this.tooltip,
    required this.newItem,
    required this.open,
    required this.quit,
  });

  final String tooltip;
  final String newItem;
  final String open;
  final String quit;
}

/// The app's presence outside its window: the Windows system tray (DD-010,
/// T1.7). A no-op on platforms without one.
abstract class DesktopShell {
  Future<void> setTrayTexts(TrayTexts texts);
}
