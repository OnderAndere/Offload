import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/database/app_database.dart';
import 'package:offload/data/items/drift_item_repository.dart';
import 'package:offload/data/people/drift_people_repository.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/domain/items/item_classification.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/domain/time/local_date.dart';
import 'package:offload/domain/tokens/token_processing.dart';
import 'package:offload/domain/tokens/token_suggestion.dart';
import 'package:offload/l10n/app_localizations.dart';
import 'package:offload/presentation/app.dart';
import 'package:offload/presentation/capture/pending_captures.dart';
import 'package:offload/presentation/home/destination.dart';
import 'package:offload/presentation/items/item_detail_screen.dart';
import 'package:offload/presentation/startup/app_storage_provider.dart';

import '../../fakes/drift_widgets.dart';
import '../../fakes/fake_capture_channel.dart';
import '../../fakes/fake_desktop_shell.dart';
import '../../fakes/test_storage.dart';

/// Commitments in the item detail and on Today (T10.1, REQ-046, REQ-047,
/// DD-018 point 10).
void main() {
  late AppStorage storage;
  late DriftItemRepository items;
  final l10n = lookupAppLocalizations(const Locale('nl'));

  Future<void> startApp(
    WidgetTester tester, {
    Future<void> Function()? data,
    Destination start = Destination.inbox,
  }) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.localesTestValue = const [Locale('nl')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    storage = await openTestStorage();
    addTearDown(storage.close);
    items = DriftItemRepository(storage);
    if (data != null) await data();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          destinationProvider.overrideWith((ref) => start),
          appStorageProvider.overrideWith((ref) => storage),
          captureChannelProvider.overrideWith((ref) => FakeCaptureChannel()),
          desktopShellProvider.overrideWith((ref) => FakeDesktopShell()),
        ],
        child: const OffloadApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<String> add(
    String text, {
    ItemType type = ItemType.task,
    ItemStatus status = ItemStatus.active,
    String? requester,
    String? waitingOn,
  }) async {
    final people = DriftPeopleRepository(storage);
    final id = await items.capture(text, source: ItemSource.app);
    await items.classify(
      id,
      ItemClassification(
        type: type,
        status: status,
        requesterId: requester == null ? null : await people.idFor(requester),
        waitingOnId: waitingOn == null ? null : await people.idFor(waitingOn),
      ),
    );
    return id;
  }

  /// Opens the detail of item [id] as a screen of its own: a classified
  /// item is not in the Inbox list.
  Future<void> open(WidgetTester tester, String id) async {
    unawaited(
      ItemDetailScreen.open(tester.element(find.byType(Scaffold).first), id),
    );
    await tester.pumpAndSettle();
  }

  late String id;

  final today = LocalDate.of(DateTime.now());

  testDriftWidgets('a request: asked on, promised and due, with defaults', (
    tester,
  ) async {
    await startApp(
      tester,
      data: () async => id = await add(
        'Offerte dakkapel',
        type: ItemType.request,
        requester: 'Jan',
      ),
    );
    await open(tester, id);

    expect(find.text(l10n.commitmentHeader.toUpperCase()), findsOneWidget);
    expect(
      find.textContaining(l10n.commitmentAskedOn(today.toLocalDateTime())),
      findsOneWidget,
    );
    expect(find.text(l10n.commitmentDueAdd), findsOneWidget);
    // The promise is the title until one is written.
    expect(find.textContaining('Offerte dakkapel'), findsWidgets);

    await tester.tap(find.textContaining(l10n.commitmentPromised('')));
    await tester.pumpAndSettle();
    expect(find.text(l10n.commitmentPromiseTitle), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'Prijs sturen');
    await tester.pump();
    await tester.tap(find.text(l10n.personSave));
    await tester.pumpAndSettle();

    final row = await (storage.database.select(
      storage.database.items,
    )..where((i) => i.title.isNull())).get();
    expect(row.single.promise, 'Prijs sturen');
    expect(find.textContaining('Prijs sturen'), findsOneWidget);
  });

  testDriftWidgets('due: the picked day goes into the text', (tester) async {
    await startApp(
      tester,
      data: () async => id = await add(
        'Offerte dakkapel',
        type: ItemType.request,
        requester: 'Jan',
      ),
    );
    await open(tester, id);

    await tester.tap(find.text(l10n.commitmentDueAdd));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    final text = tester
        .widget<TextField>(find.byType(TextField).first)
        .controller!
        .text;
    expect(text, 'Offerte dakkapel !${fixedDateWord(today)}');
  });

  testDriftWidgets('no block for a task nobody asked for that is not waiting', (
    tester,
  ) async {
    await startApp(tester, data: () async => id = await add('Hek verven'));
    await open(tester, id);

    expect(find.text(l10n.commitmentHeader.toUpperCase()), findsNothing);
  });

  testDriftWidgets('waiting: whom, and the expected day; late is orange', (
    tester,
  ) async {
    await startApp(
      tester,
      data: () async {
        id = await add(
          'Tekeningen',
          status: ItemStatus.waiting,
          waitingOn: 'Petra',
        );
        await items.setExpectedBy(id, today.addDays(-3));
      },
    );
    await open(tester, id);

    expect(find.text(l10n.commitmentWaitsOn('Petra')), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber), findsWidgets);

    // Reset clears the expected day.
    await tester.tap(find.byTooltip(l10n.commitmentReset));
    await tester.pumpAndSettle();
    expect(find.text(l10n.commitmentExpectedAdd), findsOneWidget);
    final row = await (storage.database.select(
      storage.database.items,
    )..where((i) => i.id.equals(id))).getSingle();
    expect(row.expectedAt, isNull);
  });

  testDriftWidgets('"Wacht op…" asks an optional expected day', (tester) async {
    await startApp(tester, data: () async => id = await add('Tekeningen'));
    await open(tester, id);

    await tester.tap(find.text(l10n.itemWaitFor));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.waitForExpected));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(
      find.text(l10n.waitForExpectedDate(today.toLocalDateTime())),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField).last, 'Petra');
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.triagePersonDone));
    await tester.pumpAndSettle();

    final row = await (storage.database.select(
      storage.database.items,
    )..where((i) => i.id.equals(id))).getSingle();
    expect(row.status, ItemStatus.waiting);
    expect(row.expectedAt, DateTime.utc(today.year, today.month, today.day));
  });

  testDriftWidgets('Today: late waiting items in a group of their own, once', (
    tester,
  ) async {
    await startApp(
      tester,
      start: Destination.today,
      data: () async {
        final late = await add(
          'Tekeningen',
          status: ItemStatus.waiting,
          waitingOn: 'Petra',
        );
        await items.setExpectedBy(late, today.addDays(-3));
        // Due today and late: only in "Vandaag".
        final both = await add(
          'Contract terug',
          status: ItemStatus.waiting,
          waitingOn: 'Jan',
        );
        await items.setExpectedBy(both, today.addDays(-1));
        final db = storage.database;
        await (db.update(db.items)..where((i) => i.id.equals(both))).write(
          ItemsCompanion(dueAt: Value(dateOnlyToStored(today))),
        );
        final onTime = await add(
          'Offerte terug',
          status: ItemStatus.waiting,
          waitingOn: 'Jan',
        );
        await items.setExpectedBy(onTime, today.addDays(2));
      },
    );

    expect(find.text(l10n.todayLateSection(1)), findsOneWidget);
    expect(find.text('Tekeningen'), findsOneWidget);
    expect(find.text('Contract terug'), findsOneWidget);
    expect(find.text('Offerte terug'), findsNothing);
    expect(find.text(l10n.commitmentLateChip(3)), findsOneWidget);
  });

  testDriftWidgets('Today: completing a late card takes it away', (
    tester,
  ) async {
    await startApp(
      tester,
      start: Destination.today,
      data: () async {
        final late = await add(
          'Tekeningen',
          status: ItemStatus.waiting,
          waitingOn: 'Petra',
        );
        await items.setExpectedBy(late, today.addDays(-3));
      },
    );

    await tester.drag(find.text('Tekeningen'), const Offset(500, 0));
    await tester.pumpAndSettle();

    expect(find.text('Tekeningen'), findsNothing);
    expect(find.text(l10n.todayLateSection(1)), findsNothing);
    final row = await storage.database
        .select(storage.database.items)
        .getSingle();
    expect(row.status, ItemStatus.done);
  });
}
