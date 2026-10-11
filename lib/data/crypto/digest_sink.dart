import 'package:crypto/crypto.dart';

/// Catches the [Digest] of a chunked hash conversion
/// (`sha256.startChunkedConversion`).
class DigestSink implements Sink<Digest> {
  Digest? value;

  @override
  void add(Digest data) => value = data;

  @override
  void close() {}
}
