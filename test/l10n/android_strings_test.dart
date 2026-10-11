import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/gen_android_strings.dart';

/// The native capture window and the widget show texts from the ARB files
/// (DD-009), through generated Android resources.
void main() {
  test('the Android string resources are up to date with the ARB files', () {
    final expected = androidStringFiles();

    for (final MapEntry(key: path, value: content) in expected.entries) {
      final file = File(path);
      // Line endings may differ after a checkout (core.autocrlf).
      expect(
        file.existsSync() &&
            file.readAsStringSync().replaceAll('\r\n', '\n') == content,
        isTrue,
        reason:
            '$path is out of date: run dart run tool/gen_android_strings.dart',
      );
    }
  });

  test('English is the fallback and Dutch has its own folder (AC REQ-029)', () {
    final paths = androidStringFiles().keys;

    expect(paths, contains('android/app/src/main/res/values/strings.xml'));
    expect(paths, contains('android/app/src/main/res/values-nl/strings.xml'));
  });

  test('special characters are escaped for Android', () {
    final english =
        androidStringFiles()['android/app/src/main/res/values/strings.xml']!;

    // "What's on your mind?" needs its apostrophe escaped.
    expect(english, contains(r"What\'s on your mind?"));
  });
}
