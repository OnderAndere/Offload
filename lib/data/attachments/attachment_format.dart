import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import '../../platform/cipher/aead_cipher.dart';
import '../crypto/hkdf.dart';

/// The file format of an encrypted attachment, version 1 (DD-006; streamed in
/// segments, each authenticated on its own, DD-007 point 4):
///
/// ```
/// header (32 bytes)
///   0..2   "OFA"            magic
///   3      1                format version
///   4      s                segment size is 2^s bytes (16: 64 KiB)
///   5..7   0                reserved
///   8..23  salt             16 random bytes: the file's own key
///   24..30 nonce prefix     7 random bytes
///   31     0                reserved
/// segment 0 … segment n-1   AES-256-GCM: ciphertext + 16-byte tag
/// ```
///
/// Every segment holds 2^s bytes of plaintext, the last one 0 to 2^s (an
/// empty file is one empty segment). Its nonce is the prefix, the segment
/// number (4 bytes, big-endian) and a byte that is 1 for the last segment
/// only: segments cannot be reordered, and a file cut short after a segment
/// fails, because that segment was not sealed as the last. The associated
/// data is the header followed by the attachment id, so a file does not
/// open under another attachment, nor with a changed header.
///
/// The key of a file is HKDF-SHA256 from the attachments key with the salt
/// and the attachment id: every file, and every rewrite of it, has its own.
class AttachmentHeader {
  AttachmentHeader({
    required this.segmentShift,
    required this.salt,
    required this.noncePrefix,
  }) {
    if (segmentShift < minSegmentShift || segmentShift > maxSegmentShift) {
      throw ArgumentError.value(segmentShift, 'segmentShift');
    }
    if (salt.length != saltLength) {
      throw ArgumentError.value(salt.length, 'salt.length');
    }
    if (noncePrefix.length != noncePrefixLength) {
      throw ArgumentError.value(noncePrefix.length, 'noncePrefix.length');
    }
  }

  /// A header with fresh random salt and nonce prefix from [random].
  factory AttachmentHeader.random(
    Random random, {
    int segmentShift = defaultSegmentShift,
  }) {
    Uint8List bytes(int n) =>
        Uint8List.fromList(List.generate(n, (_) => random.nextInt(256)));
    return AttachmentHeader(
      segmentShift: segmentShift,
      salt: bytes(saltLength),
      noncePrefix: bytes(noncePrefixLength),
    );
  }

  /// Reads the header at the start of [bytes]; throws
  /// [AttachmentFormatException] when it is not one this version knows.
  factory AttachmentHeader.parse(Uint8List bytes) {
    if (bytes.length < length) {
      throw const AttachmentFormatException('too short for a header');
    }
    for (var i = 0; i < _magic.length; i++) {
      if (bytes[i] != _magic[i]) {
        throw const AttachmentFormatException('not an attachment file');
      }
    }
    if (bytes[3] != version) {
      throw AttachmentFormatException('unknown format version ${bytes[3]}');
    }
    // Reserved bytes are zero: the associated data is the header as this
    // version writes it, so any other header must not open.
    for (final reserved in [5, 6, 7, 31]) {
      if (bytes[reserved] != 0) {
        throw const AttachmentFormatException('reserved bytes set');
      }
    }
    final shift = bytes[4];
    if (shift < minSegmentShift || shift > maxSegmentShift) {
      throw AttachmentFormatException('segment size 2^$shift');
    }
    return AttachmentHeader(
      segmentShift: shift,
      salt: Uint8List.fromList(bytes.sublist(8, 8 + saltLength)),
      noncePrefix: Uint8List.fromList(
        bytes.sublist(24, 24 + noncePrefixLength),
      ),
    );
  }

  static const length = 32;
  static const version = 1;
  static const saltLength = 16;
  static const noncePrefixLength = 7;
  static const defaultSegmentShift = 16;
  static const minSegmentShift = 10;
  static const maxSegmentShift = 24;
  static const _magic = [0x4F, 0x46, 0x41]; // "OFA"

  final int segmentShift;
  final Uint8List salt;
  final Uint8List noncePrefix;

  int get segmentSize => 1 << segmentShift;

  Uint8List encode() {
    final out = Uint8List(length)
      ..setRange(0, 3, _magic)
      ..[3] = version
      ..[4] = segmentShift
      ..setRange(8, 8 + saltLength, salt)
      ..setRange(24, 24 + noncePrefixLength, noncePrefix);
    return out;
  }

  /// The nonce of segment [index].
  Uint8List nonce(int index, {required bool last}) {
    if (index < 0 || index > 0xFFFFFFFF) {
      throw RangeError.range(index, 0, 0xFFFFFFFF, 'index');
    }
    final out = Uint8List(AeadCipher.nonceLength)
      ..setRange(0, noncePrefixLength, noncePrefix);
    ByteData.sublistView(out).setUint32(noncePrefixLength, index);
    out[11] = last ? 1 : 0;
    return out;
  }

  /// The associated data of every segment of attachment [id].
  Uint8List associatedData(
    String id, {
    AttachmentVariant variant = AttachmentVariant.file,
  }) => Uint8List.fromList([...encode(), ...utf8.encode(variant.bind(id))]);

  /// The key of this file of attachment [id], from [attachmentsKey].
  Uint8List fileKey(
    Uint8List attachmentsKey,
    String id, {
    AttachmentVariant variant = AttachmentVariant.file,
  }) => hkdfSha256(
    ikm: attachmentsKey,
    salt: salt,
    info: utf8.encode('eu.marandos.offload/attachment/v1/${variant.bind(id)}'),
    length: AeadCipher.keyLength,
  );
}

/// Which file of an attachment (DD-006/D3): the attachment itself (for a
/// photo its display version) or the thumbnail derived from it. Both carry
/// the attachment's id; the variant goes into the key and the associated
/// data, so one never opens as the other (review T5.1).
enum AttachmentVariant {
  /// The attachment itself, bound as before (files of T5.1 stay valid).
  file(''),

  /// A photo's thumbnail.
  thumbnail('thumbnail/');

  const AttachmentVariant(this._prefix);

  /// Never part of an id ('/' is not), so no two bindings are equal.
  final String _prefix;

  /// [id] bound to this variant.
  String bind(String id) => '$_prefix$id';
}

/// The size on disk of an attachment of [plainLength] bytes.
int encryptedLength(
  int plainLength, {
  int segmentShift = AttachmentHeader.defaultSegmentShift,
}) {
  final size = 1 << segmentShift;
  final segments = plainLength == 0 ? 1 : (plainLength + size - 1) ~/ size;
  return AttachmentHeader.length +
      plainLength +
      segments * AeadCipher.tagLength;
}

/// A file that is not a valid attachment of this version.
class AttachmentFormatException implements Exception {
  const AttachmentFormatException(this.message);

  final String message;

  @override
  String toString() => 'AttachmentFormatException: $message';
}
