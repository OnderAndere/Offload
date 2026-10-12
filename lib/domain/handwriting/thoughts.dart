/// The thoughts in a reading (AC REQ-064 b, DD-021; PO 12-10-2026): one
/// written line is one thought when it starts with `-`.
library;

/// The thoughts in [text], a reading after `cleanUpReading`, in order:
/// - a line that starts with `-` starts a thought, without the `-` and the
///   spaces after it;
/// - a line without `-` joins the thought before it with a space (a
///   thought written over two lines);
/// - text before the first `-` line is a thought of its own (a heading,
///   say), to keep or skip;
/// - blank lines and thoughts with nothing in them go.
List<String> splitThoughts(String text) {
  final thoughts = <String>[];
  StringBuffer? current;
  void close() {
    final thought = current?.toString().trim() ?? '';
    if (thought.isNotEmpty) thoughts.add(thought);
    current = null;
  }

  for (final raw in text.split(_lineBreak)) {
    final line = raw.trim();
    if (line.isEmpty) continue;
    if (line.startsWith('-')) {
      close();
      current = StringBuffer(line.substring(1).trimLeft());
    } else if (current case final buffer?) {
      if (buffer.isNotEmpty) buffer.write(' ');
      buffer.write(line);
    } else {
      current = StringBuffer(line);
    }
  }
  close();
  return thoughts;
}

final _lineBreak = RegExp(r'\r\n|\r|\n');
