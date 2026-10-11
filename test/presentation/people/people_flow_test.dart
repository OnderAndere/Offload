import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/database/app_database.dart';
import 'package:offload/data/items/drift_item_repository.dart';
import 'package:offload/data/people/drift_people_repository.dart';
import 'package:offload/data/search/drift_search_index.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/data/tokens/drift_token_processor.dart';
import 'package:offload/domain/items/item_classification.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/domain/people/birthday.dart';
import 'package:offload/domain/time/local_date.dart';
import 'package:offload/domain/tokens/inline_token.dart';
import 'package:offload/domain/tokens/inline_token_registry.dart';
import 'package:offload/domain/tokens/token_processing.dart';
import 'package:offload/l10n/app_localizations.dart';
import 'package:offload/presentation/app.dart';
import 'package:offload/presentation/capture/pending_captures.dart';
import 'package:offload/presentation/home/destination.dart';
import 'package:offload/presentation/inbox/inbox_card.dart';
import 'package:offload/presentation/items/item_detail_screen.dart';
import 'package:offload/presentation/people/person_look.dart';
import 'package:offload/presentation/people/person_screen.dart';
import 'package:offload/presentation/settings/settings_screen.dart';
import 'package:offload/presentation/startup/app_storage_provider.dart';

import '../../fakes/drift_widgets.dart';
import '../../fakes/fake_capture_channel.dart';
import '../../fakes/fake_desktop_shell.dart';
import '../../fakes/test_storage.dart';

/// People: the destination, a person, renaming, the people of an item
/// (T3.2 step B, DD-018 point 7).
void main() {
  late AppStorage storage;
  late DriftItemRepository items;
  late DriftPeopleRepository people;
  final l10n = lookupAppLocalizations(const Locale('nl'));
  final windows = TargetPlatformVariant.only(TargetPlatform.windows);

  Future<void> startApp(
    WidgetTester tester, {
    Destination start = Destination.people,
    Future<void> Function()? data,
    double width = 400,
  }) async {
    tester.view.physicalSize = Size(width, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.localesTestValue = const [Locale('nl')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    storage = await openTestStorage();
    addTearDown(storage.close);
    items = DriftItemRepository(storage);
    people = DriftPeopleRepository(storage);
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

  /// Captures [text] and processes its tokens, as after a real capture.
  Future<String> add(
    String text, {
    ItemStatus status = ItemStatus.active,
    ItemType? type = ItemType.task,
    String? requester,
    String? waitingOn,
    LocalDate? due,
  }) async {
    final id = await items.capture(text, source: ItemSource.app);
    await DriftTokenProcessor(
      storage,
      registry: InlineTokenRegistry.standard(),
      dates: () => DateVocabulary.empty,
    ).process(id);
    await items.classify(
      id,
      ItemClassification(
        type: type,
        status: status,
        requesterId: requester,
        waitingOnId: waitingOn,
      ),
    );
    if (due != null) {
      final db = storage.database;
      await (db.update(db.items)..where((i) => i.id.equals(id))).write(
        ItemsCompanion(dueAt: Value(dateOnlyToStored(due))),
      );
    }
    return id;
  }

  /// The item row, read once (never a watched stream in a widget test).
  Future<Item> row(String id) => (storage.database.select(
    storage.database.items,
  )..where((i) => i.id.equals(id))).getSingle();

  late String jan;
  late String petra;

  Future<void> sample() async {
    jan = await people.idFor('Jan Bakker');
    // "Petra" stays an alias, so `@Petra` in a text is her (DD-015).
    petra = await people.idFor('Petra');
    await people.rename(petra, 'Petra Jansen');
    await people.idFor('Anna de Vries');
    await add(
      'Offerte nakijken',
      type: ItemType.request,
      requester: jan,
      due: LocalDate.of(DateTime.now()).addDays(-2),
    );
    await add('Notulen rondsturen', status: ItemStatus.inbox, requester: jan);
    await add('Menukaart', status: ItemStatus.waiting, waitingOn: jan);
    await add('Oud verzoek', status: ItemStatus.done, requester: jan);
    await add('Cadeau voor @Petra');
    await add('Data van Petra', status: ItemStatus.waiting, waitingOn: petra);
  }

  testDriftWidgets('the balance: totals, most open first, nothing open quiet', (
    tester,
  ) async {
    await startApp(tester, data: sample);

    expect(find.text(l10n.navPeople), findsWidgets);
    expect(find.text(l10n.peopleDeliverTotal(2, 1)), findsOneWidget);
    expect(find.text(l10n.peopleWaitTotal(2, 2)), findsOneWidget);
    // One sentence per row for a screen reader (DD-018 point 11).
    expect(
      find.bySemanticsLabel(
        RegExp(r'^Jan Bakker: jij levert 2, jij wacht op 1, oudste'),
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        RegExp(r'^Petra Jansen: jij levert 0, jij wacht op 1, oudste'),
      ),
      findsOneWidget,
    );
    // Nothing open: only the name.
    expect(find.bySemanticsLabel('Anna de Vries'), findsOneWidget);
    // Order: the most open items first, the others last.
    final y = {
      for (final name in ['Jan Bakker', 'Petra Jansen', 'Anna de Vries'])
        name: tester.getTopLeft(find.text(name)).dy,
    };
    expect(y['Jan Bakker']! < y['Petra Jansen']!, isTrue);
    expect(y['Petra Jansen']! < y['Anna de Vries']!, isTrue);
  });

  testDriftWidgets('old: from the threshold on, orange with ⏱; Settings', (
    tester,
  ) async {
    await startApp(
      tester,
      data: () async {
        await sample();
        // Asked 30 days ago: old with the default of 21 days.
        await items.setAskedOn(
          (await add('Oude vraag', requester: jan)),
          LocalDate.of(DateTime.now()).addDays(-30),
        );
      },
    );

    expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp(r'^Jan Bakker: .*, oud$')),
      findsOneWidget,
    );

    // Settings: "Oud na" is a choice of days.
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    final tile = find.widgetWithText(ListTile, l10n.settingsOldAfter);
    await tester.scrollUntilVisible(
      tile,
      100,
      scrollable: find
          .descendant(
            of: find.byType(SettingsScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: tile, matching: find.byType(DropdownButton<int>)),
    );
    await tester.pumpAndSettle();
    // The choice next to the current one: the menu opens around it, also
    // when the row is low on the screen.
    await tester.tap(find.text(l10n.settingsDays(30)).last);
    await tester.pumpAndSettle();
    expect(storage.oldAfterDays, 30);
  });

  testDriftWidgets('the filter field matches names and aliases', (
    tester,
  ) async {
    await startApp(
      tester,
      data: () async {
        await sample();
        await people.rename(jan, 'Jan de Bakker'); // "Jan Bakker" an alias
      },
    );
    await tester.enterText(
      find.widgetWithText(TextField, l10n.peopleFilterHint),
      'jan bak',
    );
    await tester.pumpAndSettle();
    expect(find.text('Jan de Bakker'), findsOneWidget);
    expect(find.text('Petra Jansen'), findsNothing);

    await tester.enterText(
      find.widgetWithText(TextField, l10n.peopleFilterHint),
      'zzz',
    );
    await tester.pumpAndSettle();
    expect(find.text(l10n.peopleNoMatch), findsOneWidget);
  });

  testDriftWidgets('a person: three lists, done folded; Back to the list', (
    tester,
  ) async {
    await startApp(tester, data: sample);
    await tester.tap(find.text('Jan Bakker'));
    await tester.pumpAndSettle();
    expect(find.byType(PersonScreen), findsOneWidget);

    String header(String list, int count) =>
        l10n.personList(list, 'Jan Bakker', count).toUpperCase();
    expect(find.text(header('requestedBy', 2)), findsOneWidget);
    expect(find.text(header('waitingFor', 1)), findsOneWidget);
    expect(find.text('Offerte nakijken'), findsOneWidget);
    expect(find.text('Menukaart'), findsOneWidget);
    // Done is folded.
    expect(find.text('Oud verzoek'), findsNothing);
    await tester.tap(find.text(l10n.projectGroup('done', 1)));
    await tester.pumpAndSettle();
    expect(find.text('Oud verzoek'), findsOneWidget);

    // Android Back: to the list, then to Today.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(PersonScreen), findsNothing);
    expect(find.text('Anna de Vries'), findsOneWidget);
  });

  testDriftWidgets('mentioned in: named with @, in neither other list', (
    tester,
  ) async {
    await startApp(tester, data: sample);
    await tester.tap(find.text('Petra Jansen'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        l10n.personList('mentionedIn', 'Petra Jansen', 1).toUpperCase(),
      ),
      findsOneWidget,
    );
    expect(find.text('Cadeau voor'), findsOneWidget);
    expect(find.text('Data van Petra'), findsOneWidget);
    // The person's own chip is left out on their screen.
    expect(
      find.descendant(
        of: find.byType(InboxCard),
        matching: find.byType(PersonRoleChip),
      ),
      findsNothing,
    );
  });

  testDriftWidgets('renaming: the old name stays an alias; a taken name no', (
    tester,
  ) async {
    await startApp(tester, data: sample);
    await tester.tap(find.text('Jan Bakker'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(l10n.personMenuTooltip));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.personRename));
    await tester.pumpAndSettle();

    final field = find.widgetWithText(TextField, l10n.personNameLabel);
    await tester.enterText(field, 'Petra Jansen');
    await tester.pump();
    await tester.tap(find.text(l10n.personSave));
    await tester.pumpAndSettle();
    expect(find.text(l10n.personErrorNameTaken), findsOneWidget);

    await tester.enterText(field, 'Jan de Bakker');
    await tester.pump();
    await tester.tap(find.text(l10n.personSave));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Jan de Bakker'), findsOneWidget);
    expect(find.text(l10n.personAliases('Jan Bakker')), findsOneWidget);
  });

  testDriftWidgets('the item detail: requester chip, change and open', (
    tester,
  ) async {
    late String id;
    await startApp(
      tester,
      start: Destination.inbox,
      data: () async {
        await sample();
        id = await add(
          'Bel terug',
          status: ItemStatus.inbox,
          type: ItemType.request,
        );
      },
    );
    await tester.tap(find.text('Bel terug'));
    await tester.pumpAndSettle();
    // A request without a requester asks for one.
    await tester.tap(find.text(l10n.triageWhoAsked));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.personChange));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Petra Jansen'));
    await tester.pumpAndSettle();
    expect((await row(id)).requesterId, petra);

    await tester.tap(find.text('Petra Jansen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.personOpen('Petra Jansen')));
    await tester.pumpAndSettle();
    expect(find.byType(PersonScreen), findsOneWidget);
    expect(find.text('Bel terug'), findsOneWidget);

    // Back returns to the item.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(ItemDetailScreen), findsOneWidget);
  });

  testDriftWidgets('wait for… asks who, with the people in the text first', (
    tester,
  ) async {
    late String id;
    await startApp(
      tester,
      start: Destination.inbox,
      data: () async {
        await sample();
        id = await add('Rapport van @Petra', status: ItemStatus.inbox);
      },
    );
    await tester.tap(find.text('Rapport van'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.itemWaitFor));
    await tester.pumpAndSettle();
    expect(find.text(l10n.triageWaitingOn), findsOneWidget);
    expect(find.text(l10n.personInText), findsOneWidget);
    final first = tester.getTopLeft(find.text('Petra Jansen').last);
    final other = tester.getTopLeft(find.text('Anna de Vries').last);
    expect(first.dy, lessThan(other.dy));

    await tester.tap(find.text('Petra Jansen').last);
    await tester.pumpAndSettle();
    final stored = await row(id);
    expect(stored.status, ItemStatus.waiting);
    expect(stored.waitingOnId, petra);
    // The detail shows who it waits on now.
    expect(
      find.bySemanticsLabel(
        l10n.tokenChipSemantics(l10n.personWaitingKind, 'Petra Jansen'),
      ),
      findsOneWidget,
    );
  });

  testDriftWidgets('closing the person sheet leaves the item as it was', (
    tester,
  ) async {
    late String id;
    await startApp(
      tester,
      start: Destination.inbox,
      data: () async => id = await add('Iets', status: ItemStatus.inbox),
    );
    await tester.tap(find.text('Iets'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.itemWaitFor));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(200, 20)); // the scrim
    await tester.pumpAndSettle();
    expect((await row(id)).status, ItemStatus.inbox);
  });

  testDriftWidgets('a tap on an @person chip in the detail opens the person', (
    tester,
  ) async {
    await startApp(
      tester,
      start: Destination.inbox,
      data: () async {
        await sample();
        await add('Cadeau @Petra kopen', status: ItemStatus.inbox);
      },
    );
    await tester.tap(find.text('Cadeau kopen'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ActionChip, 'Petra'));
    await tester.pumpAndSettle();
    expect(find.byType(PersonScreen), findsOneWidget);
    expect(find.text('Petra Jansen'), findsOneWidget);
  });

  testDriftWidgets('cards show the people the text does not name', (
    tester,
  ) async {
    await startApp(
      tester,
      start: Destination.inbox,
      data: () async {
        final kees = await people.idFor('Kees');
        await add('Lijst @Kees', status: ItemStatus.inbox, requester: kees);
        await add(
          'Lijst zonder naam',
          status: ItemStatus.inbox,
          requester: kees,
        );
      },
    );
    final roleChips = find.descendant(
      of: find.byType(InboxCard),
      matching: find.widgetWithText(PersonRoleChip, 'Kees'),
    );
    // Only on the card whose text does not name Kees.
    expect(roleChips, findsOneWidget);
    expect(
      find.descendant(
        of: find.widgetWithText(InboxCard, 'Lijst zonder naam'),
        matching: find.byType(PersonRoleChip),
      ),
      findsOneWidget,
    );
  });

  testDriftWidgets(
    'Windows: Ctrl+4, arrows and Enter open a person, Escape goes back',
    (tester) async {
      await startApp(
        tester,
        start: Destination.today,
        data: sample,
        width: 1280,
      );
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit4);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pumpAndSettle();
      expect(find.text('Anna de Vries'), findsOneWidget);

      // Jan first: the most open items (DD-018 point 11).
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      // The person opens in the right pane; the balance stays.
      expect(find.byType(PersonScreen), findsOneWidget);
      expect(find.text('Offerte nakijken'), findsOneWidget);
      expect(find.text('Anna de Vries'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(PersonScreen), findsNothing);
      // Back in the list: the arrows work again.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(PersonScreen), findsOneWidget);
    },
    variant: windows,
  );

  /// Ctrl+4, then ↓ and Enter: Jan (the most open items) in the right pane.
  Future<void> openJanByKeys(WidgetTester tester) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit4);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(PersonScreen), findsOneWidget);
  }

  testDriftWidgets(
    'Windows: in the person pane the arrows and Enter open a card',
    (tester) async {
      await startApp(
        tester,
        start: Destination.today,
        data: sample,
        width: 1280,
      );
      await openJanByKeys(tester);

      // The keys are in the person pane: ↓ selects the overdue request
      // first (the 1-on-1 preparation), Enter opens it as a screen.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      final detail = tester.widget<ItemDetailScreen>(
        find.byType(ItemDetailScreen),
      );
      expect(detail.embedded, isFalse);
      expect(find.text('Offerte nakijken'), findsWidgets);

      // Escape goes back to the person, also with no focus in the text.
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(ItemDetailScreen), findsNothing);
      expect(find.byType(PersonScreen), findsOneWidget);

      // Escape closes the person; the card selected there is no longer.
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(PersonScreen), findsNothing);
      expect(find.byType(ItemDetailScreen), findsNothing);
      expect(find.text(l10n.panesChooseItem), findsOneWidget);
    },
    variant: windows,
  );

  testDriftWidgets(
    'Windows: search with a person open shows the chosen item, then the person',
    (tester) async {
      await startApp(
        tester,
        start: Destination.today,
        width: 1280,
        data: () async {
          await sample();
          await DriftSearchIndex(storage.database).processPending();
        },
      );
      await openJanByKeys(tester);

      await tester.enterText(
        find.widgetWithText(TextField, l10n.searchHint),
        'Menukaart',
      );
      await tester.pumpAndSettle();
      expect(find.byType(PersonScreen), findsNothing);
      // The result, not the search field.
      await tester.tap(
        find.byWidgetPredicate((w) => w is Text && w.data == 'Menukaart'),
      );
      await tester.pumpAndSettle();
      final detail = tester.widget<ItemDetailScreen>(
        find.byType(ItemDetailScreen),
      );
      expect(detail.embedded, isTrue);

      // An empty search field: the balance, and the person beside it.
      await tester.tap(find.byTooltip(l10n.searchClear));
      await tester.pumpAndSettle();
      expect(find.text(l10n.peopleDeliverTitle), findsOneWidget);
      expect(find.byType(PersonScreen), findsOneWidget);
    },
    variant: windows,
  );

  testDriftWidgets('a narrow window: the bars shrink, no error', (
    tester,
  ) async {
    await startApp(tester, data: sample, width: 230);
    expect(tester.takeException(), isNull);
    expect(find.text('Jan Bakker'), findsOneWidget);
  });

  testDriftWidgets(
    'Windows: @person in the detail pane opens the person in that pane',
    (tester) async {
      await startApp(
        tester,
        start: Destination.inbox,
        width: 1280,
        data: () async {
          await sample();
          await add('Cadeau @Petra kopen', status: ItemStatus.inbox);
        },
      );
      await tester.tap(find.text('Cadeau kopen'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ActionChip, 'Petra'));
      await tester.pumpAndSettle();

      // The person takes the right pane (DD-018 point 11); the balance is
      // in the list pane.
      expect(find.byType(PersonScreen), findsOneWidget);
      expect(find.byType(ItemDetailScreen), findsNothing);
      expect(find.text(l10n.peopleDeliverTitle), findsOneWidget);
      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.selectedIndex, Destination.people.index);
    },
    variant: windows,
  );

  testDriftWidgets('Windows: a person in the search results opens the person', (
    tester,
  ) async {
    await startApp(
      tester,
      start: Destination.today,
      width: 1280,
      data: () async {
        await sample();
        await DriftSearchIndex(storage.database).processPending();
      },
    );
    await tester.enterText(
      find.widgetWithText(TextField, l10n.searchHint),
      'Petra',
    );
    await tester.pumpAndSettle();
    // The person result itself, not an item that shows her as a chip.
    await tester.tap(
      find.byWidgetPredicate(
        (w) =>
            w is ListTile &&
            w.title is Text &&
            (w.title! as Text).data == 'Petra Jansen',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PersonScreen), findsOneWidget);
    // The search field made way.
    expect(find.widgetWithText(TextField, 'Petra'), findsNothing);
  }, variant: windows);

  /// The person row, read once (never a watched stream in a widget test).
  Future<PeopleData> personRow(String id) => (storage.database.select(
    storage.database.people,
  )..where((p) => p.id.equals(id))).getSingle();

  testDriftWidgets(
    'merging: choose, confirm, the screen shows the other; undo',
    (tester) async {
      late String janB;
      late String asked;
      await startApp(
        tester,
        data: () async {
          await sample();
          janB = await people.idFor('Jan B');
          asked = await add('Vraag van Jan B', requester: janB);
        },
      );
      await tester.tap(find.text('Jan B'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(l10n.personMenuTooltip));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.personMerge));
      await tester.pumpAndSettle();
      expect(find.text(l10n.personMergePickerTitle('Jan B')), findsOneWidget);
      await tester.tap(find.widgetWithText(ListTile, 'Jan Bakker'));
      await tester.pumpAndSettle();
      expect(
        find.text(l10n.personMergeBody('Jan B', 'Jan Bakker')),
        findsOneWidget,
      );
      await tester.tap(find.text(l10n.personMergeConfirm));
      await tester.pumpAndSettle();

      // The screen shows Jan Bakker now, with the item of Jan B.
      expect(find.text(l10n.personAliases('Jan B')), findsOneWidget);
      expect(find.text('Vraag van Jan B'), findsOneWidget);
      expect((await row(asked)).requesterId, jan);
      expect((await personRow(janB)).mergedIntoId, jan);

      await tester.tap(find.text(l10n.itemUndo));
      await tester.pumpAndSettle();
      expect((await personRow(janB)).deletedAt, isNull);
      expect((await row(asked)).requesterId, janB);
    },
  );

  testDriftWidgets('a refused rename offers merging with the other', (
    tester,
  ) async {
    late String janB;
    await startApp(
      tester,
      data: () async {
        await sample();
        janB = await people.idFor('Jan B');
      },
    );
    await tester.tap(find.text('Jan B'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(l10n.personMenuTooltip));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.personRename));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, l10n.personNameLabel),
      'jan bakker',
    );
    await tester.pump();
    await tester.tap(find.text(l10n.personSave));
    await tester.pumpAndSettle();
    expect(find.text(l10n.personErrorNameTaken), findsOneWidget);

    await tester.tap(find.text(l10n.personMergeWith('Jan Bakker')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.personMergeConfirm));
    await tester.pumpAndSettle();
    expect((await personRow(janB)).mergedIntoId, jan);
    expect(find.text(l10n.personAliases('Jan B')), findsOneWidget);
  });

  testDriftWidgets('merging a person opened from an item; Enter in the list', (
    tester,
  ) async {
    await startApp(
      tester,
      start: Destination.inbox,
      data: () async {
        await sample();
        await add('Cadeau @Petra kopen', status: ItemStatus.inbox);
      },
    );
    await tester.tap(find.text('Cadeau kopen'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ActionChip, 'Petra'));
    await tester.pumpAndSettle();
    expect(find.byType(PersonScreen), findsOneWidget);

    await tester.tap(find.byTooltip(l10n.personMenuTooltip));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.personMerge));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, l10n.peopleFilterHint),
      'bakker',
    );
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(
      find.text(l10n.personMergeBody('Petra Jansen', 'Jan Bakker')),
      findsOneWidget,
    );
    await tester.tap(find.text(l10n.personMergeConfirm));
    await tester.pumpAndSettle();

    // One person screen, now of Jan Bakker; back returns to the item.
    expect(find.byType(PersonScreen), findsOneWidget);
    expect((await personRow(petra)).mergedIntoId, jan);
    expect(find.text('Jan Bakker'), findsWidgets);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(ItemDetailScreen), findsOneWidget);
  });

  testDriftWidgets('the profile: a birthday with its age; a wrong date no', (
    tester,
  ) async {
    await startApp(tester, data: sample);
    await tester.tap(find.text('Anna de Vries'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.personBirthdayAdd));
    await tester.pumpAndSettle();

    Future<void> fill(String day, int month, String year) async {
      await tester.enterText(
        find.widgetWithText(TextField, l10n.personBirthdayDay),
        day,
      );
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(
        find.text(l10n.personMonthName(DateTime(2000, month))).last,
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, l10n.personBirthdayYear),
        year,
      );
      await tester.pump();
      await tester.tap(find.text(l10n.personSave));
      await tester.pumpAndSettle();
    }

    await fill('31', 4, '');
    expect(find.text(l10n.personBirthdayInvalid), findsOneWidget);
    await fill('3', 4, '1980');
    expect(find.byType(AlertDialog), findsNothing);

    final birthday = Birthday.tryCreate(3, 4, 1980)!;
    final age = birthday.ageOn(LocalDate.of(DateTime.now()))!;
    expect(
      find.text(l10n.personBirthdayWithAge(DateTime(1980, 4, 3), age)),
      findsOneWidget,
    );
    final rows = await storage.database.select(storage.database.people).get();
    final anna = rows.firstWhere((p) => p.name == 'Anna de Vries');
    expect(
      (anna.birthdayDay, anna.birthdayMonth, anna.birthdayYear),
      (3, 4, 1980),
    );
  });

  testDriftWidgets('the profile note saves itself, and when leaving', (
    tester,
  ) async {
    await startApp(tester, data: sample);
    await tester.tap(find.text('Anna de Vries'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, l10n.personNoteLabel),
      'Werkt bij de bibliotheek',
    );
    // Before the pause nothing is written; leaving saves it.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    final rows = await storage.database.select(storage.database.people).get();
    expect(
      rows.firstWhere((p) => p.name == 'Anna de Vries').note,
      'Werkt bij de bibliotheek',
    );
  });

  String noteField(WidgetTester tester) => tester
      .widget<TextField>(find.widgetWithText(TextField, l10n.personNoteLabel))
      .controller!
      .text;

  testDriftWidgets('the note saves itself after a pause', (tester) async {
    await startApp(tester, data: sample);
    await tester.tap(find.text('Anna de Vries'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, l10n.personNoteLabel),
      'Fietst graag',
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    final rows = await storage.database.select(storage.database.people).get();
    expect(
      rows.firstWhere((p) => p.name == 'Anna de Vries').note,
      'Fietst graag',
    );
  });

  testDriftWidgets('after a merge the note field shows both notes; undo too', (
    tester,
  ) async {
    late String janB;
    await startApp(
      tester,
      data: () async {
        await sample();
        janB = await people.idFor('Jan B');
        await people.setNote(janB, 'Notitie A');
        await people.setNote(jan, 'Notitie B');
      },
    );
    await tester.tap(find.text('Jan B'));
    await tester.pumpAndSettle();
    expect(noteField(tester), 'Notitie A');
    await tester.tap(find.byTooltip(l10n.personMenuTooltip));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.personMerge));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Jan Bakker'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.personMergeConfirm));
    await tester.pumpAndSettle();
    expect(noteField(tester), 'Notitie B\n\nNotitie A');

    await tester.tap(find.text(l10n.itemUndo));
    await tester.pumpAndSettle();
    expect(noteField(tester), 'Notitie B');
    expect((await personRow(jan)).note, 'Notitie B');
  });
}
