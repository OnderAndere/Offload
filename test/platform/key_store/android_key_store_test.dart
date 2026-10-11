import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/platform/key_store/android_key_store.dart';
import 'package:offload/platform/key_store/key_store.dart';

/// Checks how platform answers map onto the [KeyStore] contract. Only a
/// missing key file may read as "no key"; every failure must be an error.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('eu.marandos.offload/key_store');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final store = AndroidKeyStore();

  void answer(Object? Function(MethodCall call) handler) => messenger
      .setMockMethodCallHandler(channel, (call) async => handler(call));

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  Matcher throwsCode(KeyStoreErrorCode code) =>
      throwsA(isA<KeyStoreException>().having((e) => e.code, 'code', code));

  test('no key file reads as no key', () async {
    answer((_) => null);
    expect(await store.readMasterKey(), isNull);
  });

  test('a stored key is returned unchanged', () async {
    final key = Uint8List.fromList(List.generate(32, (i) => i));
    answer((call) {
      expect(call.arguments, {'name': AndroidKeyStore.masterKeyName});
      return key;
    });
    expect(await store.readMasterKey(), key);
  });

  test('"exists" maps to alreadyExists', () async {
    answer((_) => throw PlatformException(code: 'exists'));
    await expectLater(
      store.createMasterKey(Uint8List(32)),
      throwsCode(KeyStoreErrorCode.alreadyExists),
    );
  });

  for (final code in ['unavailable', 'invalid', 'error']) {
    test('"$code" maps to unavailable', () async {
      answer((_) => throw PlatformException(code: code));
      await expectLater(
        store.readMasterKey(),
        throwsCode(KeyStoreErrorCode.unavailable),
      );
    });
  }

  test('a missing channel is an error, not "no key"', () async {
    await expectLater(
      store.readMasterKey(),
      throwsCode(KeyStoreErrorCode.unavailable),
    );
  });

  test('rejects a key that is not 256 bits before calling the platform', () {
    expect(() => store.createMasterKey(Uint8List(16)), throwsArgumentError);
  });
}
