/// The clean-up of a reading before the inline parser (DD-021): the model's
/// consistent habits, measured in spike S6, and nothing else (AC REQ-064 a).
library;

/// [text] as the model wrote it, cleaned up:
/// - a token sign followed by spaces joins the next word (`@ Harry` →
///   `@Harry`), but only a sign that starts a word, as a token does;
/// - `×` becomes `*`;
/// - a line with only `-` goes (a thought marker with nothing after it);
/// - spaces at line ends and blank lines at the start and end go.
///
/// Line breaks stay: they carry the thoughts of the `-` convention (AC
/// REQ-064 b).
String cleanUpReading(String text) {
  final joined = text
      .replaceAll('×', '*')
      .replaceAllMapped(_signThenSpaces, (m) => m.group(1)!);
  final lines = joined
      .split(_lineBreak)
      .map((line) => line.trimRight())
      .where((line) => line.trim() != '-')
      .toList();
  while (lines.isNotEmpty && lines.first.trim().isEmpty) {
    lines.removeAt(0);
  }
  while (lines.isNotEmpty && lines.last.trim().isEmpty) {
    lines.removeLast();
  }
  return lines.join('\n');
}

final _lineBreak = RegExp(r'\r\n|\r|\n');

/// A token sign at the start of a word, then spaces before the next word.
/// Only `' '`: a sign at a line end stays on its line.
final _signThenSpaces = RegExp(r'(?<=^|\s)([@#!^*]) +(?=\S)');
