import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/database/app_database.dart';
import 'package:offload/data/items/drift_item_repository.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/data/sync/change_log_replayer.dart';
import 'package:offload/data/tokens/drift_token_processor.dart';
import 'package:offload/domain/ids/uuid_v7.dart';
import 'package:offload/domain/items/item_classification.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/domain/repeats/repeat.dart';
import 'package:offload/domain/sync/change_operation.dart';
import 'package:offload/domain/time/local_date.dart';
import 'package:offload/domain/tokens/inline_token.dart';
import 'package:offload/domain/tokens/inline_token_registry.dart';
import 'package:offload/domain/tokens/token_processing.dart';

import '../../fakes/test_storage.dart';

/// Recurring tasks (T4.7, REQ-061, DD-018 point 18): the series date from
/// the text and the records, completing a time and its undo, and two
/// devices that complete the same time.
void main() {
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
  // Every app language, Ukrainian (T8.6) included for the test.
  const repeatWords = RepeatVocabulary(
    daily: ['dagelijks', 'daily', 'щодня'],
    weekly: ['wekelijks', 'weekly', 'щотижня'],
    monthly: ['maandelijks', 'monthly', 'щомісяця'],
  );

  // Device B in the two-device test is a second database on purpose.
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  late AppStorage storage;
  late DriftItemRepository items;
  late DriftTokenProcessor processor;

  DriftTokenProcessor processorFor(AppStorage s) => DriftTokenProcessor(
    s,
    registry: InlineTokenRegistry.standard(),
    dates: () => dutch,
    repeats: repeatWords,
  );

  setUp(() async {
    storage = await openTestStorage();
    items = DriftItemRepository(storage);
    processor = processorFor(storage);
  });
  tearDown(() => storage.close());

  AppDatabase db() => storage.database;
  LocalDate d(int y, int m, int day) => LocalDate(y, m, day);

  /// An item captured at noon on [day] (its UUIDv7 carries the moment).
  Future<String> captureOn(
    LocalDate day,
    String text, {
    DriftItemRepository? repository,
  }) async {
    final id = UuidV7Generator(
      now: () =>
          DateTime(day.year, day.month, day.day, 12).millisecondsSinceEpoch,
    ).next();
    await (repository ?? items).captureWithId(id, text, source: ItemSource.app);
    return id;
  }

  Future<Item> row(String id, [AppDatabase? on]) {
    final database = on ?? db();
    return (database.select(
      database.items,
    )..where((i) => i.id.equals(id))).getSingle();
  }

  Future<LocalDate?> dueOf(String id, [AppDatabase? on]) async {
    final due = (await row(id, on)).dueAt;
    return due == null ? null : storedToDateOnly(due);
  }

  Future<List<ItemCompletion>> records([AppDatabase? on]) {
    final database = on ?? db();
    return database.select(database.itemCompletions).get();
  }

  Future<String?> storedRepeat(String id) async {
    final token =
        await (db().select(
              db().tokens,
            )..where((t) => t.itemId.equals(id) & t.tokenType.equals('repeat')))
            .getSingleOrNull();
    return token?.resolvedValue;
  }

  group('the token processor', () {
    test('a date token is the first time of the series', () async {
      final id = await captureOn(d(2026, 9, 7), 'Hardlopen !wekelijks !di');
      await processor.process(id);

      expect(await storedRepeat(id), '1W@2026-09-08');
      expect(await dueOf(id), d(2026, 9, 8));
    });

    test('without a date, the day the word was typed', () async {
      final id = await captureOn(d(2026, 10, 6), 'Rugoefeningen !dagelijks');
      await processor.process(id);

      expect(await storedRepeat(id), '1D@2026-10-06');
      expect(await dueOf(id), d(2026, 10, 6));
    });

    test(
      'recognises the repeat words of every language, Cyrillic too',
      () async {
        final weekly = await captureOn(d(2026, 10, 6), 'Run !Weekly');
        final daily = await captureOn(d(2026, 10, 6), 'Зарядка !Щодня');
        await processor.process(weekly);
        await processor.process(daily);

        expect(await storedRepeat(weekly), '1W@2026-10-06');
        expect(await storedRepeat(daily), '1D@2026-10-06');
      },
    );

    test('the first repeat word counts', () async {
      final id = await captureOn(
        d(2026, 10, 6),
        'Planten !wekelijks of toch !dagelijks',
      );
      await processor.process(id);

      final tokens =
          await (db().select(db().tokens)..where(
                (t) => t.itemId.equals(id) & t.tokenType.equals('repeat'),
              ))
              .get();
      expect(tokens.map((t) => t.resolvedValue), contains('1W@2026-10-06'));
      expect(tokens.where((t) => t.resolvedValue == null), hasLength(1));
    });

    test('works out the date from the records, again after an edit', () async {
      final id = await captureOn(d(2026, 9, 7), 'Hardlopen !wekelijks !di');
      await processor.process(id);
      await items.complete(id, today: d(2026, 9, 8));
      expect(await dueOf(id), d(2026, 9, 15));

      await items.editText(id, 'Hardlopen !wekelijks !di #sport');
      await processor.process(id);

      expect(await dueOf(id), d(2026, 9, 15));
    });

    test('the date stays when the type changes', () async {
      final id = await captureOn(d(2026, 9, 7), 'Hardlopen !wekelijks !di');
      await processor.process(id);
      await items.complete(id, today: d(2026, 9, 8));
      await items.setType(id, ItemType.idea);
      await items.editText(id, 'Hardlopen !wekelijks !di.');
      await processor.process(id);

      expect(await dueOf(id), d(2026, 9, 15));
    });

    test('without the token, the date follows the text again', () async {
      final id = await captureOn(d(2026, 9, 7), 'Hardlopen !wekelijks !di');
      await processor.process(id);
      await items.complete(id, today: d(2026, 9, 8));
      await items.editText(id, 'Hardlopen !di');
      await processor.process(id);

      expect(await storedRepeat(id), isNull);
      expect(await dueOf(id), d(2026, 9, 8));
    });
  });

  group('completing', () {
    test('records the time and moves to the next date', () async {
      final id = await captureOn(d(2026, 9, 7), 'Hardlopen !wekelijks !di');
      await processor.process(id);

      final done = await items.complete(id, today: d(2026, 9, 8));

      expect(done.repeated, isTrue);
      expect(done.nextDue, d(2026, 9, 15));
      expect(done.recordId, completionId(id, d(2026, 9, 8)));
      expect(await dueOf(id), d(2026, 9, 15));
      final record = (await records()).single;
      expect(record.id, done.recordId);
      expect(storedToDateOnly(record.occurrenceOn), d(2026, 9, 8));
      expect(storedToDateOnly(record.completedOn), d(2026, 9, 8));
      // An untyped item from the inbox becomes active, never done.
      expect((await row(id)).status, ItemStatus.active);
    });

    test('a missed time is one, and the next comes after today', () async {
      final id = await captureOn(d(2026, 9, 7), 'Hardlopen !wekelijks !di');
      await processor.process(id);
      await items.complete(id, today: d(2026, 9, 8));
      // Not done on 15, 22 and 29 September: still one date, the 15th.
      await processor.process(id);
      expect(await dueOf(id), d(2026, 9, 15));

      final done = await items.complete(id, today: d(2026, 10, 1));

      expect(done.nextDue, d(2026, 10, 6));
      expect(
        storedToDateOnly((await records()).last.occurrenceOn),
        d(2026, 9, 15),
      );
    });

    test('a daily task left three days: the next is tomorrow', () async {
      final id = await captureOn(d(2026, 10, 2), 'Rugoefeningen !dagelijks');
      await processor.process(id);
      await items.complete(id, today: d(2026, 10, 2));

      final done = await items.complete(id, today: d(2026, 10, 6));

      expect(done.nextDue, d(2026, 10, 7));
    });

    test(
      'monthly without a date from 31 January: 28 Feb, then 31 Mar',
      () async {
        final id = await captureOn(d(2026, 1, 31), 'Huur !maandelijks');
        await processor.process(id);
        expect(await dueOf(id), d(2026, 1, 31));

        await items.complete(id, today: d(2026, 1, 31));
        expect(await dueOf(id), d(2026, 2, 28));
        await items.complete(id, today: d(2026, 2, 28));
        expect(await dueOf(id), d(2026, 3, 31));
        // Processing again keeps the day of the month.
        await items.editText(id, 'Huur !maandelijks.');
        await processor.process(id);
        expect(await dueOf(id), d(2026, 3, 31));
      },
    );

    test('an idea with the word is simply done', () async {
      final id = await captureOn(d(2026, 10, 6), 'Moestuinplan !maandelijks');
      await processor.process(id);
      await items.setType(id, ItemType.idea);

      final done = await items.complete(id, today: d(2026, 10, 6));

      expect(done.repeated, isFalse);
      expect((await row(id)).status, ItemStatus.done);
      expect(await records(), isEmpty);
    });

    test('an item without the word is simply done', () async {
      final id = await captureOn(d(2026, 10, 6), 'Offerte dakgoot !vandaag');
      await processor.process(id);

      final done = await items.complete(id, today: d(2026, 10, 6));

      expect(done.repeated, isFalse);
      expect((await row(id)).status, ItemStatus.done);
    });

    test(
      'a waiting or parked task becomes active, its revisit cleared',
      () async {
        final id = await captureOn(d(2026, 10, 6), 'Filter !maandelijks');
        await processor.process(id);
        await items.setType(id, ItemType.task);
        await items.revisitOn(id, d(2026, 10, 20));

        await items.complete(id, today: d(2026, 10, 6));

        final after = await row(id);
        expect(after.status, ItemStatus.active);
        expect(after.revisitAt, isNull);
      },
    );

    test('a completed or archived item does not repeat', () async {
      final id = await captureOn(d(2026, 10, 6), 'Filter !maandelijks');
      await processor.process(id);
      await items.moveTo(id, ItemStatus.done);

      final done = await items.complete(id, today: d(2026, 10, 6));

      expect(done.repeated, isFalse);
      expect(await records(), isEmpty);
    });

    test('writes the record and the item in the change log', () async {
      final id = await captureOn(d(2026, 9, 7), 'Hardlopen !wekelijks !di');
      await processor.process(id);
      final done = await items.complete(id, today: d(2026, 9, 8));

      final log = await (db().select(
        db().changeLog,
      )..where((e) => e.entityId.equals(done.recordId!))).get();
      expect(log.single.entity, 'item_completions');
      expect(log.single.operation, ChangeOperation.insert);
    });
  });

  group('undo', () {
    test(
      'puts back status, revisit date and date, and removes the record',
      () async {
        final id = await captureOn(d(2026, 9, 7), 'Hardlopen !wekelijks !di');
        await processor.process(id);
        await items.setType(id, ItemType.task);
        await items.waitFor(id, null);
        final before = await row(id);

        final done = await items.complete(id, today: d(2026, 9, 8));
        await items.undoComplete(done);

        final after = await row(id);
        expect(after.status, before.status);
        expect(after.type, before.type);
        expect(after.dueAt, before.dueAt);
        expect(after.revisitAt, before.revisitAt);
        expect((await records()).single.deletedAt, isNotNull);
        expect(await items.watchCompletions(id).first, isEmpty);
      },
    );

    test('completing again brings the same record back', () async {
      final id = await captureOn(d(2026, 9, 7), 'Hardlopen !wekelijks !di');
      await processor.process(id);
      final first = await items.complete(id, today: d(2026, 9, 8));
      await items.undoComplete(first);

      final again = await items.complete(id, today: d(2026, 9, 9));

      expect(again.recordId, first.recordId);
      final record = (await records()).single;
      expect(record.deletedAt, isNull);
      expect(storedToDateOnly(record.completedOn), d(2026, 9, 9));
      expect(await dueOf(id), d(2026, 9, 15));
    });

    test(
      'of complete-and-repeat puts the text back, unless edited since',
      () async {
        final id = await captureOn(d(2026, 10, 6), 'Filter !6-10-2026');
        await processor.process(id);
        final done = await items.completeAndRepeat(
          id,
          rawText: 'Filter !6-10-2026 !maandelijks',
          rhythm: Rhythm.monthly,
          today: d(2026, 10, 6),
        );
        expect(done.nextDue, d(2026, 11, 6));
        await items.undoComplete(done);
        expect((await row(id)).rawText, 'Filter !6-10-2026');
        expect(await items.watchCompletions(id).first, isEmpty);

        final again = await items.completeAndRepeat(
          id,
          rawText: 'Filter !6-10-2026 !maandelijks',
          rhythm: Rhythm.monthly,
          today: d(2026, 10, 6),
        );
        await items.editText(id, 'Filter !6-10-2026 !maandelijks #huis');
        await items.undoComplete(again);
        expect((await row(id)).rawText, 'Filter !6-10-2026 !maandelijks #huis');
        expect(await items.watchCompletions(id).first, isEmpty);
      },
    );

    test('of stop-repeating puts the text and status back', () async {
      final id = await captureOn(d(2026, 9, 7), 'Hardlopen !wekelijks !di');
      await processor.process(id);
      final done = await items.stopRepeating(id, rawText: 'Hardlopen !di');
      expect((await row(id)).status, ItemStatus.done);

      await items.undoComplete(done);
      final back = await row(id);
      expect(back.rawText, 'Hardlopen !wekelijks !di');
      expect(back.status, ItemStatus.inbox);
    });

    test('of a plain completion puts back the exact status', () async {
      final id = await captureOn(d(2026, 10, 6), 'Offerte !vandaag');
      await processor.process(id);

      final done = await items.complete(id, today: d(2026, 10, 6));
      await items.undoComplete(done);

      expect(
        ItemClassification.of((await items.watchItem(id).first)!),
        done.before,
      );
    });
  });

  test('completed times are watched newest first', () async {
    final id = await captureOn(d(2026, 9, 7), 'Hardlopen !wekelijks !di');
    await processor.process(id);
    await items.complete(id, today: d(2026, 9, 8));
    await items.complete(id, today: d(2026, 9, 16));

    final times = await items.watchCompletions(id).first;
    expect(
      [for (final t in times) t.occurrenceOn],
      [d(2026, 9, 15), d(2026, 9, 8)],
    );
    expect(times.first.daysLate, 1);
  });

  test('the repeats of live items are watched', () async {
    final run = await captureOn(d(2026, 9, 7), 'Hardlopen !wekelijks !di');
    final plain = await captureOn(d(2026, 9, 7), 'Offerte !di');
    await processor.process(run);
    await processor.process(plain);

    final repeats = await items.watchRepeats().first;
    expect(repeats, {run: ItemRepeat(Rhythm.weekly, d(2026, 9, 8))});
  });

  test(
    'two devices that complete the same time make one record (Q33)',
    () async {
      final id = await captureOn(d(2026, 9, 7), 'Hardlopen !wekelijks !di');
      await processor.process(id);

      // Device B gets device A's history, as a sync would, and works out the
      // tokens itself (they are derived data, DD-003).
      final other = await AppStorage.load(AppDatabase(NativeDatabase.memory()));
      addTearDown(other.close);
      await ChangeLogReplayer(
        other.database,
      ).replay(await db().select(db().changeLog).get());
      await processorFor(other).process(id);
      final otherItems = DriftItemRepository(other);

      final onA = await items.complete(id, today: d(2026, 9, 8));
      final onB = await otherItems.complete(id, today: d(2026, 9, 8));

      expect(onB.recordId, onA.recordId);
      expect(onB.nextDue, onA.nextDue);
      expect(await dueOf(id, other.database), await dueOf(id));
      // Taken together by id, as sync will (DD-003): one record, one item.
      final byId = {
        for (final r in [...await records(), ...await records(other.database)])
          r.id: r,
      };
      expect(byId, hasLength(1));
      expect(
        await (other.database.select(other.database.items)).get(),
        hasLength(1),
      );
    },
  );

  group('ChangeLogWriter.put', () {
    test('refuses an id that is no version 5 UUID', () async {
      final id = await captureOn(d(2026, 9, 7), 'x');
      expect(
        () => storage.writer.put(
          db().itemCompletions,
          id,
          ItemCompletionsCompanion(
            itemId: Value(id),
            occurrenceOn: Value(DateTime.utc(2026, 9, 8)),
            completedOn: Value(DateTime.utc(2026, 9, 8)),
          ),
        ),
        throwsArgumentError,
      );
    });

    test(
      'inserts once, then only changes, and brings a deleted row back',
      () async {
        final item = await captureOn(d(2026, 9, 7), 'x');
        final id = completionId(item, d(2026, 9, 8));
        ItemCompletionsCompanion on(int day) => ItemCompletionsCompanion(
          itemId: Value(item),
          occurrenceOn: Value(DateTime.utc(2026, 9, 8)),
          completedOn: Value(DateTime.utc(2026, 9, day)),
        );

        expect(
          await storage.writer.put(db().itemCompletions, id, on(8)),
          isTrue,
        );
        expect(
          await storage.writer.put(db().itemCompletions, id, on(8)),
          isFalse,
        );
        await storage.writer.delete(db().itemCompletions, id);
        expect(
          await storage.writer.put(db().itemCompletions, id, on(9)),
          isTrue,
        );

        final record = (await records()).single;
        expect(record.deletedAt, isNull);
        expect(storedToDateOnly(record.completedOn), d(2026, 9, 9));
        final ops = [
          for (final e
              in await (db().select(db().changeLog)
                    ..where((e) => e.entityId.equals(id))
                    ..orderBy([(e) => OrderingTerm.asc(e.hlc)]))
                  .get())
            e.operation,
        ];
        expect(ops, [
          ChangeOperation.insert,
          ChangeOperation.delete,
          ChangeOperation.restore,
          ChangeOperation.update,
        ]);
      },
    );
  });
}
