import 'dart:math';
import 'dart:typed_data';

/// Generates RFC 9562 version 7 UUIDs: 48 bits of Unix time in milliseconds
/// followed by random bits. They sort roughly by creation time, which keeps
/// database indexes compact, and replace auto-increment keys (REQ-008).
class UuidV7Generator {
  UuidV7Generator({int Function()? now, Random? random})
    : _now = now ?? _wallClockMillis,
      _random = random ?? Random.secure();

  final int Function() _now;
  final Random _random;

  /// Returns a new UUID in the canonical 8-4-4-4-12 lowercase hex form.
  String next() {
    final millis = _now();
    if (millis < 0 || millis >= (1 << 48)) {
      throw StateError('Timestamp out of UUIDv7 range: $millis');
    }
    final bytes = Uint8List(16);
    for (var i = 0; i < 6; i++) {
      bytes[i] = (millis >> (8 * (5 - i))) & 0xff;
    }
    for (var i = 6; i < 16; i++) {
      bytes[i] = _random.nextInt(256);
    }
    bytes[6] = (bytes[6] & 0x0f) | 0x70; // version 7
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // RFC 9562 variant

    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  static int _wallClockMillis() =>
      DateTime.now().toUtc().millisecondsSinceEpoch;
}

final _canonicalV7 = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

/// Whether [id] is a version 7 UUID in the canonical lowercase form that
/// [UuidV7Generator] produces.
bool isCanonicalUuidV7(String id) => _canonicalV7.hasMatch(id);

/// The creation time encoded in the version 7 UUID [id], in UTC.
///
/// Derived data such as an item's capture time is read from the id instead
/// of being stored in a column of its own (CLAUDE.md rule 6).
/// Throws [FormatException] when [id] is not a version 7 UUID.
DateTime uuidV7Time(String id) {
  final hex = id.replaceAll('-', '');
  if (hex.length != 32 || hex[12] != '7') {
    throw FormatException('Not a version 7 UUID', id);
  }
  final millis = int.parse(hex.substring(0, 12), radix: 16);
  return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
}
