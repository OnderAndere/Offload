import '../tokens/token_processing.dart';
import 'calling_country.dart';
import 'contact_detail.dart';
import 'person.dart';

/// The optional profile of a person (DD-012): what merging joins.
typedef PersonProfile = ({
  int? birthdayDay,
  int? birthdayMonth,
  int? birthdayYear,
  String? note,
  String? organisation,
  String? jobTitle,
});

/// The profile of [into] after [from] is merged into it (DD-015, PO
/// decisions 01-10-2026 and 02-10-2026): [into] keeps what it has; an empty
/// birthday, organisation or job title takes the one of [from]; notes are
/// put one after the other, nothing is lost.
PersonProfile mergeProfiles(PersonProfile into, PersonProfile from) {
  final hasBirthday = into.birthdayDay != null;
  final notes = [
    for (final note in [into.note, from.note])
      if (note != null && note.trim().isNotEmpty) note,
  ];
  return (
    birthdayDay: hasBirthday ? into.birthdayDay : from.birthdayDay,
    birthdayMonth: hasBirthday ? into.birthdayMonth : from.birthdayMonth,
    birthdayYear: hasBirthday ? into.birthdayYear : from.birthdayYear,
    // One note stays exactly as it is; two are joined with a blank line.
    note: switch (notes) {
      [] => into.note,
      [final only] => only,
      _ => notes.map((n) => n.trim()).join('\n\n'),
    },
    organisation: into.organisation ?? from.organisation,
    jobTitle: into.jobTitle ?? from.jobTitle,
  );
}

/// What merging does with the contact details of [from] (DD-015, T3.5): a
/// detail [into] already has ([contactKey], numbers in national form read in
/// [home]) is dropped, [into] keeps its own label; every other one moves to
/// [into].
({List<ContactDetail> move, List<ContactDetail> drop}) mergeContactDetails(
  Iterable<ContactDetail> into,
  Iterable<ContactDetail> from, {
  CallingCountry home = defaultCallingCountry,
}) {
  String key(ContactDetail d) => contactKey(d.kind, d.value, home: home);
  final keys = {for (final d in into) key(d)};
  final move = <ContactDetail>[];
  final drop = <ContactDetail>[];
  for (final detail in sortContactDetails(from)) {
    (keys.add(key(detail)) ? move : drop).add(detail);
  }
  return (move: move, drop: drop);
}

/// What merging person [fromId] into [intoId] changed (DD-015), so that
/// `PeopleRepository.undoMerge` can put it back at once.
class PersonMerge {
  const PersonMerge({
    required this.fromId,
    required this.intoId,
    required this.fromNames,
    this.requesterItemIds = const [],
    this.waitingItemIds = const [],
    this.attachmentIds = const [],
    this.movedAliasIds = const [],
    this.droppedAliasIds = const [],
    this.addedAliasIds = const [],
    this.movedContactIds = const [],
    this.droppedContactIds = const [],
    required this.profileBefore,
    required this.profileAfter,
  });

  final String fromId;
  final String intoId;

  /// The name and aliases [fromId] had: the person tokens to link back.
  final List<String> fromNames;

  /// Items whose requester, or person waited on, was [fromId].
  final List<String> requesterItemIds;
  final List<String> waitingItemIds;

  /// Attachments of [fromId] (a business card, REQ-041).
  final List<String> attachmentIds;

  /// Aliases of [fromId] that moved to [intoId], and those dropped because
  /// [intoId] already had them.
  final List<String> movedAliasIds;
  final List<String> droppedAliasIds;

  /// Aliases created on [intoId]: the name of [fromId].
  final List<String> addedAliasIds;

  /// Contact details of [fromId] that moved to [intoId], and those dropped
  /// because [intoId] already had them.
  final List<String> movedContactIds;
  final List<String> droppedContactIds;

  /// The profile of [intoId] before and after the merge: undo puts it back
  /// only when nothing changed it since.
  final PersonProfile profileBefore;
  final PersonProfile profileAfter;
}

/// The person each name and alias stands for, by [nameKey] (DD-015): a name
/// before an alias, and where sync left the same name or alias with two
/// people, the one created first (the oldest UUIDv7; PO decision
/// 01-10-2026), so every device links the same way.
Map<String, String> personIdsByName(Iterable<Person> people) {
  final oldestFirst = [...people]..sort((a, b) => a.id.compareTo(b.id));
  final byName = <String, String>{};
  for (final p in oldestFirst) {
    byName.putIfAbsent(nameKey(p.name), () => p.id);
  }
  for (final p in oldestFirst) {
    for (final alias in p.aliases) {
      byName.putIfAbsent(nameKey(alias), () => p.id);
    }
  }
  return byName;
}

/// The live person [id] stands for: itself, or, for a merged person, the
/// person it was merged into, followed to the end ([mergedInto]: merged
/// person → target). A reference that arrives late through sync still
/// finds its person this way (DD-015). Null when it leads nowhere.
String? resolvePersonId(
  String id,
  Map<String, String> mergedInto,
  Set<String> live,
) {
  var current = id;
  final seen = <String>{};
  while (!live.contains(current)) {
    final next = mergedInto[current];
    if (next == null || !seen.add(current)) return null;
    current = next;
  }
  return current;
}
