import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/database/app_database.dart';
import 'package:offload/data/items/drift_item_repository.dart';
import 'package:offload/data/search/drift_search_index.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/domain/items/revisit.dart';
import 'package:offload/domain/time/local_date.dart';
import 'package:offload/domain/tokens/token_processing.dart';
import 'package:offload/l10n/app_localizations.dart';
import 'package:offload/presentation/app.dart';
import 'package:offload/presentation/capture/pending_captures.dart';
import 'package:offload/presentation/home/destination.dart';
import 'package:offload/presentation/startup/app_storage_provider.dart';

import '../../fakes/drift_widgets.dart';
import '../../fakes/fake_capture_channel.dart';
import '../../fakes/fake_desktop_shell.dart';
import '../../fakes/test_storage.dart';

/// "Revisit on" in the app (T4.2 step B, REQ-021, DD-018 point 17).
void main() {
  late AppStorage storage;
  late DriftItemRepository items;
  final l10n = lookupAppLocalizations(const Locale('nl'));
  final today = LocalDate.of(DateTime.now());

  Future<void> startApp(
    WidgetTester tester, {
    Future<void> Function()? data,
    Destination start = Destination.inbox,
  }) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.localesTestValue = const [Locale('nl')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    storage = await openTestStorage();
    addTearDown(storage.close);
    items = DriftItemRepository(storage);
    if (data != null) await data();
    await DriftSearchIndex(storage.database).processPending();
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

  /// The item row, read once (never a watched stream in a widget test).
  Future<Item> row(String id) => (storage.database.select(
    storage.database.items,
  )..where((i) => i.id.equals(id))).getSingle();

  /// Status and revisit date written directly, as if parked earlier.
  Future<void> setParked(String id, ItemStatus status, LocalDate day) {
    final db = storage.database;
    return (db.update(db.items)..where((i) => i.id.equals(id))).write(
      ItemsCompanion(
        status: Value(status),
        revisitAt: Value(dateOnlyToStored(day)),
      ),
    );
  }

  testDriftWidgets('item detail: ⋮ parks the item; the line shows the day; '
      'undo puts it back', (tester) async {
    late String id;
    await startApp(
      tester,
      data: () async {
        id = await items.capture('Fietsenrek ophangen', source: ItemSource.app);
      },
    );
    await tester.tap(find.text('Fietsenrek ophangen'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PopupMenuButton<void>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.revisitAction));
    await tester.pumpAndSettle();
    final nextWeek = revisitChoices(today).nextWeek;
    expect(
      find.text(l10n.revisitDate(nextWeek.toLocalDateTime())),
      findsOneWidget,
    );
    await tester.tap(find.text(l10n.revisitNextWeek));
    await tester.pumpAndSettle();

    expect((await row(id)).status, ItemStatus.scheduled);
    expect((await row(id)).revisitAt, dateOnlyToStored(nextWeek));
    expect(
      find.text(l10n.revisitLine(nextWeek.toLocalDateTime())),
      findsOneWidget,
    );
    expect(find.text('Gepland'), findsOneWidget);

    await tester.tap(find.text(l10n.itemUndo));
    await tester.pumpAndSettle();
    expect((await row(id)).status, ItemStatus.inbox);
    expect((await row(id)).revisitAt, isNull);
  });

  testDriftWidgets('item detail: ✕ on the line is "not any more"', (
    tester,
  ) async {
    late String id;
    final day = today.addDays(3);
    await startApp(
      tester,
      start: Destination.projects,
      data: () async {
        id = await items.capture('Moestuinbak', source: ItemSource.app);
        await setParked(id, ItemStatus.scheduled, day);
      },
    );
    // Parked: not in the inbox; open it from the Projects list.
    await tester.tap(find.text(l10n.projectsWithout).first);
    await tester.pumpAndSettle();
    // The card shows the day it comes back.
    expect(find.text(l10n.revisitDate(day.toLocalDateTime())), findsOneWidget);
    await tester.tap(find.text('Moestuinbak'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(l10n.revisitStop));
    await tester.pumpAndSettle();
    expect((await row(id)).status, ItemStatus.active);
    expect((await row(id)).revisitAt, isNull);
    expect(find.text(l10n.revisitLine(day.toLocalDateTime())), findsNothing);
  });

  testDriftWidgets('at start a parked item whose day came is back in the '
      'inbox, and on Today', (tester) async {
    late String due;
    late String later;
    await startApp(
      tester,
      start: Destination.today,
      data: () async {
        due = await items.capture('Cursus timmeren', source: ItemSource.app);
        later = await items.capture('Nog niet', source: ItemSource.app);
        await setParked(due, ItemStatus.scheduled, today);
        await setParked(later, ItemStatus.scheduled, today.addDays(2));
      },
    );
    expect((await row(due)).status, ItemStatus.inbox);
    expect((await row(later)).status, ItemStatus.scheduled);
    expect(find.text(l10n.todayBackSection(1)), findsOneWidget);
    expect(find.text('Cursus timmeren'), findsOneWidget);
    expect(find.text('Nog niet'), findsNothing);
    expect(find.text(l10n.todayEmptyTitle), findsNothing);
  });

  testDriftWidgets('Today: a returned item leaves the group once processed', (
    tester,
  ) async {
    await startApp(
      tester,
      start: Destination.today,
      data: () async {
        final id = await items.capture('Al verwerkt', source: ItemSource.app);
        await setParked(id, ItemStatus.active, today.addDays(-1));
      },
    );
    expect(find.text(l10n.todayBackSection(1)), findsNothing);
    expect(find.text(l10n.todayEmptyTitle), findsOneWidget);
  });
}
