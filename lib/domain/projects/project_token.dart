import '../tokens/token_processing.dart';
import '../tokens/token_types.dart';
import 'project.dart';

final _ignored = RegExp(r'[\s_-]');

/// Punctuation that never ends a token word (the registry drops it), so a
/// name ending in it ("Wat nu?") still matches.
final _trailing = RegExp(r'''[.,;:!?)\]}"']+$''');

/// The key a `^project` word and a project name are compared by (DD-004
/// point 11): without case (Unicode, as [nameKey]), spaces, `-` and `_`,
/// so `^oudeschuur` and `^Oude-schuur` both name "Oude schuur".
String projectKey(String name) =>
    nameKey(name).replaceAll(_ignored, '').replaceFirst(_trailing, '');

/// The project in use that the word after `^` names, or null.
///
/// - `^renovatie/keuken`: the sub-project *keuken* under the top-level
///   project *renovatie*;
/// - `^keuken`: the one project in use with that key; when a top-level
///   project and sub-projects share it, the top-level one (the path names
///   the others); when only sub-projects of different parents share it,
///   none.
///
/// Archived projects never count; [projects] may include them.
String? projectForWord(String word, Iterable<Project> projects) {
  final inUse = [
    for (final p in projects)
      if (!p.isArchived) p,
  ];
  final parts = word.split('/');
  if (parts.length == 2) {
    final parentKey = projectKey(parts[0]);
    final childKey = projectKey(parts[1]);
    final parents = {
      for (final p in inUse)
        if (p.isTopLevel && projectKey(p.name) == parentKey) p.id,
    };
    final children = [
      for (final p in inUse)
        if (parents.contains(p.parentId) && projectKey(p.name) == childKey) p,
    ];
    return children.length == 1 ? children.single.id : null;
  }
  if (parts.length != 1) return null;
  final key = projectKey(word);
  final matches = [
    for (final p in inUse)
      if (projectKey(p.name) == key) p,
  ];
  final topLevel = [
    for (final p in matches)
      if (p.isTopLevel) p,
  ];
  if (topLevel.length == 1) return topLevel.single.id;
  return matches.length == 1 ? matches.single.id : null;
}

/// The word that names [project] after `^`, for the suggestion list: its
/// name with every run of spaces as one `-`, and for a sub-project whose
/// name alone does not find it the path `parent/name`. Null when even the
/// path is ambiguous (names that differ only in case or spacing), or when
/// the name cannot be a word (it starts with a sign, or holds a `/`).
String? wordForProject(Project project, Iterable<Project> projects) {
  String word(Project p) =>
      p.name.trim().replaceFirst(_trailing, '').replaceAll(RegExp(r'\s+'), '-');
  final own = word(project);
  if (!ProjectTokenType.isWord(own)) return null;
  if (projectForWord(own, projects) == project.id) return own;
  final parentId = project.parentId;
  if (parentId == null) return null;
  final parent = projects.where((p) => p.id == parentId).firstOrNull;
  if (parent == null) return null;
  final path = '${word(parent)}/$own';
  if (!ProjectTokenType.isWord(path)) return null;
  return projectForWord(path, projects) == project.id ? path : null;
}

/// What a `^project` word names, for the chip under the text (DD-004 point
/// 11, PO decision 03-10-2026): a project, no project yet (with what to
/// create), or several.
sealed class ProjectWordMatch {
  const ProjectWordMatch();
}

/// The word names the project [id].
final class NamesProject extends ProjectWordMatch {
  const NamesProject(this.id);
  final String id;
}

/// The word names no project in use. [name] is a name for a new one, from
/// the word with `-` and `_` as spaces; [parentId] is the top-level project
/// a path names. [canCreate] is false for a path whose parent does not
/// exist, or exists more than once.
final class NamesNoProject extends ProjectWordMatch {
  const NamesNoProject({
    required this.name,
    this.parentId,
    this.canCreate = true,
  });
  final String name;
  final String? parentId;
  final bool canCreate;
}

/// The word fits several projects and names none of them: a sub-project
/// name under different parents, two top-level projects whose names differ
/// only in case or spacing, or a path whose parent name fits several
/// projects that each have that sub-project. The path or a rename tells
/// them apart.
final class NamesSeveral extends ProjectWordMatch {
  const NamesSeveral();
}

/// Looks up [word] among [projects] (archived ones never count), as
/// [projectForWord] does, and says why it names none.
ProjectWordMatch matchProjectWord(String word, Iterable<Project> projects) {
  final id = projectForWord(word, projects);
  if (id != null) return NamesProject(id);
  final inUse = [
    for (final p in projects)
      if (!p.isArchived) p,
  ];
  final parts = word.split('/');
  if (parts.length > 2) return const NamesNoProject(name: '', canCreate: false);
  final ownWord = parts.last;
  final ownKey = projectKey(ownWord);
  final name = ownWord
      .replaceFirst(_trailing, '')
      .replaceAll(RegExp(r'[-_\s]+'), ' ')
      .trim();
  if (parts.length == 2) {
    final parentKey = projectKey(parts[0]);
    final parents = [
      for (final p in inUse)
        if (p.isTopLevel && projectKey(p.name) == parentKey) p,
    ];
    if (parents.length != 1) {
      final children = inUse.where(
        (p) =>
            parents.any((parent) => parent.id == p.parentId) &&
            projectKey(p.name) == ownKey,
      );
      return children.length > 1
          ? const NamesSeveral()
          : NamesNoProject(name: name, canCreate: false);
    }
    final parent = parents.single;
    final children = inUse.where(
      (p) => p.parentId == parent.id && projectKey(p.name) == ownKey,
    );
    if (children.length > 1) return const NamesSeveral();
    return NamesNoProject(name: name, parentId: parent.id);
  }
  if (inUse.any((p) => projectKey(p.name) == ownKey)) {
    return const NamesSeveral();
  }
  return NamesNoProject(name: name);
}
