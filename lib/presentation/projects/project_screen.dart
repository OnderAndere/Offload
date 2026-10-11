import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/connections/connection_graph.dart';
import '../../domain/help/help_topics.dart';
import '../../domain/items/item.dart';
import '../../domain/projects/project.dart';
import '../../domain/projects/project_overview.dart';
import '../../domain/snapshots/snapshot.dart';
import '../../l10n/app_localizations.dart';
import '../help/help_scope.dart';
import '../home/list_keys.dart';
import '../inbox/inbox_card.dart';
import '../items/item_providers.dart';
import '../items/swipe_backgrounds.dart';
import '../items/trash_undo.dart';
import '../overview/connections_entry.dart';
import '../overview/connections_providers.dart';
import '../snapshots/where_was_i.dart';
import '../tokens/token_editor.dart';
import 'project_actions.dart';
import 'project_providers.dart';

/// One project, opened from the project list (DD-018 point 6): its
/// sub-projects as chips at the top, then its own items by status, *Done*
/// folded. [projectId] null is *Without project*. Back (the arrow, Android
/// Back, and on Windows Escape or Backspace in the list) returns to the
/// project list.
class ProjectScreen extends ConsumerStatefulWidget {
  const ProjectScreen({super.key, required this.projectId, this.onBack});

  final String? projectId;

  /// In the right pane of Connections on Windows (DD-018 point 15 (e)):
  /// no back button; Escape goes to the previous focus.
  final VoidCallback? onBack;

  @override
  ConsumerState<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends ConsumerState<ProjectScreen> {
  /// Cards sent to the trash whose removal the list has not caught up with.
  final _gone = <String>{};
  bool _showDone = false;

  @override
  void initState() {
    super.initState();
    // For *Recent geopend* in Connections (DD-018 point 15 (c)).
    final id = widget.projectId;
    if (id == null) return;
    final recent = ref.read(recentlyOpenedProvider.notifier);
    unawaited(Future.microtask(() => recent.opened(NodeRef.project(id))));
  }

  void _back() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else {
      ref.read(openProjectProvider.notifier).state = null;
    }
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

  Future<void> _act(_Action action, Project project) async {
    switch (action) {
      case _Action.rename:
        await renameProject(context, ref, project);
      case _Action.move:
        await moveProject(context, ref, project);
      case _Action.archive:
        if (await archiveProject(context, ref, project)) _back();
      case _Action.restore:
        await restoreProject(context, ref, project);
      case _Action.delete:
        if (await deleteProject(context, ref, project)) _back();
      case _Action.connections:
        showConnectionsOf(context, ref, NodeRef.project(project.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final tree = ref.watch(projectTreeProvider);
    final id = widget.projectId;
    final project = id == null ? null : tree[id];
    final loaded = ref.watch(projectsProvider).hasValue;
    if (id != null && project == null && loaded) {
      // Deleted meanwhile (here, or through sync): back to the list.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _back();
      });
    }
    final desktop = isDesktop(context);
    final title = project?.name ?? l10n.projectsWithout;
    final subs = [
      if (id != null)
        for (final p in tree.childrenOf(id))
          if (!p.isArchived) p,
    ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final items = [
      for (final item
          in ref.watch(projectItemsProvider(id)).valueOrNull ?? <Item>[])
        if (!_gone.contains(item.id)) item,
    ];
    final groups = groupProjectItems(items);
    final shownIds = [
      for (final MapEntry(key: group, value: list) in groups.entries)
        if (group != ProjectGroup.done || _showDone)
          for (final item in list) item.id,
    ];
    final now = ref.watch(minuteClockProvider).valueOrNull ?? DateTime.now();
    final tokens = ref.watch(liveItemTokensProvider).valueOrNull ?? const {};

    Widget card(Item item) {
      final child = KeyedSubtree(
        key: ListKeys.cardKey(item.id),
        child: Semantics(
          customSemanticsActions: {
            CustomSemanticsAction(label: l10n.itemMoveToTrash): () =>
                _trash(item.id),
          },
          child: InboxCard(
            item: item,
            tokens: tokens[item.id] ?? const [],
            now: now,
            showStatus: false,
            showProject: false,
          ),
        ),
      );
      if (desktop) return child;
      return Dismissible(
        key: ValueKey(item.id),
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
    final body = ListView(
      // Room at the bottom so the capture button never hides the last item.
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        // "Where was I": the card while a note is open, and the button
        // under the title (DD-018 point 13).
        if (project != null && !project.isArchived) ...[
          ResumeCard(
            owner: ProjectSnapshotOwner(project.id),
            title: project.name,
            margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: WhereWasIButton(
                owner: ProjectSnapshotOwner(project.id),
                title: project.name,
              ),
            ),
          ),
        ],
        if (subs.isNotEmpty)
          Semantics(
            container: true,
            label: l10n.projectSubprojects,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final sub in subs)
                    ActionChip(
                      label: Text(sub.name),
                      onPressed: () =>
                          ref.read(openProjectProvider.notifier).state =
                              OpenProject(sub.id),
                    ),
                ],
              ),
            ),
          ),
        if (groups.isEmpty && subs.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(l10n.projectEmpty, style: theme.textTheme.bodyLarge),
            ),
          ),
        for (final MapEntry(key: group, value: list) in groups.entries) ...[
          if (group == ProjectGroup.done)
            InkWell(
              onTap: () => setState(() => _showDone = !_showDone),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n
                            .projectGroup(group.name, list.length)
                            .toUpperCase(),
                        style: header,
                      ),
                    ),
                    Icon(
                      _showDone ? Icons.expand_less : Icons.expand_more,
                      size: 20,
                    ),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Semantics(
                header: true,
                child: Text(
                  l10n.projectGroup(group.name, list.length).toUpperCase(),
                  style: header,
                ),
              ),
            ),
          if (group != ProjectGroup.done || _showDone)
            for (final item in list) card(item),
        ],
      ],
    );

    final whereWasI = project == null || project.isArchived
        ? null
        : () => unawaited(
            showWhereWasI(
              context,
              ref,
              ProjectSnapshotOwner(project.id),
              title: project.name,
            ),
          );
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): _back,
        const SingleActivator(LogicalKeyboardKey.backspace): _back,
        const SingleActivator(
          LogicalKeyboardKey.keyP,
          control: true,
          shift: true,
        ): ?whereWasI,
      },
      child: HelpScope(
        topic: HelpTopic.project,
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: widget.onBack == null,
            leadingWidth: desktop ? 140 : null,
            leading: widget.onBack != null
                ? null
                : desktop
                ? TextButton.icon(
                    icon: const Icon(Icons.chevron_left),
                    label: Text(l10n.navProjects),
                    onPressed: _back,
                  )
                : BackButton(onPressed: _back),
            title: Text(title),
            actions: [
              const HelpButton(),
              if (project != null)
                PopupMenuButton<_Action>(
                  tooltip: l10n.projectMenuTooltip,
                  onSelected: (action) => _act(action, project),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: _Action.connections,
                      child: Text(l10n.connectionsShow),
                    ),
                    if (project.isArchived)
                      PopupMenuItem(
                        value: _Action.restore,
                        child: Text(l10n.projectRestore),
                      )
                    else ...[
                      PopupMenuItem(
                        value: _Action.rename,
                        child: Text(l10n.projectRename),
                      ),
                      PopupMenuItem(
                        value: _Action.move,
                        child: Text(l10n.projectMove),
                      ),
                      PopupMenuItem(
                        value: _Action.archive,
                        child: Text(l10n.projectArchive),
                      ),
                    ],
                    PopupMenuItem(
                      value: _Action.delete,
                      child: Text(l10n.projectDelete),
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

enum _Action { connections, rename, move, archive, restore, delete }
