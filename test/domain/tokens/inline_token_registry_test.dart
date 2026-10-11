import 'package:flutter_test/flutter_test.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/domain/repeats/repeat.dart';
import 'package:offload/domain/time/local_date.dart';
import 'package:offload/domain/tokens/inline_token.dart';
import 'package:offload/domain/tokens/inline_token_registry.dart';
import 'package:offload/domain/tokens/token_types.dart';

/// The inline syntax (REQ-019, REQ-028, DD-004; PO decisions 27-09-2026).
void main() {
  final dutch = DateVocabulary(
    today: const ['vandaag'],
    tomorrow: const ['morgen'],
    dayAfterTomorrow: const ['overmorgen'],
    nextWeek: const ['volgendeweek'],
    weekdays: const [
      ['ma', 'maandag'],
      ['di', 'dinsdag'],
      ['wo', 'woensdag'],
      ['do', 'donderdag'],
      ['vr', 'vrijdag'],
      ['za', 'zaterdag'],
      ['zo', 'zondag'],
    ],
  );
  // Sunday 27 September 2026.
  final sunday = LocalDate(2026, 9, 27);
  final registry = InlineTokenRegistry.standard();

  List<TokenMatch> parse(String text, {LocalDate? today}) => registry.parse(
    text,
    ParseContext(
      today: today ?? sunday,
      dates: dutch,
      priorities: const PriorityVocabulary(high: ['hoog'], low: ['laag']),
    ),
  );

  List<(String, Object)> found(String text, {LocalDate? today}) => [
    for (final m in parse(text, today: today)) (m.type.id, m.value),
  ];

  group('recognising tokens', () {
    test('person, date and tag in one line, in order', () {
      final matches = parse('bel Jan @Jan !vr #renovatie');

      expect([for (final m in matches) m.type.id], ['person', 'date', 'tag']);
      expect(matches[0].value, 'Jan');
      expect(matches[1].value, LocalDate(2026, 10, 2));
      expect(matches[2].value, 'renovatie');
      expect(matches[0].start, 8);
      expect(matches[0].end, 12);
    });

    test('at the start of the text and after any white space', () {
      expect(found('@Jan'), [('person', 'Jan')]);
      expect(found('x\t#renovatie'), [('tag', 'renovatie')]);
      expect(found('eerste regel\n!morgen'), [
        ('date', LocalDate(2026, 9, 28)),
      ]);
    });

    test('right after an opening bracket (PO decision 27-09-2026)', () {
      expect(found('bel Piet (@Jan) [#renovatie] {!vr}'), [
        ('person', 'Jan'),
        ('tag', 'renovatie'),
        ('date', LocalDate(2026, 10, 2)),
      ]);
      final match = parse('(@Jan)').single;
      expect((match.start, match.end), (1, 5));
    });

    test('not inside a word: an e-mail address is no person', () {
      // It is an e-mail address (T3.6), never the person "firma.nl".
      expect(found('mail jan@firma.nl'), [('email', 'jan@firma.nl')]);
      expect(found('prijs#1'), isEmpty);
    });

    test('a backslash before the prefix stays text (escape)', () {
      expect(found(r'\@Jan'), isEmpty);
      expect(found(r'zie \#renovatie en \!vr'), isEmpty);
    });

    test('trailing punctuation is not part of the token', () {
      final matches = parse('bel @Jan, over #renovatie. Klaar !vr!');

      expect([for (final m in matches) m.word], ['Jan', 'renovatie', 'vr']);
      expect(matches.first.end, 'bel @Jan'.length);
    });

    test('names and tags start with a letter, in any script', () {
      expect(found('om @10:00 en #1'), isEmpty);
      expect(found('@Željko @Олена #café'), [
        ('person', 'Željko'),
        ('person', 'Олена'),
        ('tag', 'café'),
      ]);
    });

    test('a prefix alone or followed by a space stays text', () {
      expect(found('@ Jan # ! en @'), isEmpty);
    });

    test('reserved and unknown prefixes stay text (DD-004 point 3)', () {
      expect(found('~2u ?vraag'), isEmpty);
    });

    test('project and priority (T10.5, REQ-050)', () {
      expect(found('bel Jan @Jan !vr ^renovatie *hoog'), [
        ('person', 'Jan'),
        ('date', LocalDate(2026, 10, 2)),
        ('project', 'renovatie'),
        ('priority', ItemPriority.high),
      ]);
      expect(found('^renovatie/keuken, ^2026-plan'), [
        ('project', 'renovatie/keuken'),
        ('project', '2026-plan'),
      ]);
      expect(found('(*laag) *1 *2 *3'), [
        ('priority', ItemPriority.low),
        ('priority', ItemPriority.high),
        ('priority', ItemPriority.normal),
        ('priority', ItemPriority.low),
      ]);
    });

    test('Markdown and other uses of ^ and * stay text', () {
      expect(
        found('* item, *nadruk*, **vet**, 2^10, a*hoog, *4, *hoogst'),
        isEmpty,
      );
      expect(found(r'\^renovatie \*hoog ^/x ^-x ^ x * x'), isEmpty);
    });

    test('an unknown word never is an error, only text', () {
      expect(found('!ooit !31-02 !12-13-2026'), isEmpty);
    });
  });

  group('dates (active UI language)', () {
    test('today, tomorrow, the day after tomorrow', () {
      expect(found('!vandaag !morgen !overmorgen'), [
        ('date', LocalDate(2026, 9, 27)),
        ('date', LocalDate(2026, 9, 28)),
        ('date', LocalDate(2026, 9, 29)),
      ]);
    });

    test('a weekday is the next such day, short or long, any case', () {
      expect(found('!ma !Vrijdag !ZA'), [
        ('date', LocalDate(2026, 9, 28)),
        ('date', LocalDate(2026, 10, 2)),
        ('date', LocalDate(2026, 10, 3)),
      ]);
    });

    test('on a Friday, !vr is next week\'s Friday', () {
      final friday = LocalDate(2026, 10, 2);

      expect(found('!vr', today: friday), [('date', LocalDate(2026, 10, 9))]);
      expect(found('!vandaag', today: friday), [('date', friday)]);
    });

    test('next week is Monday of next week', () {
      expect(found('!volgendeweek'), [('date', LocalDate(2026, 9, 28))]);
      final monday = LocalDate(2026, 9, 28);
      expect(found('!volgendeweek', today: monday), [
        ('date', LocalDate(2026, 10, 5)),
      ]);
    });

    test('day-month: the next such date, today included', () {
      expect(found('!12-10'), [('date', LocalDate(2026, 10, 12))]);
      expect(found('!27-9'), [('date', LocalDate(2026, 9, 27))]);
      expect(found('!1-3'), [('date', LocalDate(2027, 3, 1))]);
    });

    test('day-month-year as written', () {
      expect(found('!12-10-2027'), [('date', LocalDate(2027, 10, 12))]);
      expect(found('!29-02-2027'), isEmpty);
      // A typing slip, not a deadline.
      expect(found('!1-1-0000 !1-1-3000'), isEmpty);
    });

    test(
      'date words in another script work the same (Ukrainian later, T8.6)',
      () {
        // Only a test vocabulary: the Ukrainian words themselves come with
        // app_uk.arb and need a native speaker's check (SPEC Q9).
        final cyrillic = DateVocabulary(
          today: const ['сьогодні'],
          tomorrow: const ['завтра'],
          dayAfterTomorrow: const [],
          nextWeek: const [],
          weekdays: const [
            ['пн'],
            ['вт'],
            ['ср'],
            ['чт'],
            ['пт'],
            ['сб'],
            ['нд'],
          ],
        );

        final matches = registry.parse(
          '!Завтра !ПТ @Олена',
          ParseContext(today: sunday, dates: cyrillic),
        );

        expect(
          [for (final m in matches) m.value],
          [LocalDate(2026, 9, 28), LocalDate(2026, 10, 2), 'Олена'],
        );
      },
    );

    test('without date words only explicit dates count', () {
      final matches = registry.parse(
        '!morgen !12-10',
        ParseContext(today: sunday, dates: DateVocabulary.empty),
      );

      expect([for (final m in matches) m.value], [LocalDate(2026, 10, 12)]);
    });
  });

  group('the register (REQ-028)', () {
    test('a new token type is one registration, also by pattern', () {
      final withPhone = InlineTokenRegistry([
        for (final t in InlineTokenRegistry.standard().types)
          if (t.id != 'phone') t,
        const _PhoneTokenType(),
      ]);

      final matches = withPhone.parse(
        '@Jan 06-12345678',
        ParseContext(today: sunday, dates: dutch),
      );

      expect([for (final m in matches) m.type.id], ['person', 'phone']);
      expect(matches.last.word, '06-12345678');
    });

    test('types may share a prefix: the first that recognises it has it', () {
      final shared = InlineTokenRegistry([
        ...InlineTokenRegistry.standard().types,
        const _OtherAtType(),
      ]);

      final matches = shared.parse(
        '@Jan @10:00',
        ParseContext(today: sunday, dates: dutch),
      );

      // `@Jan` is the person (registered first), `@10:00` falls through.
      expect(
        [for (final m in matches) (m.type.id, m.word)],
        [('person', 'Jan'), ('other', '10:00')],
      );
      // The suggestion list goes by the first type of the prefix.
      expect(shared.tokenAt('@Ja', 3)?.type.id, 'person');
    });

    test('one type cannot be registered twice', () {
      expect(
        () => InlineTokenRegistry([
          ...InlineTokenRegistry.standard().types,
          const DateTokenType(),
        ]),
        throwsArgumentError,
      );
    });
  });

  group('repeat words (T4.7, DD-004 point 14)', () {
    const repeats = RepeatVocabulary(
      daily: ['dagelijks', 'daily', 'щодня'],
      weekly: ['wekelijks', 'weekly', 'щотижня'],
      monthly: ['maandelijks', 'monthly', 'щомісяця'],
    );
    List<(String, Object)> withRepeats(String text) => [
      for (final m in registry.parse(
        text,
        ParseContext(today: sunday, dates: dutch, repeats: repeats),
      ))
        (m.type.id, m.value),
    ];

    test('share `!` with dates: a repeat word and a date in one text', () {
      expect(withRepeats('Hardlopen !wekelijks !di'), [
        ('repeat', Rhythm.weekly),
        ('date', LocalDate(2026, 9, 29)),
      ]);
    });

    test('words of every language, without case, Cyrillic too', () {
      expect(withRepeats('!Daily'), [('repeat', Rhythm.daily)]);
      expect(withRepeats('Зарядка !Щодня.'), [('repeat', Rhythm.daily)]);
      expect(withRepeats('!щомісяця'), [('repeat', Rhythm.monthly)]);
    });

    test('without the vocabulary they stay text', () {
      expect(found('!wekelijks'), isEmpty);
    });

    test('an escaped word stays text', () {
      expect(withRepeats(r'\!wekelijks'), isEmpty);
    });

    test('the suggestion list of `!` is the date type', () {
      expect(registry.tokenAt('!wek', 4)?.type.id, 'date');
    });
  });

  group('where a token can start (prefix bar, REQ-034)', () {
    test('at the start, after white space or an opening bracket', () {
      expect(registry.isTokenStart('', 0), isTrue);
      expect(registry.isTokenStart('bel ', 4), isTrue);
      expect(registry.isTokenStart('bel (', 5), isTrue);
      expect(registry.isTokenStart('a\n', 2), isTrue);
    });

    test('not right after a letter, digit or punctuation', () {
      expect(registry.isTokenStart('bel', 3), isFalse);
      expect(registry.isTokenStart('12', 2), isFalse);
      expect(registry.isTokenStart('bel.', 4), isFalse);
    });
  });

  group('links [[…]] (T10.9, DD-004 point 13)', () {
    test('the text between the brackets may hold spaces', () {
      final m = parse('Zie [[Offerte kozijnen vergelijken]] morgen').single;
      expect(m.type.id, 'link');
      expect(m.word, 'Offerte kozijnen vergelijken');
      expect(m.start, 4);
      expect(m.end, 36);
    });

    test('no other token inside a link', () {
      expect(found('[[Bel @Jan !vr #klus jan@firma.nl]] @Piet'), [
        ('link', 'Bel @Jan !vr #klus jan@firma.nl'),
        ('person', 'Piet'),
      ]);
    });

    test('Cyrillic and two links on one line', () {
      expect(found('[[Плитка для кухні]] en [[Нова кухня]]'), [
        ('link', 'Плитка для кухні'),
        ('link', 'Нова кухня'),
      ]);
    });

    test('blank, unclosed or across a line break stays text', () {
      expect(found('[[ ]] [[open'), isEmpty);
      expect(found('[[eerste\ntweede]]'), isEmpty);
    });

    test('escaped or glued to a word stays text', () {
      expect(found(r'\[[Offerte]]'), isEmpty);
      expect(found('zie[[Offerte]]'), isEmpty);
    });

    test('after an opening bracket, as a prefix token may', () {
      expect(found('([[Offerte]])'), [('link', 'Offerte')]);
    });

    test('a prefix word ends where a link starts (review step A)', () {
      expect(found('@Jan([[Offerte]])'), [
        ('person', 'Jan'),
        ('link', 'Offerte'),
      ]);
      expect(found('#klus[[[Offerte]]'), [
        ('tag', 'klus'),
        ('link', 'Offerte'),
      ]);
    });

    test('a run of opening brackets counts from the last one', () {
      final m = parse('[[[Offerte]]').single;
      expect(m.word, 'Offerte');
      expect(m.start, 1);
    });

    test('an opening inside starts the link again', () {
      expect(found('[[a [[b]]'), [('link', 'b')]);
    });

    test('Markdown checkboxes and links stay text', () {
      expect(found('- [ ] taak [tekst](url)'), isEmpty);
    });
  });

  group('the link being typed (tokenAt, T10.9)', () {
    ({InlineTokenType type, int start, int end, String query})? at(
      String text,
      String before,
    ) => registry.tokenAt(text, text.indexOf(before) + before.length);

    test('an open link runs to the cursor', () {
      final t = at('Zie [[off', '[[off')!;
      expect(t.type.id, 'link');
      expect((t.start, t.end, t.query), (4, 9, 'off'));
    });

    test('spaces belong to the query', () {
      expect(at('Zie [[offerte koz', 'koz')!.query, 'offerte koz');
    });

    test('a closed link ends after its closing signs', () {
      final t = at('Zie [[Offerte]] nu', '[[Off')!;
      expect((t.start, t.end, t.query), (4, 15, 'Off'));
    });

    test("another link's closing is never taken (review step B)", () {
      final text = 'Zie [[off en [[Container]] morgen';
      final t = at(text, '[[off')!;
      expect((t.start, t.end, t.query), (4, 9, 'off'));
    });

    test('a closing on the next line is not its own', () {
      final t = at('Zie [[off\nnog [[x]]', '[[off')!;
      expect(t.end, 9);
    });

    test('the cursor between the closing signs', () {
      final t = registry.tokenAt('[[abc]]', 6)!;
      expect((t.start, t.end, t.query), (0, 7, 'abc'));
    });

    test('after a closed link there is none', () {
      expect(registry.tokenAt('Zie [[abc]] ', 12), isNull);
    });

    test('a person inside an open link is not the token', () {
      expect(at('[[Bel @Ja', '@Ja')!.type.id, 'link');
    });
  });
}

class _PhoneTokenType extends InlineTokenType {
  const _PhoneTokenType();

  @override
  String get id => 'phone';

  @override
  TokenTrigger get trigger => PatternTrigger(RegExp(r'\b0\d-\d{8}\b'));

  @override
  int get schemaVersion => 1;

  @override
  Object? parse(String word, ParseContext context) => word;
}

class _OtherAtType extends InlineTokenType {
  const _OtherAtType();

  @override
  String get id => 'other';

  @override
  TokenTrigger get trigger => const PrefixTrigger('@');

  @override
  int get schemaVersion => 1;

  @override
  Object? parse(String word, ParseContext context) => word;
}
