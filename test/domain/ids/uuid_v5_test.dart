import 'package:flutter_test/flutter_test.dart';
import 'package:offload/domain/ids/uuid_v5.dart';

/// Name-based ids (RFC 9562 version 5) for records that two devices must
/// make the same (DD-003).
void main() {
  const dns = '6ba7b810-9dad-11d1-80b4-00c04fd430c8';
  const url = '6ba7b811-9dad-11d1-80b4-00c04fd430c8';

  test('matches the RFC example', () {
    expect(
      uuidV5(dns, 'www.example.com'),
      '2ed6657d-e927-568b-95e1-2665a8aea6a2',
    );
  });

  test('hashes the name as UTF-8, Cyrillic included', () {
    // Python: uuid.uuid5(uuid.NAMESPACE_URL, 'Олена/2026-10-06').
    expect(
      uuidV5(url, 'Олена/2026-10-06'),
      'b3f1220d-097f-54e4-b53b-e3f531aea121',
    );
  });

  test('is a canonical version 5 UUID', () {
    final id = uuidV5(dns, 'x');
    expect(isCanonicalUuidV5(id), isTrue);
    expect(isCanonicalUuidV5('0199b0a0-1234-7abc-8def-0123456789ab'), isFalse);
  });

  test('refuses a namespace that is no UUID', () {
    expect(() => uuidV5('nope', 'x'), throwsFormatException);
  });
}
