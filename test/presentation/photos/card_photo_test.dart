import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/attachments/photo_storage_service.dart';
import 'package:offload/domain/attachments/photo_summary.dart';
import 'package:offload/l10n/app_localizations.dart';
import 'package:offload/presentation/photos/attachment_image.dart';
import 'package:offload/presentation/photos/card_photo.dart';
import 'package:offload/presentation/photos/photo_providers.dart';

/// The newest photo of an item on its card in a list (T5.4, DD-006 point
/// 5): the thumbnail at the size shown, the number when there are more, a
/// mark when the file is gone, nothing without photos.
void main() {
  final l10n = lookupAppLocalizations(const Locale('nl'));
  const itemId = '0192a3b4-c5d6-7e8f-9a0b-1c2d3e4f5a6b';
  const newest = '0192a3b4-c5d6-7e8f-9a0b-00000000000b';

  // The cache key is the photo: a thumbnail still loading in one test would
  // be the one the next test shows.
  setUp(() {
    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();
  });

  Future<_FakePhotos> show(
    WidgetTester tester,
    Map<String, PhotoSummary> summaries, {
    Object? failure,
    String? kindLabel,
  }) async {
    final photos = _FakePhotos(failure);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          photoStorageProvider.overrideWithValue(photos),
          itemPhotoSummariesProvider.overrideWith(
            (ref) => Stream.value(summaries),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('nl'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              child: CardPhoto(
                itemId: itemId,
                orElse: const Text('geen'), // l10n-ignore: test
                kindLabel: kindLabel,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    return photos;
  }

  testWidgets('without photos: what the caller shows instead', (tester) async {
    final photos = await show(tester, const {});
    expect(find.text('geen'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    expect(photos.asked, isEmpty);
  });

  testWidgets('one photo: its thumbnail, decoded at the size shown, without '
      'a number', (tester) async {
    final semantics = tester.ensureSemantics();
    final photos = await show(tester, {itemId: (newestId: newest, count: 1)});
    final image = tester.widget<Image>(find.byType(Image)).image;
    expect(image, isA<ResizeImage>());
    final resized = image as ResizeImage;
    final dpr = tester.view.devicePixelRatio;
    expect(resized.width, (cardPhotoSize * dpr).round());
    expect(
      resized.imageProvider,
      isA<AttachmentImage>()
          .having((a) => a.id, 'id', newest)
          .having((a) => a.thumbnail, 'thumbnail', isTrue),
    );
    expect(photos.asked, [newest]);
    expect(find.bySemanticsLabel(l10n.cardPhotos(1)), findsOneWidget);
    expect(find.text('1'), findsNothing);
    expect(find.text('geen'), findsNothing);
    semantics.dispose();
  });

  testWidgets('more photos: the newest, with how many', (tester) async {
    final semantics = tester.ensureSemantics();
    await show(tester, {itemId: (newestId: newest, count: 3)});
    expect(find.text('3'), findsOneWidget);
    expect(find.bySemanticsLabel(l10n.cardPhotos(3)), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('in place of an icon that said what the row is, that is said '
      'first (search results)', (tester) async {
    final semantics = tester.ensureSemantics();
    await show(tester, {
      itemId: (newestId: newest, count: 3),
    }, kindLabel: l10n.searchKindItem);
    expect(
      find.bySemanticsLabel(
        RegExp(
          '^${RegExp.escape(l10n.searchKindItem)}\\s+'
          '${RegExp.escape(l10n.cardPhotos(3))}\$',
        ),
      ),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('a photo whose file is gone: a mark, never a broken image', (
    tester,
  ) async {
    await show(tester, {
      itemId: (newestId: newest, count: 1),
    }, failure: StateError('not in this backup'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.hide_image_outlined), findsOneWidget);
  });
}

/// Thumbnails that never finish in fake time, or fail with [failure].
class _FakePhotos implements PhotoStorageService {
  _FakePhotos(this.failure);

  final Object? failure;
  final asked = <String>[];

  @override
  Future<Uint8List> thumbnail(String id) {
    asked.add(id);
    if (failure case final error?) return Future.error(error);
    return Completer<Uint8List>().future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
