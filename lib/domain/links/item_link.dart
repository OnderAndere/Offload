import '../items/item_enums.dart';
import '../tokens/token_processing.dart';

/// How long the text put between `[[` and `]]` may be, in characters
/// (PO decision 03-10-2026, DD-004 point 13 (f)).
const linkLabelMax = 60;

final _spaces = RegExp(r'\s+');

/// The text a link to an item with the title [title] gets between its
/// brackets: the title as one line, cut at a word boundary after about
/// [linkLabelMax] characters with "…". Square brackets become round ones,
/// so the label always reads back as this one link (`Notities [concept]`
/// would otherwise end the link early); the chip shows the real title.
String linkLabelFor(String title) {
  var label = title
      .replaceAll(_spaces, ' ')
      .replaceAll('[', '(')
      .replaceAll(']', ')')
      .trim();
  if (label.length <= linkLabelMax) return label;
  var cut = label.lastIndexOf(' ', linkLabelMax);
  if (cut <= 0) {
    cut = linkLabelMax;
    // Never between the two halves of an emoji.
    final unit = label.codeUnitAt(cut - 1);
    if (unit >= 0xD800 && unit <= 0xDBFF) cut--;
  }
  label = label.substring(0, cut).trimRight();
  return '$label…';
}

/// The key labels and titles are compared by: without case (Unicode, as
/// [nameKey]) and with every run of white space as one space, so a change
/// of case or spacing in the text keeps the link (DD-004 point 13).
String linkKey(String label) => nameKey(label).replaceAll(_spaces, ' ');

/// An item a link points to, or that points here: what a chip or a row
/// shows of it (DD-018 point 14).
class LinkedItem {
  const LinkedItem({
    required this.itemId,
    required this.rawText,
    required this.status,
    required this.trashed,
    this.label,
  });

  final String itemId;

  /// Its text: the chip or row shows its current title.
  final String rawText;
  final ItemStatus status;

  /// In the trash: the chip says so; a backlink is left out.
  final bool trashed;

  /// For a link from this item: the label in its text.
  final String? label;
}

/// A live `[[…]]` link from one live item to another: a line in
/// Connections (DD-018 point 15).
typedef ItemLinkPair = ({String from, String to});

/// Links between items (REQ-054, DD-004 point 13). Chosen links are written
/// with the text by the item repository; the token processor removes those
/// whose label left the text. This reads them.
abstract class ItemLinkRepository {
  /// The items the live links of item [itemId] point to, by label, in the
  /// trash or not.
  Stream<List<LinkedItem>> watchLinksFrom(String itemId);

  /// The live items with a live link to item [itemId]: its backlinks.
  Stream<List<LinkedItem>> watchBacklinks(String itemId);

  /// Every live `[[…]]` link whose two items are both outside the trash
  /// (Connections, DD-018 point 15). Emits again on every change of the
  /// links or the items.
  Stream<List<ItemLinkPair>> watchAllLinks();

  /// Whether items [a] and [b] are linked, in either direction.
  Future<bool> areLinked(String a, String b);

  /// The labels (by [linkKey]) of the `[[…]]` in the saved text of item
  /// [itemId] that processing found no item for: their chip says "no
  /// item" (DD-004 point 13 (b)).
  Stream<Set<String>> watchUnlinkedLabels(String itemId);
}
