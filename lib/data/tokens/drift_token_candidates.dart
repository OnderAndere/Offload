import 'package:drift/drift.dart';

import '../../domain/projects/project.dart';
import '../../domain/search/search_index.dart';
import '../../domain/tokens/token_suggestion.dart';
import '../../domain/tokens/token_types.dart';
import '../database/app_database.dart';
import '../search/drift_search_index.dart';

/// Persons, tags and projects for the suggestion list (REQ-033), each with
/// how many items link to it through their tokens.
class DriftTokenCandidates implements TokenCandidateSource {
  DriftTokenCandidates(this._db);

  final AppDatabase _db;

  @override
  Future<List<NamedCandidate>> people() async {
    final people = await (_db.select(
      _db.people,
    )..where((p) => p.deletedAt.isNull())).get();
    final aliases = await (_db.select(
      _db.personAliases,
    )..where((a) => a.deletedAt.isNull())).get();
    final uses = await _uses(const PersonTokenType().id);
    return [
      for (final person in people)
        NamedCandidate(
          name: person.name,
          aliases: [
            for (final a in aliases)
              if (a.personId == person.id) a.alias,
          ],
          uses: uses[person.id] ?? 0,
        ),
    ];
  }

  @override
  Future<List<NamedCandidate>> tags() async {
    final tags = await (_db.select(
      _db.tags,
    )..where((t) => t.deletedAt.isNull())).get();
    final uses = await _uses(const TagTokenType().id);
    return [
      for (final tag in tags)
        NamedCandidate(name: tag.name, uses: uses[tag.id] ?? 0),
    ];
  }

  @override
  Future<ProjectCandidates> projects() async {
    final rows = await (_db.select(
      _db.contexts,
    )..where((c) => c.deletedAt.isNull())).get();
    return (
      projects: [
        for (final row in rows)
          Project(
            id: row.id,
            name: row.name,
            parentId: row.parentId,
            archivedAt: row.archivedAt,
          ),
      ],
      uses: await _uses(const ProjectTokenType().id),
    );
  }

  @override
  Future<List<ItemCandidate>> items(
    String query, {
    String? excludeId,
    int limit = 5,
  }) async {
    final List<String> ids;
    if (query.trim().isEmpty) {
      // Version 7 UUIDs sort by capture time: the newest first.
      final rows =
          await (_db.selectOnly(_db.items)
                ..addColumns([_db.items.id])
                ..where(
                  _db.items.deletedAt.isNull() &
                      (excludeId == null
                          ? const Constant(true)
                          : _db.items.id.equals(excludeId).not()),
                )
                ..orderBy([OrderingTerm.desc(_db.items.id)])
                ..limit(limit))
              .get();
      ids = [for (final row in rows) row.read(_db.items.id)!];
    } else {
      // People are hits too: ask for more, so enough items remain.
      final hits = await DriftSearchIndex(
        _db,
      ).search(query, limit: limit * 4 + 1);
      ids = [
        for (final hit in hits)
          if (hit.entity == SearchEntity.item && hit.id != excludeId) hit.id,
      ].take(limit).toList();
    }
    if (ids.isEmpty) return const [];
    final item = _db.items;
    final project = _db.contexts;
    final rows = await (_db.select(item).join([
      leftOuterJoin(project, project.id.equalsExp(item.contextId)),
    ])..where(item.id.isIn(ids) & item.deletedAt.isNull())).get();
    final byId = {
      for (final row in rows)
        row.readTable(item).id: ItemCandidate(
          id: row.readTable(item).id,
          rawText: row.readTable(item).rawText,
          status: row.readTable(item).status,
          project: row.readTableOrNull(project)?.name,
        ),
    };
    // In the order of the index (best first) or of capture.
    return [for (final id in ids) ?byId[id]];
  }

  /// Linked live items per resolved id of [tokenType]; items in the trash
  /// do not count.
  Future<Map<String, int>> _uses(String tokenType) async {
    final rows = await _db
        .customSelect(
          'SELECT t.resolved_value, COUNT(DISTINCT t.item_id) AS uses '
          'FROM tokens t JOIN items i ON i.id = t.item_id '
          'WHERE t.token_type = ? AND t.resolved_value IS NOT NULL '
          'AND i.deleted_at IS NULL '
          'GROUP BY t.resolved_value',
          variables: [Variable<String>(tokenType)],
          readsFrom: {_db.tokens, _db.items},
        )
        .get();
    return {
      for (final row in rows)
        row.read<String>('resolved_value'): row.read<int>('uses'),
    };
  }
}
