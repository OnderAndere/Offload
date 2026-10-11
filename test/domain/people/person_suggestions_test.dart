import 'package:flutter_test/flutter_test.dart';
import 'package:offload/domain/people/person_suggestions.dart';
import 'package:offload/domain/tokens/token_suggestion.dart';

/// The person sheet of triage (DD-018 point 3).
void main() {
  const people = [
    NamedCandidate(name: 'Jan de Vries', aliases: ['JdV'], uses: 1),
    NamedCandidate(name: 'Janneke', uses: 5),
    NamedCandidate(name: 'Marjan', uses: 9),
    NamedCandidate(name: 'Petra', uses: 2),
  ];

  List<String> names(String query) => [
    for (final s in suggestPeople(query, people))
      s.isNew ? 'new:${s.name}' : s.name,
  ];

  test('starting with the query first, then containing, most used first', () {
    expect(names('jan'), ['Janneke', 'Jan de Vries', 'Marjan', 'new:jan']);
  });

  test('a name with spaces and an alias can be found', () {
    expect(names('jan de'), ['Jan de Vries', 'new:jan de']);
    expect(names('jdv'), ['Jan de Vries']);
  });

  test('no "new" line for an existing name, ignoring case', () {
    expect(names('PETRA'), ['Petra']);
  });

  test('an empty query gives the most used people', () {
    expect(names(''), ['Marjan', 'Janneke', 'Petra', 'Jan de Vries']);
  });

  test('at most five lines, the new line included', () {
    final many = [
      for (var i = 0; i < 9; i++) NamedCandidate(name: 'Anna $i', uses: i),
    ];
    final lines = suggestPeople('ann', many);
    expect(lines, hasLength(5));
    expect(lines.last.isNew, isTrue);
  });

  group('the people in the text first (DD-018 point 7)', () {
    test('namedPeople finds people by name or alias, in text order', () {
      expect(namedPeople(people, ['petra', 'JdV', 'Kees']), [
        'Petra',
        'Jan de Vries',
      ]);
    });

    test('the named people come first, marked by the caller', () {
      final named = namedPeople(people, ['Petra']);
      final empty = suggestPeopleNamedFirst('', people, named);
      expect(empty.first, (name: 'Petra', isNew: false));
      expect(empty.where((s) => s.name == 'Petra'), hasLength(1));
      // A query that does not match them leaves them out.
      final jan = suggestPeopleNamedFirst('jan', people, named);
      expect(jan.map((s) => s.name), isNot(contains('Petra')));
    });
  });
}
