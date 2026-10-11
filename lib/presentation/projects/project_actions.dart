import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/projects/project.dart';
import '../../l10n/app_localizations.dart';
import '../messages.dart';
import 'project_look.dart';
import 'project_providers.dart';

/// Asks for the name (and the parent) of a new project and creates it
/// (DD-018 point 6). Returns its id, or null when the dialog was closed.
Future<String?> createProject(
  BuildContext context,
  WidgetRef ref, {
  String name = '',
  String? parentId,
}) {
  final l10n = AppLocalizations.of(context);
  final parents = [
    for (final p in ref.read(projectsProvider).valueOrNull ?? const <Project>[])
      if (p.isTopLevel && !p.isArchived) p,
  ];
  return showDialog<String>(
    context: context,
    builder: (_) => _NameDialog(
      title: l10n.projectsNew,
      confirm: l10n.projectCreate,
      initialName: name,
      parents: parents,
      initialParent: parentId,
      submit: (name, parent) =>
          ref.read(projectRepositoryProvider).create(name, parentId: parent),
    ),
  );
}

/// Asks for a new name for [project] and renames it.
Future<void> renameProject(
  BuildContext context,
  WidgetRef ref,
  Project project,
) {
  final l10n = AppLocalizations.of(context);
  return showDialog<String>(
    context: context,
    builder: (_) => _NameDialog(
      title: l10n.projectRenameTitle,
      confirm: l10n.projectSave,
      initialName: project.name,
      submit: (name, _) async {
        await ref.read(projectRepositoryProvider).rename(project.id, name);
        return project.id;
      },
    ),
  );
}

/// Asks where [project] goes: the top level or under a top-level project
/// in use (two levels, DD-018 point 6).
Future<void> moveProject(
  BuildContext context,
  WidgetRef ref,
  Project project,
) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final tree = ref.read(projectTreeProvider);
  final options = <(String?, String)>[
    if (!project.isTopLevel) (null, l10n.projectTopLevel),
    // A project with sub-projects stays at the top level.
    if (tree.childrenOf(project.id).isEmpty)
      for (final p in tree.projects.toList()..sort(_byName))
        if (p.isTopLevel &&
            !p.isArchived &&
            p.id != project.id &&
            p.id != project.parentId)
          (p.id, p.name),
  ];
  final choice = await showDialog<({String? parentId})>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(l10n.projectMoveTitle),
      children: [
        for (final (id, name) in options)
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop((parentId: id)),
            child: Row(
              children: [
                Icon(id == null ? Icons.vertical_align_top : projectIcon),
                const SizedBox(width: 12),
                Expanded(child: Text(name)),
              ],
            ),
          ),
        if (options.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(l10n.projectErrorTooDeep),
          ),
      ],
    ),
  );
  if (choice == null) return;
  try {
    await ref.read(projectRepositoryProvider).move(project.id, choice.parentId);
  } catch (e) {
    showMessage(messenger, SnackBar(content: Text(projectErrorText(e, l10n))));
  }
}

/// Archives [project] with an undo in the message; returns whether it was
/// archived.
Future<bool> archiveProject(
  BuildContext context,
  WidgetRef ref,
  Project project,
) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final keep = keepUndoMessage(context);
  final projects = ref.read(projectRepositoryProvider);
  try {
    await projects.archive(project.id);
  } catch (e) {
    showMessage(messenger, SnackBar(content: Text(projectErrorText(e, l10n))));
    return false;
  }
  showMessage(
    messenger,
    undoSnackBar(
      message: l10n.projectArchived,
      l10n: l10n,
      keep: keep,
      onUndo: () => projects.restoreFromArchive(project.id).catchError((_) {}),
    ),
  );
  return true;
}

/// Brings [project] back from the archive.
Future<void> restoreProject(
  BuildContext context,
  WidgetRef ref,
  Project project,
) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  try {
    await ref.read(projectRepositoryProvider).restoreFromArchive(project.id);
    showMessage(messenger, SnackBar(content: Text(l10n.projectRestored)));
  } catch (e) {
    showMessage(messenger, SnackBar(content: Text(projectErrorText(e, l10n))));
  }
}

/// Asks for confirmation, deletes [project] and offers undo (DD-018 point
/// 6): its items stay, its sub-projects move to the top level. Returns
/// whether it was deleted.
Future<bool> deleteProject(
  BuildContext context,
  WidgetRef ref,
  Project project,
) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final keep = keepUndoMessage(context);
  final sure = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.projectDeleteTitle(project.name)),
      content: Text(l10n.projectDeleteBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.projectCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.projectDelete),
        ),
      ],
    ),
  );
  if (sure != true) return false;
  final projects = ref.read(projectRepositoryProvider);
  try {
    final deletion = await projects.delete(project.id);
    var undone = false;
    showMessage(
      messenger,
      undoSnackBar(
        message: l10n.projectDeleted,
        l10n: l10n,
        keep: keep,
        onUndo: () {
          // Once: the undo is a single step.
          if (undone) return;
          undone = true;
          projects.undoDelete(deletion).catchError((_) {});
        },
      ),
    );
    return true;
  } catch (e) {
    showMessage(messenger, SnackBar(content: Text(projectErrorText(e, l10n))));
    return false;
  }
}

int _byName(Project a, Project b) =>
    a.name.toLowerCase().compareTo(b.name.toLowerCase());

/// A name field, and for a new project the parent; the refusal of the
/// store shows under the field (DD-018 point 6).
class _NameDialog extends StatefulWidget {
  const _NameDialog({
    required this.title,
    required this.confirm,
    required this.initialName,
    required this.submit,
    this.parents,
    this.initialParent,
  });

  final String title;
  final String confirm;
  final String initialName;

  /// The top-level projects to choose a parent from; null: no choice.
  final List<Project>? parents;
  final String? initialParent;

  /// Stores the change; returns the project id.
  final Future<String> Function(String name, String? parentId) submit;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _name = TextEditingController(text: widget.initialName)
    ..selection = TextSelection(
      baseOffset: 0,
      extentOffset: widget.initialName.length,
    );
  late String? _parent = widget.initialParent;
  String? _error;
  bool _busy = false;

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
    });
    try {
      final id = await widget.submit(_name.text, _parent);
      if (mounted) navigator.pop(id);
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = projectErrorText(e, l10n);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final parents = widget.parents;
    return AlertDialog(
      title: Text(widget.title),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 280, maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.projectNameLabel,
                errorText: _error,
                errorMaxLines: 3,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _submit(),
            ),
            if (parents != null && parents.isNotEmpty) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                initialValue: _parent,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.projectParentLabel,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    child: Text(
                      l10n.projectTopLevel,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  for (final p in parents)
                    DropdownMenuItem(
                      value: p.id,
                      child: Text(p.name, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (value) => setState(() => _parent = value),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.projectCancel),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: Text(widget.confirm),
        ),
      ],
    );
  }
}
