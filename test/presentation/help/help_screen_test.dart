import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/domain/help/help_topics.dart';
import 'package:offload/l10n/app_localizations.dart';
import 'package:offload/presentation/help/help_scope.dart';
import 'package:offload/presentation/help/help_screen.dart';
import 'package:offload/presentation/theme/app_theme.dart';

/// The help screen (REQ-065, DD-020): the manual from the app's bundle, with
/// links, anchors, Back, and internet addresses only shown.
void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final nl = lookupAppLocalizations(const Locale('nl'));
  final pages = {
    'README.md':
        '# Manual\n\nSee [Today](today.md), [far](long.md#bottom) and '
        '[web](https://example.org/x).\n',
    'today.md': '# Today\n\nBack to [contents](README.md).\n',
    'long.md':
        '# Long\n\n${List.filled(60, 'A line of text.').join('\n\n')}\n\n'
        '## Bottom\n\nThe end.\n',
  };

  Future<void> pump(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    HelpTopic topic = HelpTopic.contents,
    GlobalKey<NavigatorState>? navigatorKey,
    Widget? home,
  }) async {
    tester.view
      ..physicalSize = const Size(400, 700)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final key = navigatorKey ?? GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: _Bundle({
          for (final MapEntry(:key, :value) in pages.entries)
            manualAsset('en', key): value,
        }),
        child: MaterialApp(
          theme: offloadTheme(),
          navigatorKey: key,
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) =>
              HelpKey(navigatorKey: key, child: child!),
          home:
              home ??
              Builder(
                builder: (context) => Scaffold(
                  body: Center(
                    child: TextButton(
                      onPressed: () => HelpScreen.open(context, topic),
                      child: const Text('open'),
                    ),
                  ),
                ),
              ),
        ),
      ),
    );
    if (home == null) {
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }
  }

  Future<void> tapLink(WidgetTester tester, String text) async {
    TextSpan? found;
    for (final rich in tester.widgetList<RichText>(find.byType(RichText))) {
      rich.text.visitChildren((s) {
        if (s is TextSpan && s.text == text && s.recognizer != null) found = s;
        return found == null;
      });
    }
    (found!.recognizer! as TapGestureRecognizer).onTap!();
    await tester.pumpAndSettle();
  }

  Future<void> back(WidgetTester tester) async {
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
  }

  testWidgets('opens at the contents; a link opens a chapter; Back retraces', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text(en.helpTitle), findsOneWidget);
    expect(find.text('Manual'), findsOneWidget);
    expect(find.byTooltip(en.helpContents), findsNothing);

    await tapLink(tester, 'Today');
    expect(find.text('Today'), findsOneWidget);
    expect(find.byTooltip(en.helpContents), findsOneWidget);

    await back(tester);
    expect(find.text('Manual'), findsOneWidget);
    await back(tester);
    expect(find.byType(HelpScreen), findsNothing);
  });

  testWidgets('a link to a heading scrolls to it', (tester) async {
    await pump(tester);
    await tapLink(tester, 'far');
    final heading = tester.getRect(find.text('Bottom'));
    expect(heading.top, greaterThanOrEqualTo(0));
    expect(heading.bottom, lessThanOrEqualTo(700));
  });

  testWidgets('a topic opens its chapter; the contents button goes back up', (
    tester,
  ) async {
    await pump(tester, topic: HelpTopic.today);
    expect(find.text('Today'), findsOneWidget);
    await tester.tap(find.byTooltip(en.helpContents));
    await tester.pumpAndSettle();
    expect(find.text('Manual'), findsOneWidget);
  });

  testWidgets('an internet address is shown, never opened', (tester) async {
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text'] as String);
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
    await pump(tester);
    await tapLink(tester, 'web');
    expect(
      find.text(en.helpExternalLink('https://example.org/x')),
      findsOneWidget,
    );
    expect(find.text('Manual'), findsOneWidget);
    await tester.tap(find.text(en.helpCopy));
    await tester.pumpAndSettle();
    expect(copied, ['https://example.org/x']);
  });

  testWidgets('a chapter that cannot be read says so', (tester) async {
    await pump(tester, topic: HelpTopic.settings);
    expect(find.text(en.helpLoadFailed), findsOneWidget);
  });

  testWidgets('in Dutch it says the manual is in English', (tester) async {
    await pump(tester, locale: const Locale('nl'));
    expect(find.text(nl.helpInEnglish), findsOneWidget);
    expect(find.text('Manual'), findsOneWidget);
  });

  testWidgets('in English there is no such note', (tester) async {
    await pump(tester);
    expect(find.text(en.helpInEnglish), findsNothing);
  });

  testWidgets('Escape closes; F1 inside help goes to the contents', (
    tester,
  ) async {
    await pump(tester, topic: HelpTopic.today);
    await tester.sendKeyEvent(LogicalKeyboardKey.f1);
    await tester.pumpAndSettle();
    expect(find.text('Manual'), findsOneWidget);
    expect(find.byType(HelpScreen), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Today'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(HelpScreen), findsNothing);
  });

  testWidgets('F1 on the contents adds no step to go back through', (
    tester,
  ) async {
    await pump(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.f1);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(HelpScreen), findsNothing);
  });

  testWidgets('the "?" button opens the topic of its screen', (tester) async {
    await pump(
      tester,
      home: HelpScope(
        topic: HelpTopic.today,
        child: Scaffold(appBar: AppBar(actions: const [HelpButton()])),
      ),
    );
    await tester.tap(find.byTooltip(en.helpTooltip));
    await tester.pumpAndSettle();
    expect(find.text('Today'), findsOneWidget);
  });

  testWidgets('F1 opens the topic of the screen that has the focus', (
    tester,
  ) async {
    await pump(
      tester,
      home: const HelpScope(
        topic: HelpTopic.today,
        child: Scaffold(body: TextField(autofocus: true)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.f1);
    await tester.pumpAndSettle();
    expect(find.byType(HelpScreen), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
  });
}

/// Serves [pages] by asset key; anything else is missing.
class _Bundle extends CachingAssetBundle {
  _Bundle(this.pages);

  final Map<String, String> pages;

  @override
  Future<ByteData> load(String key) async {
    final text = pages[key];
    if (text == null) throw FlutterError('missing $key');
    return ByteData.sublistView(utf8.encode(text));
  }
}
