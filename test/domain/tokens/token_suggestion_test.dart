import 'package:flutter_test/flutter_test.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/domain/projects/project.dart';
import 'package:offload/domain/time/local_date.dart';
import 'package:offload/domain/tokens/inline_token.dart';
import 'package:offload/domain/tokens/inline_token_registry.dart';
import 'package:offload/domain/tokens/token_suggestion.dart';

/// The suggestion list (REQ-033; PO decisions 27-09-2026).
void main() {
  final registry = InlineTokenRegistry.standard();

  group('the token being typed', () {
    test('after the prefix, with what is typed so far', () {
      final token = registry.tokenAt('bel @Ja', 7)!;

      expect(token.type.id, 'person');
      expect((token.start, token.end, token.query), (4, 7, 'Ja'));
    });

    test('just the prefix: an empty query', () {
      expect(registry.tokenAt('bel @', 5)!.query, '');
    });

    test('the cursor inside a word: the word ends at the next space', () {
      final token = registry.tokenAt('bel #renovatie nu', 6)!;

      expect((token.query, token.end), ('r', 14));
    });

    test('right after an opening bracket', () {
      expect(registry.tokenAt('(!v', 3)!.type.id, 'date');
    });

    test('trailing punctuation is not part of the word, as in parse', () {
      // `(@Ja|)`: the cursor before the bracket.
      final token = registry.tokenAt('(@Ja)', 4)!;

      expect((token.query, token.end), ('Ja', 4));
      // Behind the punctuation there is nothing to suggest (review T2.2a).
      expect(registry.tokenAt('bel @Jan.', 9), isNull);
      expect(registry.tokenAt('bel @Jan,', 9), isNull);
      expect(registry.tokenAt('(@Jan)', 6), isNull);
    });

    test('no token: plain text, after a space, e-mail, reserved prefix', () {
      expect(registry.tokenAt('bel Jan', 7), isNull);
      expect(registry.tokenAt('bel @Jan ', 9), isNull);
      expect(registry.tokenAt('jan@fir', 7), isNull);
      expect(registry.tokenAt('~rad', 4), isNull);
      expect(registry.tokenAt('', 0), isNull);
    });
  });

  group('date suggestions', () {
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

    List<String> words(String query) => [
      for (final o in dutch.suggestions(query, sunday)) o.word,
    ];

    test(
      'relative words, then the coming weekdays by date, then next week',
      () {
        expect(words(''), [
          'vandaag',
          'morgen',
          'overmorgen',
          'maandag',
          'dinsdag',
          'woensdag',
          'donderdag',
          'vrijdag',
          'zaterdag',
          'zondag',
          'volgendeweek',
        ]);
      },
    );

    test('short words find the full word, which is what gets inserted', () {
      final options = dutch.suggestions('vr', sunday);

      expect(options.single.word, 'vrijdag');
      expect(options.single.date, LocalDate(2026, 10, 2));
    });

    test('filters on the start of any word, case-insensitive', () {
      expect(words('V'), ['vandaag', 'vrijdag', 'volgendeweek']);
      expect(words('xyz'), isEmpty);
    });
  });

  group('names', () {
    bool validName(String word) =>
        RegExp(r'^\p{L}', unicode: true).hasMatch(word);

    List<(String, String, bool)> suggest(
      String query,
      List<NamedCandidate> candidates,
    ) => [
      for (final s in suggestNames(query, candidates, isValidNew: validName))
        (s.label, s.insert, s.isNew),
    ];

    test('names starting with the query before names containing it', () {
      final result = suggest('an', const [
        NamedCandidate(name: 'Johan'),
        NamedCandidate(name: 'Anna'),
      ]);

      expect(result.take(2).map((r) => r.$1), ['Anna', 'Johan']);
    });

    test('the most used first, then alphabetical', () {
      final result = suggest('', const [
        NamedCandidate(name: 'Bram', uses: 1),
        NamedCandidate(name: 'Anna', uses: 1),
        NamedCandidate(name: 'Piet', uses: 9),
      ]);

      expect(result.map((r) => r.$1), ['Piet', 'Anna', 'Bram']);
    });

    test('at most five; an empty query offers nothing new', () {
      final many = [for (var i = 0; i < 8; i++) NamedCandidate(name: 'Naam$i')];

      expect(suggest('', many), hasLength(5));
      expect(suggest('', many).any((r) => r.$3), isFalse);
    });

    test('offers new when nothing is called exactly that', () {
      final result = suggest('Jo', const [NamedCandidate(name: 'Johan')]);

      expect(result, [('Johan', 'Johan', false), ('Jo', 'Jo', true)]);
    });

    test('no new line when the name exists, in any case or as alias', () {
      expect(suggest('johan', const [NamedCandidate(name: 'Johan')]), [
        ('Johan', 'Johan', false),
      ]);
      expect(
        suggest('jd', const [
          NamedCandidate(name: 'Jan de Vries', aliases: ['JD']),
        ]).any((r) => r.$3),
        isFalse,
      );
    });

    test('no new line for a word that is no valid name', () {
      expect(suggest('1', const []), isEmpty);
    });

    test('with five matches, the new line takes the last place', () {
      final many = [for (var i = 0; i < 6; i++) NamedCandidate(name: 'Jan$i')];

      final result = suggest('Jan', many);

      expect(result, hasLength(5));
      expect(result.last, ('Jan', 'Jan', true));
    });

    test('a name with spaces goes in as a one-word alias', () {
      final result = suggest('vr', const [
        NamedCandidate(name: 'Jan de Vries', aliases: ['Jan', 'Vries']),
        NamedCandidate(name: 'Zonder Alias'),
      ]);

      expect(result.first, ('Jan de Vries', 'Vries', false));
      expect(result.any((r) => r.$1 == 'Zonder Alias'), isFalse);
    });

    test('Cyrillic names match without regard to case', () {
      expect(suggest('ол', const [NamedCandidate(name: 'Олена')]).first, (
        'Олена',
        'Олена',
        false,
      ));
    });
  });

  group('project suggestions (T10.5, DD-004 point 11)', () {
    const verbouwing = Project(id: 'v', name: 'Verbouwing');
    const keuken = Project(id: 'k', name: 'Keuken', parentId: 'v');
    const schuur = Project(id: 's', name: 'Oude schuur');
    final oud = Project(id: 'o', name: 'Oud', archivedAt: DateTime.utc(2026));
    final all = [verbouwing, keuken, schuur, oud];
    bool valid(String word) => true;

    List<String> labels(List<TokenSuggestion> list) => [
      for (final s in list) s.isNew ? 'new:${s.label}' : s.label,
    ];

    test('starting before containing, most used first; no archived', () {
      final found = suggestProjects(
        'ou',
        all,
        uses: const {'s': 3},
        isValidNew: valid,
      );
      // "Oude schuur" starts with it; "Verbouwing" contains it.
      expect(labels(found), ['Oude schuur', 'Verbouwing', 'new:ou']);
      expect(found.first.insert, 'Oude-schuur');
    });

    test('a sub-project carries its parent; the path finds it too', () {
      final byName = suggestProjects('keu', all, isValidNew: valid);
      expect(byName.first.label, 'Keuken');
      expect(byName.first.parent, 'Verbouwing');
      final byPath = suggestProjects('verbouwing/k', all, isValidNew: valid);
      expect(labels(byPath), ['Keuken']);
    });

    test('no "new" line for an existing key or a path', () {
      expect(labels(suggestProjects('oude-schuur', all, isValidNew: valid)), [
        'Oude schuur',
      ]);
      expect(
        suggestProjects('verbouwing/badkamer', all, isValidNew: valid),
        isEmpty,
      );
    });
  });

  group('priority suggestions', () {
    const words = PriorityVocabulary(high: ['hoog'], low: ['laag']);

    test('the words, high first, with their meaning', () {
      final all = suggestPriorities('', words);
      expect([for (final s in all) s.insert], ['hoog', 'laag']);
      expect(all.first.priority, ItemPriority.high);
      expect(
        [for (final s in suggestPriorities('l', words)) s.insert],
        ['laag'],
      );
      expect(suggestPriorities('x', words), isEmpty);
    });
  });

  group('suggestItems (T10.9)', () {
    test('title, status and project; the label goes in', () {
      final long = List.filled(20, 'woord').join(' ');
      final suggestions = suggestItems([
        const ItemCandidate(
          id: 'a',
          rawText: 'Offerte [concept]',
          status: ItemStatus.active,
          project: 'Verbouwing',
        ),
        ItemCandidate(id: 'b', rawText: long, status: ItemStatus.inbox),
      ], (raw) => raw);
      expect(suggestions.first.label, 'Offerte [concept]');
      expect(suggestions.first.insert, 'Offerte (concept)');
      expect(suggestions.first.itemId, 'a');
      expect(suggestions.first.status, ItemStatus.active);
      expect(suggestions.first.parent, 'Verbouwing');
      expect(suggestions.last.insert, endsWith('…'));
    });
  });
}
