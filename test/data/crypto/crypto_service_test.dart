import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/crypto/crypto_service.dart';
import 'package:offload/platform/key_store/key_store.dart';

import '../../fakes/fake_key_store.dart';

void main() {
  test('first start creates and stores a 32-byte master key', () async {
    final store = FakeKeyStore();
    await CryptoService.unlock(store, existingDataFound: false);
    expect(store.key, hasLength(32));
    expect(store.createCalls, 1);
  });

  test('a later start reuses the stored key', () async {
    final store = FakeKeyStore();
    final first = await CryptoService.unlock(store, existingDataFound: false);
    final second = await CryptoService.unlock(store, existingDataFound: true);
    expect(store.createCalls, 1);
    expect(
      second.deriveKey(KeyPurpose.database),
      first.deriveKey(KeyPurpose.database),
    );
  });

  test('existing data without a key stops and never creates one', () async {
    final store = FakeKeyStore();
    await expectLater(
      CryptoService.unlock(store, existingDataFound: true),
      throwsA(isA<MissingMasterKeyException>()),
    );
    expect(store.createCalls, 0);
    expect(store.key, isNull);
  });

  test('an unreadable key is an error, not a reason for a new key', () async {
    final store = FakeKeyStore(unavailable: true);
    await expectLater(
      CryptoService.unlock(store, existingDataFound: false),
      throwsA(isA<KeyStoreException>()),
    );
    expect(store.createCalls, 0);
  });

  test('a stored key of the wrong length is rejected', () async {
    final store = FakeKeyStore(key: Uint8List(16));
    await expectLater(
      CryptoService.unlock(store, existingDataFound: true),
      throwsA(isA<KeyStoreException>()),
    );
  });

  test('the database key is derived, not the master key itself', () async {
    final master = Uint8List.fromList(List.generate(32, (i) => i));
    final service = await CryptoService.unlock(
      FakeKeyStore(key: master),
      existingDataFound: true,
    );
    final dbKey = service.deriveKey(KeyPurpose.database);
    expect(dbKey, hasLength(32));
    expect(dbKey, isNot(master));
  });
}
