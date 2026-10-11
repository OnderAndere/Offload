import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/attachments/attachment_format.dart';
import 'package:offload/data/attachments/attachment_store.dart';

import '../../fakes/fake_aead_cipher.dart';

/// The encrypted attachment files (REQ-023, DD-006, DD-007 point 4): format
/// v1 in segments, each authenticated on its own. The cipher is a fake here;
/// the real ones are tested in test/platform/cipher and the integration
/// tests.
void main() {
  const id = '0192a3b4-c5d6-7e8f-9a0b-1c2d3e4f5a6b';
  const otherId = '0192a3b4-c5d6-7e8f-9a0b-000000000000';
  // 1 KiB segments, two per call: small files cover every boundary.
  const shift = 10;
  const segment = 1 << shift;
  late Directory dir;
  late FakeAeadCipher cipher;
  late AttachmentStore store;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('offload_attachments');
    cipher = FakeAeadCipher();
    store = AttachmentStore(
      directory: dir,
      attachmentsKey: Uint8List.fromList(List.generate(32, (i) => i)),
      cipher: cipher,
      random: Random(7),
      segmentShift: shift,
      batchSize: 2,
    );
  });
  tearDown(() => dir.delete(recursive: true));

  Uint8List bytes(int n) =>
      Uint8List.fromList(List.generate(n, (i) => (i * 7 + 3) & 0xFF));

  /// [data] as a stream in pieces of [piece] bytes.
  Stream<List<int>> streamOf(Uint8List data, {int piece = 300}) async* {
    for (var i = 0; i < data.length; i += piece) {
      yield data.sublist(i, min(i + piece, data.length));
    }
  }

  File fileOf(String id) => File('${dir.path}${Platform.pathSeparator}$id');

  group('writes and reads back exactly', () {
    for (final n in [
      0,
      1,
      segment - 1,
      segment,
      segment + 1,
      3 * segment,
      5 * segment + 17,
    ]) {
      test('$n bytes', () async {
        final data = bytes(n);
        final stored = await store.write(id, streamOf(data));
        expect(stored.size, n);
        expect(stored.sha256, sha256.convert(data).bytes);
        expect(
          fileOf(id).lengthSync(),
          encryptedLength(n, segmentShift: shift),
        );
        expect(await store.readAll(id), data);
      });
    }
  });

  test('chunks larger than a segment, and one very large chunk', () async {
    final data = bytes(50 * segment + 7);
    await store.write(id, streamOf(data, piece: 2500));
    expect(await store.readAll(id), data);
    await store.write(id, Stream.value(data));
    expect(await store.readAll(id), data);
  });

  test('segments go to the cipher in batches', () async {
    await store.write(id, streamOf(bytes(5 * segment + 1)));
    // 6 segments, 2 per call.
    expect(cipher.calls, 3);
  });

  test('the plaintext is nowhere in the file', () async {
    final secret = utf8.encode('Bel @Sanne over de moestuin !vr ' * 40);
    await store.write(id, Stream.value(secret));
    final onDisk = latin1.decode(fileOf(id).readAsBytesSync());
    expect(onDisk.contains('Sanne'), isFalse);
    expect(onDisk.contains('moestuin'), isFalse);
  });

  group('refuses a file that was tampered with', () {
    Future<void> refused() => expectLater(
      store.readAll(id),
      throwsA(isA<AttachmentCorruptException>()),
    );

    setUp(() => store.write(id, Stream.value(bytes(3 * segment + 100))));

    test('one bit changed', () async {
      final data = fileOf(id).readAsBytesSync();
      data[AttachmentHeader.length + segment + 5] ^= 1;
      fileOf(id).writeAsBytesSync(data);
      await refused();
    });

    test('cut short after a whole segment', () async {
      final data = fileOf(id).readAsBytesSync();
      final sealed = segment + 16;
      fileOf(
        id,
      ).writeAsBytesSync(data.sublist(0, AttachmentHeader.length + 2 * sealed));
      await refused();
    });

    test('two segments swapped', () async {
      final data = fileOf(id).readAsBytesSync();
      final sealed = segment + 16;
      final a = AttachmentHeader.length;
      final first = data.sublist(a, a + sealed);
      final second = data.sublist(a + sealed, a + 2 * sealed);
      data
        ..setRange(a, a + sealed, second)
        ..setRange(a + sealed, a + 2 * sealed, first);
      fileOf(id).writeAsBytesSync(data);
      await refused();
    });

    test('the header changed', () async {
      final data = fileOf(id).readAsBytesSync();
      data[10] ^= 1; // in the salt
      fileOf(id).writeAsBytesSync(data);
      await refused();
    });

    test('the file of another attachment', () async {
      fileOf(id).renameSync(fileOf(otherId).path);
      await expectLater(
        store.readAll(otherId),
        throwsA(isA<AttachmentCorruptException>()),
      );
    });

    test('not an attachment file at all', () async {
      fileOf(id).writeAsBytesSync(utf8.encode('just some text, not ours'));
      await refused();
    });
  });

  test('a rewrite replaces the file, with a new key', () async {
    await store.write(id, Stream.value(bytes(100)));
    final first = fileOf(id).readAsBytesSync();
    await store.write(id, Stream.value(utf8.encode('new content')));
    expect(utf8.decode(await store.readAll(id)), 'new content');
    expect(
      fileOf(id).readAsBytesSync().sublist(8, 24),
      isNot(first.sublist(8, 24)),
    );
  });

  test('a write that fails leaves no file, not even a partial one', () async {
    Stream<List<int>> failing() async* {
      yield bytes(2 * segment);
      throw const FileSystemException('source gone');
    }

    await expectLater(
      store.write(id, failing()),
      throwsA(isA<FileSystemException>()),
    );
    expect(dir.listSync(), isEmpty);
  });

  test('leftover partial files are removed and never counted', () async {
    await store.write(id, Stream.value(bytes(10)));
    File('${fileOf(otherId).path}.partial').writeAsBytesSync(bytes(500));
    expect(await store.totalBytes(), fileOf(id).lengthSync());
    expect(await store.removeLeftovers(), 1);
    expect(dir.listSync(), hasLength(1));
  });

  test('delete, exists and the total size', () async {
    expect(await store.totalBytes(), 0);
    await store.write(id, Stream.value(bytes(10)));
    expect(store.exists(id), isTrue);
    await store.delete(id);
    await store.delete(id); // Gone already: nothing happens.
    expect(store.exists(id), isFalse);
  });

  test('an id that is not an attachment id is refused', () {
    for (final bad in ['../escape', r'a\b', 'with space', '', 'ABCDEF01-23']) {
      expect(() => store.exists(bad), throwsArgumentError, reason: bad);
    }
  });

  group('the header', () {
    test('survives encoding and parsing', () {
      final header = AttachmentHeader.random(Random(1), segmentShift: 12);
      final parsed = AttachmentHeader.parse(header.encode());
      expect(parsed.segmentShift, 12);
      expect(parsed.salt, header.salt);
      expect(parsed.noncePrefix, header.noncePrefix);
    });

    test('a nonce is prefix, segment number and the last-segment flag', () {
      final header = AttachmentHeader(
        segmentShift: 16,
        salt: Uint8List(16),
        noncePrefix: Uint8List.fromList([1, 2, 3, 4, 5, 6, 7]),
      );
      expect(header.nonce(258, last: false), [
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        0,
        0,
        1,
        2,
        0,
      ]);
      expect(header.nonce(0, last: true), [1, 2, 3, 4, 5, 6, 7, 0, 0, 0, 0, 1]);
    });

    test('set reserved bytes are refused', () {
      for (final reserved in [5, 6, 7, 31]) {
        final data = AttachmentHeader.random(Random(1)).encode()
          ..[reserved] = 1;
        expect(
          () => AttachmentHeader.parse(data),
          throwsA(isA<AttachmentFormatException>()),
          reason: 'byte $reserved',
        );
      }
    });

    test('a newer format version is refused', () {
      final data = AttachmentHeader.random(Random(1)).encode()..[3] = 2;
      expect(
        () => AttachmentHeader.parse(data),
        throwsA(isA<AttachmentFormatException>()),
      );
    });
  });

  test('the size on disk: a tag per 64 KiB, at least one segment', () {
    expect(encryptedLength(0), 32 + 16);
    expect(encryptedLength(10 * 1000 * 1000), 32 + 10000000 + 153 * 16);
  });
}
