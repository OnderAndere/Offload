import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/database/app_database.dart';
import 'package:offload/data/people/drift_people_repository.dart';
import 'package:offload/data/search/drift_search_index.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/domain/people/calling_country.dart';
import 'package:offload/domain/people/contact_detail.dart';
import 'package:offload/domain/people/person.dart';
import 'package:offload/domain/sync/change_operation.dart';

import '../../fakes/test_storage.dart';

/// Contact details, organisation and job title of a person on the database
/// (T3.5, REQ-038, DD-012, AC REQ-011, AC REQ-005).
void main() {
  late AppStorage storage;
  late DriftPeopleRepository people;

  setUp(() async {
    storage = await openTestStorage();
    people = DriftPeopleRepository(storage);
  });
  tearDown(() => storage.close());

  AppDatabase db() => storage.database;

  /// The live details, read once (never a watched stream's `.first` in a
  /// test that keeps the database open).
  Future<List<ContactDetail>> details(
    String personId,
  ) async => sortContactDetails([
    for (final row in await (db().select(
      db().contactDetails,
    )..where((c) => c.personId.equals(personId) & c.deletedAt.isNull())).get())
      ContactDetail(
        id: row.id,
        personId: row.personId,
        kind: row.kind,
        value: row.value,
        label: row.label,
        sortOrder: row.sortOrder,
      ),
  ]);

  Future<List<ChangeLogData>> logFor(String id) =>
      (db().select(db().changeLog)..where((c) => c.entityId.equals(id))).get();

  test('details are added after the others of their kind, as typed', () async {
    final jan = await people.idFor('Jan');
    final mobile = await people.addContactDetail(
      jan,
      ContactKind.phone,
      '  06-12 34 56 78 ',
      label: 'mobile',
    );
    await people.addContactDetail(jan, ContactKind.email, 'jan@example.org');
    await people.addContactDetail(
      jan,
      ContactKind.phone,
      '+31 20 123 4567',
      label: ' Thuis ',
    );

    final list = await details(jan);
    expect(
      [for (final d in list) d.value],
      ['06-12 34 56 78', '+31 20 123 4567', 'jan@example.org'],
    );
    expect([for (final d in list) d.label], ['mobile', 'Thuis', null]);
    expect([for (final d in list) d.sortOrder], [0, 1, 0]);

    final log = await logFor(mobile);
    expect(log.single.operation, ChangeOperation.insert);
    expect(log.single.entity, 'contact_details');
  });

  test('a value that does not fit its kind is refused', () async {
    final jan = await people.idFor('Jan');
    await expectLater(
      people.addContactDetail(jan, ContactKind.phone, 'morgen bellen'),
      throwsA(
        isA<ContactException>().having(
          (e) => e.problem,
          'problem',
          ContactProblem.invalid,
        ),
      ),
    );
    await expectLater(
      people.addContactDetail(jan, ContactKind.email, ' '),
      throwsA(isA<ContactException>()),
    );
    await expectLater(
      people.addContactDetail('nobody', ContactKind.email, 'a@example.org'),
      throwsA(isA<PersonException>()),
    );
    expect(await details(jan), isEmpty);
  });

  test('change, delete and restore go through the change log', () async {
    final jan = await people.idFor('Jan');
    final id = await people.addContactDetail(
      jan,
      ContactKind.email,
      'jan@example.org',
    );
    await people.updateContactDetail(id, 'j.jansen@example.org', label: 'work');
    expect((await details(jan)).single.value, 'j.jansen@example.org');
    expect((await details(jan)).single.label, 'work');
    await expectLater(
      people.updateContactDetail(id, 'geen adres'),
      throwsA(isA<ContactException>()),
    );

    await people.deleteContactDetail(id);
    expect(await details(jan), isEmpty);
    expect(await people.restoreContactDetail(id), isTrue);
    expect((await details(jan)).single.id, id);
    // Not deleted: nothing to bring back.
    expect(await people.restoreContactDetail(id), isFalse);

    expect(
      [for (final e in await logFor(id)) e.operation],
      [
        ChangeOperation.insert,
        ChangeOperation.update,
        ChangeOperation.delete,
        ChangeOperation.restore,
      ],
    );
  });

  test('organisation and job title; empty removes them', () async {
    final jan = await people.idFor('Jan');
    await people.setWork(
      jan,
      organisation: ' Tennisclub ',
      jobTitle: 'Voorzitter',
    );
    var row = await (db().select(
      db().people,
    )..where((p) => p.id.equals(jan))).getSingle();
    expect(row.organisation, 'Tennisclub');
    expect(row.jobTitle, 'Voorzitter');

    await people.setWork(jan, organisation: 'Tennisclub', jobTitle: '  ');
    row = await (db().select(
      db().people,
    )..where((p) => p.id.equals(jan))).getSingle();
    expect(row.jobTitle, isNull);
    await expectLater(
      people.setWork('nobody', organisation: 'X', jobTitle: null),
      throwsA(isA<PersonException>()),
    );
  });

  test('search finds a person by number, digits, address, organisation, '
      'job title and own label, in Cyrillic too', () async {
    final olena = await people.idFor('Олена');
    await people.addContactDetail(
      olena,
      ContactKind.phone,
      '06-12 34 56 78',
      label: 'Робота',
    );
    await people.addContactDetail(
      olena,
      ContactKind.email,
      'olena@example.org',
      label: 'work',
    );
    await people.setWork(
      olena,
      organisation: 'Бібліотека',
      jobTitle: 'Бібліотекарка',
    );
    final index = DriftSearchIndex(db());
    await index.processPending();

    for (final query in [
      '0612',
      '06-12',
      'olena@example',
      'бібліотека',
      'бібліотекарка',
      'робота',
    ]) {
      expect(
        [for (final hit in await index.search(query)) hit.id],
        [olena],
        reason: query,
      );
    }
    // A standard label is shown translated, so its stored name is not
    // searched.
    expect(await index.search('work'), isEmpty);

    // A deleted detail is no longer found.
    final phone = (await details(olena)).first.id;
    await people.deleteContactDetail(phone);
    await index.processPending();
    expect(await index.search('0612'), isEmpty);
  });

  test('watching gives the live details in order', () async {
    final jan = await people.idFor('Jan');
    await people.addContactDetail(jan, ContactKind.email, 'a@example.org');
    await people.addContactDetail(jan, ContactKind.phone, '0201234567');
    final watched = await people.watchContactDetails(jan).first;
    expect(
      [for (final d in watched) d.kind],
      [ContactKind.phone, ContactKind.email],
    );
  });

  group('taken from the text (T3.6, REQ-039)', () {
    test('adds the new ones with their label; skips what is there', () async {
      final jan = await people.idFor('Jan');
      await people.addContactDetail(jan, ContactKind.phone, '+31 6 1234 5678');

      final added = await people.addContactsFromText(jan, [
        (kind: ContactKind.phone, value: '06-12345678', label: 'mobile'),
        (kind: ContactKind.phone, value: '020-1234567', label: null),
        (kind: ContactKind.email, value: 'jan@example.org', label: null),
        (kind: ContactKind.email, value: 'JAN@example.org', label: null),
      ]);

      expect(added, hasLength(2));
      expect(
        [for (final d in await details(jan)) (d.value, d.label)],
        [
          ('+31 6 1234 5678', null),
          ('020-1234567', null),
          ('jan@example.org', null),
        ],
      );
    });

    test('the home country of this device decides', () async {
      await storage.savePhoneCountry(callingCountryOf('BE'));
      final jan = await people.idFor('Jan');
      await people.addContactDetail(jan, ContactKind.phone, '+32 471 12 34 56');

      final added = await people.addContactsFromText(jan, [
        (kind: ContactKind.phone, value: '0471 12 34 56', label: null),
      ]);

      expect(added, isEmpty);
    });

    test(
      'the index finds a national number by its international form',
      () async {
        final jan = await people.idFor('Jan');
        await people.addContactDetail(jan, ContactKind.phone, '06-12345678');
        final index = DriftSearchIndex(
          db(),
          phoneCountry: () => storage.phoneCountry,
        );
        await index.processPending();

        expect((await index.search('+31612')).single.id, jan);
      },
    );
  });
}
