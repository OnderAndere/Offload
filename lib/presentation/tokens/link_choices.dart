import '../../domain/links/item_link.dart';

/// The items chosen from the `[[` suggestion list while typing, by label
/// (DD-004 point 13). The screen saves them with the text, in one
/// transaction; quick capture shows their chips without reading anything
/// (REQ-001).
class LinkChoices {
  final _byKey = <String, ({String label, String itemId})>{};

  /// Remembers that [label] was chosen for item [itemId]; a later choice for
  /// the same label wins.
  void remember(String label, String itemId) =>
      _byKey[linkKey(label)] = (label: label, itemId: itemId);

  /// The item chosen for [label], or null.
  String? itemFor(String label) => _byKey[linkKey(label)]?.itemId;

  /// The choices whose `[[label]]` is in [text], label to item, for
  /// saving.
  Map<String, String> forText(String text) => {
    for (final choice in _byKey.values)
      if (text.contains('[[${choice.label}]]')) // l10n-ignore: the link token
        choice.label: choice.itemId,
  };
}
