import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/backup/backup_attachments.dart';
import 'package:offload/data/database/app_database.dart';
import 'package:offload/data/items/drift_item_repository.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/domain/backup/backup.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/l10n/app_localizations.dart';
import 'package:offload/platform/share/share_channel.dart';
import 'package:offload/presentation/app.dart';
import 'package:offload/presentation/app_directory_provider.dart';
import 'package:offload/presentation/backup/backup_file_picker_provider.dart';
import 'package:offload/presentation/backup/backup_section.dart';
import 'package:offload/presentation/backup/busy_dialog.dart';
import 'package:offload/presentation/capture/pending_captures.dart';
import 'package:offload/presentation/settings/settings_screen.dart';
import 'package:offload/presentation/share_channel_provider.dart';
import 'package:offload/presentation/startup/app_storage_provider.dart';

import '../../fakes/drift_widgets.dart';
import '../../fakes/fake_app_directory.dart';
import '../../fakes/fake_backup_file_picker.dart';
import '../../fakes/fake_capture_channel.dart';
import '../../fakes/fake_desktop_shell.dart';
import '../../fakes/fake_share_channel.dart';
import '../../fakes/test_storage.dart';

/// Settings → Back-up (T7.1, T7.2, AC REQ-026).
void main() {
  late AppStorage storage;
  late FakeBackupFilePicker picker;
  late FakeShareChannel share;
  final l10n = lookupAppLocalizations(const Locale('nl'));

  /// Settings on a platform that shares files when [sharesFiles] (Android),
  /// else one that only saves them (Windows).
  Future<void> openSettings(
    WidgetTester tester, {
    bool sharesFiles = false,
    int? freeBytes,
    Directory? onDisk,
  }) async {
    picker = FakeBackupFilePicker(Directory.systemTemp)..cancel = true;
    share = FakeShareChannel(
      fileTargets: sharesFiles ? const [ShareTarget.system] : const [],
    );
    final appDirectory = FakeAppDirectory(Directory.systemTemp)
      ..free = freeBytes;
    tester.platformDispatcher.localesTestValue = const [Locale('nl')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    // In memory either way; [onDisk] gives it a folder, which a restore
    // needs (a file database would run in an isolate the fake time stalls).
    storage = onDisk == null
        ? await openTestStorage()
        : await AppStorage.load(
            AppDatabase(NativeDatabase.memory()),
            databaseFile: File('${onDisk.path}/${AppStorage.databaseFileName}'),
          );
    addTearDown(storage.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appStorageProvider.overrideWith((ref) => storage),
          captureChannelProvider.overrideWith((ref) => FakeCaptureChannel()),
          desktopShellProvider.overrideWith((ref) => FakeDesktopShell()),
          backupFilePickerProvider.overrideWith((ref) => picker),
          shareChannelProvider.overrideWith((ref) => share),
          appDirectoryProvider.overrideWith((ref) => appDirectory),
        ],
        child: const OffloadApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
  }

  Future<void> openPassphrase(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.text(l10n.backupPassphraseRow),
      200,
      scrollable: find
          .descendant(
            of: find.byType(SettingsScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.ensureVisible(find.text(l10n.backupPassphraseRow));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.backupPassphraseRow));
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.widgetWithText(TextField, label);

  FilledButton saveButton(WidgetTester tester) => tester.widget<FilledButton>(
    find.widgetWithText(FilledButton, l10n.backupSave),
  );

  testDriftWidgets('the section shows; no passphrase yet', (tester) async {
    await openSettings(tester);
    await tester.scrollUntilVisible(
      find.text(l10n.backupRestore),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text(l10n.settingsBackupHeader), findsOneWidget);
    expect(find.text(l10n.backupPassphraseNotSet), findsOneWidget);
    expect(find.text(l10n.backupMake), findsOneWidget);
  });

  testDriftWidgets('saving needs twice the same, 12 characters and the '
      'warning confirmed', (tester) async {
    await openSettings(tester);
    await openPassphrase(tester);

    expect(find.text(l10n.backupPassphraseWarning), findsOneWidget);
    await tester.enterText(field(l10n.backupPassphraseField), 'kort');
    await tester.pump();
    expect(find.textContaining('te kort'), findsOneWidget);
    expect(saveButton(tester).onPressed, isNull);

    await tester.enterText(
      field(l10n.backupPassphraseField),
      'vier losse woorden hier',
    );
    await tester.enterText(field(l10n.backupPassphraseRepeat), 'iets anders');
    await tester.pump();
    expect(find.text(l10n.backupPassphraseMismatch), findsOneWidget);

    await tester.enterText(
      field(l10n.backupPassphraseRepeat),
      'vier losse woorden hier',
    );
    await tester.pump();
    // Not yet: the warning is not confirmed.
    expect(saveButton(tester).onPressed, isNull);

    await tester.tap(find.text(l10n.backupPassphraseWarningConfirm));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, l10n.backupSave));
    await tester.pumpAndSettle();

    expect(await storage.hasBackupPassphrase(), isTrue);
    expect(find.text(l10n.backupPassphraseSaved), findsOneWidget);
    expect(find.text(l10n.backupPassphraseSet), findsOneWidget);
  });

  testDriftWidgets('changing says older backups keep the old one', (
    tester,
  ) async {
    await openSettings(tester);
    await storage.saveBackupPassphrase('vier losse woorden hier');
    await openPassphrase(tester);
    expect(find.text(l10n.backupPassphraseChangeNote), findsOneWidget);
  });

  Future<void> tapMake(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.text(l10n.backupMake),
      200,
      scrollable: find
          .descendant(
            of: find.byType(SettingsScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.ensureVisible(find.text(l10n.backupMake));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.backupMake));
    await tester.pumpAndSettle();
  }

  testDriftWidgets('a backup without a passphrase asks for one first', (
    tester,
  ) async {
    await openSettings(tester);
    await tapMake(tester);
    expect(find.text(l10n.backupPassphraseTitle), findsOneWidget);
  });

  group('where the backup goes (DD-014)', () {
    testDriftWidgets('where files are not shared, it goes straight to the '
        'save window', (tester) async {
      await openSettings(tester);
      await storage.saveBackupPassphrase('vier losse woorden hier');
      await tapMake(tester);

      expect(find.text(l10n.backupShare), findsNothing);
      expect(picker.suggestedNames, hasLength(1));
    });

    testDriftWidgets('where files are shared, a sheet offers share and save', (
      tester,
    ) async {
      await openSettings(tester, sharesFiles: true);
      await storage.saveBackupPassphrase('vier losse woorden hier');
      await tapMake(tester);

      expect(find.text(l10n.backupShare), findsOneWidget);
      expect(find.text(l10n.backupSaveOnDevice), findsOneWidget);
      expect(picker.suggestedNames, isEmpty);
      expect(share.sharedFiles, isEmpty);
    });

    testDriftWidgets('share hands the backup file to the share menu', (
      tester,
    ) async {
      await openSettings(tester, sharesFiles: true);
      await storage.saveBackupPassphrase('vier losse woorden hier');
      await tapMake(tester);
      await tester.tap(find.text(l10n.backupShare));
      await tester.pumpAndSettle();

      final shared = share.sharedFiles.single;
      expect(
        shared.fileName,
        matches(RegExp(r'^Offload-back-up-\d{4}-\d{2}-\d{2}\.offload$')),
      );
      expect(shared.mimeType, 'application/octet-stream');
      expect(shared.target, ShareTarget.system);
      expect(shared.subject, shared.fileName.replaceFirst('.offload', ''));
      expect(picker.suggestedNames, isEmpty);
      expect(find.text(l10n.backupReadyToShare), findsOneWidget);
    });

    testDriftWidgets('save on this device opens the save window', (
      tester,
    ) async {
      await openSettings(tester, sharesFiles: true);
      await storage.saveBackupPassphrase('vier losse woorden hier');
      await tapMake(tester);
      await tester.tap(find.text(l10n.backupSaveOnDevice));
      await tester.pumpAndSettle();

      expect(picker.suggestedNames, hasLength(1));
      expect(share.sharedFiles, isEmpty);
    });

    testDriftWidgets('closing the sheet makes nothing', (tester) async {
      await openSettings(tester, sharesFiles: true);
      await storage.saveBackupPassphrase('vier losse woorden hier');
      await tapMake(tester);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.text(l10n.backupShare), findsNothing);
      expect(picker.suggestedNames, isEmpty);
      expect(share.sharedFiles, isEmpty);
    });

    testDriftWidgets('a failed share says so', (tester) async {
      await openSettings(tester, sharesFiles: true);
      share.fail = true;
      await storage.saveBackupPassphrase('vier losse woorden hier');
      await tapMake(tester);
      await tester.tap(find.text(l10n.backupShare));
      await tester.pumpAndSettle();

      expect(find.text(l10n.backupFailed), findsOneWidget);
      expect(find.text(l10n.backupReadyToShare), findsNothing);
    });
  });

  group('with attachments (T7.2b, DD-007 points 5 and 7)', () {
    /// An attachment record of [bytes] (its file does not matter here).
    Future<void> addAttachment(int bytes) async {
      final db = storage.database;
      final item = await DriftItemRepository(
        storage,
      ).capture('Kozijnen', source: ItemSource.app);
      await storage.writer.insert(
        db.attachments,
        AttachmentsCompanion(
          itemId: Value(item),
          mimeType: const Value('audio/mp4'),
          sizeBytes: Value(bytes),
          storagePath: const Value('attachments/x'),
          pipelineVersion: const Value(0),
        ),
      );
    }

    testDriftWidgets('no attachments: no choice, straight on', (tester) async {
      await openSettings(tester);
      await storage.saveBackupPassphrase('vier losse woorden hier');
      await tapMake(tester);

      expect(find.byType(SwitchListTile), findsNothing);
      expect(picker.suggestedNames, hasLength(1));
    });

    testDriftWidgets('with attachments: the switch with their size, on', (
      tester,
    ) async {
      await openSettings(tester);
      await storage.saveBackupPassphrase('vier losse woorden hier');
      await addAttachment(85000000);
      await tapMake(tester);

      expect(find.text(l10n.backupWithAttachments('85,0 MB')), findsOneWidget);
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isTrue,
      );
      expect(picker.suggestedNames, isEmpty);

      await tester.tap(find.text(l10n.backupOptionsContinue));
      await tester.pumpAndSettle();
      expect(picker.suggestedNames, hasLength(1));
    });

    testDriftWidgets('cancelling the choice makes nothing', (tester) async {
      await openSettings(tester);
      await storage.saveBackupPassphrase('vier losse woorden hier');
      await addAttachment(3000000);
      await tapMake(tester);
      await tester.tap(find.text(l10n.backupCancel));
      await tester.pumpAndSettle();

      expect(picker.suggestedNames, isEmpty);
    });

    testDriftWidgets('too little free space: said, nothing written', (
      tester,
    ) async {
      await openSettings(tester, freeBytes: 1000000);
      picker
        ..cancel = false
        ..savedName = 'no-room-test.offload';
      if (picker.saved.existsSync()) picker.saved.deleteSync();
      await storage.saveBackupPassphrase('vier losse woorden hier');
      await tapMake(tester);

      expect(find.textContaining('Niet genoeg vrije ruimte'), findsOneWidget);
      expect(find.textContaining('vrij 1,0 MB'), findsOneWidget);
      expect(picker.saved.existsSync(), isFalse);
    });

    testDriftWidgets('restoring with too little free space: said, nothing '
        'prepared', (tester) async {
      final root = Directory.systemTemp.createTempSync('offload_no_room');
      addTearDown(() => root.deleteSync(recursive: true));
      final data = Directory('${root.path}/data')..createSync();
      const name = 'no-room-restore-test.offload';
      final source = File('${Directory.systemTemp.path}/$name')
        ..writeAsBytesSync(List.filled(4096, 1));
      addTearDown(source.deleteSync);
      await openSettings(tester, freeBytes: 1000, onDisk: data);
      picker
        ..cancel = false
        ..openName = name;
      await tester.scrollUntilVisible(
        find.text(l10n.backupRestore),
        200,
        scrollable: find
            .descendant(
              of: find.byType(SettingsScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.ensureVisible(find.text(l10n.backupRestore));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.backupRestore));
      await tester.pumpAndSettle();

      expect(find.textContaining('Niet genoeg vrije ruimte'), findsOneWidget);
      expect(find.text(l10n.backupRestoreConfirmTitle), findsNothing);
      expect(
        File('${data.path}/${AppStorage.restoreFileName}').existsSync(),
        isFalse,
      );
    });

    group('the texts (DD-007 points 2 and 7c)', () {
      BackupInfo info({required bool withAttachments, int attachments = 0}) => (
        schemaVersion: 13,
        items: 1,
        newestChange: null,
        withAttachments: withAttachments,
        attachments: attachments,
      );

      test('a backup with attachments names them; with none, nothing', () {
        expect(
          BackupSection.restoreAttachmentsLine(
            info(withAttachments: true, attachments: 3),
            deviceHasAttachments: true,
            l10n: l10n,
          ),
          'Met 3 bijlagen.',
        );
        expect(
          BackupSection.restoreAttachmentsLine(
            info(withAttachments: true, attachments: 1),
            deviceHasAttachments: false,
            l10n: l10n,
          ),
          'Met 1 bijlage.',
        );
        expect(
          BackupSection.restoreAttachmentsLine(
            info(withAttachments: true),
            deviceHasAttachments: true,
            l10n: l10n,
          ),
          isNull,
        );
      });

      test('a device without the handwriting model hears it is imported '
          'again; one with it hears nothing (T6a.3)', () {
        expect(
          BackupSection.restoreModelLine(deviceHasModel: false, l10n: l10n),
          l10n.backupRestoreModelHint,
        );
        expect(
          BackupSection.restoreModelLine(deviceHasModel: true, l10n: l10n),
          isNull,
        );
      });

      test('a backup without attachments warns only when this device has '
          'some (option b)', () {
        expect(
          BackupSection.restoreAttachmentsLine(
            info(withAttachments: false),
            deviceHasAttachments: true,
            l10n: l10n,
          ),
          l10n.backupRestoreNoAttachments,
        );
        expect(
          BackupSection.restoreAttachmentsLine(
            info(withAttachments: false),
            deviceHasAttachments: false,
            l10n: l10n,
          ),
          isNull,
        );
      });

      test('the message after a backup counts the missing attachments', () {
        BackupAttachmentsResult made(int missing) =>
            BackupAttachmentsResult(copied: 2, missing: missing, bytes: 10);
        expect(
          BackupSection.madeText(l10n.backupMade, made(1), l10n),
          'Back-up gemaakt. 1 bijlage ontbrak en zit er niet in.',
        );
        expect(
          BackupSection.madeText(l10n.backupMade, made(2), l10n),
          'Back-up gemaakt. 2 bijlagen ontbraken en zitten er niet in.',
        );
        expect(
          BackupSection.madeText(l10n.backupMade, made(0), l10n),
          l10n.backupMade,
        );
        expect(
          BackupSection.madeText(l10n.backupMade, null, l10n),
          l10n.backupMade,
        );
      });
    });

    testWidgets('progress shows as "12 MB van 85 MB" once it is large', (
      tester,
    ) async {
      final work = Completer<void>();
      final progress = ValueNotifier<(int, int)?>(null);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('nl'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => busy(context, work.future, progress: progress),
              child: const Text('start'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('start'));
      await tester.pump();
      expect(find.text(l10n.backupBusy), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);

      // A small total keeps the plain "one moment".
      progress.value = (1000, busyProgressFrom - 1);
      await tester.pump();
      expect(find.byType(LinearProgressIndicator), findsNothing);

      progress.value = (12000000, 85000000);
      await tester.pump();
      expect(find.text('12,0 MB van 85,0 MB'), findsOneWidget);
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .value,
        closeTo(12 / 85, 1e-9),
      );

      work.complete();
      await tester.pumpAndSettle();
      expect(find.text(l10n.backupBusy), findsNothing);
    });
  });

  group('export (T7.3)', () {
    Future<void> tapExport(WidgetTester tester) async {
      await tester.scrollUntilVisible(
        find.text(l10n.exportRow),
        200,
        scrollable: find
            .descendant(
              of: find.byType(SettingsScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.ensureVisible(find.text(l10n.exportRow));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.exportRow));
      await tester.pumpAndSettle();
    }

    final datedName = RegExp(r'^Offload-export-\d{4}-\d{2}-\d{2}');

    testDriftWidgets('the section is "Back-up en export" with the row', (
      tester,
    ) async {
      await openSettings(tester);
      await tester.scrollUntilVisible(
        find.text(l10n.exportRow),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Back-up en export'), findsOneWidget);
      expect(find.text(l10n.exportRowSubtitle), findsOneWidget);
    });

    testDriftWidgets('the dialog warns every time; closing exports nothing', (
      tester,
    ) async {
      await openSettings(tester);
      await tapExport(tester);
      expect(find.text(l10n.exportWarning), findsOneWidget);
      expect(find.text(l10n.exportMarkdown), findsOneWidget);
      expect(find.text(l10n.exportJson), findsOneWidget);
      await tester.tap(find.text(l10n.backupCancel));
      await tester.pumpAndSettle();
      expect(picker.savedFiles, isEmpty);

      await tapExport(tester);
      expect(find.text(l10n.exportWarning), findsOneWidget);
    });

    testDriftWidgets('where files are not shared: Markdown goes to the save '
        'window', (tester) async {
      await openSettings(tester);
      await tapExport(tester);
      await tester.tap(find.widgetWithText(FilledButton, l10n.exportConfirm));
      await tester.pumpAndSettle();

      expect(find.text(l10n.backupShare), findsNothing);
      final saved = picker.savedFiles.single;
      expect(saved.name, matches(datedName));
      expect(saved.name, endsWith('.md'));
      expect(saved.mimeType, 'text/markdown');
    });

    testDriftWidgets('JSON when chosen', (tester) async {
      await openSettings(tester);
      await tapExport(tester);
      await tester.tap(find.text(l10n.exportJson));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, l10n.exportConfirm));
      await tester.pumpAndSettle();

      expect(picker.savedFiles.single.name, endsWith('.json'));
      expect(picker.savedFiles.single.mimeType, 'application/json');
    });

    testDriftWidgets('where files are shared: the sheet, then the share menu', (
      tester,
    ) async {
      await openSettings(tester, sharesFiles: true);
      await tapExport(tester);
      await tester.tap(find.widgetWithText(FilledButton, l10n.exportConfirm));
      await tester.pumpAndSettle();
      expect(find.text(l10n.backupSaveOnDevice), findsOneWidget);
      await tester.tap(find.text(l10n.backupShare));
      await tester.pumpAndSettle();

      final shared = share.sharedFiles.single;
      expect(shared.fileName, matches(datedName));
      expect(shared.fileName, endsWith('.md'));
      expect(shared.mimeType, 'text/markdown');
      expect(picker.savedFiles, isEmpty);
      expect(find.text(l10n.exportReadyToShare), findsOneWidget);
    });

    testDriftWidgets('a failed export says so', (tester) async {
      await openSettings(tester, sharesFiles: true);
      share.fail = true;
      await tapExport(tester);
      await tester.tap(find.widgetWithText(FilledButton, l10n.exportConfirm));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.backupShare));
      await tester.pumpAndSettle();

      expect(find.text(l10n.exportFailed), findsOneWidget);
    });
  });
}
