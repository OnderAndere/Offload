import 'package:drift/drift.dart';

import '../../domain/ids/uuid_v5.dart';
import '../../domain/ids/uuid_v7.dart';
import '../../domain/sync/change_operation.dart';
import '../../domain/sync/hlc.dart';
import '../database/app_database.dart';
import '../database/tables.dart';
import 'change_log_format.dart';
import 'sql_rows.dart';

/// The single write path for synchronisable tables (REQ-008, REQ-037,
/// DD-003): every change gets a fresh HLC and is stored together with its
/// change-log entry in one transaction, so no change exists without its log
/// entry and no log entry without its change.
///
/// Repositories (T1.6 and later) write through this class, never directly
/// into a synchronisable table.
class ChangeLogWriter {
  ChangeLogWriter(this._db, {required this.clock, required this.ids});

  final AppDatabase _db;
  final HlcClock clock;
  final UuidV7Generator ids;

  /// Inserts [row] as a new entity and returns its id.
  ///
  /// [row] must not set `id`, `hlc` or `deleted_at`: the writer assigns
  /// the id and the HLC, and a new row is never a tombstone.
  Future<String> insert<T extends SyncColumns, D>(
    TableInfo<T, D> table,
    Insertable<D> row,
  ) async {
    final values = _sqlValues(row);
    return _db.transaction(() async {
      final id = ids.next();
      await _insert(table, id, values);
      return id;
    });
  }

  /// Inserts [row] under [id], a version 7 UUID made elsewhere: for example
  /// at the moment of a capture in the Android widget, so the capture time
  /// read from the id is the moment of the tap.
  ///
  /// Returns false, and writes nothing, when a row with [id] already exists,
  /// also a deleted one: a capture delivered twice is stored once.
  Future<bool> insertWithId<T extends SyncColumns, D>(
    TableInfo<T, D> table,
    String id,
    Insertable<D> row,
  ) async {
    if (!isCanonicalUuidV7(id)) {
      throw ArgumentError.value(id, 'id', 'is not a version 7 UUID');
    }
    final values = _sqlValues(row);
    return _db.transaction(() async {
      if (await SqlRows(_db, table).select(id) != null) return false;
      await _insert(table, id, values);
      return true;
    });
  }

  /// Writes [row] under [id], a version 5 UUID worked out from what the row
  /// is about (`completionId`, DD-003): the same fact written twice, on one
  /// device or on two, is one row. Inserts when no row has [id]; brings a
  /// deleted one back (`restore`) and then sets [row] on it; on a live one
  /// only the columns that change. Returns whether anything was written.
  Future<bool> put<T extends SyncColumns, D>(
    TableInfo<T, D> table,
    String id,
    Insertable<D> row,
  ) async {
    if (!isCanonicalUuidV5(id)) {
      throw ArgumentError.value(id, 'id', 'is not a version 5 UUID');
    }
    final values = _sqlValues(row);
    return _db.transaction(() async {
      final existing = await SqlRows(_db, table).select(id);
      if (existing == null) {
        await _insert(table, id, values);
        return true;
      }
      final deleted = existing[deletedAtColumn] != null;
      if (deleted) await restore(table, id);
      final changed = await update(table, id, row);
      return deleted || changed;
    });
  }

  Future<void> _insert(
    TableInfo<Table, Object?> table,
    String id,
    Map<String, Object?> values,
  ) async {
    final hlc = clock.tick();
    final rows = SqlRows(_db, table);
    await rows.insert({...values, idColumn: id, hlcColumn: hlc.pack()});
    // Log the stored row, so columns left out get their stored value too.
    final stored = (await rows.select(id))!;
    await _log(table, id, hlc, ChangeOperation.insert, {
      for (final MapEntry(:key, :value) in stored.entries)
        if (!managedColumns.contains(key)) key: value,
    });
  }

  /// Applies [changes] to the live entity [id].
  ///
  /// Only columns whose stored value actually changes get a new HLC and go
  /// into the log; returns false, and writes nothing, when nothing changes.
  Future<bool> update<T extends SyncColumns, D>(
    TableInfo<T, D> table,
    String id,
    Insertable<D> changes,
  ) async {
    final values = _sqlValues(changes);
    if (values.isEmpty) throw ArgumentError('No columns to update');
    return _db.transaction(() async {
      final rows = SqlRows(_db, table);
      final current = await _live(rows, id);
      final changed = {
        for (final MapEntry(:key, :value) in values.entries)
          if (current[key] != value) key: value,
      };
      if (changed.isEmpty) return false;
      final hlc = clock.tick();
      await rows.update(id, {...changed, hlcColumn: hlc.pack()});
      await _log(table, id, hlc, ChangeOperation.update, changed);
      return true;
    });
  }

  /// Sets the tombstone of the live entity [id]; rows are never deleted.
  Future<void> delete<T extends SyncColumns, D>(
    TableInfo<T, D> table,
    String id,
  ) {
    return _db.transaction(() async {
      final rows = SqlRows(_db, table);
      await _live(rows, id);
      final hlc = clock.tick();
      final deletedAt = _sqlValue(
        deletedAtColumn,
        Variable<DateTime>(
          DateTime.fromMillisecondsSinceEpoch(hlc.millis, isUtc: true),
        ),
      );
      final tombstone = {deletedAtColumn: deletedAt};
      await rows.update(id, {...tombstone, hlcColumn: hlc.pack()});
      await _log(table, id, hlc, ChangeOperation.delete, tombstone);
    });
  }

  /// Clears the tombstone of the deleted entity [id] ("undo" after the
  /// trash, AC REQ-010), with a new HLC so this later change wins in sync.
  Future<void> restore<T extends SyncColumns, D>(
    TableInfo<T, D> table,
    String id,
  ) {
    return _db.transaction(() async {
      final rows = SqlRows(_db, table);
      final row = await rows.select(id);
      if (row == null) {
        throw StateError('No ${table.actualTableName} row with id $id');
      }
      if (row[deletedAtColumn] == null) {
        throw StateError('${table.actualTableName} $id is not deleted');
      }
      final hlc = clock.tick();
      const cleared = {deletedAtColumn: null};
      await rows.update(id, {...cleared, hlcColumn: hlc.pack()});
      await _log(table, id, hlc, ChangeOperation.restore, cleared);
    });
  }

  Future<Map<String, Object?>> _live(SqlRows rows, String id) async {
    final row = await rows.select(id);
    if (row == null) {
      throw StateError('No ${rows.table.actualTableName} row with id $id');
    }
    if (row[deletedAtColumn] != null) {
      throw StateError('${rows.table.actualTableName} $id is deleted');
    }
    return row;
  }

  Future<void> _log(
    TableInfo<Table, Object?> table,
    String id,
    Hlc hlc,
    ChangeOperation operation,
    Map<String, Object?> payload,
  ) => _db
      .into(_db.changeLog)
      .insert(
        ChangeLogCompanion.insert(
          id: ids.next(),
          entity: table.actualTableName,
          entityId: id,
          hlc: hlc.pack(),
          operation: operation,
          payload: encodePayload(payload),
          formatVersion: changeLogFormatVersion,
        ),
      );

  /// The SQL values of the columns [row] sets, as they will be stored.
  Map<String, Object?> _sqlValues(Insertable<Object?> row) {
    final columns = row.toColumns(true);
    for (final name in columns.keys) {
      if (managedColumns.contains(name)) {
        throw ArgumentError.value(name, 'row', 'is set by ChangeLogWriter');
      }
    }
    return {
      for (final MapEntry(:key, :value) in columns.entries)
        key: _sqlValue(key, value),
    };
  }

  Object? _sqlValue(String column, Expression<Object> expression) {
    if (expression is! Variable) {
      throw ArgumentError.value(expression, column, 'must be a plain value');
    }
    final value = expression.value;
    // Timestamps are stored in UTC (DD-003); local times with a changing
    // offset would sort wrongly as text.
    if (value is DateTime && !value.isUtc) {
      throw ArgumentError.value(value, column, 'must be UTC');
    }
    return expression.mapToSimpleValue(GenerationContext.fromDb(_db));
  }
}
