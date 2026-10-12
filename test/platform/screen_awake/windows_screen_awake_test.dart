import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:offload/platform/screen_awake/windows_screen_awake.dart';

/// Keeping the PC awake while reading (T6a.4, DD-021): the real call into
/// Windows, on and off again.
void main() {
  test(
    'Windows takes the request and lets go of it again',
    () async {
      final awake = WindowsScreenAwake();
      await awake.keepAwake(true);
      await awake.keepAwake(false);
    },
    skip: Platform.isWindows ? null : 'Windows only',
  );
}
