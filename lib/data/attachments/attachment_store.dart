import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../../platform/cipher/aead_cipher.dart';
import '../crypto/digest_sink.dart';
import 'attachment_format.dart';

/// The encrypted files of the attachments (REQ-023, DD-006): one file per
/// attachment, `<directory>/<attachment id>`, in the format of
/// [AttachmentHeader]. Plaintext never touches the disk (CLAUDE.md rule 2):
/// it streams in, is sealed a batch of segments at a time, and only
/// ciphertext is written; reading verifies every segment before handing it
/// on, so nothing unverified leaves the store.
///
/// A file is written as `<id>.partial` and renamed when complete, so a
/// stopped write never looks like a finished file; [removeLeftovers] clears
/// what such a stop left behind (ciphertext only).
class AttachmentStore {
  AttachmentStore({
    required this.directory,
    required Uint8List attachmentsKey,
    required this.cipher,
    Random? random,
    this.segmentShift = AttachmentHeader.defaultSegmentShift,
    this.batchSize = 16,
    this.variant = AttachmentVariant.file,
  }) : _key = attachmentsKey,
       _random = random ?? Random.secure() {
    if (attachmentsKey.length != AeadCipher.keyLength) {
      throw ArgumentError.value(attachmentsKey.length, 'attachmentsKey.length');
    }
  }

  final Directory directory;
  final Uint8List _key;

  /// AES-256-GCM from the platform (DD-006).
  final AeadCipher cipher;
  final Random _random;

  /// Plaintext per segment is 2^[segmentShift] bytes (64 KiB).
  final int segmentShift;

  /// Segments per call to the cipher: one platform crossing on Android.
  final int batchSize;

  /// Which file of an attachment this store keeps (DD-006/D3): a store of
  /// thumbnails opens no attachment, nor the reverse.
  final AttachmentVariant variant;

  static const _partial = '.partial';

  /// Lower case only: the id is part of the key, and a case-insensitive
  /// file system (Windows) would otherwise open one file under two ids.
  static final _id = RegExp(r'^[0-9a-f-]{8,64}$');

  /// Whether [id] can name an attachment file: lower-case hex and hyphens.
  static bool isValidId(String id) => _id.hasMatch(id);

  File _file(String id) {
    if (!_id.hasMatch(id)) throw ArgumentError.value(id, 'id');
    return File('${directory.path}${Platform.pathSeparator}$id');
  }

  /// Encrypts [plaintext] as the file of attachment [id], replacing any
  /// earlier one. Returns the plaintext's size and SHA-256.
  Future<StoredAttachment> write(String id, Stream<List<int>> plaintext) async {
    final target = _file(id);
    await directory.create(recursive: true);
    final partial = File('${target.path}$_partial');
    final header = AttachmentHeader.random(_random, segmentShift: segmentShift);
    final key = header.fileKey(_key, id, variant: variant);
    final aad = header.associatedData(id, variant: variant);
    final size = header.segmentSize;
    final digest = DigestSink();
    final hasher = sha256.startChunkedConversion(digest);
    final file = await partial.open(mode: FileMode.write);
    var total = 0;
    var index = 0;
    final batch = <AeadMessage>[];

    Future<void> flushBatch() async {
      if (batch.isEmpty) return;
      final sealed = await cipher.seal(key, batch);
      for (final segment in sealed) {
        await file.writeFrom(segment);
      }
      batch.clear();
    }

    Future<void> add(Uint8List segment, {required bool last}) async {
      batch.add(
        AeadMessage(
          nonce: header.nonce(index++, last: last),
          aad: aad,
          data: segment,
        ),
      );
      if (batch.length >= batchSize || last) await flushBatch();
    }

    try {
      await file.writeFrom(header.encode());
      // The segment being filled, a copy: a source may reuse its buffer once
      // it has yielded it, and the hash above already saw these bytes. Each
      // byte is copied once, whatever the size of the chunks.
      final filling = BytesBuilder();
      // A full segment is only sealed once more data follows: the last
      // segment must be marked as such, even when it is a full one.
      Uint8List? full;
      await for (final chunk in plaintext) {
        hasher.add(chunk);
        total += chunk.length;
        final data = chunk is Uint8List ? chunk : Uint8List.fromList(chunk);
        var offset = 0;
        while (offset < data.length) {
          if (full != null) {
            await add(full, last: false);
            full = null;
          }
          final take = min(size - filling.length, data.length - offset);
          filling.add(Uint8List.sublistView(data, offset, offset + take));
          offset += take;
          if (filling.length == size) full = filling.takeBytes();
        }
      }
      await add(full ?? filling.takeBytes(), last: true);
      // On disk before the rename, so a crash leaves the old file or the
      // whole new one.
      await file.flush();
      await file.close();
      await partial.rename(target.path);
    } catch (_) {
      await file.close().catchError((Object _) => file);
      if (partial.existsSync()) partial.deleteSync();
      rethrow;
    } finally {
      key.fillRange(0, key.length, 0);
    }
    hasher.close();
    return StoredAttachment(
      size: total,
      sha256: Uint8List.fromList(digest.value!.bytes),
    );
  }

  /// The plaintext of attachment [id], a verified segment at a time. Throws
  /// [AttachmentCorruptException] when the file was changed, cut short or
  /// does not belong to [id], and [FileSystemException] when it is missing.
  Stream<Uint8List> read(String id) async* {
    final file = await _file(id).open();
    try {
      final length = await file.length();
      final header = AttachmentHeader.parse(
        await file.read(AttachmentHeader.length),
      );
      final sealedSize = header.segmentSize + AeadCipher.tagLength;
      final body = length - AttachmentHeader.length;
      if (body < AeadCipher.tagLength) {
        throw const AttachmentCorruptException('no segments');
      }
      final count = (body + sealedSize - 1) ~/ sealedSize;
      if (body - (count - 1) * sealedSize < AeadCipher.tagLength) {
        throw const AttachmentCorruptException('last segment cut short');
      }
      final aad = header.associatedData(id, variant: variant);
      final key = header.fileKey(_key, id, variant: variant);
      try {
        for (var first = 0; first < count; first += batchSize) {
          final messages = <AeadMessage>[];
          for (var i = first; i < min(first + batchSize, count); i++) {
            final sealed = await file.read(
              i == count - 1 ? body - i * sealedSize : sealedSize,
            );
            messages.add(
              AeadMessage(
                nonce: header.nonce(i, last: i == count - 1),
                aad: aad,
                data: sealed,
              ),
            );
          }
          final List<Uint8List> plain;
          try {
            plain = await cipher.open(key, messages);
          } on AeadAuthenticationException {
            throw const AttachmentCorruptException('a segment did not verify');
          }
          for (final segment in plain) {
            yield segment;
          }
        }
      } finally {
        key.fillRange(0, key.length, 0);
      }
    } on AttachmentFormatException catch (e) {
      throw AttachmentCorruptException(e.message);
    } finally {
      await file.close();
    }
  }

  /// The whole plaintext of attachment [id] in memory (a photo to show).
  Future<Uint8List> readAll(String id) async {
    final out = BytesBuilder(copy: false);
    await for (final segment in read(id)) {
      out.add(segment);
    }
    return out.takeBytes();
  }

  bool exists(String id) => _file(id).existsSync();

  /// Removes the file of attachment [id]; nothing happens when it is gone.
  Future<void> delete(String id) async {
    final file = _file(id);
    if (await file.exists()) await file.delete();
  }

  /// The bytes the attachment files take on disk (Settings → Storage).
  Future<int> totalBytes() async {
    if (!await directory.exists()) return 0;
    var total = 0;
    await for (final entity in directory.list()) {
      if (entity is File && !entity.path.endsWith(_partial)) {
        total += await entity.length();
      }
    }
    return total;
  }

  /// Removes what a stopped write left behind; returns how many files.
  Future<int> removeLeftovers() async => removeLeftoversIn(directory);

  /// [removeLeftovers] for the attachments in [directory], at start, before
  /// any write (AppStorage.open). Only ever ciphertext.
  /// Never fails: a leftover that cannot go now (locked by a virus scanner
  /// or an indexer on Windows) goes at the next start, and must not keep
  /// the app from opening.
  static int removeLeftoversIn(Directory directory) {
    var removed = 0;
    try {
      if (!directory.existsSync()) return 0;
      for (final entity in directory.listSync()) {
        if (entity is File && entity.path.endsWith(_partial)) {
          try {
            entity.deleteSync();
            removed++;
          } on FileSystemException {
            // Next start.
          }
        }
      }
    } on FileSystemException {
      // The folder cannot be read now; next start.
    }
    return removed;
  }
}

/// What [AttachmentStore.write] stored: the plaintext's size and SHA-256
/// (the backup checks restored files against it, DD-007).
class StoredAttachment {
  const StoredAttachment({required this.size, required this.sha256});

  final int size;
  final Uint8List sha256;
}

/// An attachment file that does not decrypt: changed, cut short, or not the
/// file of this attachment.
class AttachmentCorruptException implements Exception {
  const AttachmentCorruptException(this.message);

  final String message;

  @override
  String toString() => 'AttachmentCorruptException: $message';
}
