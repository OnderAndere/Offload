import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:offload/data/attachments/attachment_store.dart';
import 'package:offload/platform/cipher/aead_cipher.dart';
import 'package:offload/platform/cipher/platform_aead_cipher.dart';

import '../test/fixtures/attachment_reference.dart';
import '../test/fixtures/gcm_test_vectors.dart';

/// The attachment store with the real cipher of this platform (T5.1,
/// DD-006): Android `javax.crypto`, Windows CNG. Same test vectors and the
/// same reference file (written by pyca/cryptography) on both, so what one
/// platform writes the other reads. Prints the time for 10 and 50 MB.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final cipher = createPlatformAeadCipher();

  for (final vector in gcmTestVectors) {
    testWidgets('GCM ${vector.name}', (tester) async {
      final sealed = (await cipher.seal(vector.key, [
        AeadMessage(
          nonce: vector.nonce,
          aad: vector.aad,
          data: vector.plaintext,
        ),
      ])).single;
      expect(sealed, [...vector.ciphertext, ...vector.tag]);
      final opened = await cipher.open(vector.key, [
        AeadMessage(nonce: vector.nonce, aad: vector.aad, data: sealed),
      ]);
      expect(opened.single, vector.plaintext);
      final changed = Uint8List.fromList(sealed)..[0] ^= 1;
      await expectLater(
        cipher.open(vector.key, [
          AeadMessage(nonce: vector.nonce, aad: vector.aad, data: changed),
        ]),
        throwsA(isA<AeadAuthenticationException>()),
      );
    });
  }

  Future<AttachmentStore> store(Uint8List key) async {
    final dir = await Directory.systemTemp.createTemp('offload_attachments');
    addTearDown(() => dir.delete(recursive: true));
    return AttachmentStore(directory: dir, attachmentsKey: key, cipher: cipher);
  }

  testWidgets('reads the reference attachment written by pyca', (tester) async {
    final s = await store(referenceAttachmentsKey);
    await File(
      '${s.directory.path}${Platform.pathSeparator}$referenceAttachmentId',
    ).writeAsBytes(referenceFile);
    final plain = await s.readAll(referenceAttachmentId);
    expect(utf8.decode(plain), referencePlaintext);
    expect(sha256.convert(plain).toString(), referenceSha256);
  });

  for (final megabytes in [10, 50]) {
    testWidgets('$megabytes MB: written, read back and timed', (tester) async {
      final s = await store(
        Uint8List.fromList(List.generate(32, (i) => 255 - i)),
      );
      const id = '0192a3b4-c5d6-7e8f-9a0b-1c2d3e4f5a6b';
      final random = Random(megabytes);
      final chunk = Uint8List.fromList(
        List.generate(1 << 20, (_) => random.nextInt(256)),
      );
      Stream<List<int>> source() async* {
        for (var i = 0; i < megabytes; i++) {
          yield chunk;
        }
      }

      final expectedSink = _DigestSink();
      final expectedHasher = sha256.startChunkedConversion(expectedSink);
      for (var i = 0; i < megabytes; i++) {
        expectedHasher.add(chunk);
      }
      expectedHasher.close();
      final expected = expectedSink.value!;
      final write = Stopwatch()..start();
      final stored = await s.write(id, source());
      write.stop();
      expect(stored.size, megabytes << 20);
      expect(stored.sha256, expected.bytes);

      final read = Stopwatch()..start();
      final digest = _DigestSink();
      final hasher = sha256.startChunkedConversion(digest);
      await for (final segment in s.read(id)) {
        hasher.add(segment);
      }
      hasher.close();
      read.stop();
      expect(digest.value, expected);
      // ignore: avoid_print
      print(
        'T5.1 ${Platform.operatingSystem} $megabytes MB: '
        'write ${write.elapsedMilliseconds} ms, '
        'read ${read.elapsedMilliseconds} ms',
      );
    });
  }
}

class _DigestSink implements Sink<Digest> {
  Digest? value;

  @override
  void add(Digest data) => value = data;

  @override
  void close() {}
}
