import 'package:drift/drift.dart';

import '../../domain/sync/change_operation.dart';
import '../../domain/sync/hlc.dart';
import '../database/app_database.dart';
import '../database/tables.dart';
import 'change_log_format.dart';
import 'sql_rows.dart';

/// Rebuilds synchronisable tables from change-log entries alone (REQ-037,
/// DD-003); the basis for importing sync packages (DD-013, M9).
///
/// Entries are applied in HLC order in one transaction and copied into the
/// target's change log. Not handled yet, because they belong to sync (M9):
/// skipping entries the database already has, and last-writer-wins per
/// column against newer local changes.
class ChangeLogReplayer {
  ChangeLogReplayer(this._db)
    : _tables = {
        for (final t in _db.allTables)
          if (t is SyncColumns) t.actualTableName: t,
      };

  final AppDatabase _db;
  final Map<String, TableInfo<Table, Object?>> _tables;

  /// Applies [entries]; on any error nothing is changed.
  ///
  /// Foreign keys are checked at the end of the outermost transaction, so
  /// inside a caller's transaction they stay deferred until that commits.
  Future<void> replay(Iterable<ChangeLogData> entries) {
    final ordered = entries.toList()..sort((a, b) => a.hlc.compareTo(b.hlc));
    return _db.transaction(() async {
      // Rows may arrive before the rows they refer to within the batch;
      // foreign keys are checked when the transaction commits.
      await _db.customStatement('PRAGMA defer_foreign_keys = ON');
      for (final entry in ordered) {
        await _apply(entry);
        await _db.into(_db.changeLog).insert(entry);
      }
    });
  }

  Future<void> _apply(ChangeLogData entry) async {
    if (entry.formatVersion != changeLogFormatVersion) {
      throw FormatException(
        'Unsupported change-log format version ${entry.formatVersion}',
      );
    }
    Hlc.parse(entry.hlc); // throws FormatException when malformed
    final table = _tables[entry.entity];
    if (table == null) {
      throw FormatException('Not a synchronisable table: ${entry.entity}');
    }
    final payload = decodePayload(entry.payload);
    final rows = SqlRows(_db, table);
    switch (entry.operation) {
      case ChangeOperation.insert:
        _reject(payload, managedColumns, entry);
        await rows.insert({
          ...payload,
          idColumn: entry.entityId,
          hlcColumn: entry.hlc,
        });
      case ChangeOperation.update:
        _reject(payload, managedColumns, entry);
        await rows.update(entry.entityId, {...payload, hlcColumn: entry.hlc});
      case ChangeOperation.delete:
        if (payload.keys.toSet().difference({deletedAtColumn}).isNotEmpty ||
            payload[deletedAtColumn] == null) {
          throw FormatException('A delete sets only $deletedAtColumn');
        }
        await rows.update(entry.entityId, {...payload, hlcColumn: entry.hlc});
      case ChangeOperation.restore:
        if (payload.length != 1 ||
            !payload.containsKey(deletedAtColumn) ||
            payload[deletedAtColumn] != null) {
          throw FormatException('A restore clears only $deletedAtColumn');
        }
        await rows.update(entry.entityId, {...payload, hlcColumn: entry.hlc});
    }
  }

  static void _reject(
    Map<String, Object?> payload,
    Set<String> columns,
    ChangeLogData entry,
  ) {
    final bad = payload.keys.where(columns.contains);
    if (bad.isNotEmpty) {
      throw FormatException(
        'Payload of ${entry.operation.name} ${entry.entity} ${entry.entityId} '
        'sets managed columns ${bad.join(', ')}',
      );
    }
  }
}
