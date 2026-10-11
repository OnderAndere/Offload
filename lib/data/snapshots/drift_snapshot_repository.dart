import 'package:drift/drift.dart';

import '../../domain/snapshots/snapshot.dart';
import '../../domain/sync/hlc.dart';
import '../database/app_database.dart';
import '../storage/app_storage.dart';

/// The notes of "Where was I" in the encrypted database, every change
/// through the change log (T10.3, REQ-049, DD-018 point 13, DD-003).
class DriftSnapshotRepository implements SnapshotRepository {
  DriftSnapshotRepository(this._storage);

  final AppStorage _storage;

  AppDatabase get _db => _storage.database;

  /// The open notes of [owner], the one saved last first.
  SimpleSelectStatement<$SnapshotsTable, SnapshotRow> _open(
    SnapshotOwner owner,
  ) {
    final query = _db.select(_db.snapshots)
      ..where((s) => s.deletedAt.isNull() & s.resumedAt.isNull());
    switch (owner) {
      case ItemSnapshotOwner(:final itemId):
        query.where((s) => s.itemId.equals(itemId));
      case ProjectSnapshotOwner(:final projectId):
        query.where((s) => s.contextId.equals(projectId));
    }
    // The packed HLC sorts in time order (`Hlc.pack`).
    return query..orderBy([(s) => OrderingTerm.desc(s.hlc)]);
  }

  @override
  Stream<Snapshot?> watchOpen(SnapshotOwner owner) => _open(
    owner,
  ).watch().map((rows) => rows.isEmpty ? null : _toDomain(rows.first, owner));

  @override
  Stream<List<Snapshot>> watchAllOpen() {
    final query = _db.select(_db.snapshots)
      ..where((s) => s.deletedAt.isNull() & s.resumedAt.isNull())
      ..orderBy([(s) => OrderingTerm.desc(s.hlc)]);
    return query.watch().map((rows) {
      // The one saved last per owner, as [watchOpen] shows it.
      final seen = <SnapshotOwner>{};
      return [
        for (final row in rows)
          if (_ownerOf(row) case final owner? when seen.add(owner))
            _toDomain(row, owner),
      ];
    });
  }

  /// The owner of [row]; null for a row with neither (the CHECK rules that
  /// out, but a row from a sync is read defensively).
  static SnapshotOwner? _ownerOf(SnapshotRow row) {
    if (row.itemId case final itemId?) return ItemSnapshotOwner(itemId);
    if (row.contextId case final projectId?) {
      return ProjectSnapshotOwner(projectId);
    }
    return null;
  }

  @override
  Future<Snapshot?> open(SnapshotOwner owner) async {
    final rows = await _open(owner).get();
    return rows.isEmpty ? null : _toDomain(rows.first, owner);
  }

  @override
  Future<void> save(
    SnapshotOwner owner, {
    String? nextStep,
    String? inMind,
  }) async {
    final text = snapshotText(nextStep, inMind);
    if (text == null) return resume(owner);
    final writer = _storage.writer;
    await _db.transaction(() async {
      final open = await _open(owner).get();
      final bool changed;
      if (open.isEmpty) {
        await writer.insert(
          _db.snapshots,
          SnapshotsCompanion(
            itemId: Value(switch (owner) {
              ItemSnapshotOwner(:final itemId) => itemId,
              ProjectSnapshotOwner() => null,
            }),
            contextId: Value(switch (owner) {
              ProjectSnapshotOwner(:final projectId) => projectId,
              ItemSnapshotOwner() => null,
            }),
            nextStep: Value(text.nextStep),
            inMind: Value(text.inMind),
          ),
        );
        changed = true;
      } else {
        changed = await writer.update(
          _db.snapshots,
          open.first.id,
          SnapshotsCompanion(
            nextStep: Value(text.nextStep),
            inMind: Value(text.inMind),
          ),
        );
      }
      // Work on the item counts as touching it (point 13 (f)), as Keep in
      // the review does: the field for a touch without a change of content.
      if (changed && owner is ItemSnapshotOwner) {
        await writer.update(
          _db.items,
          owner.itemId,
          ItemsCompanion(reviewedAt: Value(DateTime.now().toUtc())),
        );
      }
    });
  }

  @override
  Future<void> resume(SnapshotOwner owner) => _db.transaction(() async {
    final now = DateTime.now().toUtc();
    for (final row in await _open(owner).get()) {
      await _storage.writer.update(
        _db.snapshots,
        row.id,
        SnapshotsCompanion(resumedAt: Value(now)),
      );
    }
  });

  static Snapshot _toDomain(SnapshotRow row, SnapshotOwner owner) => Snapshot(
    id: row.id,
    owner: owner,
    nextStep: row.nextStep,
    inMind: row.inMind,
    savedAt: hlcTime(row.hlc),
  );
}
