import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/database/app_database.dart';
import 'package:offload/data/people/drift_people_repository.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/domain/people/birthday.dart';
import 'package:offload/domain/people/person.dart';
import 'package:offload/domain/sync/change_operation.dart';

import '../../fakes/test_storage.dart';

/// People as a light entity (DD-015): found by name or alias, created when
/// unknown, never twice.
void main() {
  late AppStorage storage;
  late DriftPeopleRepository people;

  setUp(() async {
    storage = await openTestStorage();
    people = DriftPeopleRepository(storage);
  });
  tearDown(() => storage.close());

  Future<List<PeopleData>> all() =>
      storage.database.select(storage.database.people).get();

  test('creates an unknown name once, then finds it ignoring case', () async {
    final jan = await people.idFor('Jan');
    expect(await people.idFor('jan'), jan);
    expect(await people.idFor('  JAN '), jan);
    expect(await all(), hasLength(1));
  });

  test('two calls at the same moment create one person', () async {
    final ids = await Future.wait([
      people.idFor('Olena'),
      people.idFor('olena'),
    ]);
    expect(ids.toSet(), hasLength(1));
    expect(await all(), hasLength(1));
  });

  test('finds a person by alias', () async {
    final jan = await people.idFor('Jan de Vries');
    await storage.writer.insert(
      storage.database.personAliases,
      PersonAliasesCompanion(personId: Value(jan), alias: const Value('JdV')),
    );
    expect(await people.idFor('jdv'), jan);
  });

  Future<List<String>> aliasesOf(String id) async => [
    for (final a in await (storage.database.select(
      storage.database.personAliases,
    )..where((a) => a.personId.equals(id) & a.deletedAt.isNull())).get())
      a.alias,
  ];

  Matcher refused(PersonProblem problem) => throwsA(
    isA<PersonException>().having((e) => e.problem, 'problem', problem),
  );

  test('find looks up by name or alias and creates nothing', () async {
    expect(await people.find('Jan'), isNull);
    final jan = await people.idFor('Jan');
    await people.rename(jan, 'Jan Bakker');
    expect(await people.find('JAN'), jan);
    expect(await people.find('jan bakker'), jan);
    expect(await people.find('Piet'), isNull);
    expect(await all(), hasLength(1));
  });

  test('watchPeople lists live people by name, with their aliases', () async {
    final petra = await people.idFor('petra');
    final anna = await people.idFor('Anna');
    final gone = await people.idFor('Weg');
    await storage.writer.delete(storage.database.people, gone);
    await people.rename(petra, 'Petra Jansen');

    final list = await people.watchPeople().first;
    expect(list.map((p) => p.id), [anna, petra]);
    expect(list[0].aliases, isEmpty);
    expect(list[1].aliases, ['petra']);
  });

  test('watchPeople emits again when only an alias is added', () async {
    final jan = await people.idFor('Jan');
    final seen = <List<String>>[];
    final sub = people.watchPeople().listen(
      (list) => seen.add(list.single.aliases),
    );
    await pumpEventQueue();
    await storage.writer.insert(
      storage.database.personAliases,
      PersonAliasesCompanion(personId: Value(jan), alias: const Value('JB')),
    );
    await pumpEventQueue();
    await sub.cancel();
    expect(seen.first, isEmpty);
    expect(seen.last, ['JB']);
  });

  group('rename (DD-015)', () {
    test('the old name becomes an alias, through the change log', () async {
      final jan = await people.idFor('Jan');
      await people.rename(jan, ' Jan Bakker ');

      final row = (await all()).single;
      expect(row.name, 'Jan Bakker');
      expect(await aliasesOf(jan), ['Jan']);
      expect(await people.idFor('jan'), jan);
      final log = await storage.database
          .select(storage.database.changeLog)
          .get();
      expect(log.where((e) => e.entityId == jan).map((e) => e.operation), [
        ChangeOperation.insert,
        ChangeOperation.update,
      ]);
    });

    test('renaming to an own alias swaps the two', () async {
      final jan = await people.idFor('Jan');
      await people.rename(jan, 'Jan Bakker');
      await people.rename(jan, 'jan');
      expect((await all()).single.name, 'jan');
      expect(await aliasesOf(jan), ['Jan Bakker']);
    });

    test(
      'a change of case adds no alias; an alias is not added twice',
      () async {
        final jan = await people.idFor('jan bakker');
        await people.rename(jan, 'Jan Bakker');
        expect(await aliasesOf(jan), isEmpty);

        await people.rename(jan, 'Jan');
        await people.rename(jan, 'Jan Bakker');
        await people.rename(jan, 'Jan');
        expect((await all()).single.name, 'Jan');
        expect(await aliasesOf(jan), ['Jan Bakker']);
      },
    );

    test('refuses an empty name and a name of someone else', () async {
      final jan = await people.idFor('Jan');
      final petra = await people.idFor('Petra');
      await people.rename(petra, 'Petra Jansen');

      await expectLater(
        people.rename(jan, '  '),
        refused(PersonProblem.emptyName),
      );
      await expectLater(
        people.rename(jan, 'PETRA JANSEN'),
        refused(PersonProblem.nameTaken),
      );
      await expectLater(
        people.rename(jan, 'petra'),
        refused(PersonProblem.nameTaken),
      );
      await expectLater(
        people.rename('nobody', 'X'),
        refused(PersonProblem.notAvailable),
      );
      expect((await all()).firstWhere((p) => p.id == jan).name, 'Jan');
      expect(await aliasesOf(jan), isEmpty);
    });
  });

  group('profile (T3.3, REQ-031)', () {
    test('birthday and note are stored, shown and removed', () async {
      final jan = await people.idFor('Jan');
      await people.setBirthday(jan, Birthday.tryCreate(3, 4, 1980));
      await people.setNote(jan, 'Werkt bij de bibliotheek');
      var shown = (await people.watchPeople().first).single;
      expect(shown.birthday, Birthday.tryCreate(3, 4, 1980));
      expect(shown.note, 'Werkt bij de bibliotheek');

      await people.setBirthday(jan, null);
      await people.setNote(jan, '   ');
      shown = (await people.watchPeople().first).single;
      expect(shown.birthday, isNull);
      expect(shown.note, isNull);
      final row = (await all()).single;
      expect(row.birthdayDay, isNull);
      expect(row.note, isNull);
    });

    test('through the change log; not for someone gone', () async {
      final jan = await people.idFor('Jan');
      await people.setBirthday(jan, Birthday.tryCreate(29, 2));
      final log = await (storage.database.select(
        storage.database.changeLog,
      )..where((e) => e.entityId.equals(jan))).get();
      expect(log.last.operation, ChangeOperation.update);
      expect(log.last.payload, contains('birthday_day'));

      await storage.writer.delete(storage.database.people, jan);
      await expectLater(
        people.setNote(jan, 'x'),
        refused(PersonProblem.notAvailable),
      );
      await expectLater(
        people.setBirthday(jan, null),
        refused(PersonProblem.notAvailable),
      );
    });
  });
}
