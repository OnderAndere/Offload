import 'package:flutter_test/flutter_test.dart';
import 'package:offload/domain/people/person.dart';
import 'package:offload/domain/people/person_merge.dart';

/// Merging people (T3.2b, DD-015).
void main() {
  PersonProfile profile({
    int? day,
    int? month,
    int? year,
    String? note,
    String? organisation,
    String? jobTitle,
  }) => (
    birthdayDay: day,
    birthdayMonth: month,
    birthdayYear: year,
    note: note,
    organisation: organisation,
    jobTitle: jobTitle,
  );

  group('mergeProfiles', () {
    test('the target keeps its own; an empty birthday is taken over', () {
      expect(
        mergeProfiles(profile(day: 3, month: 4), profile(day: 9, month: 9)),
        profile(day: 3, month: 4),
      );
      expect(
        mergeProfiles(profile(), profile(day: 9, month: 9, year: 1980)),
        profile(day: 9, month: 9, year: 1980),
      );
    });

    test('organisation and job title: the target keeps its own', () {
      expect(
        mergeProfiles(
          profile(organisation: 'Tennisclub'),
          profile(organisation: 'Bibliotheek', jobTitle: 'Voorzitter'),
        ),
        profile(organisation: 'Tennisclub', jobTitle: 'Voorzitter'),
      );
    });

    test('notes are put one after the other', () {
      expect(
        mergeProfiles(
          profile(note: 'Werkt bij de bibliotheek'),
          profile(note: ' Fietst '),
        ),
        profile(note: 'Werkt bij de bibliotheek\n\nFietst'),
      );
      expect(mergeProfiles(profile(), profile(note: 'X')), profile(note: 'X'));
      // A single note stays exactly as it was.
      expect(
        mergeProfiles(profile(note: '  - lijst'), profile()),
        profile(note: '  - lijst'),
      );
      expect(
        mergeProfiles(profile(note: '  '), profile(note: '# A')),
        profile(note: '# A'),
      );
    });
  });

  group('personIdsByName', () {
    test('a name before an alias; the oldest of two wins', () {
      const older = Person(id: '01a', name: 'Jan', aliases: ['JB']);
      const newer = Person(id: '01b', name: 'Bakker', aliases: ['jan', 'jb']);
      final byName = personIdsByName([newer, older]);
      expect(byName['jan'], '01a'); // a name beats an alias
      expect(byName['jb'], '01a'); // the oldest of two aliases
      expect(byName['bakker'], '01b');
    });
  });

  group('resolvePersonId', () {
    test('follows merged people to a live one; stops at a loop', () {
      final merged = {'a': 'b', 'b': 'c', 'x': 'y', 'y': 'x'};
      expect(resolvePersonId('c', merged, {'c'}), 'c');
      expect(resolvePersonId('a', merged, {'c'}), 'c');
      expect(resolvePersonId('x', merged, {'c'}), isNull);
      expect(resolvePersonId('gone', merged, {'c'}), isNull);
    });
  });
}
