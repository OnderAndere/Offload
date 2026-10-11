import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/items/completion.dart';
import '../../domain/items/item.dart';
import '../../domain/items/item_repository.dart';
import '../../domain/time/local_date.dart';
import '../../l10n/app_localizations.dart';
import '../messages.dart';

/// The items being completed right now: a second tap (or key) while the
/// first is still written is ignored, so a repeating task never records
/// two times at once (T4.7).
final _completing = <String>{};

/// Whether item [itemId] is being completed right now.
bool isCompleting(String itemId) => _completing.contains(itemId);

/// Completes [item] and says so, with undo in the message (DD-018 points 4
/// and 18). A repeating task records this time and moves on; the message
/// names the next time. Undo puts back exactly what was there: the status
/// (also inbox, waiting or scheduled), the revisit date and the date, and
/// removes the record ([ItemRepository.undoComplete]). Returns false when
/// completing failed or was already under way; a failure is said, and so
/// is a failed undo. [onUndo] runs when the user taps undo, before it is
/// written.
Future<bool> completeWithUndo({
  required ScaffoldMessengerState messenger,
  required AppLocalizations l10n,
  required ItemRepository items,
  required Item item,
  VoidCallback? onUndo,
}) async =>
    await runCompletionWithUndo(
      messenger: messenger,
      l10n: l10n,
      items: items,
      itemId: item.id,
      run: () => items.complete(item.id, today: LocalDate.of(DateTime.now())),
      onUndo: onUndo,
    ) !=
    null;

/// Runs [run] for item [itemId] (completing, *Afronden en herhalen*,
/// *Herhaling stoppen*) and says what it did, with undo through
/// [ItemRepository.undoComplete]; [message] overrides the text. A second
/// call for the same item while the first is still written does nothing,
/// so a double tap never records two times (T4.7). Returns the completion,
/// or null when it failed (said) or was under way. [afterUndo] runs once
/// the undo is written, for example to process the text it put back.
Future<Completion?> runCompletionWithUndo({
  required ScaffoldMessengerState messenger,
  required AppLocalizations l10n,
  required ItemRepository items,
  required String itemId,
  required Future<Completion> Function() run,
  String? message,
  VoidCallback? onUndo,
  Future<void> Function()? afterUndo,
}) async {
  if (!_completing.add(itemId)) return null;
  final keep = keepUndoMessage(messenger.context);
  try {
    final completion = await run();
    final next = completion.nextDue;
    showMessage(
      messenger,
      undoSnackBar(
        message:
            message ??
            (next == null
                ? l10n.itemCompleted
                : l10n.itemCompletedNextTime(next.toLocalDateTime())),
        l10n: l10n,
        keep: keep,
        onUndo: () {
          onUndo?.call();
          unawaited(
            items
                .undoComplete(completion)
                .then((_) => afterUndo?.call())
                .catchError((Object _) {
                  showMessage(
                    messenger,
                    SnackBar(content: Text(l10n.itemChangeFailed)),
                  );
                }),
          );
        },
      ),
    );
    return completion;
  } catch (_) {
    showMessage(messenger, SnackBar(content: Text(l10n.itemChangeFailed)));
    return null;
  } finally {
    _completing.remove(itemId);
  }
}
