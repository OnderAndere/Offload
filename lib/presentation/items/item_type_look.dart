import 'package:flutter/material.dart';

import '../../domain/items/item_enums.dart';
import '../../l10n/app_localizations.dart';
import 'item_labels.dart';

/// The icon of an item type: the same on the cards, in the item detail and
/// on the triage buttons (T2.10, DD-018 point 2).
IconData itemTypeIcon(ItemType type) => switch (type) {
  ItemType.task => Icons.check_box_outlined,
  ItemType.idea => Icons.lightbulb_outline,
  ItemType.request => Icons.front_hand_outlined,
  ItemType.note => Icons.description_outlined,
};

/// The type of an item as a chip on its card: icon and name, in the calm
/// style of the other chips, because orange and blue carry a meaning of
/// their own (DD-017). An icon and a word, never a colour alone (REQ-016).
class ItemTypeChip extends StatelessWidget {
  const ItemTypeChip({super.key, required this.type, this.dense = false});

  final ItemType type;

  /// Smaller, for inside a list card.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = l10n.type(type);
    return Semantics(
      label: l10n.tokenChipSemantics(l10n.itemTypeKind, name),
      excludeSemantics: true,
      child: Chip(
        avatar: Icon(itemTypeIcon(type), size: dense ? 16 : 18),
        label: Text(name),
        visualDensity: dense ? VisualDensity.compact : null,
        materialTapTargetSize: dense ? MaterialTapTargetSize.shrinkWrap : null,
        labelPadding: dense ? const EdgeInsetsDirectional.only(end: 4) : null,
      ),
    );
  }
}
