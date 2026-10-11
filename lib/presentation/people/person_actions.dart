import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/people/person.dart';
import '../../domain/time/local_date.dart';
import '../../domain/tokens/token_types.dart';
import '../../l10n/app_localizations.dart';
import '../home/destination.dart';
import '../home/item_panes.dart';
import '../items/item_providers.dart';
import '../messages.dart';
import '../review/review_providers.dart';
import '../tokens/token_display.dart';
import '../tokens/token_editor.dart';
import '../triage/person_sheet.dart';
import 'people_providers.dart';
import 'person_look.dart';
import 'person_screen.dart';

/// Opens person [id] (DD-018 point 7). With two panes (wide Windows) the
/// app switches to *People*: the balance in the list pane, the person in
/// the right pane in place of the item (point 11); otherwise the person
/// opens over the current screen, and back returns to it.
void openPerson(BuildContext context, WidgetRef ref, String id) {
  if (ItemPanes.find(context) != null) {
    // The weekly review gives way, as for the rail (DD-018 point 8).
    ref.read(weeklyReviewOpenProvider.notifier).state = false;
    ref.read(weeklyReviewWideProvider.notifier).state = false;
    // Through null, so the shell hears it also when [id] is open already
    // (the search field empties for the person).
    ref.read(openPersonProvider.notifier).state = null;
    ref.read(openPersonProvider.notifier).state = id;
    ref.read(destinationProvider.notifier).state = Destination.people;
    return;
  }
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => PersonScreen(personId: id, standalone: true),
    ),
  );
}

/// Opens the person called [name] (an `@name` chip in the item detail);
/// nothing when nobody is called that yet.
Future<void> openPersonNamed(
  BuildContext context,
  WidgetRef ref,
  String name,
) async {
  final id = await ref.read(peopleRepositoryProvider).find(name);
  if (id != null && context.mounted) openPerson(context, ref, id);
}

/// The words after `@` in [text], for the person sheet (DD-018 point 7).
List<String> personWordsIn(String text, WidgetRef ref, AppLocalizations l10n) =>
    [
      for (final match
          in ref
              .read(inlineTokenRegistryProvider)
              .parse(text, parseContextOf(l10n, todayOnDevice())))
        if (match.type is PersonTokenType) match.word,
    ];

/// Asks for a person with the sheet of triage and returns their id, or
/// null when the sheet was closed; `(id: null)` for *Skip*. A new name
/// creates the person (DD-015). With [askExpected] also the optional
/// expected day of a wait (DD-018 point 10 (d)).
Future<({String? id, LocalDate? expected})?> askPerson(
  BuildContext context,
  WidgetRef ref, {
  required String title,
  List<String> namedWords = const [],
  bool askExpected = false,
}) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final choice = await showPersonSheet(
    context,
    title: title,
    namedWords: namedWords,
    askExpected: askExpected,
  );
  if (choice == null) return null;
  final name = choice.name;
  if (name == null) return (id: null, expected: choice.expected);
  try {
    return (
      id: await ref.read(peopleRepositoryProvider).idFor(name),
      expected: choice.expected,
    );
  } catch (_) {
    showMessage(messenger, SnackBar(content: Text(l10n.itemChangeFailed)));
    return null;
  }
}

/// *Wait for…* in the item detail (DD-018 point 7): asks who, then moves
/// item [itemId] to waiting on that person in one change; *Skip* waits
/// without a new person, closing the sheet changes nothing.
Future<void> waitForWithPerson(
  BuildContext context,
  WidgetRef ref, {
  required String itemId,
  required String text,
}) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final choice = await askPerson(
    context,
    ref,
    title: l10n.triageWaitingOn,
    namedWords: personWordsIn(text, ref, l10n),
    askExpected: true,
  );
  if (choice == null) return;
  final items = ref.read(itemRepositoryProvider);
  try {
    await items.waitFor(itemId, choice.id, expected: choice.expected);
  } catch (e) {
    showMessage(messenger, SnackBar(content: Text(personErrorText(e, l10n))));
  }
}

/// Asks for a new name for [person] and renames them; the old name stays
/// an alias (DD-015). When the name is someone else's, the dialog offers
/// merging with them (PO decision 01-10-2026): then this returns that
/// person, and the caller merges.
Future<Person?> renamePerson(
  BuildContext context,
  WidgetRef ref,
  Person person,
) => showDialog<Person>(
  context: context,
  builder: (_) => _RenameDialog(person: person),
);

/// Merges [from] into another person (DD-015, DD-018 point 7): [into], or
/// the one chosen from a list of the others; then a confirmation, the merge,
/// and a message with Undo. Returns the id of the person merged into, or
/// null when nothing was merged.
Future<String?> mergePerson(
  BuildContext context,
  WidgetRef ref,
  Person from, {
  Person? into,
}) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final keep = keepUndoMessage(context);
  final target =
      into ??
      await showModalBottomSheet<Person>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => _MergePicker(from: from),
      );
  if (target == null || !context.mounted) return null;
  final sure = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.personMergeTitle),
      content: Text(l10n.personMergeBody(from.name, target.name)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.personCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.personMergeConfirm),
        ),
      ],
    ),
  );
  if (sure != true) return null;
  final people = ref.read(peopleRepositoryProvider);
  try {
    final merge = await people.merge(from.id, target.id);
    var undone = false;
    showMessage(
      messenger,
      undoSnackBar(
        message: l10n.personMerged(from.name, target.name),
        l10n: l10n,
        keep: keep,
        onUndo: () {
          // Once: the undo is a single step.
          if (undone) return;
          undone = true;
          unawaited(
            people.undoMerge(merge).catchError((Object _) {
              showMessage(
                messenger,
                SnackBar(content: Text(l10n.personMergeUndoFailed)),
              );
            }),
          );
        },
      ),
    );
    return target.id;
  } catch (e) {
    showMessage(messenger, SnackBar(content: Text(personErrorText(e, l10n))));
    return null;
  }
}

/// The other live people with a filter field, as the people list: whom
/// [from] is merged into.
class _MergePicker extends ConsumerStatefulWidget {
  const _MergePicker({required this.from});

  final Person from;

  @override
  ConsumerState<_MergePicker> createState() => _MergePickerState();
}

class _MergePickerState extends ConsumerState<_MergePicker> {
  final _filter = TextEditingController();

  @override
  void dispose() {
    _filter.dispose();
    super.dispose();
  }

  List<Person> _others() {
    final query = _filter.text.trim();
    return [
      for (final p in ref.read(peopleProvider).valueOrNull ?? const <Person>[])
        if (p.id != widget.from.id && (query.isEmpty || p.matches(query))) p,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    // Watched here, read in [_others]: a change of the people rebuilds.
    ref.watch(peopleProvider);
    final others = _others();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                l10n.personMergePickerTitle(widget.from.name),
                style: theme.textTheme.titleMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _filter,
                // A keyboard on a phone would hide half the list.
                autofocus: isDesktop(context),
                decoration: InputDecoration(
                  hintText: l10n.peopleFilterHint,
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
                // Enter takes the only one left; read now, not from the
                // last build (CLAUDE.md, enterText pitfall).
                onSubmitted: (_) {
                  final left = _others();
                  if (left.length == 1) Navigator.of(context).pop(left.single);
                },
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final p in others)
                    ListTile(
                      leading: PersonAvatar(name: p.name),
                      title: Text(p.name),
                      subtitle: p.aliases.isEmpty
                          ? null
                          : Text(
                              l10n.personAliases(p.aliases.join(', ')),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                      onTap: () => Navigator.of(context).pop(p),
                    ),
                  if (others.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _filter.text.trim().isEmpty
                            ? l10n.personMergeNoOthers
                            : l10n.peopleNoMatch,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _RenameDialog extends ConsumerStatefulWidget {
  const _RenameDialog({required this.person});

  final Person person;

  @override
  ConsumerState<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends ConsumerState<_RenameDialog> {
  late final _name = TextEditingController(text: widget.person.name)
    ..selection = TextSelection(
      baseOffset: 0,
      extentOffset: widget.person.name.length,
    );
  String? _error;
  bool _busy = false;

  /// The person whose name was typed: offered to merge with.
  Person? _holder;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    final navigator = Navigator.of(context);
    setState(() {
      _busy = true;
      _error = null;
      _holder = null;
    });
    final people = ref.read(peopleRepositoryProvider);
    // Read now, not from the last build (CLAUDE.md, enterText pitfall).
    final name = _name.text;
    try {
      await people.rename(widget.person.id, name);
      if (mounted) navigator.pop();
    } catch (e) {
      // The name is someone else's: offer to merge with them.
      Person? holder;
      if (e is PersonException && e.problem == PersonProblem.nameTaken) {
        try {
          final id = await people.find(name);
          holder = id == null ? null : ref.read(peopleByIdProvider)[id];
        } catch (_) {
          // Without the lookup there is only the message, no offer.
        }
      }
      if (mounted) {
        setState(() {
          _busy = false;
          _error = personErrorText(e, l10n);
          _holder = holder;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.personRenameTitle),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 280, maxWidth: 400),
        child: TextField(
          controller: _name,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: l10n.personNameLabel,
            helperText: l10n.personRenameKeeps(widget.person.name),
            helperMaxLines: 3,
            errorText: _error,
            errorMaxLines: 3,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        if (_holder case final holder?)
          TextButton(
            onPressed: () => Navigator.of(context).pop(holder),
            child: Text(l10n.personMergeWith(holder.name)),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.personCancel),
        ),
        TextButton(onPressed: _submit, child: Text(l10n.personSave)),
      ],
    );
  }
}
