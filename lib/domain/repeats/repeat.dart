import '../ids/uuid_v5.dart';
import '../items/item_enums.dart';
import '../time/local_date.dart';

/// The calendar unit of a series (REQ-061, DD-004 point 14).
enum RepeatUnit { day, week, month }

/// How a series counts. Only fixed on the calendar for now; "N days after
/// completing" (SPEC Q30) may come later as a second mode.
enum RepeatMode { calendar }

/// The rhythm of a recurring task: `!dagelijks`, `!wekelijks`,
/// `!maandelijks`. Stored language-neutral as [code] (`1D`, `1W`, `1M`),
/// so a change of UI language never changes a series.
class Rhythm {
  const Rhythm(this.unit, {this.interval = 1, this.mode = RepeatMode.calendar})
    : assert(interval > 0);

  static const daily = Rhythm(RepeatUnit.day);
  static const weekly = Rhythm(RepeatUnit.week);
  static const monthly = Rhythm(RepeatUnit.month);

  final RepeatUnit unit;
  final int interval;
  final RepeatMode mode;

  static const _letters = {
    RepeatUnit.day: 'D',
    RepeatUnit.week: 'W',
    RepeatUnit.month: 'M',
  };
  static final _code = RegExp(r'^([1-9]\d{0,2})([DWM])$');

  /// `1D`, `1W`, `1M`.
  String get code => '$interval${_letters[unit]}';

  /// The rhythm of [code], or null for anything else.
  static Rhythm? fromCode(String code) {
    final match = _code.firstMatch(code);
    if (match == null) return null;
    final unit = _letters.entries.firstWhere((e) => e.value == match[2]).key;
    return Rhythm(unit, interval: int.parse(match[1]!));
  }

  @override
  bool operator ==(Object other) =>
      other is Rhythm &&
      other.unit == unit &&
      other.interval == interval &&
      other.mode == mode;

  @override
  int get hashCode => Object.hash(unit, interval, mode);

  @override
  String toString() => code;
}

/// The repeat words (DD-004 point 14), lowercase. Unlike date words, the
/// parser knows those of **every** app language, so a series never stops
/// after a change of language; the suggestion list shows the words of the
/// active language only.
class RepeatVocabulary {
  const RepeatVocabulary({
    this.daily = const [],
    this.weekly = const [],
    this.monthly = const [],
  });

  /// No repeat words.
  static const none = RepeatVocabulary();

  /// The words of all [vocabularies] together.
  factory RepeatVocabulary.merge(Iterable<RepeatVocabulary> vocabularies) =>
      RepeatVocabulary(
        daily: [for (final v in vocabularies) ...v.daily],
        weekly: [for (final v in vocabularies) ...v.weekly],
        monthly: [for (final v in vocabularies) ...v.monthly],
      );

  final List<String> daily;
  final List<String> weekly;
  final List<String> monthly;

  List<({List<String> words, Rhythm rhythm})> get _entries => [
    (words: daily, rhythm: Rhythm.daily),
    (words: weekly, rhythm: Rhythm.weekly),
    (words: monthly, rhythm: Rhythm.monthly),
  ];

  /// The rhythm [word] means, or null when it is no repeat word. Unicode
  /// lower case, so Cyrillic words compare without case too.
  Rhythm? resolve(String word) {
    final lower = word.toLowerCase();
    for (final entry in _entries) {
      if (entry.words.contains(lower)) return entry.rhythm;
    }
    return null;
  }

  /// Options for the suggestion list (REQ-033): daily, weekly, monthly, each
  /// with its last (full) word, when one of its words starts with [query].
  List<({String word, Rhythm rhythm})> suggestions(String query) {
    final start = query.toLowerCase();
    return [
      for (final entry in _entries)
        if (entry.words.isNotEmpty &&
            entry.words.any((w) => w.startsWith(start)))
          (word: entry.words.last, rhythm: entry.rhythm),
    ];
  }
}

/// Date [k] of the series that starts on [anchor] (k = 0 is the anchor).
/// Monthly keeps the anchor's day of the month and falls on the last day
/// of a shorter month; it is always counted from the anchor, never from the
/// previous date, so the 31st never drifts to the 28th.
LocalDate seriesDate(LocalDate anchor, Rhythm rhythm, int k) {
  final steps = k * rhythm.interval;
  switch (rhythm.unit) {
    case RepeatUnit.day:
      return anchor.addDays(steps);
    case RepeatUnit.week:
      return anchor.addDays(7 * steps);
    case RepeatUnit.month:
      final months = anchor.month - 1 + steps;
      final year = anchor.year + (months ~/ 12);
      final month = months % 12 + 1;
      // Day 0 of the next month is the last day of this one.
      final lastDay = DateTime.utc(year, month + 1, 0).day;
      return LocalDate(
        year,
        month,
        anchor.day <= lastDay ? anchor.day : lastDay,
      );
  }
}

/// The first date of the series from [anchor] that is after [after]; the
/// anchor itself when that is after it already.
LocalDate firstSeriesDateAfter(
  LocalDate anchor,
  Rhythm rhythm,
  LocalDate after,
) {
  if (anchor.compareTo(after) > 0) return anchor;
  // An estimate of the step, then exact: never more than a step or two off.
  final span = switch (rhythm.unit) {
    RepeatUnit.day => after.daysSince(anchor),
    RepeatUnit.week => after.daysSince(anchor) ~/ 7,
    RepeatUnit.month =>
      (after.year - anchor.year) * 12 + after.month - anchor.month,
  };
  var k = span ~/ rhythm.interval;
  while (k > 0 && seriesDate(anchor, rhythm, k - 1).compareTo(after) > 0) {
    k--;
  }
  while (seriesDate(anchor, rhythm, k).compareTo(after) <= 0) {
    k++;
  }
  return seriesDate(anchor, rhythm, k);
}

/// The dates of the series from [anchor] in [from]..[to], both included.
Iterable<LocalDate> seriesDatesBetween(
  LocalDate anchor,
  Rhythm rhythm,
  LocalDate from,
  LocalDate to,
) sync* {
  var date = anchor.compareTo(from) >= 0
      ? anchor
      : firstSeriesDateAfter(anchor, rhythm, from.addDays(-1));
  while (date.compareTo(to) <= 0) {
    yield date;
    date = firstSeriesDateAfter(anchor, rhythm, date);
  }
}

/// One completed time of a series (`item_completions`, DD-018 point 18):
/// the date of the time, and the day it was done.
class RepeatCompletion {
  const RepeatCompletion({
    required this.occurrenceOn,
    required this.completedOn,
  });

  final LocalDate occurrenceOn;
  final LocalDate completedOn;

  /// Up to where this record covers the series: done early covers its own
  /// date, done late covers the day it was done (SPEC Q31).
  LocalDate get doneThrough =>
      completedOn.compareTo(occurrenceOn) > 0 ? completedOn : occurrenceOn;

  /// Days after its date it was done; 0 when on time or early.
  int get daysLate {
    final late = completedOn.daysSince(occurrenceOn);
    return late > 0 ? late : 0;
  }
}

/// The first time of a series (DD-004 point 14): the first date token of
/// the text; without one the earliest completed time, so a monthly series
/// keeps its day of the month and removing and typing the token again does
/// not move it; else the day the repeat token [entered] the text.
LocalDate repeatAnchor({
  LocalDate? dateToken,
  required Iterable<RepeatCompletion> records,
  required LocalDate entered,
}) {
  if (dateToken != null) return dateToken;
  LocalDate? earliest;
  for (final record in records) {
    if (earliest == null || record.occurrenceOn.compareTo(earliest) < 0) {
      earliest = record.occurrenceOn;
    }
  }
  return earliest ?? entered;
}

/// The date of a repeating item (`due_at`): the first series date on or
/// after [anchor] and after every completed time ([doneThrough]); the
/// anchor itself before the first completion. Missed periods give one
/// overdue date, never a pile (SPEC Q31).
LocalDate repeatDue(
  LocalDate anchor,
  Rhythm rhythm,
  Iterable<RepeatCompletion> records,
) {
  LocalDate? through;
  for (final record in records) {
    final done = record.doneThrough;
    if (through == null || done.compareTo(through) > 0) through = done;
  }
  return through == null
      ? anchor
      : firstSeriesDateAfter(anchor, rhythm, through);
}

/// Whether an item of [type] repeats when completed (decision 6b): a task,
/// or an item without a type yet. An idea, request or note does not.
bool repeatsAs(ItemType? type) => type == null || type == ItemType.task;

/// What the stored repeat token of an item says: its rhythm and first time.
class ItemRepeat {
  const ItemRepeat(this.rhythm, this.anchor);

  final Rhythm rhythm;
  final LocalDate anchor;

  /// As stored in `tokens.resolved_value`: `1W@2026-09-08`.
  String encode() => '${rhythm.code}@$anchor';

  /// The value of [stored], or null when it is not one.
  static ItemRepeat? decode(String? stored) {
    if (stored == null) return null;
    final at = stored.indexOf('@');
    if (at < 0) return null;
    final rhythm = Rhythm.fromCode(stored.substring(0, at));
    final date = _parseDate(stored.substring(at + 1));
    return rhythm == null || date == null ? null : ItemRepeat(rhythm, date);
  }

  static LocalDate? _parseDate(String text) {
    final parts = text.split('-');
    if (parts.length != 3) return null;
    final numbers = [for (final p in parts) int.tryParse(p)];
    if (numbers.contains(null)) return null;
    return LocalDate.tryCreate(numbers[0]!, numbers[1]!, numbers[2]!);
  }

  @override
  bool operator ==(Object other) =>
      other is ItemRepeat && other.rhythm == rhythm && other.anchor == anchor;

  @override
  int get hashCode => Object.hash(rhythm, anchor);
}

/// The fixed namespace of [completionId]; never change it, or devices stop
/// agreeing on ids (DD-003).
const completionIdNamespace = '7daf67a7-b5b8-4a94-861e-aabcf1f4baf7';

/// The id of the record of the time on [occurrence] of item [itemId]: a
/// UUIDv5, so two devices that complete the same time make the same row,
/// and so does completing it again after an undo (SPEC Q33, DD-003). Two
/// completions one after the other record two times: the screens guard
/// against a double tap.
String completionId(String itemId, LocalDate occurrence) =>
    uuidV5(completionIdNamespace, '$itemId/$occurrence');
