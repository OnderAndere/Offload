import 'package:flutter_test/flutter_test.dart';
import 'package:offload/domain/projects/project.dart';
import 'package:offload/domain/projects/project_token.dart';

/// `^project` words (T10.5, REQ-050, DD-004 point 11).
void main() {
  const renovatie = Project(id: 'r', name: 'Renovatie');
  const keukenSub = Project(id: 'rk', name: 'Keuken', parentId: 'r');
  const schuur = Project(id: 's', name: 'Oude schuur');
  const tuin = Project(id: 't', name: 'Tuin');
  const tuinKeuken = Project(id: 'tk', name: 'Keuken', parentId: 't');
  final archived = Project(
    id: 'a',
    name: 'Archief',
    archivedAt: DateTime.utc(2026),
  );

  group('projectKey', () {
    test('ignores case, spaces, - and _', () {
      expect(projectKey('Oude schuur'), 'oudeschuur');
      expect(projectKey('oude-Schuur'), 'oudeschuur');
      expect(projectKey('OUDE_SCHUUR'), 'oudeschuur');
    });

    test('Cyrillic case folds too', () {
      expect(projectKey('Стара Хата'), projectKey('стара-хата'));
    });

    test('trailing punctuation does not count', () {
      expect(projectKey('Wat nu?'), projectKey('wat-nu'));
    });
  });

  group('projectForWord', () {
    final all = [renovatie, keukenSub, schuur, tuin, tuinKeuken, archived];

    test('a top-level project by name', () {
      expect(projectForWord('renovatie', all), 'r');
      expect(projectForWord('oude-schuur', all), 's');
    });

    test('a sub-project by path', () {
      expect(projectForWord('renovatie/keuken', all), 'rk');
      expect(projectForWord('Tuin/Keuken', all), 'tk');
    });

    test('a sub-project name shared by two parents needs the path', () {
      expect(projectForWord('keuken', all), isNull);
    });

    test('a sub-project with a unique name is found by name alone', () {
      expect(projectForWord('keuken', [renovatie, keukenSub]), 'rk');
    });

    test('the top-level project wins a name it shares', () {
      const keukenTop = Project(id: 'k', name: 'Keuken');
      expect(projectForWord('keuken', [...all, keukenTop]), 'k');
    });

    test('archived projects and unknown names give none', () {
      expect(projectForWord('archief', all), isNull);
      expect(projectForWord('onbekend', all), isNull);
      expect(projectForWord('renovatie/badkamer', all), isNull);
      expect(projectForWord('a/b/c', all), isNull);
    });
  });

  group('wordForProject', () {
    final all = [renovatie, keukenSub, schuur, tuin, tuinKeuken];

    test('the name, spaces as -', () {
      expect(wordForProject(schuur, all), 'Oude-schuur');
      expect(wordForProject(renovatie, all), 'Renovatie');
    });

    test('the path when the name alone is ambiguous', () {
      expect(wordForProject(keukenSub, all), 'Renovatie/Keuken');
      expect(wordForProject(keukenSub, [renovatie, keukenSub]), 'Keuken');
    });

    test('none for a name that cannot be a word', () {
      const sign = Project(id: 'x', name: '#thuis');
      const slash = Project(id: 'y', name: 'A/B');
      expect(wordForProject(sign, [sign]), isNull);
      expect(wordForProject(slash, [slash]), isNull);
    });

    test('every word it gives finds its project again', () {
      for (final project in all) {
        final word = wordForProject(project, all);
        expect(projectForWord(word!, all), project.id, reason: project.name);
      }
    });
  });

  group('matchProjectWord (PO decision 03-10-2026)', () {
    final all = [renovatie, keukenSub, schuur, tuin, tuinKeuken, archived];

    test('a project it names', () {
      expect(matchProjectWord('oude-schuur', all), isA<NamesProject>());
      final named = matchProjectWord('renovatie/keuken', all) as NamesProject;
      expect(named.id, 'rk');
    });

    test('no project: a top-level name from the word', () {
      final none = matchProjectWord('nieuwe_kas-2026', all) as NamesNoProject;
      expect(none.name, 'nieuwe kas 2026');
      expect(none.parentId, isNull);
      expect(none.canCreate, isTrue);
    });

    test('a Cyrillic name with spaces', () {
      final none = matchProjectWord('Нова-кухня', all) as NamesNoProject;
      expect(none.name, 'Нова кухня');
    });

    test('an archived project does not count', () {
      final none = matchProjectWord('archief', all) as NamesNoProject;
      expect(none.name, 'archief');
    });

    test('a path under an existing project: a sub-project there', () {
      final none = matchProjectWord('tuin/kas', all) as NamesNoProject;
      expect(none.name, 'kas');
      expect(none.parentId, 't');
      expect(none.canCreate, isTrue);
    });

    test('a path whose parent does not exist cannot be created', () {
      final none = matchProjectWord('zolder/kast', all) as NamesNoProject;
      expect(none.canCreate, isFalse);
    });

    test('a name shared by sub-projects of different parents', () {
      expect(matchProjectWord('keuken', all), isA<NamesSeveral>());
    });

    test('a path whose parent fits two projects, each with that child', () {
      const tuinA = Project(id: 'ta', name: 'Tuin');
      const tuinB = Project(id: 'tb', name: 'tuin ');
      const kasA = Project(id: 'ka', name: 'Kas', parentId: 'ta');
      const kasB = Project(id: 'kb', name: 'Kas', parentId: 'tb');
      expect(
        matchProjectWord('tuin/kas', [tuinA, tuinB, kasA, kasB]),
        isA<NamesSeveral>(),
      );
    });
  });
}
