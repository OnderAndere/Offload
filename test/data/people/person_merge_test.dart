import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/database/app_database.dart';
import 'package:offload/data/items/drift_item_repository.dart';
import 'package:offload/data/people/drift_people_repository.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/data/tokens/drift_token_processor.dart';
import 'package:offload/domain/items/item_classification.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/domain/people/contact_detail.dart';
import 'package:offload/domain/people/person.dart';
import 'package:offload/domain/sync/change_operation.dart';
import 'package:offload/domain/tokens/inline_token.dart';
import 'package:offload/domain/tokens/inline_token_registry.dart';

import '../../fakes/test_storage.dart';

/// Merging people on the database (T3.2b, DD-015).
void main() {
  late AppStorage storage;
  late DriftItemRepository items;
  late DriftPeopleRepository people;

  setUp(() async {
    storage = await openTestStorage();
    items = DriftItemRepository(storage);
    people = DriftPeopleRepository(storage);
  });
  tearDown(() => storage.close());

  AppDatabase db() => storage.database;

  Future<String> capture(String text) async {
    final id = await items.capture(text, source: ItemSource.app);
    await DriftTokenProcessor(
      storage,
      registry: InlineTokenRegistry.standard(),
      dates: () => DateVocabulary.empty,
    ).process(id);
    return id;
  }

  Future<void> classify(String id, {String? requester, String? waitingOn}) =>
      items.classify(
        id,
        ItemClassification(
          type: ItemType.task,
          status: waitingOn != null ? ItemStatus.waiting : ItemStatus.active,
          requesterId: requester,
          waitingOnId: waitingOn,
        ),
      );

  Future<Item> item(String id) =>
      (db().select(db().items)..where((i) => i.id.equals(id))).getSingle();

  Future<PeopleData> person(String id) =>
      (db().select(db().people)..where((p) => p.id.equals(id))).getSingle();

  Future<List<String>> aliasesOf(String id) async => [
    for (final a in await (db().select(
      db().personAliases,
    )..where((a) => a.personId.equals(id) & a.deletedAt.isNull())).get())
      a.alias,
  ]..sort();

  Future<List<String?>> tokenPeople(String itemId) async => [
    for (final t in await (db().select(
      db().tokens,
    )..where((t) => t.itemId.equals(itemId))).get())
      t.resolvedValue,
  ];

  Matcher refused(PersonProblem problem) => throwsA(
    isA<PersonException>().having((e) => e.problem, 'problem', problem),
  );

  test('everything of the one goes to the other, in the change log', () async {
    final janB = await people.idFor('Jan B');
    final jan = await people.idFor('Jan Bakker');
    await people.rename(janB, 'Jantje'); // "Jan B" becomes an alias
    final asked = await capture('offerte');
    await classify(asked, requester: janB);
    final waits = await capture('rapport');
    await classify(waits, waitingOn: janB);
    final named = await capture('cadeau @Jantje');
    final logBefore = (await db().select(db().changeLog).get()).length;

    final merge = await people.merge(janB, jan);

    expect((await item(asked)).requesterId, jan);
    expect((await item(waits)).waitingOnId, jan);
    expect(await tokenPeople(named), [jan]);
    expect(await aliasesOf(jan), ['Jan B', 'Jantje']);
    final gone = await person(janB);
    expect(gone.deletedAt, isNotNull);
    expect(gone.mergedIntoId, jan);
    expect(await people.idFor('jantje'), jan);
    expect(await people.idFor('Jan B'), jan);
    expect(await people.watchMergedInto().first, {janB: jan});
    expect(merge.requesterItemIds, [asked]);
    expect(merge.waitingItemIds, [waits]);

    final log = (await db().select(db().changeLog).get()).skip(logBefore);
    expect(log.where((e) => e.entityId == janB).map((e) => e.operation), [
      ChangeOperation.update,
      ChangeOperation.delete,
    ]);
  });

  test('an alias the target has already is kept once', () async {
    final a = await people.idFor('Jan');
    final b = await people.idFor('Jan Bakker');
    await people.rename(a, 'Jan B.'); // a: alias "Jan"
    // As if sync gave b the same alias.
    await storage.writer.insert(
      db().personAliases,
      PersonAliasesCompanion(personId: Value(b), alias: const Value('jan')),
    );
    final merge = await people.merge(a, b);
    expect(await aliasesOf(b), ['Jan B.', 'jan']);
    expect(merge.droppedAliasIds, hasLength(1));
  });

  test('profiles are joined; undo puts them back', () async {
    final a = await people.idFor('A');
    final b = await people.idFor('B');
    await (db().update(db().people)..where((p) => p.id.equals(a))).write(
      const PeopleCompanion(
        birthdayDay: Value(3),
        birthdayMonth: Value(4),
        note: Value('Notitie A'),
      ),
    );
    await (db().update(db().people)..where((p) => p.id.equals(b))).write(
      const PeopleCompanion(note: Value('Notitie B')),
    );
    final merge = await people.merge(a, b);
    var target = await person(b);
    expect(target.birthdayDay, 3);
    expect(target.note, 'Notitie B\n\nNotitie A');

    await people.undoMerge(merge);
    target = await person(b);
    expect(target.birthdayDay, isNull);
    expect(target.note, 'Notitie B');
  });

  test('contact details move, the same one once; undo puts all back '
      '(T3.5)', () async {
    final a = await people.idFor('Олена');
    final b = await people.idFor('Олена Коваль');
    final same = await people.addContactDetail(
      a,
      ContactKind.phone,
      '06 1234 5678',
      label: 'work',
    );
    final own = await people.addContactDetail(
      a,
      ContactKind.email,
      'olena@example.org',
      label: 'Робота',
    );
    final kept = await people.addContactDetail(
      b,
      ContactKind.phone,
      '06-12345678',
      label: 'mobile',
    );
    await people.setWork(a, organisation: 'Бібліотека', jobTitle: 'Голова');
    await people.setWork(b, organisation: 'Тенісний клуб', jobTitle: null);

    Future<Map<String, String>> live() async => {
      for (final row in await (db().select(
        db().contactDetails,
      )..where((c) => c.deletedAt.isNull())).get())
        row.id: row.personId,
    };

    final merge = await people.merge(a, b);
    expect(await live(), {own: b, kept: b});
    expect(merge.movedContactIds, [own]);
    expect(merge.droppedContactIds, [same]);
    var target = await person(b);
    expect(target.organisation, 'Тенісний клуб');
    expect(target.jobTitle, 'Голова');

    await people.undoMerge(merge);
    expect(await live(), {same: a, own: a, kept: b});
    target = await person(b);
    expect(target.organisation, 'Тенісний клуб');
    expect(target.jobTitle, isNull);
  });

  test('a deleted detail of a merged person does not come back', () async {
    final a = await people.idFor('A');
    final b = await people.idFor('B');
    final id = await people.addContactDetail(a, ContactKind.email, 'a@b.nl');
    await people.deleteContactDetail(id);
    await people.merge(a, b);
    expect(await people.restoreContactDetail(id), isFalse);
    final row = await (db().select(
      db().contactDetails,
    )..where((c) => c.id.equals(id))).getSingle();
    expect(row.deletedAt, isNotNull);
  });

  test('undo brings the person back with what nothing changed', () async {
    final janB = await people.idFor('Jan B');
    final jan = await people.idFor('Jan Bakker');
    final asked = await capture('offerte');
    await classify(asked, requester: janB);
    final other = await capture('nog een');
    await classify(other, requester: janB);
    final named = await capture('cadeau @Jan');
    await people.rename(janB, 'Jan B.'); // tokens of "Jan B" stay valid
    final mentioned = await capture('bel @Jan');

    final merge = await people.merge(janB, jan);
    // Meanwhile someone chooses another requester for one item.
    final piet = await people.idFor('Piet');
    await items.setRequester(other, piet);

    await people.undoMerge(merge);

    final back = await person(janB);
    expect(back.deletedAt, isNull);
    expect(back.mergedIntoId, isNull);
    expect((await item(asked)).requesterId, janB);
    expect((await item(other)).requesterId, piet);
    expect(await aliasesOf(janB), ['Jan B']);
    expect(await aliasesOf(jan), isEmpty);
    // "@Jan" never was Jan B: it created another person, untouched.
    expect(await tokenPeople(named), await tokenPeople(mentioned));
    expect(await people.watchMergedInto().first, isEmpty);
  });

  test('undo links the tokens of the merged names back', () async {
    final a = await people.idFor('Kees');
    final b = await people.idFor('Cornelis');
    final named = await capture('bel @Kees');
    final merge = await people.merge(a, b);
    expect(await tokenPeople(named), [b]);
    await people.undoMerge(merge);
    expect(await tokenPeople(named), [a]);
  });

  test('refuses merging into oneself or with someone gone', () async {
    final a = await people.idFor('A');
    final b = await people.idFor('B');
    await expectLater(people.merge(a, a), refused(PersonProblem.samePerson));
    await people.merge(a, b);
    await expectLater(people.merge(a, b), refused(PersonProblem.notAvailable));
    await expectLater(people.merge(b, a), refused(PersonProblem.notAvailable));
  });

  test('a late reference to a merged person counts for the target', () async {
    final a = await people.idFor('A');
    final b = await people.idFor('B');
    final c = await people.idFor('C');
    await people.merge(a, b);
    await people.merge(b, c);
    // As if sync brought an item that still points to A.
    final late = await capture('laat');
    await (db().update(db().items)..where((i) => i.id.equals(late))).write(
      ItemsCompanion(
        requesterId: Value(a),
        status: const Value(ItemStatus.active),
      ),
    );

    final result = await items.watchPersonItems(c).first;
    expect(result.items.single.id, late);
    expect(result.items.single.requesterId, c);
  });

  test('a name two people share after sync goes to the oldest', () async {
    final older = await people.idFor('Jan Bakker');
    final newer = await people.idFor('Jan de Vries');
    for (final id in [newer, older]) {
      await storage.writer.insert(
        db().personAliases,
        PersonAliasesCompanion(personId: Value(id), alias: const Value('JB')),
      );
    }
    expect(await people.find('jb'), older);
    expect(await people.idFor('JB'), older);
  });
}
