import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/database/app_database.dart';
import 'package:offload/data/items/drift_item_repository.dart';
import 'package:offload/data/people/drift_people_repository.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/data/tokens/drift_token_processor.dart';
import 'package:offload/domain/items/item_classification.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/domain/people/person.dart';
import 'package:offload/domain/tokens/inline_token.dart';
import 'package:offload/domain/tokens/inline_token_registry.dart';

import '../../fakes/test_storage.dart';

/// The items of a person and the people of an item (DD-018 point 7).
void main() {
  late AppStorage storage;
  late DriftItemRepository items;
  late DriftPeopleRepository people;
  late DriftTokenProcessor tokens;

  setUp(() async {
    storage = await openTestStorage();
    items = DriftItemRepository(storage);
    people = DriftPeopleRepository(storage);
    tokens = DriftTokenProcessor(
      storage,
      registry: InlineTokenRegistry.standard(),
      dates: () => DateVocabulary.empty,
    );
  });
  tearDown(() => storage.close());

  AppDatabase db() => storage.database;

  Future<String> capture(String text) async {
    final id = await items.capture(text, source: ItemSource.app);
    await tokens.process(id);
    return id;
  }

  Future<Item> row(String id) =>
      (db().select(db().items)..where((i) => i.id.equals(id))).getSingle();

  Matcher refused(PersonProblem problem) => throwsA(
    isA<PersonException>().having((e) => e.problem, 'problem', problem),
  );

  group('watchPersonItems', () {
    test('requester, waited on and named in the text, newest first', () async {
      final jan = await people.idFor('Jan');
      final asked = await capture('offerte nakijken');
      await items.classify(
        asked,
        ItemClassification(
          type: ItemType.request,
          status: ItemStatus.active,
          requesterId: jan,
          waitingOnId: null,
        ),
      );
      final waits = await capture('menukaart');
      await items.waitFor(waits, jan);
      final named = await capture('cadeau voor @jan');
      await capture('iets anders @Petra');

      final result = await items.watchPersonItems(jan).first;
      expect(result.items.map((i) => i.id), [named, waits, asked]);
      expect(result.mentionedIds, {named});
    });

    test('an alias in the text counts; the trash does not', () async {
      final jan = await people.idFor('Jan');
      await people.rename(jan, 'Jan Bakker'); // "Jan" becomes an alias
      final named = await capture('bel @Jan');
      final trashed = await capture('weg @jan');
      await items.moveToTrash(trashed);

      final result = await items.watchPersonItems(jan).first;
      expect(result.items.map((i) => i.id), [named]);
      expect(result.mentionedIds, {named});
    });

    test('emits again when the tokens change', () async {
      final jan = await people.idFor('Jan');
      final id = await capture('nog niemand');
      final stream = items.watchPersonItems(jan);
      final seen = <Set<String>>[];
      final sub = stream.listen((r) => seen.add(r.mentionedIds));
      await pumpEventQueue();
      await items.editText(id, 'nu wel @Jan');
      await tokens.process(id);
      await pumpEventQueue();
      await sub.cancel();
      expect(seen.first, isEmpty);
      expect(seen.last, {id});
    });
  });

  group('the people of an item', () {
    test('setRequester and setWaitingOn set and clear', () async {
      final jan = await people.idFor('Jan');
      final id = await capture('x');
      await items.setRequester(id, jan);
      await items.setWaitingOn(id, jan);
      expect((await row(id)).requesterId, jan);
      expect((await row(id)).waitingOnId, jan);
      expect((await row(id)).status, ItemStatus.inbox);
      await items.setRequester(id, null);
      await items.setWaitingOn(id, null);
      expect((await row(id)).requesterId, isNull);
      expect((await row(id)).waitingOnId, isNull);
    });

    test('refuses a person that does not exist or is deleted', () async {
      final id = await capture('x');
      final gone = await people.idFor('Weg');
      await storage.writer.delete(db().people, gone);
      await expectLater(
        items.setRequester(id, 'nobody'),
        refused(PersonProblem.notAvailable),
      );
      await expectLater(
        items.setWaitingOn(id, gone),
        refused(PersonProblem.notAvailable),
      );
      await expectLater(
        items.waitFor(id, gone),
        refused(PersonProblem.notAvailable),
      );
      expect((await row(id)).status, ItemStatus.inbox);
    });

    test('waitFor sets status and person in one change', () async {
      final petra = await people.idFor('Petra');
      final id = await capture('x');
      final before = await db().select(db().changeLog).get();
      await items.waitFor(id, petra);
      final after = await db().select(db().changeLog).get();
      expect(after.length - before.length, 1);
      final item = await row(id);
      expect(item.status, ItemStatus.waiting);
      expect(item.waitingOnId, petra);
    });

    test('waitFor without a person keeps the one it had', () async {
      final petra = await people.idFor('Petra');
      final id = await capture('x');
      await items.setWaitingOn(id, petra);
      await items.waitFor(id, null);
      expect((await row(id)).status, ItemStatus.waiting);
      expect((await row(id)).waitingOnId, petra);
    });

    test('waitFor on a waiting item replaces the person', () async {
      final petra = await people.idFor('Petra');
      final jan = await people.idFor('Jan');
      final id = await capture('x');
      await items.waitFor(id, petra);
      await items.waitFor(id, jan);
      expect((await row(id)).waitingOnId, jan);
    });

    test('waitFor follows the status machine', () async {
      final id = await capture('x');
      await items.moveTo(id, ItemStatus.done);
      await expectLater(items.waitFor(id, null), throwsStateError);
    });
  });
}
