import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/database/app_database.dart';
import 'package:offload/data/database/database_encryption.dart';
import 'package:sqlite3/sqlite3.dart';

const _marker = 'PLAINTEXT_MARKER_7f3a';

Uint8List _key(int seed) =>
    Uint8List.fromList(List.generate(32, (i) => (i * 7 + seed) & 0xff));

/// True if [file] exists and contains [text] as raw bytes.
bool _containsText(File file, String text) =>
    file.existsSync() &&
    String.fromCharCodes(file.readAsBytesSync()).contains(text);

void main() {
  late Directory dir;
  late File file;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('offload_db_test');
    file = File('${dir.path}/offload.db');
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Future<void> writeMarker(Uint8List key) async {
    final db = AppDatabase(openEncryptedDatabase(file, key));
    await db.customStatement(
      'INSERT INTO local_state (key, value) VALUES (?, ?)',
      ['probe', _marker],
    );
    await db.close();
  }

  test('the file on disk does not contain the plaintext', () async {
    await writeMarker(_key(1));
    expect(file.existsSync(), isTrue);
    expect(_containsText(file, _marker), isFalse);
    expect(_containsText(file, 'SQLite format 3'), isFalse);
  });

  test('the same key opens the database again', () async {
    await writeMarker(_key(1));
    final db = AppDatabase(openEncryptedDatabase(file, _key(1)));
    final rows = await db
        .customSelect("SELECT value FROM local_state WHERE key = 'probe'")
        .get();
    expect(rows.single.read<String>('value'), _marker);
    await db.close();
  });

  test('a wrong key cannot open the database', () async {
    await writeMarker(_key(1));
    final db = AppDatabase(openEncryptedDatabase(file, _key(2)));
    await expectLater(
      db.customSelect('SELECT count(*) FROM local_state').get(),
      // Drift runs the database in an isolate and wraps the SqliteException
      // (its wrapper type is experimental API, so match on the message).
      // Code 26 is SQLITE_NOTADB: the key does not decrypt the file.
      throwsA(
        isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('SqliteException(26)'),
        ),
      ),
    );
    await db.close();
  });

  test('the cipher is set explicitly to chacha20', () {
    final db = sqlite3.open(file.path);
    applyEncryption(db, _key(1));
    expect(db.select('PRAGMA cipher;').single.values.single, databaseCipher);
    db.close();
  });

  test('every connection waits for a lock instead of failing', () {
    final db = sqlite3.open(file.path);
    applyEncryption(db, _key(1));
    expect(
      db.select('PRAGMA busy_timeout;').single.values.single,
      busyTimeoutMs,
    );
    db.close();
  });

  test('WAL files are encrypted too', () {
    final db = sqlite3.open(file.path);
    applyEncryption(db, _key(1));
    db
      ..execute('PRAGMA journal_mode = WAL;')
      ..execute('CREATE TABLE t (x TEXT);')
      ..execute('INSERT INTO t VALUES (?);', [_marker]);
    final wal = File('${file.path}-wal');
    expect(wal.existsSync(), isTrue);
    expect(_containsText(wal, _marker), isFalse);
    db.close();
  });

  test('FTS5 is available in the linked SQLite (REQ-011)', () {
    final db = sqlite3.open(file.path);
    applyEncryption(db, _key(1));
    db.execute('CREATE VIRTUAL TABLE f USING fts5(x);');
    db.close();
  });

  test('rejects a key that is not 256 bits', () {
    final db = sqlite3.open(file.path);
    expect(() => applyEncryption(db, Uint8List(16)), throwsArgumentError);
    db.close();
  });
}
