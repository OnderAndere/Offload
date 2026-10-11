import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/database/app_database.dart';
import 'package:offload/data/items/drift_item_repository.dart';
import 'package:offload/data/projects/drift_project_repository.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/domain/projects/project.dart';
import 'package:offload/domain/projects/project_tree.dart';
import 'package:offload/domain/sync/change_operation.dart';

import '../../fakes/test_storage.dart';

/// Projects on the database (T3.1, DD-018 point 6).
void main() {
  late AppStorage storage;
  late DriftProjectRepository projects;
  late DriftItemRepository items;

  setUp(() async {
    storage = await openTestStorage();
    projects = DriftProjectRepository(storage);
    items = DriftItemRepository(storage);
  });
  tearDown(() => storage.close());

  AppDatabase db() => storage.database;

  Future<Map<String, Project>> byName() async => {
    for (final p in await projects.watchProjects().first) p.name: p,
  };

  Future<String?> projectOf(String itemId) async => (await (db().select(
    db().items,
  )..where((i) => i.id.equals(itemId))).getSingle()).contextId;

  Matcher refused(ProjectProblem problem) => throwsA(
    isA<ProjectException>().having((e) => e.problem, 'problem', problem),
  );

  test('creates projects on two levels, through the change log', () async {
    final renovatie = await projects.create('  Renovatie ');
    final garden = await projects.create('Moestuin', parentId: renovatie);

    final all = await byName();
    expect(all.keys, ['Moestuin', 'Renovatie']);
    expect(all['Moestuin']!.parentId, renovatie);
    final log = await (db().select(
      db().changeLog,
    )..where((e) => e.entityId.equals(garden))).get();
    expect(log.single.operation, ChangeOperation.insert);

    await expectLater(
      projects.create('Te diep', parentId: garden),
      refused(ProjectProblem.tooDeep),
    );
    await expectLater(
      projects.create('renovatie'),
      refused(ProjectProblem.nameTaken),
    );
    await expectLater(projects.create(' '), refused(ProjectProblem.emptyName));
  });

  test('two creates of one name at the same moment make one project', () async {
    final results = await Future.wait([
      projects
          .create('Renovatie')
          .then<Object>((id) => id, onError: (Object e) => e),
      projects
          .create('renovatie')
          .then<Object>((id) => id, onError: (Object e) => e),
    ]);
    expect(results.whereType<String>(), hasLength(1));
    expect(results.whereType<ProjectException>(), hasLength(1));
  });

  test('renames and moves within the rules', () async {
    final renovatie = await projects.create('Renovatie');
    final team = await projects.create('Teamoverleg');
    final garden = await projects.create('Moestuin', parentId: renovatie);

    await projects.rename(garden, 'Vakantie');
    await projects.move(team, renovatie);
    expect((await byName())['Teamoverleg']!.parentId, renovatie);

    await expectLater(
      projects.move(renovatie, team),
      refused(ProjectProblem.tooDeep),
    );
    await projects.create('Vakantie');
    await expectLater(
      projects.move(garden, null),
      refused(ProjectProblem.nameTaken),
    );
    await expectLater(
      projects.rename(team, 'vakantie'),
      refused(ProjectProblem.nameTaken),
    );
  });

  test(
    'archiving takes the sub-projects along; restoring brings them back',
    () async {
      final renovatie = await projects.create('Renovatie');
      final garden = await projects.create('Moestuin', parentId: renovatie);

      await projects.archive(renovatie);
      var all = await byName();
      expect(all['Renovatie']!.isArchived, isTrue);
      expect(all['Moestuin']!.isArchived, isTrue);
      await expectLater(
        projects.restoreFromArchive(garden),
        refused(ProjectProblem.notAvailable),
      );

      // The name is free again while it is archived.
      final other = await projects.create('Renovatie');
      await projects.restoreFromArchive(renovatie);
      all = await byName();
      expect(all['Renovatie']!.id, other);
      expect(all['Renovatie (2)']!.id, renovatie);
      expect(all['Renovatie (2)']!.isArchived, isFalse);
      expect(all['Moestuin']!.isArchived, isFalse);
    },
  );

  test(
    'deleting keeps the items and moves sub-projects up; undo puts it all back',
    () async {
      final renovatie = await projects.create('Renovatie');
      final garden = await projects.create('Moestuin', parentId: renovatie);
      await projects.create('Moestuin');
      final a = await items.capture('Offerte', source: ItemSource.app);
      final b = await items.capture('Planning', source: ItemSource.app);
      await items.setProject(a, renovatie);
      await items.setProject(b, garden);

      final deletion = await projects.delete(renovatie);
      var all = await byName();
      expect(all.containsKey('Renovatie'), isFalse);
      expect(all['Moestuin (2)']!.id, garden);
      expect(all['Moestuin (2)']!.parentId, isNull);
      expect(await projectOf(a), isNull);
      expect(await projectOf(b), garden);
      expect(await items.watchItem(a).first, isNotNull);

      await projects.undoDelete(deletion);
      all = await byName();
      expect(all['Renovatie']!.id, renovatie);
      expect(all['Moestuin']!.parentId, isNull);
      final back = (await projects.watchProjects().first).firstWhere(
        (p) => p.id == garden,
      );
      expect(back.name, 'Moestuin');
      expect(back.parentId, renovatie);
      expect(await projectOf(a), renovatie);
    },
  );

  test('undo leaves an item alone that got another project since', () async {
    final renovatie = await projects.create('Renovatie');
    final team = await projects.create('Teamoverleg');
    final a = await items.capture('Offerte', source: ItemSource.app);
    await items.setProject(a, renovatie);

    final deletion = await projects.delete(renovatie);
    await items.setProject(a, team);
    await projects.undoDelete(deletion);

    expect(await projectOf(a), team);
  });

  group('items and projects', () {
    test('an item goes only into a project in use', () async {
      final renovatie = await projects.create('Renovatie');
      final a = await items.capture('Offerte', source: ItemSource.app);

      await items.setProject(a, renovatie);
      expect((await items.watchItem(a).first)!.projectId, renovatie);
      await items.setProject(a, null);
      expect((await items.watchItem(a).first)!.projectId, isNull);

      await projects.archive(renovatie);
      await expectLater(
        items.setProject(a, renovatie),
        refused(ProjectProblem.notAvailable),
      );
    });

    test('the items of a project, and those without one', () async {
      final renovatie = await projects.create('Renovatie');
      final garden = await projects.create('Moestuin', parentId: renovatie);
      final a = await items.capture('Offerte', source: ItemSource.app);
      final b = await items.capture('Planning', source: ItemSource.app);
      final c = await items.capture('Los', source: ItemSource.app);
      final d = await items.capture('Weg', source: ItemSource.app);
      await items.setProject(a, renovatie);
      await items.setProject(b, garden);
      await items.moveToTrash(d);
      // An item whose project was deleted elsewhere (sync) counts as without.
      final orphanProject = await projects.create('Oud');
      final e = await items.capture('Wees', source: ItemSource.app);
      await items.setProject(e, orphanProject);
      await storage.writer.delete(db().contexts, orphanProject);

      final ofRenovatie = await items.watchProjectItems(renovatie).first;
      expect(ofRenovatie.map((i) => i.id), [a]);
      final without = await items.watchProjectItems(null).first;
      expect(without.map((i) => i.id), unorderedEquals([c, e]));
    });
  });

  test('the archived column survives a round trip through the log', () async {
    final renovatie = await projects.create('Renovatie');
    await projects.archive(renovatie);
    final log =
        await (db().select(db().changeLog)
              ..where((e) => e.entityId.equals(renovatie))
              ..orderBy([(e) => OrderingTerm.asc(e.hlc)]))
            .get();
    expect(log.map((e) => e.operation), [
      ChangeOperation.insert,
      ChangeOperation.update,
    ]);
    expect(log.last.payload, contains('archived_at'));
  });

  group('undo keeps the tree rules', () {
    test('no third level when the old parent moved under another', () async {
      final a = await projects.create('A');
      final c = await projects.create('C');
      final b = await projects.create('B', parentId: a);

      final deletion = await projects.delete(b);
      await projects.move(a, c);
      await projects.undoDelete(deletion);

      final all = await byName();
      expect(all['A']!.parentId, c);
      expect(all['B']!.parentId, isNull);
    });

    test('no sub-project in use under an archived project', () async {
      final a = await projects.create('A');
      final b = await projects.create('B', parentId: a);
      await projects.archive(a);

      final deletion = await projects.delete(a);
      await projects.restoreFromArchive(b);
      await projects.undoDelete(deletion);

      final all = await byName();
      expect(all['A']!.isArchived, isTrue);
      expect(all['B']!.parentId, isNull);
      expect(all['B']!.isArchived, isFalse);
    });
  });

  test('restoring a parent leaves a sub-project archived on its own', () async {
    final renovatie = await projects.create('Renovatie');
    final oud = await projects.create('Oud', parentId: renovatie);
    await projects.create('Moestuin', parentId: renovatie);
    await projects.archive(oud);
    // A later moment, so the parent's archive time differs.
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await projects.archive(renovatie);

    await projects.restoreFromArchive(renovatie);

    final all = await byName();
    expect(all['Renovatie']!.isArchived, isFalse);
    expect(all['Moestuin']!.isArchived, isFalse);
    expect(all['Oud']!.isArchived, isTrue);
  });
}
