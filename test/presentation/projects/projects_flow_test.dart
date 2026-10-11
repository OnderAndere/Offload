import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/database/app_database.dart';
import 'package:offload/data/items/drift_item_repository.dart';
import 'package:offload/data/projects/drift_project_repository.dart';
import 'package:offload/data/search/drift_search_index.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/l10n/app_localizations.dart';
import 'package:offload/presentation/app.dart';
import 'package:offload/presentation/capture/pending_captures.dart';
import 'package:offload/presentation/home/destination.dart';
import 'package:offload/presentation/inbox/inbox_card.dart';
import 'package:offload/presentation/items/item_detail_screen.dart';
import 'package:offload/presentation/projects/project_look.dart';
import 'package:offload/presentation/projects/project_screen.dart';
import 'package:offload/presentation/startup/app_storage_provider.dart';
import 'package:offload/presentation/triage/triage_screen.dart';

import '../../fakes/drift_widgets.dart';
import '../../fakes/fake_capture_channel.dart';
import '../../fakes/fake_desktop_shell.dart';
import '../../fakes/test_storage.dart';

/// Projects: the destination, a project, the picker (T3.1 step B, DD-018
/// point 6).
void main() {
  late AppStorage storage;
  late DriftItemRepository items;
  late DriftProjectRepository projects;
  final l10n = lookupAppLocalizations(const Locale('nl'));
  final windows = TargetPlatformVariant.only(TargetPlatform.windows);

  Future<void> startApp(
    WidgetTester tester, {
    Destination start = Destination.projects,
    Future<void> Function()? data,
    double width = 400,
  }) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.localesTestValue = const [Locale('nl')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    storage = await openTestStorage();
    addTearDown(storage.close);
    items = DriftItemRepository(storage);
    projects = DriftProjectRepository(storage);
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

  Future<String> add(String text, {String? project, ItemStatus? status}) async {
    final id = await items.capture(text, source: ItemSource.app);
    if (status != null) {
      final db = storage.database;
      await (db.update(db.items)..where((i) => i.id.equals(id))).write(
        ItemsCompanion(status: Value(status)),
      );
    }
    if (project != null) await items.setProject(id, project);
    return id;
  }

  Future<String?> projectOf(String id) async => (await (storage.database.select(
    storage.database.items,
  )..where((i) => i.id.equals(id))).getSingle()).contextId;

  /// The live projects, read once. Never a watched Drift stream here: in
  /// the fake time of a widget test it never answers (CLAUDE.md).
  Future<List<Context>> storedProjects() => (storage.database.select(
    storage.database.contexts,
  )..where((c) => c.deletedAt.isNull())).get();

  late String renovatie;

  Future<void> sample() async {
    renovatie = await projects.create('Renovatie');
    final garden = await projects.create('Moestuin', parentId: renovatie);
    await projects.create('Teamoverleg');
    await add(
      'Planning vakantie',
      project: renovatie,
      status: ItemStatus.active,
    );
    await add(
      'Marktkraam ophalen',
      project: garden,
      status: ItemStatus.waiting,
    );
    await add('Oude offerte', project: renovatie, status: ItemStatus.done);
    await add('Losse gedachte', status: ItemStatus.active);
  }

  testDriftWidgets('the list: without project first, sub-projects, counts', (
    tester,
  ) async {
    await startApp(tester, data: sample);

    expect(find.text(l10n.navProjects), findsWidgets);
    expect(find.text(l10n.projectsWithout), findsOneWidget);
    expect(find.text('Renovatie'), findsOneWidget);
    expect(find.text('Moestuin'), findsOneWidget);
    expect(find.text('Teamoverleg'), findsOneWidget);
    // Renovatie counts its sub-project; done items do not count.
    expect(
      find.bySemanticsLabel(RegExp('^Renovatie, 2 open items')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp('^${l10n.projectsWithout}, 1 open item')),
      findsOneWidget,
    );
  });

  testDriftWidgets('a project: sub-projects, groups, done folded; back', (
    tester,
  ) async {
    await startApp(tester, data: sample);

    await tester.tap(find.text('Renovatie'));
    await tester.pumpAndSettle();
    expect(find.byType(ProjectScreen), findsOneWidget);
    expect(find.widgetWithText(ActionChip, 'Moestuin'), findsOneWidget);
    expect(
      find.text(l10n.projectGroup('active', 1).toUpperCase()),
      findsOneWidget,
    );
    expect(find.text('Planning vakantie'), findsOneWidget);
    // A sub-project's items are in the sub-project.
    expect(find.text('Marktkraam ophalen'), findsNothing);
    expect(find.text('Oude offerte'), findsNothing);

    await tester.tap(find.text(l10n.projectGroup('done', 1).toUpperCase()));
    await tester.pumpAndSettle();
    expect(find.text('Oude offerte'), findsOneWidget);

    await tester.tap(find.widgetWithText(ActionChip, 'Moestuin'));
    await tester.pumpAndSettle();
    expect(find.text('Marktkraam ophalen'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(ProjectScreen), findsNothing);
    expect(find.text(l10n.projectsWithout), findsOneWidget);
  });

  testDriftWidgets('Android Back closes a project, then goes to Today', (
    tester,
  ) async {
    await startApp(tester, data: sample);
    await tester.tap(find.text(l10n.projectsWithout));
    await tester.pumpAndSettle();
    expect(find.text('Losse gedachte'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(ProjectScreen), findsNothing);
    expect(find.text('Renovatie'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text(l10n.navToday), findsWidgets);
    expect(find.text('Renovatie'), findsNothing);
  });

  testDriftWidgets('a new project; a taken name is refused in the dialog', (
    tester,
  ) async {
    await startApp(tester, data: sample);

    await tester.tap(find.byTooltip(l10n.projectsNew));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'renovatie');
    await tester.tap(find.text(l10n.projectCreate));
    await tester.pumpAndSettle();
    expect(find.text(l10n.projectErrorNameTaken), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Beurs');
    await tester.tap(find.text(l10n.projectCreate));
    await tester.pumpAndSettle();
    expect(find.text('Beurs'), findsOneWidget);
  });

  testDriftWidgets('deleting keeps the items; undo brings the project back', (
    tester,
  ) async {
    late String id;
    await startApp(
      tester,
      data: () async {
        await sample();
        id = await add('Offerte afvoer', project: renovatie);
      },
    );
    await tester.tap(find.text('Renovatie'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(l10n.projectMenuTooltip));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.projectDelete));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, l10n.projectDelete));
    await tester.pumpAndSettle();

    expect(find.byType(ProjectScreen), findsNothing);
    expect(find.text('Renovatie'), findsNothing);
    expect(await projectOf(id), isNull);
    expect(find.text(l10n.projectDeleted), findsOneWidget);

    await tester.tap(find.text(l10n.itemUndo));
    await tester.pumpAndSettle();
    expect(find.text('Renovatie'), findsOneWidget);
    expect(await projectOf(id), renovatie);
  });

  testDriftWidgets('the item detail chooses a project; the card shows it', (
    tester,
  ) async {
    late String id;
    await startApp(
      tester,
      start: Destination.inbox,
      data: () async {
        await sample();
        id = await add('Bel Jan');
      },
    );
    await tester.tap(find.text('Bel Jan'));
    await tester.pumpAndSettle();
    expect(find.byType(ItemDetailScreen), findsOneWidget);

    await tester.tap(find.text(l10n.projectNone));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Teamoverleg'));
    await tester.pumpAndSettle();
    final team = (await storedProjects())
        .firstWhere((p) => p.name == 'Teamoverleg')
        .id;
    expect(await projectOf(id), team);
    // The detail chip shows it now.
    expect(find.text('Teamoverleg'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(InboxCard),
        matching: find.widgetWithText(ProjectChip, 'Teamoverleg'),
      ),
      findsOneWidget,
    );
  });

  testDriftWidgets('a choice right after typing ^project wins (T10.5)', (
    tester,
  ) async {
    late String id;
    await startApp(
      tester,
      start: Destination.inbox,
      data: () async {
        await sample();
        id = await add('Bel Jan');
      },
    );
    await tester.tap(find.text('Bel Jan'));
    await tester.pumpAndSettle();

    // Typed, and within the autosave pause the picker is opened.
    await tester.enterText(find.byType(TextField).first, 'Bel Jan ^renovatie');
    await tester.pump();
    await tester.tap(find.text(l10n.projectNone));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Teamoverleg'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    final team = (await storedProjects())
        .firstWhere((p) => p.name == 'Teamoverleg')
        .id;
    // The text was saved before the picker opened, so the choice is the
    // later change and the token does not take it back (DD-004 point 11).
    expect(await projectOf(id), team);
    expect(
      (await (storage.database.select(
        storage.database.items,
      )..where((i) => i.id.equals(id))).getSingle()).rawText,
      'Bel Jan ^renovatie',
    );
  });

  testDriftWidgets('the picker creates a project from the typed name', (
    tester,
  ) async {
    late String id;
    await startApp(
      tester,
      start: Destination.inbox,
      data: () async => id = await add('Bel Jan'),
    );
    await tester.tap(find.text('Bel Jan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.projectNone));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, l10n.projectPickerHint),
      'Beurs',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.projectNewNamed('Beurs')));
    await tester.pumpAndSettle();

    final beurs = (await storedProjects()).single;
    expect(beurs.name, 'Beurs');
    expect(await projectOf(id), beurs.id);
  });

  testDriftWidgets('the triage card has a project chip; it does not sort', (
    tester,
  ) async {
    late String id;
    await startApp(
      tester,
      start: Destination.inbox,
      data: () async {
        await sample();
        id = await add('Bel Jan');
      },
    );
    await tester.tap(find.text(l10n.inboxTriage(1)));
    await tester.pumpAndSettle();
    expect(find.byType(TriageScreen), findsOneWidget);

    await tester.tap(find.text(l10n.projectNone));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Renovatie'));
    await tester.pumpAndSettle();

    expect(await projectOf(id), renovatie);
    // Still the same card: choosing a project processes nothing.
    expect(find.text('Bel Jan'), findsOneWidget);
    expect(find.text('Renovatie'), findsOneWidget);
  });

  testDriftWidgets(
    'Windows: Ctrl+3, arrows and Enter open a project, Escape goes back',
    (tester) async {
      await startApp(
        tester,
        start: Destination.today,
        data: sample,
        width: 1280,
      );
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pumpAndSettle();
      expect(find.text(l10n.projectsWithout), findsOneWidget);

      // Without project, then Renovatie.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(ProjectScreen), findsOneWidget);
      expect(find.text('Planning vakantie'), findsOneWidget);
      expect(find.text(l10n.navProjects), findsWidgets);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(ProjectScreen), findsNothing);
    },
    variant: windows,
  );

  testDriftWidgets('Windows: key P on the triage card opens the picker', (
    tester,
  ) async {
    await startApp(
      tester,
      start: Destination.inbox,
      width: 1280,
      data: () async {
        await sample();
        await add('Bel Jan');
      },
    );
    await tester.tap(find.text(l10n.inboxTriage(1)));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
    await tester.pumpAndSettle();
    expect(find.text(l10n.projectPickerTitle), findsOneWidget);
  }, variant: windows);

  testDriftWidgets('Enter in the picker takes the sub-project that matches', (
    tester,
  ) async {
    late String id;
    await startApp(
      tester,
      start: Destination.inbox,
      data: () async {
        await sample();
        id = await add('Bel Jan');
      },
    );
    await tester.tap(find.text('Bel Jan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.projectNone));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, l10n.projectPickerHint),
      'moes',
    );
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    final garden = (await storedProjects())
        .firstWhere((p) => p.name == 'Moestuin')
        .id;
    expect(await projectOf(id), garden);
  });

  testDriftWidgets('archiving folds a project away; undo brings it back', (
    tester,
  ) async {
    await startApp(tester, data: sample);
    await tester.tap(find.text('Teamoverleg'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(l10n.projectMenuTooltip));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.projectArchive));
    await tester.pumpAndSettle();

    expect(find.byType(ProjectScreen), findsNothing);
    expect(find.text('Teamoverleg'), findsNothing);
    expect(find.text(l10n.projectsArchived(1)), findsOneWidget);

    await tester.tap(find.text(l10n.itemUndo));
    await tester.pumpAndSettle();
    expect(find.text('Teamoverleg'), findsOneWidget);
    expect(find.text(l10n.projectsArchived(1)), findsNothing);
  });

  testDriftWidgets('a search result shows the project of the item', (
    tester,
  ) async {
    await startApp(
      tester,
      start: Destination.inbox,
      data: () async {
        await sample();
        await DriftSearchIndex(storage.database).processPending();
      },
    );
    await tester.tap(find.byTooltip(l10n.searchTooltip));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'vakantie');
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ProjectChip, 'Renovatie'), findsOneWidget);
  });
}
