import '../tokens/token_processing.dart';
import '../tokens/token_suggestion.dart';

/// One line of the person sheet in triage (DD-018 point 3).
typedef PersonSuggestion = ({String name, bool isNew});

/// The suggestions for [query] among stored people (REQ-033, DD-015): at
/// most [max]; people whose name or alias starts with the query before
/// those that only contain it, then the most used, then by name. Unlike a
/// token, a name here may have spaces ("Jan de Vries"). When nobody is
/// called exactly [query], the last line creates it ("New: …"). An empty
/// query gives the most used people.
List<PersonSuggestion> suggestPeople(
  String query,
  List<NamedCandidate> candidates, {
  int max = 5,
}) {
  final key = nameKey(query);
  final ranked = <({String name, int group, int uses})>[];
  var exact = false;
  for (final candidate in candidates) {
    final keys = [candidate.name, ...candidate.aliases].map(nameKey);
    if (keys.contains(key)) exact = true;
    final group = key.isEmpty || keys.any((k) => k.startsWith(key))
        ? 0
        : keys.any((k) => k.contains(key))
        ? 1
        : null;
    if (group == null) continue;
    ranked.add((name: candidate.name, group: group, uses: candidate.uses));
  }
  ranked.sort((a, b) {
    final byGroup = a.group.compareTo(b.group);
    if (byGroup != 0) return byGroup;
    final byUse = b.uses.compareTo(a.uses);
    if (byUse != 0) return byUse;
    return nameKey(a.name).compareTo(nameKey(b.name));
  });
  final isNew = key.isNotEmpty && !exact;
  return [
    for (final r in ranked.take(isNew ? max - 1 : max))
      (name: r.name, isNew: false),
    if (isNew) (name: query.trim(), isNew: true),
  ];
}

/// The names of the stored people that [words] (the words after `@` in an
/// item's text) stand for, by name or alias, in the order of [words].
List<String> namedPeople(
  List<NamedCandidate> candidates,
  Iterable<String> words,
) {
  final names = <String>[];
  for (final word in words) {
    final key = nameKey(word);
    for (final candidate in candidates) {
      final keys = [candidate.name, ...candidate.aliases].map(nameKey);
      if (keys.contains(key) && !names.contains(candidate.name)) {
        names.add(candidate.name);
      }
    }
  }
  return names;
}

/// [suggestPeople] with the people named in the item's text ([named], from
/// [namedPeople]) first, as far as they match [query] (DD-018 point 7:
/// "Wait for…" asks who, the people in the text first).
List<PersonSuggestion> suggestPeopleNamedFirst(
  String query,
  List<NamedCandidate> candidates,
  List<String> named, {
  int max = 5,
}) {
  final key = nameKey(query);
  final first = [
    for (final candidate in candidates)
      if (named.contains(candidate.name) &&
          [
            candidate.name,
            ...candidate.aliases,
          ].map(nameKey).any((k) => k.contains(key)))
        candidate.name,
  ]..sort((a, b) => named.indexOf(a).compareTo(named.indexOf(b)));
  return [
    for (final name in first) (name: name, isNew: false),
    for (final s in suggestPeople(query, candidates, max: max))
      if (!first.contains(s.name)) s,
  ];
}
