import '../items/item_enums.dart';
import '../repeats/repeat.dart';
import '../time/local_date.dart';

/// What starts a token (DD-004 point 3a): a prefix character such as `@`, a
/// pattern for tokens without prefix (phone number, e-mail; REQ-039), or a
/// pair of signs around text (`[[…]]`, a link; DD-004 point 13).
sealed class TokenTrigger {
  const TokenTrigger();
}

class PrefixTrigger extends TokenTrigger {
  const PrefixTrigger(this.prefix) : assert(prefix.length == 1);

  final String prefix;
}

class PatternTrigger extends TokenTrigger {
  const PatternTrigger(this.pattern);

  final Pattern pattern;
}

/// A token between [open] and [close] on one line, such as `[[Offerte]]`:
/// unlike a prefix token, the text between may hold spaces, and no other
/// token is recognised inside it (DD-004 point 13).
class EnclosedTrigger extends TokenTrigger {
  const EnclosedTrigger(this.open, this.close);

  final String open;
  final String close;
}

/// The date words of the active UI language (DD-004 point 5): the parser
/// itself holds no language-specific text. All words lowercase.
class DateVocabulary {
  DateVocabulary({
    required Iterable<String> today,
    required Iterable<String> tomorrow,
    required Iterable<String> dayAfterTomorrow,
    required Iterable<String> nextWeek,
    required List<List<String>> weekdays,
  }) : assert(weekdays.length == 7),
       _entries = [
         (words: [...today], meaning: const _Relative(0)),
         (words: [...tomorrow], meaning: const _Relative(1)),
         (words: [...dayAfterTomorrow], meaning: const _Relative(2)),
         for (var i = 0; i < 7; i++)
           (words: weekdays[i], meaning: _Weekday(i + 1)),
         (words: [...nextWeek], meaning: const _NextWeek()),
       ] {
    for (final entry in _entries) {
      for (final word in entry.words) {
        _words[word] = entry.meaning;
      }
    }
  }

  /// No date words; only explicit dates.
  static final empty = DateVocabulary(
    today: const [],
    tomorrow: const [],
    dayAfterTomorrow: const [],
    nextWeek: const [],
    weekdays: const [[], [], [], [], [], [], []],
  );

  final List<({List<String> words, _DateWord meaning})> _entries;
  final _words = <String, _DateWord>{};

  /// The date [word] means on [today], or null when it is no date word.
  LocalDate? resolve(String word, LocalDate today) =>
      _words[word.toLowerCase()]?.dateFrom(today);

  /// Date options for the suggestion list (REQ-033): every meaning with a
  /// word starting with [query], in order: today, tomorrow, the day after,
  /// the coming weekdays by date, next week. Each option inserts the last
  /// (full) word of its meaning (PO decision 27-09-2026: `!vrijdag`).
  List<({String word, LocalDate date})> suggestions(
    String query,
    LocalDate today,
  ) {
    final start = query.toLowerCase();
    final options = <({String word, LocalDate date, int group})>[];
    for (final entry in _entries) {
      if (!entry.words.any((w) => w.startsWith(start))) continue;
      // Relative words first, then the weekdays by date, then next week.
      final group = switch (entry.meaning) {
        _Relative() => 0,
        _Weekday() => 1,
        _NextWeek() => 2,
      };
      options.add((
        word: entry.words.last,
        date: entry.meaning.dateFrom(today),
        group: group,
      ));
    }
    options.sort((a, b) {
      final byGroup = a.group.compareTo(b.group);
      return byGroup != 0 ? byGroup : a.date.compareTo(b.date);
    });
    return [for (final o in options) (word: o.word, date: o.date)];
  }
}

sealed class _DateWord {
  const _DateWord();

  LocalDate dateFrom(LocalDate today);
}

class _Relative extends _DateWord {
  const _Relative(this.days);

  final int days;

  @override
  LocalDate dateFrom(LocalDate today) => today.addDays(days);
}

/// The next such weekday, never today: `!vr` on a Friday is next week's
/// Friday (PO decision 27-09-2026).
class _Weekday extends _DateWord {
  const _Weekday(this.weekday);

  final int weekday;

  @override
  LocalDate dateFrom(LocalDate today) {
    final ahead = (weekday - today.weekday + 7) % 7;
    return today.addDays(ahead == 0 ? 7 : ahead);
  }
}

/// Monday of next week.
class _NextWeek extends _DateWord {
  const _NextWeek();

  @override
  LocalDate dateFrom(LocalDate today) => today.addDays(8 - today.weekday);
}

/// The priority words of the active UI language (DD-004 points 3 and 5),
/// lowercase; the digits `1`, `2` and `3` work in every language.
class PriorityVocabulary {
  const PriorityVocabulary({this.high = const [], this.low = const []});

  /// Only the digits.
  static const digitsOnly = PriorityVocabulary();

  final List<String> high;
  final List<String> low;

  /// The priority [word] means, or null when it is none.
  ItemPriority? resolve(String word) {
    final lower = word.toLowerCase();
    return switch (lower) {
      '1' => ItemPriority.high,
      '2' => ItemPriority.normal,
      '3' => ItemPriority.low,
      _ when high.contains(lower) => ItemPriority.high,
      _ when low.contains(lower) => ItemPriority.low,
      _ => null,
    };
  }
}

/// What a token type needs to know besides the text.
class ParseContext {
  const ParseContext({
    required this.today,
    required this.dates,
    this.priorities = PriorityVocabulary.digitsOnly,
    this.repeats = RepeatVocabulary.none,
    this.repeatsShown = RepeatVocabulary.none,
  });

  /// Today's date on this device; relative dates count from here.
  final LocalDate today;
  final DateVocabulary dates;
  final PriorityVocabulary priorities;

  /// The repeat words of every app language (DD-004 point 14).
  final RepeatVocabulary repeats;

  /// Those of the active UI language, for the suggestion list.
  final RepeatVocabulary repeatsShown;
}

/// One kind of inline token (DD-004): recognising it in the raw text.
/// Resolving against stored data and applying it to an item follow with the
/// post-save processing (T2.2 step B); chips, icons and labels live in the
/// presentation layer, because the domain has no UI types.
abstract class InlineTokenType {
  const InlineTokenType();

  /// Stable id, stored as `tokens.token_type`: `person`, `tag`, `date`.
  String get id;

  TokenTrigger get trigger;

  /// Raised when this type recognises differently, so stored tokens of older
  /// versions are parsed again.
  int get schemaVersion;

  /// Whether this type shares its prefix with the type that owns it (the
  /// repeat words on the `!` of dates, DD-004 point 14): it is tried first,
  /// but the suggestion list of the prefix goes by the owner.
  bool get sharesPrefix => false;

  /// The meaning of [word] (the text after the prefix, without trailing
  /// punctuation), or null when it is not this token: it then stays text
  /// (DD-004 point 6).
  Object? parse(String word, ParseContext context);
}

/// A token found in the raw text.
class TokenMatch {
  const TokenMatch({
    required this.type,
    required this.start,
    required this.end,
    required this.word,
    required this.value,
  });

  final InlineTokenType type;

  /// Position in the raw text, prefix included; [end] is exclusive.
  final int start;
  final int end;

  /// The text after the prefix, as typed; for an enclosed token the text
  /// between the signs.
  final String word;

  /// What [InlineTokenType.parse] made of it: a name for person, tag and
  /// project, a [LocalDate] for a date, an [ItemPriority] for a priority,
  /// a [Rhythm] for a repeat word.
  final Object value;
}
