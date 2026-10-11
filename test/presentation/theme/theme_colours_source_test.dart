import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Colours come from the theme, never as constants (T8.1a, DD-017): outside
/// `lib/presentation/theme/` no file names a colour instance of
/// `OffloadColors` or imports the former constants, so a dark variant (T8.1)
/// cannot be bypassed. Reads the sources, as the other static checks do.
void main() {
  test('no colour constants of the theme outside lib/presentation/theme', () {
    final theme =
        '${Platform.pathSeparator}presentation'
        '${Platform.pathSeparator}theme${Platform.pathSeparator}';
    final offenders = <String>[];
    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      if (file.path.contains(theme)) continue;
      final source = file.readAsStringSync();
      if (source.contains('design_tokens.dart') ||
          RegExp(r'OffloadColors\.[a-z]').hasMatch(source)) {
        offenders.add(file.path);
      }
    }
    expect(offenders, isEmpty, reason: 'use context.offloadColors instead');
  });

  test('the check sees a constant when there is one', () {
    expect(
      RegExp(r'OffloadColors\.[a-z]').hasMatch('OffloadColors.light.calm'),
      isTrue,
    );
    expect(
      RegExp(r'OffloadColors\.[a-z]').hasMatch('context.offloadColors.calm'),
      isFalse,
    );
  });
}
