import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';
import 'package:offload/data/database/app_database.dart';
import 'package:offload/data/database/database_encryption.dart';
import 'package:offload/data/items/drift_item_repository.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/l10n/app_localizations.dart';
import 'package:offload/presentation/photos/item_photos.dart';
import 'package:offload/presentation/photos/photo_providers.dart';
import 'package:offload/presentation/photos/photo_viewer.dart';
import 'package:offload/presentation/startup/app_storage_provider.dart';

import '../test/fakes/fake_photo_source.dart';

/// A photo added to an item on the device (T5.3, REQ-024, REQ-027): the
/// real pipeline and the platform's cipher behind the screen, from a picture
/// as a camera makes it (turned, with a location), to the thumbnail in the
/// row, the viewer, and deleting both files. The source is a fake: the
/// camera app and the picker themselves are checked by hand.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final l10n = lookupAppLocalizations(const Locale('nl'));

  /// 2400×1800 stored sideways (EXIF orientation 6), with a location.
  Uint8List cameraPicture() {
    final image = img.Image(width: 2400, height: 1800);
    img.fill(image, color: img.ColorRgb8(30, 90, 160));
    image.exif.imageIfd.orientation = 6;
    image.exif.gpsIfd['GPSLatitudeRef'] = img.IfdValueAscii('N');
    image.exif.gpsIfd['GPSMapDatum'] = img.IfdValueAscii('WGS-84');
    return img.encodeJpg(image, quality: 90);
  }

  bool hasExif(Uint8List jpeg) {
    const marker = [0x45, 0x78, 0x69, 0x66, 0, 0]; // "Exif\0\0"
    for (var i = 0; i + marker.length <= jpeg.length; i++) {
      var match = true;
      for (var j = 0; j < marker.length && match; j++) {
        match = jpeg[i + j] == marker[j];
      }
      if (match) return true;
    }
    return false;
  }

  /// Pumps until [done], at most [seconds].
  Future<void> until(
    WidgetTester tester,
    bool Function() done, {
    int seconds = 30,
  }) async {
    for (var i = 0; i < seconds * 10 && !done(); i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(done(), isTrue);
  }

  /// The decoded width of the first image under [of], or null.
  int? shownWidth(WidgetTester tester, Finder of) {
    final raw = find.descendant(of: of, matching: find.byType(RawImage));
    if (raw.evaluate().isEmpty) return null;
    return tester.widget<RawImage>(raw.first).image?.width;
  }

  testWidgets('a turned photo with a location: upright, without EXIF, '
      'encrypted, shown, viewed and deleted', (tester) async {
    final dir = Directory.systemTemp.createTempSync('offload_photos');
    addTearDown(() => dir.deleteSync(recursive: true));
    final key = Uint8List.fromList(List.generate(32, (i) => i));
    final database = File('${dir.path}/offload.db');
    final storage = await AppStorage.load(
      AppDatabase(openEncryptedDatabase(database, key)),
      databaseFile: database,
      attachmentsKey: Uint8List.fromList(List.generate(32, (i) => 7 * i)),
    );
    addTearDown(storage.close);
    final itemId = await DriftItemRepository(
      storage,
    ).capture('Indeling moestuin uitwerken', source: ItemSource.app);
    final source = FakePhotoSource(canTakePhoto: false)..next = cameraPicture();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appStorageProvider.overrideWith((ref) => storage),
          photoSourceProvider.overrideWithValue(source),
        ],
        child: MaterialApp(
          locale: const Locale('nl'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
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

    await tester.tap(find.text(l10n.photoAddOpen));
    await tester.pump();
    final started = DateTime.now();
    await until(
      tester,
      () => find.text(l10n.photosHeader(1)).evaluate().isNotEmpty,
    );
    await until(
      tester,
      () => find.text(l10n.photoProcessing).evaluate().isEmpty,
    );
    // ignore: avoid_print
    print('T5.3 photo added in ${DateTime.now().difference(started)}');

    // Two files, both ciphertext; the display version upright, no EXIF.
    final records = await storage.database
        .select(storage.database.attachments)
        .get();
    expect(records, hasLength(1));
    final id = records.single.id;
    final display = File('${storage.attachmentsDirectory!.path}/$id');
    final thumbnail = File('${storage.thumbnailsDirectory!.path}/$id');
    expect(display.existsSync(), isTrue);
    expect(thumbnail.existsSync(), isTrue);
    for (final file in [display, thumbnail]) {
      final bytes = file.readAsBytesSync();
      expect(bytes.take(2), isNot([0xFF, 0xD8]), reason: 'no JPEG start');
      expect(hasExif(bytes), isFalse);
    }
    final photos = ProviderScope.containerOf(
      tester.element(find.byType(ItemPhotos)),
    ).read(photoStorageProvider)!;
    final shown = await photos.display(id);
    final decoded = img.decodeJpg(shown)!;
    expect((decoded.width, decoded.height), (1200, 1600));
    expect(hasExif(shown), isFalse);

    // The thumbnail in the row, through the image provider.
    final tile = find.bySemanticsLabel(l10n.photoSemantics(1, 1));
    await until(tester, () => shownWidth(tester, tile) != null);

    // The viewer shows the display version.
    await tester.tap(tile);
    await tester.pump();
    await until(
      tester,
      () => shownWidth(tester, find.byType(PhotoViewer)) == 1200,
    );

    // Deleting from the viewer removes both files and the row.
    await tester.tap(find.byTooltip(l10n.photoDelete));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, l10n.photoDelete));
    await until(tester, () => find.byType(PhotoViewer).evaluate().isEmpty);
    await until(
      tester,
      () => find.text(l10n.photosHeader(1)).evaluate().isEmpty,
    );
    expect(display.existsSync(), isFalse);
    expect(thumbnail.existsSync(), isFalse);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
