import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/attachments/attachment_store.dart';
import 'package:offload/data/database/app_database.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/domain/handwriting/reading_policy.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/domain/settings/language_choice.dart';
import 'package:offload/domain/settings/prefix_bar_mode.dart';
import 'package:offload/domain/sync/change_operation.dart';
import 'package:offload/domain/sync/hlc.dart';

import '../../fakes/fake_key_store.dart';

void main() {
  late Directory dir;
  late File dbFile;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('offload_storage_test');
    dbFile = File('${dir.path}${Platform.pathSeparator}offload.db');
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Future<AppStorage> open(FakeKeyStore keys) =>
      AppStorage.open(directory: dir, keyStore: keys);

  Future<String> addItem(AppStorage storage) => storage.writer.insert(
    storage.database.items,
    const ItemsCompanion(
      rawText: Value('Call Jan'),
      status: Value(ItemStatus.inbox),
      source: Value(ItemSource.app),
    ),
  );

  test('first start creates key, database and device id', () async {
    final keys = FakeKeyStore();

    final storage = await open(keys);
    await addItem(storage);
    final deviceId = storage.writer.clock.node;
    await storage.close();

    expect(keys.key, isNotNull);
    expect(keys.createCalls, 1);
    expect(dbFile.existsSync(), isTrue);
    expect(deviceId, matches(RegExp(r'^[0-9a-f]{16}$')));
    expect(Hlc.isValidNode(deviceId), isTrue);
  });

  test('opening gives the attachments key and folder and clears leftovers '
      '(T5.1)', () async {
    final folder = Directory(
      '${dir.path}${Platform.pathSeparator}${AppStorage.attachmentsFolderName}',
    )..createSync();
    final partials = Directory(
      '${folder.path}${Platform.pathSeparator}'
      '${AttachmentStore.partialFolderName}',
    )..createSync();
    final leftover = File('${partials.path}${Platform.pathSeparator}x')
      ..writeAsBytesSync([1, 2, 3]);
    final kept = File('${folder.path}${Platform.pathSeparator}kept')
      ..writeAsBytesSync([4]);

    final storage = await open(FakeKeyStore());
    addTearDown(storage.close);

    expect(storage.attachmentsKey, hasLength(32));
    expect(storage.attachmentsDirectory!.path, folder.path);
    expect(leftover.existsSync(), isFalse);
    expect(kept.existsSync(), isTrue);
  });

  test('leftovers of a version up to 0.6.2 go once, after the start, also '
      'of thumbnails (DD-006)', () async {
    String sep(String a, String b) => '$a${Platform.pathSeparator}$b';
    final folder = Directory(sep(dir.path, AppStorage.attachmentsFolderName));
    final thumbs = Directory(sep(folder.path, AppStorage.thumbnailsFolderName))
      ..createSync(recursive: true);
    const id = '0192a3b4-c5d6-7e8f-9a0b-1c2d3e4f5a6b';
    final kept = File(sep(folder.path, id))..writeAsBytesSync([4]);
    final old = File(sep(folder.path, '$id.partial'))..writeAsBytesSync([1]);
    final oldThumb = File(sep(thumbs.path, '$id.partial'))
      ..writeAsBytesSync([2]);

    final storage = await open(FakeKeyStore());
    addTearDown(storage.close);
    // Not in the start route (REQ-001).
    expect(old.existsSync(), isTrue);

    await storage.removeOldPartialFiles();
    expect(old.existsSync(), isFalse);
    expect(oldThumb.existsSync(), isFalse);
    expect(kept.existsSync(), isTrue);

    // Remembered: a later one is not looked for again.
    final later = File(sep(folder.path, '$id.partial'))..writeAsBytesSync([3]);
    await storage.removeOldPartialFiles();
    expect(later.existsSync(), isTrue);
  });

  test('a restart keeps key, device id and data', () async {
    final keys = FakeKeyStore();
    final first = await open(keys);
    final deviceId = first.writer.clock.node;
    await addItem(first);
    await first.close();

    final second = await open(keys);
    addTearDown(second.close);

    expect(keys.createCalls, 1);
    expect(second.writer.clock.node, deviceId);
    expect(
      await second.database.select(second.database.items).get(),
      hasLength(1),
    );
  });

  test('the clock continues after the newest logged change', () async {
    final keys = FakeKeyStore();
    final first = await open(keys);
    await addItem(first);
    final lastBefore = first.writer.clock.last!;
    // An entry of another device with a later time must not be taken over.
    await first.database
        .into(first.database.changeLog)
        .insert(
          ChangeLogCompanion.insert(
            id: 'other',
            entity: 'items',
            entityId: 'x',
            hlc: Hlc(lastBefore.millis + 999999, 0, 'otherdevice').pack(),
            operation: ChangeOperation.insert,
            payload: '{}',
            formatVersion: 1,
          ),
        );
    await first.close();

    final second = await open(keys);
    addTearDown(second.close);

    expect(second.writer.clock.last, lastBefore);
  });

  test('data without its key: error, no new key, file untouched', () async {
    final keys = FakeKeyStore();
    final first = await open(keys);
    await addItem(first);
    await first.close();
    final before = dbFile.readAsBytesSync();

    final withoutKey = FakeKeyStore();
    await expectLater(
      open(withoutKey),
      throwsA(
        isA<StorageOpenException>().having(
          (e) => e.failure,
          'failure',
          StorageFailure.missingKey,
        ),
      ),
    );

    expect(withoutKey.createCalls, 0);
    expect(withoutKey.key, isNull);
    expect(dbFile.readAsBytesSync(), before);
  });

  test('a leftover write-ahead log counts as data', () async {
    File('${dbFile.path}-wal').writeAsBytesSync([1, 2, 3]);
    final keys = FakeKeyStore();

    await expectLater(
      open(keys),
      throwsA(
        isA<StorageOpenException>().having(
          (e) => e.failure,
          'failure',
          StorageFailure.missingKey,
        ),
      ),
    );
    expect(keys.createCalls, 0);
  });

  test('two starts at once agree on one device id', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final [a, b] = await Future.wait([
      AppStorage.load(db),
      AppStorage.load(db),
    ]);

    expect(a.writer.clock.node, b.writer.clock.node);
  });

  test('an unreadable key is reported as such', () async {
    await expectLater(
      open(FakeKeyStore(unavailable: true)),
      throwsA(
        isA<StorageOpenException>().having(
          (e) => e.failure,
          'failure',
          StorageFailure.keyUnavailable,
        ),
      ),
    );
    expect(dbFile.existsSync(), isFalse);
  });

  test('a wrong key: database error, file untouched', () async {
    final first = await open(FakeKeyStore());
    await addItem(first);
    await first.close();
    final before = dbFile.readAsBytesSync();

    final wrong = FakeKeyStore(
      key: Uint8List.fromList(List.generate(32, (i) => i)),
    );
    await expectLater(
      open(wrong),
      throwsA(
        isA<StorageOpenException>().having(
          (e) => e.failure,
          'failure',
          StorageFailure.databaseUnavailable,
        ),
      ),
    );
    expect(dbFile.readAsBytesSync(), before);
  });

  group('language choice (REQ-029)', () {
    test('defaults to the system language', () async {
      final storage = await open(FakeKeyStore());
      addTearDown(storage.close);

      expect(storage.languageChoice, const LanguageChoice.system());
    });

    test('is kept across a restart', () async {
      final keys = FakeKeyStore();
      final first = await open(keys);
      await first.saveLanguageChoice(const LanguageChoice.language('en'));
      expect(first.languageChoice, const LanguageChoice.language('en'));
      await first.close();

      final second = await open(keys);
      expect(second.languageChoice, const LanguageChoice.language('en'));
      await second.saveLanguageChoice(const LanguageChoice.system());
      await second.close();

      final third = await open(keys);
      addTearDown(third.close);
      expect(third.languageChoice, const LanguageChoice.system());
    });

    test('is device-local: never in the change log', () async {
      final storage = await open(FakeKeyStore());
      addTearDown(storage.close);

      await storage.saveLanguageChoice(const LanguageChoice.language('nl'));

      expect(
        await storage.database.select(storage.database.changeLog).get(),
        isEmpty,
      );
    });
  });

  group('prefix bar (REQ-034)', () {
    test('defaults to always visible, not expanded', () async {
      final storage = await open(FakeKeyStore());
      addTearDown(storage.close);

      expect(storage.prefixBarMode, PrefixBarMode.always);
      expect(storage.prefixBarExpanded, isFalse);
    });

    test('mode and expanded state are kept across a restart', () async {
      final keys = FakeKeyStore();
      final first = await open(keys);
      await first.savePrefixBarMode(PrefixBarMode.collapsed);
      await first.savePrefixBarExpanded(true);
      await first.close();

      final second = await open(keys);
      addTearDown(second.close);
      expect(second.prefixBarMode, PrefixBarMode.collapsed);
      expect(second.prefixBarExpanded, isTrue);
    });

    test('is device-local: never in the change log', () async {
      final storage = await open(FakeKeyStore());
      addTearDown(storage.close);

      await storage.savePrefixBarMode(PrefixBarMode.off);
      await storage.savePrefixBarExpanded(true);

      expect(
        await storage.database.select(storage.database.changeLog).get(),
        isEmpty,
      );
    });
  });

  group('stale after (AC REQ-051)', () {
    test('3 weeks by default; kept across a restart; never logged', () async {
      final keys = FakeKeyStore();
      final first = await open(keys);
      expect(first.staleAfterWeeks, 3);
      await first.saveStaleAfterWeeks(5);
      expect(
        await first.database.select(first.database.changeLog).get(),
        isEmpty,
      );
      await first.close();

      final second = await open(keys);
      addTearDown(second.close);
      expect(second.staleAfterWeeks, 5);
      await second.saveStaleAfterWeeks(40);
      expect(second.staleAfterWeeks, 12);
    });
  });

  group('weekly review due (DD-018 point 8)', () {
    test('7 days and never reviewed by default; kept across a restart; '
        'never logged', () async {
      final keys = FakeKeyStore();
      final first = await open(keys);
      expect(first.reviewDueAfterDays, 7);
      expect(first.lastReviewCompletedAt, isNull);
      await first.saveReviewDueAfterDays(14);
      await first.saveLastReviewCompletedAt(DateTime(2026, 10, 2, 21, 30));
      expect(
        await first.database.select(first.database.changeLog).get(),
        isEmpty,
      );
      await first.close();

      final second = await open(keys);
      addTearDown(second.close);
      expect(second.reviewDueAfterDays, 14);
      expect(
        second.lastReviewCompletedAt,
        DateTime(2026, 10, 2, 21, 30).toUtc(),
      );
      expect(second.lastReviewCompletedAt!.isUtc, isTrue);
      await second.saveReviewDueAfterDays(6);
      expect(second.reviewDueAfterDays, 7);
    });
  });

  group('deadline reminders (DD-005, DD-018 point 16)', () {
    test('on at 09:00, not asked, by default; kept across a restart; never '
        'logged', () async {
      final keys = FakeKeyStore();
      final first = await open(keys);
      expect(first.remindersOn, isTrue);
      expect(first.reminderMinute, 540);
      expect(first.notificationsAsked, isFalse);
      await first.saveRemindersOn(false);
      await first.saveReminderMinute(7 * 60 + 30);
      await first.saveNotificationsAsked();
      expect(
        await first.database.select(first.database.changeLog).get(),
        isEmpty,
      );
      await first.close();

      final second = await open(keys);
      addTearDown(second.close);
      expect(second.remindersOn, isFalse);
      expect(second.reminderMinute, 450);
      expect(second.notificationsAsked, isTrue);
      await second.saveReminderMinute(24 * 60);
      expect(second.reminderMinute, 540);
    });

    test(
      'the weekly-review reminder: off, Friday 16:00 by default; kept',
      () async {
        final keys = FakeKeyStore();
        final first = await open(keys);
        expect(first.reviewReminderOn, isFalse);
        expect(first.reviewReminderWeekday, DateTime.friday);
        expect(first.reviewReminderMinute, 16 * 60);
        // Birthdays: on unless switched off (T4.6).
        expect(first.birthdayRemindersOn, isTrue);
        await first.saveBirthdayRemindersOn(false);
        await first.saveReviewReminderOn(true);
        await first.saveReviewReminderWeekday(DateTime.sunday);
        await first.saveReviewReminderMinute(19 * 60 + 30);
        await first.close();

        final second = await open(keys);
        addTearDown(second.close);
        expect(second.reviewReminderOn, isTrue);
        expect(second.reviewReminderWeekday, DateTime.sunday);
        expect(second.reviewReminderMinute, 19 * 60 + 30);
        expect(second.birthdayRemindersOn, isFalse);
        await second.saveReviewReminderWeekday(9);
        expect(second.reviewReminderWeekday, DateTime.friday);
      },
    );

    test('the size of the database file (T7.5)', () async {
      final storage = await open(FakeKeyStore());
      addTearDown(storage.close);
      await addItem(storage);
      expect(storage.databaseBytes(), greaterThan(0));
    });

    test('"Where was I" on Today: on by default; kept (T4b.2)', () async {
      final keys = FakeKeyStore();
      final first = await open(keys);
      expect(first.todayNotesOn, isTrue);
      await first.saveTodayNotesOn(false);
      await first.close();

      final second = await open(keys);
      addTearDown(second.close);
      expect(second.todayNotesOn, isFalse);
    });

    test('reading handwriting: accurate by default; kept (T6a.3)', () async {
      final keys = FakeKeyStore();
      final first = await open(keys);
      expect(await first.readingSpeed(), ReadingSpeed.accurate);
      await first.saveReadingSpeed(ReadingSpeed.faster);
      await first.close();

      final second = await open(keys);
      addTearDown(second.close);
      expect(await second.readingSpeed(), ReadingSpeed.faster);
    });
  });
}
