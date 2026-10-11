import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/database/app_database.dart';
import 'package:offload/data/items/drift_item_repository.dart';
import 'package:offload/data/models/model_store.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/domain/models/model_catalog.dart';
import 'package:offload/l10n/app_localizations.dart';
import 'package:offload/presentation/app.dart';
import 'package:offload/presentation/app_directory_provider.dart';
import 'package:offload/presentation/capture/pending_captures.dart';
import 'package:offload/presentation/models/model_providers.dart';
import 'package:offload/presentation/settings/settings_screen.dart';
import 'package:offload/presentation/startup/app_storage_provider.dart';

import '../../fakes/drift_widgets.dart';
import '../../fakes/fake_app_directory.dart';
import '../../fakes/fake_capture_channel.dart';
import '../../fakes/fake_desktop_shell.dart';
import '../../fakes/fake_model_file_source.dart';
import '../../fakes/test_storage.dart';

/// Settings → Storage (*Opslag*; T7.5, PO decisions 09-10-2026).
void main() {
  late AppStorage storage;
  final l10n = lookupAppLocalizations(const Locale('nl'));

  Future<void> openStorage(
    WidgetTester tester, {
    int? temporaryBytes,
    bool failTemporary = false,
    Future<void> Function()? seed,
    List<Override> extra = const [],
  }) async {
    tester.platformDispatcher.localesTestValue = const [Locale('nl')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    storage = await openTestStorage();
    addTearDown(storage.close);
    await seed?.call();
    final directory = FakeAppDirectory(Directory.systemTemp)
      ..temporaryBytes = temporaryBytes
      ..failTemporary = failTemporary;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appStorageProvider.overrideWith((ref) => storage),
          captureChannelProvider.overrideWith((ref) => FakeCaptureChannel()),
          desktopShellProvider.overrideWith((ref) => FakeDesktopShell()),
          appDirectoryProvider.overrideWith((ref) => directory),
          ...extra,
        ],
        child: const OffloadApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text(l10n.storageContent),
      200,
      scrollable: find
          .descendant(
            of: find.byType(SettingsScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
  }

  testDriftWidgets('database, temporary files and the content, trash '
      'included', (tester) async {
    await openStorage(
      tester,
      temporaryBytes: 2500,
      seed: () async {
        final items = DriftItemRepository(storage);
        await items.capture('Offerte kozijnen', source: ItemSource.app);
        await items.moveToTrash(
          await items.capture('Weg', source: ItemSource.app),
        );
      },
    );

    expect(find.text(l10n.settingsStorageHeader), findsOneWidget);
    expect(find.text(l10n.storageDatabase), findsOneWidget);
    expect(find.text(l10n.storageTemporary), findsOneWidget);
    expect(find.text('3 kB'), findsOneWidget);
    expect(
      find.text(
        '2 items, waarvan 1 in de prullenbak · 0 projecten · 0 personen',
      ),
      findsOneWidget,
    );
  });

  testDriftWidgets('attachments: one row with the size per kind (T5.1)', (
    tester,
  ) async {
    await openStorage(
      tester,
      seed: () async {
        final db = storage.database;
        final item = await DriftItemRepository(
          storage,
        ).capture('Kozijnen', source: ItemSource.app);
        for (final (mime, size) in [
          ('image/jpeg', 1500000),
          ('audio/mp4', 30000000),
        ]) {
          await storage.writer.insert(
            db.attachments,
            AttachmentsCompanion(
              itemId: Value(item),
              mimeType: Value(mime),
              sizeBytes: Value(size),
              storagePath: const Value('attachments/x'),
              pipelineVersion: const Value(0),
            ),
          );
        }
      },
    );

    expect(find.text(l10n.storageAttachments), findsOneWidget);
    expect(find.text("Foto's 1,5 MB · Audio 30,0 MB"), findsOneWidget);
    expect(find.text('31,5 MB'), findsOneWidget);
  });

  testDriftWidgets('no attachments row without attachments', (tester) async {
    await openStorage(tester);
    expect(find.text(l10n.storageAttachments), findsNothing);
  });

  testDriftWidgets('no temporary files row where the platform keeps none', (
    tester,
  ) async {
    await openStorage(tester);

    expect(find.text(l10n.storageTemporary), findsNothing);
    expect(find.text('0 items · 0 projecten · 0 personen'), findsOneWidget);
  });

  testDriftWidgets('temporary files that cannot be measured say so (review)', (
    tester,
  ) async {
    await openStorage(tester, failTemporary: true);

    expect(find.text(l10n.storageTemporary), findsOneWidget);
    expect(find.text(l10n.storageUnavailable), findsOneWidget);
  });

  testDriftWidgets('imported models: a row with their size '
      '(T6a.3)', (tester) async {
    final models = Directory.systemTemp.createTempSync('storage_models_');
    addTearDown(() => models.deleteSync(recursive: true));
    const spec = ModelSpec(
      id: 'm',
      kind: ModelKind.handwriting,
      name: 'M',
      source: 'here',
      licence: 'MIT',
      files: [
        ModelFileSpec(
          name: 'm.gguf',
          role: ModelFileRole.languageModel,
          sizeBytes: 2500,
          sha256: 'aa',
        ),
      ],
    );
    Directory('${models.path}/models/m').createSync(recursive: true);
    File(
      '${models.path}/models/m/m.gguf',
    ).writeAsBytesSync(List.filled(2500, 1));
    await openStorage(
      tester,
      extra: [
        modelCatalogProvider.overrideWith((ref) => [spec]),
        modelStoreProvider.overrideWith(
          (ref) => ModelStore(
            dataDirectory: () async => models,
            source: FakeModelFileSource(),
            freeBytes: (_) async => null,
          ),
        ),
      ],
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
    expect(find.text(l10n.storageModels), findsOneWidget);
    expect(find.text(l10n.storageModelsHint), findsOneWidget);
    expect(find.text('3 kB'), findsOneWidget);
  });
}
