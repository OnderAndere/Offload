import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/models/model_store.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/domain/handwriting/reading_policy.dart';
import 'package:offload/domain/models/model_catalog.dart';
import 'package:offload/l10n/app_localizations.dart';
import 'package:offload/presentation/models/model_providers.dart';
import 'package:offload/presentation/models/models_screen.dart';
import 'package:offload/presentation/startup/app_storage_provider.dart';

import '../../fakes/drift_widgets.dart';
import '../../fakes/fake_model_file_source.dart';
import '../../fakes/test_storage.dart';

/// Settings → *Models* (T6a.3, PO 11-10-2026), with a small model made up
/// for the test (the real one is 1.5 GB with fixed hashes).
void main() {
  final l10n = lookupAppLocalizations(const Locale('nl'));
  final language = Uint8List.fromList(List.generate(3000, (i) => i % 251));
  final projector = Uint8List.fromList(List.generate(1200, (i) => i % 13));
  final spec = ModelSpec(
    id: 'test-model',
    kind: ModelKind.handwriting,
    name: 'Testmodel-2B',
    source: 'Hugging Face, voorbeeld/testmodel @ abc1234',
    licence: 'Apache-2.0',
    files: [
      ModelFileSpec(
        name: 'testmodel.gguf',
        role: ModelFileRole.languageModel,
        sizeBytes: language.length,
        sha256: sha256.convert(language).toString(),
      ),
      ModelFileSpec(
        name: 'mmproj-testmodel.gguf',
        role: ModelFileRole.projector,
        sizeBytes: projector.length,
        sha256: sha256.convert(projector).toString(),
      ),
    ],
  );

  late Directory dir;
  late FakeModelFileSource source;
  late AppStorage storage;
  int? free;

  Future<void> open(WidgetTester tester) async {
    dir = Directory.systemTemp.createTempSync('models_screen_');
    addTearDown(() => dir.deleteSync(recursive: true));
    source = FakeModelFileSource();
    free = null;
    storage = await openTestStorage();
    addTearDown(storage.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appStorageProvider.overrideWith((ref) => storage),
          modelCatalogProvider.overrideWith((ref) => [spec]),
          modelFileSourceProvider.overrideWith((ref) => source),
          modelStoreProvider.overrideWith(
            (ref) => ModelStore(
              dataDirectory: () async => dir,
              source: source,
              freeBytes: (_) async => free,
            ),
          ),
        ],
        child: const MaterialApp(
          locale: Locale('nl'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: ModelsScreen(),
        ),
      ),
    );
    await settle(tester);
  }

  /// Runs the import of [picked] through the button, real file work
  /// included, until its message shows.
  Future<void> importFiles(WidgetTester tester, List<Object> picked) async {
    source.picked = picked.cast();
    await tester.tap(find.text(l10n.modelImport));
    await settle(tester);
  }

  testDriftWidgets('without the model: not imported, import offered, '
      'source and licence, accurate by default', (tester) async {
    await open(tester);
    expect(find.text(l10n.modelKindHandwriting), findsOneWidget);
    expect(find.text(l10n.modelNotImported), findsOneWidget);
    expect(
      find.text(l10n.modelSource(spec.source, spec.licence)),
      findsOneWidget,
    );
    expect(find.text(l10n.modelImport), findsOneWidget);
    expect(find.text(l10n.modelRemove), findsNothing);
    final choice = tester.widget<SegmentedButton<ReadingSpeed>>(
      find.byType(SegmentedButton<ReadingSpeed>),
    );
    expect(choice.selected, {ReadingSpeed.accurate});
  });

  testDriftWidgets('both files in one pick: ready, import gone, remove '
      'there', (tester) async {
    await open(tester);
    await importFiles(tester, [
      source.offer('download (1).bin', projector),
      source.offer('download (2).bin', language),
    ]);
    expect(find.text(l10n.modelImportReady), findsOneWidget);
    await tester.tap(find.text('OK'));
    await settle(tester);
    expect(find.text(l10n.modelReady), findsOneWidget);
    expect(find.text(l10n.modelImport), findsNothing);
    expect(find.text(l10n.modelRemove), findsOneWidget);
  });

  testDriftWidgets('one file: names the file still needed', (tester) async {
    await open(tester);
    await importFiles(tester, [source.offer('a', language)]);
    // In the message and, behind it, as the state of the model.
    expect(
      find.text(l10n.modelMissing('mmproj-testmodel.gguf')),
      findsNWidgets(2),
    );
  });

  testDriftWidgets('a file of no model is named and not kept', (tester) async {
    await open(tester);
    await importFiles(tester, [source.offer('vakantie.jpg', Uint8List(99))]);
    expect(find.text(l10n.modelImportUnknown('vakantie.jpg')), findsOneWidget);
    expect(source.copies, isEmpty);
  });

  testDriftWidgets('too little room: needed and free, nothing copied', (
    tester,
  ) async {
    await open(tester);
    free = 1000;
    await importFiles(tester, [source.offer('a', language)]);
    expect(
      find.textContaining(l10n.modelImportNoRoom('', '').split(':').first),
      findsOneWidget,
    );
    expect(source.copies, isEmpty);
  });

  testDriftWidgets('Stop during the copy: stopped, nothing kept', (
    tester,
  ) async {
    await open(tester);
    final gate = Completer<void>();
    source.gate = gate.future;
    source.picked = [source.offer('a', language)];
    await tester.tap(find.text(l10n.modelImport));
    await tester.runAsync(() => Future<void>.delayed(_fileWork));
    await tester.pump();
    expect(find.text(l10n.modelImporting), findsOneWidget);
    await tester.tap(find.text(l10n.modelImportStop));
    await tester.pump();
    gate.complete();
    await settle(tester);
    expect(find.text(l10n.modelImportStopped), findsOneWidget);
    expect(Directory('${dir.path}/models/test-model').listSync(), isEmpty);
  });

  testDriftWidgets('remove asks first, then the model is gone', (tester) async {
    await open(tester);
    await importFiles(tester, [source.offer('a', language)]);
    await tester.tap(find.text('OK'));
    await settle(tester);
    await tester.tap(find.text(l10n.modelRemove));
    await settle(tester);
    expect(find.text(l10n.modelRemoveTitle), findsOneWidget);
    await tester.tap(find.text(l10n.modelRemove).last);
    await settle(tester);
    expect(find.text(l10n.modelNotImported), findsOneWidget);
  });

  testDriftWidgets('faster is chosen and kept on this device', (tester) async {
    await open(tester);
    await tester.tap(find.text(l10n.readingSpeedFaster));
    await settle(tester);
    expect(await tester.runAsync(storage.readingSpeed), ReadingSpeed.faster);
  });
}

/// Lets the real file work of the store run (outside the test's fake
/// time) and the screen follow it.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 40; i++) {
    await tester.runAsync(() => Future<void>.delayed(_fileWork));
    await tester.pump();
  }
}

/// Long enough for a step of real file work of a small copy.
const _fileWork = Duration(milliseconds: 10);
