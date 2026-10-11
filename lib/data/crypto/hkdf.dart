import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// HKDF with HMAC-SHA256 (RFC 5869).
///
/// Derives [length] bytes from the input key material [ikm], bound to the
/// context string [info]. An empty [salt] means a salt of 32 zero bytes, as
/// the RFC specifies; that is fine for a uniformly random [ikm].
Uint8List hkdfSha256({
  required List<int> ikm,
  required List<int> info,
  required int length,
  List<int> salt = const [],
}) {
  const hashLength = 32;
  if (length <= 0 || length > 255 * hashLength) {
    throw RangeError.range(length, 1, 255 * hashLength, 'length');
  }
  final prk = Hmac(
    sha256,
    salt.isEmpty ? List<int>.filled(hashLength, 0) : salt,
  ).convert(ikm).bytes;

  final expand = Hmac(sha256, prk);
  final output = BytesBuilder(copy: false);
  var previous = <int>[];
  for (var counter = 1; output.length < length; counter++) {
    previous = expand.convert([...previous, ...info, counter]).bytes;
    output.add(previous);
  }
  return Uint8List.sublistView(output.takeBytes(), 0, length);
}
