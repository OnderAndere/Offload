import 'dart:typed_data';

/// AES-256-GCM test vectors from the GCM specification (McGrew and Viega,
/// "The Galois/Counter Mode of Operation", test cases 13, 14 and 16; checked
/// against pyca/cryptography on 09-10-2026).
typedef GcmTestVector = ({
  String name,
  Uint8List key,
  Uint8List nonce,
  Uint8List aad,
  Uint8List plaintext,
  Uint8List ciphertext,
  Uint8List tag,
});

Uint8List _hex(String hex) => Uint8List.fromList([
  for (var i = 0; i < hex.length; i += 2)
    int.parse(hex.substring(i, i + 2), radix: 16),
]);

final gcmTestVectors = <GcmTestVector>[
  (
    name: 'test case 13 (empty)',
    key: Uint8List(32),
    nonce: Uint8List(12),
    aad: Uint8List(0),
    plaintext: Uint8List(0),
    ciphertext: Uint8List(0),
    tag: _hex('530f8afbc74536b9a963b4f1c4cb738b'),
  ),
  (
    name: 'test case 14 (one block)',
    key: Uint8List(32),
    nonce: Uint8List(12),
    aad: Uint8List(0),
    plaintext: Uint8List(16),
    ciphertext: _hex('cea7403d4d606b6e074ec5d3baf39d18'),
    tag: _hex('d0d1c8a799996bf0265b98b5d48ab919'),
  ),
  (
    name: 'test case 16 (associated data, partial block)',
    key: _hex(
      'feffe9928665731c6d6a8f9467308308feffe9928665731c6d6a8f9467308308',
    ),
    nonce: _hex('cafebabefacedbaddecaf888'),
    aad: _hex('feedfacedeadbeeffeedfacedeadbeefabaddad2'),
    plaintext: _hex(
      'd9313225f88406e5a55909c5aff5269a86a7a9531534f7da2e4c303d8a318a72'
      '1c3c0c95956809532fcf0e2449a6b525b16aedf5aa0de657ba637b39',
    ),
    ciphertext: _hex(
      '522dc1f099567d07f47f37a32a84427d643a8cdcbfe5c0c97598a2bd2555d1aa'
      '8cb08e48590dbb3da7b08b1056828838c5f61e6393ba7a0abcc9f662',
    ),
    tag: _hex('76fc6ece0f4e1768cddf8853bb2d551b'),
  ),
];
