import 'contact_token_types.dart';
import 'inline_token.dart';
import 'token_types.dart';

/// The inline syntax of the raw text (REQ-019, REQ-028, DD-004): a register
/// of token types, so a new token is one new type, not a new parser.
///
/// Rules for prefix tokens:
/// - a token starts at the beginning of the text, after white space or
///   right after an opening bracket (`(@Jan)`, PO decision 27-09-2026), so
///   `jan@example.org` is no person and `\@Jan` stays text (the escape);
/// - several types may share a prefix (`!` for dates and repeat words,
///   DD-004 point 14): they are tried in the order they are registered, and
///   the first that recognises the word has it;
/// - the token runs to the next white space; trailing punctuation such as
///   `,` or `.` is not part of it;
/// - a prefix no type has registered (`~` and `?` are reserved) and a word
///   a type does not recognise stay text; nothing is an error.
///
/// An enclosed token (`[[Offerte kozijnen]]`, DD-004 point 13) starts where
/// a prefix token may start and ends at its closing signs on the same line;
/// no other token is recognised inside it.
class InlineTokenRegistry {
  InlineTokenRegistry(List<InlineTokenType> types)
    : types = List.unmodifiable(types) {
    for (final type in types) {
      final trigger = type.trigger;
      if (trigger is! PrefixTrigger) continue;
      final shared = _byPrefix.putIfAbsent(trigger.prefix, () => []);
      if (shared.any((t) => t.id == type.id)) {
        throw ArgumentError('Token type ${type.id} registered twice');
      }
      shared.add(type);
    }
  }

  /// The tokens of this version of the app.
  factory InlineTokenRegistry.standard() => InlineTokenRegistry(const [
    PersonTokenType(),
    TagTokenType(),
    RepeatTokenType(),
    DateTokenType(),
    ProjectTokenType(),
    PriorityTokenType(),
    PhoneTokenType(),
    EmailTokenType(),
    LinkTokenType(),
  ]);

  final List<InlineTokenType> types;
  final _byPrefix = <String, List<InlineTokenType>>{};

  /// The prefixes of the registered types, such as `@` and `#`.
  Iterable<String> get prefixes => _byPrefix.keys;

  static final _space = RegExp(r'\s');
  static const _openingBrackets = '([{';

  /// Punctuation at the end of a word that is not part of it; an opening
  /// bracket too, so `@Jan([[Offerte]])` names Jan (DD-004 point 13).
  static final _trailingPunctuation = RegExp(r'''[.,;:!?)\]}"'([{]+$''');

  /// Whether [character] is the prefix of a registered type, such as `@`.
  bool isPrefix(String character) => _byPrefix.containsKey(character);

  /// Whether a prefix at [offset] in [text] would start a token: at the
  /// beginning, after white space or right after an opening bracket. The
  /// prefix bar uses this to decide on a space before the sign (REQ-034).
  bool isTokenStart(String text, int offset) =>
      offset == 0 ||
      _space.hasMatch(text[offset - 1]) ||
      _openingBrackets.contains(text[offset - 1]);

  /// The tokens in [rawText], in order of position. Pure: no stored data is
  /// read, so this can run on every keystroke (REQ-001).
  List<TokenMatch> parse(String rawText, ParseContext context) {
    final enclosed = _enclosedMatches(rawText, context).toList();
    final matches = <TokenMatch>[...enclosed];
    var i = 0;
    var next = 0;
    while (i < rawText.length) {
      // Nothing inside an enclosed token is a token of its own.
      if (next < enclosed.length && i >= enclosed[next].start) {
        i = enclosed[next].end;
        next++;
        continue;
      }
      final shared = _byPrefix[rawText[i]];
      if (shared == null || !isTokenStart(rawText, i)) {
        i++;
        continue;
      }
      var end = rawText.indexOf(_space, i + 1);
      if (end < 0) end = rawText.length;
      // A word ends where a link starts, so tokens never overlap.
      if (next < enclosed.length && enclosed[next].start < end) {
        end = enclosed[next].start;
      }
      final word = rawText
          .substring(i + 1, end)
          .replaceFirst(_trailingPunctuation, '');
      InlineTokenType? type;
      Object? value;
      for (final candidate
          in word.isEmpty ? const <InlineTokenType>[] : shared) {
        value = candidate.parse(word, context);
        if (value != null) {
          type = candidate;
          break;
        }
      }
      if (type != null && value != null) {
        matches.add(
          TokenMatch(
            type: type,
            start: i,
            end: i + 1 + word.length,
            word: word,
            value: value,
          ),
        );
      }
      i = end;
    }
    return [...matches, ..._patternMatches(rawText, context, matches)]
      ..sort((a, b) => a.start.compareTo(b.start));
  }

  /// The prefix token being typed at [cursor], for the suggestion list
  /// (REQ-033): its type, where the prefix is, where the word ends and what
  /// is typed after the prefix so far. The same rules as [parse]: the word
  /// ends at the next white space, without trailing punctuation. Null when
  /// the cursor is not in such a word, including when it is after trailing
  /// punctuation (`@Jan.|`); pattern tokens have no suggestions. For a
  /// prefix several types share, [type] is the one that owns it (the date
  /// for `!`, not the repeat words that share it).
  ///
  /// Inside a link being typed (`[[offer|`, also with spaces) that link is
  /// the token: [start] is at its opening signs, [end] after its closing
  /// signs when they are there on the same line, or else at the cursor, so
  /// choosing never swallows text after it (DD-004 point 13).
  ({InlineTokenType type, int start, int end, String query})? tokenAt(
    String text,
    int cursor,
  ) {
    if (cursor < 1 || cursor > text.length) return null;
    final enclosed = _enclosedAt(text, cursor);
    if (enclosed != null) return enclosed;
    for (var p = cursor - 1; p >= 0; p--) {
      final char = text[p];
      if (_space.hasMatch(char)) return null;
      final type = _ownerOf(char);
      if (type != null && isTokenStart(text, p)) {
        var spaceAt = text.indexOf(_space, cursor);
        if (spaceAt < 0) spaceAt = text.length;
        final word = text
            .substring(p + 1, spaceAt)
            .replaceFirst(_trailingPunctuation, '');
        final end = p + 1 + word.length;
        if (cursor > end) return null;
        return (
          type: type,
          start: p,
          end: end,
          query: text.substring(p + 1, cursor),
        );
      }
    }
    return null;
  }

  /// The type that owns [prefix] for the suggestion list: the first that
  /// does not merely share it ([InlineTokenType.sharesPrefix]).
  InlineTokenType? _ownerOf(String prefix) {
    final shared = _byPrefix[prefix];
    if (shared == null) return null;
    return shared.where((t) => !t.sharesPrefix).firstOrNull ?? shared.first;
  }

  /// The link being typed at [cursor]: the last opening on this line
  /// before the cursor, at a token start, with no closing between them.
  ({InlineTokenType type, int start, int end, String query})? _enclosedAt(
    String text,
    int cursor,
  ) {
    for (final type in types) {
      final trigger = type.trigger;
      if (trigger is! EnclosedTrigger) continue;
      final lineStart = text.lastIndexOf(_lineBreak, cursor - 1) + 1;
      final before = text.substring(lineStart, cursor);
      final at = before.lastIndexOf(trigger.open);
      if (at < 0) continue;
      final start = lineStart + at;
      final inner = start + trigger.open.length;
      if (!isTokenStart(text, start)) continue;
      if (text.substring(inner, cursor).contains(trigger.close)) continue;
      // The cursor between the closing signs (`[[abc]|]`): the link ends
      // there, and the first closing sign is no part of the query.
      if (cursor > inner && text.startsWith(trigger.close, cursor - 1)) {
        return (
          type: type,
          start: start,
          end: cursor - 1 + trigger.close.length,
          query: text.substring(inner, cursor - 1),
        );
      }
      var lineEnd = text.indexOf(_lineBreak, cursor);
      if (lineEnd < 0) lineEnd = text.length;
      final close = text.indexOf(trigger.close, cursor);
      // Its own closing only: not one on another line, nor that of a link
      // opened after the cursor (`[[off| en [[Container]]`).
      final own =
          close >= 0 &&
          close < lineEnd &&
          !text.substring(cursor, close).contains(trigger.open);
      return (
        type: type,
        start: start,
        end: own ? close + trigger.close.length : cursor,
        query: text.substring(inner, cursor),
      );
    }
    return null;
  }

  /// The enclosed tokens of [rawText], in order of position. A run of
  /// opening signs counts from its last one (`[[[x]]` is `[` and a link),
  /// the closing signs must be on the same line, and an opening inside the
  /// text between starts again from there.
  Iterable<TokenMatch> _enclosedMatches(
    String rawText,
    ParseContext context,
  ) sync* {
    for (final type in types) {
      final trigger = type.trigger;
      if (trigger is! EnclosedTrigger) continue;
      final open = trigger.open;
      final close = trigger.close;
      var i = 0;
      while (true) {
        var start = rawText.indexOf(open, i);
        if (start < 0) break;
        while (rawText.startsWith(open, start + 1)) {
          start++;
        }
        final inner = start + open.length;
        if (!isTokenStart(rawText, start)) {
          i = inner;
          continue;
        }
        final end = rawText.indexOf(close, inner);
        if (end < 0) break;
        final word = rawText.substring(inner, end);
        if (word.contains(open) || word.contains(_lineBreak)) {
          i = inner;
          continue;
        }
        final value = type.parse(word, context);
        if (value != null) {
          yield TokenMatch(
            type: type,
            start: start,
            end: end + close.length,
            word: word,
            value: value,
          );
        }
        i = end + close.length;
      }
    }
  }

  static final _lineBreak = RegExp(r'[\r\n]');

  /// Tokens found by a pattern, outside the prefix tokens.
  Iterable<TokenMatch> _patternMatches(
    String rawText,
    ParseContext context,
    List<TokenMatch> prefixed,
  ) sync* {
    for (final type in types) {
      final trigger = type.trigger;
      if (trigger is! PatternTrigger) continue;
      for (final m in trigger.pattern.allMatches(rawText)) {
        final overlaps = prefixed.any(
          (p) => m.start < p.end && p.start < m.end,
        );
        final value = overlaps ? null : type.parse(m[0]!, context);
        if (value != null) {
          yield TokenMatch(
            type: type,
            start: m.start,
            end: m.end,
            word: m[0]!,
            value: value,
          );
        }
      }
    }
  }
}
