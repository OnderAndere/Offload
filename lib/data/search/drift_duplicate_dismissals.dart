import 'package:drift/drift.dart';

import '../../domain/search/duplicates.dart';
import '../database/app_database.dart' show DuplicateDismissalsCompanion;
import '../storage/app_storage.dart';

/// Ignored pairs of the duplicate hint (AC REQ-053), written through the change
/// log like all user data, so the choice synchronises.
class DriftDuplicateDismissals implements DuplicateDismissals {
  DriftDuplicateDismissals(this._storage);

  final AppStorage _storage;

  @override
  Future<bool> isDismissed(String itemId, String otherItemId) async {
    final (first, second) = _ordered(itemId, otherItemId);
    final db = _storage.database;
    final row = await db
        .customSelect(
          'SELECT 1 FROM duplicate_dismissals WHERE item_id = ? '
          'AND other_item_id = ? AND deleted_at IS NULL LIMIT 1',
          variables: [Variable<String>(first), Variable<String>(second)],
          readsFrom: {db.duplicateDismissals},
        )
        .getSingleOrNull();
    return row != null;
  }

  @override
  Future<void> dismiss(String itemId, String otherItemId) async {
    if (await isDismissed(itemId, otherItemId)) return;
    final (first, second) = _ordered(itemId, otherItemId);
    final db = _storage.database;
    await _storage.writer.insert(
      db.duplicateDismissals,
      DuplicateDismissalsCompanion(
        itemId: Value(first),
        otherItemId: Value(second),
      ),
    );
  }

  /// Fires when the hints may have changed: the search index was updated
  /// (items saved, changed or trashed) or a pair was ignored.
  Stream<void> changes() {
    final db = _storage.database;
    return db.tableUpdates(
      TableUpdateQuery.onAllTables([db.searchMap, db.duplicateDismissals]),
    );
  }

  /// One row per pair: the smaller id first (a table constraint).
  static (String, String) _ordered(String a, String b) =>
      a.compareTo(b) < 0 ? (a, b) : (b, a);
}
