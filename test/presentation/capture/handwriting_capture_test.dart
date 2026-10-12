import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/database/app_database.dart';
import 'package:offload/data/handwriting/reading_image_preparer.dart';
import 'package:offload/data/items/drift_item_repository.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/domain/handwriting/straightening.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/l10n/app_localizations.dart';
import 'package:offload/platform/handwriting/handwriting_reader.dart';
import 'package:offload/presentation/app.dart';
import 'package:offload/presentation/capture/capture_screen.dart';
import 'package:offload/presentation/capture/pending_captures.dart';
import 'package:offload/presentation/handwriting/handwriting_providers.dart';
import 'package:offload/presentation/handwriting/handwriting_screen.dart';
import 'package:offload/presentation/handwriting/thoughts_review_screen.dart';
import 'package:offload/presentation/items/item_providers.dart';
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
  late _HeldSave repository;

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
          itemRepositoryProvider.overrideWith(
            (ref) => repository = _HeldSave(ref.watch(storageProvider)),
          ),
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

  /// Takes a photo through the button, reads [reading] and waits on the
  /// review screen.
  Future<void> readToReview(WidgetTester tester, String reading) async {
    photos.next = Uint8List(8);
    reader.next = reading;
    await tester.tap(button());
    await tester.pumpAndSettle();
    expect(find.byType(HandwritingScreen), findsOneWidget);
    await tester.tap(find.text(l10n.handwritingRead));
    await tester.pumpAndSettle();
    expect(find.byType(ThoughtsReviewScreen), findsOneWidget);
  }

  Future<List<Item>> storedItems() =>
      storage.database.select(storage.database.items).get();

  testDriftWidgets('with a model: photo, read, review, and each kept thought '
      'is an inbox item; capture closes with a message', (tester) async {
    await startApp(tester, found: model);
    expect(button(), findsOneWidget);
    await readToReview(
      tester,
      '- @ Anna bellen\n- kweekbak bouwen\n  van oude planken\n- tegels',
    );
    expect(photos.calls, ['pick']);
    expect(find.text(l10n.reviewThoughtsIntro(3)), findsOneWidget);
    expect(find.text(l10n.reviewThoughtsSave(3)), findsOneWidget);

    // Correct the second thought, skip the third.
    await tester.enterText(
      find.widgetWithText(TextField, 'kweekbak bouwen van oude planken'),
      'kweekbak bouwen #tuin',
    );
    await tester.pump();
    await tester.tap(find.byType(Checkbox).last);
    await tester.pump();
    expect(find.text(l10n.reviewThoughtsSave(2)), findsOneWidget);
    expect(await tester.runAsync(storedItems), isEmpty);

    await tester.tap(find.text(l10n.reviewThoughtsSave(2)));
    await tester.pumpAndSettle();

    final items = (await tester.runAsync(storedItems))!;
    expect([for (final i in items) i.rawText]..sort(), [
      '@Anna bellen',
      'kweekbak bouwen #tuin',
    ]);
    for (final item in items) {
      expect(item.source, ItemSource.handwriting);
      expect(item.status, ItemStatus.inbox);
    }
    expect(find.byType(ThoughtsReviewScreen), findsNothing);
    expect(find.byType(HandwritingScreen), findsNothing);
    expect(find.byType(CaptureScreen), findsNothing);
    expect(find.text(l10n.handwritingSaved(2)), findsOneWidget);
  });

  testDriftWidgets('text typed in capture stays, and capture stays open', (
    tester,
  ) async {
    await startApp(tester, found: model);
    await tester.enterText(find.byType(TextField), 'Boodschappen');
    await tester.pump();
    await readToReview(tester, '- zaaien');
    await tester.tap(find.text(l10n.reviewThoughtsSave(1)));
    await tester.pumpAndSettle();

    expect(find.byType(CaptureScreen), findsOneWidget);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, 'Boodschappen');
    expect(find.text(l10n.handwritingSaved(1)), findsOneWidget);
    expect(
      [for (final i in (await tester.runAsync(storedItems))!) i.rawText],
      ['zaaien'],
    );
  });

  testDriftWidgets(
    'Windows: the first thought has the focus, and Ctrl+Enter saves',
    (tester) async {
      await startApp(tester, found: model);
      await readToReview(tester, '- zaaien\n- snoeien');
      final first = tester.widget<EditableText>(
        find.byType(EditableText).first,
      );
      expect(first.focusNode.hasFocus, isTrue);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(await tester.runAsync(storedItems), hasLength(2));
      expect(find.text(l10n.handwritingSaved(2)), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );

  testDriftWidgets('Android: no field takes the focus, so the keyboard does '
      'not cover the thoughts', (tester) async {
    await startApp(tester, found: model);
    await readToReview(tester, '- zaaien\n- snoeien');
    for (final field in tester.widgetList<EditableText>(
      find.byType(EditableText),
    )) {
      expect(field.focusNode.hasFocus, isFalse);
    }
  });

  testDriftWidgets('a save that fails keeps the thoughts, says so, and can '
      'be tried again', (tester) async {
    await startApp(tester, found: model);
    await readToReview(tester, '- zaaien\n- snoeien');
    repository.fail = true;
    await tester.tap(find.text(l10n.reviewThoughtsSave(2)));
    await tester.pumpAndSettle();
    expect(find.text(l10n.reviewThoughtsSaveFailed), findsOneWidget);
    expect(find.byType(ThoughtsReviewScreen), findsOneWidget);
    expect(await tester.runAsync(storedItems), isEmpty);

    repository.fail = false;
    await tester.tap(find.text(l10n.reviewThoughtsSave(2)));
    await tester.pumpAndSettle();
    expect(await tester.runAsync(storedItems), hasLength(2));
    expect(find.byType(ThoughtsReviewScreen), findsNothing);
  });

  testDriftWidgets('back while saving does nothing: the save ends as '
      'usual, with its message', (tester) async {
    await startApp(tester, found: model);
    await readToReview(tester, '- zaaien');
    repository.hold = Completer<void>();
    await tester.tap(find.text(l10n.reviewThoughtsSave(1)));
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(ThoughtsReviewScreen), findsOneWidget);
    repository.hold!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(ThoughtsReviewScreen), findsNothing);
    expect(find.byType(HandwritingScreen), findsNothing);
    expect(find.text(l10n.handwritingSaved(1)), findsOneWidget);
    expect(await tester.runAsync(storedItems), hasLength(1));
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

/// The real repository, whose `captureAll` can fail or wait on request.
class _HeldSave extends DriftItemRepository {
  _HeldSave(super.storage);

  bool fail = false;
  Completer<void>? hold;

  @override
  Future<List<String>> captureAll(
    List<String> rawTexts, {
    required ItemSource source,
  }) async {
    if (hold case final wait?) await wait.future;
    if (fail) throw StateError('disk full');
    return super.captureAll(rawTexts, source: source);
  }
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
