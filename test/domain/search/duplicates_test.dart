import 'package:flutter_test/flutter_test.dart';
import 'package:offload/domain/search/duplicates.dart';

/// "Bestaat dit al?": when two items look the same (REQ-053; PO decisions
/// 27-09-2026).
void main() {
  group('comparable words', () {
    test('case, diacritics and token signs do not matter', () {
      expect(comparableWords('Bel @Jan over #Renovatie !vr'), [
        'bel',
        'jan',
        'over',
        'renovatie',
        'vr',
      ]);
      expect(comparableWords('Café crème, Straße!'), [
        'cafe',
        'creme',
        'strasse',
      ]);
      expect(comparableWords('Олена Київ'), ['олена', 'київ']);
    });
  });

  group('looks like a duplicate', () {
    test('the same text, also when short', () {
      expect(looksLikeDuplicate('Bel Jan', 'bel @jan'), isTrue);
      expect(looksLikeDuplicate('Café', 'cafe'), isTrue);
    });

    test('most meaningful words shared, at least three (plan examples)', () {
      expect(
        looksLikeDuplicate(
          'Offerte renovatie opvragen bij Jan',
          'offerte renovatie opvragen',
        ),
        isTrue,
      );
      // "vragen" is no "opvragen": rather no hint than a wrong one.
      expect(
        looksLikeDuplicate(
          'Offerte renovatie opvragen bij Jan',
          'Jan vragen om offerte renovatie',
        ),
        isFalse,
      );
      expect(looksLikeDuplicate('Bel Jan', 'Bel Piet'), isFalse);
    });

    test('80% of the shorter one: four of four yes, three of five no', () {
      const five = 'afvoer keuren meubelplan renovatie offerte';
      expect(
        looksLikeDuplicate(five, 'afvoer keuren meubelplan renovatie'),
        isTrue,
      );
      expect(
        looksLikeDuplicate(five, 'afvoer keuren meubelplan vandaag nog'),
        isFalse,
      );
    });

    test('short words do not count as meaningful', () {
      // Only "kast" and "hal" are meaningful: fewer than three.
      expect(looksLikeDuplicate('De kast in de hal', 'kast hal'), isFalse);
    });

    test('nothing to compare', () {
      expect(looksLikeDuplicate('', 'iets'), isFalse);
      expect(looksLikeDuplicate('!!', '##'), isFalse);
    });
  });
}
