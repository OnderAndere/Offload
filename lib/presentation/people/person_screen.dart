import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/connections/connection_graph.dart';
import '../../domain/help/help_topics.dart';
import '../../domain/items/item.dart';
import '../../domain/people/person.dart';
import '../../domain/people/person_overview.dart';
import '../../domain/projects/project_overview.dart';
import '../../domain/time/local_date.dart';
import '../../l10n/app_localizations.dart';
import '../help/help_scope.dart';
import '../home/list_keys.dart';
import '../inbox/inbox_card.dart';
import '../items/item_providers.dart';
import '../items/swipe_backgrounds.dart';
import '../items/trash_undo.dart';
import '../overview/connections_entry.dart';
import '../overview/connections_providers.dart';
import '../tokens/token_editor.dart';
import 'people_providers.dart';
import 'person_actions.dart';
import 'person_look.dart';
import 'person_profile.dart';

/// One person (DD-018 point 7): name and aliases, then *Requested by*,
/// *Waiting for* and *Mentioned in*, each with its done items folded. In
/// the People destination back returns to the list ([standalone] false);
/// opened from an item or a search result ([standalone]) it is a screen of
/// its own, and back closes it.
class PersonScreen extends ConsumerStatefulWidget {
  const PersonScreen({
    super.key,
    required this.personId,
    this.standalone = false,
    this.onBack,
  });

  final String personId;
  final bool standalone;

  /// In the right pane of Connections on Windows (DD-018 point 15 (e)):
  /// no back button; Escape goes to the previous focus.
  final VoidCallback? onBack;

  @override
  ConsumerState<PersonScreen> createState() => _PersonScreenState();
}

class _PersonScreenState extends ConsumerState<PersonScreen> {
  /// Cards sent to the trash whose removal the list has not caught up with.
  final _gone = <String>{};

  /// The lists whose done items are unfolded.
  final _showDone = <PersonList>{};

  /// The profile, to save a typed note before a merge.
  final _profile = GlobalKey<PersonProfileState>();

  @override
  void initState() {
    super.initState();
    // For *Recent geopend* in Connections (DD-018 point 15 (c)).
    final recent = ref.read(recentlyOpenedProvider.notifier);
    final opened = NodeRef.person(widget.personId);
    unawaited(Future.microtask(() => recent.opened(opened)));
  }

  void _back() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (widget.standalone) {
      Navigator.of(context).maybePop();
    } else {
      // In the right pane on Windows the shell hands the focus back to the
      // list (DD-018 point 11).
      ref.read(openPersonProvider.notifier).state = null;
    }
  }

  /// Merges this person into another; the screen then shows that person
  /// (DD-018 point 7, Merging).
  Future<void> _merge(Person person, {Person? into}) async {
    // After the merge this person is gone and a note can no longer be
    // saved on them.
    await _profile.currentState?.flush();
    if (!mounted) return;
    final target = await mergePerson(context, ref, person, into: into);
    if (target == null || !mounted) return;
    if (widget.standalone) {
      unawaited(
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => PersonScreen(personId: target, standalone: true),
          ),
        ),
      );
    } else {
      ref.read(openPersonProvider.notifier).state = target;
    }
  }

  Future<void> _rename(Person person) async {
    final mergeWith = await renamePerson(context, ref, person);
    if (mergeWith != null && mounted) await _merge(person, into: mergeWith);
  }

  Future<void> _trash(String id) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    setState(() => _gone.add(id));
    final trashed = await trashWithUndo(
      messenger: messenger,
      l10n: l10n,
      items: ref.read(itemRepositoryProvider),
      id: id,
      onUndo: () {
        if (mounted) setState(() => _gone.remove(id));
      },
    );
    if (!trashed && mounted) setState(() => _gone.remove(id));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final id = widget.personId;
    final person = ref.watch(peopleByIdProvider)[id];
    if (person == null && ref.watch(peopleProvider).hasValue) {
      // Gone meanwhile (through sync, later through merging): back.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _back();
      });
    }
    final desktop = isDesktop(context);
    final linked = ref.watch(personItemsProvider(id)).valueOrNull;
    final now = ref.watch(minuteClockProvider).valueOrNull ?? DateTime.now();
    // As the 1-on-1 preparation: late and overdue first, then the oldest
    // (DD-018 point 11).
    final lists = linked == null
        ? const <PersonList, PersonListItems>{}
        : personLists(
            id,
            [
              for (final item in linked.items)
                if (!_gone.contains(item.id)) item,
            ],
            linked.mentionedIds,
            today: LocalDate.of(now),
          );
    // An item can be in two lists; the keys move over it once.
    final shownIds = <String>{
      for (final MapEntry(key: list, value: part) in lists.entries) ...[
        for (final item in part.open) item.id,
        if (_showDone.contains(list))
          for (final item in part.done) item.id,
      ],
    }.toList();
    // The first card of an item gets the key the list keys look for; a
    // second one (the other list) a key of its own. A screen of its own
    // never: the list it was opened over can still hold the same card.
    final keyed = <String>{};
    Key keyOf(Item item, PersonList list) =>
        !widget.standalone && keyed.add(item.id)
        ? ListKeys.cardKey(item.id)
        : ValueKey((list, item.id));
    final tokens = ref.watch(liveItemTokensProvider).valueOrNull ?? const {};
    final name = person?.name ?? '';

    Widget card(Item item, PersonList list) {
      final child = KeyedSubtree(
        key: keyOf(item, list),
        child: Semantics(
          customSemanticsActions: {
            CustomSemanticsAction(label: l10n.itemMoveToTrash): () =>
                _trash(item.id),
          },
          child: InboxCard(
            item: item,
            tokens: tokens[item.id] ?? const [],
            now: now,
            showStatus: true,
            showInboxStatus: true,
            hidePersonId: id,
          ),
        ),
      );
      if (desktop) return child;
      return Dismissible(
        key: ValueKey((#swipe, list, item.id)),
        direction: DismissDirection.endToStart,
        background: SwipeToTrash(label: l10n.itemMoveToTrash),
        onDismissed: (_) => _trash(item.id),
        child: child,
      );
    }

    final header = theme.textTheme.labelMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      letterSpacing: 0.6,
    );
    final aliases = person?.aliases ?? const <String>[];
    final body = ListView(
      // Room at the bottom so the capture button never hides the last item.
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Row(
            children: [
              PersonAvatar(name: name, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: theme.textTheme.titleLarge),
                    if (aliases.isNotEmpty)
                      Text(
                        l10n.personAliases(aliases.join(', ')),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (person != null) PersonProfile(key: _profile, person: person),
        if (linked != null && lists.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(l10n.personEmpty, style: theme.textTheme.bodyLarge),
            ),
          ),
        for (final MapEntry(key: list, value: part) in lists.entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Semantics(
              header: true,
              child: Row(
                children: [
                  Icon(
                    switch (list) {
                      PersonList.requestedBy => requesterIcon,
                      PersonList.waitingFor => waitingIcon,
                      PersonList.mentionedIn => personIcon,
                    },
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n
                          .personList(list.name, name, part.open.length)
                          .toUpperCase(),
                      style: header,
                    ),
                  ),
                ],
              ),
            ),
          ),
          for (final item in part.open) card(item, list),
          if (part.done.isNotEmpty)
            InkWell(
              onTap: () => setState(
                () => _showDone.contains(list)
                    ? _showDone.remove(list)
                    : _showDone.add(list),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 8, 16, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.projectGroup(
                          ProjectGroup.done.name,
                          part.done.length,
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Icon(
                      _showDone.contains(list)
                          ? Icons.expand_less
                          : Icons.expand_more,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          if (_showDone.contains(list))
            for (final item in part.done) card(item, list),
        ],
      ],
    );

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): _back,
        const SingleActivator(LogicalKeyboardKey.backspace): _back,
      },
      child: HelpScope(
        topic: HelpTopic.person,
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: widget.onBack == null,
            leadingWidth: desktop && !widget.standalone ? 140 : null,
            leading: widget.onBack != null
                ? null
                : desktop && !widget.standalone
                ? TextButton.icon(
                    icon: const Icon(Icons.chevron_left),
                    label: Text(l10n.navPeople),
                    onPressed: _back,
                  )
                : BackButton(onPressed: _back),
            actions: [
              const HelpButton(),
              if (person != null)
                PopupMenuButton<_Action>(
                  tooltip: l10n.personMenuTooltip,
                  onSelected: (action) => switch (action) {
                    _Action.rename => _rename(person),
                    _Action.merge => _merge(person),
                    _Action.connections => showConnectionsOf(
                      context,
                      ref,
                      NodeRef.person(person.id),
                    ),
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: _Action.connections,
                      child: Text(l10n.connectionsShow),
                    ),
                    PopupMenuItem(
                      value: _Action.rename,
                      child: Text(l10n.personRename),
                    ),
                    PopupMenuItem(
                      value: _Action.merge,
                      child: Text(l10n.personMerge),
                    ),
                  ],
                ),
            ],
          ),
          body: ListKeys(ids: shownIds, onTrash: _trash, child: body),
        ),
      ),
    );
  }
}

/// The actions in ⋮ of a person.
enum _Action { connections, rename, merge }
