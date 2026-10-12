/// Keeps the device awake while handwriting is read (T6a.4, DD-021, PO
/// 11/12-10-2026): on Android the screen stays on, since Android pauses an
/// app the user leaves; on Windows the PC does not go to sleep (the screen
/// may go off, reading goes on). No permission is needed for either.
abstract class ScreenAwake {
  /// Keeps the device awake when [on], lets it sleep again when not.
  Future<void> keepAwake(bool on);
}
