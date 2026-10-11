import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';
import 'package:offload/data/database/app_database.dart';
import 'package:offload/data/database/database_encryption.dart';
import 'package:offload/data/items/drift_item_repository.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/domain/attachments/attachment.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/l10n/app_localizations.dart';
import 'package:offload/presentation/inbox/inbox_screen.dart';
import 'package:offload/presentation/photos/card_photo.dart';
import 'package:offload/presentation/photos/photo_providers.dart';
import 'package:offload/presentation/startup/app_storage_provider.dart';
import 'package:offload/presentation/theme/app_theme.dart';

/// Scrolling through a list of items that each have a photo (T5.4, DD-006
/// point 5, measurable: ≥ 100 items at 60 fps, without jank while the
/// thumbnails load). The real pipeline, cipher and inbox; prints the frame
/// times. Meaningful in profile mode, with `flutter drive --profile -d DEVICE`
/// and `--driver=test_driver/integration_test.dart`
/// `--target=integration_test/card_photos_test.dart`.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const count = 120;
  // A control run without photos: `--dart-define=CARD_PHOTOS=false`.
  const withPhotos = bool.fromEnvironment('CARD_PHOTOS', defaultValue: true);

  /// A photo of 800×600, a different colour per item.
  Uint8List picture(int i) {
    final image = img.Image(width: 800, height: 600);
    img.fill(
      image,
      color: img.ColorRgb8((i * 37) % 256, (i * 91) % 256, (i * 53) % 256),
    );
    return img.encodeJpg(image, quality: 85);
  }

  testWidgets('$count items with a photo scroll without jank', (tester) async {
    final dir = Directory.systemTemp.createTempSync('offload_card_photos');
    addTearDown(() => dir.deleteSync(recursive: true));
    final key = Uint8List.fromList(List.generate(32, (i) => i));
    final database = File('${dir.path}/offload.db');
    final storage = await AppStorage.load(
      AppDatabase(openEncryptedDatabase(database, key)),
      databaseFile: database,
      attachmentsKey: Uint8List.fromList(List.generate(32, (i) => 7 * i)),
    );
    addTearDown(storage.close);
    final container = ProviderContainer(
      overrides: [appStorageProvider.overrideWith((ref) => storage)],
    );
    addTearDown(container.dispose);
    await container.read(appStorageProvider.future);
    final photos = container.read(photoStorageProvider)!;
    final items = DriftItemRepository(storage);
    final adding = Stopwatch()..start();
    for (var i = 0; i < count; i++) {
      final id = await items.capture(
        'Plantvak $i bekijken',
        source: ItemSource.app,
      );
      if (withPhotos) {
        await photos.add(owner: ItemOwner(id), source: picture(i));
      }
    }
    // ignore: avoid_print
    print('T5.4 $count photos added in ${adding.elapsed}');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: offloadTheme(),
          locale: const Locale('nl'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const InboxScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Image), withPhotos ? findsWidgets : findsNothing);

    // From the first scroll, while the thumbnails decrypt and decode.
    final list = find.byType(Scrollable).first;
    // The frame times straight from the engine: watchPerformance also asks
    // the VM service for garbage collection, which a profile build on a
    // device does not offer.
    final frames = <FrameTiming>[];
    void collect(List<FrameTiming> timings) => frames.addAll(timings);
    SchedulerBinding.instance.addTimingsCallback(collect);
    for (var round = 0; round < 3; round++) {
      await tester.fling(list, const Offset(0, -4000), 4000);
      await tester.pumpAndSettle();
    }
    await tester.fling(list, const Offset(0, 12000), 6000);
    await tester.pumpAndSettle();
    // The last timings arrive with the next frames.
    await tester.pump(const Duration(seconds: 1));
    SchedulerBinding.instance.removeTimingsCallback(collect);

    const budget = Duration(microseconds: 16667);
    String ms(Duration d) => (d.inMicroseconds / 1000).toStringAsFixed(1);
    Duration average(Iterable<Duration> all) => Duration(
      microseconds: all.fold(0, (s, d) => s + d.inMicroseconds) ~/ all.length,
    );
    Duration worst(Iterable<Duration> all) =>
        all.reduce((a, b) => a > b ? a : b);
    final build = frames.map((f) => f.buildDuration);
    final raster = frames.map((f) => f.rasterDuration);
    // ignore: avoid_print
    print(
      'T5.4 ${Platform.operatingSystem} photos: $withPhotos, frames: ${frames.length}, '
      'build avg ${ms(average(build))} ms (worst ${ms(worst(build))}), '
      'raster avg ${ms(average(raster))} ms (worst ${ms(worst(raster))}), '
      'over 16.7 ms: build ${build.where((d) => d > budget).length}, '
      'raster ${raster.where((d) => d > budget).length}',
    );
    expect(frames, isNotEmpty);

    // Only thumbnails, decoded at the size shown (REQ-024).
    final dpr = tester.view.devicePixelRatio;
    for (final raw in tester.widgetList<RawImage>(find.byType(RawImage))) {
      final width = raw.image?.width;
      if (width != null) {
        expect(width, lessThanOrEqualTo((cardPhotoSize * dpr).round()));
      }
    }
  });
}
