import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/database/app_database.dart';
import 'package:offload/data/items/drift_item_repository.dart';
import 'package:offload/data/projects/drift_project_repository.dart';
import 'package:offload/data/snapshots/drift_snapshot_repository.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/domain/snapshots/snapshot.dart';
import 'package:offload/l10n/app_localizations.dart';
import 'package:offload/presentation/app.dart';
import 'package:offload/presentation/capture/pending_captures.dart';
import 'package:offload/presentation/items/item_detail_screen.dart';
import 'package:offload/presentation/projects/project_screen.dart';
import 'package:offload/presentation/settings/settings_screen.dart';
import 'package:offload/presentation/startup/app_storage_provider.dart';

import '../../fakes/drift_widgets.dart';
import '../../fakes/fake_capture_channel.dart';
import '../../fakes/fake_desktop_shell.dart';
import '../../fakes/test_storage.dart';

/// "Where was I" on Today (T4b.2, DD-018 point 13 (e), sketch 22 variant A).
void main() {
  late AppStorage storage;
  late DriftItemRepository items;
  late DriftSnapshotRepository notes;
  final l10n = lookupAppLocalizations(const Locale('nl'));

  Future<void> startApp(
    WidgetTester tester, {
    Future<void> Function()? seed,
  }) async {
    tester.platformDispatcher.localesTestValue = const [Locale('nl')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    storage = await openTestStorage();
    addTearDown(storage.close);
    items = DriftItemRepository(storage);
    notes = DriftSnapshotRepository(storage);
    await seed?.call();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appStorageProvider.overrideWith((ref) => storage),
          captureChannelProvider.overrideWith((ref) => FakeCaptureChannel()),
          desktopShellProvider.overrideWith((ref) => FakeDesktopShell()),
        ],
        child: const OffloadApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// An item with an open note whose next step is [step]; returns its id.
  Future<String> noted(String text, {String? step, String? inMind}) async {
    final id = await items.capture(text, source: ItemSource.app);
    await notes.save(ItemSnapshotOwner(id), nextStep: step, inMind: inMind);
    return id;
  }

  testDriftWidgets('open notes of items and projects show at the top', (
    tester,
  ) async {
    await startApp(
      tester,
      seed: () async {
        await noted('Offerte kozijnen', step: 'Prijzen in een tabel');
        await noted('Tuinplan', inMind: 'Schaduw achterin meten');
        final project = await DriftProjectRepository(
          storage,
        ).create('Verbouwing keuken');
        await notes.save(
          ProjectSnapshotOwner(project),
          nextStep: 'Tegelzetter mailen',
        );
      },
    );

    expect(find.text(l10n.todayNotesSection(3)), findsOneWidget);
    expect(find.text('Offerte kozijnen'), findsOneWidget);
    expect(find.text('Prijzen in een tabel'), findsOneWidget);
    expect(find.text(l10n.todayNoteInMind('Schaduw achterin meten')), findsOne);
    expect(find.text('Verbouwing keuken'), findsOneWidget);
    // Not deadlines: the empty message still shows below them.
    expect(find.text(l10n.todayEmptyTitle), findsOneWidget);
  });

  testDriftWidgets('more than three: "+n meer" unfolds the rest in place', (
    tester,
  ) async {
    await startApp(
      tester,
      seed: () async {
        for (final text in ['Een', 'Twee', 'Drie', 'Vier', 'Vijf']) {
          await noted('Item $text', step: 'Stap $text');
        }
      },
    );

    expect(find.text(l10n.todayNotesSection(5)), findsOneWidget);
    expect(find.textContaining('Stap '), findsNWidgets(3));
    await tester.tap(find.text(l10n.todayNotesMore(2)));
    await tester.pumpAndSettle();
    expect(find.textContaining('Stap '), findsNWidgets(5));
    expect(find.text(l10n.todayNotesMore(2)), findsNothing);
  });

  testDriftWidgets('notes of done items and resumed notes stay away', (
    tester,
  ) async {
    await startApp(
      tester,
      seed: () async {
        await noted('Open item', step: 'Verder');
        final done = await noted('Klaar item', step: 'Afgerond');
        final db = storage.database;
        await (db.update(db.items)..where((i) => i.id.equals(done))).write(
          const ItemsCompanion(status: Value(ItemStatus.done)),
        );
        final resumed = await noted('Hervat item', step: 'Weg');
        await notes.resume(ItemSnapshotOwner(resumed));
      },
    );

    expect(find.text(l10n.todayNotesSection(1)), findsOneWidget);
    expect(find.text('Verder'), findsOneWidget);
    expect(find.text('Afgerond'), findsNothing);
    expect(find.text('Weg'), findsNothing);
  });

  testDriftWidgets('a tap opens the item, with its resume card', (
    tester,
  ) async {
    await startApp(
      tester,
      seed: () => noted('Offerte kozijnen', step: 'Prijzen in een tabel'),
    );

    await tester.tap(find.text('Prijzen in een tabel'));
    await tester.pumpAndSettle();
    expect(find.byType(ItemDetailScreen), findsOneWidget);
    expect(find.text(l10n.resumeCardTitle.toUpperCase()), findsOneWidget);
  });

  testDriftWidgets('a tap on a project note opens the project', (tester) async {
    await startApp(
      tester,
      seed: () async {
        final project = await DriftProjectRepository(
          storage,
        ).create('Verbouwing keuken');
        await notes.save(
          ProjectSnapshotOwner(project),
          nextStep: 'Tegelzetter mailen',
        );
      },
    );

    await tester.tap(find.text('Tegelzetter mailen'));
    await tester.pumpAndSettle();
    expect(find.byType(ProjectScreen), findsOneWidget);
  });

  testDriftWidgets('switched off on this device: no group', (tester) async {
    await startApp(
      tester,
      seed: () async {
        await noted('Offerte kozijnen', step: 'Prijzen in een tabel');
        await storage.saveTodayNotesOn(false);
      },
    );

    expect(find.text(l10n.todayNotesSection(1)), findsNothing);
    expect(find.text('Prijzen in een tabel'), findsNothing);
  });

  testDriftWidgets('the switch in Settings turns it off and stores it', (
    tester,
  ) async {
    await startApp(
      tester,
      seed: () => noted('Offerte kozijnen', step: 'Prijzen in een tabel'),
    );
    expect(find.text('Prijzen in een tabel'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    final scrollable = find
        .descendant(
          of: find.byType(SettingsScreen),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text(l10n.settingsTodayNotes),
      200,
      scrollable: scrollable,
    );
    await tester.tap(find.text(l10n.settingsTodayNotes));
    await tester.pumpAndSettle();
    expect(storage.todayNotesOn, isFalse);

    // The system back, as on a phone.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Prijzen in een tabel'), findsNothing);
  });
}
