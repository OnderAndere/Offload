import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:offload/domain/app/bundled_licenses.dart';
import 'package:offload/presentation/about/bundled_licenses.dart';
import 'package:offload/presentation/theme/design_tokens.dart';

/// The licences Flutter does not collect itself (T8.10, REQ-062). These
/// tests keep *About Offload* current: a native library or a typeface that
/// ships without a registered licence fails here (PO request 03-10-2026).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  bool covered(String file) => bundledLicenses.any(
    (l) =>
        l.covers.any((c) => c.endsWith('/') ? file.startsWith(c) : c == file),
  );

  test('every allowed native library has a licence', () {
    final libs = [
      for (final line in File('tool/allowed_native_libs.txt').readAsLinesSync())
        if (line.trim().isNotEmpty && !line.trim().startsWith('#')) line.trim(),
    ];
    expect(libs, isNotEmpty);
    for (final lib in libs) {
      expect(
        flutterNativeFiles.contains(lib) || covered(lib),
        isTrue,
        reason: '$lib ships without a licence in bundledLicenses',
      );
    }
  });

  test('every bundled typeface has a licence', () {
    final fonts = Directory('assets/fonts')
        .listSync()
        .whereType<File>()
        .map((f) => 'assets/fonts/${f.uri.pathSegments.last}')
        .where((p) => p.endsWith('.ttf') || p.endsWith('.otf'));
    expect(fonts, isNotEmpty);
    for (final font in fonts) {
      expect(covered(font), isTrue, reason: '$font has no licence');
    }
    expect(bundledLicenses.first.packages, [sansFamily, monoFamily]);
  });

  test('the Material icons have a licence: the font and the widget icons', () {
    // Flutter ships its icon font without listing its licence (06-10-2026).
    expect(covered('MaterialIcons-Regular.otf'), isTrue);
    for (final icon in [
      'ic_bar_today',
      'ic_bar_insights',
      'ic_shortcut_today',
      'ic_shortcut_insights',
    ]) {
      expect(
        File('android/app/src/main/res/drawable/$icon.xml').existsSync(),
        isTrue,
      );
      expect(covered('res/drawable/$icon.xml'), isTrue, reason: icon);
    }
  });

  test('every licence text is bundled as an asset', () {
    final pubspec = File('pubspec.yaml').readAsLinesSync().map((l) => l.trim());
    for (final asset in [
      ...bundledLicenses.map((l) => l.asset),
      appLicenseAsset,
    ]) {
      expect(File(asset).existsSync(), isTrue, reason: asset);
      final folder = asset.substring(0, asset.lastIndexOf('/') + 1);
      expect(
        pubspec.contains('- $asset') ||
            (folder.isNotEmpty && pubspec.contains('- $folder')),
        isTrue,
        reason: '$asset is not in the pubspec assets',
      );
    }
  });

  test('the entries hold the real texts', () async {
    final entries = await bundledLicenseEntries().toList();
    String textOf(String package) => entries
        .firstWhere((e) => e.packages.contains(package))
        .paragraphs
        .map((p) => p.text)
        .join('\n');
    expect(textOf(sansFamily), contains('SIL Open Font License, Version 1.1'));
    expect(textOf(sansFamily), contains('IBM Corp.'));
    final sqlite3mc = entries
        .where((e) => e.packages.contains('SQLite3MultipleCiphers'))
        .expand((e) => e.paragraphs.map((p) => p.text))
        .join(' ');
    expect(sqlite3mc, contains('Ulrich Telle'));
    expect(sqlite3mc, contains('Olivier Gay'));
    expect(sqlite3mc, contains('ISC License'));
    expect(sqlite3mc, contains('AEGIS'));
    expect(textOf('sqlite'), contains('public domain'));
    // Code by others inside the Dart packages (review T5.2).
    expect(
      entries
          .where((e) => e.packages.contains('image'))
          .expand((e) => e.paragraphs.map((p) => p.text))
          .join(' '),
      contains('jpgjs'),
    );
    expect(textOf('archive'), contains('Bouncy Castle'));
  });

  test('the licence of Offload is GPL 3.0', () {
    final text = File(appLicenseAsset).readAsStringSync();
    expect(text, contains('GNU GENERAL PUBLIC LICENSE'));
    expect(text, contains('Version 3, 29 June 2007'));
  });
}
