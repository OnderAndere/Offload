import 'package:drift/drift.dart';

import '../../domain/projects/project.dart';
import '../../domain/projects/project_repository.dart';
import '../../domain/projects/project_tree.dart';
import '../../domain/tokens/token_processing.dart';
import '../database/app_database.dart';
import '../storage/app_storage.dart';

/// [ProjectRepository] on the `contexts` table (DD-011, DD-018 point 6).
///
/// Every change reads the live projects, checks it with [ProjectTree] and
/// writes through the change log, all in one transaction: transactions run
/// one after the other, so two changes can never both take the same name.
class DriftProjectRepository implements ProjectRepository {
  DriftProjectRepository(this._storage);

  final AppStorage _storage;

  AppDatabase get _db => _storage.database;

  @override
  Stream<List<Project>> watchProjects() {
    final query = _db.select(_db.contexts)..where((c) => c.deletedAt.isNull());
    return query.watch().map(
      (rows) => [for (final row in rows) _projectOf(row)]
        ..sort((a, b) {
          final byName = nameKey(a.name).compareTo(nameKey(b.name));
          return byName != 0 ? byName : a.id.compareTo(b.id);
        }),
    );
  }

  @override
  Future<String> create(String name, {String? parentId}) =>
      _db.transaction(() async {
        final tree = await _tree();
        tree.checkParent(parentId);
        return _storage.writer.insert(
          _db.contexts,
          ContextsCompanion(
            name: Value(tree.checkedName(name, parentId)),
            parentId: Value(parentId),
          ),
        );
      });

  @override
  Future<void> rename(String id, String name) => _db.transaction(() async {
    final tree = await _tree();
    final project = _inUse(tree, id);
    await _storage.writer.update(
      _db.contexts,
      id,
      ContextsCompanion(
        name: Value(
          tree.checkedName(name, project.parentId, exceptId: project.id),
        ),
      ),
    );
  });

  @override
  Future<void> move(String id, String? parentId) => _db.transaction(() async {
    final tree = await _tree();
    final project = _inUse(tree, id);
    if (project.parentId == parentId) return;
    tree
      ..checkMove(id, parentId)
      ..checkedName(project.name, parentId, exceptId: id);
    await _storage.writer.update(
      _db.contexts,
      id,
      ContextsCompanion(parentId: Value(parentId)),
    );
  });

  @override
  Future<void> archive(String id) => _db.transaction(() async {
    final tree = await _tree();
    final project = _inUse(tree, id);
    final now = DateTime.now().toUtc();
    for (final p in [project, ...tree.childrenOf(id)]) {
      if (p.isArchived) continue;
      await _storage.writer.update(
        _db.contexts,
        p.id,
        ContextsCompanion(archivedAt: Value(now)),
      );
    }
  });

  @override
  Future<void> restoreFromArchive(String id) => _db.transaction(() async {
    var tree = await _tree();
    final project = tree[id];
    if (project == null || !project.isArchived) {
      throw const ProjectException(ProjectProblem.notAvailable);
    }
    // A sub-project comes back only under a parent in use.
    if (project.parentId case final parentId?) {
      if (tree[parentId]?.isArchived ?? true) {
        throw const ProjectException(ProjectProblem.notAvailable);
      }
    }
    // A parent brings back the sub-projects it took along (archived at the
    // same moment), not those archived on their own before.
    final comeBack = [
      project,
      for (final child in tree.childrenOf(id))
        if (child.archivedAt == project.archivedAt) child,
    ];
    for (final p in comeBack) {
      final name = tree.freeName(p.name, p.parentId, exceptId: p.id);
      await _storage.writer.update(
        _db.contexts,
        p.id,
        ContextsCompanion(archivedAt: const Value(null), name: Value(name)),
      );
      tree = tree.withProject(
        Project(id: p.id, name: name, parentId: p.parentId),
      );
    }
  });

  @override
  Future<ProjectDeletion> delete(String id) => _db.transaction(() async {
    var tree = await _tree();
    final project = tree[id];
    if (project == null) {
      throw const ProjectException(ProjectProblem.notAvailable);
    }
    await _storage.writer.delete(_db.contexts, id);
    tree = tree.without(id);

    // Sub-projects move up; one in use gets a number when its name is taken
    // at the top level. An archived one keeps its name until it is restored.
    final movedUp = <({String id, String name})>[];
    for (final child in tree.childrenOf(id)) {
      final name = child.isArchived
          ? child.name
          : tree.freeName(child.name, null, exceptId: child.id);
      await _storage.writer.update(
        _db.contexts,
        child.id,
        ContextsCompanion(parentId: const Value(null), name: Value(name)),
      );
      tree = tree.withProject(
        Project(id: child.id, name: name, archivedAt: child.archivedAt),
      );
      movedUp.add((id: child.id, name: child.name));
    }

    final items = await (_db.select(
      _db.items,
    )..where((i) => i.contextId.equals(id) & i.deletedAt.isNull())).get();
    for (final item in items) {
      await _storage.writer.update(
        _db.items,
        item.id,
        const ItemsCompanion(contextId: Value(null)),
      );
    }
    return ProjectDeletion(
      projectId: id,
      unlinkedItemIds: [for (final item in items) item.id],
      movedUp: movedUp,
    );
  });

  @override
  Future<void> undoDelete(ProjectDeletion deletion) =>
      _db.transaction(() async {
        final id = deletion.projectId;
        await _storage.writer.restore(_db.contexts, id);
        var tree = await _tree();
        final project = tree[id]!;
        // A parent that is gone, archived or no longer top level in the
        // meantime cannot take it back: then it stays at the top level.
        final parentId = project.parentId;
        final parent = parentId == null ? null : tree[parentId];
        final keepParent =
            parentId == null ||
            (parent != null && !parent.isArchived && parent.isTopLevel);
        final name = project.isArchived
            ? project.name
            : tree.freeName(
                project.name,
                keepParent ? parentId : null,
                exceptId: id,
              );
        if (name != project.name || !keepParent) {
          await _storage.writer.update(
            _db.contexts,
            id,
            ContextsCompanion(
              name: Value(name),
              parentId: Value(keepParent ? parentId : null),
            ),
          );
        }
        tree = tree.withProject(
          Project(
            id: id,
            name: name,
            parentId: keepParent ? parentId : null,
            archivedAt: project.archivedAt,
          ),
        );

        // Sub-projects go back, unless they moved or went since; under an
        // archived project only archived ones (an archived project has no
        // sub-project in use).
        final back = tree[id]!;
        for (final moved in deletion.movedUp) {
          final child = tree[moved.id];
          if (child == null || !child.isTopLevel || !back.isTopLevel) continue;
          if (tree.childrenOf(moved.id).isNotEmpty) continue;
          if (back.isArchived && !child.isArchived) continue;
          final childName = child.isArchived
              ? moved.name
              : tree.freeName(moved.name, id, exceptId: moved.id);
          await _storage.writer.update(
            _db.contexts,
            moved.id,
            ContextsCompanion(parentId: Value(id), name: Value(childName)),
          );
          tree = tree.withProject(
            Project(
              id: moved.id,
              name: childName,
              parentId: id,
              archivedAt: child.archivedAt,
            ),
          );
        }

        // Items get the project back, unless they got another one since.
        for (final itemId in deletion.unlinkedItemIds) {
          final item =
              await (_db.select(_db.items)..where(
                    (i) =>
                        i.id.equals(itemId) &
                        i.deletedAt.isNull() &
                        i.contextId.isNull(),
                  ))
                  .getSingleOrNull();
          if (item == null) continue;
          await _storage.writer.update(
            _db.items,
            itemId,
            ItemsCompanion(contextId: Value(id)),
          );
        }
      });

  /// The live projects, archived ones included.
  Future<ProjectTree> _tree() async {
    final rows = await (_db.select(
      _db.contexts,
    )..where((c) => c.deletedAt.isNull())).get();
    return ProjectTree([for (final row in rows) _projectOf(row)]);
  }

  /// Project [id] when it is live and not archived.
  static Project _inUse(ProjectTree tree, String id) {
    final project = tree[id];
    if (project == null || project.isArchived) {
      throw const ProjectException(ProjectProblem.notAvailable);
    }
    return project;
  }

  static Project _projectOf(Context row) => Project(
    id: row.id,
    name: row.name,
    parentId: row.parentId,
    archivedAt: row.archivedAt,
  );
}
