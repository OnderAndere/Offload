#include "single_instance.h"

#include <windows.h>

#include "win32_window.h"

namespace {

// "Local\" scopes the guard to the user's session.
constexpr const wchar_t kMutexName[] =
    L"Local\\eu.marandos.offload.single-instance";

// Brings the main window of the running instance to the front. Does nothing
// when that window does not exist yet (the first instance is still starting).
void ActivateRunningInstance() {
  HWND existing = ::FindWindowW(kOffloadWindowClassName, nullptr);
  if (existing == nullptr) {
    return;
  }
  if (::IsIconic(existing)) {
    ::ShowWindow(existing, SW_RESTORE);
  } else {
    ::ShowWindow(existing, SW_SHOW);
  }
  // Allowed: this process was just started by the user, so it owns the
  // foreground and may hand it over.
  ::SetForegroundWindow(existing);
}

}  // namespace

SingleInstance::~SingleInstance() {
  if (mutex_ != nullptr) {
    ::CloseHandle(static_cast<HANDLE>(mutex_));
  }
}

SingleInstance::Result SingleInstance::Acquire() {
  HANDLE mutex = ::CreateMutexW(nullptr, FALSE, kMutexName);
  const DWORD error = ::GetLastError();
  if (mutex == nullptr) {
    if (error == ERROR_ACCESS_DENIED) {
      // The mutex exists but belongs to a process we may not open: another
      // instance is running.
      ActivateRunningInstance();
      return Result::kAlreadyRunning;
    }
    return Result::kFailed;
  }
  if (error == ERROR_ALREADY_EXISTS) {
    ::CloseHandle(mutex);
    ActivateRunningInstance();
    return Result::kAlreadyRunning;
  }
  mutex_ = mutex;
  return Result::kAcquired;
}
