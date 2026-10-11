import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/database/app_database.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/domain/settings/prefix_bar_mode.dart';
import 'package:offload/domain/tokens/inline_token.dart';
import 'package:offload/domain/tokens/inline_token_registry.dart';
import 'package:offload/presentation/app.dart';
import 'package:offload/presentation/capture/capture_screen.dart';
import 'package:offload/presentation/capture/pending_captures.dart';
import 'package:offload/presentation/startup/app_storage_provider.dart';
import 'package:offload/presentation/tokens/prefix_bar.dart';
import 'package:offload/presentation/tokens/token_display.dart';

import '../../fakes/drift_widgets.dart';
import '../../fakes/fake_capture_channel.dart';
import '../../fakes/fake_desktop_shell.dart';
import '../../fakes/start_on_inbox.dart';
import '../../fakes/test_storage.dart';

/// The prefix bar and the syntax overview in quick capture (REQ-034; PO
/// decisions 27-09-2026).
void main() {
  late AppStorage storage;

  Future<void> startApp(
    WidgetTester tester, {
    PrefixBarMode? mode,
    InlineTokenRegistry? registry,
  }) async {
    tester.platformDispatcher.localesTestValue = const [Locale('nl')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    storage = await openTestStorage();
    addTearDown(storage.close);
    if (mode != null) await storage.savePrefixBarMode(mode);
    for (final name in ['Jan', 'Piet']) {
      await storage.writer.insert(
        storage.database.people,
        PeopleCompanion(name: Value(name)),
      );
    }
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          startOnInbox,
          appStorageProvider.overrideWith((ref) => storage),
          captureChannelProvider.overrideWith((ref) => FakeCaptureChannel()),
          desktopShellProvider.overrideWith((ref) => FakeDesktopShell()),
          if (registry != null)
            inlineTokenRegistryProvider.overrideWith((ref) => registry),
        ],
        child: const OffloadApp(),
      ),
    );
    await tester.pumpAndSettle();
    // The capture button: extended on a phone, + in the rail on Windows.
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
  }

  Future<void> setText(WidgetTester tester, String text, int cursor) async {
    await tester.showKeyboard(find.byType(TextField));
    tester.testTextInput.updateEditingValue(
      TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: cursor),
      ),
    );
    await tester.pumpAndSettle();
  }

  TextEditingController controller(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField)).controller!;

  Finder suggestion(String label) =>
      find.descendant(of: find.byType(ListTile), matching: find.text(label));

  testDriftWidgets('by default a button with sign and label per token', (
    tester,
  ) async {
    await startApp(tester);

    expect(find.text('@ persoon'), findsOneWidget);
    expect(find.text('# tag'), findsOneWidget);
    expect(find.text('! datum'), findsOneWidget);
    expect(find.text('?'), findsOneWidget);
  });

  testDriftWidgets('a button puts its sign at the cursor and opens the list', (
    tester,
  ) async {
    await startApp(tester);

    await tester.tap(find.text('@ persoon'));
    await tester.pumpAndSettle();

    expect(controller(tester).text, '@');
    expect(suggestion('Jan'), findsOneWidget);
    expect(suggestion('Piet'), findsOneWidget);
  });

  testDriftWidgets('right after a word a space goes first', (tester) async {
    await startApp(tester);
    await setText(tester, 'bel', 3);

    await tester.tap(find.text('@ persoon'));
    await tester.pumpAndSettle();

    expect(controller(tester).text, 'bel @');
    expect(suggestion('Jan'), findsOneWidget);
  });

  testDriftWidgets('in the middle of the text, at the cursor', (tester) async {
    await startApp(tester);
    await setText(tester, 'klaar  nu', 6);

    await tester.tap(find.text('! datum'));
    await tester.pumpAndSettle();

    expect(controller(tester).text, 'klaar ! nu');
    expect(controller(tester).selection.baseOffset, 7);
    expect(suggestion('vandaag'), findsOneWidget);
  });

  testDriftWidgets('after an opening bracket, no space', (tester) async {
    await startApp(tester);
    await setText(tester, 'bel (', 5);

    await tester.tap(find.text('# tag'));
    await tester.pumpAndSettle();

    expect(controller(tester).text, 'bel (#');
  });

  testDriftWidgets('? opens the syntax overview with an example per token', (
    tester,
  ) async {
    await startApp(tester);

    await tester.tap(find.text('?'));
    await tester.pumpAndSettle();

    final overview = find.byType(SyntaxOverview);
    expect(overview, findsOneWidget);
    final scrollable = find.descendant(
      of: overview,
      matching: find.byType(Scrollable),
    );
    // Scrolled into view one by one: the list only builds what is near.
    Future<void> seen(String text) async {
      final finder = find.descendant(of: overview, matching: find.text(text));
      await tester.scrollUntilVisible(finder, 50, scrollable: scrollable);
      expect(finder, findsOneWidget);
    }

    await seen('@ persoon');
    await seen('Bel @Jan over de offerte');
    await seen('Dakgoot schoonmaken #klussen');
    await seen('Offerte af !vrijdag, ook !morgen of !12-10');
    // Tokens without a sign are in the overview too (T3.6).
    await seen('telefoonnummer');
    await seen('Bel @Jan op 06-12345678 of +31 6 1234 5678');
    await seen('e-mailadres');
    await seen(r'\ gewone tekst');
  });

  testDriftWidgets('a new token type shows up in bar and overview', (
    tester,
  ) async {
    await startApp(
      tester,
      registry: InlineTokenRegistry([
        ...InlineTokenRegistry.standard().types,
        const _PercentTokenType(),
      ]),
    );

    // No look of its own yet: the fallback label, and no example line.
    expect(find.text('% herkend woord'), findsOneWidget);
    await tester.tap(find.text('?'));
    await tester.pumpAndSettle();
    final inOverview = find.descendant(
      of: find.byType(SyntaxOverview),
      matching: find.text('% herkend woord'),
    );
    await tester.scrollUntilVisible(
      inOverview,
      50,
      scrollable: find.descendant(
        of: find.byType(SyntaxOverview),
        matching: find.byType(Scrollable),
      ),
    );
    expect(inOverview, findsOneWidget);
  });

  testDriftWidgets('setting off: no bar', (tester) async {
    await startApp(tester, mode: PrefixBarMode.off);

    expect(find.byType(PrefixBar), findsNothing);
    expect(find.text('@ persoon'), findsNothing);
  });

  testDriftWidgets('collapsed: only the signs; expanding is remembered', (
    tester,
  ) async {
    await startApp(tester, mode: PrefixBarMode.collapsed);

    expect(find.text('@'), findsOneWidget);
    expect(find.text('@ persoon'), findsNothing);
    // The signs work in the slim row too.
    await tester.tap(find.text('#'));
    await tester.pumpAndSettle();
    expect(controller(tester).text, '#');

    await tester.tap(find.byTooltip('Uitklappen'));
    await tester.pumpAndSettle();

    expect(find.text('@ persoon'), findsOneWidget);
    expect(storage.prefixBarExpanded, isTrue);

    // Closed and opened again: still expanded.
    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();
    // The capture button: extended on a phone, + in the rail on Windows.
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('@ persoon'), findsOneWidget);

    await tester.tap(find.byTooltip('Inklappen'));
    await tester.pumpAndSettle();
    expect(find.text('@ persoon'), findsNothing);
    expect(storage.prefixBarExpanded, isFalse);
  });

  testDriftWidgets('saving is not slowed by the bar (REQ-001)', (tester) async {
    await startApp(tester);
    await tester.tap(find.text('@ persoon'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Opslaan'));
    await tester.pumpAndSettle();

    expect(find.byType(CaptureScreen), findsNothing);
  });

  group('on Windows (PO decision 27-09-2026)', () {
    final windows = TargetPlatformVariant.only(TargetPlatform.windows);

    testDriftWidgets('the same bar, right under the field', (tester) async {
      await startApp(tester);

      final field = tester.getRect(find.byType(TextField));
      final bar = tester.getRect(find.byType(PrefixBar));
      expect(bar.top, greaterThanOrEqualTo(field.bottom));
      expect(bar.top - field.bottom, lessThan(24));

      await tester.tap(find.text('@ persoon'));
      await tester.pumpAndSettle();
      expect(controller(tester).text, '@');
      expect(suggestion('Jan'), findsOneWidget);
    }, variant: windows);

    testDriftWidgets('the overview is a dialog with a close button', (
      tester,
    ) async {
      await startApp(tester);

      await tester.tap(find.text('?'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text('Sluiten'));
      await tester.pumpAndSettle();
      expect(find.byType(SyntaxOverview), findsNothing);
      expect(find.byType(CaptureScreen), findsOneWidget);
    }, variant: windows);
  });
}

/// A token type the presentation layer does not know yet.
class _PercentTokenType extends InlineTokenType {
  const _PercentTokenType();

  @override
  String get id => 'percent';

  @override
  TokenTrigger get trigger => const PrefixTrigger('%');

  @override
  int get schemaVersion => 1;

  @override
  Object? parse(String word, ParseContext context) => word;
}
