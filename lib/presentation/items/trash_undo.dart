import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/items/item_repository.dart';
import '../../l10n/app_localizations.dart';
import '../messages.dart';

/// Moves item [id] to the trash and says so, with undo in the message
/// (AC REQ-010, DD-018). Returns false when the move failed; that is said
/// too. A failed undo says so as well, or the item would seem back.
/// [onUndo] runs when the user taps undo, before the restore is written.
Future<bool> trashWithUndo({
  required ScaffoldMessengerState messenger,
  required AppLocalizations l10n,
  required ItemRepository items,
  required String id,
  VoidCallback? onUndo,
}) async {
  final keep = keepUndoMessage(messenger.context);
  try {
    await items.moveToTrash(id);
  } catch (_) {
    showMessage(messenger, SnackBar(content: Text(l10n.itemChangeFailed)));
    return false;
  }
  showMessage(
    messenger,
    undoSnackBar(
      message: l10n.itemMovedToTrash,
      l10n: l10n,
      keep: keep,
      onUndo: () {
        onUndo?.call();
        unawaited(
          items.restoreFromTrash(id).catchError((Object _) {
            showMessage(
              messenger,
              SnackBar(content: Text(l10n.itemUndoFailed)),
            );
          }),
        );
      },
    ),
  );
  return true;
}
