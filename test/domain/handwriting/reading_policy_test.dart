import 'package:flutter_test/flutter_test.dart';
import 'package:offload/domain/handwriting/reading_policy.dart';

/// The reading settings of DD-021 (T6a.2).
void main() {
  test('the standard policy holds the values of DD-021', () {
    const policy = ReadingPolicy.standard;
    expect(policy.maxSide, 1280);
    expect(policy.contextSize, 2048);
    expect(policy.maxTextTokens, 1024);
  });

  test('accurate keeps the model\'s image tokens, faster limits them', () {
    const policy = ReadingPolicy.standard;
    expect(policy.imageTokensFor(ReadingSpeed.accurate), 0);
    expect(policy.imageTokensFor(ReadingSpeed.faster), 512);
  });

  test('a stored speed reads back; anything else is accurate', () {
    expect(ReadingSpeed.parse('faster'), ReadingSpeed.faster);
    expect(ReadingSpeed.parse('accurate'), ReadingSpeed.accurate);
    expect(ReadingSpeed.parse(null), ReadingSpeed.accurate);
    expect(ReadingSpeed.parse('turbo'), ReadingSpeed.accurate);
  });

  test('the prompt is prompt B of spike S6, literally', () {
    expect(
      readingPrompt,
      'Transcribe the handwritten text in this image exactly, line by line, '
      'one output line per written line. Keep every symbol exactly as '
      'written, including - @ ! # ^ * and digits. Do not add, remove, '
      'correct, translate or complete anything. The text is Dutch. Output '
      'only the text.',
    );
  });
}
