import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/database/app_database.dart';
import 'package:offload/data/items/drift_item_repository.dart';
import 'package:offload/data/people/drift_people_repository.dart';
import 'package:offload/data/projects/drift_project_repository.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/domain/items/item_classification.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/domain/time/local_date.dart';
import 'package:offload/domain/tokens/token_processing.dart';
import 'package:offload/l10n/app_localizations.dart';
import 'package:offload/presentation/items/item_detail_screen.dart';
import 'package:offload/presentation/overview/horizon_view.dart';
import 'package:offload/presentation/startup/app_storage_provider.dart';

import '../../fakes/drift_widgets.dart';
import '../../fakes/test_storage.dart';

/// The Horizon (T10.7 step B, REQ-052, DD-018 point 12 (a), (b)).
void main() {
  late AppStorage storage;
  final l10n = lookupAppLocalizations(const Locale('nl'));
  final today = LocalDate.of(DateTime.now());
  final windows = TargetPlatformVariant.only(TargetPlatform.windows);

  Future<String> add(
    String text, {
    LocalDate? due,
    String? project,
    String? waitingOn,
    LocalDate? expected,
  }) async {
    final items = DriftItemRepository(storage);
    final id = await items.capture(text, source: ItemSource.app);
    await items.classify(
      id,
      const ItemClassification(
        type: ItemType.task,
        status: ItemStatus.active,
        requesterId: null,
        waitingOnId: null,
      ),
    );
    if (project != null) await items.setProject(id, project);
    if (waitingOn != null) {
      await items.waitFor(id, waitingOn, expected: expected);
    }
    if (due != null) {
      final db = storage.database;
      await (db.update(db.items)..where((i) => i.id.equals(id))).write(
        ItemsCompanion(dueAt: Value(dateOnlyToStored(due))),
      );
    }
    return id;
  }

  Future<void> start(
    WidgetTester tester, {
    required Future<void> Function() data,
    int busyFrom = 5,
  }) async {
    tester.view.physicalSize = const Size(420, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    storage = await openTestStorage();
    addTearDown(storage.close);
    await storage.saveBusyFromItems(busyFrom);
    await data();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appStorageProvider.overrideWith((ref) => storage)],
        child: MaterialApp(
          locale: const Locale('nl'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: HorizonView()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The column of the week of [day], by its sentence for a screen reader
  /// (a week number alone can equal a count).
  Finder week(LocalDate day) =>
      find.bySemanticsLabel(RegExp('^Week ${day.isoWeek}, '));

  // The second week, where nothing is overdue.
  final nextMonday = today.monday.addDays(7);

  testDriftWidgets('lanes per top-level project, busy week, the week list', (
    tester,
  ) async {
    await start(
      tester,
      busyFrom: 3,
      data: () async {
        final projects = DriftProjectRepository(storage);
        final house = await projects.create('Verbouwing');
        final kitchen = await projects.create('Keuken', parentId: house);
        final jan = await DriftPeopleRepository(storage).idFor('Jan');
        await add('Tegels kiezen', due: nextMonday, project: kitchen);
        await add('Kozijnen meten', due: nextMonday.addDays(1), project: house);
        await add('Offerte schilder', due: nextMonday.addDays(2));
        await add(
          'Getekende opdracht',
          waitingOn: jan,
          expected: nextMonday.addDays(3),
        );
        await add('Te laat', due: today.addDays(-2));
      },
    );

    expect(find.text(l10n.horizonTitle(6)), findsOneWidget);
    // Kitchen is a subproject: its item is in the lane of Verbouwing.
    expect(find.text('Verbouwing'), findsOneWidget);
    expect(find.text('Keuken'), findsNothing);
    expect(find.text(l10n.horizonNoProject), findsOneWidget);
    expect(find.text(l10n.horizonSummary(2, 5)), findsOneWidget);
    // Week 2 has three to deliver: busy from 3, as text.
    expect(find.text(l10n.horizonBusy), findsOneWidget);

    // This week first: the overdue item.
    expect(find.text('Te laat'), findsOneWidget);
    expect(find.text('Tegels kiezen'), findsNothing);

    await tester.tap(week(nextMonday));
    await tester.pumpAndSettle();
    expect(find.text(l10n.horizonToDeliverBusy(3)), findsOneWidget);
    expect(find.text('Tegels kiezen'), findsOneWidget);
    expect(
      find.textContaining(
        l10n.horizonEntryWaiting(
          'Jan',
          nextMonday.addDays(3).toLocalDateTime(),
        ),
      ),
      findsOneWidget,
    );
    expect(find.text('Te laat'), findsNothing);

    // A tap opens the item.
    await tester.tap(find.text('Kozijnen meten'));
    await tester.pumpAndSettle();
    expect(find.byType(ItemDetailScreen), findsOneWidget);
  });

  testDriftWidgets('more than four marks in a cell: four, then +n', (
    tester,
  ) async {
    await start(
      tester,
      data: () async {
        for (var i = 0; i < 6; i++) {
          await add('Klus $i', due: nextMonday);
        }
      },
    );
    expect(find.text('+2'), findsOneWidget);
    // A cell chooses its week, as the header does.
    await tester.tap(find.text('+2'));
    await tester.pumpAndSettle();
    expect(find.text('Klus 5'), findsOneWidget);
  });

  testDriftWidgets('waiting with a deadline: once in the list, both dates', (
    tester,
  ) async {
    await start(
      tester,
      data: () async {
        final jan = await DriftPeopleRepository(storage).idFor('Jan');
        await add(
          'Getekende opdracht',
          waitingOn: jan,
          expected: nextMonday.addDays(1),
          due: nextMonday.addDays(3),
        );
      },
    );
    await tester.tap(week(nextMonday));
    await tester.pumpAndSettle();
    // The deadline is mine (PO 02-10-2026): it counts as to deliver.
    expect(find.text(l10n.horizonToDeliver(1)), findsOneWidget);
    expect(find.text('Getekende opdracht'), findsOneWidget);
    final waiting = l10n.horizonEntryWaiting(
      'Jan',
      nextMonday.addDays(1).toLocalDateTime(),
    );
    final due = l10n.horizonEntryDue(nextMonday.addDays(3).toLocalDateTime());
    expect(find.text(l10n.horizonEntryMore(waiting, due)), findsOneWidget);
  });

  testDriftWidgets('nothing with a date: an explanation, not empty lanes', (
    tester,
  ) async {
    await start(tester, data: () async => add('Zonder datum'));
    expect(find.text(l10n.horizonEmpty(6)), findsOneWidget);
    expect(find.text(l10n.horizonWeekEmpty), findsOneWidget);
  });

  testDriftWidgets('a screen reader hears each week as a sentence', (
    tester,
  ) async {
    await start(
      tester,
      data: () async => add('Kozijnen meten', due: nextMonday),
    );
    expect(
      find.bySemanticsLabel(
        RegExp('^Week ${nextMonday.isoWeek}, .*: 1 te leveren; niets wachtend'),
      ),
      findsOneWidget,
    );
  });

  testDriftWidgets('Windows: ← and → choose the week', (tester) async {
    await start(
      tester,
      data: () async => add('Kozijnen meten', due: nextMonday),
    );
    // Clicking the first week puts the focus on the timeline.
    await tester.tap(week(today));
    await tester.pumpAndSettle();
    expect(find.text('Kozijnen meten'), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(find.text('Kozijnen meten'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(find.text('Kozijnen meten'), findsNothing);
  }, variant: windows);
}
