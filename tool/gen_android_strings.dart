// Generates the Android string resources of the native capture window and the
// widget from the ARB files (DD-009): one source for every text.
//
// Usage: dart run tool/gen_android_strings.dart
//
// `values/strings.xml` comes from app_en.arb, because Android falls back to it
// when the system language is not offered, and English is the fallback
// language of the app (AC REQ-029). Every other ARB file becomes
// `values-<language>/strings.xml`. `test/l10n/android_strings_test.dart` fails
// when the files on disk are out of date.
import 'dart:convert';
import 'dart:io';

/// ARB key -> Android resource name, for the texts native code shows.
const androidStringKeys = {
  'captureHint': 'capture_hint',
  'captureSave': 'capture_save',
  'captureSaveFailed': 'capture_failed',
  'captureAction': 'widget_button',
  'androidWidgetDescription': 'widget_description',
  'androidWidgetHint': 'widget_hint',
  // The Offload bar and the app shortcuts (REQ-063, T1.11).
  'androidBarName': 'bar_name',
  'androidBarDescription': 'bar_description',
  'navToday': 'bar_today',
  'navInsights': 'bar_insights',
  'androidOpenToday': 'open_today',
  'androidOpenInsights': 'open_insights',
};

const _fallbackLanguage = 'en';
const _resDir = 'android/app/src/main/res';

/// The generated files, as path (relative to the project root) -> content.
Map<String, String> androidStringFiles({String l10nDir = 'lib/l10n'}) {
  final files = <String, String>{};
  final arbs =
      Directory(l10nDir)
          .listSync()
          .whereType<File>()
          .where((f) => RegExp(r'app_\w+\.arb$').hasMatch(f.path))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  for (final arb in arbs) {
    final messages = jsonDecode(arb.readAsStringSync()) as Map<String, Object?>;
    final language = messages['@@locale']! as String;
    final folder = language == _fallbackLanguage
        ? 'values'
        : 'values-$language';
    files['$_resDir/$folder/strings.xml'] = _resourceFile(messages, arb.path);
  }
  return files;
}

String _resourceFile(Map<String, Object?> messages, String source) {
  final out = StringBuffer()
    ..writeln('<?xml version="1.0" encoding="utf-8"?>')
    ..writeln(
      '<!-- Generated from lib/l10n/${source.split(RegExp(r'[\\/]')).last} '
      'by tool/gen_android_strings.dart. Do not edit. -->',
    )
    ..writeln('<resources>');
  for (final MapEntry(key: arbKey, value: name) in androidStringKeys.entries) {
    final text = messages[arbKey];
    if (text is! String) {
      throw StateError('$source has no text for $arbKey');
    }
    if (text.contains('{')) {
      throw StateError('$arbKey has placeholders; Android strings cannot');
    }
    out.writeln('    <string name="$name">${_escape(text)}</string>');
  }
  out.writeln('</resources>');
  return out.toString();
}

/// Escapes [text] for an Android string resource.
String _escape(String text) {
  var escaped = text
      .replaceAll(r'\', r'\\')
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll("'", r"\'")
      .replaceAll('"', r'\"')
      .replaceAll('\n', r'\n');
  if (escaped.startsWith('@') || escaped.startsWith('?')) {
    escaped = '\\$escaped';
  }
  return escaped;
}

void main() {
  for (final MapEntry(key: path, value: content)
      in androidStringFiles().entries) {
    final file = File(path);
    file.parent.createSync(recursive: true);
    // No BOM, LF line endings.
    file.writeAsStringSync(content);
    stdout.writeln('wrote $path');
  }
}
