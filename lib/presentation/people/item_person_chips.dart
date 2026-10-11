import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/items/item.dart';
import '../../domain/items/item_enums.dart';
import '../../domain/people/person_overview.dart';
import '../../l10n/app_localizations.dart';
import '../items/item_providers.dart';
import '../messages.dart';
import 'people_providers.dart';
import 'person_actions.dart';
import 'person_look.dart';

/// The people of [item] as chips in the item detail (DD-018 point 7): ✋
/// who asked, when it has a requester or is a request, and ⏳ who it waits
/// on, while it waits. [text] is what the text field holds now: the people
/// it names come first in the sheet.
List<Widget> itemPersonChips(Item item, {required String Function() text}) => [
  if (item.requesterId != null || item.type == ItemType.request)
    _ItemPersonChip(item: item, waiting: false, text: text),
  if (isWaitingNow(item))
    _ItemPersonChip(item: item, waiting: true, text: text),
];

enum _Choice { open, change, remove }

class _ItemPersonChip extends ConsumerStatefulWidget {
  const _ItemPersonChip({
    required this.item,
    required this.waiting,
    required this.text,
  });

  final Item item;
  final bool waiting;
  final String Function() text;

  @override
  ConsumerState<_ItemPersonChip> createState() => _ItemPersonChipState();
}

class _ItemPersonChipState extends ConsumerState<_ItemPersonChip> {
  /// Opens the menu for a screen reader, whose tap the chip's semantics
  /// take (REQ-016).
  final _menu = GlobalKey<PopupMenuButtonState<_Choice>>();

  Item get item => widget.item;
  bool get waiting => widget.waiting;
  String Function() get text => widget.text;

  Future<void> _choose(_Choice choice, String? personId) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final items = ref.read(itemRepositoryProvider);
    Future<void> store(String? id) => waiting
        ? items.setWaitingOn(item.id, id)
        : items.setRequester(item.id, id);
    switch (choice) {
      case _Choice.open:
        if (personId != null) openPerson(context, ref, personId);
        return;
      case _Choice.remove:
        try {
          await store(null);
        } catch (e) {
          showMessage(
            messenger,
            SnackBar(content: Text(personErrorText(e, l10n))),
          );
        }
        return;
      case _Choice.change:
        final picked = await askPerson(
          context,
          ref,
          title: waiting ? l10n.triageWaitingOn : l10n.triageWhoAsked,
          namedWords: personWordsIn(text(), ref, l10n),
        );
        // Closed, or skipped: nothing changes.
        final id = picked?.id;
        if (id == null || id == personId) return;
        try {
          await store(id);
        } catch (e) {
          showMessage(
            messenger,
            SnackBar(content: Text(personErrorText(e, l10n))),
          );
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final personId = waiting ? item.waitingOnId : item.requesterId;
    final person = personId == null
        ? null
        : ref.watch(peopleByIdProvider)[personId];
    final kind = waiting ? l10n.personWaitingKind : l10n.personRequesterKind;
    final label =
        person?.name ?? (waiting ? l10n.triageWaitingOn : l10n.triageWhoAsked);
    return PopupMenuButton<_Choice>(
      key: _menu,
      tooltip: kind,
      onSelected: (choice) => _choose(choice, person?.id),
      itemBuilder: (_) => [
        if (person != null)
          PopupMenuItem(
            value: _Choice.open,
            child: Text(l10n.personOpen(person.name)),
          ),
        PopupMenuItem(value: _Choice.change, child: Text(l10n.personChange)),
        if (person != null)
          PopupMenuItem(value: _Choice.remove, child: Text(l10n.personRemove)),
      ],
      child: Semantics(
        label: l10n.tokenChipSemantics(kind, label),
        button: true,
        onTap: () => _menu.currentState?.showButtonMenu(),
        excludeSemantics: true,
        child: Chip(
          avatar: Icon(waiting ? waitingIcon : requesterIcon, size: 18),
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
              const Icon(Icons.arrow_drop_down, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
