import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/items/drift_item_repository.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/domain/time/local_date.dart';
import 'package:offload/l10n/app_localizations.dart';
import 'package:offload/platform/share/share_channel.dart';
import 'package:offload/presentation/app.dart';
import 'package:offload/presentation/capture/pending_captures.dart';
import 'package:offload/presentation/items/share_preview.dart';
import 'package:offload/presentation/share_channel_provider.dart';
import 'package:offload/presentation/startup/app_storage_provider.dart';

import '../../fakes/drift_widgets.dart';
import '../../fakes/fake_capture_channel.dart';
import '../../fakes/fake_desktop_shell.dart';
import '../../fakes/fake_share_channel.dart';
import '../../fakes/start_on_inbox.dart';
import '../../fakes/test_storage.dart';

/// Sharing an item as text with an editable preview (REQ-043, DD-014).
void main() {
  final thisYear = DateTime.now().year;

  Future<FakeShareChannel> showPreview(
    WidgetTester tester, {
    required String rawText,
    Map<String, LocalDate> knownDates = const {},
    List<ShareTarget> targets = const [ShareTarget.system],
  }) async {
    final channel = FakeShareChannel(textTargets: targets);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [shareChannelProvider.overrideWith((ref) => channel)],
        child: MaterialApp(
          locale: const Locale('nl'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showSharePreview(
                  context,
                  rawText: rawText,
                  knownDates: knownDates,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return channel;
  }

  String preview(WidgetTester tester) => tester
      .widget<TextField>(
        find.descendant(
          of: find.byType(SharePreview),
          matching: find.byType(TextField),
        ),
      )
      .controller!
      .text;

  testWidgets('proposes the text without the inline syntax', (tester) async {
    await showPreview(
      tester,
      rawText: 'Bel @Jan over de offerte #renovatie !vr',
      knownDates: {'vr': LocalDate(thisYear, 10, 2)},
    );

    final weekday = [
      'maandag',
      'dinsdag',
      'woensdag',
      'donderdag',
      'vrijdag',
      'zaterdag',
      'zondag',
    ][LocalDate(thisYear, 10, 2).weekday - 1];
    expect(preview(tester), 'Bel Jan over de offerte $weekday 2 oktober');
    expect(find.text('Item delen'), findsOneWidget);
    expect(
      find.text('Wat je hier aanpast, verandert het item niet.'),
      findsOneWidget,
    );
  });

  testWidgets('a date in another year is written with the year', (
    tester,
  ) async {
    await showPreview(
      tester,
      rawText: 'Jubileum !1-1',
      knownDates: {'1-1': LocalDate(thisYear + 1, 1, 1)},
    );

    expect(preview(tester), endsWith('1 januari ${thisYear + 1}'));
  });

  testWidgets('as typed: the tokens stay, a date word becomes its date, the '
      'tags switch goes (T2.7a)', (tester) async {
    final channel = await showPreview(
      tester,
      rawText: 'Bel @Jan over #renovatie ^verbouwing *hoog !vr',
      knownDates: {'vr': LocalDate(thisYear, 10, 2)},
    );
    final l10n = lookupAppLocalizations(const Locale('nl'));
    await tester.tap(find.text(l10n.itemShareAsTyped));
    await tester.pumpAndSettle();

    expect(
      preview(tester),
      'Bel @Jan over #renovatie ^verbouwing *hoog !2-10-$thisYear',
    );
    expect(find.text(l10n.itemShareIncludeTags), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, l10n.itemShare));
    await tester.pumpAndSettle();
    expect(
      channel.shared.single.text,
      'Bel @Jan over #renovatie ^verbouwing *hoog !2-10-$thisYear',
    );
  });

  testWidgets('as typed off again: the plain proposal comes back', (
    tester,
  ) async {
    await showPreview(tester, rawText: 'Idee #renovatie voor @Jan');
    final l10n = lookupAppLocalizations(const Locale('nl'));
    await tester.tap(find.text(l10n.itemShareAsTyped));
    await tester.pumpAndSettle();
    expect(preview(tester), 'Idee #renovatie voor @Jan');
    await tester.tap(find.text(l10n.itemShareAsTyped));
    await tester.pumpAndSettle();
    expect(preview(tester), 'Idee voor Jan');
    expect(find.text(l10n.itemShareIncludeTags), findsOneWidget);
  });

  testWidgets('the switch takes the tags along', (tester) async {
    await showPreview(tester, rawText: 'Idee #renovatie voor @Jan');
    expect(preview(tester), 'Idee voor Jan');

    await tester.tap(find.text('Tags meenemen'));
    await tester.pumpAndSettle();

    expect(preview(tester), 'Idee #renovatie voor Jan');
  });

  testWidgets('sends exactly the edited text, with its first line as '
      'subject', (tester) async {
    final channel = await showPreview(tester, rawText: 'Bel @Jan');

    await tester.enterText(find.byType(TextField), 'Hoi,\n\nBel Jan even');
    await tester.tap(find.widgetWithText(FilledButton, 'Delen'));
    await tester.pumpAndSettle();

    expect(channel.shared.single.text, 'Hoi,\n\nBel Jan even');
    expect(channel.shared.single.subject, 'Hoi,');
    expect(channel.shared.single.target, ShareTarget.system);
    expect(find.byType(SharePreview), findsNothing);
  });

  testWidgets('an empty text cannot be shared', (tester) async {
    final channel = await showPreview(tester, rawText: '#renovatie');

    expect(preview(tester), '');
    await tester.tap(find.widgetWithText(FilledButton, 'Delen'));
    await tester.pumpAndSettle();

    expect(channel.shared, isEmpty);
    expect(find.byType(SharePreview), findsOneWidget);
  });

  testWidgets('Windows: copy and save as, with a message', (tester) async {
    final channel = await showPreview(
      tester,
      rawText: 'Offerte',
      targets: const [ShareTarget.clipboard, ShareTarget.file],
    );

    expect(find.widgetWithText(FilledButton, 'Kopiëren'), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Opslaan als…'));
    await tester.pumpAndSettle();

    expect(channel.shared.single.target, ShareTarget.file);
    expect(channel.shared.single.fileTypeName, 'Tekstbestand');
    expect(find.byType(SharePreview), findsNothing);
    expect(find.text('Opgeslagen'), findsOneWidget);
  });

  testWidgets('closing the save window keeps the preview', (tester) async {
    final channel = await showPreview(
      tester,
      rawText: 'Offerte',
      targets: const [ShareTarget.clipboard, ShareTarget.file],
    );
    channel.result = ShareResult.cancelled;

    await tester.tap(find.text('Opslaan als…'));
    await tester.pumpAndSettle();

    expect(find.byType(SharePreview), findsOneWidget);
    expect(find.text('Opgeslagen'), findsNothing);
  });

  testWidgets('a failure says so and keeps the preview', (tester) async {
    final channel = await showPreview(tester, rawText: 'Offerte');
    channel.fail = true;

    await tester.tap(find.widgetWithText(FilledButton, 'Delen'));
    await tester.pumpAndSettle();

    expect(find.byType(SharePreview), findsOneWidget);
    expect(
      find.text('Delen is niet gelukt. Probeer het nog eens.'),
      findsOneWidget,
    );
  });

  group('from the item detail', () {
    late AppStorage storage;

    testDriftWidgets('shares the text in the field; the item stays', (
      tester,
    ) async {
      tester.platformDispatcher.localesTestValue = const [Locale('nl')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      storage = await openTestStorage();
      addTearDown(storage.close);
      final items = DriftItemRepository(storage);
      final id = await items.capture('Offerte @Piet', source: ItemSource.app);
      final channel = FakeShareChannel();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            startOnInbox,
            appStorageProvider.overrideWith((ref) => storage),
            captureChannelProvider.overrideWith((ref) => FakeCaptureChannel()),
            desktopShellProvider.overrideWith((ref) => FakeDesktopShell()),
            shareChannelProvider.overrideWith((ref) => channel),
          ],
          child: const OffloadApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Offerte'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Delen'));
      await tester.pumpAndSettle();
      expect(preview(tester), 'Offerte Piet');
      await tester.enterText(
        find.descendant(
          of: find.byType(SharePreview),
          matching: find.byType(TextField),
        ),
        'Offerte Piet Jansen',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Delen'));
      await tester.pumpAndSettle();

      expect(channel.shared.single.text, 'Offerte Piet Jansen');
      final item = await (storage.database.select(
        storage.database.items,
      )..where((i) => i.id.equals(id))).getSingle();
      expect(item.rawText, 'Offerte @Piet');
    });
  });
}
