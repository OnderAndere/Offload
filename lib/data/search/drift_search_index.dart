import 'dart:async';
import 'dart:developer' as developer;

import 'package:drift/drift.dart';

import '../../domain/people/calling_country.dart';
import '../../domain/people/contact_detail.dart';
import '../../domain/search/search_index.dart';
// The generated row class of the table has the same name as the domain
// interface; only the interface is used here.
import '../database/app_database.dart' hide SearchIndex;

/// The FTS5 search index in the encrypted database (REQ-011, DD-016).
///
/// Triggers note changed items and people in `search_pending` inside the
/// saving transaction; this class does the indexing afterwards. Each entry is
/// indexed in its own transaction and leaves the queue only then, so an
/// interrupted run loses nothing.
class DriftSearchIndex implements SearchIndex {
  DriftSearchIndex(this._db, {this.phoneCountry = _defaultCountry});

  final AppDatabase _db;

  /// The home country of this device, to index a number typed without
  /// country code in its international form too (T3.6).
  final CallingCountry Function() phoneCountry;

  static CallingCountry _defaultCountry() => defaultCallingCountry;
  Future<void> _queue = Future.value();

  /// A hit in the title (item title, person name and aliases) weighs ten
  /// times a hit in the text (AC REQ-011).
  static const _titleWeight = 10.0;
  static const _bodyWeight = 1.0;

  static const _batchSize = 200;
  static const _items = 'items';
  static const _people = 'people';

  @override
  Future<List<SearchHit>> search(String query, {int limit = 50}) async {
    final match = ftsMatchExpression(query);
    if (match == null) return const [];
    return _hits(match, limit: limit);
  }

  @override
  Future<List<SearchHit>> itemsSharingWords(
    String text, {
    String? excludeId,
    int limit = 20,
  }) async {
    final match = ftsAnyWordExpression(text);
    if (match == null) return const [];
    return _hits(match, limit: limit, itemsOnly: true, excludeId: excludeId);
  }

  /// Live items and people matching [match], best first. The live rows are
  /// joined here, for what to show and so an entry deleted a moment ago
  /// never shows up while the indexer catches up.
  Future<List<SearchHit>> _hits(
    String match, {
    required int limit,
    bool itemsOnly = false,
    String? excludeId,
  }) async {
    final rows = await _db
        .customSelect(
          'SELECT m.entity, m.entity_id, '
          'bm25(search_index, ?, ?) AS rank, '
          'COALESCE(i.title, p.name) AS title, '
          "COALESCE(i.raw_text, p.note, '') AS text "
          'FROM search_index JOIN search_map m ON m.row_id = search_index.rowid '
          "LEFT JOIN items i ON m.entity = '$_items' "
          'AND i.id = m.entity_id AND i.deleted_at IS NULL '
          "LEFT JOIN people p ON m.entity = '$_people' "
          'AND p.id = m.entity_id AND p.deleted_at IS NULL '
          'WHERE search_index MATCH ? '
          '${itemsOnly ? 'AND i.id IS NOT NULL ' : 'AND (i.id IS NOT NULL OR p.id IS NOT NULL) '}'
          'AND m.entity_id IS NOT ? '
          'ORDER BY rank LIMIT ?',
          variables: [
            Variable<double>(_titleWeight),
            Variable<double>(_bodyWeight),
            Variable<String>(match),
            Variable<String>(excludeId),
            Variable<int>(limit),
          ],
          readsFrom: {_db.searchMap, _db.items, _db.people},
        )
        .get();
    return [
      for (final row in rows)
        SearchHit(
          entity: row.read<String>('entity') == _items
              ? SearchEntity.item
              : SearchEntity.person,
          id: row.read<String>('entity_id'),
          rank: row.read<double>('rank'),
          title: row.read<String?>('title'),
          text: row.read<String>('text'),
        ),
    ];
  }

  @override
  Future<void> processPending() => _serial(_processPending);

  @override
  Future<void> rebuild() => _serial(() async {
    await _db.transaction(() async {
      await _db.customStatement('DELETE FROM search_index');
      await _db.customStatement('DELETE FROM search_map');
      await _db.queueEverythingForSearch();
    });
    await _processPending();
  });

  /// Indexes the queue now and after every change to items, people or
  /// aliases, until the returned subscription is cancelled. Runs never
  /// overlap; changes during a run lead to one more run.
  StreamSubscription<void> keepUpToDate() {
    var running = false;
    var again = false;
    Future<void> run() async {
      if (running) {
        again = true;
        return;
      }
      running = true;
      do {
        again = false;
        try {
          await processPending();
        } catch (e, stack) {
          // Stays queued; the next change or start tries again. Only in the
          // local developer log, never sent anywhere (REQ-015).
          developer.log(
            'Search indexing failed',
            name: 'offload.search',
            error: e,
            stackTrace: stack,
          );
        }
      } while (again);
      running = false;
    }

    unawaited(run());
    return _db
        .tableUpdates(
          TableUpdateQuery.onAllTables([
            _db.items,
            _db.people,
            _db.personAliases,
            _db.contactDetails,
          ]),
        )
        .listen((_) => unawaited(run()));
  }

  Future<void> _serial(Future<void> Function() work) {
    final next = _queue.then((_) => work());
    _queue = next.catchError((Object _) {});
    return next;
  }

  Future<void> _processPending() async {
    // Entries that fail are skipped for the rest of this run, so one bad
    // row cannot keep the loop busy; they stay queued for the next run.
    final failed = <(String, String)>{};
    Object? firstError;
    // Passes over the queue in key order, a batch at a time, so a large
    // queue (after the migration) is never loaded at once. Entries queued
    // during a pass may sort before it: another pass follows as long as the
    // previous one did some work.
    var worked = true;
    var indexedAny = false;
    while (worked) {
      worked = false;
      var after = ('', '');
      while (true) {
        final rows = await _db
            .customSelect(
              'SELECT entity, entity_id FROM search_pending '
              'WHERE (entity, entity_id) > (?, ?) '
              'ORDER BY entity, entity_id LIMIT $_batchSize',
              variables: [
                Variable<String>(after.$1),
                Variable<String>(after.$2),
              ],
              readsFrom: {_db.searchPending},
            )
            .get();
        if (rows.isEmpty) break;
        final batch = [
          for (final row in rows)
            (row.read<String>('entity'), row.read<String>('entity_id')),
        ];
        after = batch.last;
        for (final key in batch) {
          if (failed.contains(key)) continue;
          worked = true;
          try {
            await _db.transaction(() => _index(key.$1, key.$2));
            indexedAny = true;
          } catch (e) {
            failed.add(key);
            firstError ??= e;
          }
        }
      }
    }
    // Screens that depend on the index (the duplicate hint) look again.
    if (indexedAny) {
      _db.notifyUpdates({TableUpdate.onTable(_db.searchMap)});
    }
    if (firstError != null) throw firstError;
  }

  Future<void> _index(String entity, String id) async {
    final document = switch (entity) {
      _items => await _itemDocument(id),
      _people => await _personDocument(id),
      _ => null, // Unknown source: nothing to index; drop the entry.
    };
    final existing = await _db
        .customSelect(
          'SELECT row_id FROM search_map WHERE entity = ? AND entity_id = ?',
          variables: [Variable<String>(entity), Variable<String>(id)],
        )
        .getSingleOrNull();
    var rowId = existing?.read<int>('row_id');
    if (rowId != null) {
      await _db.customStatement('DELETE FROM search_index WHERE rowid = ?', [
        rowId,
      ]);
    }
    if (document == null) {
      if (rowId != null) {
        await _db.customStatement('DELETE FROM search_map WHERE row_id = ?', [
          rowId,
        ]);
      }
    } else {
      rowId ??= await _db.customInsert(
        'INSERT INTO search_map (entity, entity_id) VALUES (?, ?)',
        variables: [Variable<String>(entity), Variable<String>(id)],
      );
      await _db.customStatement(
        'INSERT INTO search_index (rowid, title, body) VALUES (?, ?, ?)',
        [rowId, document.title, document.body],
      );
    }
    await _db.customStatement(
      'DELETE FROM search_pending WHERE entity = ? AND entity_id = ?',
      [entity, id],
    );
  }

  /// Title and text of a live item; null when it is gone or in the trash.
  Future<({String title, String body})?> _itemDocument(String id) async {
    final row = await _db
        .customSelect(
          'SELECT title, raw_text, body FROM items '
          'WHERE id = ? AND deleted_at IS NULL',
          variables: [Variable<String>(id)],
        )
        .getSingleOrNull();
    if (row == null) return null;
    return (
      title: row.read<String?>('title') ?? '',
      body: [
        row.read<String>('raw_text'),
        ?row.read<String?>('body'),
      ].join('\n'),
    );
  }

  /// Name and live aliases as the title (PO decision 27-09-2026); the note,
  /// organisation, job title and contact details as the text (REQ-038): a
  /// phone number also by its digits alone, so "0612" finds "06-12 34 56
  /// 78", and an own label (a standard one is shown translated, so its
  /// stored name is not searched). Null when the person is gone or deleted.
  Future<({String title, String body})?> _personDocument(String id) async {
    final row = await _db
        .customSelect(
          'SELECT name, note, organisation, job_title FROM people '
          'WHERE id = ? AND deleted_at IS NULL',
          variables: [Variable<String>(id)],
        )
        .getSingleOrNull();
    if (row == null) return null;
    final aliases = await _db
        .customSelect(
          'SELECT alias FROM person_aliases '
          'WHERE person_id = ? AND deleted_at IS NULL ORDER BY alias',
          variables: [Variable<String>(id)],
        )
        .get();
    final contacts = await (_db.select(
      _db.contactDetails,
    )..where((c) => c.personId.equals(id) & c.deletedAt.isNull())).get();
    return (
      title: [
        row.read<String>('name'),
        for (final a in aliases) a.read<String>('alias'),
      ].join('\n'),
      body: [
        ?row.read<String?>('note'),
        ?row.read<String?>('organisation'),
        ?row.read<String?>('job_title'),
        for (final c in contacts) ...[
          c.value,
          if (c.kind == ContactKind.phone) phoneDigits(c.value),
          // "+316…" finds "06…" (the tokenizer drops the +).
          if (c.kind == ContactKind.phone)
            ?e164(c.value, phoneCountry())?.substring(1),
          if (c.label case final label?
              when StandardContactLabel.of(label) == null)
            label,
        ],
      ].join('\n'),
    );
  }
}
