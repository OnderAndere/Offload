import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/database/app_database.dart';
import 'package:offload/data/items/drift_item_repository.dart';
import 'package:offload/data/projects/drift_project_repository.dart';
import 'package:offload/data/snapshots/drift_snapshot_repository.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/domain/snapshots/snapshot.dart';
import 'package:offload/domain/sync/change_operation.dart';

import '../../fakes/test_storage.dart';

/// "Where was I" on the database (T10.3 step A, REQ-049, DD-018 point 13).
void main() {
  late AppStorage storage;
  late DriftSnapshotRepository snapshots;
  late String item;
  late ItemSnapshotOwner owner;

  setUp(() async {
    storage = await openTestStorage();
    snapshots = DriftSnapshotRepository(storage);
    item = await DriftItemRepository(
      storage,
    ).capture('Offerte kozijnen vergelijken', source: ItemSource.app);
    owner = ItemSnapshotOwner(item);
  });
  tearDown(() => storage.close());

  AppDatabase db() => storage.database;

  /// Every row of the table, read once.
  Future<List<SnapshotRow>> rows() => db().select(db().snapshots).get();

  Future<DateTime?> reviewedAt() async => (await (db().select(
    db().items,
  )..where((i) => i.id.equals(item))).getSingle()).reviewedAt;

  test('saving starts a note; the open one is watched', () async {
    await snapshots.save(owner, nextStep: '  Prijzen in tabel ', inMind: '');
    final open = await snapshots
        .watchOpen(owner)
        .first
        .timeout(const Duration(seconds: 5));
    expect(open?.nextStep, 'Prijzen in tabel');
    expect(open?.inMind, isNull);
    expect(open?.savedAt, isNotNull);
    final row = (await rows()).single;
    expect(row.itemId, item);
    expect(row.contextId, isNull);
  });

  test('saving again updates the open note: one row', () async {
    await snapshots.save(owner, nextStep: 'Eerste');
    await snapshots.save(owner, nextStep: 'Tweede', inMind: 'B is goedkoper');
    final row = (await rows()).single;
    expect(row.nextStep, 'Tweede');
    expect(row.inMind, 'B is goedkoper');
  });

  test('saving counts as touching the item; unchanged does not', () async {
    expect(await reviewedAt(), isNull);
    await snapshots.save(owner, nextStep: 'Bellen');
    final touched = await reviewedAt();
    expect(touched, isNotNull);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await snapshots.save(owner, nextStep: 'Bellen');
    expect(await reviewedAt(), touched);
  });

  test('resume closes the note and keeps it; not a touch', () async {
    await snapshots.save(owner, nextStep: 'Bellen');
    final touched = await reviewedAt();
    await snapshots.resume(owner);
    final row = (await rows()).single;
    expect(row.resumedAt, isNotNull);
    expect(await reviewedAt(), touched);
    // A new save after resuming starts a new note.
    await snapshots.save(owner, inMind: 'Toch nog iets');
    expect(await rows(), hasLength(2));
  });

  test('both fields empty resumes the open note, or saves nothing', () async {
    await snapshots.save(owner, nextStep: '  ', inMind: '');
    expect(await rows(), isEmpty);
    await snapshots.save(owner, nextStep: 'Bellen');
    await snapshots.save(owner, nextStep: '', inMind: ' ');
    expect((await rows()).single.resumedAt, isNotNull);
  });

  test('a project has notes of its own, without a touch', () async {
    final project = await DriftProjectRepository(storage).create('Verbouwing');
    await snapshots.save(
      ProjectSnapshotOwner(project),
      nextStep: 'Kozijnen kiezen',
    );
    final row = (await rows()).single;
    expect(row.contextId, project);
    expect(row.itemId, isNull);
    expect(await reviewedAt(), isNull);
  });

  test(
    'two open notes after a sync: the last shows, resume closes both',
    () async {
      // As two devices would: two open notes on one item.
      for (final text in ['Van de telefoon', 'Van de laptop']) {
        await storage.writer.insert(
          db().snapshots,
          SnapshotsCompanion(itemId: Value(item), nextStep: Value(text)),
        );
      }
      final open = await snapshots
          .watchOpen(owner)
          .first
          .timeout(const Duration(seconds: 5));
      expect(open?.nextStep, 'Van de laptop');
      await snapshots.resume(owner);
      expect([
        for (final r in await rows()) r.resumedAt,
      ], everyElement(isNotNull));
    },
  );

  test('all open notes: one per owner, the last saved; resumed ones '
      'left out (T4b.2)', () async {
    final project = await DriftProjectRepository(storage).create('Verbouwing');
    final other = await DriftItemRepository(
      storage,
    ).capture('Tuinplan tekenen', source: ItemSource.app);
    // As two devices would: two open notes on one item.
    for (final text in ['Van de telefoon', 'Van de laptop']) {
      await storage.writer.insert(
        db().snapshots,
        SnapshotsCompanion(itemId: Value(item), nextStep: Value(text)),
      );
    }
    await snapshots.save(
      ProjectSnapshotOwner(project),
      inMind: 'Kozijnen kiezen',
    );
    await snapshots.save(ItemSnapshotOwner(other), nextStep: 'Schets');
    await snapshots.resume(ItemSnapshotOwner(other));

    final open = await snapshots.watchAllOpen().first.timeout(
      const Duration(seconds: 5),
    );
    expect(
      {for (final note in open) note.owner: note.nextStep ?? note.inMind},
      {
        owner: 'Van de laptop',
        ProjectSnapshotOwner(project): 'Kozijnen kiezen',
      },
    );
    expect(open, hasLength(2));
  });

  test('every change goes through the change log', () async {
    await snapshots.save(owner, nextStep: 'Bellen');
    await snapshots.resume(owner);
    final log = await (db().select(
      db().changeLog,
    )..where((c) => c.entity.equals('snapshots'))).get();
    expect(
      [for (final e in log) e.operation],
      [ChangeOperation.insert, ChangeOperation.update],
    );
  });

  test('the database allows one owner and some text, never less', () async {
    expect(
      () => storage.writer.insert(
        db().snapshots,
        const SnapshotsCompanion(nextStep: Value('Zonder eigenaar')),
      ),
      throwsA(anything),
    );
    expect(
      () => storage.writer.insert(
        db().snapshots,
        SnapshotsCompanion(itemId: Value(item)),
      ),
      throwsA(anything),
    );
  });
}
