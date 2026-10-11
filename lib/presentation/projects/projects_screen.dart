import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/help/help_topics.dart';
import '../../domain/projects/project.dart';
import '../../domain/projects/project_overview.dart';
import '../../l10n/app_localizations.dart';
import '../help/help_scope.dart';
import '../home/destination_actions.dart';
import '../home/item_panes.dart';
import '../theme/design_tokens.dart';
import '../tokens/token_editor.dart';
import 'project_actions.dart';
import 'project_look.dart';
import 'project_providers.dart';
import 'project_screen.dart';

/// The Projects destination (DD-011, DD-018 point 6): the project list, or
/// the project opened from it in its place.
class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final open = ref.watch(openProjectProvider);
    if (open != null) {
      return ProjectScreen(key: ValueKey(open.id), projectId: open.id);
    }
    return const _ProjectList();
  }
}

/// *Without project* first, then the projects in use with their
/// sub-projects indented, each with its open and overdue items; the
/// archived ones folded at the bottom (DD-018 point 6).
class _ProjectList extends ConsumerStatefulWidget {
  const _ProjectList();

  @override
  ConsumerState<_ProjectList> createState() => _ProjectListState();
}

class _ProjectListState extends ConsumerState<_ProjectList> {
  final _ownFocus = FocusNode();
  bool _showArchived = false;

  /// The row chosen with ↑/↓ on Windows.
  int? _highlight;

  @override
  void dispose() {
    _ownFocus.dispose();
    super.dispose();
  }

  void _open(String? id) =>
      ref.read(openProjectProvider.notifier).state = OpenProject(id);

  KeyEventResult _onKey(List<String?> targets, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowUp) {
      final at = _highlight ?? -1;
      final next = key == LogicalKeyboardKey.arrowDown
          ? (at + 1).clamp(0, targets.length - 1)
          : (at <= 0 ? 0 : at - 1);
      setState(() => _highlight = next);
      return KeyEventResult.handled;
    }
    final enter =
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter;
    if (enter && _highlight != null && _highlight! < targets.length) {
      _open(targets[_highlight!]);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final projects = ref.watch(projectsProvider).valueOrNull ?? <Project>[];
    final counts = ref.watch(projectCountsProvider);
    final inUse = [
      for (final p in projects)
        if (!p.isArchived) p,
    ];
    final archived = [
      for (final p in projects)
        if (p.isArchived &&
            (p.isTopLevel ||
                !(projects
                    .firstWhere((q) => q.id == p.parentId, orElse: () => p)
                    .isArchived)))
          p,
    ];
    // The rows in the order on screen, with what opening them opens.
    // A sub-project whose parent is gone (sync) stands at the top level.
    final live = {for (final p in projects) p.id};
    bool atTop(Project p) => p.isTopLevel || !live.contains(p.parentId);
    final rows = <(Project?, bool)>[(null, false)];
    for (final top in inUse.where(atTop)) {
      rows.add((top, false));
      for (final sub in inUse.where((p) => p.parentId == top.id)) {
        rows.add((sub, true));
      }
    }
    final visibleArchived = _showArchived ? archived : const <Project>[];
    final targets = [
      for (final (p, _) in rows) p?.id,
      for (final p in visibleArchived) p.id,
    ];

    Widget row(Project? project, bool indent, int index) => _ProjectRow(
      project: project,
      indent: indent,
      count: project == null || !project.isArchived
          ? counts[project?.id]
          : null,
      highlighted: _highlight == index,
      onTap: () => _open(project?.id),
    );

    final list = ListView(
      // Room at the bottom so the capture button never hides the last row.
      padding: const EdgeInsets.only(top: 4, bottom: 96),
      children: [
        for (final (index, (project, indent)) in rows.indexed)
          row(project, indent, index),
        if (inUse.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Text(
              l10n.projectsEmpty,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        if (archived.isNotEmpty)
          ListTile(
            title: Text(l10n.projectsArchived(archived.length)),
            trailing: Icon(
              _showArchived ? Icons.expand_less : Icons.expand_more,
            ),
            onTap: () => setState(() => _showArchived = !_showArchived),
          ),
        for (final (index, project) in visibleArchived.indexed)
          row(project, false, rows.length + index),
      ],
    );
    return HelpScope(
      topic: HelpTopic.projects,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.navProjects),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: l10n.projectsNew,
              onPressed: () => createProject(context, ref),
            ),
            ...destinationActions(context),
            const HelpButton(),
          ],
        ),
        body: isDesktop(context)
            ? Focus(
                focusNode: ItemPanes.maybeOf(context)?.listFocus ?? _ownFocus,
                autofocus: true,
                onKeyEvent: (_, event) => _onKey(targets, event),
                child: list,
              )
            : list,
      ),
    );
  }
}

/// One row of the project list: *Without project* (dashed, it is not a
/// project) or a project, with its counts.
class _ProjectRow extends StatelessWidget {
  const _ProjectRow({
    required this.project,
    required this.indent,
    required this.count,
    required this.highlighted,
    required this.onTap,
  });

  /// Null for *Without project*.
  final Project? project;
  final bool indent;
  final ProjectCount? count;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final project = this.project;
    final open = count?.open ?? 0;
    final overdue = count?.overdue ?? 0;
    final name = project?.name ?? l10n.projectsWithout;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: colors.onSurfaceVariant,
    );
    final archived = project?.isArchived ?? false;
    return Semantics(
      button: true,
      label: [
        name,
        if (count != null) l10n.projectsOpenCount(open),
        if (overdue > 0) l10n.projectsOverdueCount(overdue),
      ].join(', '),
      excludeSemantics: true,
      child: Card(
        margin: EdgeInsetsDirectional.fromSTEB(indent ? 40 : 12, 3, 12, 3),
        color: highlighted
            ? colors.secondaryContainer
            : project == null || archived
            ? Colors.transparent
            : null,
        elevation: project == null || archived ? 0 : null,
        shape: project == null
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: colors.outlineVariant),
              )
            : null,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                if (!indent) ...[
                  Icon(
                    project == null ? Icons.inbox_outlined : projectIcon,
                    size: 20,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: indent || archived ? FontWeight.w400 : null,
                      color: archived ? colors.onSurfaceVariant : null,
                    ),
                  ),
                ),
                if (overdue > 0) ...[
                  Icon(
                    Icons.warning_amber,
                    size: 16,
                    color: attentionTextColor,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '$overdue', // l10n-ignore: a number
                    style: muted?.copyWith(color: attentionTextColor),
                  ),
                  const SizedBox(width: 12),
                ],
                if (count != null)
                  Text(
                    '$open', // l10n-ignore: a number
                    style: muted,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
