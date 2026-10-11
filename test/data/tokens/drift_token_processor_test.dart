import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/database/app_database.dart';
import 'package:offload/data/items/drift_item_repository.dart';
import 'package:offload/data/projects/drift_project_repository.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/data/tokens/drift_token_processor.dart';
import 'package:offload/domain/ids/uuid_v7.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/domain/time/local_date.dart';
import 'package:offload/domain/tokens/inline_token.dart';
import 'package:offload/domain/tokens/inline_token_registry.dart';
import 'package:offload/domain/tokens/token_processing.dart';

import '../../fakes/test_storage.dart';

/// Working out tokens after saving (T2.2 step B, DD-004, DD-015).
void main() {
  late AppStorage storage;
  late DriftItemRepository items;
  late DriftTokenProcessor processor;

  final dutch = DateVocabulary(
    today: const ['vandaag'],
    tomorrow: const ['morgen'],
    dayAfterTomorrow: const ['overmorgen'],
    nextWeek: const ['volgendeweek'],
    weekdays: const [
      ['ma'],
      ['di'],
      ['wo'],
      ['do'],
      ['vr'],
      ['za'],
      ['zo'],
    ],
  );

  setUp(() async {
    storage = await openTestStorage();
    items = DriftItemRepository(storage);
    processor = DriftTokenProcessor(
      storage,
      registry: InlineTokenRegistry.standard(),
      dates: () => dutch,
      priorities: () => const PriorityVocabulary(high: ['hoog'], low: ['laag']),
    );
  });
  tearDown(() => storage.close());

  AppDatabase db() => storage.database;

  Future<String> capture(String text) =>
      items.capture(text, source: ItemSource.app);

  /// An item captured at [moment] (its UUIDv7 carries the time), as the
  /// widget does.
  Future<String> captureAt(DateTime moment, String text) async {
    final id = UuidV7Generator(
      now: () => moment.toUtc().millisecondsSinceEpoch,
    ).next();
    await items.captureWithId(id, text, source: ItemSource.widget);
    return id;
  }

  Future<List<PeopleData>> people() => db().select(db().people).get();
  Future<List<Tag>> tags() => db().select(db().tags).get();
  Future<List<Token>> tokensOf(String id) =>
      (db().select(db().tokens)..where((t) => t.itemId.equals(id))).get();
  Future<Item> item(String id) =>
      (db().select(db().items)..where((i) => i.id.equals(id))).getSingle();

  test('creates the person and tag and stores the tokens', () async {
    final id = await capture('bel @Jan over #renovatie');

    await processor.process(id);

    final person = (await people()).single;
    final tag = (await tags()).single;
    expect(person.name, 'Jan');
    expect(tag.name, 'renovatie');
    final tokens = await tokensOf(id);
    expect(
      {for (final t in tokens) t.tokenType: t.resolvedValue},
      {'person': person.id, 'tag': tag.id},
    );
    expect(tokens.every((t) => t.parserVersion == tokenParserVersion), isTrue);
    expect(tokens.map((t) => t.rawValue), containsAll(['Jan', 'renovatie']));
  });

  test('new persons and tags go through the change log (REQ-008)', () async {
    final id = await capture('@Jan #renovatie');

    await processor.process(id);

    final log = await db().select(db().changeLog).get();
    expect(log.map((e) => e.entity), containsAll(['people', 'tags']));
  });

  test('an existing person or tag is reused, whatever the case', () async {
    final first = await capture('@Jan #Renovatie');
    final second = await capture('@jan #RENOVATIE');

    await processor.process(first);
    await processor.process(second);

    expect(await people(), hasLength(1));
    expect(await tags(), hasLength(1));
    expect(
      (await tokensOf(
        second,
      )).firstWhere((t) => t.tokenType == 'person').resolvedValue,
      (await people()).single.id,
    );
  });

  test('Cyrillic names match without regard to case (DD-015)', () async {
    // SQLite NOCASE would see two people here; Unicode folding sees one.
    final first = await capture('@Олена');
    final second = await capture('@олена');

    await processor.process(first);
    await processor.process(second);

    expect((await people()).single.name, 'Олена');
  });

  test('an alias finds the person', () async {
    final janId = await storage.writer.insert(
      db().people,
      const PeopleCompanion(name: Value('Jan de Vries')),
    );
    await storage.writer.insert(
      db().personAliases,
      PersonAliasesCompanion(personId: Value(janId), alias: const Value('Jan')),
    );
    final id = await capture('@jan');

    await processor.process(id);

    expect(await people(), hasLength(1));
    expect((await tokensOf(id)).single.resolvedValue, janId);
  });

  test('a deleted person is not reused', () async {
    final oldId = await storage.writer.insert(
      db().people,
      const PeopleCompanion(name: Value('Jan')),
    );
    await storage.writer.delete(db().people, oldId);
    final id = await capture('@Jan');

    await processor.process(id);

    expect((await tokensOf(id)).single.resolvedValue, isNot(oldId));
  });

  test(
    'two items with the same new person, processed together: one person',
    () async {
      final a = await capture('@Piet');
      final b = await capture('@piet');

      await Future.wait([processor.process(a), processor.process(b)]);

      expect(await people(), hasLength(1));
    },
  );

  group('deadline', () {
    test(
      'the first date becomes the deadline, as a date without time',
      () async {
        // Sunday 27 September 2026, 10:00 local time.
        final id = await captureAt(DateTime(2026, 9, 27, 10), '!vr en !ma');

        await processor.process(id);

        final dueAt = (await item(id)).dueAt!;
        expect(storedToDateOnly(dueAt), LocalDate(2026, 10, 2));
        expect(dueAt.isUtc, isTrue);
        final dates = [
          for (final t in await tokensOf(id))
            if (t.tokenType == 'date') t.resolvedValue,
        ];
        expect(dates, containsAll(['2026-10-02', '2026-09-28']));
      },
    );

    test('relative dates count from the moment of capture', () async {
      // Captured on Friday; processed later, e.g. from the widget queue.
      final id = await captureAt(DateTime(2026, 10, 2, 22), '!morgen');

      await processor.process(id);

      expect(storedToDateOnly((await item(id)).dueAt!), LocalDate(2026, 10, 3));
    });

    test('a deadline that fails to be written leaves no tokens, so it is '
        'set at the next start (review T2.2 step B)', () async {
      final id = await capture('@Jan !morgen');
      await db().customStatement(
        'CREATE TRIGGER fail_due BEFORE UPDATE OF due_at ON items '
        "BEGIN SELECT RAISE(ABORT, 'test failure'); END",
      );

      await expectLater(processor.process(id), throwsA(anything));

      expect(await tokensOf(id), isEmpty);
      expect((await item(id)).dueAt, isNull);

      await db().customStatement('DROP TRIGGER fail_due');
      await processor.processOutdated();

      expect((await item(id)).dueAt, isNotNull);
      expect(await tokensOf(id), hasLength(2));
    });

    group('follows the text after editing (DD-018 point 1)', () {
      // Captured ten days ago; the edits below happen now. Worked out when
      // each test runs, not once for the group.
      late DateTime tenDaysAgo;
      late LocalDate captureDay;
      late LocalDate today;
      setUp(() {
        final now = DateTime.now();
        tenDaysAgo = now.subtract(const Duration(days: 10));
        captureDay = LocalDate.of(tenDaysAgo);
        today = LocalDate.of(now);
      });
      DateTime stored(LocalDate day) => dateOnlyToStored(day);

      test('a changed date replaces the deadline', () async {
        final id = await captureAt(tenDaysAgo, 'Bel !morgen');
        await processor.process(id);
        expect((await item(id)).dueAt, stored(captureDay.addDays(1)));

        await items.editText(id, 'Bel !overmorgen');
        await processor.process(id);

        // A newly typed relative date counts from the edit.
        expect((await item(id)).dueAt, stored(today.addDays(2)));
      });

      test('removing the date clears the deadline', () async {
        final id = await captureAt(tenDaysAgo, 'Bel !morgen');
        await processor.process(id);

        await items.editText(id, 'Bel Jan');
        await processor.process(id);

        expect((await item(id)).dueAt, isNull);
      });

      test('a date that stays in the text keeps its date', () async {
        final id = await captureAt(tenDaysAgo, 'Bel !morgen');
        await processor.process(id);

        await items.editText(id, 'Bel Jan !morgen over de offerte');
        await processor.process(id);

        expect((await item(id)).dueAt, stored(captureDay.addDays(1)));
      });

      test('a date removed and typed again counts from then', () async {
        final id = await captureAt(tenDaysAgo, 'Bel !morgen');
        await processor.process(id);
        await items.editText(id, 'Bel');
        await processor.process(id);

        await items.editText(id, 'Bel !morgen');
        await processor.process(id);

        expect((await item(id)).dueAt, stored(today.addDays(1)));
      });

      test(
        'an edit whose processing was interrupted is caught at start',
        () async {
          final id = await captureAt(tenDaysAgo, 'Bel !morgen');
          await processor.process(id);

          // Saved, but the app stopped before processing.
          await items.editText(id, 'Bel Jan');
          await processor.processOutdated();

          expect((await item(id)).dueAt, isNull);
          expect(await tokensOf(id), isEmpty);
        },
      );

      test(
        'the same after rebuilding the tokens, as on another device',
        () async {
          final id = await captureAt(tenDaysAgo, 'Bel !morgen');
          await processor.process(id);
          await items.editText(id, 'Bel !morgen en !overmorgen');
          await processor.process(id);
          final before = await tokensOf(id);

          // Tokens are derived data: gone, then worked out again.
          await (db().delete(
            db().tokens,
          )..where((t) => t.itemId.equals(id))).go();
          await processor.processOutdated();

          final after = await tokensOf(id);
          expect(
            {for (final t in after) t.rawValue: t.resolvedValue},
            {for (final t in before) t.rawValue: t.resolvedValue},
          );
          expect(
            {for (final t in after) t.rawValue: t.resolvedValue},
            {
              'morgen': captureDay.addDays(1).toString(),
              'overmorgen': today.addDays(2).toString(),
            },
          );
        },
      );
    });
  });

  test('processing again replaces the tokens, never duplicates', () async {
    final id = await capture('@Jan #renovatie !vr');

    await processor.process(id);
    await processor.process(id);

    expect(await tokensOf(id), hasLength(3));
    expect(await people(), hasLength(1));
  });

  test('deleted and missing items are skipped', () async {
    final id = await capture('@Jan');
    await storage.writer.delete(db().items, id);

    await processor.process(id);
    await processor.process(UuidV7Generator().next());

    expect(await people(), isEmpty);
  });

  test('the raw text is never changed (DD-004)', () async {
    const text = 'bel (@Jan) over #renovatie, !vr.';
    final id = await capture(text);

    await processor.process(id);

    expect((await item(id)).rawText, text);
  });

  group('processOutdated', () {
    test('processes items without tokens, skips plain text', () async {
      final withTokens = await capture('@Jan');
      final plain = await capture('Gewoon een gedachte');

      await processor.processOutdated();

      expect(await tokensOf(withTokens), hasLength(1));
      expect(await tokensOf(plain), isEmpty);
    });

    test('an item that always fails does not stop the others', () async {
      // An id that is no UUIDv7 (e.g. arriving later through sync): its
      // capture time cannot be read.
      await db()
          .into(db().items)
          .insert(
            ItemsCompanion.insert(
              id: 'not-a-uuid',
              hlc: '000000000000000-0000-test',
              rawText: '@Kapot',
              status: ItemStatus.inbox,
              source: ItemSource.app,
            ),
          );
      final good = await capture('@Jan');

      await processor.processOutdated();

      expect(await tokensOf(good), hasLength(1));
      expect([for (final p in await people()) p.name], ['Jan']);
    });

    test('skips items already at the current parser version', () async {
      final id = await capture('@Jan');
      await processor.process(id);
      final before = (await tokensOf(id)).single.id;

      await processor.processOutdated();

      expect((await tokensOf(id)).single.id, before);
    });

    test('processes items with tokens of an older parser version', () async {
      final id = await capture('@Jan');
      await db()
          .into(db().tokens)
          .insert(
            TokensCompanion.insert(
              id: UuidV7Generator().next(),
              itemId: id,
              tokenType: 'person',
              rawValue: 'Jan',
              parserVersion: tokenParserVersion - 1,
            ),
          );

      await processor.processOutdated();

      final tokens = await tokensOf(id);
      expect(tokens.single.parserVersion, tokenParserVersion);
      expect(tokens.single.resolvedValue, (await people()).single.id);
    });
  });

  group('priority (T10.5, REQ-050)', () {
    Future<ItemPriority?> priorityAfter(String text) async {
      final id = await capture(text);
      await processor.process(id);
      return (await item(id)).priority;
    }

    test('words and digits set it; normal is stored too', () async {
      expect(await priorityAfter('Offerte *hoog'), ItemPriority.high);
      expect(await priorityAfter('Offerte *1'), ItemPriority.high);
      expect(await priorityAfter('Offerte *LAAG'), ItemPriority.low);
      expect(await priorityAfter('Offerte *3'), ItemPriority.low);
      expect(await priorityAfter('Offerte *2'), ItemPriority.normal);
      expect(await priorityAfter('Offerte'), isNull);
    });

    test('the first priority counts and the token is stored', () async {
      final id = await capture('Offerte *laag *hoog');
      await processor.process(id);
      expect((await item(id)).priority, ItemPriority.low);
      expect(
        [for (final t in await tokensOf(id)) t.resolvedValue],
        ['low', 'high'],
      );
    });

    test('Markdown stays text (DD-004 point 3)', () async {
      for (final text in [
        '* boodschappen',
        'dit is *nadruk*',
        'dit is **vet**',
        'a*hoog',
        r'\*hoog',
        '*hoogst',
      ]) {
        final id = await capture(text);
        await processor.process(id);
        expect((await item(id)).priority, isNull, reason: text);
        expect(await tokensOf(id), isEmpty, reason: text);
      }
    });

    test('follows the text: removing it clears the priority', () async {
      final id = await capture('Offerte *hoog');
      await processor.process(id);
      await items.editText(id, 'Offerte');
      await processor.process(id);
      expect((await item(id)).priority, isNull);
    });
  });

  group('project (T10.5, REQ-050, DD-004 point 11)', () {
    late DriftProjectRepository projects;
    setUp(() => projects = DriftProjectRepository(storage));

    Future<String?> projectOf(String id) async => (await item(id)).contextId;

    /// The HLC has millisecond time: changes in a test must not share one.
    Future<void> later() =>
        Future<void>.delayed(const Duration(milliseconds: 5));

    test('a captured token sets the project and is stored', () async {
      final renovation = await projects.create('Renovatie');
      final id = await capture('Kozijnen bestellen ^renovatie');
      await processor.process(id);
      expect(await projectOf(id), renovation);
      final token = (await tokensOf(id)).single;
      expect(token.tokenType, 'project');
      expect(token.resolvedValue, renovation);
    });

    test('spaces, case, - and _ do not matter', () async {
      final shed = await projects.create('Oude schuur');
      for (final word in ['oudeschuur', 'Oude-schuur', 'OUDE_SCHUUR']) {
        final id = await capture('Dak ^$word');
        await processor.process(id);
        expect(await projectOf(id), shed, reason: word);
      }
    });

    test('an unknown name sets nothing and creates nothing', () async {
      final id = await capture('Dak ^onbekend');
      await processor.process(id);
      expect(await projectOf(id), isNull);
      expect(await db().select(db().contexts).get(), isEmpty);
      expect((await tokensOf(id)).single.resolvedValue, isNull);
    });

    test('Cyrillic names match without regard to case', () async {
      final dacha = await projects.create('Дача');
      final id = await capture('Паркан ^дача');
      await processor.process(id);
      expect(await projectOf(id), dacha);
    });

    test('a sub-project by path; the top-level one wins its name', () async {
      final renovation = await projects.create('Renovatie');
      final kitchenSub = await projects.create('Keuken', parentId: renovation);
      final kitchenTop = await projects.create('Keuken');
      final viaPath = await capture('Tegels ^renovatie/keuken');
      final byName = await capture('Tegels ^keuken');
      await processor.process(viaPath);
      await processor.process(byName);
      expect(await projectOf(viaPath), kitchenSub);
      expect(await projectOf(byName), kitchenTop);
    });

    test('an archived project never matches', () async {
      final oldProject = await projects.create('Oud');
      await projects.archive(oldProject);
      final id = await capture('Iets ^oud');
      await processor.process(id);
      expect(await projectOf(id), isNull);
    });

    test('the change goes through the change log (REQ-008)', () async {
      final renovation = await projects.create('Renovatie');
      final id = await capture('Kozijnen ^renovatie');
      await processor.process(id);
      final entries = await (db().select(
        db().changeLog,
      )..where((e) => e.entityId.equals(id))).get();
      expect(entries.any((e) => e.payload.contains(renovation)), isTrue);
    });

    test('a later choice in the picker wins over the token', () async {
      final renovation = await projects.create('Renovatie');
      final garden = await projects.create('Tuin');
      final id = await capture('Kozijnen ^renovatie');
      await processor.process(id);
      await later();
      await items.setProject(id, garden);
      await later();
      // An edit that keeps the token does not take the project back.
      await items.editText(id, 'Kozijnen bestellen ^renovatie');
      await processor.process(id);
      expect(await projectOf(id), garden);
      expect(renovation, isNot(garden));
    });

    test('a token typed after the choice acts as a new choice', () async {
      final renovation = await projects.create('Renovatie');
      final garden = await projects.create('Tuin');
      final id = await capture('Kozijnen');
      await items.setProject(id, garden);
      await later();
      await items.editText(id, 'Kozijnen ^renovatie');
      await processor.process(id);
      expect(await projectOf(id), renovation);
    });

    test('an older token does not block a newly typed one', () async {
      await projects.create('Renovatie');
      final garden = await projects.create('Tuin');
      final shed = await projects.create('Schuur');
      final id = await capture('Kozijnen ^renovatie');
      await processor.process(id);
      await later();
      await items.setProject(id, garden);
      await later();
      await items.editText(id, 'Kozijnen ^renovatie ^schuur');
      await processor.process(id);
      expect(await projectOf(id), shed);
      expect(garden, isNot(shed));
    });

    test('removing the token keeps the project', () async {
      final renovation = await projects.create('Renovatie');
      final id = await capture('Kozijnen ^renovatie');
      await processor.process(id);
      await later();
      await items.editText(id, 'Kozijnen');
      await processor.process(id);
      expect(await projectOf(id), renovation);
    });

    test('an older item keeps a project chosen after its capture', () async {
      final renovation = await projects.create('Renovatie');
      final garden = await projects.create('Tuin');
      // Captured before `^` was a token, then put in a project by hand.
      final id = await captureAt(
        DateTime.now().subtract(const Duration(days: 3)),
        'Kozijnen ^renovatie',
      );
      final plain = await captureAt(
        DateTime.now().subtract(const Duration(days: 3)),
        'Hekwerk ^renovatie',
      );
      await items.setProject(id, garden);
      await processor.processOutdated();
      expect(await projectOf(id), garden);
      // Without a choice the token sets it.
      expect(await projectOf(plain), renovation);
    });

    group('a project that comes later is linked at the next start', () {
      test('when it is created', () async {
        final id = await capture('Zaaien ^kas');
        await processor.process(id);
        final greenhouse = await projects.create('Kas');
        await processor.processOutdated();
        expect(await projectOf(id), greenhouse);
        expect((await tokensOf(id)).single.resolvedValue, greenhouse);
      });

      test('a Cyrillic name with spaces', () async {
        final id = await capture('Плитка ^нова-кухня');
        await processor.process(id);
        final kitchen = await projects.create('Нова кухня');
        await processor.processOutdated();
        expect(await projectOf(id), kitchen);
      });

      test('when it comes back from the archive', () async {
        final oldProject = await projects.create('Oud');
        await projects.archive(oldProject);
        final id = await capture('Iets ^oud');
        await processor.process(id);
        await projects.restoreFromArchive(oldProject);
        await processor.processOutdated();
        expect(await projectOf(id), oldProject);
      });

      test('not when a project was chosen after the token', () async {
        final garden = await projects.create('Tuin');
        final id = await capture('Zaaien ^kas');
        await processor.process(id);
        await later();
        await items.setProject(id, garden);
        await projects.create('Kas');
        await processor.processOutdated();
        expect(await projectOf(id), garden);
      });

      test('a name that still names nothing writes nothing', () async {
        final id = await capture('Zaaien ^kas');
        await processor.process(id);
        final before = await db().select(db().changeLog).get();
        await processor.processOutdated();
        expect(
          await db().select(db().changeLog).get(),
          hasLength(before.length),
        );
        expect((await tokensOf(id)).single.resolvedValue, isNull);
      });
    });
  });
}
