import 'package:drift/drift.dart';

import '../../domain/items/completion.dart';
import '../../domain/items/item.dart' as domain;
import '../../domain/items/item_classification.dart';
import '../../domain/items/item_enums.dart';
import '../../domain/items/item_repository.dart';
import '../../domain/items/item_status_machine.dart';
import '../../domain/links/item_link.dart';
import '../../domain/people/person.dart';
import '../../domain/people/person_overview.dart';
import '../../domain/projects/project_tree.dart';
import '../../domain/repeats/repeat.dart';
import '../../domain/sync/hlc.dart';
import '../../domain/time/local_date.dart';
import '../../domain/tokens/token_processing.dart';
import '../../domain/tokens/token_types.dart';
import '../database/app_database.dart';
import '../links/drift_item_link_repository.dart';
import '../repeats/drift_completions.dart';
import '../storage/app_storage.dart';

/// [ItemRepository] on the encrypted Drift database. Writes only through
/// the [AppStorage.writer], so every change gets its HLC and change-log entry
/// (REQ-008, REQ-037, DD-003).
class DriftItemRepository implements ItemRepository {
  DriftItemRepository(this._storage);

  final AppStorage _storage;

  AppDatabase get _db => _storage.database;

  @override
  Future<String> capture(
    String rawText, {
    required ItemSource source,
    Map<String, String> links = const {},
  }) async {
    final row = _newInboxItem(rawText, source);
    if (links.isEmpty) return _storage.writer.insert(_db.items, row);
    return _db.transaction(() async {
      final id = await _storage.writer.insert(_db.items, row);
      await _writeLinks(id, rawText, links);
      return id;
    });
  }

  /// The links chosen while typing, by label (DD-004 point 13), for the
  /// labels still in [rawText]; the processing removes any left over.
  Future<void> _writeLinks(
    String fromId,
    String rawText,
    Map<String, String> links,
  ) async {
    for (final MapEntry(key: label, value: toId) in links.entries) {
      if (!rawText.contains(label.trim())) continue;
      await _links.writeChosen(fromId, toId, label);
    }
  }

  late final _links = DriftItemLinkRepository(_storage);

  /// Spaces and tabs at the end of a text; line breaks stay.
  static final _trailingSpaces = RegExp(r'[ \t]+$');

  @override
  Future<bool> captureWithId(
    String id,
    String rawText, {
    required ItemSource source,
  }) async => _storage.writer.insertWithId(
    _db.items,
    id,
    _newInboxItem(rawText, source),
  );

  static ItemsCompanion _newInboxItem(String rawText, ItemSource source) {
    if (!domain.hasCapturableText(rawText)) {
      throw ArgumentError.value(rawText, 'rawText', 'has no text');
    }
    return ItemsCompanion(
      rawText: Value(rawText),
      status: const Value(ItemStatus.inbox),
      source: Value(source),
    );
  }

  @override
  Stream<List<domain.Item>> watchInbox() {
    final query = _db.select(_db.items)
      ..where(
        (i) => i.status.equalsValue(ItemStatus.inbox) & i.deletedAt.isNull(),
      )
      // UUIDv7 ids sort by creation time.
      ..orderBy([(i) => OrderingTerm.desc(i.id)]);
    return query.watch().map(
      (rows) => [for (final row in rows) _toDomain(row)],
    );
  }

  @override
  Stream<List<domain.Item>> watchLiveItems() {
    final query = _db.select(_db.items)
      ..where((i) => i.deletedAt.isNull())
      ..orderBy([(i) => OrderingTerm.desc(i.id)]);
    return query.watch().map(
      (rows) => [for (final row in rows) _toDomain(row)],
    );
  }

  @override
  Stream<List<domain.Item>> watchDueThrough(LocalDate day) {
    // A date-only deadline is midnight UTC of its day (DD-004), so "on or
    // before day" is "before midnight UTC of the next day".
    final before = dateOnlyToStored(day.addDays(1));
    final query = _db.select(_db.items)
      ..where(
        (i) =>
            i.deletedAt.isNull() &
            i.status.isNotInValues([ItemStatus.done, ItemStatus.archived]) &
            i.dueAt.isSmallerThanValue(before),
      )
      ..orderBy([
        (i) => OrderingTerm.asc(i.dueAt),
        (i) => OrderingTerm.asc(i.id),
      ]);
    return query.watch().map(
      (rows) => [for (final row in rows) _toDomain(row)],
    );
  }

  @override
  Stream<List<domain.Item>> watchLateWaiting(LocalDate day) {
    // Expected dates are date-only, midnight UTC of their day (DD-004).
    final query = _db.select(_db.items)
      ..where(
        (i) =>
            i.deletedAt.isNull() &
            i.status.equalsValue(ItemStatus.waiting) &
            i.expectedAt.isSmallerThanValue(dateOnlyToStored(day)),
      )
      ..orderBy([
        (i) => OrderingTerm.asc(i.expectedAt),
        (i) => OrderingTerm.asc(i.id),
      ]);
    return query.watch().map(
      (rows) => [for (final row in rows) _toDomain(row)],
    );
  }

  @override
  Stream<domain.Item?> watchItem(String id) {
    final query = _db.select(_db.items)
      ..where((i) => i.id.equals(id) & i.deletedAt.isNull());
    return query.watchSingleOrNull().map(
      (row) => row == null ? null : _toDomain(row),
    );
  }

  @override
  Stream<List<domain.Item>> watchProjectItems(String? projectId) {
    final query = _db.select(_db.items)
      ..where((i) {
        final inProject = projectId != null
            ? i.contextId.equals(projectId)
            : i.contextId.isNull() |
                  i.contextId.isNotInQuery(
                    _db.selectOnly(_db.contexts)
                      ..addColumns([_db.contexts.id])
                      ..where(_db.contexts.deletedAt.isNull()),
                  );
        return i.deletedAt.isNull() & inProject;
      })
      ..orderBy([(i) => OrderingTerm.desc(i.id)]);
    return query.watch().map(
      (rows) => [for (final row in rows) _toDomain(row)],
    );
  }

  @override
  Stream<PersonItems> watchPersonItems(String personId) {
    // The person and everyone merged into them, also through a chain: a
    // reference to a merged person reads as one to this person (DD-015).
    const ids =
        'WITH RECURSIVE ids(id) AS (SELECT ?2 UNION '
        'SELECT p.id FROM people p JOIN ids ON p.merged_into_id = ids.id '
        'WHERE p.deleted_at IS NOT NULL) ';
    // Named in the text: a stored person token resolved to the person
    // (DD-004). Tokens are replaced per item when it is parsed again; a
    // rename keeps them valid, because the old name stays an alias.
    const named =
        'EXISTS (SELECT 1 FROM tokens t WHERE t.item_id = i.id '
        'AND t.token_type = ?1 AND t.resolved_value IN ids)';
    return _db
        .customSelect(
          '${ids}SELECT i.*, $named AS named, '
          '(SELECT group_concat(id) FROM ids) AS person_ids FROM items i '
          'WHERE i.deleted_at IS NULL AND (i.requester_id IN ids '
          'OR i.waiting_on_id IN ids OR $named) '
          'ORDER BY i.id DESC',
          variables: [
            Variable.withString(const PersonTokenType().id),
            Variable.withString(personId),
          ],
          readsFrom: {_db.items, _db.tokens, _db.people},
        )
        .watch()
        .map((rows) {
          final items = <domain.Item>[];
          final mentioned = <String>{};
          for (final row in rows) {
            final merged = row.read<String>('person_ids').split(',').toSet();
            String? follow(String? id) =>
                id != null && merged.contains(id) ? personId : id;
            final stored = _toDomain(_db.items.map(row.data));
            final item = domain.Item(
              id: stored.id,
              rawText: stored.rawText,
              type: stored.type,
              status: stored.status,
              source: stored.source,
              body: stored.body,
              dueAt: stored.dueAt,
              requesterId: follow(stored.requesterId),
              waitingOnId: follow(stored.waitingOnId),
              projectId: stored.projectId,
              revisitAt: stored.revisitAt,
              changedAt: stored.changedAt,
              reviewedAt: stored.reviewedAt,
              priority: stored.priority,
              askedAt: stored.askedAt,
              promise: stored.promise,
              expectedAt: stored.expectedAt,
            );
            items.add(item);
            if (row.read<bool>('named')) mentioned.add(item.id);
          }
          return (items: items, mentionedIds: mentioned);
        });
  }

  @override
  Stream<Map<String, Set<String>>> watchMentions() => _db
      .customSelect(
        'SELECT t.item_id, t.resolved_value FROM tokens t '
        'JOIN items i ON i.id = t.item_id AND i.deleted_at IS NULL '
        'WHERE t.token_type = ?1 AND t.resolved_value IS NOT NULL',
        variables: [Variable.withString(const PersonTokenType().id)],
        readsFrom: {_db.tokens, _db.items},
      )
      .watch()
      .map((rows) {
        final mentions = <String, Set<String>>{};
        for (final row in rows) {
          (mentions[row.read<String>('item_id')] ??= {}).add(
            row.read<String>('resolved_value'),
          );
        }
        return mentions;
      });

  @override
  Future<void> editText(
    String id,
    String rawText, {
    Map<String, String> links = const {},
  }) async {
    if (!domain.hasCapturableText(rawText)) {
      throw ArgumentError.value(rawText, 'rawText', 'has no text');
    }
    await _db.transaction(() async {
      await _storage.writer.update(
        _db.items,
        id,
        ItemsCompanion(rawText: Value(rawText)),
      );
      await _writeLinks(id, rawText, links);
    });
  }

  @override
  Future<void> appendLink(String fromId, String toId, String label) =>
      _db.transaction(() async {
        final item = await (_db.select(
          _db.items,
        )..where((i) => i.id.equals(fromId))).getSingle();
        final text = item.rawText.replaceFirst(_trailingSpaces, '');
        final word = linkLabelFor(label);
        await _storage.writer.update(
          _db.items,
          fromId,
          ItemsCompanion(rawText: Value('$text [[$word]]')),
        );
        await _links.writeChosen(fromId, toId, word);
      });

  @override
  Future<String> captureLinked(
    String fromId,
    String label, {
    required ItemSource source,
  }) => _db.transaction(() async {
    final id = await _storage.writer.insert(
      _db.items,
      _newInboxItem(label.trim(), source),
    );
    await _links.writeChosen(fromId, id, label);
    return id;
  });

  @override
  Future<void> editNote(String id, String note) => _storage.writer.update(
    _db.items,
    id,
    ItemsCompanion(body: Value(note.trim().isEmpty ? null : note)),
  );

  @override
  Future<void> moveTo(String id, ItemStatus status) async {
    await _db.transaction(() async {
      final item = await (_db.select(
        _db.items,
      )..where((i) => i.id.equals(id) & i.deletedAt.isNull())).getSingle();
      if (item.status == status) return;
      if (!nextStatuses(item.status).contains(status)) {
        throw StateError('${item.status.name} cannot move to ${status.name}');
      }
      await _storage.writer.update(
        _db.items,
        id,
        ItemsCompanion(
          status: Value(status),
          // Scheduled by hand has no date: an old one (of an item that
          // returned earlier) must not send it back at once.
          revisitAt: status == ItemStatus.scheduled
              ? const Value(null)
              : _leavesParking(item),
        ),
      );
    });
  }

  @override
  Future<Completion> complete(String id, {required LocalDate today}) =>
      _db.transaction(() async {
        final item = await (_db.select(
          _db.items,
        )..where((i) => i.id.equals(id) & i.deletedAt.isNull())).getSingle();
        final repeat = await _db.storedRepeat(id);
        final repeats =
            repeat != null &&
            repeatsAs(item.type) &&
            nextStatuses(item.status).contains(ItemStatus.done);
        if (!repeats) {
          await moveTo(id, ItemStatus.done);
          return Completion(
            itemId: id,
            before: ItemClassification.of(_toDomain(item)),
            dueBefore: item.dueAt,
          );
        }
        final records = await _db.liveCompletions(id);
        final dueAt = item.dueAt;
        final occurrence = dueAt == null
            ? repeatDue(repeat.anchor, repeat.rhythm, records)
            : storedToDateOnly(dueAt);
        return _completeTime(item, repeat, occurrence, today, records);
      });

  @override
  Future<Completion> completeAndRepeat(
    String id, {
    required String rawText,
    required Rhythm rhythm,
    required LocalDate today,
  }) => _db.transaction(() async {
    final item = await (_db.select(
      _db.items,
    )..where((i) => i.id.equals(id) & i.deletedAt.isNull())).getSingle();
    if (!repeatsAs(item.type) ||
        !nextStatuses(item.status).contains(ItemStatus.done)) {
      throw StateError('$id cannot repeat');
    }
    await _storage.writer.update(
      _db.items,
      id,
      ItemsCompanion(rawText: Value(rawText)),
    );
    // Without a repeat word yet, the item's date is its first date token
    // (DD-018 point 1): the first time of the series, and this time.
    final dueAt = item.dueAt;
    final occurrence = dueAt == null ? today : storedToDateOnly(dueAt);
    final completion = await _completeTime(
      item,
      ItemRepeat(rhythm, occurrence),
      occurrence,
      today,
      const [],
    );
    return Completion(
      itemId: id,
      before: completion.before,
      dueBefore: dueAt,
      recordId: completion.recordId,
      nextDue: completion.nextDue,
      textBefore: item.rawText,
      textAfter: rawText,
    );
  });

  @override
  Future<Completion> stopRepeating(String id, {required String rawText}) =>
      _db.transaction(() async {
        final item = await (_db.select(
          _db.items,
        )..where((i) => i.id.equals(id) & i.deletedAt.isNull())).getSingle();
        await _storage.writer.update(
          _db.items,
          id,
          ItemsCompanion(rawText: Value(rawText)),
        );
        await moveTo(id, ItemStatus.done);
        return Completion(
          itemId: id,
          before: ItemClassification.of(_toDomain(item)),
          dueBefore: item.dueAt,
          textBefore: item.rawText,
          textAfter: rawText,
        );
      });

  /// Records [occurrence] of the series [repeat] of [item] as done on
  /// [today] and moves the item to the next time (DD-018 point 18).
  Future<Completion> _completeTime(
    Item item,
    ItemRepeat repeat,
    LocalDate occurrence,
    LocalDate today,
    List<RepeatCompletion> records,
  ) async {
    final recordId = completionId(item.id, occurrence);
    final record = RepeatCompletion(
      occurrenceOn: occurrence,
      completedOn: today,
    );
    await _storage.writer.put(
      _db.itemCompletions,
      recordId,
      ItemCompletionsCompanion(
        itemId: Value(item.id),
        occurrenceOn: Value(dateOnlyToStored(occurrence)),
        completedOn: Value(dateOnlyToStored(today)),
      ),
    );
    final next = repeatDue(repeat.anchor, repeat.rhythm, [
      ...records.where((r) => r.occurrenceOn != occurrence),
      record,
    ]);
    await _storage.writer.update(
      _db.items,
      item.id,
      ItemsCompanion(
        dueAt: Value(dateOnlyToStored(next)),
        status: item.status == ItemStatus.active
            ? const Value.absent()
            : const Value(ItemStatus.active),
        revisitAt: const Value(null),
      ),
    );
    return Completion(
      itemId: item.id,
      before: ItemClassification.of(_toDomain(item)),
      dueBefore: item.dueAt,
      recordId: recordId,
      nextDue: next,
    );
  }

  @override
  Future<void> undoComplete(Completion completion) => _db.transaction(() async {
    final textBefore = completion.textBefore;
    final current = await (_db.select(
      _db.items,
    )..where((i) => i.id.equals(completion.itemId))).getSingleOrNull();
    if (textBefore != null && current?.rawText == completion.textAfter) {
      await _storage.writer.update(
        _db.items,
        completion.itemId,
        ItemsCompanion(rawText: Value(textBefore)),
      );
    }
    final recordId = completion.recordId;
    if (recordId != null) {
      final record = await (_db.select(
        _db.itemCompletions,
      )..where((c) => c.id.equals(recordId))).getSingleOrNull();
      if (record != null && record.deletedAt == null) {
        await _storage.writer.delete(_db.itemCompletions, recordId);
      }
      await _storage.writer.update(
        _db.items,
        completion.itemId,
        ItemsCompanion(dueAt: Value(completion.dueBefore)),
      );
    }
    await classify(completion.itemId, completion.before);
  });

  @override
  Stream<Map<String, ItemRepeat>> watchRepeats() => _db
      .customSelect(
        'SELECT t.item_id, t.resolved_value FROM tokens t '
        'JOIN items i ON i.id = t.item_id AND i.deleted_at IS NULL '
        'WHERE t.token_type = ?1 AND t.resolved_value IS NOT NULL',
        variables: [Variable.withString(const RepeatTokenType().id)],
        readsFrom: {_db.tokens, _db.items},
      )
      .watch()
      .map((rows) {
        final repeats = <String, ItemRepeat>{};
        for (final row in rows) {
          final repeat = ItemRepeat.decode(row.read<String>('resolved_value'));
          if (repeat != null) {
            repeats.putIfAbsent(row.read<String>('item_id'), () => repeat);
          }
        }
        return repeats;
      });

  @override
  Stream<List<RepeatCompletion>> watchCompletions(String itemId) {
    final query = _db.select(_db.itemCompletions)
      ..where((c) => c.itemId.equals(itemId) & c.deletedAt.isNull())
      ..orderBy([(c) => OrderingTerm.desc(c.occurrenceOn)]);
    return query.watch().map(
      (rows) => [for (final row in rows) completionOf(row)],
    );
  }

  /// A parked item moved by hand loses its revisit date (DD-005).
  static Value<DateTime?> _leavesParking(Item item) =>
      item.status == ItemStatus.scheduled && item.revisitAt != null
      ? const Value(null)
      : const Value.absent();

  @override
  Future<void> revisitOn(String id, LocalDate day) => _db.transaction(() async {
    final item = await (_db.select(
      _db.items,
    )..where((i) => i.id.equals(id) & i.deletedAt.isNull())).getSingle();
    if (item.status != ItemStatus.scheduled &&
        !nextStatuses(item.status).contains(ItemStatus.scheduled)) {
      throw StateError('${item.status.name} cannot be parked');
    }
    await _storage.writer.update(
      _db.items,
      id,
      ItemsCompanion(
        status: const Value(ItemStatus.scheduled),
        revisitAt: Value(dateOnlyToStored(day)),
      ),
    );
  });

  @override
  Future<void> stopRevisit(String id) => _db.transaction(() async {
    final item = await (_db.select(
      _db.items,
    )..where((i) => i.id.equals(id) & i.deletedAt.isNull())).getSingle();
    if (item.status != ItemStatus.scheduled) {
      throw StateError('${item.status.name} is not parked');
    }
    await _storage.writer.update(
      _db.items,
      id,
      const ItemsCompanion(
        status: Value(ItemStatus.active),
        revisitAt: Value(null),
      ),
    );
  });

  @override
  Future<List<String>> returnRevisited(LocalDate today) =>
      _db.transaction(() async {
        // The stored date is UTC midnight: everything up to the end of
        // [today] in UTC is due.
        final due =
            await (_db.select(_db.items)..where(
                  (i) =>
                      i.deletedAt.isNull() &
                      i.status.equalsValue(ItemStatus.scheduled) &
                      i.revisitAt.isSmallerOrEqualValue(
                        dateOnlyToStored(today.addDays(1)),
                      ),
                ))
                .get();
        final back = <String>[];
        for (final item in due) {
          if (storedToDateOnly(item.revisitAt!).compareTo(today) > 0) continue;
          await _storage.writer.update(
            _db.items,
            item.id,
            const ItemsCompanion(status: Value(ItemStatus.inbox)),
          );
          back.add(item.id);
        }
        return back;
      });

  @override
  Future<void> setType(String id, ItemType? type) =>
      _storage.writer.update(_db.items, id, ItemsCompanion(type: Value(type)));

  @override
  Future<void> setProject(String id, String? projectId) =>
      _db.transaction(() async {
        if (projectId != null) {
          final project =
              await (_db.select(_db.contexts)..where(
                    (c) =>
                        c.id.equals(projectId) &
                        c.deletedAt.isNull() &
                        c.archivedAt.isNull(),
                  ))
                  .getSingleOrNull();
          if (project == null) {
            throw const ProjectException(ProjectProblem.notAvailable);
          }
        }
        await _storage.writer.update(
          _db.items,
          id,
          ItemsCompanion(contextId: Value(projectId)),
        );
      });

  @override
  Future<void> setRequester(String id, String? personId) =>
      _db.transaction(() async {
        await _checkPerson(personId);
        await _storage.writer.update(
          _db.items,
          id,
          ItemsCompanion(requesterId: Value(personId)),
        );
      });

  @override
  Future<void> setWaitingOn(String id, String? personId) =>
      _db.transaction(() async {
        await _checkPerson(personId);
        await _storage.writer.update(
          _db.items,
          id,
          ItemsCompanion(waitingOnId: Value(personId)),
        );
      });

  @override
  Future<void> waitFor(String id, String? personId, {LocalDate? expected}) =>
      _db.transaction(() async {
        final item = await (_db.select(
          _db.items,
        )..where((i) => i.id.equals(id) & i.deletedAt.isNull())).getSingle();
        if (item.status != ItemStatus.waiting &&
            !nextStatuses(item.status).contains(ItemStatus.waiting)) {
          throw StateError('${item.status.name} cannot move to waiting');
        }
        await _checkPerson(personId);
        await _storage.writer.update(
          _db.items,
          id,
          ItemsCompanion(
            status: const Value(ItemStatus.waiting),
            revisitAt: _leavesParking(item),
            waitingOnId: personId == null
                ? const Value.absent()
                : Value(personId),
            // Starting to wait: exactly the day chosen, none included.
            expectedAt: item.status != ItemStatus.waiting || expected != null
                ? Value(expected == null ? null : dateOnlyToStored(expected))
                : const Value.absent(),
          ),
        );
      });

  /// Refuses a person that is deleted or does not exist; null is no person.
  Future<void> _checkPerson(String? personId) async {
    if (personId == null) return;
    final person =
        await (_db.select(_db.people)
              ..where((p) => p.id.equals(personId) & p.deletedAt.isNull()))
            .getSingleOrNull();
    if (person == null) {
      throw const PersonException(PersonProblem.notAvailable);
    }
  }

  @override
  Future<void> classify(
    String id,
    ItemClassification classification, {
    ({LocalDate? day})? expected,
  }) => _storage.writer.update(
    _db.items,
    id,
    ItemsCompanion(
      type: Value(classification.type),
      status: Value(classification.status),
      requesterId: Value(classification.requesterId),
      waitingOnId: Value(classification.waitingOnId),
      revisitAt: Value(classification.revisitAt),
      expectedAt: switch (expected) {
        null => const Value.absent(),
        (:final day) => Value(day == null ? null : dateOnlyToStored(day)),
      },
    ),
  );

  @override
  Future<void> markReviewed(String id) => _storage.writer.update(
    _db.items,
    id,
    ItemsCompanion(reviewedAt: Value(DateTime.now().toUtc())),
  );

  @override
  Future<void> setAskedOn(String id, LocalDate? day) => _storage.writer.update(
    _db.items,
    id,
    ItemsCompanion(askedAt: Value(day == null ? null : dateOnlyToStored(day))),
  );

  @override
  Future<void> setPromise(String id, String? promise) {
    final text = promise?.trim();
    return _storage.writer.update(
      _db.items,
      id,
      ItemsCompanion(
        promise: Value(text == null || text.isEmpty ? null : text),
      ),
    );
  }

  @override
  Future<void> setExpectedBy(String id, LocalDate? day) =>
      _storage.writer.update(
        _db.items,
        id,
        ItemsCompanion(
          expectedAt: Value(day == null ? null : dateOnlyToStored(day)),
        ),
      );

  @override
  Future<void> moveToTrash(String id) => _storage.writer.delete(_db.items, id);

  @override
  Future<bool> isLive(String id) async =>
      await (_db.select(_db.items)
            ..where((i) => i.id.equals(id) & i.deletedAt.isNull()))
          .getSingleOrNull() !=
      null;

  @override
  Future<void> restoreFromTrash(String id) =>
      _storage.writer.restore(_db.items, id);

  /// [row] as a domain item, for a reader of its own (the export, T7.3).
  static domain.Item itemOf(Item row) => _toDomain(row);

  static domain.Item _toDomain(Item row) => domain.Item(
    revisitAt: row.revisitAt,
    changedAt: hlcTime(row.hlc),
    reviewedAt: row.reviewedAt,
    id: row.id,
    rawText: row.rawText,
    type: row.type,
    status: row.status,
    source: row.source,
    body: row.body,
    dueAt: row.dueAt,
    requesterId: row.requesterId,
    waitingOnId: row.waitingOnId,
    projectId: row.contextId,
    priority: row.priority,
    askedAt: _dateOnly(row.askedAt),
    promise: row.promise,
    expectedAt: _dateOnly(row.expectedAt),
  );

  static LocalDate? _dateOnly(DateTime? stored) =>
      stored == null ? null : storedToDateOnly(stored);
}
