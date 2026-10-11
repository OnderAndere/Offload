import '../time/local_date.dart';
import '../tokens/inline_token.dart';
import '../tokens/inline_token_registry.dart';
import '../tokens/token_types.dart';

/// Turns an item's raw text into plain text for someone else (REQ-043,
/// DD-014): the tokens become ordinary words, because the recipient does not
/// know the inline syntax.
///
/// - `@Jan` becomes "Jan", as typed (PO decision 30-09-2026; the full name
///   of the linked person may follow after some use);
/// - `!vr` becomes the date written out by [formatDate];
/// - `#renovatie` is left out, unless tags are included;
/// - an escaped `\@Jan` becomes "@Jan";
/// - anything else stays as typed, pattern tokens included.
///
/// Pure: the result is only a proposal the user edits before it goes out;
/// the item itself never changes.
class ItemShareRenderer {
  const ItemShareRenderer({required this.registry, required this.formatDate});

  final InlineTokenRegistry registry;

  /// A date written out in the UI language.
  final String Function(LocalDate date) formatDate;

  static final _horizontalSpace = RegExp(r'[ \t]');

  /// The shareable text of [rawText]. A date word takes its date from
  /// [knownDates] (by word, as the token processor stored it, so an old
  /// `!morgen` keeps its date), otherwise from [context]. [includeTags]
  /// keeps the tags as typed.
  String render(
    String rawText, {
    required ParseContext context,
    Map<String, LocalDate> knownDates = const {},
    bool includeTags = false,
  }) {
    final edits = <_Edit>[
      for (final match in registry.parse(rawText, context))
        if (match.type.trigger is! PatternTrigger)
          if (_replacement(match, knownDates, includeTags) case final text?)
            (
              start: match.start,
              end: match.end,
              text: text,
              leftOut: text.isEmpty,
            ),
      ..._escapes(rawText),
    ]..sort((a, b) => a.start.compareTo(b.start));

    final buffer = StringBuffer();
    var at = 0;
    for (final edit in edits) {
      var start = edit.start;
      var end = edit.end;
      if (edit.leftOut) {
        // A word left out takes one run of spaces with it, so no double or
        // trailing space remains: the one after it, or else the one before.
        if (end < rawText.length && _isSpace(rawText[end])) {
          while (end < rawText.length && _isSpace(rawText[end])) {
            end++;
          }
        } else {
          while (start > at && _isSpace(rawText[start - 1])) {
            start--;
          }
        }
      }
      buffer
        ..write(rawText.substring(at, start))
        ..write(edit.text);
      at = end;
    }
    buffer.write(rawText.substring(at));
    return buffer.toString().trim();
  }

  /// [rawText] as typed, for Offload on another device (T2.7a, PO
  /// 09-10-2026): every token stays, so the item comes back with its
  /// person, deadline, tags, project and priority. Only a date word becomes
  /// its fixed date (`!morgen` → `!10-10-2026`), taken from [knownDates] as
  /// in [render], so the deadline stays the same day whenever the text is
  /// read; repeat words (`!wekelijks`) stay. Escapes stay too.
  String renderAsTyped(
    String rawText, {
    required ParseContext context,
    Map<String, LocalDate> knownDates = const {},
  }) {
    final buffer = StringBuffer();
    var at = 0;
    for (final match in registry.parse(rawText, context)) {
      if (match.type is! DateTokenType) continue;
      final date = knownDates[match.word] ?? match.value as LocalDate;
      final prefix = (match.type.trigger as PrefixTrigger).prefix;
      buffer
        ..write(rawText.substring(at, match.start))
        ..write('$prefix${date.day}-${date.month}-${date.year}');
      at = match.end;
    }
    buffer.write(rawText.substring(at));
    return buffer.toString().trim();
  }

  /// What replaces [match]; null keeps it as typed.
  String? _replacement(
    TokenMatch match,
    Map<String, LocalDate> knownDates,
    bool includeTags,
  ) => switch (match.type) {
    PersonTokenType() => match.word,
    DateTokenType() => formatDate(
      knownDates[match.word] ?? match.value as LocalDate,
    ),
    TagTokenType() => includeTags ? null : '',
    // A link reads as its text (DD-004 point 13).
    LinkTokenType() => match.word.trim(),
    _ => null,
  };

  /// The escape backslash before a prefix that would otherwise start a
  /// token (DD-004 point 4): dropped, the prefix stays.
  Iterable<_Edit> _escapes(String text) sync* {
    for (var i = 0; i < text.length - 1; i++) {
      if (text[i] == r'\' &&
          registry.isPrefix(text[i + 1]) &&
          registry.isTokenStart(text, i)) {
        yield (start: i, end: i + 1, text: '', leftOut: false);
      }
    }
  }

  static bool _isSpace(String character) =>
      _horizontalSpace.hasMatch(character);
}

/// One change to the raw text: [text] replaces `start..end`; [leftOut] is a
/// word dropped from the text, which takes a run of spaces with it.
typedef _Edit = ({int start, int end, String text, bool leftOut});

/// The first non-empty line of [text], trimmed: the subject of a shared
/// text and the proposed file name (PO decision 30-09-2026). Taken from the
/// text as it goes out, so nothing is sent that was not in the preview.
String shareSubject(String text) {
  for (final line in text.split(RegExp(r'\r\n|\r|\n'))) {
    final trimmed = line.trim();
    if (trimmed.isNotEmpty) return trimmed;
  }
  return '';
}
