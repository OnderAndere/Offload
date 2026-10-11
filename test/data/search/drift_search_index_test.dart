import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/database/app_database.dart' hide SearchIndex;
import 'package:offload/data/items/drift_item_repository.dart';
import 'package:offload/data/search/drift_search_index.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/domain/search/search_index.dart';

import '../../fakes/test_storage.dart';

/// The FTS5 index (REQ-011, DD-016; T2.5 step A).
void main() {
  late AppStorage storage;
  late DriftSearchIndex index;

  setUp(() async {
    storage = await openTestStorage();
    index = DriftSearchIndex(storage.database);
  });
  tearDown(() => storage.close());

  AppDatabase db() => storage.database;

  Future<String> capture(String text) =>
      DriftItemRepository(storage).capture(text, source: ItemSource.app);

  Future<String> person(String name, {String? note}) => storage.writer.insert(
    db().people,
    PeopleCompanion(name: Value(name), note: Value(note)),
  );

  Future<List<String>> found(String query) async => [
    for (final hit in await index.search(query)) hit.id,
  ];

  Future<int> queued() async =>
      (await db().customSelect('SELECT * FROM search_pending').get()).length;

  test('indexed after saving, not during', () async {
    final id = await capture('Keuring van de afvoer');

    expect(await found('afvoer'), isEmpty);
    expect(await queued(), 1);

    await index.processPending();

    expect(await found('afvoer'), [id]);
    expect(await queued(), 0);
  });

  test('diacritics do not matter, either way (AC REQ-011)', () async {
    final cafe = await capture('Afspraak in het café');
    final creme = await capture('creme brulee bestellen');
    await index.processPending();

    expect(await found('cafe'), [cafe]);
    expect(await found('CAFÉ'), [cafe]);
    expect(await found('crème brûlée'), [creme]);
  });

  test('a word also finds longer words it starts (AC REQ-011)', () async {
    final id = await capture('Keuring meubelplan');
    await index.processPending();

    expect(await found('keur'), [id]);
    expect(await found('meub keur'), [id]);
    expect(await found('uring'), isEmpty);
  });

  test('all words must match', () async {
    final both = await capture('offerte renovatie');
    await capture('offerte afvoer');
    await index.processPending();

    expect(await found('renovatie offerte'), [both]);
  });

  test('a hit in the title ranks above one in the text (AC REQ-011)', () async {
    final inText = await capture('Iets over de renovatie en meer');
    final inTitle = await capture('Notitie');
    await storage.writer.update(
      db().items,
      inTitle,
      const ItemsCompanion(title: Value('Renovatie')),
    );
    await index.processPending();

    expect(await found('renovatie'), [inTitle, inText]);
  });

  test('tokens are found by their word', () async {
    final id = await capture('Meten #renovatie met @Jan');
    await index.processPending();

    expect(await found('renovatie'), [id]);
    expect(await found('#renovatie'), [id]);
    expect(await found('jan'), [id]);
  });

  test('an item in the trash is not found, also before indexing', () async {
    final id = await capture('weggooien');
    await index.processPending();
    await storage.writer.delete(db().items, id);

    expect(await found('weggooien'), isEmpty);
    await index.processPending();
    expect(await db().customSelect('SELECT * FROM search_map').get(), isEmpty);
  });

  test('people by name, alias and note (PO decision 27-09-2026)', () async {
    final jan = await person('Jan de Vries', note: 'Werkt aan de renovatie');
    await storage.writer.insert(
      db().personAliases,
      PersonAliasesCompanion(personId: Value(jan), alias: const Value('JD')),
    );
    await index.processPending();

    final hits = await index.search('vries');
    expect(hits.single.entity, SearchEntity.person);
    expect(await found('jd'), [jan]);
    expect(await found('renovatie'), [jan]);
  });

  test('hits carry what to show (T2.5 step B)', () async {
    final item = await capture('Keuring van de afvoer');
    final jan = await person('Jan', note: 'Moestuin');
    final noNote = await person('Janneke');
    await index.processPending();

    final itemHit = (await index.search('keur')).single;
    expect(
      (itemHit.id, itemHit.title, itemHit.text),
      (item, null, 'Keuring van de afvoer'),
    );
    final people = {for (final h in await index.search('jan')) h.id: h};
    expect((people[jan]!.title, people[jan]!.text), ('Jan', 'Moestuin'));
    expect((people[noNote]!.title, people[noNote]!.text), ('Janneke', ''));
  });

  test('Cyrillic names ignore case', () async {
    final id = await person('Олена');
    await index.processPending();

    expect(await found('олена'), [id]);
  });

  test('a change to an unrelated column queues nothing', () async {
    final id = await capture('deadline volgt');
    await index.processPending();

    await storage.writer.update(
      db().items,
      id,
      ItemsCompanion(dueAt: Value(DateTime.utc(2026, 10, 2))),
    );

    expect(await queued(), 0);
  });

  test('changed text replaces the old text in the index', () async {
    final id = await capture('eerste versie');
    await index.processPending();
    await storage.writer.update(
      db().items,
      id,
      const ItemsCompanion(rawText: Value('tweede versie')),
    );
    await index.processPending();

    expect(await found('eerste'), isEmpty);
    expect(await found('tweede'), [id]);
  });

  test('a queue larger than one batch is fully indexed', () async {
    await db().transaction(() async {
      for (var i = 0; i < 450; i++) {
        await capture('Markt nummer $i');
      }
    });
    expect(await queued(), 450);

    await index.processPending();

    expect(await queued(), 0);
    expect(await index.search('markt', limit: 1000), hasLength(450));
  });

  test('an entry of an unknown source leaves the queue', () async {
    await db().customStatement(
      "INSERT INTO search_pending (entity, entity_id) VALUES ('other', 'x')",
    );

    await index.processPending();

    expect(await queued(), 0);
  });

  test('input with search syntax never fails', () async {
    await capture('gewoon tekst');
    await index.processPending();

    for (final query in ['"', 'AND', 'NEAR(', '-', '*', 'a OR', ':']) {
      expect(await index.search(query), isA<List<SearchHit>>());
    }
  });

  test('rebuilding gives the same results', () async {
    final id = await capture('opnieuw opbouwen');
    await person('Piet');
    await index.processPending();

    await index.rebuild();

    expect(await found('opbouw'), [id]);
    expect(await found('piet'), hasLength(1));
    expect(await queued(), 0);
  });

  test('keeps up with saved changes by itself', () async {
    final subscription = index.keepUpToDate();
    addTearDown(subscription.cancel);

    final id = await capture('vanzelf gevonden');

    for (var i = 0; i < 100 && (await found('vanzelf')).isEmpty; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(await found('vanzelf'), [id]);
  });
}
