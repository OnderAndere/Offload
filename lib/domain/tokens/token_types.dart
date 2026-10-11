import '../time/local_date.dart';
import 'inline_token.dart';

final _startsWithLetter = RegExp(r'^\p{L}', unicode: true);

/// A project word: letters or digits first, optionally one `/` between a
/// top-level project and a sub-project (`^renovatie/keuken`).
final _projectWord = RegExp(
  r'^[\p{L}\p{N}][^/]*(/[\p{L}\p{N}][^/]*)?$',
  unicode: true,
);

/// `@Jan`: a link to a person (DD-004, DD-015). At capture it is only a
/// link; whether Jan asked for it or is waited on is chosen in triage
/// (PO decision 27-09-2026).
class PersonTokenType extends InlineTokenType {
  const PersonTokenType();

  @override
  String get id => 'person';

  @override
  TokenTrigger get trigger => const PrefixTrigger('@');

  @override
  int get schemaVersion => 1;

  /// A name starts with a letter, so `@10:00` stays text.
  @override
  Object? parse(String word, ParseContext context) =>
      _startsWithLetter.hasMatch(word) ? word : null;
}

/// `#renovatie`: a tag (DD-004; tags are linked through tokens, DD-003).
class TagTokenType extends InlineTokenType {
  const TagTokenType();

  @override
  String get id => 'tag';

  @override
  TokenTrigger get trigger => const PrefixTrigger('#');

  @override
  int get schemaVersion => 1;

  /// A tag starts with a letter, so `#1` stays text.
  @override
  Object? parse(String word, ParseContext context) =>
      _startsWithLetter.hasMatch(word) ? word : null;
}

/// `^renovatie`: the project of the item (REQ-050, DD-004 point 11). The
/// word is matched against project names without case, spaces, `-` and `_`
/// (`projectForWord`); a name nobody has stays a token without a project.
class ProjectTokenType extends InlineTokenType {
  const ProjectTokenType();

  @override
  String get id => 'project';

  @override
  TokenTrigger get trigger => const PrefixTrigger('^');

  @override
  int get schemaVersion => 1;

  /// Whether [word] can follow `^`.
  static bool isWord(String word) => _projectWord.hasMatch(word);

  @override
  Object? parse(String word, ParseContext context) =>
      isWord(word) ? word : null;
}

/// `[[Offerte kozijnen]]`: a link to another item (REQ-054, DD-004 point
/// 13). The text between the brackets is the label; which item it names is
/// stored as an item link, never looked up by title, so renaming the target
/// breaks nothing.
class LinkTokenType extends InlineTokenType {
  const LinkTokenType();

  @override
  String get id => 'link';

  @override
  TokenTrigger get trigger => const EnclosedTrigger('[[', ']]');

  @override
  int get schemaVersion => 1;

  /// The label as typed; blank (`[[ ]]`) is no link.
  @override
  Object? parse(String word, ParseContext context) =>
      word.trim().isEmpty ? null : word;
}

/// `*hoog`, `*1`: the priority of the item (REQ-050, DD-004 point 3). Only
/// a fixed value is a token, so Markdown such as `* item`, `*nadruk*` and
/// `**vet**` stays text.
class PriorityTokenType extends InlineTokenType {
  const PriorityTokenType();

  @override
  String get id => 'priority';

  @override
  TokenTrigger get trigger => const PrefixTrigger('*');

  @override
  int get schemaVersion => 1;

  @override
  Object? parse(String word, ParseContext context) =>
      context.priorities.resolve(word);
}

/// `!vr`, `!morgen`, `!12-10`: a deadline (DD-004). Words come from the
/// active UI language; dates are day-month or day-month-year.
class DateTokenType extends InlineTokenType {
  const DateTokenType();

  static const _minYear = 1900;
  static const _maxYear = 2999;
  static final _explicit = RegExp(r'^(\d{1,2})-(\d{1,2})(?:-(\d{4}))?$');

  @override
  String get id => 'date';

  @override
  TokenTrigger get trigger => const PrefixTrigger('!');

  @override
  int get schemaVersion => 1;

  @override
  Object? parse(String word, ParseContext context) {
    final named = context.dates.resolve(word, context.today);
    if (named != null) return named;
    final match = _explicit.firstMatch(word);
    if (match == null) return null;
    final day = int.parse(match[1]!);
    final month = int.parse(match[2]!);
    final year = match[3];
    if (year != null) {
      final y = int.parse(year);
      // A plausible deadline, not a typing slip such as 0000.
      if (y < _minYear || y > _maxYear) return null;
      return LocalDate.tryCreate(y, month, day);
    }
    // Without a year: the next such date, today included.
    final today = context.today;
    final thisYear = LocalDate.tryCreate(today.year, month, day);
    if (thisYear != null && thisYear.compareTo(today) >= 0) return thisYear;
    return LocalDate.tryCreate(today.year + 1, month, day);
  }
}

/// `!dagelijks`, `!wekelijks`, `!maandelijks` (EN `!daily`, `!weekly`,
/// `!monthly`): the item repeats (REQ-061, DD-004 point 14). It shares `!`
/// with the date and is tried before it, so a date word of one language can
/// never take a repeat word of another; the words of every app language
/// are recognised, so a change of language never stops a series.
class RepeatTokenType extends InlineTokenType {
  const RepeatTokenType();

  @override
  String get id => 'repeat';

  @override
  TokenTrigger get trigger => const PrefixTrigger('!');

  @override
  int get schemaVersion => 1;

  @override
  bool get sharesPrefix => true;

  @override
  Object? parse(String word, ParseContext context) =>
      context.repeats.resolve(word);
}
