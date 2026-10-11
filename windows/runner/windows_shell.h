#ifndef RUNNER_WINDOWS_SHELL_H_
#define RUNNER_WINDOWS_SHELL_H_

#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <windows.h>

#include <memory>
#include <optional>
#include <string>

// Quick capture from anywhere in Windows (REQ-017, DD-010, T1.7 step B):
// - the global hotkey Win+Shift+B brings the window to the front and asks the
//   app to open its capture screen; after the capture the window goes back to
//   how it was (hidden, minimized or behind another window);
// - a system-tray icon with the menu "new item / open / quit";
// - closing the window hides it to the tray, so the hotkey keeps working;
// - reminders as balloons of the tray icon (T4.5, DD-005), over the channel
//   `eu.marandos.offload/reminders` (WindowsReminderScheduler in Dart); a
//   click opens the window and tells the app what to show.
//
// Talks to the app over the method channel `eu.marandos.offload/windows_shell`
// (WindowsCaptureChannel and WindowsDesktopShell in Dart). The menu texts come
// from the app, in its active language.
class WindowsShell {
 public:
  WindowsShell(HWND window, flutter::BinaryMessenger* messenger);
  ~WindowsShell();

  WindowsShell(const WindowsShell&) = delete;
  WindowsShell& operator=(const WindowsShell&) = delete;

  // Handles the window messages of the shell; returns a result when the
  // message was handled and must not go further.
  std::optional<LRESULT> HandleMessage(HWND window, UINT message,
                                       WPARAM wparam, LPARAM lparam);

 private:
  // How the window was before a capture request brought it to the front.
  enum class Previous { kHidden, kMinimized, kBehind, kInFront };

  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void HandleReminderCall(
      const flutter::MethodCall<flutter::EncodableValue>& call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  // Shows a reminder as a balloon of the tray icon; false without the icon.
  bool ShowReminder(const std::wstring& title, const std::wstring& text);

  void RequestCapture(const std::string& source);
  void RestoreAfterCapture();
  // Shows the window because the user asked for it (tray): it then stays
  // open after a capture that is in progress.
  void OpenByUser();
  void ShowAndActivate();
  bool MenuReady() const;
  void AddTrayIcon();
  void RemoveTrayIcon();
  void UpdateTrayTooltip();
  void ShowTrayMenu(POINT at);
  void Quit();

  HWND window_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
      reminder_channel_;

  // What a click on the balloon shown last opens: an item id, empty for
  // Today, or the weekly review. Only in memory.
  std::string reminder_open_;
  UINT taskbar_created_message_;
  bool hotkey_registered_ = false;
  bool tray_added_ = false;
  bool quitting_ = false;

  // The app listens for capture requests; until then one waits here.
  bool app_ready_ = false;
  std::optional<std::string> pending_source_;

  // When the hotkey came in; the capture waits until its keys are released.
  ULONGLONG hotkey_pressed_at_ = 0;

  // The window has been shown at least once (after the first frame).
  bool ever_shown_ = false;

  // A capture request is open in the app.
  bool capture_active_ = false;
  Previous previous_ = Previous::kInFront;
  HWND previous_foreground_ = nullptr;

  // Texts from the app; no menu until they arrive.
  std::wstring tooltip_;
  std::wstring new_item_text_;
  std::wstring open_text_;
  std::wstring quit_text_;
};

#endif  // RUNNER_WINDOWS_SHELL_H_
