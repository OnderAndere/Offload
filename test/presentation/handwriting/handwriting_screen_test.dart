import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/handwriting/reading_image_preparer.dart';
import 'package:offload/domain/handwriting/reading_policy.dart';
import 'package:offload/domain/handwriting/straightening.dart';
import 'package:offload/l10n/app_localizations.dart';
import 'package:offload/platform/handwriting/handwriting_reader.dart';
import 'package:offload/presentation/handwriting/corners_editor.dart';
import 'package:offload/presentation/handwriting/handwriting_providers.dart';
import 'package:offload/presentation/handwriting/handwriting_screen.dart';
import 'package:offload/presentation/models/model_providers.dart';

import '../../fakes/fake_handwriting_reader.dart';
import '../../fakes/fake_screen_awake.dart';

/// The photo screen (T6a.4, REQ-064, DD-021; PO 12-10-2026): corners,
/// reading with progress, stop, the 5-minute stop counted in the app, and
/// back to the corners after a stop or a failure. Fictional sample text.
void main() {
  final l10n = lookupAppLocalizations(const Locale('nl'));
  const model = HandwritingModel(
    languageModelPath: 'model.gguf',
    projectorPath: 'mmproj.gguf',
  );

  late FakeHandwritingReader reader;
  late FakeScreenAwake awake;
  late _FakePreparer preparer;
  late Duration now;
  String? result;
  bool closed = false;

  Future<void> open(WidgetTester tester, {bool pausesOutsideApp = true}) async {
    reader = FakeHandwritingReader(pausesOutsideApp: pausesOutsideApp);
    awake = FakeScreenAwake();
    final image = (await tester.runAsync(
      () => createTestImage(width: 200, height: 150),
    ))!;
    preparer = _FakePreparer(WorkingPhoto(image, Uint8List(0).buffer));
    now = Duration.zero;
    result = null;
    closed = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          handwritingReaderProvider.overrideWith((ref) => reader),
          screenAwakeProvider.overrideWith((ref) => awake),
          readingImagePreparerProvider.overrideWith((ref) => preparer),
          readingTimeSourceProvider.overrideWith(
            (ref) =>
                () => now,
          ),
          readingSpeedProvider.overrideWith(_Faster.new),
        ],
        child: MaterialApp(
          locale: const Locale('nl'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await Navigator.of(context).push<String>(
                    MaterialPageRoute(
                      builder: (_) =>
                          HandwritingScreen(photo: Uint8List(4), model: model),
                    ),
                  );
                  closed = true;
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> tapRead(WidgetTester tester) async {
    await tester.tap(find.text(l10n.handwritingRead));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('opens on the whole photo: hint, read, nothing to reset', (
    tester,
  ) async {
    await open(tester);
    expect(find.byType(CornersEditor), findsOneWidget);
    expect(find.text(l10n.handwritingCornersHint), findsOneWidget);
    final reset = tester.widget<TextButton>(
      find.widgetWithText(TextButton, l10n.handwritingResetCorners),
    );
    expect(reset.onPressed, isNull);
  });

  testWidgets('reads with progress and the screen on, then closes with the '
      'text cleaned up', (tester) async {
    await open(tester);
    reader
      ..hold = true
      ..progress = const [ReadingProgress(ReadingPhase.encoding, 0)]
      ..next = '- @ Anna bellen\n-\n- tegels ×3\n';
    await tapRead(tester);
    expect(find.text(l10n.handwritingWait), findsOneWidget);
    expect(find.text(l10n.handwritingPhaseEncoding), findsOneWidget);
    expect(find.text(l10n.handwritingStop), findsOneWidget);
    expect(awake.isAwake, isTrue);
    expect(preparer.prepared, Corners.whole);
    expect(reader.calls.single.speed, ReadingSpeed.faster);

    now = const Duration(seconds: 75);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text(l10n.handwritingElapsed('1', '15')), findsOneWidget);

    reader.release();
    await tester.pumpAndSettle();
    expect(closed, isTrue);
    expect(result, '- @Anna bellen\n- tegels *3');
    expect(awake.isAwake, isFalse);
  });

  testWidgets('Windows: no word about pausing outside the app', (tester) async {
    await open(tester, pausesOutsideApp: false);
    reader.hold = true;
    await tapRead(tester);
    expect(find.text(l10n.handwritingWaitDesktop), findsOneWidget);
    expect(find.text(l10n.handwritingWait), findsNothing);
    reader.release();
    await tester.pumpAndSettle();
  });

  testWidgets('stop goes back to the corners with the same photo, without a '
      'message', (tester) async {
    await open(tester);
    reader.hold = true;
    await tapRead(tester);
    await tester.tap(find.text(l10n.handwritingStop));
    await tester.pump();
    expect(find.text(l10n.handwritingStopping), findsOneWidget);
    reader.release();
    await tester.pumpAndSettle();
    expect(closed, isFalse);
    expect(find.byType(CornersEditor), findsOneWidget);
    expect(find.text(l10n.handwritingCornersHint), findsOneWidget);
    expect(awake.isAwake, isFalse);
  });

  testWidgets('back while reading stops it; the next back closes', (
    tester,
  ) async {
    await open(tester);
    reader.hold = true;
    await tapRead(tester);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.text(l10n.handwritingStopping), findsOneWidget);
    reader.release();
    await tester.pumpAndSettle();
    expect(find.byType(CornersEditor), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(closed, isTrue);
    expect(result, isNull);
  });

  testWidgets('after 5 minutes in the app it stops with the advice', (
    tester,
  ) async {
    await open(tester);
    reader.hold = true;
    await tapRead(tester);
    now = const Duration(minutes: 5);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text(l10n.handwritingStopping), findsOneWidget);
    reader.release();
    await tester.pumpAndSettle();
    expect(find.text(l10n.handwritingTooLong(5)), findsOneWidget);
    expect(find.byType(CornersEditor), findsOneWidget);
  });

  testWidgets('time outside the app does not count where reading pauses '
      'there', (tester) async {
    await open(tester);
    reader.hold = true;
    await tapRead(tester);
    now = const Duration(minutes: 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    now = const Duration(minutes: 20);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    now = const Duration(minutes: 22);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text(l10n.handwritingStopping), findsNothing);
    expect(find.text(l10n.handwritingElapsed('3', '00')), findsOneWidget);
    reader.release();
    await tester.pumpAndSettle();
  });

  testWidgets('on Windows the clock counts, also with the window hidden', (
    tester,
  ) async {
    await open(tester, pausesOutsideApp: false);
    reader.hold = true;
    await tapRead(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    now = const Duration(minutes: 6);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text(l10n.handwritingStopping), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    reader.release();
    await tester.pumpAndSettle();
  });

  for (final (failure, text) in [
    (HandwritingFailure.outOfMemory, l10n.handwritingOutOfMemory),
    (HandwritingFailure.modelUnreadable, l10n.handwritingModelUnreadable),
    (HandwritingFailure.failed, l10n.handwritingFailed),
  ]) {
    testWidgets('${failure.name}: back to the corners with its message', (
      tester,
    ) async {
      await open(tester);
      reader.next = HandwritingReaderException(failure);
      await tapRead(tester);
      await tester.pumpAndSettle();
      expect(find.text(text), findsOneWidget);
      expect(find.byType(CornersEditor), findsOneWidget);
      expect(closed, isFalse);
      expect(awake.isAwake, isFalse);
    });
  }

  testWidgets('no text read: says so and stays', (tester) async {
    await open(tester);
    reader.next = '\n-\n';
    await tapRead(tester);
    await tester.pumpAndSettle();
    expect(find.text(l10n.handwritingNothingFound), findsOneWidget);
    expect(closed, isFalse);
  });

  testWidgets('a dragged corner is read straightened', (tester) async {
    await open(tester);
    final photo = tester.getRect(find.byType(RawImage));
    // The top-left corner a quarter inwards.
    await tester.dragFrom(
      photo.topLeft,
      Offset(photo.width / 4, photo.height / 4),
    );
    await tester.pumpAndSettle();
    expect(find.text(l10n.handwritingCornersHint), findsOneWidget);
    reader.next = '- zaaien';
    await tapRead(tester);
    await tester.pumpAndSettle();
    final straightened = preparer.prepared!;
    expect(straightened.isWhole, isFalse);
    expect(straightened.topLeft.x, closeTo(0.25, 0.05));
    expect(straightened.topLeft.y, closeTo(0.25, 0.05));
    expect(straightened.bottomRight, const CornerPoint(1, 1));
  });

  testWidgets('crossed corners: the message, no reading, reset helps', (
    tester,
  ) async {
    await open(tester);
    final photo = tester.getRect(find.byType(RawImage));
    // The top-left corner onto the right side: no shape left to read.
    await tester.dragFrom(
      photo.topLeft,
      Offset(photo.width * 1.2, photo.height / 2),
    );
    await tester.pumpAndSettle();
    expect(find.text(l10n.handwritingCornersCrossed), findsOneWidget);
    final read = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text(l10n.handwritingRead),
        matching: find.byWidgetPredicate((w) => w is FilledButton),
      ),
    );
    expect(read.onPressed, isNull);
    await tester.tap(find.text(l10n.handwritingResetCorners));
    await tester.pumpAndSettle();
    expect(find.text(l10n.handwritingCornersHint), findsOneWidget);
  });

  testWidgets('closing while reading stops it and lets the device sleep', (
    tester,
  ) async {
    await open(tester);
    reader.hold = true;
    await tapRead(tester);
    expect(awake.isAwake, isTrue);
    await tester.pumpWidget(const SizedBox());
    expect(awake.isAwake, isFalse);
    reader.release();
    await tester.pump();
  });
}

/// The pixel work replaced: opens on a ready photo, remembers the corners.
class _FakePreparer extends ReadingImagePreparer {
  _FakePreparer(this.photo);

  final WorkingPhoto photo;
  Corners? prepared;

  @override
  Future<WorkingPhoto> open(Uint8List bytes) async => photo;

  @override
  Future<ReadingImage> prepare(WorkingPhoto photo, Corners corners) async {
    prepared = corners;
    return ReadingImage(width: 1, height: 1, rgb: Uint8List(3));
  }
}

class _Faster extends ReadingSpeedNotifier {
  @override
  Future<ReadingSpeed> build() async => ReadingSpeed.faster;
}
