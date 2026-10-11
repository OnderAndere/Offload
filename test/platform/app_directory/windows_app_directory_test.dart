@TestOn('windows')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:offload/platform/app_directory/windows_app_directory.dart';

void main() {
  test('the data directory is eu.marandos.offload under LOCALAPPDATA', () {
    final base = Platform.environment['LOCALAPPDATA']!;

    expect(
      WindowsAppDirectory.defaultDirectory().path,
      [base, 'eu.marandos.offload'].join(Platform.pathSeparator),
    );
  });
}
