import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// The RFC 9562 version 5 UUID of [name] in [namespace]: the SHA-1 of the
/// namespace's 16 bytes followed by the UTF-8 name, with the version and
/// variant bits set. The same namespace and name always give the same id,
/// on every device (DD-003, deterministic ids).
String uuidV5(String namespace, String name) {
  final hex = namespace.replaceAll('-', '');
  if (hex.length != 32) {
    throw FormatException('Not a UUID', namespace);
  }
  final input = BytesBuilder(copy: false)
    ..add([
      for (var i = 0; i < 32; i += 2)
        int.parse(hex.substring(i, i + 2), radix: 16),
    ])
    ..add(utf8.encode(name));
  final bytes = Uint8List.fromList(
    sha1.convert(input.takeBytes()).bytes.sublist(0, 16),
  );
  bytes[6] = (bytes[6] & 0x0f) | 0x50; // version 5
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // RFC 9562 variant
  final out = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${out.substring(0, 8)}-${out.substring(8, 12)}-'
      '${out.substring(12, 16)}-${out.substring(16, 20)}-${out.substring(20)}';
}

final _canonicalV5 = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-5[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

/// Whether [id] is a version 5 UUID in the canonical lowercase form that
/// [uuidV5] produces.
bool isCanonicalUuidV5(String id) => _canonicalV5.hasMatch(id);
