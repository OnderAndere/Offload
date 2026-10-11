import 'package:flutter_test/flutter_test.dart';
import 'package:offload/domain/repeats/repeat.dart';
import 'package:offload/domain/time/local_date.dart';
import 'package:offload/domain/tokens/inline_token.dart';
import 'package:offload/domain/tokens/inline_token_registry.dart';
import 'package:offload/domain/tokens/token_text.dart';
import 'package:offload/domain/tokens/token_types.dart';

/// Taking tokens out of the text (*Herhaling stoppen*, DD-018 point 18).
void main() {
  final registry = InlineTokenRegistry.standard();
  final context = ParseContext(
    today: LocalDate(2026, 10, 6),
    dates: DateVocabulary.empty,
    repeats: const RepeatVocabulary(
      daily: ['dagelijks'],
      weekly: ['wekelijks'],
      monthly: ['щомісяця'],
    ),
  );

  String withoutRepeats(String text) => withoutTokens(text, [
    for (final m in registry.parse(text, context))
      if (m.type is RepeatTokenType) m,
  ]);

  test('removes the word with one space, the rest as typed', () {
    expect(withoutRepeats('Hardlopen !wekelijks !6-10'), 'Hardlopen !6-10');
    expect(withoutRepeats('Hardlopen !wekelijks'), 'Hardlopen');
    expect(withoutRepeats('!wekelijks Hardlopen'), 'Hardlopen');
    expect(
      withoutRepeats('Hardlopen  !wekelijks, #sport'),
      'Hardlopen , #sport',
    );
  });

  test('removes every repeat word, Cyrillic too', () {
    expect(withoutRepeats('Зарядка !dagelijks\nен !щомісяця'), 'Зарядка\nен');
  });

  test('leaves a text without them alone', () {
    expect(withoutRepeats('Offerte !6-10 @Jan'), 'Offerte !6-10 @Jan');
  });
}
