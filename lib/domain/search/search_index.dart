/// Full-text search over items and people (REQ-011, DD-016).
library;

/// What a search hit refers to.
enum SearchEntity { item, person }

/// One search result: which entity, how well it matches, and what to show.
class SearchHit {
  const SearchHit({
    required this.entity,
    required this.id,
    required this.rank,
    this.title,
    this.text = '',
  });

  final SearchEntity entity;

  /// UUID of the item or person.
  final String id;

  /// Relevance from `bm25`: lower is better.
  final double rank;

  /// The item's title, if it has one, or the person's name.
  final String? title;

  /// The item's text as captured, or the person's note (may be empty).
  final String text;

  @override
  bool operator ==(Object other) =>
      other is SearchHit &&
      other.entity == entity &&
      other.id == id &&
      other.rank == rank &&
      other.title == title &&
      other.text == text;

  @override
  int get hashCode => Object.hash(entity, id, rank, title, text);

  @override
  String toString() => 'SearchHit(${entity.name}, $id, $rank)';
}

/// The search index. Indexing always happens after saving, never during
/// (hard rule 7, REQ-001), so a just-saved item can take a moment to show up.
abstract class SearchIndex {
  /// Live items and people matching every word of [query], best first; a
  /// hit in a title or name ranks above one in the text. Case and
  /// diacritics do not matter, and each word also matches the start of a
  /// longer word (AC REQ-011). Empty when [query] has no searchable word.
  Future<List<SearchHit>> search(String query, {int limit = 50});

  /// Live items that share at least one word with [text], best first,
  /// without the item [excludeId]: the candidates for the duplicate hint
  /// (REQ-053). Whole words only, no prefixes.
  Future<List<SearchHit>> itemsSharingWords(
    String text, {
    String? excludeId,
    int limit = 20,
  });

  /// Indexes everything changed since the last time. Safe to call at any
  /// moment; an entry that fails stays queued for the next run.
  Future<void> processPending();

  /// Empties the index and fills it again from the saved data.
  Future<void> rebuild();
}

final _searchable = RegExp(r'[\p{L}\p{N}]', unicode: true);
final _whitespace = RegExp(r'\s+');

/// An FTS5 `MATCH` expression for items sharing any word with [text], or
/// null when [text] has no word. Only the first [maxWords] distinct words
/// are used, so a long text keeps the query small.
String? ftsAnyWordExpression(String text, {int maxWords = 32}) {
  final words = {
    for (final word in text.split(_whitespace))
      for (final part in _wordParts.allMatches(word)) part[0]!,
  }.take(maxWords);
  if (words.isEmpty) return null;
  return words.map((w) => '"$w"').join(' OR ');
}

final _wordParts = RegExp(r'[\p{L}\p{N}]+', unicode: true);

/// The FTS5 `MATCH` expression for what the user typed, or null when there
/// is no word to search for.
///
/// Every word becomes a quoted prefix term (`"keur"*`), so FTS5 operators
/// and punctuation in the input are plain text and never a syntax error.
/// Words without a letter or digit (`#`, `-`) are left out.
String? ftsMatchExpression(String query) {
  final terms = [
    for (final word in query.split(_whitespace))
      if (_searchable.hasMatch(word)) '"${word.replaceAll('"', '""')}"*',
  ];
  return terms.isEmpty ? null : terms.join(' ');
}
