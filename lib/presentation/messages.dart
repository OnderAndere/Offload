import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// How long a message with Undo stays.
const undoMessageDuration = Duration(seconds: 5);

/// Whether an undo message should stay until tapped: only with a screen
/// reader on, because reaching the button then takes longer (REQ-016).
/// Read it before any await; the context may be gone afterwards.
///
/// Only TalkBack sets this: the Flutter Windows embedder never reports
/// accessible navigation, so with Narrator the message still leaves (T8.2).
bool keepUndoMessage(BuildContext context) =>
    MediaQuery.maybeAccessibleNavigationOf(context) ?? false;

/// A message with an Undo button (AC REQ-010, DD-018). Flutter keeps a
/// message with an action on screen until it is tapped (`persist`); here it
/// goes away by itself after [undoMessageDuration], so it never lingers,
/// unless [keep] (see [keepUndoMessage]).
SnackBar undoSnackBar({
  required String message,
  required AppLocalizations l10n,
  required bool keep,
  required VoidCallback onUndo,
}) => SnackBar(
  content: Text(message),
  duration: undoMessageDuration,
  persist: keep,
  action: SnackBarAction(label: l10n.itemUndo, onPressed: onUndo),
);

/// Shows [message] in place of whatever message is showing or waiting.
///
/// Flutter queues messages. A message that stays until tapped (an undo
/// message with a screen reader on) would then hide every later one behind
/// it, the undo of the last swipe included, so a new message always
/// replaces the previous ones instead (REQ-016, AC REQ-010).
void showMessage(ScaffoldMessengerState messenger, SnackBar message) {
  messenger
    ..clearSnackBars()
    ..showSnackBar(message);
}
