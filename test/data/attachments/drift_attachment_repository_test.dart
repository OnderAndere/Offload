import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/attachments/attachment_store.dart';
import 'package:offload/data/attachments/drift_attachment_repository.dart';
import 'package:offload/data/database/app_database.dart';
import 'package:offload/data/items/drift_item_repository.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/domain/attachments/attachment.dart';
import 'package:offload/domain/items/item_enums.dart';

import '../../fakes/fake_aead_cipher.dart';
import '../../fakes/test_storage.dart';

/// The attachment records and their files (T5.1 step B, REQ-023, DD-006):
/// written through the change log, never a file without its record.
void main() {
  late AppStorage storage;
  late Directory dir;
  late DriftAttachmentRepository attachments;
  late String itemId;

  setUp(() async {
    storage = await openTestStorage();
    dir = await Directory.systemTemp.createTemp('offload_attachments');
    attachments = DriftAttachmentRepository(
      storage,
      AttachmentStore(
        directory: dir,
        attachmentsKey: Uint8List(32),
        cipher: FakeAeadCipher(),
        random: Random(3),
      ),
    );
    itemId = await DriftItemRepository(
      storage,
    ).capture('Offerte kozijnen', source: ItemSource.app);
  });
  tearDown(() async {
    await storage.close();
    await dir.delete(recursive: true);
  });

  Stream<List<int>> text(String s) => Stream.value(utf8.encode(s));

  test('adds a record and its encrypted file', () async {
    final id = await attachments.add(
      owner: ItemOwner(itemId),
      mimeType: 'audio/mp4',
      content: text('a short voice note'),
    );
    final record = (await attachments.liveFor(ItemOwner(itemId))).single;
    expect(record.id, id);
    expect(record.itemId, itemId);
    expect(record.personId, isNull);
    expect(record.mimeType, 'audio/mp4');
    expect(record.sizeBytes, 'a short voice note'.length);
    expect(record.storagePath, 'attachments/$id');
    expect(record.pipelineVersion, 0);
    expect(attachments.files.exists(id), isTrue);
    expect(
      utf8.decode(await attachments.files.readAll(id)),
      'a short voice note',
    );
  });

  test('the record goes through the change log', () async {
    final id = await attachments.add(
      owner: ItemOwner(itemId),
      mimeType: 'image/jpeg',
      content: text('pixels'),
    );
    final db = storage.database;
    final log = await (db.select(
      db.changeLog,
    )..where((c) => c.entityId.equals(id))).get();
    expect(log, hasLength(1));
  });

  test('removing sets the tombstone, then removes the file', () async {
    final id = await attachments.add(
      owner: ItemOwner(itemId),
      mimeType: 'application/pdf',
      content: text('%PDF'),
    );
    await attachments.delete(id);
    expect(await attachments.liveFor(ItemOwner(itemId)), isEmpty);
    final db = storage.database;
    final row = await (db.select(
      db.attachments,
    )..where((a) => a.id.equals(id))).getSingle();
    expect(row.deletedAt, isNotNull);
    expect(attachments.files.exists(id), isFalse);
  });

  test('a record that cannot be written leaves no file behind', () async {
    // No such item: the foreign key refuses the record.
    await expectLater(
      attachments.add(
        owner: const ItemOwner('0192a3b4-c5d6-7e8f-9a0b-000000000000'),
        mimeType: 'image/jpeg',
        content: text('pixels'),
      ),
      throwsA(anything),
    );
    expect(dir.listSync(recursive: true).whereType<File>(), isEmpty);
  });

  test('a person can own an attachment too (a business card)', () async {
    final personId = await storage.writer.insert(
      storage.database.people,
      const PeopleCompanion(name: Value('Sanne')),
    );
    await attachments.add(
      owner: PersonOwner(personId),
      mimeType: 'image/jpeg',
      content: text('card'),
    );
    expect(await attachments.liveFor(PersonOwner(personId)), hasLength(1));
    expect(await attachments.liveFor(ItemOwner(itemId)), isEmpty);
  });
}
