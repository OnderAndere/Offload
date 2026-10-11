import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/items/drift_item_repository.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/domain/backup/backup.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/domain/people/calling_country.dart';
import 'package:offload/domain/settings/language_choice.dart';

import '../../fakes/fake_key_store.dart';

/// Making and restoring a backup through the storage (T7.1, T7.2, REQ-014,
/// REQ-026, DD-007, SPEC Q15).
void main() {
  const passphrase = 'vier losse woorden hier';
  late Directory root;
  late Directory phone;
  late Directory tablet;
  late File backup;
  final phoneKeys = FakeKeyStore();
  final tabletKeys = FakeKeyStore();

  setUp(() {
    root = Directory.systemTemp.createTempSync('offload_restore_test');
    phone = Directory('${root.path}/phone')..createSync();
    tablet = Directory('${root.path}/tablet')..createSync();
    backup = File('${root.path}/Offload-back-up.offload');
    phoneKeys.key = null;
    tabletKeys.key = null;
  });
  tearDown(() => root.deleteSync(recursive: true));

  Future<AppStorage> open(Directory dir, FakeKeyStore keys) =>
      AppStorage.open(directory: dir, keyStore: keys);

  Future<List<String>> texts(AppStorage s) async => [
    for (final i in await s.database.select(s.database.items).get()) i.rawText,
  ];

  Future<String?> deviceId(AppStorage s) async =>
      (await s.database.select(s.database.localState).get())
          .where((r) => r.key == AppStorage.deviceIdKey)
          .single
          .value;

  BackupProblem? problemOf(Object e) => e is BackupException ? e.problem : null;

  Future<String> phoneBackup() async {
    final s = await open(phone, phoneKeys);
    await DriftItemRepository(s).capture('Нова кухня', source: ItemSource.app);
    await s.saveBackupPassphrase(passphrase);
    await s.saveLanguageChoice(const LanguageChoice.language('en'));
    await s.makeBackup(backup);
    final id = (await deviceId(s))!;
    await s.close();
    return id;
  }

  test('a passphrase shorter than 12 characters is not saved', () async {
    final s = await open(phone, phoneKeys);
    addTearDown(s.close);
    await expectLater(
      s.saveBackupPassphrase('te kort'),
      throwsA(isA<BackupException>()),
    );
    expect(await s.hasBackupPassphrase(), isFalse);
  });

  test('no passphrase, no backup', () async {
    final s = await open(phone, phoneKeys);
    addTearDown(s.close);
    await expectLater(
      s.makeBackup(backup),
      throwsA(predicate((e) => problemOf(e!) == BackupProblem.noPassphrase)),
    );
  });

  test('on another device: asked once, then everything is there', () async {
    final phoneId = await phoneBackup();

    var t = await open(tablet, tabletKeys);
    await DriftItemRepository(
      t,
    ).capture('Alleen tablet', source: ItemSource.app);
    await t.savePhoneCountry(callingCountryOf('BE'));
    final tabletId = (await deviceId(t))!;
    // The tablet has no passphrase of its own: it must be asked for.
    await expectLater(
      t.prepareRestore(backup),
      throwsA(predicate((e) => problemOf(e!) == BackupProblem.wrongPassphrase)),
    );
    final info = await t.prepareRestore(backup, passphrase: passphrase);
    expect(info.items, 1);
    // Nothing replaced yet.
    expect(await texts(t), ['Alleen tablet']);
    await t.close();

    AppStorage.finishRestore(tablet);
    t = await open(tablet, tabletKeys);
    addTearDown(t.close);

    expect(await texts(t), ['Нова кухня']);
    final newId = await deviceId(t);
    expect(newId, isNot(tabletId));
    expect(newId, isNot(phoneId));
    // The tablet's own settings stay; the phone's do not come along.
    expect(t.phoneCountry.isoCode, 'BE');
    expect(t.languageChoice, const LanguageChoice.system());
    expect(await t.hasBackupPassphrase(), isFalse);
    // The previous database is gone once the restored one opened.
    expect(
      File('${tablet.path}/${AppStorage.beforeRestoreFileName}').existsSync(),
      isFalse,
    );
  });

  test('on the same device: its own passphrase, nothing asked', () async {
    final phoneId = await phoneBackup();
    var s = await open(phone, phoneKeys);
    await DriftItemRepository(
      s,
    ).capture('Na de back-up', source: ItemSource.app);
    await s.prepareRestore(backup);
    await s.close();

    AppStorage.finishRestore(phone);
    s = await open(phone, phoneKeys);
    addTearDown(s.close);
    expect(await texts(s), ['Нова кухня']);
    expect(await deviceId(s), isNot(phoneId));
    expect(await s.hasBackupPassphrase(), isTrue);
    expect(s.languageChoice, const LanguageChoice.language('en'));
  });

  test('a swap stopped halfway is finished at the next start', () async {
    await phoneBackup();
    final s = await open(phone, phoneKeys);
    await s.prepareRestore(backup);
    await s.close();
    // The app stopped right after moving the old database aside.
    File(
      '${phone.path}/${AppStorage.databaseFileName}',
    ).renameSync('${phone.path}/${AppStorage.beforeRestoreFileName}');

    final again = await open(phone, phoneKeys);
    addTearDown(again.close);
    expect(await texts(again), ['Нова кухня']);
  });

  test('a restore never swapped in is dropped at the next start', () async {
    await phoneBackup();
    var s = await open(phone, phoneKeys);
    await DriftItemRepository(s).capture('Blijft', source: ItemSource.app);
    await s.prepareRestore(backup);
    await s.close();

    s = await open(phone, phoneKeys);
    addTearDown(s.close);
    expect(await texts(s), containsAll(['Нова кухня', 'Blijft']));
    expect(
      File('${phone.path}/${AppStorage.restoreFileName}').existsSync(),
      isFalse,
    );
  });

  test('undo puts the previous database back', () async {
    await phoneBackup();
    final s = await open(phone, phoneKeys);
    await DriftItemRepository(s).capture('Vorige', source: ItemSource.app);
    await s.prepareRestore(backup);
    await s.close();
    AppStorage.finishRestore(phone);

    AppStorage.undoRestore(phone);
    final back = await open(phone, phoneKeys);
    addTearDown(back.close);
    expect(await texts(back), containsAll(['Нова кухня', 'Vorige']));
    // Undone by hand here, not by a failed open: nothing to tell.
    expect(back.restoreUndone, isFalse);
  });

  group('undo keeps the companion files from before (review T7.2b)', () {
    const main = AppStorage.databaseFileName;
    const old = AppStorage.beforeRestoreFileName;

    void write(String name, String content) =>
        File('${phone.path}/$name').writeAsStringSync(content);
    String? read(String name) {
      final file = File('${phone.path}/$name');
      return file.existsSync() ? file.readAsStringSync() : null;
    }

    test('the restored files go, the ones from before take their place', () {
      write(main, 'restored');
      write('$main-journal', 'restored journal');
      write(old, 'previous');
      write('$old-wal', 'previous wal');

      AppStorage.undoRestore(phone);

      expect(read(main), 'previous');
      expect(read('$main-wal'), 'previous wal');
      expect(read('$main-journal'), isNull);
      expect(read(old), isNull);
      expect(read('$old-wal'), isNull);
    });

    test('stopped after a companion moved back: running again keeps it', () {
      // The restored database is gone and the `-wal` from before already
      // has its old name back; the main file from before has not.
      write('$main-wal', 'previous wal');
      write(old, 'previous');

      AppStorage.undoRestore(phone);

      expect(read(main), 'previous');
      expect(read('$main-wal'), 'previous wal');
      expect(read(old), isNull);
    });

    test('stopped while removing the restored files: running again removes '
        'the rest', () {
      // The restored `-journal` went first; its main file is still there.
      write(main, 'restored');
      write(old, 'previous');
      write('$old-journal', 'previous journal');

      AppStorage.undoRestore(phone);

      expect(read(main), 'previous');
      expect(read('$main-journal'), 'previous journal');
      expect(read(old), isNull);
    });
  });

  test('the device key never leaves: a backup is no database file', () async {
    await phoneBackup();
    final bytes = backup.readAsBytesSync();
    expect(String.fromCharCodes(bytes.take(16)), isNot('SQLite format 3\x00'));
    expect(phoneKeys.key, isA<Uint8List>());
  });

  test('the app keeps writing while a backup is made (review)', () async {
    final s = await open(phone, phoneKeys);
    addTearDown(s.close);
    final items = DriftItemRepository(s);
    for (var i = 0; i < 50; i++) {
      await items.capture('Item $i', source: ItemSource.app);
    }
    await s.saveBackupPassphrase(passphrase);

    final making = s.makeBackup(backup);
    // Captures during the copy wait for its lock instead of failing.
    final writes = [
      for (var i = 0; i < 5; i++)
        items.capture('Tijdens $i', source: ItemSource.app),
    ];
    await Future.wait([making, ...writes]);

    expect(await texts(s), hasLength(55));
    expect(backup.existsSync(), isTrue);
  });

  test('a passphrase with a control character is not saved', () async {
    final s = await open(phone, phoneKeys);
    addTearDown(s.close);
    await expectLater(
      s.saveBackupPassphrase('twee regels\nin een wachtwoord'),
      throwsA(
        predicate((e) => problemOf(e!) == BackupProblem.passphraseInvalid),
      ),
    );
  });

  test(
    'a restored database that does not open gives the previous back',
    () async {
      final s = await open(phone, phoneKeys);
      await DriftItemRepository(s).capture('Veilig', source: ItemSource.app);
      await s.close();
      // A "restore" that is no database of this device.
      File(
        '${phone.path}/${AppStorage.restoreFileName}',
      ).writeAsStringSync('stuk');
      AppStorage.finishRestore(phone);

      final back = await open(phone, phoneKeys);
      addTearDown(back.close);
      expect(await texts(back), ['Veilig']);
    },
  );

  test('closing twice is harmless', () async {
    final s = await open(phone, phoneKeys);
    await s.close();
    await s.close();
    expect(s.directory?.path, phone.path);
  });
}
