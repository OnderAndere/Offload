#ifndef RUNNER_SAVE_DIALOG_H_
#define RUNNER_SAVE_DIALOG_H_

#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <windows.h>

#include <memory>

// "Save as…" and "Open" (REQ-043, DD-014; backups T7.2, DD-007; a photo for
// an item, T5.3; the files of a model, T6a.3): the Windows save and open
// windows, owned by the app window, on the method channel
// `eu.marandos.offload/save_dialog` (WindowsShareChannel,
// WindowsBackupFilePicker, WindowsPhotoSource and WindowsModelFileSource in
// Dart). They only pick the path; the app reads or writes the file itself.
// Shown from the platform thread, like any modal window, so the app keeps
// drawing meanwhile.
class SaveDialog {
 public:
  SaveDialog(HWND window, flutter::BinaryMessenger* messenger);
  ~SaveDialog();

  SaveDialog(const SaveDialog&) = delete;
  SaveDialog& operator=(const SaveDialog&) = delete;

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  HWND window_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
};

#endif  // RUNNER_SAVE_DIALOG_H_
