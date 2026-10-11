import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/database/app_database.dart';
import 'package:offload/domain/ids/uuid_v7.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/domain/sync/hlc.dart';

/// Tables that must carry id, hlc and deleted_at (REQ-008, DD-003).
const syncTables = [
  'items',
  'people',
  'person_aliases',
  'contexts',
  'tags',
  'attachments',
  'item_links',
];

void main() {
  late AppDatabase db;
  final ids = UuidV7Generator();
  final clock = HlcClock(node: 'testnode');

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<List<String>> columnsOf(String table) async {
    final rows = await db.customSelect('PRAGMA table_info($table)').get();
    return rows.map((r) => r.read<String>('name')).toList();
  }

  test('bundled SQLite is SQLite3MultipleCiphers (DD-007)', () async {
    final rows = await db.customSelect('PRAGMA cipher').get();
    expect(rows, isNotEmpty);
  });

  test('every synchronisable table has id, hlc and deleted_at', () async {
    for (final table in syncTables) {
      expect(
        await columnsOf(table),
        containsAll(['id', 'hlc', 'deleted_at']),
        reason: table,
      );
    }
  });

  test('derived tokens carry no sync columns', () async {
    final columns = await columnsOf('tokens');
    expect(columns, isNot(contains('hlc')));
    expect(columns, isNot(contains('deleted_at')));
  });

  test('no table uses AUTOINCREMENT or an integer primary key', () async {
    final rows = await db
        .customSelect(
          "SELECT name, sql FROM sqlite_master WHERE type = 'table'",
        )
        .get();
    // The one exception: the search map's own integer key is the rowid of
    // the full-text index, derived and device-local data (DD-003, DD-016).
    const derivedWithIntegerKey = {'search_map'};
    for (final row in rows) {
      final name = row.read<String>('name');
      final sql = row.read<String>('sql').toUpperCase();
      expect(sql, isNot(contains('AUTOINCREMENT')), reason: name);
      if (derivedWithIntegerKey.contains(name)) continue;
      expect(
        sql,
        isNot(contains('INTEGER NOT NULL PRIMARY KEY')),
        reason: name,
      );
    }
  });

  test('stores and reads an item with enums and timestamps', () async {
    final id = ids.next();
    final due = DateTime.utc(2026, 10, 2, 9);
    await db
        .into(db.items)
        .insert(
          ItemsCompanion.insert(
            id: id,
            hlc: clock.tick().pack(),
            rawText: 'Call @Jan about #renovatie !fri',
            status: ItemStatus.inbox,
            source: ItemSource.widget,
            dueAt: Value(due),
          ),
        );

    final item = await (db.select(
      db.items,
    )..where((t) => t.id.equals(id))).getSingle();
    expect(item.status, ItemStatus.inbox);
    expect(item.source, ItemSource.widget);
    expect(item.type, isNull);
    expect(item.dueAt, due);
    expect(item.deletedAt, isNull);
  });

  test('enforces foreign keys', () async {
    expect(
      () => db
          .into(db.items)
          .insert(
            ItemsCompanion.insert(
              id: ids.next(),
              hlc: clock.tick().pack(),
              rawText: 'x',
              status: ItemStatus.inbox,
              source: ItemSource.app,
              contextId: const Value('missing-context'),
            ),
          ),
      throwsA(isA<SqliteException>()),
    );
  });

  test('rejects a birthday year without day and month', () async {
    expect(
      () => db
          .into(db.people)
          .insert(
            PeopleCompanion.insert(
              id: ids.next(),
              hlc: clock.tick().pack(),
              name: 'Jan',
              birthdayYear: const Value(1980),
            ),
          ),
      throwsA(isA<SqliteException>()),
    );
  });

  test('tag names are unique among live tags only', () async {
    Future<void> addTag(String name, {DateTime? deletedAt}) => db
        .into(db.tags)
        .insert(
          TagsCompanion.insert(
            id: ids.next(),
            hlc: clock.tick().pack(),
            name: name,
            deletedAt: Value(deletedAt),
          ),
        );

    await addTag('Renovatie', deletedAt: DateTime.utc(2026));
    await addTag('renovatie'); // the old one is a tombstone
    expect(() => addTag('RENOVATIE'), throwsA(isA<SqliteException>()));
  });
}
