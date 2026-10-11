import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/crypto/hkdf.dart';

List<int> _hex(String hex) => [
  for (var i = 0; i < hex.length; i += 2)
    int.parse(hex.substring(i, i + 2), radix: 16),
];

List<int> _range(int from, int to) => [for (var i = from; i <= to; i++) i];

void main() {
  // Test vectors from RFC 5869, appendix A (SHA-256 cases).
  test('RFC 5869 test case 1', () {
    final okm = hkdfSha256(
      ikm: List.filled(22, 0x0b),
      salt: _range(0x00, 0x0c),
      info: _range(0xf0, 0xf9),
      length: 42,
    );
    expect(
      okm,
      _hex(
        '3cb25f25faacd57a90434f64d0362f2a2d2d0a90cf1a5a4c5db02d56ecc4c5bf'
        '34007208d5b887185865',
      ),
    );
  });

  test('RFC 5869 test case 2 (longer inputs and output)', () {
    final okm = hkdfSha256(
      ikm: _range(0x00, 0x4f),
      salt: _range(0x60, 0xaf),
      info: _range(0xb0, 0xff),
      length: 82,
    );
    expect(
      okm,
      _hex(
        'b11e398dc80327a1c8e7f78c596a49344f012eda2d4efad8a050cc4c19afa97c'
        '59045a99cac7827271cb41c65e590e09da3275600c2f09b8367793a9aca3db71'
        'cc30c58179ec3e87c14c01d5c1f3434f1d87',
      ),
    );
  });

  test('RFC 5869 test case 3 (empty salt and info)', () {
    final okm = hkdfSha256(ikm: List.filled(22, 0x0b), info: [], length: 42);
    expect(
      okm,
      _hex(
        '8da4e775a563c18f715f802a063c5a31b8a11f5c5ee1879ec3454e5f3c738d2d'
        '9d201395faa4b61a96c8',
      ),
    );
  });

  test('rejects an impossible output length', () {
    expect(() => hkdfSha256(ikm: [1], info: [], length: 0), throwsRangeError);
    expect(
      () => hkdfSha256(ikm: [1], info: [], length: 255 * 32 + 1),
      throwsRangeError,
    );
  });
}
