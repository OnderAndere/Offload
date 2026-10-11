import '../tokens/token_processing.dart';
import 'project.dart';

/// Why a change to a project is refused (DD-018 point 6). The screen turns
/// the reason into a message.
enum ProjectProblem {
  /// The name is empty.
  emptyName,

  /// A project in use under the same parent already has this name.
  nameTaken,

  /// The change would make a third level, or put a project under itself.
  tooDeep,

  /// The project or its intended parent is deleted or archived.
  notAvailable,
}

class ProjectException implements Exception {
  const ProjectException(this.problem);

  final ProjectProblem problem;

  @override
  String toString() => 'ProjectException(${problem.name})';
}

/// The live projects, archived ones included, and the rules that hold
/// between them (DD-018 point 6): two levels, names unique per parent among
/// the projects in use, case-insensitive with Unicode rules ([nameKey]).
/// Pure, so the repository checks a change against the stored projects
/// inside its write transaction.
class ProjectTree {
  ProjectTree(Iterable<Project> projects)
    : _byId = {for (final p in projects) p.id: p};

  final Map<String, Project> _byId;

  Iterable<Project> get projects => _byId.values;

  Project? operator [](String id) => _byId[id];

  /// This tree with [project] added or replaced by its id.
  ProjectTree withProject(Project project) =>
      ProjectTree([..._byId.values.where((p) => p.id != project.id), project]);

  /// This tree without project [id].
  ProjectTree without(String id) =>
      ProjectTree(_byId.values.where((p) => p.id != id));

  /// The live sub-projects of [id], archived ones included.
  List<Project> childrenOf(String id) => [
    for (final p in _byId.values)
      if (p.parentId == id) p,
  ];

  /// The project in use (not archived) under [parentId] called [name],
  /// other than [exceptId]; null when the name is free.
  Project? holderOf(String name, String? parentId, {String? exceptId}) {
    final key = nameKey(name);
    for (final p in _byId.values) {
      if (p.id != exceptId &&
          !p.isArchived &&
          p.parentId == parentId &&
          nameKey(p.name) == key) {
        return p;
      }
    }
    return null;
  }

  /// [name] trimmed, checked for a new or renamed project under
  /// [parentId]; throws [ProjectException] when it is empty or taken.
  String checkedName(String name, String? parentId, {String? exceptId}) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw const ProjectException(ProjectProblem.emptyName);
    }
    if (holderOf(trimmed, parentId, exceptId: exceptId) != null) {
      throw const ProjectException(ProjectProblem.nameTaken);
    }
    return trimmed;
  }

  /// Checks that a project can go under [parentId]: null (top level) or a
  /// top-level project in use. Throws [ProjectException] otherwise.
  void checkParent(String? parentId) {
    if (parentId == null) return;
    final parent = _byId[parentId];
    if (parent == null || parent.isArchived) {
      throw const ProjectException(ProjectProblem.notAvailable);
    }
    if (!parent.isTopLevel) {
      throw const ProjectException(ProjectProblem.tooDeep);
    }
  }

  /// Checks that project [id] can move under [parentId]: a project with
  /// sub-projects stays at the top level, and nothing goes under itself.
  void checkMove(String id, String? parentId) {
    final project = _byId[id];
    if (project == null || project.isArchived) {
      throw const ProjectException(ProjectProblem.notAvailable);
    }
    checkParent(parentId);
    if (parentId == id || (parentId != null && childrenOf(id).isNotEmpty)) {
      throw const ProjectException(ProjectProblem.tooDeep);
    }
  }

  /// A name for a project that arrives under [parentId] by itself (after a
  /// delete, an undo, a restore): [name] when it is free, otherwise the
  /// first free "name (2)", "name (3)", …
  String freeName(String name, String? parentId, {String? exceptId}) {
    if (holderOf(name, parentId, exceptId: exceptId) == null) return name;
    for (var n = 2; ; n++) {
      final candidate = '$name ($n)';
      if (holderOf(candidate, parentId, exceptId: exceptId) == null) {
        return candidate;
      }
    }
  }
}
