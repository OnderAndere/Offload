import 'package:flutter_test/flutter_test.dart';
import 'package:offload/domain/handwriting/thoughts.dart';

/// The thoughts of a reading (T6a.5, AC REQ-064 b; PO 12-10-2026).
/// Fictional sample text.
void main() {
  test('each - line is a thought, without its -', () {
    expect(splitThoughts('- @Anna bellen !vr\n- kweekbak bouwen #tuin'), [
      '@Anna bellen !vr',
      'kweekbak bouwen #tuin',
    ]);
  });

  test('a line without - joins the thought before it with a space', () {
    expect(
      splitThoughts(
        '- met de buren afspreken\n  voor koffie !overmorgen\n- zaaien',
      ),
      ['met de buren afspreken voor koffie !overmorgen', 'zaaien'],
    );
  });

  test('text before the first - line is a thought of its own', () {
    expect(splitThoughts('Tuin\nvoorjaar\n- zaaien\n- snoeien'), [
      'Tuin voorjaar',
      'zaaien',
      'snoeien',
    ]);
  });

  test('no - at all: one thought', () {
    expect(splitThoughts('bel Bram\nover de sleutel'), [
      'bel Bram over de sleutel',
    ]);
  });

  test('blank lines and empty thoughts go; spaces are trimmed', () {
    expect(splitThoughts('\n-   \n\n -zaaien  \r\n\n-\tsnoeien\n'), [
      'zaaien',
      'snoeien',
    ]);
  });

  test('nothing in, nothing out', () {
    expect(splitThoughts(''), isEmpty);
    expect(splitThoughts('\n - \n'), isEmpty);
  });

  test('tokens, dates and numbers stay as written', () {
    expect(splitThoughts('- Bel 06-12345678 op 30-10-2026 *hoog'), [
      'Bel 06-12345678 op 30-10-2026 *hoog',
    ]);
  });
}
