import '../items/item_enums.dart';
import '../links/item_link.dart';
import '../projects/project.dart';
import '../projects/project_token.dart';
import '../repeats/repeat.dart';
import '../time/local_date.dart';
import 'inline_token.dart';
import 'token_processing.dart';

/// One line of the suggestion list (REQ-033).
class TokenSuggestion {
  const TokenSuggestion({
    required this.insert,
    required this.label,
    this.isNew = false,
    this.date,
    this.priority,
    this.parent,
    this.itemId,
    this.status,
    this.rhythm,
  }) : pickDate = false;

  /// The calendar line (`tokenSuggestionPickDate`): the chosen day goes into the
  /// text as a fixed date (PO decision 27-09-2026, DD-018).
  const TokenSuggestion.pickDate()
    : insert = '',
      label = '',
      isNew = false,
      date = null,
      priority = null,
      parent = null,
      itemId = null,
      status = null,
      rhythm = null,
      pickDate = true;

  /// The word that goes into the text after the prefix.
  final String insert;

  /// What the list shows: a person's or tag's name, or a date word.
  final String label;

  /// "New: …": nothing by this name exists yet. A person or tag is created
  /// on saving (PO decision 27-09-2026), never before; a project right when
  /// the line is chosen (AC REQ-050, PO decision 02-10-2026).
  final bool isNew;

  /// For date suggestions: the date the word means.
  final LocalDate? date;

  /// For priority suggestions: the priority the word means.
  final ItemPriority? priority;

  /// For a sub-project: the name of its top-level project. For an item:
  /// the project it is in.
  final String? parent;

  /// For an item (`[[`): its id and status (DD-004 point 13).
  final String? itemId;
  final ItemStatus? status;

  /// For a repeat word: the rhythm it means (DD-004 point 14).
  final Rhythm? rhythm;

  /// The calendar line, not a word; see [TokenSuggestion.pickDate].
  final bool pickDate;
}

/// A date as it goes into the text when picked from the calendar:
/// day-month-year, which the date token reads as that exact day, in every
/// language (`!2-10-2026`).
String fixedDateWord(LocalDate date) =>
    '${date.day}-${date.month}-${date.year}';

/// A stored person or tag the list can suggest.
class NamedCandidate {
  const NamedCandidate({
    required this.name,
    this.aliases = const [],
    this.uses = 0,
  });

  final String name;
  final List<String> aliases;

  /// How many items link to it; the most used come first.
  final int uses;
}

/// A live item the `[[` list can suggest (REQ-054): its text, status and
/// the project it is in.
class ItemCandidate {
  const ItemCandidate({
    required this.id,
    required this.rawText,
    required this.status,
    this.project,
  });

  final String id;
  final String rawText;
  final ItemStatus status;
  final String? project;
}

/// The `[[` suggestions (DD-004 point 13): each item shows its title
/// ([titleOf] its text, as lists show it), status and project, and inserts
/// its label ([linkLabelFor]).
List<TokenSuggestion> suggestItems(
  Iterable<ItemCandidate> candidates,
  String Function(String rawText) titleOf,
) => [
  for (final item in candidates)
    if (titleOf(item.rawText) case final title)
      TokenSuggestion(
        insert: linkLabelFor(title),
        label: title,
        itemId: item.id,
        status: item.status,
        parent: item.project,
      ),
];

/// The live projects, archived ones included, and how many live items
/// name each through a `^` token.
typedef ProjectCandidates = ({List<Project> projects, Map<String, int> uses});

/// Where persons, tags and projects come from (DD-004: the token type
/// decides the content of the list, one list for all types).
abstract class TokenCandidateSource {
  Future<List<NamedCandidate>> people();
  Future<List<NamedCandidate>> tags();
  Future<ProjectCandidates> projects();

  /// Live items for `[[` (REQ-054): those matching [query] through the
  /// search index, best first; with an empty query the most recently
  /// captured. Never [excludeId]; at most [limit].
  Future<List<ItemCandidate>> items(
    String query, {
    String? excludeId,
    int limit = 5,
  });
}

final _space = RegExp(r'\s');

/// The suggestions for [query] among [candidates] (REQ-033, PO decision
/// 27-09-2026): at most [max]; names starting with the query before names
/// containing it, then the most used, then alphabetical; case-insensitive
/// with Unicode rules ([nameKey]). When nothing is called exactly [query]
/// and [isValidNew] accepts it, the last line offers it as new.
///
/// A token is one word, so a name with spaces is inserted as one of its
/// one-word aliases, and left out when it has none.
List<TokenSuggestion> suggestNames(
  String query,
  List<NamedCandidate> candidates, {
  required bool Function(String word) isValidNew,
  int max = 5,
}) {
  final key = nameKey(query);
  final ranked = <({TokenSuggestion suggestion, int group, int uses})>[];
  var exact = false;
  for (final candidate in candidates) {
    final names = [candidate.name, ...candidate.aliases];
    final keys = [for (final n in names) nameKey(n)];
    if (keys.contains(key)) exact = true;
    final int group;
    if (keys.any((k) => k.startsWith(key))) {
      group = 0;
    } else if (keys.any((k) => k.contains(key))) {
      group = 1;
    } else {
      continue;
    }
    final insert = _oneWord(candidate, key);
    if (insert == null) continue;
    ranked.add((
      suggestion: TokenSuggestion(insert: insert, label: candidate.name),
      group: group,
      uses: candidate.uses,
    ));
  }
  ranked.sort((a, b) {
    final byGroup = a.group.compareTo(b.group);
    if (byGroup != 0) return byGroup;
    final byUses = b.uses.compareTo(a.uses);
    if (byUses != 0) return byUses;
    return nameKey(a.suggestion.label).compareTo(nameKey(b.suggestion.label));
  });
  final offerNew = key.isNotEmpty && !exact && isValidNew(query.trim());
  final room = offerNew ? max - 1 : max;
  return [
    for (final r in ranked.take(room)) r.suggestion,
    if (offerNew)
      TokenSuggestion(insert: query.trim(), label: query.trim(), isNew: true),
  ];
}

/// The project suggestions for [query] (the text after `^`; REQ-033,
/// DD-004 point 11): projects in use whose name, or `parent/name` path,
/// starts with the query before those whose name contains it, then the most
/// [uses], then alphabetical; at most [max]. Keys as [projectKey]. Each inserts
/// [wordForProject]; a project it cannot name is left out. When no project
/// in use has exactly this key and the query is a valid one-level word, the
/// last line offers to create it.
List<TokenSuggestion> suggestProjects(
  String query,
  List<Project> projects, {
  Map<String, int> uses = const {},
  required bool Function(String word) isValidNew,
  int max = 5,
}) {
  final key = projectKey(query);
  final inUse = [
    for (final p in projects)
      if (!p.isArchived) p,
  ];
  final byId = {for (final p in inUse) p.id: p};
  final ranked = <({TokenSuggestion suggestion, int group, int uses})>[];
  var exact = false;
  for (final project in inUse) {
    final parent = project.parentId == null ? null : byId[project.parentId];
    if (project.parentId != null && parent == null) continue;
    final ownKey = projectKey(project.name);
    final keys = [
      ownKey,
      if (parent != null) projectKey('${parent.name}/${project.name}'),
    ];
    if (ownKey == key) exact = true;
    final int group;
    if (keys.any((k) => k.startsWith(key))) {
      group = 0;
    } else if (ownKey.contains(key)) {
      // Only its own name: a sub-project is not found by a word in the
      // middle of its parent's name.
      group = 1;
    } else {
      continue;
    }
    final word = wordForProject(project, projects);
    if (word == null) continue;
    ranked.add((
      suggestion: TokenSuggestion(
        insert: word,
        label: project.name,
        parent: parent?.name,
      ),
      group: group,
      uses: uses[project.id] ?? 0,
    ));
  }
  ranked.sort((a, b) {
    final byGroup = a.group.compareTo(b.group);
    if (byGroup != 0) return byGroup;
    final byUses = b.uses.compareTo(a.uses);
    if (byUses != 0) return byUses;
    return nameKey(a.suggestion.label).compareTo(nameKey(b.suggestion.label));
  });
  final word = query.trim();
  final offerNew =
      key.isNotEmpty && !exact && !word.contains('/') && isValidNew(word);
  final room = offerNew ? max - 1 : max;
  return [
    for (final r in ranked.take(room)) r.suggestion,
    if (offerNew) TokenSuggestion(insert: word, label: word, isNew: true),
  ];
}

/// The priority suggestions for [query] (the text after `*`): the words of
/// [words] that start with it, high before low; at most [max]. The digits
/// are not offered: they need no help.
List<TokenSuggestion> suggestPriorities(
  String query,
  PriorityVocabulary words, {
  int max = 5,
}) {
  final start = query.toLowerCase();
  return [
    for (final (list, priority) in [
      (words.high, ItemPriority.high),
      (words.low, ItemPriority.low),
    ])
      for (final word in list)
        if (word.startsWith(start))
          TokenSuggestion(insert: word, label: word, priority: priority),
  ].take(max).toList();
}

/// The word to insert for [candidate]: its name when that is one word,
/// else a one-word alias, preferring one that matches [key].
String? _oneWord(NamedCandidate candidate, String key) {
  if (!_space.hasMatch(candidate.name)) return candidate.name;
  final aliases = [
    for (final a in candidate.aliases)
      if (!_space.hasMatch(a.trim()) && a.trim().isNotEmpty) a.trim(),
  ];
  for (final alias in aliases) {
    if (nameKey(alias).startsWith(key)) return alias;
  }
  return aliases.isEmpty ? null : aliases.first;
}
