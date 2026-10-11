import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/projects/project.dart';
import '../../domain/tokens/token_processing.dart';
import '../../l10n/app_localizations.dart';
import '../items/item_providers.dart';
import '../messages.dart';
import '../tokens/token_editor.dart';
import 'project_actions.dart';
import 'project_look.dart';
import 'project_providers.dart';

/// Chooses the project of item [itemId] with the picker and stores it
/// (DD-018 point 6): from the chip in the item detail and on the triage
/// card. Nothing changes when the sheet is closed.
Future<void> chooseProjectFor(
  BuildContext context,
  WidgetRef ref, {
  required String itemId,
  required String? currentId,
  Future<void> Function()? beforeOpen,
}) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  // The item detail saves typed text first: a choice made right after
  // typing `^project` must be the later change (DD-004 point 11).
  await beforeOpen?.call();
  if (!context.mounted) return;
  final choice = await showModalBottomSheet<({String? id})>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _ProjectPicker(currentId: currentId),
  );
  if (choice == null || choice.id == currentId) return;
  try {
    await ref.read(itemRepositoryProvider).setProject(itemId, choice.id);
  } catch (e) {
    showMessage(messenger, SnackBar(content: Text(projectErrorText(e, l10n))));
  }
}

/// One picker for every place (DD-018 point 6): a filter field, *No
/// project*, the projects in use with their sub-projects indented, and a
/// new project, which takes the typed text as its name.
class _ProjectPicker extends ConsumerStatefulWidget {
  const _ProjectPicker({required this.currentId});

  final String? currentId;

  @override
  ConsumerState<_ProjectPicker> createState() => _ProjectPickerState();
}

class _ProjectPickerState extends ConsumerState<_ProjectPicker> {
  final _filter = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _filter.dispose();
    super.dispose();
  }

  void _choose(String? id) => Navigator.of(context).pop((id: id));

  /// Creates a top-level project called [name] and chooses it; with no
  /// name, the dialog asks for one (and a parent).
  Future<void> _create(String name) async {
    final l10n = AppLocalizations.of(context);
    if (name.trim().isEmpty) {
      final id = await createProject(context, ref);
      if (id != null && mounted) _choose(id);
      return;
    }
    try {
      final id = await ref.read(projectRepositoryProvider).create(name);
      if (mounted) _choose(id);
    } catch (e) {
      if (mounted) setState(() => _error = projectErrorText(e, l10n));
    }
  }

  /// The projects in use, filtered by the text in the field now: top-level
  /// projects with their sub-projects below them (true: indented). A filter
  /// keeps a parent when it or one of its sub-projects matches; a
  /// sub-project whose parent is gone (sync) stands at the top level.
  List<(Project, bool)> _rows() {
    final query = nameKey(_filter.text);
    final inUse = [
      for (final p in ref.read(projectsProvider).valueOrNull ?? <Project>[])
        if (!p.isArchived) p,
    ];
    final tree = ref.read(projectTreeProvider);
    bool matches(Project p) => nameKey(p.name).contains(query);
    bool atTop(Project p) => p.isTopLevel || tree[p.parentId!] == null;
    final rows = <(Project, bool)>[];
    for (final top in inUse.where(atTop)) {
      final subs = [
        for (final s in inUse)
          if (s.parentId == top.id && (query.isEmpty || matches(s))) s,
      ];
      if (query.isNotEmpty && !matches(top) && subs.isEmpty) continue;
      rows.add((top, false));
      for (final s in subs) {
        rows.add((s, true));
      }
    }
    return rows;
  }

  /// Enter: the first project that matches the text itself (a parent shown
  /// for its sub-project does not count), otherwise a new project.
  void _submit() {
    final query = nameKey(_filter.text);
    final typed = _filter.text.trim();
    if (query.isNotEmpty) {
      for (final (project, _) in _rows()) {
        if (nameKey(project.name).contains(query)) {
          _choose(project.id);
          return;
        }
      }
    }
    if (typed.isNotEmpty) _create(typed);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Watched here, read in [_rows]: a change of the projects rebuilds.
    ref.watch(projectsProvider);
    final tree = ref.watch(projectTreeProvider);
    final query = nameKey(_filter.text);
    final rows = _rows();
    final exact = tree.projects.any(
      (p) => p.isTopLevel && !p.isArchived && nameKey(p.name) == query,
    );
    final typed = _filter.text.trim();
    final theme = Theme.of(context);
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
                l10n.projectPickerTitle,
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
                  hintText: l10n.projectPickerHint,
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  errorText: _error,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() => _error = null),
                onSubmitted: (_) => _submit(),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  if (query.isEmpty)
                    _Option(
                      icon: Icons.block,
                      text: l10n.projectNone,
                      selected: widget.currentId == null,
                      onTap: () => _choose(null),
                    ),
                  for (final (project, indent) in rows)
                    _Option(
                      icon: indent ? null : projectIcon,
                      indent: indent,
                      text: project.name,
                      tooltip: projectPathOf(project, tree, l10n),
                      selected: project.id == widget.currentId,
                      onTap: () => _choose(project.id),
                    ),
                  const Divider(height: 1),
                  _Option(
                    icon: Icons.add,
                    text: typed.isEmpty || exact
                        ? l10n.projectNewEllipsis
                        : l10n.projectNewNamed(typed),
                    accent: true,
                    onTap: () => _create(exact ? '' : typed),
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

class _Option extends StatelessWidget {
  const _Option({
    required this.text,
    required this.onTap,
    this.icon,
    this.indent = false,
    this.selected = false,
    this.accent = false,
    this.tooltip,
  });

  final String text;
  final VoidCallback onTap;
  final IconData? icon;
  final bool indent;
  final bool selected;
  final bool accent;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tile = ListTile(
      contentPadding: EdgeInsetsDirectional.only(
        start: indent ? 56 : 16,
        end: 16,
      ),
      leading: icon == null ? null : Icon(icon),
      title: Text(
        text,
        style: accent
            ? TextStyle(color: colors.primary, fontWeight: FontWeight.w600)
            : null,
      ),
      trailing: selected ? const Icon(Icons.check) : null,
      selected: selected,
      onTap: onTap,
    );
    return tooltip == null ? tile : Tooltip(message: tooltip!, child: tile);
  }
}

/// The project of an item as a chip that opens the picker (DD-018 point
/// 6): the third chip in the item detail, next to status and type, and the
/// chip on the triage card. An archived project still shows, marked.
class ItemProjectChip extends ConsumerWidget {
  const ItemProjectChip({
    super.key,
    required this.itemId,
    required this.projectId,
    this.beforeOpen,
  });

  final String itemId;
  final String? projectId;

  /// Runs before the picker opens; see [chooseProjectFor].
  final Future<void> Function()? beforeOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tree = ref.watch(projectTreeProvider);
    final project = projectId == null ? null : tree[projectId!];
    final label = switch (project) {
      null => l10n.projectNone,
      Project(isArchived: true) => l10n.projectArchivedName(project.name),
      _ => project.name,
    };
    final path = project == null ? null : projectPathOf(project, tree, l10n);
    return Tooltip(
      message: path ?? l10n.projectChipTooltip,
      child: Semantics(
        label: l10n.tokenChipSemantics(l10n.projectKind, path ?? label),
        hint: l10n.projectChipTooltip,
        button: true,
        excludeSemantics: true,
        child: ActionChip(
          avatar: const Icon(projectIcon, size: 18),
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
              const Icon(Icons.arrow_drop_down, size: 18),
            ],
          ),
          onPressed: () => chooseProjectFor(
            context,
            ref,
            itemId: itemId,
            currentId: projectId,
            beforeOpen: beforeOpen,
          ),
        ),
      ),
    );
  }
}
