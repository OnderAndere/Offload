import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/attachments/photo_compressor.dart';
import 'package:offload/data/attachments/photo_storage_service.dart';
import 'package:offload/domain/attachments/attachment.dart';
import 'package:offload/l10n/app_localizations.dart';
import 'package:offload/platform/photo_source/photo_source.dart';
import 'package:offload/presentation/photos/item_photos.dart';
import 'package:offload/presentation/photos/photo_providers.dart';
import 'package:offload/presentation/photos/photo_viewer.dart';

import '../../fakes/fake_photo_source.dart';

/// Photos in the item detail (T5.3, REQ-024, DD-018 point 19): the row,
/// adding from camera, gallery or the Open window, the messages, deleting
/// and the viewer.
void main() {
  final l10n = lookupAppLocalizations(const Locale('nl'));
  const itemId = '0192f1a2-0000-7000-8000-000000000001';
  late _FakePhotos photos;
  late FakePhotoSource source;

  Future<void> show(
    WidgetTester tester, {
    bool camera = true,
    List<ItemPhoto> initial = const [],
  }) async {
    photos = _FakePhotos(initial);
    source = FakePhotoSource(canTakePhoto: camera);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          photoStorageProvider.overrideWithValue(photos),
          photoSourceProvider.overrideWithValue(source),
          itemPhotosProvider.overrideWith((ref, id) => photos.watch()),
        ],
        child: MaterialApp(
          locale: const Locale('nl'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ItemPhotos(itemId: itemId),
                AddPhotoButton(itemId: itemId),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder addButton() => find.widgetWithText(OutlinedButton, l10n.photoAdd);
  bool enabled(WidgetTester tester, Finder button) =>
      tester.widget<OutlinedButton>(button).onPressed != null;

  testWidgets('no photos: no row, only the button', (tester) async {
    await show(tester);
    expect(find.text(l10n.photosHeader(0)), findsNothing);
    expect(addButton(), findsOneWidget);
  });

  testWidgets('the row: a count, a label per photo, a missing one says so', (
    tester,
  ) async {
    await show(
      tester,
      initial: const [
        (id: 'aaaa0001', present: true),
        (id: 'aaaa0002', present: false),
      ],
    );
    expect(find.text(l10n.photosHeader(2)), findsOneWidget);
    expect(find.bySemanticsLabel(l10n.photoSemantics(1, 2)), findsOneWidget);
    // The missing one also reads its text.
    expect(
      find.bySemanticsLabel(
        RegExp(
          '^${l10n.photoSemantics(2, 2)}.*${l10n.photoMissing}',
          dotAll: true,
        ),
      ),
      findsOneWidget,
    );
    expect(find.text(l10n.photoMissing), findsOneWidget);
  });

  testWidgets('camera: the sheet, processing while it is made ready, then '
      'the photo of this item', (tester) async {
    await show(tester);
    source.next = Uint8List.fromList([1, 2, 3]);
    photos.hold = true;

    await tester.tap(addButton());
    await tester.pumpAndSettle();
    expect(find.text(l10n.photoTake), findsOneWidget);
    expect(find.text(l10n.photoFromGallery), findsOneWidget);
    await tester.tap(find.text(l10n.photoTake));
    // The spinner never settles.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(source.calls, ['take']);
    expect(find.text(l10n.photoProcessing), findsOneWidget);
    expect(enabled(tester, addButton()), isFalse);

    photos.release();
    await tester.pumpAndSettle();
    expect(find.text(l10n.photoProcessing), findsNothing);
    expect(enabled(tester, addButton()), isTrue);
    expect(photos.added, hasLength(1));
    expect(photos.added.single.owner.id, itemId);
    expect(photos.added.single.owner, isA<ItemOwner>());
    expect(photos.added.single.source, [1, 2, 3]);
    expect(find.text(l10n.photosHeader(1)), findsOneWidget);
  });

  testWidgets('gallery: the photo picker', (tester) async {
    await show(tester);
    source.next = Uint8List.fromList([4]);
    await tester.tap(addButton());
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.photoFromGallery));
    await tester.pumpAndSettle();
    expect(source.calls, ['pick']);
    expect(photos.added, hasLength(1));
  });

  testWidgets('closing the sheet adds nothing', (tester) async {
    await show(tester);
    await tester.tap(addButton());
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(source.calls, isEmpty);
    expect(enabled(tester, addButton()), isTrue);
  });

  testWidgets('Windows: the Open window at once, no sheet', (tester) async {
    await show(tester, camera: false);
    source.next = Uint8List.fromList([5]);
    final button = find.widgetWithText(OutlinedButton, l10n.photoAddOpen);
    expect(button, findsOneWidget);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.text(l10n.photoTake), findsNothing);
    expect(source.calls, ['pick']);
    expect(photos.added, hasLength(1));
  });

  testWidgets('cancelled in the camera app: nothing, no message', (
    tester,
  ) async {
    await show(tester, camera: false);
    source.next = null;
    await tester.tap(find.text(l10n.photoAddOpen));
    await tester.pumpAndSettle();
    expect(photos.added, isEmpty);
    expect(find.byType(SnackBar), findsNothing);
    expect(enabled(tester, find.byType(OutlinedButton)), isTrue);
  });

  for (final (name, setUp, message) in <(String, void Function(), String)>[
    (
      'an unreadable picture',
      () => photos.fail = const PhotoFormatException('HEIC'),
      l10n.photoUnreadable,
    ),
    (
      'a failed save',
      () => photos.fail = StateError('disk full'),
      l10n.photoSaveFailed,
    ),
    (
      'a picture too large',
      () =>
          source.next = const PhotoSourceException(PhotoSourceFailure.tooLarge),
      l10n.photoTooLarge,
    ),
    (
      'a window that did not open',
      () => source.next = const PhotoSourceException(
        PhotoSourceFailure.unavailable,
      ),
      l10n.photoSourceFailed,
    ),
  ]) {
    testWidgets('$name: a message, nothing kept, the button free again', (
      tester,
    ) async {
      await show(tester, camera: false);
      source.next = Uint8List.fromList([6]);
      setUp();
      await tester.tap(find.text(l10n.photoAddOpen));
      await tester.pumpAndSettle();
      expect(find.text(message), findsOneWidget);
      expect(photos.added, isEmpty);
      expect(find.text(l10n.photoProcessing), findsNothing);
      expect(enabled(tester, find.byType(OutlinedButton)), isTrue);
    });
  }

  testWidgets('long press: the menu; deleting asks first, cancel keeps it', (
    tester,
  ) async {
    await show(tester, initial: const [(id: 'aaaa0001', present: true)]);
    final tile = find.bySemanticsLabel(l10n.photoSemantics(1, 1));

    await tester.longPress(tile);
    await tester.pumpAndSettle();
    expect(find.text(l10n.photoView), findsOneWidget);
    await tester.tap(find.text(l10n.photoDelete));
    await tester.pumpAndSettle();
    expect(find.text(l10n.photoDeleteTitle), findsOneWidget);
    expect(find.text(l10n.photoDeleteBody), findsOneWidget);
    await tester.tap(find.text(l10n.photoDeleteCancel));
    await tester.pumpAndSettle();
    expect(photos.deleted, isEmpty);

    await tester.longPress(tile);
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.photoDelete));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, l10n.photoDelete));
    await tester.pumpAndSettle();
    expect(photos.deleted, ['aaaa0001']);
    expect(find.text(l10n.photosHeader(1)), findsNothing);
  });

  testWidgets('Del on a focused thumbnail asks to delete', (tester) async {
    await show(tester, initial: const [(id: 'aaaa0001', present: true)]);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pumpAndSettle();
    expect(find.text(l10n.photoDeleteTitle), findsOneWidget);
  });

  testWidgets('a tap opens the viewer; Esc closes it, back on the photo', (
    tester,
  ) async {
    await show(tester, initial: const [(id: 'aaaa0001', present: true)]);
    await tester.tap(find.bySemanticsLabel(l10n.photoSemantics(1, 1)));
    await tester.pumpAndSettle();
    expect(find.byType(PhotoViewer), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(PhotoViewer), findsNothing);

    // The thumbnail has the focus back: Del means the photo (Windows).
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pumpAndSettle();
    expect(find.text(l10n.photoDeleteTitle), findsOneWidget);
  });

  testWidgets('deleting from the viewer closes it', (tester) async {
    await show(tester, initial: const [(id: 'aaaa0001', present: true)]);
    await tester.tap(find.bySemanticsLabel(l10n.photoSemantics(1, 1)));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(l10n.photoDelete));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, l10n.photoDelete));
    await tester.pumpAndSettle();
    expect(photos.deleted, ['aaaa0001']);
    expect(find.byType(PhotoViewer), findsNothing);
  });

  testWidgets('a photo not in the backup: the viewer says so', (tester) async {
    await show(tester, initial: const [(id: 'aaaa0002', present: false)]);
    await tester.tap(find.text(l10n.photoMissing));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsNothing);
    expect(
      find.descendant(
        of: find.byType(PhotoViewer),
        matching: find.text(l10n.photoMissing),
      ),
      findsOneWidget,
    );
  });
}

/// The photos of one item in memory: [add] and [delete] change the row.
class _FakePhotos implements PhotoStorageService {
  _FakePhotos(List<ItemPhoto> initial) : _photos = [...initial];

  final List<ItemPhoto> _photos;
  final _changes = StreamController<List<ItemPhoto>>.broadcast();
  final added = <({AttachmentOwner owner, Uint8List source})>[];
  final deleted = <String>[];

  /// Thrown by [add] instead of keeping the photo.
  Object? fail;

  /// Keeps [add] waiting until [release].
  bool hold = false;
  Completer<void>? _held;

  void release() => _held?.complete();

  Stream<List<ItemPhoto>> watch() async* {
    yield [..._photos];
    yield* _changes.stream;
  }

  @override
  Future<String> add({
    required AttachmentOwner owner,
    required Uint8List source,
  }) async {
    if (hold) await (_held = Completer<void>()).future;
    if (fail case final error?) throw error;
    added.add((owner: owner, source: source));
    final id = 'bbbb${added.length.toString().padLeft(4, '0')}';
    _photos.add((id: id, present: true));
    _changes.add([..._photos]);
    return id;
  }

  @override
  Future<void> delete(String id) async {
    deleted.add(id);
    _photos.removeWhere((p) => p.id == id);
    _changes.add([..._photos]);
  }

  @override
  bool hasDisplay(String id) => _photos.any((p) => p.id == id && p.present);

  // Never finishes in fake time; the tests look at the tiles, not pixels.
  @override
  Future<Uint8List> thumbnail(String id) => Completer<Uint8List>().future;

  @override
  Future<Uint8List> display(String id) => Completer<Uint8List>().future;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
