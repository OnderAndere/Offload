import 'project.dart';

/// What deleting a project changed, so that it can be undone at once
/// (DD-018 point 6, DD-003).
class ProjectDeletion {
  const ProjectDeletion({
    required this.projectId,
    required this.unlinkedItemIds,
    required this.movedUp,
  });

  final String projectId;

  /// The items that lost the project.
  final List<String> unlinkedItemIds;

  /// The sub-projects that moved to the top level, with the name they had
  /// under the project.
  final List<({String id, String name})> movedUp;
}

/// Projects (DD-011, DD-018 point 6). Every change goes through the change
/// log (DD-003); the rules of `ProjectTree` are checked in the same
/// transaction as the write. A refused change throws a `ProjectException`.
abstract class ProjectRepository {
  /// The live projects, archived ones included, by name.
  Stream<List<Project>> watchProjects();

  /// Creates a project called [name], at the top level or under the
  /// top-level project [parentId]; returns its id.
  Future<String> create(String name, {String? parentId});

  Future<void> rename(String id, String name);

  /// Moves [id] to the top level (null) or under the top-level project
  /// [parentId]. A name that is taken there is refused.
  Future<void> move(String id, String? parentId);

  /// Archives [id]; a top-level project takes its sub-projects along.
  Future<void> archive(String id);

  /// Brings [id] back from the archive; a top-level project brings its
  /// sub-projects along. A name taken in the meantime gets a number.
  Future<void> restoreFromArchive(String id);

  /// Deletes [id] (a tombstone): its items stay and lose the project, its
  /// sub-projects move to the top level (a taken name gets a number).
  Future<ProjectDeletion> delete(String id);

  /// Undoes [deletion]: the project, its sub-projects and the link of its
  /// items come back, as far as nothing else changed them in between.
  Future<void> undoDelete(ProjectDeletion deletion);
}
