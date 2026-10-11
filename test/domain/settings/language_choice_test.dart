import 'package:flutter_test/flutter_test.dart';
import 'package:offload/domain/settings/language_choice.dart';

void main() {
  const supported = ['en', 'nl'];

  String resolve(LanguageChoice choice, List<String> system) =>
      resolveUiLanguage(
        choice,
        systemLanguageCodes: system,
        supportedLanguageCodes: supported,
      );

  group('LanguageChoice', () {
    test('system follows the system; a language does not', () {
      expect(const LanguageChoice.system().followsSystem, isTrue);
      expect(const LanguageChoice.language('nl').followsSystem, isFalse);
    });

    test('equality is by language code', () {
      expect(
        const LanguageChoice.language('nl'),
        LanguageChoice.language('nl'),
      );
      expect(const LanguageChoice.system(), const LanguageChoice.system());
      expect(
        const LanguageChoice.system(),
        isNot(const LanguageChoice.language('en')),
      );
    });
  });

  group('resolveUiLanguage (AC REQ-029)', () {
    const system = LanguageChoice.system();

    test('system: an offered system language is used', () {
      expect(resolve(system, ['nl']), 'nl');
      expect(resolve(system, ['en']), 'en');
    });

    test('system: a language that is not offered falls back to English', () {
      expect(resolve(system, ['de']), fallbackLanguageCode);
      expect(fallbackLanguageCode, 'en');
    });

    test('system: the first offered preferred language is used', () {
      expect(resolve(system, ['de', 'nl']), 'nl');
      expect(resolve(system, ['de', 'nl', 'en']), 'nl');
      expect(resolve(system, ['en', 'nl']), 'en');
    });

    test('system: no offered preferred language falls back to English', () {
      expect(resolve(system, ['de', 'fr']), 'en');
    });

    test('system: no system language at all falls back to English', () {
      expect(resolve(system, []), 'en');
    });

    test('a fixed choice wins over the system language', () {
      expect(resolve(const LanguageChoice.language('nl'), ['en']), 'nl');
      expect(resolve(const LanguageChoice.language('en'), ['nl']), 'en');
      expect(resolve(const LanguageChoice.language('nl'), ['de']), 'nl');
    });

    test('a fixed choice that is not offered behaves like system', () {
      expect(resolve(const LanguageChoice.language('uk'), ['nl']), 'nl');
      expect(resolve(const LanguageChoice.language('uk'), ['de']), 'en');
      expect(resolve(const LanguageChoice.language('uk'), ['de', 'nl']), 'nl');
    });

    test(
      'the fallback does not depend on the order of supported languages',
      () {
        for (final order in [
          ['nl', 'en'],
          ['en', 'nl'],
        ]) {
          expect(
            resolveUiLanguage(
              system,
              systemLanguageCodes: ['de'],
              supportedLanguageCodes: order,
            ),
            'en',
          );
        }
      },
    );
  });
}
