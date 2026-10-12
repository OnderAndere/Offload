import 'package:flutter_test/flutter_test.dart';
import 'package:offload/domain/handwriting/reading_clean_up.dart';

/// The clean-up of DD-021 (T6a.4): the model's habits from spike S6, and
/// nothing else (AC REQ-064 a). Fictional sample text.
void main() {
  test('a token sign followed by a space joins the next word', () {
    expect(
      cleanUpReading('- @ Anna bellen ! vr # thuis ^ tuin * 2'),
      '- @Anna bellen !vr #thuis ^tuin *2',
    );
  });

  test('several spaces after the sign go too', () {
    expect(cleanUpReading('- bel @   Bram'), '- bel @Bram');
  });

  test('a sign inside a word, or with nothing after it, stays', () {
    expect(cleanUpReading('- mail a@b.nl'), '- mail a@b.nl');
    expect(cleanUpReading('- 3! is zes'), '- 3! is zes');
    expect(cleanUpReading('- vraag #\n  verder'), '- vraag #\n  verder');
  });

  test('× becomes *', () {
    expect(cleanUpReading('- tegels ×3'), '- tegels *3');
    expect(cleanUpReading('- tegels × 3'), '- tegels *3');
  });

  test('a lone - line goes, a thought with text stays', () {
    expect(
      cleanUpReading('- zaaien\n-\n - \n- oogsten'),
      '- zaaien\n- oogsten',
    );
  });

  test('line breaks stay; a line without - stays with its thought', () {
    expect(
      cleanUpReading('- kweekbak bouwen\n  van oude planken\n- @Anna bellen'),
      '- kweekbak bouwen\n  van oude planken\n- @Anna bellen',
    );
  });

  test('spaces at line ends and blank lines around the text go', () {
    expect(
      cleanUpReading('\r\n\n- zaaien   \r\n\n- oogsten \n\n'),
      '- zaaien\n\n- oogsten',
    );
  });

  test('nothing else changes: spelling, digits, case', () {
    const text = '- Bel 06-12345678 op 30-10-2026, NIET vergetn';
    expect(cleanUpReading(text), text);
  });

  test('empty in, empty out', () {
    expect(cleanUpReading(''), '');
    expect(cleanUpReading('\n -\n'), '');
  });
}
