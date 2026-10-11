import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/database/app_database.dart';
import 'package:offload/data/items/drift_item_repository.dart';
import 'package:offload/data/people/drift_people_repository.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/domain/items/item_classification.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/domain/sync/hlc.dart';
import 'package:offload/l10n/app_localizations.dart';
import 'package:offload/presentation/app.dart';
import 'package:offload/presentation/capture/pending_captures.dart';
import 'package:offload/presentation/home/destination.dart';
import 'package:offload/presentation/reminders/reminder_providers.dart';
import 'package:offload/presentation/startup/app_storage_provider.dart';

import '../../fakes/drift_widgets.dart';
import '../../fakes/fake_capture_channel.dart';
import '../../fakes/fake_desktop_shell.dart';
import '../../fakes/fake_reminder_scheduler.dart';
import '../../fakes/test_storage.dart';

/// The nudge of waiting items that stay silent in the app (T10.1,
/// AC REQ-047, DD-018 point 10).
void main() {
  late AppStorage storage;
  late DriftItemRepository items;
  late FakeReminderScheduler scheduler;
  final l10n = lookupAppLocalizations(const Locale('nl'));

  /// A waiting item on Joris, last changed [daysAgo] days ago.
  Future<String> waiting(String text, int daysAgo) async {
    final joris = await DriftPeopleRepository(storage).idFor('Joris');
    final id = await items.capture(text, source: ItemSource.app);
    await items.classify(
      id,
      ItemClassification(
        type: ItemType.task,
        status: ItemStatus.waiting,
        requesterId: null,
        waitingOnId: joris,
      ),
    );
    final then = DateTime.now().toUtc().subtract(Duration(days: daysAgo));
    final db = storage.database;
    await (db.update(db.items)..where((i) => i.id.equals(id))).write(
      ItemsCompanion(
        hlc: Value(Hlc(then.millisecondsSinceEpoch, 0, 'test').pack()),
      ),
    );
    return id;
  }

  Future<Item> row(String id) => (storage.database.select(
    storage.database.items,
  )..where((i) => i.id.equals(id))).getSingle();

  Future<void> startApp(
    WidgetTester tester,
    Future<void> Function() data,
  ) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.localesTestValue = const [Locale('nl')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    storage = await openTestStorage();
    addTearDown(storage.close);
    items = DriftItemRepository(storage);
    scheduler = FakeReminderScheduler(granted: true);
    await data();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          destinationProvider.overrideWith((ref) => Destination.today),
          appStorageProvider.overrideWith((ref) => storage),
          captureChannelProvider.overrideWith((ref) => FakeCaptureChannel()),
          desktopShellProvider.overrideWith((ref) => FakeDesktopShell()),
          reminderSchedulerProvider.overrideWithValue(scheduler),
        ],
        child: const OffloadApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
  }

  testDriftWidgets('Today: a silent waiting item; Chased (no undo), '
      'Received completes', (tester) async {
    late String key;
    late String photos;
    await startApp(tester, () async {
      key = await waiting('Sleutel tuinhuis terugkrijgen', 12);
      photos = await waiting('Foto\'s van het buurtfeest', 9);
    });
    expect(find.text(l10n.todaySilentSection(2)), findsOneWidget);
    expect(find.text(l10n.nudgeSilentDays(12)), findsOneWidget);

    await tester.tap(find.text(l10n.nudgeChased).first);
    await tester.pumpAndSettle();
    expect((await row(key)).reviewedAt, isNotNull);
    expect(find.text(l10n.todaySilentSection(1)), findsOneWidget);

    // No undo: putting the moment back would be a touch too.
    expect(find.text(l10n.itemUndo), findsNothing);

    await tester.tap(find.text(l10n.nudgeReceived).last);
    await tester.pumpAndSettle();
    expect((await row(photos)).status, ItemStatus.done);
  });

  testDriftWidgets('a waiting item going silent in 3 days is nudged then', (
    tester,
  ) async {
    late String id;
    await startApp(tester, () async {
      id = await waiting('Sleutel tuinhuis terugkrijgen', 4);
    });
    expect(find.text(l10n.todaySilentSection(1)), findsNothing);
    final nudge = scheduler.planned.single;
    expect(nudge.title, l10n.nudgeReminderOne('Joris', 7));
    expect(nudge.title, 'Wacht nog op Joris · 7 dagen stil');
    expect(nudge.lines, ['Sleutel tuinhuis terugkrijgen']);
    expect(nudge.publicTitle, l10n.nudgeReminderPublic);
    expect(nudge.open, id);
    expect(nudge.at.difference(DateTime.now()).inDays, inInclusiveRange(2, 3));
  });

  testDriftWidgets('the item: the silent line with Chased', (tester) async {
    late String id;
    await startApp(tester, () async {
      id = await waiting('Sleutel tuinhuis terugkrijgen', 10);
    });
    await tester.tap(find.text('Sleutel tuinhuis terugkrijgen'));
    await tester.pumpAndSettle();
    expect(find.text(l10n.nudgeSilentDays(10)), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, l10n.nudgeChased));
    await tester.pumpAndSettle();
    expect((await row(id)).reviewedAt, isNotNull);
    expect(find.text(l10n.nudgeSilentDays(10)), findsNothing);
  });
}
