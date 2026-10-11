import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/l10n/app_localizations.dart';

/// Guards the ARB files (DD-009): every language has every text, and adding a
/// language is only an extra ARB file (it then shows up in Settings through
/// AppLocalizations.supportedLocales).
void main() {
  const template = 'app_nl.arb';
  final arbFiles =
      Directory('lib/l10n')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.arb'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  Map<String, Object?> read(File f) =>
      jsonDecode(f.readAsStringSync()) as Map<String, Object?>;

  Set<String> messageKeys(Map<String, Object?> arb) =>
      arb.keys.where((k) => !k.startsWith('@')).toSet();

  String fileName(File f) => f.uri.pathSegments.last;

  test('there is a template and at least one translation', () {
    expect(arbFiles.map(fileName), containsAll([template, 'app_en.arb']));
  });

  test('every ARB file has exactly the keys of the template', () {
    final expected = messageKeys(
      read(arbFiles.singleWhere((f) => fileName(f) == template)),
    );
    for (final file in arbFiles) {
      expect(messageKeys(read(file)), expected, reason: fileName(file));
    }
  });

  test('the locale of each ARB file matches its file name', () {
    for (final file in arbFiles) {
      final code = RegExp(r'^app_(\w+)\.arb$').firstMatch(fileName(file))![1];
      expect(read(file)['@@locale'], code, reason: fileName(file));
    }
  });

  test('every ARB file is a supported locale', () {
    expect(
      AppLocalizations.supportedLocales.map((l) => l.languageCode).toSet(),
      arbFiles.map((f) => read(f)['@@locale']).toSet(),
    );
  });

  test('each language is named in its own language, uniquely', () {
    final names = [
      for (final l in AppLocalizations.supportedLocales)
        lookupAppLocalizations(Locale(l.languageCode)).languageName,
    ];
    expect(names.toSet(), hasLength(names.length));
    expect(names, containsAll(['Nederlands', 'English']));
  });

  test('no translation is empty', () {
    for (final file in arbFiles) {
      final arb = read(file);
      for (final key in messageKeys(arb)) {
        expect(
          (arb[key]! as String).trim(),
          isNotEmpty,
          reason: '${fileName(file)}: $key',
        );
      }
    }
  });
}
