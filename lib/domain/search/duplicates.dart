/// The duplicate hint (REQ-053, DD-016; PO decisions 27-09-2026): after
/// saving, a hint when an older item says nearly the same. Never merged or
/// deleted automatically; the hint is computed, never stored.
library;

import '../links/item_link.dart';
import 'search_index.dart';

/// Words that count: at least this many letters or digits.
const _minMeaningfulLength = 3;

/// Share of the shorter item's meaningful words the other must contain.
const _minOverlap = 0.8;

/// And at least this many shared meaningful words.
const _minShared = 3;

final _word = RegExp(r'[\p{L}\p{N}]+', unicode: true);

/// A link `[[…]]` with its text (DD-004 point 13). Broader than the
/// grammar (it also takes `zie[[x]]` and `\[[x]]`), which is harmless here:
/// the words are only compared.
final _link = RegExp(r'\[\[[^\]\r\n]*\]\]');

/// The words of [text] for comparing: lower case, diacritics folded, and
/// token signs (`@`, `#`, `!`) and other punctuation left out. The text of a
/// link `[[…]]` is left out too: it names another item, so an item that
/// links to one does not look like items similar to its target (T10.9).
List<String> comparableWords(String text) => [
  for (final match in _word.allMatches(
    _fold(text.replaceAll(_link, ' ').toLowerCase()),
  ))
    match[0]!,
];

/// Whether [a] and [b] look like the same item (PO decision 27-09-2026):
/// the same words in the same order, or at least 80% of the meaningful
/// words (3+ letters) of the shorter one occur in the other, and that is at
/// least 3 words. Deliberately careful: rather no hint than too many.
bool looksLikeDuplicate(String a, String b) {
  final wordsA = comparableWords(a);
  final wordsB = comparableWords(b);
  if (wordsA.isEmpty || wordsB.isEmpty) return false;
  if (wordsA.join(' ') == wordsB.join(' ')) return true;
  final meaningfulA = _meaningful(wordsA);
  final meaningfulB = _meaningful(wordsB);
  final shorter = meaningfulA.length <= meaningfulB.length
      ? meaningfulA
      : meaningfulB;
  final longer = identical(shorter, meaningfulA) ? meaningfulB : meaningfulA;
  final shared = shorter.where(longer.contains).length;
  return shared >= _minShared && shared >= shorter.length * _minOverlap;
}

Set<String> _meaningful(List<String> words) => {
  for (final word in words)
    if (word.runes.length >= _minMeaningfulLength) word,
};

/// The pairs the user marked as "not the same" (AC REQ-053). A pair is
/// unordered: ignoring (a, b) also ignores (b, a).
abstract class DuplicateDismissals {
  Future<bool> isDismissed(String itemId, String otherItemId);

  /// Stores the choice, synchronised like other user data.
  Future<void> dismiss(String itemId, String otherItemId);
}

/// Finds the older item that the item [itemId] seems to repeat.
class DuplicateFinder {
  const DuplicateFinder(this._index, this._dismissals, [this._links]);

  final SearchIndex _index;
  final DuplicateDismissals _dismissals;

  /// Linked items are no duplicates (T10.9, DD-004 point 13).
  final ItemLinkRepository? _links;

  /// The best matching older live item, done or not, that the user has not
  /// dismissed for this pair; null when there is none. The hint belongs to
  /// the newer item of a pair only (PO decision 27-09-2026), so the older
  /// one shows none.
  Future<SearchHit?> olderDuplicateOf(String itemId, String rawText) async {
    final candidates = await _index.itemsSharingWords(
      rawText,
      excludeId: itemId,
    );
    for (final candidate in candidates) {
      // Version 7 UUIDs sort by creation time.
      if (candidate.id.compareTo(itemId) >= 0) continue;
      if (!looksLikeDuplicate(rawText, candidate.text)) continue;
      if (await _dismissals.isDismissed(itemId, candidate.id)) continue;
      if (await _links?.areLinked(itemId, candidate.id) ?? false) continue;
      return candidate;
    }
    return null;
  }
}

/// Folds common Latin letters with diacritics to their base letter, as the
/// search index does (`remove_diacritics`), so "café" and "cafe" match.
String _fold(String text) {
  final out = StringBuffer();
  for (final rune in text.runes) {
    final char = String.fromCharCode(rune);
    out.write(_folded[char] ?? char);
  }
  return out.toString();
}

final Map<String, String> _folded = {
  for (final (letters, base) in const [
    ('àáâãäåāăą', 'a'),
    ('çćĉċč', 'c'),
    ('ďđ', 'd'),
    ('èéêëēĕėęě', 'e'),
    ('ĝğġģ', 'g'),
    ('ĥħ', 'h'),
    ('ìíîïĩīĭįı', 'i'),
    ('ĵ', 'j'),
    ('ķ', 'k'),
    ('ĺļľŀł', 'l'),
    ('ñńņňŉ', 'n'),
    ('òóôõöøōŏő', 'o'),
    ('ŕŗř', 'r'),
    ('śŝşš', 's'),
    ('ţťŧ', 't'),
    ('ùúûüũūŭůűų', 'u'),
    ('ŵ', 'w'),
    ('ýÿŷ', 'y'),
    ('źżž', 'z'),
    ('ß', 'ss'),
    ('æ', 'ae'),
    ('œ', 'oe'),
  ])
    for (final letter in letters.split('')) letter: base,
};
