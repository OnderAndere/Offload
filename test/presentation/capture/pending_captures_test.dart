import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/items/drift_item_repository.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/domain/ids/uuid_v7.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/presentation/app.dart';
import 'package:offload/presentation/capture/pending_captures.dart';
import 'package:offload/presentation/startup/app_storage_provider.dart';

import '../../fakes/drift_widgets.dart';
import '../../fakes/fake_capture_channel.dart';
import '../../fakes/fake_desktop_shell.dart';
import '../../fakes/start_on_inbox.dart';
import '../../fakes/test_storage.dart';

/// Captures from outside the app (the Android widget) reach the inbox
/// without loss (AC REQ-001, DD-010; spike S3 tests T2 and T3).
void main() {
  group('importPendingCaptures', () {
    late AppStorage storage;
    late DriftItemRepository repository;
    late FakeCaptureChannel channel;

    setUp(() async {
      storage = await openTestStorage();
      repository = DriftItemRepository(storage);
      channel = FakeCaptureChannel();
    });
    tearDown(() => storage.close());

    Future<List<String>> inboxTexts() async => [
      for (final item in await repository.watchInbox().first) item.rawText,
    ];

    test('stores each capture under its own id, then acknowledges', () async {
      final first = channel.add('Bel Jan');
      final second = channel.add('  Idee: afvoer\n  ');

      await importPendingCaptures(channel, repository);

      final inbox = await repository.watchInbox().first;
      expect(
        {for (final i in inbox) i.id: i.rawText},
        {first: 'Bel Jan', second: '  Idee: afvoer\n  '},
      );
      expect(inbox.every((i) => i.source == ItemSource.widget), isTrue);
      // Same millisecond: the random part of the ids decides their order.
      expect(channel.acknowledged, unorderedEquals([first, second]));
      expect(channel.waiting, isEmpty);
    });

    test('keeps the moment of the tap as capture time', () async {
      final id = channel.add('Bel Jan');

      await importPendingCaptures(channel, repository);

      final item = (await repository.watchInbox().first).single;
      expect(item.capturedAt, uuidV7Time(id));
    });

    test('a capture delivered again is stored once (T3)', () async {
      channel.add('Bel Jan');
      channel.failAcknowledge = true; // the app stops before acknowledging
      await expectLater(
        importPendingCaptures(channel, repository),
        throwsA(isA<Exception>()),
      );
      expect(channel.waiting, hasLength(1));

      channel.failAcknowledge = false;
      await importPendingCaptures(channel, repository);

      expect(await inboxTexts(), ['Bel Jan']);
      expect(channel.waiting, isEmpty);
    });

    test('nothing is acknowledged when storing fails (T2)', () async {
      channel.add('Bel Jan');
      await storage.close(); // every write fails

      await expectLater(
        importPendingCaptures(channel, repository),
        throwsA(anything),
      );

      expect(channel.acknowledged, isEmpty);
      expect(channel.waiting, hasLength(1));
      storage = await openTestStorage(); // for tearDown
    });

    test('an unreadable queue changes nothing', () async {
      channel
        ..add('Bel Jan')
        ..failPending = true;

      await expectLater(
        importPendingCaptures(channel, repository),
        throwsA(anything),
      );

      expect(await inboxTexts(), isEmpty);
      expect(channel.waiting, hasLength(1));
    });

    test('a capture the app refuses is set aside and blocks nothing', () async {
      // Blank for the app, e.g. only a byte-order mark: refused on storing.
      final refused = channel.add('\uFEFF');
      final later = channel.add('Daarna vastgelegd');

      final result = await importPendingCaptures(channel, repository);

      expect(result.setAside, 1);
      expect(result.stored, [later]);
      expect(channel.setAsideIds, [refused]);
      expect(channel.acknowledged, [later]);
      expect(await inboxTexts(), ['Daarna vastgelegd']);
      expect(channel.waiting, isEmpty);
    });

    test('reports captures that were set aside as unreadable', () async {
      channel.quarantineNext = 2;

      expect((await importPendingCaptures(channel, repository)).setAside, 2);
    });
  });

  group('in the app', () {
    late AppStorage storage;
    late FakeCaptureChannel channel;

    Future<void> startApp(WidgetTester tester) async {
      tester.platformDispatcher.localesTestValue = const [Locale('nl')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      storage = await openTestStorage();
      addTearDown(storage.close);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            startOnInbox,
            appStorageProvider.overrideWith((ref) => storage),
            captureChannelProvider.overrideWith((ref) => channel),
            desktopShellProvider.overrideWith((ref) => FakeDesktopShell()),
          ],
          child: const OffloadApp(),
        ),
      );
      await tester.pumpAndSettle();
    }

    setUp(() => channel = FakeCaptureChannel());

    testDriftWidgets('captures waiting at start appear in the inbox', (
      tester,
    ) async {
      channel.add('Uit de widget');

      await startApp(tester);

      expect(find.text('Uit de widget'), findsOneWidget);
      expect(channel.waiting, isEmpty);
    });

    testDriftWidgets('captures from the widget get their person and tag', (
      tester,
    ) async {
      channel.add('Bel @Jan over #renovatie');

      await startApp(tester);

      final db = storage.database;
      expect((await db.select(db.people).getSingle()).name, 'Jan');
      expect((await db.select(db.tags).getSingle()).name, 'renovatie');
    });

    testDriftWidgets('a widget capture arriving on resume is processed too', (
      tester,
    ) async {
      await startApp(tester);
      channel.add('Bel @Piet');

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      final db = storage.database;
      expect((await db.select(db.people).getSingle()).name, 'Piet');
    });

    testDriftWidgets('captures are fetched again when the app comes back', (
      tester,
    ) async {
      await startApp(tester);
      channel.add('Later vastgelegd');

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(find.text('Later vastgelegd'), findsOneWidget);
    });

    testDriftWidgets('unreadable captures are reported, and can be closed', (
      tester,
    ) async {
      channel.quarantineNext = 1;

      await startApp(tester);

      const text =
          '1 vastgelegd item kon niet worden gelezen. '
          'Het is apart bewaard, niet verwijderd.';
      expect(find.text(text), findsOneWidget);
      await tester.tap(find.byTooltip('Sluiten'));
      await tester.pumpAndSettle();
      expect(find.text(text), findsNothing);
    });

    testDriftWidgets('a failed fetch is reported until it works again', (
      tester,
    ) async {
      channel
        ..add('Wacht nog')
        ..failPending = true;

      await startApp(tester);

      const text =
          'Items uit de widget konden nog niet worden opgehaald. '
          'Ze blijven bewaard; Offload probeert het opnieuw.';
      expect(find.text(text), findsOneWidget);

      channel.failPending = false;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(find.text(text), findsNothing);
      expect(find.text('Wacht nog'), findsOneWidget);
    });
  });
}
