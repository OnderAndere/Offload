import 'package:flutter/material.dart';

import '../../domain/items/item.dart';
import '../../domain/items/item_repository.dart';
import '../../l10n/app_localizations.dart';
import '../messages.dart';

/// *Chased* (NL "Nagevraagd", AC REQ-047, T10.1): records a touch on a
/// silent waiting item, so its period starts again. No undo, as *Keep* and
/// *Still waiting* in the weekly review: putting the moment back would be
/// a change too, and every change is a touch (DD-018 point 10).
Future<void> chase({
  required ScaffoldMessengerState messenger,
  required AppLocalizations l10n,
  required ItemRepository items,
  required Item item,
}) async {
  try {
    await items.markReviewed(item.id);
  } catch (_) {
    showMessage(messenger, SnackBar(content: Text(l10n.itemChangeFailed)));
    return;
  }
  showMessage(messenger, SnackBar(content: Text(l10n.nudgeChasedMessage)));
}
