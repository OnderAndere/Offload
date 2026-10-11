import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:sqlite3/sqlite3.dart';

import '../../domain/backup/backup.dart';
import '../../domain/sync/hlc.dart';
import '../database/database_encryption.dart';
import 'backup_attachments.dart';

/// The cipher of a backup: AEGIS of SQLite3MultipleCiphers, which derives
/// its key from the passphrase with Argon2id (DD-007, decided 03-10-2026).
const backupCipher = 'aegis';

/// Argon2id settings of a backup: time cost (passes), memory cost (KiB),
/// parallelism. The file does not record them, so restoring tries each set
/// of [backupKdfs], the current one first.
typedef BackupKdf = ({int tcost, int mcost, int pcost});

/// The current settings first; older ones stay, so their backups open.
const backupKdfs = <BackupKdf>[(tcost: 3, mcost: 65536, pcost: 1)];

/// Backup files on disk (T7.2). Every step runs in an isolate of its own, so
/// the screen keeps moving, and every file is encrypted from its first byte:
/// nothing of the data is ever written in the clear (CLAUDE.md rule 2).
///
/// Errors never carry the SQL text: it holds the passphrase or the key.
class BackupFiles {
  const BackupFiles._();

  /// Writes an encrypted copy of the database [database] (opened with the
  /// device [key]) to [target], with [passphrase]. The copy holds no
  /// `local_state`: no device settings, no device id, no passphrase.
  ///
  /// With [attachments], every live attachment goes into the copy too,
  /// decrypted a chunk at a time in this isolate and written only into the
  /// copy's encrypted pages (T7.2b, DD-007); [onProgress] hears the bytes done
  /// and the total. Without, the copy records that it carries none.
  static Future<BackupAttachmentsResult> write({
    required File database,
    required Uint8List key,
    required String passphrase,
    required File target,
    BackupAttachmentSource? attachments,
    void Function(int done, int total)? onProgress,
  }) async {
    _checkLength(passphrase);
    final databasePath = database.path;
    final targetPath = target.path;
    final keyCopy = Uint8List.fromList(key);
    // In a helper: a closure here would put [onProgress] in the context the
    // isolate's closure is sent with, and it need not be sendable.
    final progress = onProgress == null ? null : _progressPort(onProgress);
    final progressPort = progress?.sendPort;
    try {
      return await _run(() async {
        final kdf = backupKdfs.first;
        _deleteWithJournal(targetPath);
        try {
          // URI filenames: VACUUM INTO then takes the cipher of the copy.
          // Read-only: the backup never changes the database itself.
          final source = sqlite3.open(
            databasePath,
            mode: OpenMode.readOnly,
            uri: true,
          );
          try {
            applyEncryption(source, keyCopy);
            // Temporary files are not encrypted: none, all in memory.
            source.execute('PRAGMA temp_store = MEMORY');
            source.execute(
              "VACUUM INTO '${_uri(targetPath, passphrase, kdf)}'",
            );
          } finally {
            source.close();
          }
          final copy = _openBackup(targetPath, passphrase, kdf);
          try {
            copy.execute('PRAGMA temp_store = MEMORY');
            // Overwritten, not only unlinked: deleted pages keep no settings.
            copy.execute('PRAGMA secure_delete = ON');
            copy.execute('DELETE FROM local_state');
            // A database restored from a backup made before step B of T7.2b
            // may still hold these tables; they belong to a copy only.
            BackupAttachmentTables.drop(copy);
            BackupAttachmentTables.create(
              copy,
              withAttachments: attachments != null,
            );
            if (attachments == null) {
              return const BackupAttachmentsResult(
                copied: 0,
                missing: 0,
                bytes: 0,
              );
            }
            return await copyAttachmentsInto(
              copy,
              attachments,
              progress: progressPort == null
                  ? null
                  : (done, total) => progressPort.send((done, total)),
            );
          } finally {
            copy.close();
          }
        } catch (_) {
          // Never a partial copy, nor one that still holds local_state.
          _deleteWithJournal(targetPath);
          rethrow;
        }
      });
    } finally {
      progress?.close();
    }
  }

  /// What the backup [backup] holds, opened with [passphrase]. Throws
  /// [BackupException]: [BackupProblem.wrongPassphrase] when it does not open
  /// the file, [BackupProblem.tooNew] when it comes from a newer app than
  /// [appSchemaVersion].
  static Future<BackupInfo> inspect({
    required File backup,
    required String passphrase,
    required int appSchemaVersion,
  }) {
    final path = backup.path;
    return _run(() {
      final db = _openAny(path, passphrase, readOnly: true).db;
      try {
        return _info(db, appSchemaVersion);
      } finally {
        db.close();
      }
    });
  }

  /// Makes [target] a database of this device from the backup [backup]: a
  /// copy, opened with [passphrase] and switched to the device cipher and
  /// [key], with [localState] (this device's own settings) put back. The
  /// backup itself is not changed. Throws [BackupException] as [inspect].
  /// [onProgress] hears the attachment bytes done and the total (T7.2b).
  static Future<BackupInfo> prepareRestore({
    required File backup,
    required String passphrase,
    required Uint8List key,
    required File target,
    required int appSchemaVersion,
    required Map<String, String> localState,
    RestoreAttachmentTarget? attachments,
    void Function(int done, int total)? onProgress,
  }) async {
    final backupPath = backup.path;
    final targetPath = target.path;
    final keyCopy = Uint8List.fromList(key);
    final state = Map.of(localState);
    // In a helper, as in [write]: [onProgress] need not be sendable.
    final progress = onProgress == null ? null : _progressPort(onProgress);
    final progressPort = progress?.sendPort;
    try {
      return await _prepareRestore(
        backupPath: backupPath,
        targetPath: targetPath,
        passphrase: passphrase,
        keyCopy: keyCopy,
        appSchemaVersion: appSchemaVersion,
        state: state,
        attachments: attachments,
        progressPort: progressPort,
      );
    } finally {
      progress?.close();
    }
  }

  /// The isolate part of [prepareRestore]: its closure sees only these
  /// sendable values.
  static Future<BackupInfo> _prepareRestore({
    required String backupPath,
    required String targetPath,
    required String passphrase,
    required Uint8List keyCopy,
    required int appSchemaVersion,
    required Map<String, String> state,
    required RestoreAttachmentTarget? attachments,
    required SendPort? progressPort,
  }) {
    return _run(() async {
      // An earlier copy never stays, whatever happens below.
      _deleteWithJournal(targetPath);
      // Checked on the backup itself first: a wrong passphrase or a newer
      // schema never leaves a copy behind.
      final probe = _openAny(backupPath, passphrase, readOnly: true);
      final BackupInfo info;
      try {
        info = _info(probe.db, appSchemaVersion);
      } finally {
        probe.db.close();
      }
      try {
        File(backupPath).copySync(targetPath);
        final copy = _openBackup(targetPath, passphrase, probe.kdf);
        try {
          copy.execute("PRAGMA cipher = '$databaseCipher'");
          final hex = keyCopy
              .map((b) => b.toRadixString(16).padLeft(2, '0'))
              .join();
          copy.execute("PRAGMA rekey = \"x'$hex'\"");
        } finally {
          copy.close();
        }
        // Opened as the app opens it, which also proves the new key works.
        final restored = sqlite3.open(targetPath);
        try {
          applyEncryption(restored, keyCopy);
          restored.execute('PRAGMA temp_store = MEMORY');
          // The attachments of this restore, ready to swap in with the
          // database (T7.2b step B); a failure here keeps everything as is.
          if (attachments != null) {
            await prepareRestoredAttachments(
              restored,
              attachments,
              progress: progressPort == null
                  ? null
                  : (done, total) => progressPort.send((done, total)),
            );
          }
          // The attachment tables belong to the backup copy only (DD-007
          // point 3); the live database never holds them, nor their pages.
          BackupAttachmentTables.drop(restored);
          restored.execute('VACUUM');
          final insert = restored.prepare(
            'INSERT OR REPLACE INTO local_state (key, value) VALUES (?, ?)',
          );
          try {
            for (final MapEntry(:key, :value) in state.entries) {
              insert.execute([key, value]);
            }
          } finally {
            insert.close();
          }
        } finally {
          restored.close();
        }
      } catch (e) {
        _deleteWithJournal(targetPath);
        if (attachments != null) _discardAttachments(attachments);
        if (e is BackupException) rethrow;
        throw const BackupException(BackupProblem.unreadable);
      }
      return info;
    });
  }

  static void _checkLength(String passphrase) {
    final problem = passphraseProblem(passphrase);
    if (problem != null) throw BackupException(problem);
  }

  /// [path] and its rollback journal, which belongs to that file only.
  static void _deleteWithJournal(String path) {
    for (final name in [path, '$path-journal']) {
      final file = File(name);
      if (file.existsSync()) file.deleteSync();
    }
  }

  /// Removes what a failed restore prepared for the attachments.
  static void _discardAttachments(RestoreAttachmentTarget target) {
    final staging = Directory(target.stagingPath);
    if (staging.existsSync()) staging.deleteSync(recursive: true);
    final keep = File(target.keepListPath);
    if (keep.existsSync()) keep.deleteSync();
  }

  /// A port that hands the (done, total) pairs it gets to [onProgress].
  static ReceivePort _progressPort(void Function(int, int) onProgress) {
    final port = ReceivePort();
    port.listen((message) {
      final (done, total) = message as (int, int);
      onProgress(done, total);
    });
    return port;
  }

  /// Runs [work] in an isolate; any error but a [BackupException] becomes
  /// [BackupProblem.unreadable], without its text.
  static Future<T> _run<T>(FutureOr<T> Function() work) async {
    try {
      return await Isolate.run(work);
    } on BackupException {
      rethrow;
    } catch (_) {
      throw const BackupException(BackupProblem.unreadable);
    }
  }

  /// The backup at [path] opened with [passphrase] by the first settings of
  /// [backupKdfs] that open it.
  static ({Database db, BackupKdf kdf}) _openAny(
    String path,
    String passphrase, {
    bool readOnly = false,
  }) {
    if (!File(path).existsSync()) {
      throw const BackupException(BackupProblem.unreadable);
    }
    for (final kdf in backupKdfs) {
      try {
        return (
          db: _openBackup(path, passphrase, kdf, readOnly: readOnly),
          kdf: kdf,
        );
      } on BackupException {
        continue;
      }
    }
    throw const BackupException(BackupProblem.wrongPassphrase);
  }

  /// The backup at [path] with [passphrase] and [kdf]; throws
  /// [BackupProblem.wrongPassphrase] when they do not open it.
  static Database _openBackup(
    String path,
    String passphrase,
    BackupKdf kdf, {
    bool readOnly = false,
  }) {
    final db = sqlite3.open(
      path,
      mode: readOnly ? OpenMode.readOnly : OpenMode.readWrite,
    );
    try {
      if (db.select('PRAGMA cipher;').isEmpty) {
        throw StateError('SQLite3MultipleCiphers is not linked (DD-007)');
      }
      db.execute('PRAGMA busy_timeout = $busyTimeoutMs');
      db.execute("PRAGMA cipher = '$backupCipher'");
      db.execute('PRAGMA tcost = ${kdf.tcost}');
      db.execute('PRAGMA mcost = ${kdf.mcost}');
      db.execute('PRAGMA pcost = ${kdf.pcost}');
      db.execute("PRAGMA key = '${passphrase.replaceAll("'", "''")}'");
      db.select('SELECT count(*) FROM sqlite_master;');
      return db;
    } on SqliteException {
      db.close();
      throw const BackupException(BackupProblem.wrongPassphrase);
    } catch (_) {
      db.close();
      rethrow;
    }
  }

  static BackupInfo _info(Database db, int appSchemaVersion) {
    final version = db.select('PRAGMA user_version').first.values.first as int;
    if (version > appSchemaVersion) {
      throw const BackupException(BackupProblem.tooNew);
    }
    final items =
        db
                .select(
                  'SELECT count(*) AS n FROM items WHERE deleted_at IS NULL',
                )
                .first['n']
            as int;
    final newest = db.select('SELECT max(hlc) AS h FROM change_log').first['h'];
    final attachments = readAttachmentInfo(db);
    // A newer layout of the attachment tables: a newer app made it.
    if (attachments.formatVersion > BackupAttachmentTables.formatVersion) {
      throw const BackupException(BackupProblem.tooNew);
    }
    return (
      schemaVersion: version,
      withAttachments: attachments.withAttachments,
      attachments: attachments.count,
      items: items,
      newestChange: newest is String
          ? DateTime.fromMillisecondsSinceEpoch(
              Hlc.parse(newest).millis,
              isUtc: true,
            )
          : null,
    );
  }

  /// The URI of a new backup file at [path]: cipher, Argon2id settings and
  /// the passphrase as parameters, escaped for both the URI and the SQL text.
  static String _uri(String path, String passphrase, BackupKdf kdf) {
    final key = Uri.encodeComponent(passphrase);
    return '${Uri.file(path)}?cipher=$backupCipher'
            '&tcost=${kdf.tcost}&mcost=${kdf.mcost}&pcost=${kdf.pcost}'
            '&key=$key'
        .replaceAll("'", '%27');
  }
}
