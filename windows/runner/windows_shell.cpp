#include "windows_shell.h"

#include <flutter/standard_method_codec.h>
#include <shellapi.h>
#include <windowsx.h>

#include "resource.h"
#include "utils.h"

namespace {

constexpr char kChannelName[] = "eu.marandos.offload/windows_shell";
constexpr char kReminderChannelName[] = "eu.marandos.offload/reminders";
constexpr int kHotkeyId = 1;
constexpr UINT kTrayIconId = 1;
constexpr UINT kTrayMessage = WM_APP + 1;
constexpr UINT_PTR kMenuNewItem = 1;
constexpr UINT_PTR kMenuOpen = 2;
constexpr UINT_PTR kMenuQuit = 3;
constexpr UINT_PTR kReleaseTimerId = 1;
constexpr UINT kReleasePollMs = 15;
constexpr ULONGLONG kReleaseTimeoutMs = 1000;

// The modifier keys of the hotkey and the ones a text field cares about.
constexpr int kModifierKeys[] = {
    VK_SHIFT, VK_LSHIFT, VK_RSHIFT, VK_CONTROL, VK_LCONTROL, VK_RCONTROL,
    VK_MENU,  VK_LMENU,  VK_RMENU,  VK_LWIN,    VK_RWIN,
};

bool AnyModifierDown() {
  for (const int key : kModifierKeys) {
    if (::GetAsyncKeyState(key) & 0x8000) return true;
  }
  return false;
}

// Flutter reads modifier keys with GetKeyState, the state this thread last
// saw. The hotkey arrives with Win and Shift down, but their release goes to
// the window that was in front, so this thread would keep them pressed and
// Enter would arrive as Win+Enter. Copy the real state into this thread.
void SyncModifierKeyState() {
  BYTE state[256];
  if (!::GetKeyboardState(state)) return;
  for (const int key : kModifierKeys) {
    if (::GetAsyncKeyState(key) & 0x8000) {
      state[key] |= 0x80;
    } else {
      state[key] &= static_cast<BYTE>(~0x80);
    }
  }
  ::SetKeyboardState(state);
}

// The app name; not translated.
constexpr wchar_t kAppName[] = L"Offload";

}  // namespace

WindowsShell::WindowsShell(HWND window, flutter::BinaryMessenger* messenger)
    : window_(window),
      taskbar_created_message_(::RegisterWindowMessageW(L"TaskbarCreated")) {
  channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      messenger, kChannelName,
      &flutter::StandardMethodCodec::GetInstance());
  channel_->SetMethodCallHandler([this](const auto& call, auto result) {
    HandleMethodCall(call, std::move(result));
  });
  reminder_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          messenger, kReminderChannelName,
          &flutter::StandardMethodCodec::GetInstance());
  reminder_channel_->SetMethodCallHandler(
      [this](const auto& call, auto result) {
        HandleReminderCall(call, std::move(result));
      });
  // Fails when another program already owns the combination; the app shows
  // that (never silently).
  hotkey_registered_ = ::RegisterHotKey(window_, kHotkeyId,
                                        MOD_WIN | MOD_SHIFT | MOD_NOREPEAT,
                                        'B') != FALSE;
  AddTrayIcon();
}

WindowsShell::~WindowsShell() {
  if (hotkey_registered_) ::UnregisterHotKey(window_, kHotkeyId);
  RemoveTrayIcon();
  channel_->SetMethodCallHandler(nullptr);
  reminder_channel_->SetMethodCallHandler(nullptr);
}

std::optional<LRESULT> WindowsShell::HandleMessage(HWND window, UINT message,
                                                   WPARAM wparam,
                                                   LPARAM lparam) {
  if (message == taskbar_created_message_) {
    // Explorer restarted: the tray icon is gone and must be added again.
    tray_added_ = false;
    AddTrayIcon();
    return 0;
  }
  switch (message) {
    case WM_SHOWWINDOW:
      if (wparam) ever_shown_ = true;
      return std::nullopt;
    case WM_CLOSE:
      // Closing hides the window to the tray, so the hotkey keeps working.
      // Only when the tray offers a way back and a way out: without the icon
      // or before the app sent the menu texts (still starting, or a start-up
      // error) it really closes.
      if (!quitting_ && tray_added_ && MenuReady()) {
        ::ShowWindow(window_, SW_HIDE);
        return 0;
      }
      return std::nullopt;
    case WM_HOTKEY:
      if (wparam == kHotkeyId) {
        // Wait until Win and Shift are released before taking the focus;
        // see SyncModifierKeyState.
        hotkey_pressed_at_ = ::GetTickCount64();
        ::SetTimer(window_, kReleaseTimerId, kReleasePollMs, nullptr);
        return 0;
      }
      return std::nullopt;
    case WM_TIMER:
      if (wparam == kReleaseTimerId) {
        if (AnyModifierDown() &&
            ::GetTickCount64() - hotkey_pressed_at_ < kReleaseTimeoutMs) {
          return 0;
        }
        ::KillTimer(window_, kReleaseTimerId);
        SyncModifierKeyState();
        RequestCapture("hotkey");
        return 0;
      }
      return std::nullopt;
    case kTrayMessage:
      switch (LOWORD(lparam)) {
        case NIN_SELECT:
        case NIN_KEYSELECT:
          OpenByUser();
          return 0;
        case WM_CONTEXTMENU:
          ShowTrayMenu(POINT{GET_X_LPARAM(wparam), GET_Y_LPARAM(wparam)});
          return 0;
        case NIN_BALLOONUSERCLICK:
          // A click on a reminder: the window, then what it is about.
          OpenByUser();
          reminder_channel_->InvokeMethod(
              "opened",
              std::make_unique<flutter::EncodableValue>(reminder_open_));
          return 0;
      }
      return 0;
  }
  return std::nullopt;
}

void WindowsShell::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const std::string& method = call.method_name();
  if (method == "ready") {
    // The app now listens; hand over a request that came in before.
    app_ready_ = true;
    if (pending_source_) {
      result->Success(flutter::EncodableValue(*pending_source_));
      pending_source_.reset();
    } else {
      result->Success();
    }
  } else if (method == "hotkeyStatus") {
    result->Success(flutter::EncodableValue(hotkey_registered_));
  } else if (method == "captureHandled") {
    RestoreAfterCapture();
    result->Success();
  } else if (method == "setTrayTexts") {
    const auto* arguments =
        std::get_if<flutter::EncodableMap>(call.arguments());
    if (arguments == nullptr) {
      result->Error("invalid", "Missing texts");
      return;
    }
    tooltip_ = StringArgument(*arguments, "tooltip");
    new_item_text_ = StringArgument(*arguments, "newItem");
    open_text_ = StringArgument(*arguments, "open");
    quit_text_ = StringArgument(*arguments, "quit");
    UpdateTrayTooltip();
    result->Success();
  } else {
    result->NotImplemented();
  }
}

void WindowsShell::HandleReminderCall(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const std::string& method = call.method_name();
  if (method == "show") {
    const auto* arguments =
        std::get_if<flutter::EncodableMap>(call.arguments());
    if (arguments == nullptr) {
      result->Error("invalid", "Missing reminder");
      return;
    }
    const auto open = arguments->find(flutter::EncodableValue("open"));
    const std::string* open_text =
        open == arguments->end() ? nullptr
                                 : std::get_if<std::string>(&open->second);
    if (!ShowReminder(StringArgument(*arguments, "title"),
                      StringArgument(*arguments, "text"))) {
      result->Error("unavailable", "No tray icon");
      return;
    }
    reminder_open_ = open_text == nullptr ? std::string() : *open_text;
    result->Success();
  } else if (method == "openSettings") {
    // Windows' notification settings, where the user can switch them off.
    ::ShellExecuteW(nullptr, L"open", L"ms-settings:notifications", nullptr,
                    nullptr, SW_SHOWNORMAL);
    result->Success();
  } else {
    result->NotImplemented();
  }
}

bool WindowsShell::ShowReminder(const std::wstring& title,
                                const std::wstring& text) {
  if (!tray_added_) return false;
  NOTIFYICONDATAW data = {};
  data.cbSize = sizeof(data);
  data.hWnd = window_;
  data.uID = kTrayIconId;
  data.uFlags = NIF_INFO;
  // Windows cuts the title at 63 and the text at 255 characters.
  wcsncpy_s(data.szInfoTitle, title.c_str(), _TRUNCATE);
  // An empty text would remove the balloon instead of showing one.
  wcsncpy_s(data.szInfo, text.empty() ? L" " : text.c_str(), _TRUNCATE);
  data.dwInfoFlags = NIIF_USER | NIIF_LARGE_ICON;
  data.hBalloonIcon = static_cast<HICON>(::LoadImageW(
      ::GetModuleHandleW(nullptr), MAKEINTRESOURCEW(IDI_APP_ICON), IMAGE_ICON,
      ::GetSystemMetrics(SM_CXICON), ::GetSystemMetrics(SM_CYICON),
      LR_SHARED));
  return ::Shell_NotifyIconW(NIM_MODIFY, &data) != FALSE;
}

void WindowsShell::RequestCapture(const std::string& source) {
  if (!capture_active_) {
    // Remember how the window was, to put it back after the capture. A
    // window that was never shown (the app is still starting) stays open.
    if (!ever_shown_) {
      previous_ = Previous::kInFront;
    } else if (!::IsWindowVisible(window_)) {
      previous_ = Previous::kHidden;
    } else if (::IsIconic(window_)) {
      previous_ = Previous::kMinimized;
    } else if (::GetForegroundWindow() != window_) {
      previous_ = Previous::kBehind;
      previous_foreground_ = ::GetForegroundWindow();
    } else {
      previous_ = Previous::kInFront;
    }
    capture_active_ = true;
  }
  // Before the first frame this can show an empty window for a moment;
  // accepted, the capture screen follows as soon as the app listens.
  ShowAndActivate();
  // The app answers every request with captureHandled. Should it ever stop
  // listening in the middle (it only rebuilds after a start-up error), the
  // window is not put back and later requests do not record a new state;
  // no text is lost.
  if (app_ready_) {
    channel_->InvokeMethod("captureRequested",
                           std::make_unique<flutter::EncodableValue>(source));
  } else {
    pending_source_ = source;
  }
}

void WindowsShell::RestoreAfterCapture() {
  if (!capture_active_) return;
  capture_active_ = false;
  switch (previous_) {
    case Previous::kHidden:
      ::ShowWindow(window_, SW_HIDE);
      break;
    case Previous::kMinimized:
      ::ShowWindow(window_, SW_MINIMIZE);
      break;
    case Previous::kBehind:
      // Allowed: this window is in front, so it may hand the focus back.
      if (previous_foreground_ != nullptr &&
          ::IsWindow(previous_foreground_)) {
        ::SetForegroundWindow(previous_foreground_);
      }
      break;
    case Previous::kInFront:
      break;
  }
  previous_foreground_ = nullptr;
}

void WindowsShell::OpenByUser() {
  // Opened on purpose: do not hide or minimize it after a capture.
  previous_ = Previous::kInFront;
  ShowAndActivate();
}

bool WindowsShell::MenuReady() const {
  return !new_item_text_.empty() && !open_text_.empty() && !quit_text_.empty();
}

void WindowsShell::ShowAndActivate() {
  if (::IsIconic(window_)) {
    ::ShowWindow(window_, SW_RESTORE);
  } else {
    ::ShowWindow(window_, SW_SHOW);
  }
  ::SetForegroundWindow(window_);
}

void WindowsShell::AddTrayIcon() {
  if (tray_added_) return;
  NOTIFYICONDATAW data = {};
  data.cbSize = sizeof(data);
  data.hWnd = window_;
  data.uID = kTrayIconId;
  data.uFlags = NIF_ICON | NIF_MESSAGE | NIF_TIP | NIF_SHOWTIP;
  data.uCallbackMessage = kTrayMessage;
  // The small icon size, so the tray does not scale down the large one.
  data.hIcon = static_cast<HICON>(::LoadImageW(
      ::GetModuleHandleW(nullptr), MAKEINTRESOURCEW(IDI_APP_ICON), IMAGE_ICON,
      ::GetSystemMetrics(SM_CXSMICON), ::GetSystemMetrics(SM_CYSMICON),
      LR_SHARED));
  const std::wstring& tip = tooltip_.empty() ? std::wstring(kAppName) : tooltip_;
  wcsncpy_s(data.szTip, tip.c_str(), _TRUNCATE);
  if (!::Shell_NotifyIconW(NIM_ADD, &data)) return;
  // Version 4: keyboard selection and the context-menu key work as well.
  data.uVersion = NOTIFYICON_VERSION_4;
  ::Shell_NotifyIconW(NIM_SETVERSION, &data);
  tray_added_ = true;
}

void WindowsShell::RemoveTrayIcon() {
  if (!tray_added_) return;
  NOTIFYICONDATAW data = {};
  data.cbSize = sizeof(data);
  data.hWnd = window_;
  data.uID = kTrayIconId;
  ::Shell_NotifyIconW(NIM_DELETE, &data);
  tray_added_ = false;
}

void WindowsShell::UpdateTrayTooltip() {
  if (!tray_added_ || tooltip_.empty()) return;
  NOTIFYICONDATAW data = {};
  data.cbSize = sizeof(data);
  data.hWnd = window_;
  data.uID = kTrayIconId;
  data.uFlags = NIF_TIP | NIF_SHOWTIP;
  wcsncpy_s(data.szTip, tooltip_.c_str(), _TRUNCATE);
  ::Shell_NotifyIconW(NIM_MODIFY, &data);
}

void WindowsShell::ShowTrayMenu(POINT at) {
  // The texts come from the app; before they arrive there is no menu.
  if (!MenuReady()) return;
  HMENU menu = ::CreatePopupMenu();
  if (menu == nullptr) return;
  ::AppendMenuW(menu, MF_STRING, kMenuNewItem, new_item_text_.c_str());
  ::AppendMenuW(menu, MF_STRING, kMenuOpen, open_text_.c_str());
  ::AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
  ::AppendMenuW(menu, MF_STRING, kMenuQuit, quit_text_.c_str());
  // Needed so the menu closes when the user clicks elsewhere.
  ::SetForegroundWindow(window_);
  const UINT command = static_cast<UINT>(::TrackPopupMenu(
      menu, TPM_RETURNCMD | TPM_RIGHTBUTTON | TPM_NONOTIFY, at.x, at.y, 0,
      window_, nullptr));
  ::DestroyMenu(menu);
  ::PostMessageW(window_, WM_NULL, 0, 0);
  switch (command) {
    case kMenuNewItem:
      RequestCapture("tray");
      break;
    case kMenuOpen:
      OpenByUser();
      break;
    case kMenuQuit:
      Quit();
      break;
  }
}

void WindowsShell::Quit() {
  quitting_ = true;
  ::PostMessageW(window_, WM_CLOSE, 0, 0);
}
