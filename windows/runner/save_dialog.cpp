#include "save_dialog.h"

#include <flutter/standard_method_codec.h>
#include <shobjidl.h>
#include <wrl/client.h>

#include <optional>
#include <string>

#include "utils.h"

namespace {

constexpr char kChannelName[] = "eu.marandos.offload/save_dialog";

using Microsoft::WRL::ComPtr;

// What the save window gave: a path, nothing (cancelled), or an error.
struct PickResult {
  std::optional<std::wstring> path;
  HRESULT error = S_OK;
};

// Shows the save window over [owner] with [name] proposed, for files of
// type [type_name] with [extension] (without the dot).
PickResult PickSaveFile(HWND owner, const std::wstring& name,
                        const std::wstring& type_name,
                        const std::wstring& extension) {
  ComPtr<IFileSaveDialog> dialog;
  HRESULT hr = ::CoCreateInstance(CLSID_FileSaveDialog, nullptr,
                                  CLSCTX_INPROC_SERVER, IID_PPV_ARGS(&dialog));
  if (FAILED(hr)) return {std::nullopt, hr};

  const std::wstring pattern = L"*." + extension;
  const COMDLG_FILTERSPEC filter{type_name.c_str(), pattern.c_str()};
  DWORD options = 0;
  if (FAILED(hr = dialog->SetFileTypes(1, &filter)) ||
      FAILED(hr = dialog->SetDefaultExtension(extension.c_str())) ||
      FAILED(hr = dialog->SetFileName(name.c_str())) ||
      FAILED(hr = dialog->GetOptions(&options)) ||
      FAILED(hr = dialog->SetOptions(options | FOS_OVERWRITEPROMPT |
                                     FOS_FORCEFILESYSTEM |
                                     FOS_NOREADONLYRETURN))) {
    return {std::nullopt, hr};
  }

  hr = dialog->Show(owner);
  if (hr == HRESULT_FROM_WIN32(ERROR_CANCELLED)) return {};
  if (FAILED(hr)) return {std::nullopt, hr};

  ComPtr<IShellItem> item;
  if (FAILED(hr = dialog->GetResult(&item))) return {std::nullopt, hr};
  PWSTR path = nullptr;
  if (FAILED(hr = item->GetDisplayName(SIGDN_FILESYSPATH, &path))) {
    return {std::nullopt, hr};
  }
  std::wstring result(path);
  ::CoTaskMemFree(path);
  return {result, S_OK};
}

// The filter pattern of [extensions], without dots and separated by ";":
// "jpg;png" gives "*.jpg;*.png".
std::wstring PatternOf(const std::wstring& extensions) {
  std::wstring pattern;
  size_t start = 0;
  while (start <= extensions.size()) {
    size_t end = extensions.find(L';', start);
    if (end == std::wstring::npos) end = extensions.size();
    if (end > start) {
      if (!pattern.empty()) pattern += L';';
      pattern += L"*." + extensions.substr(start, end - start);
    }
    start = end + 1;
  }
  return pattern;
}

// Shows the open window over [owner] for files of type [type_name] with
// [extensions] (without dots, separated by ";": a backup, or the pictures of
// a photo, T5.3); "all files" is offered too.
PickResult PickOpenFile(HWND owner, const std::wstring& type_name,
                        const std::wstring& extensions) {
  ComPtr<IFileOpenDialog> dialog;
  HRESULT hr = ::CoCreateInstance(CLSID_FileOpenDialog, nullptr,
                                  CLSCTX_INPROC_SERVER, IID_PPV_ARGS(&dialog));
  if (FAILED(hr)) return {std::nullopt, hr};

  const std::wstring pattern = PatternOf(extensions);
  const COMDLG_FILTERSPEC filters[] = {{type_name.c_str(), pattern.c_str()},
                                       {L"*.*", L"*.*"}};
  DWORD options = 0;
  if (FAILED(hr = dialog->SetFileTypes(2, filters)) ||
      FAILED(hr = dialog->GetOptions(&options)) ||
      FAILED(hr = dialog->SetOptions(options | FOS_FORCEFILESYSTEM |
                                     FOS_FILEMUSTEXIST |
                                     FOS_PATHMUSTEXIST))) {
    return {std::nullopt, hr};
  }

  hr = dialog->Show(owner);
  if (hr == HRESULT_FROM_WIN32(ERROR_CANCELLED)) return {};
  if (FAILED(hr)) return {std::nullopt, hr};

  ComPtr<IShellItem> item;
  if (FAILED(hr = dialog->GetResult(&item))) return {std::nullopt, hr};
  PWSTR path = nullptr;
  if (FAILED(hr = item->GetDisplayName(SIGDN_FILESYSPATH, &path))) {
    return {std::nullopt, hr};
  }
  std::wstring result(path);
  ::CoTaskMemFree(path);
  return {result, S_OK};
}

}  // namespace

SaveDialog::SaveDialog(HWND window, flutter::BinaryMessenger* messenger)
    : window_(window) {
  channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      messenger, kChannelName,
      &flutter::StandardMethodCodec::GetInstance());
  channel_->SetMethodCallHandler([this](const auto& call, auto result) {
    HandleMethodCall(call, std::move(result));
  });
}

SaveDialog::~SaveDialog() { channel_->SetMethodCallHandler(nullptr); }

void SaveDialog::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const bool open = call.method_name() == "pickOpenFile";
  if (!open && call.method_name() != "pickSaveFile") {
    result->NotImplemented();
    return;
  }
  const auto* arguments = std::get_if<flutter::EncodableMap>(call.arguments());
  if (arguments == nullptr) {
    result->Error("invalid", "Missing arguments");
    return;
  }
  const std::wstring extension = StringArgument(*arguments, "extension");
  if (extension.empty()) {
    result->Error("invalid", "Missing extension");
    return;
  }
  const PickResult picked =
      open ? PickOpenFile(window_, StringArgument(*arguments, "fileTypeName"),
                          extension)
           : PickSaveFile(window_, StringArgument(*arguments, "suggestedName"),
                          StringArgument(*arguments, "fileTypeName"),
                          extension);
  if (FAILED(picked.error)) {
    result->Error("unavailable",
                  "File window failed: " + std::to_string(picked.error));
  } else if (picked.path) {
    result->Success(flutter::EncodableValue(Utf8FromUtf16(picked.path->c_str())));
  } else {
    result->Success();
  }
}
