import 'package:flutter_test/flutter_test.dart';
import 'package:offload/domain/links/item_link.dart';
import 'package:offload/domain/time/local_date.dart';
import 'package:offload/domain/tokens/inline_token.dart';
import 'package:offload/domain/tokens/inline_token_registry.dart';

/// Labels of links between items (T10.9, REQ-054, DD-004 point 13).
void main() {
  group('linkLabelFor', () {
    test('a short title as it is, on one line', () {
      expect(
        linkLabelFor('Offerte  kozijnen\tvergelijken'),
        'Offerte kozijnen vergelijken',
      );
    });

    test('a long title is cut at a word boundary with …', () {
      final title = List.filled(20, 'woord').join(' ');
      final label = linkLabelFor(title);
      expect(label.endsWith('…'), isTrue);
      expect(label.length, lessThanOrEqualTo(linkLabelMax + 1));
      expect(label, startsWith('woord woord'));
      expect(label.substring(0, label.length - 1).endsWith(' '), isFalse);
    });

    test('square brackets become round ones', () {
      expect(linkLabelFor('Notities [concept]'), 'Notities (concept)');
    });

    test('every label reads back as the one link (review step A)', () {
      final registry = InlineTokenRegistry.standard();
      final context = ParseContext(
        today: LocalDate(2026, 10, 3),
        dates: DateVocabulary.empty,
      );
      for (final title in [
        'Notities [concept]',
        '[concept] Notities',
        'a [[[ b',
        'a ]] b [[ c',
        'Bel @Jan !vr #klus',
        List.filled(30, 'woord').join(' '),
        '${'x' * 59}😀 en meer',
      ]) {
        final label = linkLabelFor(title);
        final word = registry.parse('Zie [[$label]]', context).single.word;
        expect(linkKey(word), linkKey(label), reason: title);
      }
    });

    test('an emoji is never cut in half', () {
      final label = linkLabelFor('${'x' * 59}😀${'y' * 10}');
      expect(label.runes.every((r) => r < 0xD800 || r > 0xDFFF), isTrue);
    });

    test('Cyrillic is cut by characters, not bytes', () {
      final title = List.filled(15, 'кухня').join(' ');
      expect(linkLabelFor(title).length, lessThanOrEqualTo(linkLabelMax + 1));
    });
  });

  group('linkKey', () {
    test('case and white space do not matter', () {
      expect(linkKey('Offerte  Kozijnen'), linkKey('offerte kozijnen'));
      expect(linkKey('Нова Кухня'), linkKey('нова  кухня'));
    });
  });
}
