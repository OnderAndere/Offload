import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/projects/project.dart';
import '../../domain/projects/project_tree.dart';
import '../../l10n/app_localizations.dart';
import 'project_providers.dart';

/// The icon of a project, on chips, rows and in the picker.
const projectIcon = Icons.folder_outlined;

/// The message for a refused project change (DD-018 point 6).
String projectProblemText(ProjectProblem problem, AppLocalizations l10n) =>
    switch (problem) {
      ProjectProblem.emptyName => l10n.projectErrorEmptyName,
      ProjectProblem.nameTaken => l10n.projectErrorNameTaken,
      ProjectProblem.tooDeep => l10n.projectErrorTooDeep,
      ProjectProblem.notAvailable => l10n.projectErrorNotAvailable,
    };

/// The message for any failure of a project change.
String projectErrorText(Object error, AppLocalizations l10n) =>
    error is ProjectException
    ? projectProblemText(error.problem, l10n)
    : l10n.projectChangeFailed;

/// "Renovatie › Offerte afvoer" for a sub-project, the name for a top-level
/// one.
String projectPathOf(Project project, ProjectTree tree, AppLocalizations l10n) {
  final parent = project.parentId == null ? null : tree[project.parentId!];
  return parent == null
      ? project.name
      : l10n.projectPath(parent.name, project.name);
}

/// The project of an item as a grey chip on its card (DD-018 point 6):
/// on Today, in the Inbox and in search results. Nothing when the item has
/// no project, or its project no longer exists.
class ProjectChip extends ConsumerWidget {
  const ProjectChip({super.key, required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tree = ref.watch(projectTreeProvider);
    final project = tree[projectId];
    if (project == null) return const SizedBox.shrink();
    return Tooltip(
      message: projectPathOf(project, tree, l10n),
      child: Semantics(
        label: l10n.tokenChipSemantics(
          l10n.projectKind,
          projectPathOf(project, tree, l10n),
        ),
        excludeSemantics: true,
        child: Chip(
          avatar: const Icon(projectIcon, size: 16),
          label: Text(project.name),
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          labelPadding: const EdgeInsetsDirectional.only(end: 4),
        ),
      ),
    );
  }
}
