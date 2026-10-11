import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:offload/domain/ids/uuid_v7.dart';

final _format = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

void main() {
  test('has the canonical version 7 format', () {
    final id = UuidV7Generator().next();
    expect(id, matches(_format));
  });

  test('encodes the timestamp in the first 48 bits', () {
    const millis = 0x0192a1b2c3d4;
    final id = UuidV7Generator(now: () => millis).next();
    expect(id.replaceAll('-', '').substring(0, 12), '0192a1b2c3d4');
  });

  test('ids from later milliseconds sort after earlier ones', () {
    var now = 1790000000000;
    final generator = UuidV7Generator(now: () => now++);
    final ids = List.generate(200, (_) => generator.next());
    expect([...ids]..sort(), ids);
  });

  test('ids are unique', () {
    final generator = UuidV7Generator(now: () => 1790000000000);
    final ids = {for (var i = 0; i < 10000; i++) generator.next()};
    expect(ids, hasLength(10000));
  });

  test('uses the injected random source', () {
    final a = UuidV7Generator(now: () => 1, random: Random(7)).next();
    final b = UuidV7Generator(now: () => 1, random: Random(7)).next();
    expect(a, b);
  });

  test('rejects timestamps outside the 48-bit range', () {
    expect(() => UuidV7Generator(now: () => -1).next(), throwsStateError);
    expect(() => UuidV7Generator(now: () => 1 << 48).next(), throwsStateError);
  });

  group('uuidV7Time', () {
    test('reads back the creation time in UTC', () {
      final created = DateTime.utc(2026, 9, 27, 14, 32, 5, 123);
      final id = UuidV7Generator(
        now: () => created.millisecondsSinceEpoch,
      ).next();

      final time = uuidV7Time(id);

      expect(time, created);
      expect(time.isUtc, isTrue);
    });

    test('rejects ids that are not version 7 UUIDs', () {
      expect(
        () => uuidV7Time('0192a1b2-c3d4-4000-8000-000000000000'),
        throwsFormatException,
      );
      expect(() => uuidV7Time('not-a-uuid'), throwsFormatException);
      expect(
        () => uuidV7Time('zzzzzzzz-zzzz-7zzz-8zzz-zzzzzzzzzzzz'),
        throwsFormatException,
      );
    });
  });
}
