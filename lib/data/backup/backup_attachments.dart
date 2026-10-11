import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../domain/backup/backup.dart';
import '../../platform/cipher/aead_cipher.dart';
import '../attachments/attachment_store.dart';
import '../crypto/digest_sink.dart';

/// The attachments inside a backup file (T7.2b, DD-007 "Backup with
/// attachments" points 1–2, PO 09-10-2026). The backup stays one file: the
/// attachments go into tables of the backup copy only, which AEGIS encrypts
/// with the passphrase like every other page. Plaintext exists only in
/// memory, a chunk at a time, and in those encrypted pages; never on disk.
///
/// ```
/// backup_meta(key TEXT PRIMARY KEY, value TEXT)
///   format_version   1
///   attachments      1 with attachments, 0 without
/// backup_attachments(attachment_id TEXT PRIMARY KEY, size INTEGER, sha256 TEXT)
/// backup_attachment_chunks(attachment_id TEXT, seq INTEGER, data BLOB,
///                          PRIMARY KEY (attachment_id, seq))
/// ```
abstract final class BackupAttachmentTables {
  static const formatVersion = 1;

  /// Plaintext bytes per chunk row.
  static const chunkSize = 1 << 20;

  static const meta = 'backup_meta';
  static const attachments = 'backup_attachments';
  static const chunks = 'backup_attachment_chunks';

  /// Removes the tables from [db]: from a restored copy, and from a database
  /// that still holds them, before a new backup creates them again.
  static void drop(Database db) {
    for (final table in [chunks, attachments, meta]) {
      db.execute('DROP TABLE IF EXISTS $table');
    }
  }

  /// Creates the tables in the backup copy [db] and records whether it
  /// carries attachments.
  static void create(Database db, {required bool withAttachments}) {
    db
      ..execute(
        'CREATE TABLE $meta (key TEXT NOT NULL PRIMARY KEY, value TEXT NOT NULL)',
      )
      ..execute(
        'CREATE TABLE $attachments (attachment_id TEXT NOT NULL PRIMARY KEY, '
        'size INTEGER NOT NULL, sha256 TEXT NOT NULL)',
      )
      ..execute(
        'CREATE TABLE $chunks (attachment_id TEXT NOT NULL, '
        'seq INTEGER NOT NULL, data BLOB NOT NULL, '
        'PRIMARY KEY (attachment_id, seq))',
      );
    final insert = db.prepare('INSERT INTO $meta (key, value) VALUES (?, ?)');
    try {
      insert
        ..execute(['format_version', '$formatVersion'])
        ..execute(['attachments', withAttachments ? '1' : '0']);
    } finally {
      insert.close();
    }
  }
}

/// Where the attachment files of this device are, for a backup: sendable to
/// the backup's isolate. [cipher] makes the platform cipher there.
class BackupAttachmentSource {
  const BackupAttachmentSource({
    required this.directoryPath,
    required this.key,
    required this.cipher,
  });

  final String directoryPath;
  final Uint8List key;
  final AeadCipher Function() cipher;
}

/// What went into a backup.
class BackupAttachmentsResult {
  const BackupAttachmentsResult({
    required this.copied,
    required this.missing,
    required this.bytes,
  });

  /// Attachments in the backup.
  final int copied;

  /// Attachments whose file was gone or did not verify: the backup was made
  /// without them, and says so (DD-007 point 2).
  final int missing;

  /// Plaintext bytes in the backup.
  final int bytes;
}

/// Copies every live attachment of the backup copy [db] (the records the
/// copy itself holds, so files and records match), read and verified from
/// [source], into the chunk tables. Calls [progress] with the plaintext bytes
/// done and the total after each chunk.
Future<BackupAttachmentsResult> copyAttachmentsInto(
  Database db,
  BackupAttachmentSource source, {
  void Function(int done, int total)? progress,
}) async {
  final records = db.select(
    'SELECT id, size_bytes FROM attachments WHERE deleted_at IS NULL '
    'ORDER BY id',
  );
  final total = records.fold<int>(
    0,
    (sum, r) => sum + (r['size_bytes'] as int),
  );
  final store = AttachmentStore(
    directory: Directory(source.directoryPath),
    attachmentsKey: source.key,
    cipher: source.cipher(),
  );
  final insertChunk = db.prepare(
    'INSERT INTO ${BackupAttachmentTables.chunks} '
    '(attachment_id, seq, data) VALUES (?, ?, ?)',
  );
  final insertRecord = db.prepare(
    'INSERT INTO ${BackupAttachmentTables.attachments} '
    '(attachment_id, size, sha256) VALUES (?, ?, ?)',
  );
  var copied = 0;
  var missing = 0;
  var bytes = 0;
  var done = 0;
  try {
    for (final record in records) {
      final id = record['id'] as String;
      final expected = record['size_bytes'] as int;
      var size = 0;
      // One attachment per transaction: a file that fails halfway leaves
      // none of its chunks behind.
      db.execute('BEGIN');
      try {
        final digest = DigestSink();
        final hasher = sha256.startChunkedConversion(digest);
        final chunk = BytesBuilder(copy: false);
        var seq = 0;
        void flush() {
          if (chunk.isEmpty) return;
          insertChunk.execute([id, seq++, chunk.takeBytes()]);
        }

        await for (final segment in store.read(id)) {
          hasher.add(segment);
          size += segment.length;
          chunk.add(segment);
          if (chunk.length >= BackupAttachmentTables.chunkSize) flush();
          progress?.call(min(done + size, total), total);
        }
        flush();
        hasher.close();
        insertRecord.execute([id, size, digest.value!.toString()]);
        db.execute('COMMIT');
        copied++;
        bytes += size;
        done += size;
      } catch (e) {
        // SQLite may have rolled back by itself (a full disk).
        if (!db.autocommit) db.execute('ROLLBACK');
        if (e is! AttachmentCorruptException && e is! FileSystemException) {
          rethrow;
        }
        missing++;
        done += max(expected, size);
      }
      progress?.call(min(done, total), total);
    }
  } finally {
    insertChunk.close();
    insertRecord.close();
  }
  return BackupAttachmentsResult(
    copied: copied,
    missing: missing,
    bytes: bytes,
  );
}

/// What the backup copy [db] says about its attachments: none for a backup
/// from before T7.2b, which has no `backup_meta`.
({int formatVersion, bool withAttachments, int count}) readAttachmentInfo(
  Database db,
) {
  final hasMeta = db.select(
    "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = ?",
    [BackupAttachmentTables.meta],
  ).isNotEmpty;
  if (!hasMeta) return (formatVersion: 0, withAttachments: false, count: 0);
  final meta = {
    for (final row in db.select(
      'SELECT key, value FROM ${BackupAttachmentTables.meta}',
    ))
      row['key'] as String: row['value'] as String,
  };
  final count =
      db
              .select(
                'SELECT count(*) AS n FROM ${BackupAttachmentTables.attachments}',
              )
              .first['n']
          as int;
  return (
    formatVersion: int.tryParse(meta['format_version'] ?? '') ?? 0,
    withAttachments: meta['attachments'] == '1',
    count: count,
  );
}

/// Where a restore puts the attachments, on this device: sendable to the
/// restore's isolate. [cipher] is only needed for a backup with attachments.
class RestoreAttachmentTarget {
  const RestoreAttachmentTarget({
    required this.currentPath,
    required this.stagingPath,
    required this.keepListPath,
    required this.key,
    this.cipher,
  });

  /// The attachments folder in use now.
  final String currentPath;

  /// The new folder, swapped in with the database.
  final String stagingPath;

  /// The ids of files to take over from [currentPath] (a backup without
  /// attachments, PO 09-10-2026 option b), one per line.
  final String keepListPath;

  /// This device's attachments key.
  final Uint8List key;

  final AeadCipher Function()? cipher;
}

/// Prepares the attachments of the restored copy [db] (DD-007 point 3,
/// T7.2b step B): a fresh [RestoreAttachmentTarget.stagingPath] that is
/// swapped in with the database.
///
/// A backup with attachments: every attachment is written there from its
/// chunks, encrypted with this device's key, and checked against its size
/// and SHA-256; any difference throws [BackupException] and nothing is
/// swapped. A backup without (or from before T7.2b): the folder stays empty
/// and the keep list names this device's files that belong to a live record
/// of the copy; they move over once the restored database has opened.
/// Calls [progress] with the plaintext bytes done and the total after each
/// chunk.
Future<void> prepareRestoredAttachments(
  Database db,
  RestoreAttachmentTarget target, {
  void Function(int done, int total)? progress,
}) async {
  final staging = Directory(target.stagingPath);
  if (staging.existsSync()) staging.deleteSync(recursive: true);
  staging.createSync(recursive: true);
  final keep = File(target.keepListPath);
  if (keep.existsSync()) keep.deleteSync();
  final info = readAttachmentInfo(db);

  if (!info.withAttachments) {
    final current = Directory(target.currentPath);
    final ids =
        [
          for (final row in db.select(
            'SELECT id FROM attachments WHERE deleted_at IS NULL ORDER BY id',
          ))
            row['id'] as String,
        ].where(
          (id) =>
              AttachmentStore.isValidId(id) &&
              File('${current.path}${Platform.pathSeparator}$id').existsSync(),
        );
    keep.writeAsStringSync(ids.map((id) => '$id\n').join(), flush: true);
    return;
  }

  final makeCipher = target.cipher;
  if (makeCipher == null) {
    throw const BackupException(BackupProblem.unreadable);
  }
  final store = AttachmentStore(
    directory: staging,
    attachmentsKey: target.key,
    cipher: makeCipher(),
  );
  final chunk = db.prepare(
    'SELECT data FROM ${BackupAttachmentTables.chunks} '
    'WHERE attachment_id = ? AND seq = ?',
  );
  final rows = db.select(
    'SELECT attachment_id, size, sha256 '
    'FROM ${BackupAttachmentTables.attachments} ORDER BY attachment_id',
  );
  final total = rows.fold<int>(0, (sum, r) => sum + (r['size'] as int));
  var done = 0;
  try {
    for (final row in rows) {
      final id = row['attachment_id'] as String;
      // A chunk at a time from the backup: never a whole file in memory.
      Stream<List<int>> chunks() async* {
        for (var seq = 0; ; seq++) {
          final found = chunk.select([id, seq]);
          if (found.isEmpty) return;
          final data = found.first['data'] as Uint8List;
          done += data.length;
          progress?.call(min(done, total), total);
          yield data;
        }
      }

      final stored = await store.write(id, chunks());
      final hash = stored.sha256
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();
      if (stored.size != row['size'] || hash != row['sha256']) {
        throw const BackupException(BackupProblem.unreadable);
      }
    }
  } finally {
    chunk.close();
  }
}
