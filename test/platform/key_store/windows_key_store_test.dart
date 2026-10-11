@TestOn('windows')
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:offload/platform/key_store/key_store.dart';
import 'package:offload/platform/key_store/windows_key_store.dart';

/// Runs against the real DPAPI of the current Windows user.
void main() {
  late Directory dir;
  late WindowsKeyStore store;
  final key = Uint8List.fromList(List.generate(32, (i) => 200 - i));

  setUp(() {
    dir = Directory.systemTemp.createTempSync('offload_key_test');
    store = WindowsKeyStore(directory: dir, name: 'test_key');
  });
  tearDown(() => dir.deleteSync(recursive: true));

  File keyFile() => File('${dir.path}\\test_key.key');

  test('no key file means no key', () async {
    expect(await store.readMasterKey(), isNull);
  });

  test('a created key reads back unchanged', () async {
    await store.createMasterKey(key);
    expect(await store.readMasterKey(), key);
    expect(
      await WindowsKeyStore(directory: dir, name: 'test_key').readMasterKey(),
      key,
    );
  });

  test('the file holds a DPAPI blob, not the key', () async {
    await store.createMasterKey(key);
    final bytes = keyFile().readAsBytesSync();
    final content = String.fromCharCodes(bytes);
    expect(content.contains(String.fromCharCodes(key)), isFalse);
    expect(bytes.length, greaterThan(key.length + 1));
  });

  test('an existing key is never overwritten', () async {
    await store.createMasterKey(key);
    await expectLater(
      store.createMasterKey(Uint8List(32)),
      throwsA(
        isA<KeyStoreException>().having(
          (e) => e.code,
          'code',
          KeyStoreErrorCode.alreadyExists,
        ),
      ),
    );
    expect(await store.readMasterKey(), key);
  });

  test('a damaged key file is an error, not "no key"', () async {
    await store.createMasterKey(key);
    final bytes = keyFile().readAsBytesSync();
    bytes[bytes.length ~/ 2] ^= 0xff;
    keyFile().writeAsBytesSync(bytes);
    await expectLater(
      store.readMasterKey(),
      throwsA(
        isA<KeyStoreException>().having(
          (e) => e.code,
          'code',
          KeyStoreErrorCode.unavailable,
        ),
      ),
    );
  });

  test('another key name cannot unwrap the blob', () async {
    await store.createMasterKey(key);
    File(
      '${dir.path}\\other_key.key',
    ).writeAsBytesSync(keyFile().readAsBytesSync());
    await expectLater(
      WindowsKeyStore(directory: dir, name: 'other_key').readMasterKey(),
      throwsA(isA<KeyStoreException>()),
    );
  });

  test('the production key cannot be deleted', () async {
    await expectLater(
      WindowsKeyStore(directory: dir).deleteForTesting(),
      throwsStateError,
    );
  });

  test('a directory that cannot be created is a KeyStoreException', () async {
    // A file where the directory should be: creating it fails.
    final blocker = File('${dir.path}${Platform.pathSeparator}blocked')
      ..writeAsStringSync('x');
    final blocked = WindowsKeyStore(
      directory: Directory(blocker.path),
      name: 'test_key',
    );

    await expectLater(
      blocked.createMasterKey(key),
      throwsA(
        isA<KeyStoreException>().having(
          (e) => e.code,
          'code',
          KeyStoreErrorCode.unavailable,
        ),
      ),
    );
    expect(dir.listSync().whereType<File>().map((f) => f.path), [blocker.path]);
  });
}
