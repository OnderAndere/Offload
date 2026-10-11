import '../tokens/inline_token.dart';
import '../tokens/inline_token_registry.dart';

/// What a list row shows of an item's text (DD-018 point 2): the first
/// non-empty line without its prefix tokens, and how many non-empty lines
/// follow. Computed from the text, never stored (hard rule 6).
typedef ItemHeadline = ({String title, int moreLines});

final _lineBreak = RegExp(r'\r\n|\r|\n');
final _spaces = RegExp(r'\s+');

/// Everything of [rawText] after the line [itemHeadline] takes as the
/// title, trimmed: the rest of a shared mail on a triage card (DD-018 point
/// 3). Empty for a text of one line.
String textAfterFirstLine(String rawText) {
  final lines = rawText.split(_lineBreak);
  final first = lines.indexWhere((l) => l.trim().isNotEmpty);
  if (first < 0) return '';
  return lines.sublist(first + 1).join('\n').trim();
}

/// The headline of [rawText]. The line is parsed live with [registry], not
/// from the stored tokens, so the title does not change when processing
/// finishes. Only prefix tokens (`@Jan`, `#renovatie`, `!vr`) are left out; a
/// link `[[…]]` reads as its text without brackets (DD-004 point 13); a
/// pattern token, an escaped `\@` and anything unrecognised stay (DD-004).
/// A line of only tokens is shown as typed, never as an empty title.
ItemHeadline itemHeadline(
  String rawText,
  InlineTokenRegistry registry,
  ParseContext context,
) {
  final lines = [
    for (final line in rawText.split(_lineBreak))
      if (line.trim().isNotEmpty) line.trim(),
  ];
  if (lines.isEmpty) return (title: '', moreLines: 0);
  final first = lines.first;
  final buffer = StringBuffer();
  var at = 0;
  for (final match in registry.parse(first, context)) {
    final trigger = match.type.trigger;
    if (trigger is PatternTrigger) continue;
    buffer.write(first.substring(at, match.start));
    if (trigger is EnclosedTrigger) buffer.write(match.word.trim());
    at = match.end;
  }
  buffer.write(first.substring(at));
  final title = buffer.toString().replaceAll(_spaces, ' ').trim();
  return (title: title.isEmpty ? first : title, moreLines: lines.length - 1);
}
