import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/database/app_database.dart';
import 'package:offload/data/items/drift_item_repository.dart';
import 'package:offload/data/people/drift_people_repository.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/domain/items/item_classification.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/domain/people/contact_detail.dart';
import 'package:offload/l10n/app_localizations.dart';
import 'package:offload/presentation/app.dart';
import 'package:offload/presentation/capture/pending_captures.dart';
import 'package:offload/presentation/home/destination.dart';
import 'package:offload/presentation/home/item_panes.dart';
import 'package:offload/presentation/people/person_contacts.dart';
import 'package:offload/presentation/people/person_screen.dart';
import 'package:offload/presentation/startup/app_storage_provider.dart';

import '../../fakes/drift_widgets.dart';
import '../../fakes/fake_capture_channel.dart';
import '../../fakes/fake_contact_launcher.dart';
import '../../fakes/fake_desktop_shell.dart';
import '../../fakes/test_storage.dart';

/// Contact details in the person profile (T3.5 step B, REQ-038, DD-018
/// point 9).
void main() {
  late AppStorage storage;
  late DriftPeopleRepository people;
  late String petra;
  late FakeContactLauncher launcher;
  final l10n = lookupAppLocalizations(const Locale('nl'));
  final windows = TargetPlatformVariant.only(TargetPlatform.windows);

  /// Starts on People with Petra and opens her.
  Future<void> openPetra(
    WidgetTester tester, {
    Future<void> Function()? data,
    double width = 400,
    bool canDial = true,
    bool launchFails = false,
  }) async {
    launcher = FakeContactLauncher(canDial: canDial, fails: launchFails);
    tester.view.physicalSize = Size(width, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.localesTestValue = const [Locale('nl')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    storage = await openTestStorage();
    addTearDown(storage.close);
    people = DriftPeopleRepository(storage);
    petra = await people.idFor('Petra Jansen');
    if (data != null) await data();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          destinationProvider.overrideWith((ref) => Destination.people),
          appStorageProvider.overrideWith((ref) => storage),
          captureChannelProvider.overrideWith((ref) => FakeCaptureChannel()),
          desktopShellProvider.overrideWith((ref) => FakeDesktopShell()),
          contactLauncherProvider.overrideWithValue(launcher),
        ],
        child: const OffloadApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Petra Jansen'));
    await tester.pumpAndSettle();
  }

  /// The live details, read once (never a watched stream in a widget test).
  Future<List<ContactDetailRow>> stored() => (storage.database.select(
    storage.database.contactDetails,
  )..where((c) => c.deletedAt.isNull())).get();

  Future<PeopleData> person() => (storage.database.select(
    storage.database.people,
  )..where((p) => p.id.equals(petra))).getSingle();

  Future<void> addThroughSheet(
    WidgetTester tester,
    ContactKind kind,
    String value,
  ) async {
    await tester.tap(
      find.widgetWithText(
        TextButton,
        kind == ContactKind.phone
            ? l10n.contactKindPhone
            : l10n.contactKindEmail,
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, value);
    await tester.pump();
  }

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, l10n.personSave));
    await tester.pumpAndSettle();
  }

  testDriftWidgets('job title and organisation as one line, through a dialog', (
    tester,
  ) async {
    await openPetra(tester);
    await tester.tap(find.text(l10n.personWorkAdd));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, l10n.personJobTitle),
      'Voorzitter',
    );
    await tester.enterText(
      find.widgetWithText(TextField, l10n.personOrganisation),
      'Tennisclub Groenoord',
    );
    await tester.pump();
    await save(tester);
    expect(
      find.text(l10n.personWork('Voorzitter', 'Tennisclub Groenoord')),
      findsOneWidget,
    );
    expect((await person()).jobTitle, 'Voorzitter');

    // An emptied field removes it; the other stays on its own.
    await tester.tap(
      find.text(l10n.personWork('Voorzitter', 'Tennisclub Groenoord')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, l10n.personJobTitle),
      '',
    );
    await tester.pump();
    await save(tester);
    expect(find.text('Tennisclub Groenoord'), findsOneWidget);
    expect((await person()).jobTitle, isNull);
  });

  testDriftWidgets('a number: the phone keyboard, Mobile by default', (
    tester,
  ) async {
    await openPetra(tester);
    expect(find.text(l10n.contactSection.toUpperCase()), findsOneWidget);
    await addThroughSheet(tester, ContactKind.phone, '06-12 34 56 78');
    expect(find.text(l10n.contactAddPhone), findsWidgets);
    final field = tester.widget<TextField>(find.byType(TextField).last);
    expect(field.keyboardType, TextInputType.phone);
    final mobile = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, l10n.contactStandardLabel('mobile')),
    );
    expect(mobile.selected, isTrue);
    await save(tester);

    expect(find.text('06-12 34 56 78'), findsOneWidget);
    expect(find.text(l10n.contactStandardLabel('mobile')), findsOneWidget);
    final row = (await stored()).single;
    expect(row.value, '06-12 34 56 78');
    expect(row.label, 'mobile');
  });

  testDriftWidgets('an address that does not fit stays in the sheet', (
    tester,
  ) async {
    await openPetra(tester);
    await addThroughSheet(tester, ContactKind.email, 'petra@example');
    final field = tester.widget<TextField>(find.byType(TextField).last);
    expect(field.keyboardType, TextInputType.emailAddress);
    await save(tester);
    expect(find.text(l10n.contactInvalidEmail), findsOneWidget);
    expect(await stored(), isEmpty);

    await tester.enterText(find.byType(TextField).last, 'petra@example.org');
    await tester.pump();
    await save(tester);
    expect(find.text('petra@example.org'), findsOneWidget);
    // A new address gets no label.
    expect((await stored()).single.label, isNull);
  });

  testDriftWidgets('an own label, in Cyrillic, is kept as typed', (
    tester,
  ) async {
    await openPetra(tester);
    await addThroughSheet(tester, ContactKind.email, 'olena@example.org');
    await tester.tap(find.widgetWithText(ChoiceChip, l10n.contactOwnLabel));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, l10n.contactOwnLabelField),
      'Робота',
    );
    await tester.pump();
    await save(tester);
    expect(find.text('Робота'), findsOneWidget);
    expect((await stored()).single.label, 'Робота');
  });

  testDriftWidgets('a tap dials a number and mails an address (step C)', (
    tester,
  ) async {
    await openPetra(
      tester,
      data: () async {
        await people.addContactDetail(petra, ContactKind.phone, '06-12345678');
        await people.addContactDetail(
          petra,
          ContactKind.email,
          'petra@example.org',
        );
      },
    );
    await tester.tap(find.text('06-12345678'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('petra@example.org'));
    await tester.pumpAndSettle();
    expect(launcher.dialled, ['06-12345678']);
    expect(launcher.mailed, ['petra@example.org']);

    // The menu offers the same first.
    await tester.tap(find.byTooltip(l10n.contactMenuTooltip).first);
    await tester.pumpAndSettle();
    expect(find.text(l10n.contactCall), findsOneWidget);
    await tester.tap(find.text(l10n.contactCall));
    await tester.pumpAndSettle();
    expect(launcher.dialled, ['06-12345678', '06-12345678']);
  });

  testDriftWidgets('no app to open it: a message, nothing else', (
    tester,
  ) async {
    await openPetra(
      tester,
      launchFails: true,
      data: () => people.addContactDetail(
        petra,
        ContactKind.email,
        'petra@example.org',
      ),
    );
    await tester.tap(find.text('petra@example.org'));
    await tester.pumpAndSettle();
    expect(find.text(l10n.contactLaunchFailed), findsOneWidget);
  });

  testDriftWidgets('⋮ changes a detail and deletes it, with undo', (
    tester,
  ) async {
    await openPetra(
      tester,
      data: () async {
        await people.addContactDetail(
          petra,
          ContactKind.phone,
          '020 123 4567',
          label: 'work',
        );
      },
    );
    await tester.tap(find.byTooltip(l10n.contactMenuTooltip));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.contactEdit));
    await tester.pumpAndSettle();
    expect(find.text(l10n.contactEditPhone), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, '020 765 4321');
    await tester.pump();
    await save(tester);
    expect(find.text('020 765 4321'), findsOneWidget);
    expect(find.text(l10n.contactStandardLabel('work')), findsOneWidget);

    await tester.tap(find.byTooltip(l10n.contactMenuTooltip));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.contactDelete));
    await tester.pumpAndSettle();
    expect(find.text('020 765 4321'), findsNothing);
    expect(find.text(l10n.contactDeletedPhone), findsOneWidget);
    expect(await stored(), isEmpty);

    await tester.tap(find.text(l10n.itemUndo));
    await tester.pumpAndSettle();
    expect(find.text('020 765 4321'), findsOneWidget);
    expect((await stored()).single.value, '020 765 4321');
  });

  testDriftWidgets('undo after the person was merged away says it failed', (
    tester,
  ) async {
    late String id;
    await openPetra(
      tester,
      data: () async {
        id = await people.addContactDetail(
          petra,
          ContactKind.email,
          'petra@example.org',
        );
      },
    );
    await tester.tap(find.byTooltip(l10n.contactMenuTooltip));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.contactDelete));
    await tester.pumpAndSettle();
    // Meanwhile Petra is merged into someone else (another device, sync).
    await people.merge(petra, await people.idFor('Petra J.'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.itemUndo));
    await tester.pumpAndSettle();
    expect(find.text(l10n.contactUndoFailed), findsOneWidget);
    final row = await (storage.database.select(
      storage.database.contactDetails,
    )..where((c) => c.id.equals(id))).getSingle();
    expect(row.deletedAt, isNotNull);
  });

  testDriftWidgets('a screen reader hears value, label and kind', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await openPetra(
      tester,
      data: () => people.addContactDetail(
        petra,
        ContactKind.phone,
        '06-12345678',
        label: 'mobile',
      ),
    );
    expect(
      find.bySemanticsLabel(
        l10n.contactRowSemanticsWithLabel(
          '06-12345678',
          l10n.contactStandardLabel('mobile'),
          l10n.contactKindPhone,
        ),
      ),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testDriftWidgets(
    'Windows: on a focused row Enter copies a number, Shift+F10 opens the '
    'menu, Delete deletes it with undo',
    (tester) async {
      String? copied;
      late String card;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await openPetra(
        tester,
        width: 1280,
        canDial: false,
        data: () async {
          // A card in Petra's lists, to select: Delete on a contact row must
          // never trash it (DD-018 point 9, precedence).
          final items = DriftItemRepository(storage);
          card = await items.capture(
            'Ledenlijst voor de nieuwsbrief',
            source: ItemSource.app,
          );
          await items.classify(
            card,
            ItemClassification(
              type: ItemType.request,
              status: ItemStatus.active,
              requesterId: petra,
              waitingOnId: null,
            ),
          );
          await people.addContactDetail(
            petra,
            ContactKind.phone,
            '06-12345678',
          );
          await people.addContactDetail(
            petra,
            ContactKind.email,
            'petra@example.org',
          );
        },
      );
      InkWell rowOf(int at) => tester.widget<InkWell>(
        find
            .descendant(
              of: find.byType(ContactRow).at(at),
              matching: find.byType(InkWell),
            )
            .first,
      );
      // The card selected, as ↑/↓ in the person pane do: a tap opens it as
      // a screen of its own there (DD-018 point 11).
      ProviderScope.containerOf(
        tester.element(find.byType(PersonScreen)),
      ).read(selectedItemProvider.notifier).state = card;
      await tester.pumpAndSettle();
      final number = rowOf(0);
      number.focusNode!.requestFocus();
      await tester.pump();

      // No dialler on Windows: Enter copies the number.
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(copied, '06-12345678');
      expect(find.text(l10n.contactCopied), findsOneWidget);
      expect(launcher.dialled, isEmpty);

      // ↓ goes to the address; Enter there mails it.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(rowOf(1).focusNode!.hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(launcher.mailed, ['petra@example.org']);

      number.focusNode!.requestFocus();
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      await tester.pumpAndSettle();
      expect(find.text(l10n.contactCopy), findsOneWidget);
      // No dialler on Windows: the menu has no Call.
      expect(find.text(l10n.contactCall), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text(l10n.contactCopy), findsNothing);

      number.focusNode!.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await tester.pumpAndSettle();
      expect([for (final d in await stored()) d.value], ['petra@example.org']);
      expect(find.text(l10n.contactDeletedPhone), findsOneWidget);
      final item = await (storage.database.select(
        storage.database.items,
      )..where((i) => i.id.equals(card))).getSingle();
      expect(item.deletedAt, isNull);
    },
    variant: windows,
  );
}
