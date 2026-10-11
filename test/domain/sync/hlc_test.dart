import 'package:flutter_test/flutter_test.dart';
import 'package:offload/domain/sync/hlc.dart';

void main() {
  group('Hlc', () {
    test('pack and parse round-trip', () {
      final hlc = Hlc(1790000000000, 0x2a, 'abc123');
      expect(hlc.pack(), '001790000000000-002a-abc123');
      expect(Hlc.parse(hlc.pack()), hlc);
    });

    test('packed form sorts like compareTo', () {
      final stamps = [
        Hlc(2000, 0, 'b'),
        Hlc(1000, 5, 'a'),
        Hlc(1000, 0, 'z'),
        Hlc(99999, 0, 'a'),
        Hlc(1000, 5, 'b'),
      ];
      final byCompare = [...stamps]..sort();
      final byText = [...stamps]..sort((a, b) => a.pack().compareTo(b.pack()));
      expect(byText, byCompare);
    });

    test('constructor validates in every build mode', () {
      expect(() => Hlc(-1, 0, 'n'), throwsArgumentError);
      expect(() => Hlc(Hlc.maxMillis + 1, 0, 'n'), throwsArgumentError);
      expect(() => Hlc(0, Hlc.maxCounter + 1, 'n'), throwsArgumentError);
      expect(() => Hlc(0, -1, 'n'), throwsArgumentError);
      expect(() => Hlc(0, 0, ''), throwsArgumentError);
      expect(() => Hlc(0, 0, 'a-b'), throwsArgumentError);
    });

    test('parse rejects malformed input', () {
      for (final bad in [
        '',
        '1-2-3',
        '001790000000000-2a-x',
        'a-b',
        '-00000000000001-0000-n', // sign
        '+00000000000001-0000-n',
        '001790000000000-00AZ-n', // not hex
        '001790000000000-0000-', // empty node
        '001790000000000-0000-a-b', // node with "-"
      ]) {
        expect(() => Hlc.parse(bad), throwsFormatException, reason: bad);
      }
    });
  });

  group('HlcClock', () {
    test('follows the wall clock when it moves forward', () {
      var now = 1000;
      final clock = HlcClock(node: 'n1', now: () => now);
      expect(clock.tick(), Hlc(1000, 0, 'n1'));
      now = 1005;
      expect(clock.tick(), Hlc(1005, 0, 'n1'));
    });

    test('counts up within the same millisecond', () {
      final clock = HlcClock(node: 'n1', now: () => 1000);
      final stamps = List.generate(1000, (_) => clock.tick());
      for (var i = 1; i < stamps.length; i++) {
        expect(stamps[i].compareTo(stamps[i - 1]), greaterThan(0));
      }
      expect(stamps.last, Hlc(1000, 999, 'n1'));
    });

    test('stays monotonic when the wall clock jumps backwards', () {
      var now = 5000;
      final clock = HlcClock(node: 'n1', now: () => now);
      final before = clock.tick();
      now = 1000; // e.g. a manual clock correction
      final after = clock.tick();
      expect(after.compareTo(before), greaterThan(0));
      expect(after, Hlc(5000, 1, 'n1'));
    });

    test('borrows the next millisecond when the counter is exhausted', () {
      final clock = HlcClock(
        node: 'n1',
        last: Hlc(1000, Hlc.maxCounter, 'n1'),
        now: () => 1000,
      );
      expect(clock.tick(), Hlc(1001, 0, 'n1'));
    });

    test('continues after a persisted last timestamp', () {
      final clock = HlcClock(
        node: 'n1',
        last: Hlc(9000, 3, 'n1'),
        now: () => 100,
      );
      expect(clock.tick(), Hlc(9000, 4, 'n1'));
    });

    test('rejects node ids that would break the packed form', () {
      expect(() => HlcClock(node: ''), throwsArgumentError);
      expect(() => HlcClock(node: 'a-b'), throwsArgumentError);
    });

    test('rejects a last timestamp from another node', () {
      expect(
        () => HlcClock(node: 'n1', last: Hlc(9000, 0, 'n2')),
        throwsArgumentError,
      );
    });
  });

  test('hlcTime: the physical time in UTC, null for text that is no HLC', () {
    expect(
      hlcTime(Hlc(1790000000000, 7, 'abc123').pack()),
      DateTime.fromMillisecondsSinceEpoch(1790000000000, isUtc: true),
    );
    expect(hlcTime('not an hlc'), isNull);
  });
}
