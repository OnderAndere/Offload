import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/handwriting/reading_image_preparer.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/domain/handwriting/straightening.dart';
import 'package:offload/l10n/app_localizations.dart';
import 'package:offload/platform/handwriting/handwriting_reader.dart';
import 'package:offload/presentation/app.dart';
import 'package:offload/presentation/capture/pending_captures.dart';
import 'package:offload/presentation/handwriting/handwriting_providers.dart';
import 'package:offload/presentation/handwriting/handwriting_screen.dart';
import 'package:offload/presentation/photos/photo_providers.dart';
import 'package:offload/presentation/startup/app_storage_provider.dart';

import '../../fakes/drift_widgets.dart';
import '../../fakes/fake_capture_channel.dart';
import '../../fakes/fake_desktop_shell.dart';
import '../../fakes/fake_handwriting_reader.dart';
import '../../fakes/fake_photo_source.dart';
import '../../fakes/fake_screen_awake.dart';
import '../../fakes/start_on_inbox.dart';
import '../../fakes/test_storage.dart';

/// The handwriting button in quick capture (T6a.4, REQ-064; PO 12-10-2026):
/// only with a model, and the text read lands in the field. Fictional
/// sample text.
void main() {
  final l10n = lookupAppLocalizations(const Locale('nl'));
  const model = HandwritingModel(
    languageModelPath: 'model.gguf',
    projectorPath: 'mmproj.gguf',
  );
  late AppStorage storage;
  late FakePhotoSource photos;
  late FakeHandwritingReader reader;

  Future<void> startApp(WidgetTester tester, {HandwritingModel? found}) async {
    tester.platformDispatcher.localesTestValue = [const Locale('nl')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    storage = await openTestStorage();
    addTearDown(storage.close);
    photos = FakePhotoSource(canTakePhoto: false);
    reader = FakeHandwritingReader();
    final image = (await tester.runAsync(
      () => createTestImage(width: 40, height: 30),
    ))!;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          startOnInbox,
          appStorageProvider.overrideWith((ref) => storage),
          captureChannelProvider.overrideWith((ref) => FakeCaptureChannel()),
          desktopShellProvider.overrideWith((ref) => FakeDesktopShell()),
          handwritingModelProvider.overrideWith((ref) async => found),
          photoSourceProvider.overrideWith((ref) => photos),
          handwritingReaderProvider.overrideWith((ref) => reader),
          screenAwakeProvider.overrideWith((ref) => FakeScreenAwake()),
          readingImagePreparerProvider.overrideWith(
            (ref) => _ReadyPreparer(WorkingPhoto(image, Uint8List(0).buffer)),
          ),
        ],
        child: const OffloadApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
  }

  Finder button() => find.byTooltip(l10n.handwritingButton);

  testDriftWidgets('without a model there is no handwriting button', (
    tester,
  ) async {
    await startApp(tester);
    expect(button(), findsNothing);
  });

  testDriftWidgets('with a model: photo, read, and the text is added in the '
      'field on a line of its own', (tester) async {
    await startApp(tester, found: model);
    expect(button(), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Boodschappen');
    await tester.pump();
    photos.next = Uint8List(8);
    reader.next = '- @ Anna bellen\n- kweekbak bouwen';

    await tester.tap(button());
    await tester.pumpAndSettle();
    expect(find.byType(HandwritingScreen), findsOneWidget);
    expect(photos.calls, ['pick']);
    await tester.tap(find.text(l10n.handwritingRead));
    await tester.pumpAndSettle();

    expect(find.byType(HandwritingScreen), findsNothing);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(
      field.controller!.text,
      'Boodschappen\n- @Anna bellen\n- kweekbak bouwen',
    );
  });

  testDriftWidgets('no photo chosen: nothing changes', (tester) async {
    await startApp(tester, found: model);
    photos.next = null;
    await tester.tap(button());
    await tester.pumpAndSettle();
    expect(find.byType(HandwritingScreen), findsNothing);
    expect(reader.calls, isEmpty);
  });
}

/// Opens on a ready photo and hands over a tiny image.
class _ReadyPreparer extends ReadingImagePreparer {
  _ReadyPreparer(this.photo);

  final WorkingPhoto photo;

  @override
  Future<WorkingPhoto> open(Uint8List bytes) async => photo;

  @override
  Future<ReadingImage> prepare(WorkingPhoto photo, Corners corners) async =>
      ReadingImage(width: 1, height: 1, rgb: Uint8List(3));
}
