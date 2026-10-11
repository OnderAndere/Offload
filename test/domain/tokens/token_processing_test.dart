import 'package:flutter_test/flutter_test.dart';
import 'package:offload/domain/tokens/token_processing.dart';

void main() {
  group('the moment a date counts from (DD-018 point 1)', () {
    final capture = DateTime.utc(2026, 9, 1);
    final edit1 = DateTime.utc(2026, 9, 10);
    final edit2 = DateTime.utc(2026, 9, 20);
    bool hasVr(String text) => text.contains('!vr');

    test('in the text since capture: the capture moment', () {
      expect(
        dateTokenAnchor(
          [
            (savedAt: capture, rawText: 'bel !vr'),
            (savedAt: edit1, rawText: 'bel Jan !vr'),
          ],
          hasVr,
          fallback: capture,
        ),
        capture,
      );
    });

    test('typed in an edit: that edit', () {
      expect(
        dateTokenAnchor(
          [
            (savedAt: capture, rawText: 'bel'),
            (savedAt: edit1, rawText: 'bel !vr'),
          ],
          hasVr,
          fallback: capture,
        ),
        edit1,
      );
    });

    test('removed and typed again: the edit that brought it back', () {
      expect(
        dateTokenAnchor(
          [
            (savedAt: capture, rawText: 'bel !vr'),
            (savedAt: edit1, rawText: 'bel'),
            (savedAt: edit2, rawText: 'bel !vr'),
          ],
          hasVr,
          fallback: capture,
        ),
        edit2,
      );
    });

    test('no history: the fallback', () {
      expect(dateTokenAnchor(const [], hasVr, fallback: capture), capture);
    });
  });

  group('where a token entered the text', () {
    final at = DateTime.utc(2026, 9, 1);
    bool hasRen(String text) => text.contains('^renovatie');

    test('the start of the latest unbroken run', () {
      final versions = [
        (savedAt: at, rawText: 'a ^renovatie'),
        (savedAt: at, rawText: 'a'),
        (savedAt: at, rawText: 'a ^renovatie'),
        (savedAt: at, rawText: 'ab ^renovatie'),
      ];
      expect(tokenRunStart(versions, hasRen), 2);
    });

    test('none when the latest version lacks it', () {
      expect(
        tokenRunStart([
          (savedAt: at, rawText: 'a ^renovatie'),
          (savedAt: at, rawText: 'a'),
        ], hasRen),
        isNull,
      );
      expect(tokenRunStart(const [], hasRen), isNull);
    });
  });

  group('whether a project token applies (DD-004 point 11)', () {
    test('without a choice it applies', () {
      expect(projectTokenApplies(0, null), isTrue);
    });

    test('only after the last choice, by change-log position', () {
      expect(projectTokenApplies(3, 2), isTrue);
      expect(projectTokenApplies(2, 3), isFalse);
      // The same position cannot be both; never a tie that applies.
      expect(projectTokenApplies(2, 2), isFalse);
    });
  });
}
