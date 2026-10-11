@TestOn('windows')
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/attachments/attachment_store.dart';
import 'package:offload/platform/cipher/aead_cipher.dart';
import 'package:offload/platform/cipher/windows_aead_cipher.dart';

import '../../fixtures/attachment_reference.dart';
import '../../fixtures/gcm_test_vectors.dart';

/// AES-256-GCM from Windows CNG (T5.1, DD-006): the GCM test vectors, the
/// tag check, and the reference attachment written by pyca/cryptography.
void main() {
  final cipher = WindowsAeadCipher();

  for (final vector in gcmTestVectors) {
    test('seals and opens ${vector.name}', () async {
      final message = AeadMessage(
        nonce: vector.nonce,
        aad: vector.aad,
        data: vector.plaintext,
      );
      final sealed = (await cipher.seal(vector.key, [message])).single;
      expect(sealed, [...vector.ciphertext, ...vector.tag]);
      final opened = await cipher.open(vector.key, [
        AeadMessage(nonce: vector.nonce, aad: vector.aad, data: sealed),
      ]);
      expect(opened.single, vector.plaintext);
    });
  }

  test('any change fails the tag: data, associated data, nonce, key', () async {
    final v = gcmTestVectors.last;
    final sealed = Uint8List.fromList([...v.ciphertext, ...v.tag]);
    Future<void> fails(Uint8List key, AeadMessage m) => expectLater(
      cipher.open(key, [m]),
      throwsA(isA<AeadAuthenticationException>()),
    );
    final flipped = Uint8List.fromList(sealed)..[3] ^= 1;
    await fails(v.key, AeadMessage(nonce: v.nonce, aad: v.aad, data: flipped));
    await fails(
      v.key,
      AeadMessage(nonce: v.nonce, aad: Uint8List.fromList([1]), data: sealed),
    );
    await fails(
      v.key,
      AeadMessage(
        nonce: Uint8List.fromList(v.nonce)..[0] ^= 1,
        aad: v.aad,
        data: sealed,
      ),
    );
    await fails(
      Uint8List.fromList(v.key)..[0] ^= 1,
      AeadMessage(nonce: v.nonce, aad: v.aad, data: sealed),
    );
  });

  test('a batch keeps its order', () async {
    final key = Uint8List(32);
    final messages = [
      for (var i = 0; i < 5; i++)
        AeadMessage(
          nonce: Uint8List(12)..[11] = i,
          aad: Uint8List(0),
          data: Uint8List.fromList(utf8.encode('message $i')),
        ),
    ];
    final sealed = await cipher.seal(key, messages);
    final opened = await cipher.open(key, [
      for (var i = 0; i < 5; i++)
        AeadMessage(
          nonce: messages[i].nonce,
          aad: Uint8List(0),
          data: sealed[i],
        ),
    ]);
    expect(
      [for (final o in opened) utf8.decode(o)],
      [for (var i = 0; i < 5; i++) 'message $i'],
    );
  });

  test('reads the reference attachment written by pyca/cryptography', () async {
    final store = await _storeWith(referenceFile, cipher);
    final plain = await store.readAll(referenceAttachmentId);
    expect(utf8.decode(plain), referencePlaintext);
    expect(sha256.convert(plain).toString(), referenceSha256);
  });
}

Future<AttachmentStore> _storeWith(Uint8List file, AeadCipher cipher) async {
  final dir = await Directory.systemTemp.createTemp('offload_attachments');
  addTearDown(() => dir.delete(recursive: true));
  await File(
    '${dir.path}${Platform.pathSeparator}$referenceAttachmentId',
  ).writeAsBytes(file);
  return AttachmentStore(
    directory: dir,
    attachmentsKey: referenceAttachmentsKey,
    cipher: cipher,
  );
}
