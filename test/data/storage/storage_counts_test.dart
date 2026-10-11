import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/database/app_database.dart';
import 'package:offload/data/items/drift_item_repository.dart';
import 'package:offload/data/people/drift_people_repository.dart';
import 'package:offload/data/projects/drift_project_repository.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/data/storage/storage_counts.dart';
import 'package:offload/domain/attachments/attachment.dart';
import 'package:offload/domain/items/item_enums.dart';

import '../../fakes/test_storage.dart';

/// The numbers in Settings → Storage (T7.5, PO 09-10-2026).
void main() {
  late AppStorage storage;

  setUp(() async => storage = await openTestStorage());
  tearDown(() => storage.close());

  test('items with the trash, projects and people outside it', () async {
    final items = DriftItemRepository(storage);
    await items.capture('Offerte kozijnen', source: ItemSource.app);
    final trashed = await items.capture('Weg', source: ItemSource.app);
    await items.moveToTrash(trashed);
    final projects = DriftProjectRepository(storage);
    await projects.create('Verbouwing');
    await projects.archive(await projects.create('Tuin'));
    final db = storage.database;
    final from = await storage.writer.insert(
      db.people,
      const PeopleCompanion(name: Value('Jantje')),
    );
    final into = await storage.writer.insert(
      db.people,
      const PeopleCompanion(name: Value('Jan Jansen')),
    );
    await DriftPeopleRepository(storage).merge(from, into);

    final counts = await readStorageCounts(db);

    expect(counts.items, 2);
    expect(counts.trashedItems, 1);
    expect(counts.projects, 2);
    // The merged one is not counted.
    expect(counts.people, 1);
  });

  test('the attachments per kind, the removed ones not (T5.1)', () async {
    final db = storage.database;
    final item = await DriftItemRepository(
      storage,
    ).capture('Kozijnen', source: ItemSource.app);
    Future<String> add(String mime, int size) => storage.writer.insert(
      db.attachments,
      AttachmentsCompanion(
        itemId: Value(item),
        mimeType: Value(mime),
        sizeBytes: Value(size),
        storagePath: const Value('attachments/x'),
        pipelineVersion: const Value(0),
      ),
    );
    await add('image/jpeg', 400);
    await add('image/png', 100);
    await add('audio/mp4', 2000);
    await storage.writer.delete(db.attachments, await add('audio/mp4', 999));

    expect((await readStorageCounts(db)).attachmentBytes, {
      AttachmentKind.photo: 500,
      AttachmentKind.audio: 2000,
    });
  });

  test('no attachments: nothing per kind', () async {
    expect(
      (await readStorageCounts(storage.database)).attachmentBytes,
      isEmpty,
    );
  });
}
