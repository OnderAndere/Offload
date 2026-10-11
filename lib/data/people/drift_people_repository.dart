import 'package:drift/drift.dart';

import '../../domain/people/birthday.dart';
import '../../domain/people/contact_detail.dart';
import '../../domain/people/contacts_from_text.dart';
import '../../domain/people/people_repository.dart';
import '../../domain/people/person.dart';
import '../../domain/people/person_merge.dart';
import '../../domain/tokens/token_processing.dart';
import '../../domain/tokens/token_types.dart';
import '../database/app_database.dart';
import '../storage/app_storage.dart';

/// [PeopleRepository] on the encrypted database; every change goes through
/// the change log like every entity (DD-003).
class DriftPeopleRepository implements PeopleRepository {
  DriftPeopleRepository(this._storage);

  final AppStorage _storage;

  AppDatabase get _db => _storage.database;

  /// Looking and creating happen in one transaction: transactions on the
  /// database run one after the other, so the token processor and triage
  /// can never both create the same new name (DD-015).
  @override
  Future<String> idFor(String name) => _db.transaction(() async {
    final found = (await _stored()).holderOf(name);
    if (found != null) return found;
    return _storage.writer.insert(
      _db.people,
      PeopleCompanion(name: Value(name.trim())),
    );
  });

  @override
  Future<String?> find(String name) async => (await _stored()).holderOf(name);

  @override
  Stream<List<Person>> watchPeople() {
    final people = _db.select(_db.people)..where((p) => p.deletedAt.isNull());
    // One query that reads both tables, so a new alias emits too.
    final query = people.join([
      leftOuterJoin(
        _db.personAliases,
        _db.personAliases.personId.equalsExp(_db.people.id) &
            _db.personAliases.deletedAt.isNull(),
      ),
    ]);
    return query.watch().map((rows) {
      final people = <String, PeopleData>{};
      final aliasesOf = <String, List<String>>{};
      for (final row in rows) {
        final person = row.readTable(_db.people);
        people[person.id] = person;
        final list = aliasesOf.putIfAbsent(person.id, () => []);
        if (row.readTableOrNull(_db.personAliases) case final alias?) {
          list.add(alias.alias);
        }
      }
      return [
        for (final p in people.values)
          Person(
            id: p.id,
            name: p.name,
            aliases: aliasesOf[p.id]!
              ..sort((a, b) => nameKey(a).compareTo(nameKey(b))),
            birthday: p.birthdayDay == null || p.birthdayMonth == null
                ? null
                : Birthday.tryCreate(
                    p.birthdayDay!,
                    p.birthdayMonth!,
                    p.birthdayYear,
                  ),
            note: p.note,
            organisation: p.organisation,
            jobTitle: p.jobTitle,
          ),
      ]..sort((a, b) {
        final byName = nameKey(a.name).compareTo(nameKey(b.name));
        return byName != 0 ? byName : a.id.compareTo(b.id);
      });
    });
  }

  @override
  Future<void> rename(String id, String name) => _db.transaction(() async {
    final stored = await _stored();
    final person = stored.people[id];
    if (person == null) {
      throw const PersonException(PersonProblem.notAvailable);
    }
    final newName = name.trim();
    final key = nameKey(newName);
    if (key.isEmpty) throw const PersonException(PersonProblem.emptyName);
    final holder = stored.holderOf(newName);
    if (holder != null && holder != id) {
      throw const PersonException(PersonProblem.nameTaken);
    }
    if (newName == person.name) return;

    final oldKey = nameKey(person.name);
    final own = stored.aliasesOf(id);
    if (key != oldKey) {
      // The new name stops being an alias (the swap)…
      for (final alias in own) {
        if (nameKey(alias.alias) == key) {
          await _storage.writer.delete(_db.personAliases, alias.id);
        }
      }
      // …and the old name becomes one, once.
      if (!own.any((a) => nameKey(a.alias) == oldKey)) {
        await _storage.writer.insert(
          _db.personAliases,
          PersonAliasesCompanion(
            personId: Value(id),
            alias: Value(person.name),
          ),
        );
      }
    }
    await _storage.writer.update(
      _db.people,
      id,
      PeopleCompanion(name: Value(newName)),
    );
  });

  @override
  Future<void> setBirthday(String id, Birthday? birthday) =>
      _db.transaction(() async {
        await _livePerson(id);
        await _storage.writer.update(
          _db.people,
          id,
          PeopleCompanion(
            birthdayDay: Value(birthday?.day),
            birthdayMonth: Value(birthday?.month),
            birthdayYear: Value(birthday?.year),
          ),
        );
      });

  @override
  Future<void> setNote(String id, String note) => _db.transaction(() async {
    await _livePerson(id);
    await _storage.writer.update(
      _db.people,
      id,
      PeopleCompanion(note: Value(note.trim().isEmpty ? null : note)),
    );
  });

  @override
  Future<void> setWork(
    String id, {
    required String? organisation,
    required String? jobTitle,
  }) => _db.transaction(() async {
    await _livePerson(id);
    String? kept(String? text) =>
        text == null || text.trim().isEmpty ? null : text.trim();
    await _storage.writer.update(
      _db.people,
      id,
      PeopleCompanion(
        organisation: Value(kept(organisation)),
        jobTitle: Value(kept(jobTitle)),
      ),
    );
  });

  @override
  Stream<List<ContactDetail>> watchContactDetails(String personId) {
    final query = _db.select(_db.contactDetails)
      ..where((c) => c.personId.equals(personId) & c.deletedAt.isNull());
    return query.watch().map(
      (rows) => sortContactDetails(rows.map(_contactOf)),
    );
  }

  @override
  Future<String> addContactDetail(
    String personId,
    ContactKind kind,
    String value, {
    String? label,
  }) => _db.transaction(() async {
    _check(kind, value);
    await _livePerson(personId);
    final last =
        await (_db.selectOnly(_db.contactDetails)
              ..addColumns([_db.contactDetails.sortOrder.max()])
              ..where(
                _db.contactDetails.personId.equals(personId) &
                    _db.contactDetails.kind.equalsValue(kind) &
                    _db.contactDetails.deletedAt.isNull(),
              ))
            .map((row) => row.read(_db.contactDetails.sortOrder.max()))
            .getSingle();
    return _storage.writer.insert(
      _db.contactDetails,
      ContactDetailsCompanion(
        personId: Value(personId),
        kind: Value(kind),
        value: Value(value.trim()),
        label: Value(_label(label)),
        sortOrder: Value((last ?? -1) + 1),
      ),
    );
  });

  @override
  Future<List<String>> addContactsFromText(
    String personId,
    List<TextContact> contacts,
  ) => _db.transaction(() async {
    final home = _storage.phoneCountry;
    final keys = {
      for (final d in await _liveContactsOf(personId))
        contactKey(d.kind, d.value, home: home),
    };
    return [
      for (final c in contacts)
        if (keys.add(contactKey(c.kind, c.value, home: home)))
          await addContactDetail(personId, c.kind, c.value, label: c.label),
    ];
  });

  @override
  Future<void> updateContactDetail(String id, String value, {String? label}) =>
      _db.transaction(() async {
        final detail = await _liveContact(id);
        _check(detail.kind, value);
        await _storage.writer.update(
          _db.contactDetails,
          id,
          ContactDetailsCompanion(
            value: Value(value.trim()),
            label: Value(_label(label)),
          ),
        );
      });

  @override
  Future<void> deleteContactDetails(List<String> ids) =>
      _db.transaction(() async {
        for (final id in ids) {
          await deleteContactDetail(id);
        }
      });

  @override
  Future<void> deleteContactDetail(String id) => _db.transaction(() async {
    await _liveContact(id);
    await _storage.writer.delete(_db.contactDetails, id);
  });

  @override
  Future<bool> restoreContactDetail(String id) => _db.transaction(() async {
    final detail = await (_db.select(
      _db.contactDetails,
    )..where((c) => c.id.equals(id))).getSingleOrNull();
    // Only back when its person still is: no detail of a merged person.
    if (detail == null || detail.deletedAt == null) return false;
    final person =
        await (_db.select(_db.people)..where(
              (p) => p.id.equals(detail.personId) & p.deletedAt.isNull(),
            ))
            .getSingleOrNull();
    if (person == null) return false;
    await _storage.writer.restore(_db.contactDetails, id);
    return true;
  });

  static void _check(ContactKind kind, String value) {
    final problem = checkContact(kind, value);
    if (problem != null) throw ContactException(problem);
  }

  static String? _label(String? label) =>
      label == null || label.trim().isEmpty ? null : label.trim();

  Future<ContactDetailRow> _liveContact(String id) async {
    final detail = await (_db.select(
      _db.contactDetails,
    )..where((c) => c.id.equals(id) & c.deletedAt.isNull())).getSingleOrNull();
    if (detail == null) {
      throw const ContactException(ContactProblem.notAvailable);
    }
    return detail;
  }

  static ContactDetail _contactOf(ContactDetailRow row) => ContactDetail(
    id: row.id,
    personId: row.personId,
    kind: row.kind,
    value: row.value,
    label: row.label,
    sortOrder: row.sortOrder,
  );

  Future<List<ContactDetail>> _liveContactsOf(String personId) async => [
    for (final row in await (_db.select(
      _db.contactDetails,
    )..where((c) => c.personId.equals(personId) & c.deletedAt.isNull())).get())
      _contactOf(row),
  ];

  Future<PeopleData> _livePerson(String id) async {
    final person = await (_db.select(
      _db.people,
    )..where((p) => p.id.equals(id) & p.deletedAt.isNull())).getSingleOrNull();
    if (person == null) {
      throw const PersonException(PersonProblem.notAvailable);
    }
    return person;
  }

  @override
  Stream<Map<String, String>> watchMergedInto() {
    final query = _db.select(_db.people)
      ..where((p) => p.deletedAt.isNotNull() & p.mergedIntoId.isNotNull());
    return query.watch().map(
      (rows) => {for (final row in rows) row.id: row.mergedIntoId!},
    );
  }

  @override
  Future<PersonMerge> merge(
    String fromId,
    String intoId,
  ) => _db.transaction(() async {
    if (fromId == intoId) {
      throw const PersonException(PersonProblem.samePerson);
    }
    final stored = await _stored();
    final from = stored.people[fromId];
    final into = stored.people[intoId];
    if (from == null || into == null) {
      throw const PersonException(PersonProblem.notAvailable);
    }
    final writer = _storage.writer;

    // Every reference to [from] goes to [into]. Items in the trash keep
    // theirs: reading follows merged_into_id (DD-015).
    final requesterItems = await (_db.select(
      _db.items,
    )..where((i) => i.requesterId.equals(fromId) & i.deletedAt.isNull())).get();
    for (final item in requesterItems) {
      await writer.update(
        _db.items,
        item.id,
        ItemsCompanion(requesterId: Value(intoId)),
      );
    }
    final waitingItems = await (_db.select(
      _db.items,
    )..where((i) => i.waitingOnId.equals(fromId) & i.deletedAt.isNull())).get();
    for (final item in waitingItems) {
      await writer.update(
        _db.items,
        item.id,
        ItemsCompanion(waitingOnId: Value(intoId)),
      );
    }
    final attachments = await (_db.select(
      _db.attachments,
    )..where((a) => a.personId.equals(fromId) & a.deletedAt.isNull())).get();
    for (final attachment in attachments) {
      await writer.update(
        _db.attachments,
        attachment.id,
        AttachmentsCompanion(personId: Value(intoId)),
      );
    }

    // The name and aliases of [from] become aliases of [into], each
    // once.
    final keys = {
      nameKey(into.name),
      for (final a in stored.aliasesOf(intoId)) nameKey(a.alias),
    };
    final moved = <PersonAliase>[];
    final dropped = <String>[];
    for (final alias in stored.aliasesOf(fromId)) {
      if (keys.add(nameKey(alias.alias))) {
        await writer.update(
          _db.personAliases,
          alias.id,
          PersonAliasesCompanion(personId: Value(intoId)),
        );
        moved.add(alias);
      } else {
        await writer.delete(_db.personAliases, alias.id);
        dropped.add(alias.id);
      }
    }
    final added = <String>[];
    if (keys.add(nameKey(from.name))) {
      added.add(
        await writer.insert(
          _db.personAliases,
          PersonAliasesCompanion(
            personId: Value(intoId),
            alias: Value(from.name),
          ),
        ),
      );
    }

    final before = _profileOf(into);
    final after = mergeProfiles(before, _profileOf(from));
    if (after != before) await _writeProfile(intoId, after);

    // Contact details move; one [into] already has is dropped (T3.5).
    final contacts = mergeContactDetails(
      await _liveContactsOf(intoId),
      await _liveContactsOf(fromId),
      home: _storage.phoneCountry,
    );
    for (final detail in contacts.move) {
      await writer.update(
        _db.contactDetails,
        detail.id,
        ContactDetailsCompanion(personId: Value(intoId)),
      );
    }
    for (final detail in contacts.drop) {
      await writer.delete(_db.contactDetails, detail.id);
    }

    await writer.update(
      _db.people,
      fromId,
      PeopleCompanion(mergedIntoId: Value(intoId)),
    );
    await writer.delete(_db.people, fromId);

    // Derived tokens follow at once (DD-004: not change-logged).
    await (_db.update(_db.tokens)..where(
          (t) =>
              t.tokenType.equals(const PersonTokenType().id) &
              t.resolvedValue.equals(fromId),
        ))
        .write(TokensCompanion(resolvedValue: Value(intoId)));

    return PersonMerge(
      fromId: fromId,
      intoId: intoId,
      // The names whose tokens go back on undo: not those [into] had.
      fromNames: [
        for (final a in moved) a.alias,
        if (added.isNotEmpty) from.name,
      ],
      requesterItemIds: [for (final i in requesterItems) i.id],
      waitingItemIds: [for (final i in waitingItems) i.id],
      attachmentIds: [for (final a in attachments) a.id],
      movedAliasIds: [for (final a in moved) a.id],
      droppedAliasIds: dropped,
      addedAliasIds: added,
      movedContactIds: [for (final d in contacts.move) d.id],
      droppedContactIds: [for (final d in contacts.drop) d.id],
      profileBefore: before,
      profileAfter: after,
    );
  });

  @override
  Future<void> undoMerge(PersonMerge merge) => _db.transaction(() async {
    final writer = _storage.writer;
    final fromId = merge.fromId;
    final intoId = merge.intoId;
    final from = await (_db.select(
      _db.people,
    )..where((p) => p.id.equals(fromId))).getSingleOrNull();
    // Brought back meanwhile, or merged elsewhere: leave it.
    if (from == null || from.deletedAt == null || from.mergedIntoId != intoId) {
      return;
    }
    await writer.restore(_db.people, fromId);
    await writer.update(
      _db.people,
      fromId,
      const PeopleCompanion(mergedIntoId: Value(null)),
    );

    // Back only what still points to [into].
    for (final id in merge.requesterItemIds) {
      final item = await _liveItem(id);
      if (item?.requesterId == intoId) {
        await writer.update(
          _db.items,
          id,
          ItemsCompanion(requesterId: Value(fromId)),
        );
      }
    }
    for (final id in merge.waitingItemIds) {
      final item = await _liveItem(id);
      if (item?.waitingOnId == intoId) {
        await writer.update(
          _db.items,
          id,
          ItemsCompanion(waitingOnId: Value(fromId)),
        );
      }
    }
    for (final id in merge.attachmentIds) {
      final attachment =
          await (_db.select(_db.attachments)
                ..where((a) => a.id.equals(id) & a.deletedAt.isNull()))
              .getSingleOrNull();
      if (attachment?.personId == intoId) {
        await writer.update(
          _db.attachments,
          id,
          AttachmentsCompanion(personId: Value(fromId)),
        );
      }
    }

    for (final id in merge.movedAliasIds) {
      final alias = await _alias(id);
      if (alias != null &&
          alias.deletedAt == null &&
          alias.personId == intoId) {
        await writer.update(
          _db.personAliases,
          id,
          PersonAliasesCompanion(personId: Value(fromId)),
        );
      }
    }
    for (final id in merge.droppedAliasIds) {
      final alias = await _alias(id);
      if (alias != null && alias.deletedAt != null) {
        await writer.restore(_db.personAliases, id);
      }
    }
    for (final id in merge.addedAliasIds) {
      final alias = await _alias(id);
      if (alias != null && alias.deletedAt == null) {
        await writer.delete(_db.personAliases, id);
      }
    }

    for (final id in merge.movedContactIds) {
      final detail = await (_db.select(
        _db.contactDetails,
      )..where((c) => c.id.equals(id))).getSingleOrNull();
      if (detail != null &&
          detail.deletedAt == null &&
          detail.personId == intoId) {
        await writer.update(
          _db.contactDetails,
          id,
          ContactDetailsCompanion(personId: Value(fromId)),
        );
      }
    }
    for (final id in merge.droppedContactIds) {
      final detail = await (_db.select(
        _db.contactDetails,
      )..where((c) => c.id.equals(id))).getSingleOrNull();
      if (detail != null && detail.deletedAt != null) {
        await writer.restore(_db.contactDetails, id);
      }
    }

    final into = await (_db.select(
      _db.people,
    )..where((p) => p.id.equals(intoId))).getSingleOrNull();
    if (into != null && _profileOf(into) == merge.profileAfter) {
      await _writeProfile(intoId, merge.profileBefore);
    }

    // The tokens of the names of [from] link to [from] again.
    final keys = {for (final name in merge.fromNames) nameKey(name)};
    final tokens =
        await (_db.select(_db.tokens)..where(
              (t) =>
                  t.tokenType.equals(const PersonTokenType().id) &
                  t.resolvedValue.equals(intoId),
            ))
            .get();
    for (final token in tokens) {
      if (keys.contains(nameKey(token.rawValue))) {
        await (_db.update(_db.tokens)..where((t) => t.id.equals(token.id)))
            .write(TokensCompanion(resolvedValue: Value(fromId)));
      }
    }
  });

  Future<Item?> _liveItem(String id) => (_db.select(
    _db.items,
  )..where((i) => i.id.equals(id) & i.deletedAt.isNull())).getSingleOrNull();

  Future<PersonAliase?> _alias(String id) => (_db.select(
    _db.personAliases,
  )..where((a) => a.id.equals(id))).getSingleOrNull();

  static PersonProfile _profileOf(PeopleData person) => (
    birthdayDay: person.birthdayDay,
    birthdayMonth: person.birthdayMonth,
    birthdayYear: person.birthdayYear,
    note: person.note,
    organisation: person.organisation,
    jobTitle: person.jobTitle,
  );

  Future<void> _writeProfile(String id, PersonProfile profile) =>
      _storage.writer.update(
        _db.people,
        id,
        PeopleCompanion(
          birthdayDay: Value(profile.birthdayDay),
          birthdayMonth: Value(profile.birthdayMonth),
          birthdayYear: Value(profile.birthdayYear),
          note: Value(profile.note),
          organisation: Value(profile.organisation),
          jobTitle: Value(profile.jobTitle),
        ),
      );

  Future<_StoredPeople> _stored() async {
    final people = await (_db.select(
      _db.people,
    )..where((p) => p.deletedAt.isNull())).get();
    final aliases = await (_db.select(
      _db.personAliases,
    )..where((a) => a.deletedAt.isNull())).get();
    return _StoredPeople({for (final p in people) p.id: p}, aliases);
  }
}

/// The live people and their live aliases, read inside a transaction.
class _StoredPeople {
  _StoredPeople(this.people, this._aliases);

  final Map<String, PeopleData> people;
  final List<PersonAliase> _aliases;

  /// The live aliases of person [id].
  List<PersonAliase> aliasesOf(String id) => [
    for (final alias in _aliases)
      if (alias.personId == id) alias,
  ];

  /// The id of the live person called [name], by name first, then by
  /// alias, the oldest where two share it ([personIdsByName]); null when
  /// nobody is.
  String? holderOf(String name) => personIdsByName([
    for (final p in people.values)
      Person(
        id: p.id,
        name: p.name,
        aliases: [for (final a in aliasesOf(p.id)) a.alias],
      ),
  ])[nameKey(name)];
}
