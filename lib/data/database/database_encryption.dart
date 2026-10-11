import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart';

/// Cipher of SQLite3MultipleCiphers used for the database. The file does not
/// record its cipher, so it is set explicitly on every connection.
const databaseCipher = 'chacha20';

/// How long a connection waits for a lock another connection holds, such as
/// the copy of a backup (T7.2), before giving up. Without it a write during a
/// backup failed at once (review backup step A, 03-10-2026).
const busyTimeoutMs = 10000;

/// Opens the database [file] encrypted with the 256-bit [key] (DD-007).
///
/// Drift runs the database in a background isolate; [applyEncryption] runs
/// for every connection there.
QueryExecutor openEncryptedDatabase(File file, Uint8List key) {
  final keyCopy = Uint8List.fromList(key);
  return NativeDatabase.createInBackground(
    file,
    setup: (db) => applyEncryption(db, keyCopy),
  );
}

/// Makes [db] use SQLite3MultipleCiphers with [key]. Call this before any
/// other statement on every connection, in every isolate.
///
/// Throws [StateError] if the linked SQLite has no cipher support: then
/// `PRAGMA key` would silently do nothing and the file would be plaintext.
/// Throws [SqliteException] if [key] does not open an existing file.
void applyEncryption(Database db, Uint8List key) {
  if (key.length != 32) throw ArgumentError.value(key.length, 'key.length');
  if (db.select('PRAGMA cipher;').isEmpty) {
    throw StateError(
      'SQLite3MultipleCiphers is not linked; refusing to open the database '
      'unencrypted (DD-007).',
    );
  }
  db.execute('PRAGMA busy_timeout = $busyTimeoutMs;');
  db.execute("PRAGMA cipher = '$databaseCipher';");
  // Raw 256-bit key, no passphrase KDF. Hex digits need no escaping.
  final hex = key.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  try {
    db.execute("PRAGMA key = \"x'$hex'\";");
  } on SqliteException catch (e) {
    // The exception text contains the statement, and so the key; it may end
    // up on the start-up error screen. Rethrow without it.
    throw SqliteException(
      extendedResultCode: e.extendedResultCode,
      message: 'PRAGMA key failed',
    );
  }
  // Fails right here with a wrong key, instead of at some later query.
  db.select('SELECT count(*) FROM sqlite_master;');
}
