import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:offload/data/attachments/attachment_format.dart';
import 'package:offload/data/attachments/attachment_store.dart';
import 'package:offload/data/attachments/drift_attachment_repository.dart';
import 'package:offload/data/attachments/photo_compressor.dart';
import 'package:offload/data/attachments/photo_storage_service.dart';
import 'package:offload/data/items/drift_item_repository.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/domain/attachments/attachment.dart';
import 'package:offload/domain/attachments/image_policy.dart';
import 'package:offload/domain/items/item_enums.dart';

import '../../fakes/fake_aead_cipher.dart';
import '../../fakes/fake_key_store.dart';

/// Photos as attachments (T5.2, REQ-027, REQ-032, DD-006 D1, D3, D8, D9):
/// two encrypted files under one id, the thumbnail's path derived, deleting
/// both, a missing thumbnail made again.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;
  late AppStorage storage;
  late PhotoStorageService photos;
  late ItemOwner owner;
  late FakeKeyStore keys;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('offload_photos');
    keys = FakeKeyStore();
    storage = await AppStorage.open(directory: dir, keyStore: keys);
    AttachmentStore store(Directory folder, AttachmentVariant variant) =>
        AttachmentStore(
          directory: folder,
          attachmentsKey: storage.attachmentsKey!,
          cipher: FakeAeadCipher(),
          random: Random(5),
          variant: variant,
        );
    photos = PhotoStorageService(
      attachments: DriftAttachmentRepository(
        storage,
        store(storage.attachmentsDirectory!, AttachmentVariant.file),
      ),
      thumbnails: store(
        storage.thumbnailsDirectory!,
        AttachmentVariant.thumbnail,
      ),
    );
    owner = ItemOwner(
      await DriftItemRepository(
        storage,
      ).capture('Whiteboard van het overleg', source: ItemSource.app),
    );
  });
  tearDown(() async {
    await storage.close();
    dir.deleteSync(recursive: true);
  });

  Uint8List photo() =>
      img.encodeJpg(img.Image(width: 2400, height: 1800), quality: 90);

  File displayFile(String id) =>
      File('${storage.attachmentsDirectory!.path}/$id');
  File thumbnailFile(String id) =>
      File('${storage.thumbnailsDirectory!.path}/$id');

  test('one photo: a record, the display version and the thumbnail under '
      'the derived path', () async {
    final id = await photos.add(owner: owner, source: photo());

    expect(
      storage.thumbnailsDirectory!.path,
      endsWith('attachments${Platform.pathSeparator}thumbs'),
    );
    expect(displayFile(id).existsSync(), isTrue);
    expect(thumbnailFile(id).existsSync(), isTrue);
    final record = await (storage.database.select(
      storage.database.attachments,
    )..where((a) => a.id.equals(id))).getSingle();
    expect(record.mimeType, 'image/jpeg');
    expect(record.pipelineVersion, photoPipelineVersion);
    expect(record.storagePath, 'attachments/$id');

    final display = img.decodeJpg(await photos.display(id))!;
    final thumbnail = img.decodeJpg(await photos.thumbnail(id))!;
    expect((display.width, display.height), (1600, 1200));
    expect((thumbnail.width, thumbnail.height), (256, 192));
    expect(record.sizeBytes, (await photos.display(id)).length);
  });

  test('nothing but ciphertext on disk', () async {
    final id = await photos.add(owner: owner, source: photo());
    for (final file in [displayFile(id), thumbnailFile(id)]) {
      final bytes = file.readAsBytesSync();
      // A JPEG starts with FF D8; the store's files with its header.
      expect(bytes.take(3), 'OFA'.codeUnits);
    }
  });

  test('deleting removes both files (DD-006/D8)', () async {
    final id = await photos.add(owner: owner, source: photo());
    await photos.delete(id);
    expect(displayFile(id).existsSync(), isFalse);
    expect(thumbnailFile(id).existsSync(), isFalse);
  });

  test('a missing thumbnail is made again and kept (DD-006/D9)', () async {
    final id = await photos.add(owner: owner, source: photo());
    thumbnailFile(id).deleteSync();

    final again = img.decodeJpg(await photos.thumbnail(id))!;
    expect((again.width, again.height), (256, 192));
    expect(thumbnailFile(id).existsSync(), isTrue);
  });

  test('asked twice at once, a missing thumbnail is made once (review '
      'T5.2)', () async {
    final id = await photos.add(owner: owner, source: photo());
    thumbnailFile(id).deleteSync();

    final both = await Future.wait([
      photos.thumbnail(id),
      photos.thumbnail(id),
    ]);
    expect(both[0], same(both[1]));
    expect(thumbnailFile(id).existsSync(), isTrue);
    expect(await photos.thumbnail(id), both[0]);
  });

  test('a display version put in the thumbnail\'s place does not open as '
      'one: the variant is in the key (review T5.1)', () async {
    final id = await photos.add(owner: owner, source: photo());
    displayFile(id).copySync(thumbnailFile(id).path);

    await expectLater(
      photos.thumbnails.readAll(id),
      throwsA(isA<AttachmentCorruptException>()),
    );
    // The service makes a real thumbnail instead of showing the swap.
    final made = img.decodeJpg(await photos.thumbnail(id))!;
    expect(made.width, 256);
  });

  test('no picture: nothing is kept', () async {
    await expectLater(
      photos.add(owner: owner, source: Uint8List.fromList(List.filled(99, 1))),
      throwsA(isA<PhotoFormatException>()),
    );
    expect(
      await storage.database.select(storage.database.attachments).get(),
      isEmpty,
    );
    expect(
      storage.thumbnailsDirectory!.existsSync()
          ? storage.thumbnailsDirectory!.listSync()
          : const [],
      isEmpty,
    );
  });

  test('a thumbnail written halfway is cleared at the next start', () async {
    final id = await photos.add(owner: owner, source: photo());
    final partial = File('${thumbnailFile(id).path}.partial')
      ..writeAsBytesSync([1, 2, 3]);
    await storage.close();
    storage = await AppStorage.open(directory: dir, keyStore: keys);
    expect(partial.existsSync(), isFalse);
    expect(thumbnailFile(id).existsSync(), isTrue);
  });

  test('the photos of an item as they change, oldest first, and whether '
      'each file is here (T5.3)', () async {
    final seen = <List<String>>[];
    final watching = photos.attachments
        .watchFor(owner)
        .listen((records) => seen.add([for (final r in records) r.id]));
    final first = await photos.add(owner: owner, source: photo());
    final second = await photos.add(owner: owner, source: photo());
    await photos.delete(first);
    await pumpEventQueue();
    await watching.cancel();

    expect(seen.first, isEmpty);
    expect(seen, anyElement(equals([first, second])));
    expect(seen.last, [second]);

    expect(photos.hasDisplay(second), isTrue);
    expect(photos.hasDisplay(first), isFalse);
    // As after restoring a backup without attachments.
    displayFile(second).deleteSync();
    expect(photos.hasDisplay(second), isFalse);
  });
}
