/// Row access by SQL column name, shared by the change-log writer and
/// replayer (REQ-037). Column names are checked against the table before
/// they go into a statement, so a payload can never inject SQL.
library;

import 'package:drift/drift.dart';

/// Reads, inserts and updates rows of [table] as maps of SQL values.
///
/// Plain SQL statements: drift's client-side column behaviour
/// (`clientDefault`, `withLength`, `validateIntegrity`) does not run here.
/// Synchronisable tables must not rely on it; use SQL defaults and CHECK
/// constraints instead.
class SqlRows {
  SqlRows(this._db, this.table)
    : _columns = {for (final c in table.$columns) c.name};

  final DatabaseConnectionUser _db;
  final TableInfo<Table, Object?> table;
  final Set<String> _columns;

  String get _name => '"${table.actualTableName}"';

  /// The row with [id] as stored, or null when there is none.
  Future<Map<String, Object?>?> select(String id) async {
    final row = await _db
        .customSelect(
          'SELECT * FROM $_name WHERE "id" = ?',
          variables: [Variable<String>(id)],
          readsFrom: {table},
        )
        .getSingleOrNull();
    return row?.data;
  }

  Future<void> insert(Map<String, Object?> values) {
    final names = _checked(values.keys);
    return _db.customInsert(
      'INSERT INTO $_name (${names.map(_quote).join(', ')}) '
      'VALUES (${List.filled(names.length, '?').join(', ')})',
      variables: [for (final n in names) Variable<Object>(values[n])],
      updates: {table},
    );
  }

  /// Updates the row with [id]; fails when there is no such row.
  Future<void> update(String id, Map<String, Object?> values) async {
    final names = _checked(values.keys);
    final count = await _db.customUpdate(
      'UPDATE $_name SET ${names.map((n) => '${_quote(n)} = ?').join(', ')} '
      'WHERE "id" = ?',
      variables: [
        for (final n in names) Variable<Object>(values[n]),
        Variable<String>(id),
      ],
      updates: {table},
      updateKind: UpdateKind.update,
    );
    if (count != 1) {
      throw StateError('No ${table.actualTableName} row with id $id');
    }
  }

  List<String> _checked(Iterable<String> names) {
    final list = names.toList();
    if (list.isEmpty) throw ArgumentError('No columns given');
    for (final n in list) {
      if (!_columns.contains(n)) {
        throw ArgumentError.value(
          n,
          'column',
          'not in ${table.actualTableName}',
        );
      }
    }
    return list;
  }

  static String _quote(String name) => '"$name"';
}
