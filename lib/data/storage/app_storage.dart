import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Variable;
import 'package:flutter/foundation.dart' show visibleForTesting;

import '../../domain/backup/backup.dart';
import '../../domain/ids/uuid_v7.dart';
import '../../domain/items/nudge.dart';
import '../../domain/overview/horizon.dart';
import '../../domain/people/calling_country.dart';
import '../../domain/people/person_balance.dart';
import '../../domain/reminders/day_reminders.dart';
import '../../domain/reminders/review_reminders.dart';
import '../../domain/review/weekly_review.dart';
import '../../domain/settings/language_choice.dart';
import '../../domain/settings/prefix_bar_mode.dart';
import '../../domain/sync/hlc.dart';
import '../../platform/cipher/aead_cipher.dart';
import '../../platform/key_store/key_store.dart';
import '../attachments/attachment_store.dart';
import '../backup/backup_attachments.dart';
import '../backup/backup_files.dart';
import '../crypto/crypto_service.dart';
import '../database/app_database.dart';
import '../database/database_encryption.dart';
import '../sync/change_log_writer.dart';
import 'local_state_store.dart';

/// Why the storage could not be opened. Nothing was changed or created in
/// any of these cases.
enum StorageFailure {
  /// Data exists but its master key does not (DD-007): no new key is made.
  missingKey,

  /// A master key is stored but cannot be read or unwrapped.
  keyUnavailable,

  /// The database file cannot be opened with the key.
  databaseUnavailable,
}

class StorageOpenException implements Exception {
  StorageOpenException(this.failure, this.cause);

  final StorageFailure failure;
  final Object cause;

  @override
  String toString() => 'StorageOpenException(${failure.name}): $cause';
}

/// The opened, encrypted storage of the app (REQ-004, DD-003, DD-007): the
/// database, the single write path and the device-local state.
class AppStorage {
  AppStorage._(
    this.database,
    this._localState,
    this.writer,
    this._language,
    this._prefixBarMode,
    this._prefixBarExpanded,
    this._staleAfterWeeks,
    this._reviewDueAfterDays,
    this._lastReviewCompletedAt,
    this._phoneCountry,
    this._oldAfterDays,
    this._busyFromItems,
    this._remindersOn,
    this._reminderMinute,
    this._notificationsAsked,
    this._reviewReminderOn,
    this._reviewReminderWeekday,
    this._reviewReminderMinute,
    this._birthdayRemindersOn,
    this._nudgeOn,
    this._nudgeAfterDays,
    this._todayNotesOn, [
    this._databaseFile,
    this._databaseKey,
    this.attachmentsKey,
  ]);

  static const databaseFileName = 'offload.db';

  /// A restored backup turned into a database of this device, waiting to
  /// replace [databaseFileName] (DD-007, T7.2).
  static const restoreFileName = 'offload.restore.db';

  /// The database as it was before a restore, kept (encrypted) until the
  /// restored one has opened.
  static const beforeRestoreFileName = 'offload.before-restore.db';

  /// `local_state` keys.
  static const deviceIdKey = 'device_id';
  static const languageKey = 'ui_language';
  static const prefixBarModeKey = 'prefix_bar_mode';
  static const prefixBarExpandedKey = 'prefix_bar_expanded';
  static const staleAfterWeeksKey = 'stale_after_weeks';
  static const reviewDueAfterDaysKey = 'review_due_after_days';
  static const lastReviewCompletedAtKey = 'last_review_completed_at';
  static const phoneCountryKey = 'phone_country';
  static const oldAfterDaysKey = 'old_after_days';
  static const busyFromItemsKey = 'busy_from_items';
  static const backupPassphraseKey = 'backup_passphrase';
  static const remindersOnKey = 'reminders_on';
  static const reminderMinuteKey = 'reminder_minute';
  static const notificationsAskedKey = 'notifications_asked';
  static const reviewReminderOnKey = 'review_reminder_on';
  static const reviewReminderWeekdayKey = 'review_reminder_weekday';
  static const reviewReminderMinuteKey = 'review_reminder_minute';
  static const birthdayRemindersOnKey = 'birthday_reminders_on';
  static const nudgeOnKey = 'nudge_on';
  static const nudgeAfterDaysKey = 'nudge_after_days';
  static const todayNotesOnKey = 'today_notes_on';
  static const _systemLanguage = 'system';
  static const _true = 'true';
  static const _false = 'false';

  final AppDatabase database;
  final LocalStateStore _localState;

  /// The database file and its key, for backups; null for a database not
  /// opened from a file (tests).
  final File? _databaseFile;
  final Uint8List? _databaseKey;

  /// The key of the attachment files (DD-006); each file derives its own
  /// from it. Null for a storage without files (tests).
  final Uint8List? attachmentsKey;

  /// Where the encrypted attachment files are (T5.1): `attachments` in the
  /// app's own folder. Null for a storage without files (tests).
  Directory? get attachmentsDirectory => switch (directory) {
    final folder? => Directory(
      '${folder.path}${Platform.pathSeparator}$attachmentsFolderName',
    ),
    null => null,
  };

  static const attachmentsFolderName = 'attachments';

  /// The thumbnails of photos (T5.2, DD-006/D3): derived data, inside the
  /// attachments folder so they move and go with it on a restore, and never
  /// in a backup (D7).
  static const thumbnailsFolderName = 'thumbs';

  /// The folder of photo thumbnails, or null without a database file.
  Directory? get thumbnailsDirectory => switch (attachmentsDirectory) {
    final folder? => _thumbnailsIn(folder),
    null => null,
  };

  static Directory _thumbnailsIn(Directory attachments) => Directory(
    '${attachments.path}${Platform.pathSeparator}$thumbnailsFolderName',
  );

  /// The attachments of a restore, waiting to be swapped in (T7.2b).
  static const restoreAttachmentsFolderName = 'attachments.restore';

  /// The attachments as they were before a restore, kept until the restored
  /// database has opened.
  static const beforeRestoreAttachmentsFolderName =
      'attachments.before-restore';

  /// Ids of this device's files that a restore without attachments keeps
  /// (PO 09-10-2026, option b): moved over once the restored database opens.
  static const restoreKeepListName = 'attachments.keep';

  /// The only way to change synchronisable tables (T1.5b).
  final ChangeLogWriter writer;

  LanguageChoice _language;

  /// The UI language stored on this device (REQ-029).
  LanguageChoice get languageChoice => _language;

  PrefixBarMode _prefixBarMode;
  bool _prefixBarExpanded;

  /// How the prefix bar is shown on this device (REQ-034). Read at start,
  /// so opening quick capture reads nothing from the database (REQ-001).
  PrefixBarMode get prefixBarMode => _prefixBarMode;

  /// Whether a collapsed prefix bar was last expanded (AC REQ-034).
  bool get prefixBarExpanded => _prefixBarExpanded;

  int _staleAfterWeeks;

  /// After how many weeks an untouched item is stale (AC REQ-051): a
  /// setting of this device, never synchronised (DD-018 point 8).
  int get staleAfterWeeks => _staleAfterWeeks;

  int _reviewDueAfterDays;

  /// After how many days since the last completed review a new one is due
  /// (DD-018 point 8): a setting of this device, never synchronised.
  int get reviewDueAfterDays => _reviewDueAfterDays;

  DateTime? _lastReviewCompletedAt;

  /// When a weekly review last reached its end screen on this device, in
  /// UTC; null when never (DD-018 point 8). Local state, not synchronised.
  DateTime? get lastReviewCompletedAt => _lastReviewCompletedAt;

  CallingCountry _phoneCountry;

  /// The country of phone numbers typed without a country code (T3.6,
  /// DD-012): a setting of this device, the Netherlands by default.
  CallingCountry get phoneCountry => _phoneCountry;

  int _oldAfterDays;

  /// From how many days an open item with a person is old on the balance
  /// (DD-018 point 11): a setting of this device, never synchronised.
  int get oldAfterDays => _oldAfterDays;

  int _busyFromItems;

  /// From how many items to deliver a week is busy on the Horizon (DD-018
  /// point 12): a setting of this device, never synchronised.
  int get busyFromItems => _busyFromItems;

  bool _remindersOn;

  /// Whether deadline reminders are on (DD-005, DD-018 point 16): a setting
  /// of this device, on unless switched off.
  bool get remindersOn => _remindersOn;

  int _reminderMinute;

  /// When the deadline reminder of a day comes, in minutes after local
  /// midnight ([ReminderTime]); 09:00 by default.
  int get reminderMinute => _reminderMinute;

  bool _notificationsAsked;

  /// Whether this device has asked for the notification permission: it is
  /// asked once, at the first deadline (AC REQ-020, DD-005).
  bool get notificationsAsked => _notificationsAsked;

  bool _reviewReminderOn;
  int _reviewReminderWeekday;
  int _reviewReminderMinute;

  /// Whether the weekly-review reminder is on (REQ-022, T4.4): a setting of
  /// this device, off unless switched on.
  bool get reviewReminderOn => _reviewReminderOn;

  /// Its weekday, Monday 1 ... Sunday 7; Friday by default.
  int get reviewReminderWeekday => _reviewReminderWeekday;

  /// Its time, in minutes after local midnight; 16:00 by default.
  int get reviewReminderMinute => _reviewReminderMinute;

  bool _birthdayRemindersOn;

  /// Whether birthdays are reminded (REQ-031, T4.6): a setting of this
  /// device, on unless switched off.
  bool get birthdayRemindersOn => _birthdayRemindersOn;

  bool _nudgeOn;
  int _nudgeAfterDays;

  /// Whether a silent waiting item gets a notification (AC REQ-047,
  /// T10.1): a setting of this device, on unless switched off.
  bool get nudgeOn => _nudgeOn;

  /// After how many days without a touch a waiting item is silent
  /// ([NudgeAfter]); 7 by default. It counts for *Today* too.
  int get nudgeAfterDays => _nudgeAfterDays;

  bool _todayNotesOn;

  bool _restoreUndone = false;

  /// Whether this opening put the data from before a restore back, as the
  /// restored database did not open (DD-007): the app says so once.
  bool get restoreUndone => _restoreUndone;

  /// Sets [restoreUndone] for a test of the screen that tells it.
  @visibleForTesting
  set restoreUndoneForTest(bool value) => _restoreUndone = value;

  /// Whether the open "Where was I" notes show on *Today* (T4b.2): a
  /// setting of this device, on unless switched off (PO 09-10-2026).
  bool get todayNotesOn => _todayNotesOn;

  /// Opens the encrypted database in [directory], creating it and the
  /// master key on the very first start.
  ///
  /// The database file existing counts as "data found": then a missing key
  /// is an error, never a reason for a new key and an empty database.
  /// Throws [StorageOpenException].
  static Future<AppStorage> open({
    required Directory directory,
    required KeyStore keyStore,
    Random? random,
  }) async {
    final file = File(
      '${directory.path}${Platform.pathSeparator}$databaseFileName',
    );
    try {
      _finishInterruptedRestore(directory);
    } on FileSystemException catch (e) {
      // A file held by another program (Windows): the next start retries.
      throw StorageOpenException(StorageFailure.databaseUnavailable, e);
    }
    final CryptoService crypto;
    try {
      crypto = await CryptoService.unlock(
        keyStore,
        // A leftover write-ahead log is data too.
        existingDataFound:
            file.existsSync() || File('${file.path}-wal').existsSync(),
        random: random,
      );
    } on MissingMasterKeyException catch (e) {
      throw StorageOpenException(StorageFailure.missingKey, e);
    } on KeyStoreException catch (e) {
      throw StorageOpenException(StorageFailure.keyUnavailable, e);
    }
    final key = crypto.deriveKey(KeyPurpose.database);
    // A write stopped halfway left only ciphertext; it goes (T5.1), also
    // of a thumbnail (T5.2).
    final attachments = Directory(
      '${directory.path}${Platform.pathSeparator}$attachmentsFolderName',
    );
    AttachmentStore.removeLeftoversIn(attachments);
    AttachmentStore.removeLeftoversIn(_thumbnailsIn(attachments));
    final database = AppDatabase(openEncryptedDatabase(file, key));
    final AppStorage storage;
    try {
      storage = await load(
        database,
        random: random,
        databaseFile: file,
        databaseKey: key,
        attachmentsKey: crypto.deriveKey(KeyPurpose.attachments),
      );
    } catch (e) {
      try {
        await database.close();
      } catch (_) {
        // The open error below is the one that matters.
      }
      // A restored database that does not open: the previous one, kept for
      // this, comes back, so a bad backup never costs the data (DD-007).
      if (_in(directory, beforeRestoreFileName).existsSync()) {
        try {
          undoRestore(directory);
        } on FileSystemException catch (e) {
          // A file held by another program (Windows): the next start
          // finishes the undo.
          throw StorageOpenException(StorageFailure.databaseUnavailable, e);
        }
        // Said once the app has started (T7.2 follow-up): the data is safe,
        // but the restore the user asked for did not happen.
        return (await open(
          directory: directory,
          keyStore: keyStore,
          random: random,
        )).._restoreUndone = true;
      }
      throw StorageOpenException(StorageFailure.databaseUnavailable, e);
    }
    // The restored database opened: the commit point of a restore. The
    // database from before it goes first, so nothing after this is ever
    // rolled back (review T7.2b); then the attachments a restore keeps move
    // over and the folder from before it goes. Both are safe to repeat: a
    // failure (a file held on Windows) fails this start, never the data, and
    // the next start finishes them.
    try {
      for (final name in _fileSet(beforeRestoreFileName)) {
        _deleteIfThere(_in(directory, name));
      }
      _settleRestoredAttachments(directory);
    } on FileSystemException catch (e) {
      await storage.close();
      throw StorageOpenException(StorageFailure.databaseUnavailable, e);
    }
    return storage;
  }

  /// Reads the device-local state of an opened [database]: the device id
  /// (created on first use), the clock and the language choice.
  static Future<AppStorage> load(
    AppDatabase database, {
    Random? random,
    File? databaseFile,
    Uint8List? databaseKey,
    Uint8List? attachmentsKey,
  }) async {
    final localState = LocalStateStore(database);
    // Insert only if absent, then read back: if two instances start at once,
    // both end up with the id that was stored first.
    await localState.writeIfAbsent(
      deviceIdKey,
      _newDeviceId(random ?? Random.secure()),
    );
    final deviceId = (await localState.read(deviceIdKey))!;
    final clock = HlcClock(
      node: deviceId,
      last: await _lastHlc(database, deviceId),
    );
    return AppStorage._(
      database,
      localState,
      ChangeLogWriter(database, clock: clock, ids: UuidV7Generator()),
      _parseLanguage(await localState.read(languageKey)),
      PrefixBarMode.parse(await localState.read(prefixBarModeKey)),
      await localState.read(prefixBarExpandedKey) == _true,
      StaleAfter.parse(await localState.read(staleAfterWeeksKey)),
      ReviewDueAfter.parse(await localState.read(reviewDueAfterDaysKey)),
      DateTime.tryParse(
        await localState.read(lastReviewCompletedAtKey) ?? '',
      )?.toUtc(),
      callingCountryOf(await localState.read(phoneCountryKey)),
      OldAfter.parse(await localState.read(oldAfterDaysKey)),
      BusyFrom.parse(await localState.read(busyFromItemsKey)),
      await localState.read(remindersOnKey) != _false,
      ReminderTime.parse(await localState.read(reminderMinuteKey)),
      await localState.read(notificationsAskedKey) == _true,
      await localState.read(reviewReminderOnKey) == _true,
      ReviewReminderSetting.parseWeekday(
        await localState.read(reviewReminderWeekdayKey),
      ),
      ReviewReminderSetting.parseMinute(
        await localState.read(reviewReminderMinuteKey),
      ),
      await localState.read(birthdayRemindersOnKey) != _false,
      await localState.read(nudgeOnKey) != _false,
      NudgeAfter.parse(await localState.read(nudgeAfterDaysKey)),
      await localState.read(todayNotesOnKey) != _false,
      databaseFile,
      databaseKey,
      attachmentsKey,
    );
  }

  Future<void> saveLanguageChoice(LanguageChoice choice) async {
    await _localState.write(
      languageKey,
      choice.languageCode ?? _systemLanguage,
    );
    _language = choice;
  }

  Future<void> savePrefixBarMode(PrefixBarMode mode) async {
    await _localState.write(prefixBarModeKey, mode.name);
    _prefixBarMode = mode;
  }

  Future<void> savePrefixBarExpanded(bool expanded) async {
    await _localState.write(prefixBarExpandedKey, expanded ? _true : _false);
    _prefixBarExpanded = expanded;
  }

  /// Stores [weeks], kept within the allowed range.
  Future<void> saveStaleAfterWeeks(int weeks) async {
    final kept = StaleAfter.parse('$weeks');
    await _localState.write(staleAfterWeeksKey, '$kept');
    _staleAfterWeeks = kept;
  }

  /// Stores [days], or the default when it is not one of the choices.
  Future<void> saveReviewDueAfterDays(int days) async {
    final kept = ReviewDueAfter.parse('$days');
    await _localState.write(reviewDueAfterDaysKey, '$kept');
    _reviewDueAfterDays = kept;
  }

  Future<void> saveOldAfterDays(int days) async {
    final kept = OldAfter.parse('$days');
    await _localState.write(oldAfterDaysKey, '$kept');
    _oldAfterDays = kept;
  }

  Future<void> saveRemindersOn(bool on) async {
    await _localState.write(remindersOnKey, on ? _true : _false);
    _remindersOn = on;
  }

  /// Stores [minutes] after midnight, or 09:00 when it is no time of day.
  Future<void> saveReminderMinute(int minutes) async {
    final kept = ReminderTime.parse('$minutes');
    await _localState.write(reminderMinuteKey, '$kept');
    _reminderMinute = kept;
  }

  Future<void> saveReviewReminderOn(bool on) async {
    await _localState.write(reviewReminderOnKey, on ? _true : _false);
    _reviewReminderOn = on;
  }

  Future<void> saveNudgeOn(bool on) async {
    await _localState.write(nudgeOnKey, on ? _true : _false);
    _nudgeOn = on;
  }

  /// Stores [days], or the default when it is no choice.
  Future<void> saveNudgeAfterDays(int days) async {
    final kept = NudgeAfter.parse(days.toString());
    await _localState.write(nudgeAfterDaysKey, '$kept');
    _nudgeAfterDays = kept;
  }

  Future<void> saveTodayNotesOn(bool on) async {
    await _localState.write(todayNotesOnKey, on ? _true : _false);
    _todayNotesOn = on;
  }

  Future<void> saveBirthdayRemindersOn(bool on) async {
    await _localState.write(birthdayRemindersOnKey, on ? _true : _false);
    _birthdayRemindersOn = on;
  }

  /// Stores [weekday], or Friday when it is no weekday.
  Future<void> saveReviewReminderWeekday(int weekday) async {
    final kept = ReviewReminderSetting.parseWeekday(weekday.toString());
    await _localState.write(reviewReminderWeekdayKey, '$kept');
    _reviewReminderWeekday = kept;
  }

  /// Stores [minutes] after midnight, or 16:00 when it is no time of day.
  Future<void> saveReviewReminderMinute(int minutes) async {
    final kept = ReviewReminderSetting.parseMinute(minutes.toString());
    await _localState.write(reviewReminderMinuteKey, '$kept');
    _reviewReminderMinute = kept;
  }

  /// The notification permission has been asked; it is not asked again.
  Future<void> saveNotificationsAsked() async {
    await _localState.write(notificationsAskedKey, _true);
    _notificationsAsked = true;
  }

  /// Stores [count], or the default when it is out of range.
  Future<void> saveBusyFromItems(int count) async {
    final kept = BusyFrom.parse('$count');
    await _localState.write(busyFromItemsKey, '$kept');
    _busyFromItems = kept;
  }

  Future<void> savePhoneCountry(CallingCountry country) async {
    await _localState.write(phoneCountryKey, country.isoCode);
    _phoneCountry = country;
  }

  Future<void> saveLastReviewCompletedAt(DateTime moment) async {
    final utc = moment.toUtc();
    await _localState.write(lastReviewCompletedAtKey, utc.toIso8601String());
    _lastReviewCompletedAt = utc;
  }

  /// Closes the database; once, however often it is called (a restore
  /// closes it before the app's own clean-up does).
  Future<void> close() => _closing ??= database.close();
  Future<void>? _closing;

  /// The folder of the database file, for a restore; null for a database not
  /// opened from a file (tests).
  Directory? get directory => _databaseFile?.parent;

  /// The size on disk of the database with its companion files (T7.5);
  /// 0 for a database without a file (tests in memory).
  int databaseBytes() {
    final directory = this.directory;
    if (directory == null) return 0;
    var total = 0;
    for (final name in _fileSet(databaseFileName)) {
      final file = _in(directory, name);
      if (file.existsSync()) total += file.lengthSync();
    }
    return total;
  }

  /// Whether a backup passphrase is set on this device (T7.1).
  Future<bool> hasBackupPassphrase() async =>
      await _localState.read(backupPassphraseKey) != null;

  /// Sets or changes the backup passphrase of this device (REQ-026). It is
  /// kept in `local_state`, inside the encrypted database, and never goes
  /// into a backup. Throws [BackupException] when it is too short.
  Future<void> saveBackupPassphrase(String passphrase) async {
    final problem = passphraseProblem(passphrase);
    if (problem != null) throw BackupException(problem);
    await _localState.write(backupPassphraseKey, passphrase);
  }

  /// Writes a backup of everything to [target] with this device's
  /// passphrase (T7.2). With [cipher] (the maker of the platform cipher for
  /// the backup's isolate) the attachments go in too, with [onProgress]
  /// hearing the bytes done and the total (T7.2b). Throws [BackupException].
  Future<BackupAttachmentsResult> makeBackup(
    File target, {
    AeadCipher Function()? cipher,
    void Function(int done, int total)? onProgress,
  }) async {
    final passphrase = await _localState.read(backupPassphraseKey);
    if (passphrase == null) {
      throw const BackupException(BackupProblem.noPassphrase);
    }
    final folder = attachmentsDirectory;
    final key = attachmentsKey;
    return BackupFiles.write(
      database: _fileOrThrow(),
      key: _databaseKey!,
      passphrase: passphrase,
      target: target,
      attachments: cipher == null || folder == null || key == null
          ? null
          : BackupAttachmentSource(
              directoryPath: folder.path,
              key: key,
              cipher: cipher,
            ),
      onProgress: onProgress,
    );
  }

  /// Turns the backup [backup] into a database of this device, next to the
  /// current one, without replacing anything yet (T7.2). Tries this device's
  /// own passphrase first, so restoring here asks nothing (PO 03-10-2026),
  /// then [passphrase]. This device keeps its own `local_state` but gets a
  /// new device id when the restored database opens (SPEC Q15). Throws
  /// [BackupException]; [BackupProblem.wrongPassphrase] means: ask for it.
  ///
  /// The attachments are prepared too (T7.2b): from the backup when it has
  /// them, which needs [cipher] (the maker of the platform cipher for the
  /// restore's isolate); otherwise a list of this device's files to keep.
  /// [onProgress] hears the attachment bytes done and the total.
  Future<BackupInfo> prepareRestore(
    File backup, {
    String? passphrase,
    AeadCipher Function()? cipher,
    void Function(int done, int total)? onProgress,
  }) async {
    final file = _fileOrThrow();
    final key = attachmentsKey;
    final folder = file.parent;
    final attachments = key == null
        ? null
        : RestoreAttachmentTarget(
            currentPath: _folderIn(folder, attachmentsFolderName).path,
            stagingPath: _folderIn(folder, restoreAttachmentsFolderName).path,
            keepListPath: _in(folder, restoreKeepListName).path,
            key: key,
            cipher: cipher,
          );
    final own = await _localState.read(backupPassphraseKey);
    final tries = [
      ?own,
      if (passphrase != null && passphrase != own) passphrase,
    ];
    if (tries.isEmpty) {
      throw const BackupException(BackupProblem.wrongPassphrase);
    }
    final state = await _localState.all()
      ..remove(deviceIdKey);
    BackupException? last;
    for (final phrase in tries) {
      try {
        return await BackupFiles.prepareRestore(
          backup: backup,
          passphrase: phrase,
          key: _databaseKey!,
          target: _in(file.parent, restoreFileName),
          appSchemaVersion: database.schemaVersion,
          localState: state,
          attachments: attachments,
          onProgress: onProgress,
        );
      } on BackupException catch (e) {
        if (e.problem != BackupProblem.wrongPassphrase) rethrow;
        last = e;
      }
    }
    throw last!;
  }

  /// Puts the restore made by [prepareRestore] in place of the database in
  /// [directory]; the storage must be closed first. The previous database is
  /// kept until the restored one has opened ([open] removes it then).
  static void finishRestore(Directory directory) {
    final restore = _in(directory, restoreFileName);
    if (!restore.existsSync()) {
      throw const BackupException(BackupProblem.unreadable);
    }
    for (final (index, name) in _fileSet(databaseFileName).indexed) {
      final from = _in(directory, name);
      if (!from.existsSync()) continue;
      from.renameSync(
        _in(directory, _fileSet(beforeRestoreFileName)[index]).path,
      );
    }
    // A journal of the restore copy was never part of it.
    for (final name in _fileSet(restoreFileName).skip(1)) {
      _deleteIfThere(_in(directory, name));
    }
    restore.renameSync(_in(directory, databaseFileName).path);
    _swapRestoredAttachments(directory);
  }

  /// Drops a restore prepared but not confirmed.
  static void discardRestore(Directory directory) {
    for (final name in _fileSet(restoreFileName)) {
      _deleteIfThere(_in(directory, name));
    }
    _deleteFolder(_folderIn(directory, restoreAttachmentsFolderName));
    _deleteIfThere(_in(directory, restoreKeepListName));
  }

  /// Puts the attachments of a restore in place, after the database: the
  /// folder in use becomes the one from before the restore (kept until the
  /// restored database opens). Safe to run again after an interruption.
  static void _swapRestoredAttachments(Directory directory) {
    final restored = _folderIn(directory, restoreAttachmentsFolderName);
    if (!restored.existsSync()) return;
    final current = _folderIn(directory, attachmentsFolderName);
    final before = _folderIn(directory, beforeRestoreAttachmentsFolderName);
    if (current.existsSync()) {
      // An open that succeeds leaves no folder from before a restore (it
      // settles it), and a restore is only prepared on an open storage: one
      // left here belongs to nothing.
      _deleteFolder(before);
      current.renameSync(before.path);
    }
    restored.renameSync(current.path);
  }

  /// After the restored database opened: this device's files on the keep
  /// list move over from the folder from before the restore, then that
  /// folder goes. Safe to run again after an interruption.
  static void _settleRestoredAttachments(Directory directory) {
    final before = _folderIn(directory, beforeRestoreAttachmentsFolderName);
    final keep = _in(directory, restoreKeepListName);
    if (keep.existsSync()) {
      final current = _folderIn(directory, attachmentsFolderName)
        ..createSync(recursive: true);
      for (final id in keep.readAsLinesSync()) {
        if (!AttachmentStore.isValidId(id)) continue;
        final from = _in(before, id);
        final to = _in(current, id);
        if (from.existsSync() && !to.existsSync()) from.renameSync(to.path);
      }
      keep.deleteSync();
    }
    _deleteFolder(before);
  }

  /// Puts the database from before a restore back, when the restored one
  /// did not open; the storage must be closed.
  ///
  /// The restored database goes first: stopped after any step, the next
  /// start finds no database and runs this again, so a restored database
  /// never opens beside the folder from before it, and the folder from
  /// before a restore never stays beside the database from before it, which
  /// an open would take for a committed restore and remove (review T7.2b).
  ///
  /// Within each set the companion files go before the main file, so the
  /// main database file tells where a stop came: there, the restored one is
  /// still being removed; gone, the companions in its place are already the
  /// ones from before the restore (a `-wal` holds data) and stay.
  static void undoRestore(Directory directory) {
    final before = _in(directory, beforeRestoreFileName);
    if (!before.existsSync()) return;
    if (_in(directory, databaseFileName).existsSync()) {
      for (final name in _fileSet(databaseFileName).reversed) {
        _deleteIfThere(_in(directory, name));
      }
    }
    final attachmentsBefore = _folderIn(
      directory,
      beforeRestoreAttachmentsFolderName,
    );
    if (attachmentsBefore.existsSync()) {
      final current = _folderIn(directory, attachmentsFolderName);
      _deleteFolder(current);
      attachmentsBefore.renameSync(current.path);
    }
    _deleteFolder(_folderIn(directory, restoreAttachmentsFolderName));
    _deleteIfThere(_in(directory, restoreKeepListName));
    for (final (index, name) in _fileSet(
      beforeRestoreFileName,
    ).indexed.toList().reversed) {
      final from = _in(directory, name);
      if (from.existsSync()) {
        from.renameSync(_in(directory, _fileSet(databaseFileName)[index]).path);
      }
    }
  }

  /// A restore stopped halfway (the app was closed during the swap): no
  /// database but a restore waiting finishes it, as the user confirmed it;
  /// no database but one from before puts that back. A restore never
  /// swapped in is dropped.
  static void _finishInterruptedRestore(Directory directory) {
    final database = _in(directory, databaseFileName);
    final restore = _in(directory, restoreFileName);
    if (!database.existsSync()) {
      if (restore.existsSync()) {
        // The move of the previous database stopped after its file: its
        // companions follow it, never deleted (data, DD-007).
        for (final (index, name) in _fileSet(databaseFileName).indexed) {
          final from = _in(directory, name);
          if (index == 0 || !from.existsSync()) continue;
          from.renameSync(
            _in(directory, _fileSet(beforeRestoreFileName)[index]).path,
          );
        }
        restore.renameSync(database.path);
      } else {
        undoRestore(directory);
      }
    }
    for (final name in _fileSet(restoreFileName)) {
      _deleteIfThere(_in(directory, name));
    }
    // The attachments follow the database: swapped in when the restored
    // database is in place (the one from before it is still kept), dropped
    // when the restore was never swapped in.
    if (_in(directory, beforeRestoreFileName).existsSync()) {
      _swapRestoredAttachments(directory);
    } else {
      _deleteFolder(_folderIn(directory, restoreAttachmentsFolderName));
      // A folder from before a restore with no database from before it: the
      // restore was committed (its database opened) and is still settling;
      // its keep list stays for [open] to finish.
      if (!_folderIn(
        directory,
        beforeRestoreAttachmentsFolderName,
      ).existsSync()) {
        _deleteIfThere(_in(directory, restoreKeepListName));
      }
    }
  }

  File _fileOrThrow() {
    final file = _databaseFile;
    if (file == null || _databaseKey == null) {
      throw const BackupException(BackupProblem.unreadable);
    }
    return file;
  }

  /// A database file with its rollback journal, write-ahead log and shared
  /// memory.
  static List<String> _fileSet(String name) => [
    name,
    '$name-journal',
    '$name-wal',
    '$name-shm',
  ];

  static File _in(Directory directory, String name) =>
      File('${directory.path}${Platform.pathSeparator}$name');

  static Directory _folderIn(Directory directory, String name) =>
      Directory('${directory.path}${Platform.pathSeparator}$name');

  static void _deleteFolder(Directory folder) {
    if (folder.existsSync()) folder.deleteSync(recursive: true);
  }

  static void _deleteIfThere(File file) {
    if (file.existsSync()) file.deleteSync();
  }

  /// 64 random bits as 16 hex digits: ASCII without "-", as a HLC node
  /// must be (DD-003).
  static String _newDeviceId(Random random) => [
    for (var i = 0; i < 8; i++)
      random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ].join();

  /// The newest HLC this device wrote, read from the change log. The log is
  /// written in the same transaction as every change, so unlike a separately
  /// stored value it can never lag behind after a crash.
  static Future<Hlc?> _lastHlc(AppDatabase database, String node) async {
    // The node is the tail of the packed form: `<millis>-<counter>-<node>`.
    final nodeStart = Hlc(0, 0, node).pack().length - node.length + 1;
    final row = await database
        .customSelect(
          'SELECT hlc FROM change_log WHERE substr(hlc, ?) = ? '
          'ORDER BY hlc DESC LIMIT 1',
          variables: [Variable<int>(nodeStart), Variable<String>(node)],
          readsFrom: {database.changeLog},
        )
        .getSingleOrNull();
    return row == null ? null : Hlc.parse(row.read<String>('hlc'));
  }

  static LanguageChoice _parseLanguage(String? stored) =>
      stored == null || stored == _systemLanguage
      ? const LanguageChoice.system()
      : LanguageChoice.language(stored);
}
