import 'package:drift/drift.dart';

import '../database/app_database.dart';

/// Device-local key/value state in `local_state` (DD-003): never
/// synchronised and never change-logged.
class LocalStateStore {
  LocalStateStore(this._db);

  final AppDatabase _db;

  Future<String?> read(String key) async {
    final row = await (_db.select(
      _db.localState,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> write(String key, String value) => _db
      .into(_db.localState)
      .insertOnConflictUpdate(
        LocalStateCompanion.insert(key: key, value: value),
      );

  /// Every key and value: the settings of this device, kept when a backup
  /// is restored (DD-007).
  Future<Map<String, String>> all() async => {
    for (final row in await _db.select(_db.localState).get())
      row.key: row.value,
  };

  /// Stores [value] only when [key] has no value yet.
  Future<void> writeIfAbsent(String key, String value) => _db
      .into(_db.localState)
      .insert(
        LocalStateCompanion.insert(key: key, value: value),
        mode: InsertMode.insertOrIgnore,
      );
}
