import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/domain/people/calling_country.dart';
import 'package:offload/l10n/app_localizations.dart';
import 'package:offload/presentation/app.dart';
import 'package:offload/presentation/capture/pending_captures.dart';
import 'package:offload/presentation/items/item_detail_screen.dart';
import 'package:offload/presentation/startup/app_storage_provider.dart';

import '../../fakes/drift_widgets.dart';
import '../../fakes/fake_capture_channel.dart';
import '../../fakes/fake_desktop_shell.dart';
import '../../fakes/start_on_inbox.dart';
import '../../fakes/test_storage.dart';

/// Phone numbers and email addresses typed in the text go to the person
/// named in it (T3.6, REQ-039; PO decisions c–e, 02-10-2026).
void main() {
  late AppStorage storage;
  final l10n = lookupAppLocalizations(const Locale('nl'));

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
          captureChannelProvider.overrideWith((ref) => FakeCaptureChannel()),
          desktopShellProvider.overrideWith((ref) => FakeDesktopShell()),
        ],
        child: const OffloadApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> capture(WidgetTester tester, String text) async {
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), text);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(l10n.captureSave));
    await tester.pumpAndSettle();
  }

  /// The live details of the person called [name]: value and label.
  Future<List<(String, String?)>> detailsOf(String name) async {
    final db = storage.database;
    final person = await (db.select(
      db.people,
    )..where((p) => p.name.equals(name))).getSingle();
    final rows =
        await (db.select(db.contactDetails)
              ..where(
                (c) => c.personId.equals(person.id) & c.deletedAt.isNull(),
              )
              ..orderBy([(c) => OrderingTerm.asc(c.kind)]))
            .get();
    return [for (final r in rows) (r.value, r.label)];
  }

  testDriftWidgets('saving adds them to the person, with Undo', (tester) async {
    await startApp(tester);
    await capture(tester, 'Bel @Jan 06-12345678 of mail jan@voorbeeld.nl');

    expect(find.text(l10n.contactsTakenFromText(2, 'Jan')), findsOneWidget);
    expect(
      await detailsOf('Jan'),
      unorderedEquals([('06-12345678', 'mobile'), ('jan@voorbeeld.nl', null)]),
    );

    await tester.tap(find.text(l10n.itemUndo));
    await tester.pumpAndSettle();
    expect(await detailsOf('Jan'), isEmpty);
  });

  testDriftWidgets('while typing, the chip names the person', (tester) async {
    await startApp(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Bel @Jan 06-12345678');
    await tester.pumpAndSettle();

    expect(
      find.widgetWithText(Chip, l10n.tokenContactFor('06-12345678', 'Jan')),
      findsOneWidget,
    );
  });

  testDriftWidgets('without one person nothing is added', (tester) async {
    await startApp(tester);
    await capture(tester, 'Bel @Jan of @Piet op 06-12345678');

    expect(find.textContaining('Toegevoegd'), findsNothing);
    expect(
      await storage.database.select(storage.database.contactDetails).get(),
      isEmpty,
    );
  });

  testDriftWidgets('a number the person has already is not added again', (
    tester,
  ) async {
    await startApp(tester);
    await capture(tester, 'Bel @Jan op 06-12345678');
    await capture(tester, 'Nog eens @Jan bellen: +31 6 1234 5678');

    expect(await detailsOf('Jan'), [('06-12345678', 'mobile')]);
  });

  testDriftWidgets('the item detail: "Link to…" asks whose it is', (
    tester,
  ) async {
    await startApp(tester);
    await capture(tester, 'Terugbellen 020-1234567');
    await tester.tap(find.text('Terugbellen 020-1234567'));
    await tester.pumpAndSettle();
    expect(find.byType(ItemDetailScreen), findsOneWidget);

    await tester.tap(find.byTooltip(l10n.contactLinkTooltip));
    await tester.pumpAndSettle();
    expect(find.text(l10n.contactLinkTitle), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'Petra');
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.tokenSuggestionNew('Petra')));
    await tester.pumpAndSettle();

    expect(await detailsOf('Petra'), [('020-1234567', null)]);
    expect(find.text(l10n.contactsTakenFromText(1, 'Petra')), findsOneWidget);
  });

  testDriftWidgets('a number typed in the detail goes on leaving it', (
    tester,
  ) async {
    await startApp(tester);
    await capture(tester, 'Afspraak @Jan');
    await tester.tap(find.text('Afspraak'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField).first,
      'Afspraak @Jan jan@voorbeeld.nl',
    );
    await tester.pump();
    expect(
      await storage.database.select(storage.database.contactDetails).get(),
      isEmpty,
    );
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(await detailsOf('Jan'), [('jan@voorbeeld.nl', null)]);
    expect(find.text(l10n.contactsTakenFromText(1, 'Jan')), findsOneWidget);
    // Like every undo message it leaves by itself (DD-018).
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    expect(find.text(l10n.contactsTakenFromText(1, 'Jan')), findsNothing);
  });

  testDriftWidgets('trashing from the detail takes nothing (review)', (
    tester,
  ) async {
    await startApp(tester);
    await capture(tester, 'Afspraak @Jan');
    await tester.tap(find.text('Afspraak'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).first,
      'Afspraak @Jan 06-12345678',
    );
    await tester.pump();

    await tester.tap(find.byType(PopupMenuButton<void>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.itemMoveToTrash));
    await tester.pumpAndSettle();

    // Trashing is not saving: no detail for Jan, and the trash keeps its
    // Undo message.
    expect(await detailsOf('Jan'), isEmpty);
    expect(find.text(l10n.itemMovedToTrash), findsOneWidget);
  });

  testDriftWidgets('Settings: the country for phone numbers', (tester) async {
    await startApp(tester);
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    final dropdown = find.byType(DropdownButton<CallingCountry>);
    await tester.scrollUntilVisible(dropdown, 100);
    await tester.pumpAndSettle();
    expect(
      find.text(l10n.settingsCountryOption(l10n.countryName('NL'), '31')),
      findsOneWidget,
    );
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    // The open list starts at the chosen country; the next one is near.
    final next = l10n.settingsCountryOption(l10n.countryName('NZ'), '64');
    await tester.tap(find.text(next).last);
    await tester.pumpAndSettle();

    expect(storage.phoneCountry.isoCode, 'NZ');
  });
}
