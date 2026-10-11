import '../time/local_date.dart';

/// Version of the whole inline syntax as stored in `tokens.parser_version`.
/// Raise it when recognising changes; stored items are then processed again
/// (DD-004 point 1).
///
/// 2: `^project` and `*priority` (T10.5). 3: `*2` is stored as normal
/// (PO decision 02-10-2026), so items processed by 2 are processed again.
/// 4: phone numbers and email addresses (T3.6). 5: links `[[…]]` (T10.9).
/// 6: repeat words `!wekelijks` (T4.7).
const tokenParserVersion = 6;

/// The key names and tags are compared by: case-insensitive with Unicode
/// rules, so `Олена` and `олена` are one person (DD-015). Deliberately not
/// SQLite's `COLLATE NOCASE`, which only folds ASCII letters (DD-003).
String nameKey(String name) => name.trim().toLowerCase();

/// A deadline without a time of day (`!vr`) is stored as midnight UTC of
/// that date, and read back from its year, month and day without converting
/// to local time; so it is the same day in every time zone (DD-003, DD-004).
DateTime dateOnlyToStored(LocalDate date) =>
    DateTime.utc(date.year, date.month, date.day);

LocalDate storedToDateOnly(DateTime stored) {
  final utc = stored.toUtc();
  return LocalDate(utc.year, utc.month, utc.day);
}

/// One saved version of an item's text: when it was saved, and the text.
typedef TextVersion = ({DateTime savedAt, String rawText});

/// The moment a date token counts from (DD-018 point 1): the start of the
/// latest unbroken run of [versions] (oldest first) whose text [contains]
/// the token. So a date that stays in the text keeps its date, and a date
/// typed (again) in an edit counts from that edit. [fallback] (the capture
/// moment) when no version contains it.
///
/// The versions come from the change log, which is synchronised, so every
/// device works out the same deadline.
DateTime dateTokenAnchor(
  List<TextVersion> versions,
  bool Function(String rawText) contains, {
  required DateTime fallback,
}) {
  final start = tokenRunStart(versions, contains);
  return start == null ? fallback : versions[start].savedAt;
}

/// The index in [versions] (oldest first) where the latest unbroken run of
/// versions whose text [contains] the token starts: the version in which it
/// entered the text. Null when the latest version does not contain it.
int? tokenRunStart(
  List<TextVersion> versions,
  bool Function(String rawText) contains,
) {
  int? start;
  for (var i = versions.length - 1; i >= 0; i--) {
    if (!contains(versions[i].rawText)) break;
    start = i;
  }
  return start;
}

/// Whether a `^project` token sets the item's project (DD-004 point 11): when
/// it [entered] the text (as for a date, [tokenRunStart]) after the project
/// was [lastChosen] (picker, triage, or an earlier token). So a newly typed
/// token acts like a choice, a later choice in the picker wins over a token
/// that stays in the text, and removing the token keeps the project.
///
/// Both are positions in the item's change log in HLC order, not clock
/// times: the change log is synchronised and its order is the same on every
/// device, also when two changes share a millisecond.
bool projectTokenApplies(int entered, int? lastChosen) =>
    lastChosen == null || entered > lastChosen;

/// Works out the tokens of saved items (T2.2 step B, DD-004): it runs after
/// saving, never before (CLAUDE.md rule 7).
abstract class ItemTokenProcessor {
  /// Links the tokens of item [itemId]: finds or creates the persons and
  /// tags, stores the tokens and sets the deadline from the first date in
  /// the text, or clears it when there is none (DD-018 point 1). The
  /// priority follows the text too; a new `^project` sets the project
  /// ([projectTokenApplies]). Projects are never created here (AC REQ-050).
  Future<void> process(String itemId);

  /// Processes every live item whose tokens are missing or come from an
  /// older [tokenParserVersion], e.g. items saved before this version, and
  /// every item with a `^project` that named no project when it was
  /// processed but names one now. Once per start; an item that fails does
  /// not stop the others.
  Future<void> processOutdated();
}
