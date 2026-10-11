import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/storage/app_storage.dart';
import '../../domain/people/contacts_from_text.dart';
import '../../domain/people/people_repository.dart';
import '../../domain/tokens/inline_token_registry.dart';
import '../../l10n/app_localizations.dart';
import '../items/item_providers.dart';
import '../messages.dart';
import '../startup/app_storage_provider.dart';
import '../tokens/token_display.dart';

/// Takes phone numbers and email addresses from a saved text into the
/// contact details of the one person it names (REQ-039, T3.6; PO decisions
/// c–e, 02-10-2026): saving is confirming. Only newly typed ones, compared
/// with [TextContactTaker.take]'s `before`; then a message with Undo.
///
/// Made while the screen is alive, used after it is gone (quick capture
/// closes on saving, the item detail when it is left).
class TextContactTaker {
  TextContactTaker._({
    required this.people,
    required this.registry,
    required this.storage,
    required this.messenger,
    required this.l10n,
    required this.keepMessage,
  });

  factory TextContactTaker.of(BuildContext context, WidgetRef ref) =>
      TextContactTaker._(
        people: ref.read(peopleRepositoryProvider),
        registry: ref.read(inlineTokenRegistryProvider),
        storage: ref.read(storageProvider),
        messenger: ScaffoldMessenger.of(context),
        l10n: AppLocalizations.of(context),
        keepMessage: keepUndoMessage(context),
      );

  final PeopleRepository people;
  final InlineTokenRegistry registry;
  final AppStorage storage;
  final ScaffoldMessengerState messenger;
  final AppLocalizations l10n;

  /// See [keepUndoMessage]: read while the screen is alive.
  final bool keepMessage;

  ({String? person, List<TextContact> contacts}) _read(String text) =>
      contactsInText(
        registry.parse(text, parseContextOf(l10n, todayOnDevice())),
        home: storage.phoneCountry,
      );

  /// Adds the details typed in [text] that were not in [before] to the
  /// person [text] names. Nothing when it names no person or several, or
  /// when nothing is new. A failure only says so; the text is saved anyway.
  Future<void> take(String text, {String before = ''}) async {
    final now = _read(text);
    final person = now.person;
    if (person == null) return;
    final fresh = newContacts(
      now.contacts,
      _read(before).contacts,
      home: storage.phoneCountry,
    );
    if (fresh.isEmpty) return;
    try {
      // The same lookup the token processor uses: one person for one name.
      final id = await people.idFor(person);
      await _add(id, person, fresh);
    } catch (_) {
      showMessage(messenger, SnackBar(content: Text(l10n.contactSaveFailed)));
    }
  }

  /// "Link to…": adds [contact] to the person called [name], created when
  /// there is none (DD-015).
  Future<void> link(TextContact contact, String name) async {
    try {
      await _add(await people.idFor(name), name, [contact]);
    } catch (_) {
      showMessage(messenger, SnackBar(content: Text(l10n.contactSaveFailed)));
    }
  }

  Future<void> _add(
    String personId,
    String name,
    List<TextContact> contacts,
  ) async {
    final added = await people.addContactsFromText(personId, contacts);
    if (added.isEmpty) return;
    showMessage(
      messenger,
      undoSnackBar(
        message: l10n.contactsTakenFromText(added.length, name),
        l10n: l10n,
        keep: keepMessage,
        onUndo: () => unawaited(_undo(added)),
      ),
    );
  }

  Future<void> _undo(List<String> ids) async {
    try {
      await people.deleteContactDetails(ids);
    } catch (_) {
      showMessage(
        messenger,
        SnackBar(content: Text(l10n.contactsTakenUndoFailed)),
      );
    }
  }
}
