import 'inline_token.dart';

/// Tokens without a prefix (DD-004 point 3a, REQ-039, T3.6): a phone number
/// and an email address in free text. Stricter than the check of the
/// contact form, so years, times and dates stay text.

/// `06-12345678`, `+31 6 1234 5678`: a phone number (PO decision f,
/// 02-10-2026). It starts with `+` or `0` at the start of a word, has 9 to
/// 15 digits, and spaces, `-`, `.`, `/` or brackets between them.
class PhoneTokenType extends InlineTokenType {
  const PhoneTokenType();

  @override
  String get id => 'phone';

  @override
  TokenTrigger get trigger => const PatternTrigger(PhonePattern());

  @override
  int get schemaVersion => 1;

  @override
  Object? parse(String word, ParseContext context) =>
      const PhonePattern().matchAsPrefix(word)?.end == word.length
      ? word
      : null;
}

/// `jan@example.org`: an email address.
class EmailTokenType extends InlineTokenType {
  const EmailTokenType();

  static final _email = RegExp(
    r'(?<![\w.%+-])[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)*'
    r'\.[A-Za-z]{2,}(?![\w-])',
  );

  @override
  String get id => 'email';

  @override
  TokenTrigger get trigger => PatternTrigger(_email);

  @override
  int get schemaVersion => 1;

  @override
  Object? parse(String word, ParseContext context) =>
      _email.matchAsPrefix(word)?.end == word.length ? word : null;
}

/// Finds phone numbers in text. A regular expression cannot tell where a
/// number ends ("06-12345678 10 uur"), so this scans: groups of digits
/// joined by `-`, `.`, `/` or brackets always belong together; a group
/// after a space only while the number is still short (fewer than 10
/// digits for a national number, 11 after `+` or 13 after "00"), which is
/// where a number written in blocks ("06 12 34 56 78", "+31 6 1234 5678")
/// still goes on.
class PhonePattern implements Pattern {
  const PhonePattern();

  static const _minDigits = 9;
  static const _maxDigits = 15;
  // A date with a year ("01-02-2026"), also with a time after it. One
  // without a year has too few digits anyway, and "06-12 34 56 78" is a
  // number.
  static final _date = RegExp(r'^\d{1,2}[-./]\d{1,2}[-./]\d{2,4}(?=\s|$)');
  static final _space = RegExp(r'\s');
  static final _wordChar = RegExp(r'[\p{L}\p{N}_@]', unicode: true);

  @override
  Iterable<Match> allMatches(String string, [int start = 0]) sync* {
    var i = start;
    while (i < string.length) {
      // The cheap check first: most characters start no word.
      final match = _startsWord(string, i) ? matchAsPrefix(string, i) : null;
      if (match != null) {
        yield match;
        i = match.end;
      } else {
        i++;
      }
    }
  }

  @override
  Match? matchAsPrefix(String string, [int start = 0]) {
    if (start >= string.length) return null;
    final first = string[start];
    if (first != '+' && first != '0') return null;
    final international = first == '+';
    // A group after a space belongs to the number while it has fewer
    // digits than this: 10 for a national number, 11 after `+`, and 13
    // after "00" (which counts its two zeros).
    final blockLimit = international
        ? 11
        : string.startsWith('00', start)
        ? 13
        : 10;
    var i = international ? start + 1 : start;
    var digits = 0;
    var end = -1;
    while (i < string.length) {
      // A run of digits, or a bracketed one: "(0)20".
      if (string[i] == '(') {
        final close = string.indexOf(')', i);
        if (close < 0) break;
        final inner = string.substring(i + 1, close);
        if (inner.isEmpty || !_allDigits(inner)) break;
        digits += inner.length;
        i = close + 1;
        end = i;
      } else if (_isDigit(string[i])) {
        while (i < string.length && _isDigit(string[i])) {
          digits++;
          i++;
        }
        end = i;
      } else {
        break;
      }
      // Too long for a phone number: no need to read on.
      if (digits > _maxDigits) return null;
      if (i >= string.length) break;
      final next = string[i];
      final after = i + 1 < string.length ? string[i + 1] : '';
      final continues = _isDigit(after) || after == '(';
      if ('-./'.contains(next) && continues) {
        i++;
      } else if (next == '(' || _isDigit(next)) {
        // "+31(0)20": a bracket right after digits, or digits right after
        // a bracket.
      } else if (next == ' ' && continues && digits < blockLimit) {
        i++;
      } else {
        break;
      }
    }
    if (end < 0 || digits < _minDigits || digits > _maxDigits) return null;
    // Glued to a letter or digit: part of a word, not a number.
    if (end < string.length && _wordChar.hasMatch(string[end])) return null;
    final text = string.substring(start, end);
    // A date is no phone number, also with a time after it.
    if (!international && _date.hasMatch(text)) return null;
    return _PhoneMatch(string, start, end, this);
  }

  static bool _startsWord(String text, int at) =>
      at == 0 || _space.hasMatch(text[at - 1]) || '([{'.contains(text[at - 1]);

  static bool _isDigit(String char) =>
      char.isNotEmpty &&
      char.codeUnitAt(0) >= 0x30 &&
      char.codeUnitAt(0) <= 0x39;

  static bool _allDigits(String text) => text.split('').every(_isDigit);
}

class _PhoneMatch implements Match {
  _PhoneMatch(this.input, this.start, this.end, this.pattern);

  @override
  final String input;
  @override
  final int start;
  @override
  final int end;
  @override
  final Pattern pattern;

  @override
  String? group(int group) =>
      group == 0 ? input.substring(start, end) : throw RangeError(group);

  @override
  String? operator [](int group) => this.group(group);

  @override
  List<String?> groups(List<int> groupIndices) => [
    for (final g in groupIndices) group(g),
  ];

  @override
  int get groupCount => 0;
}
