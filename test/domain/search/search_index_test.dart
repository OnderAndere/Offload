import 'package:flutter_test/flutter_test.dart';
import 'package:offload/domain/search/search_index.dart';

/// Turning what the user typed into an FTS5 query (REQ-011, DD-016).
void main() {
  test('every word becomes a quoted prefix term; all words must match', () {
    expect(ftsMatchExpression('keur'), '"keur"*');
    expect(
      ftsMatchExpression('  offerte   renovatie '),
      '"offerte"* "renovatie"*',
    );
  });

  test('FTS5 syntax in the input is plain text', () {
    expect(ftsMatchExpression('NEAR(a b)'), '"NEAR(a"* "b)"*');
    expect(ftsMatchExpression('zeg "hoi"'), '"zeg"* """hoi"""*');
    expect(ftsMatchExpression('-renovatie'), '"-renovatie"*');
  });

  test('tokens and non-Latin words are searchable words too', () {
    expect(ftsMatchExpression('#renovatie @Jan'), '"#renovatie"* "@Jan"*');
    expect(ftsMatchExpression('Олена'), '"Олена"*');
    expect(ftsMatchExpression('2026'), '"2026"*');
  });

  test('nothing to search for', () {
    expect(ftsMatchExpression(''), isNull);
    expect(ftsMatchExpression('   '), isNull);
    expect(ftsMatchExpression('# - !'), isNull);
  });

  group('candidates sharing a word (duplicate hint)', () {
    test('distinct whole words, quoted and joined with OR', () {
      expect(
        ftsAnyWordExpression('Bel @Jan, bel Jan'),
        '"Bel" OR "Jan" OR "bel"',
      );
    });

    test('FTS5 operator words are plain words', () {
      expect(
        ftsAnyWordExpression('a OR b NEAR'),
        '"a" OR "OR" OR "b" OR "NEAR"',
      );
    });

    test('no word: nothing to look for', () {
      expect(ftsAnyWordExpression(''), isNull);
      expect(ftsAnyWordExpression('! # @'), isNull);
    });

    test('a long text uses only the first words', () {
      final long = [for (var i = 0; i < 100; i++) 'w$i'].join(' ');

      expect(ftsAnyWordExpression(long)!.split(' OR '), hasLength(32));
    });
  });
}
