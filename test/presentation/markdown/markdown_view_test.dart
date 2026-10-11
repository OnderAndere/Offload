import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/domain/markdown/markdown_document.dart';
import 'package:offload/presentation/markdown/markdown_view.dart';
import 'package:offload/presentation/theme/app_theme.dart';
import 'package:offload/presentation/theme/typography.dart';

/// The Markdown renderer (DD-020, REQ-065): the manual's subset in the
/// app's typeface, theme and text size.
void main() {
  Future<void> pump(
    WidgetTester tester,
    String source, {
    ValueChanged<String>? onLinkTap,
    Map<String, GlobalKey>? anchorKeys,
    double textScale = 1,
  }) {
    // A phone: 360 by 640 logical pixels.
    tester.view
      ..physicalSize = const Size(360, 640)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    return tester.pumpWidget(
      MaterialApp(
        theme: offloadTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: MarkdownView(
              blocks: parseMarkdown(source),
              onLinkTap: onLinkTap,
              anchorKeys: anchorKeys,
            ),
          ),
        ),
      ),
    );
  }

  /// The span with [text] inside the rich text that contains it.
  TextSpan span(WidgetTester tester, String text) {
    TextSpan? found;
    for (final rich in tester.widgetList<RichText>(find.byType(RichText))) {
      rich.text.visitChildren((s) {
        if (s is TextSpan && s.text == text) found = s;
        return found == null;
      });
    }
    return found!;
  }

  testWidgets('shows headings, paragraphs, lists, code and tables', (
    tester,
  ) async {
    await pump(
      tester,
      '# Title\n\nSome **bold** text.\n\n- one\n- two\n\n1. first\n\n'
      '```\ncode here\n```\n\n| Key | Does |\n|---|---|\n| N | New |\n',
    );
    expect(find.text('Title'), findsOneWidget);
    expect(find.text('Some bold text.'), findsOneWidget);
    expect(find.text('•'), findsNWidgets(2));
    expect(find.text('1.'), findsOneWidget);
    expect(find.text('first'), findsOneWidget);
    expect(find.text('code here'), findsOneWidget);
    expect(find.text('Does'), findsOneWidget);
    expect(find.text('New'), findsOneWidget);
    expect(span(tester, 'bold').style!.fontWeight, FontWeight.w600);
    final code = tester.widget<Text>(find.text('code here'));
    expect(code.style!.fontFamily, monoFamily);
  });

  testWidgets('a heading is marked as a heading for screen readers', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pump(tester, '## Saving\n\nText.\n');
    expect(
      tester.getSemantics(find.text('Saving')),
      matchesSemantics(label: 'Saving', isHeader: true),
    );
    semantics.dispose();
  });

  testWidgets('a tap on a link gives its target as written', (tester) async {
    final tapped = <String>[];
    await pump(
      tester,
      'See [Today](today.md#groups) or [up](#top).',
      onLinkTap: tapped.add,
    );
    (span(tester, 'Today').recognizer! as TapGestureRecognizer).onTap!();
    (span(tester, 'up').recognizer! as TapGestureRecognizer).onTap!();
    expect(tapped, ['today.md#groups', '#top']);
    expect(span(tester, 'Today').style!.decoration, TextDecoration.underline);
  });

  testWidgets('without a link handler a link is plain text', (tester) async {
    await pump(tester, 'See [Today](today.md).');
    expect(span(tester, 'Today').recognizer, isNull);
    expect(span(tester, 'Today').style!.decoration, isNull);
  });

  testWidgets('each heading can be scrolled to by its anchor', (tester) async {
    final keys = <String, GlobalKey>{};
    await pump(
      tester,
      '# Searching\n\n## Searching\n\n### What is searched\n',
      anchorKeys: keys,
    );
    expect(keys.keys, ['searching', 'searching-1', 'what-is-searched']);
    for (final key in keys.values) {
      expect(key.currentContext, isNotNull);
    }
  });

  group('every chapter of the manual', () {
    final chapters = Directory('docs/user-manual/en')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.md'))
        .toList();

    for (final chapter in chapters) {
      final name = chapter.uri.pathSegments.last;
      testWidgets('$name fits a phone at double text size', (tester) async {
        await pump(
          tester,
          chapter.readAsStringSync(),
          onLinkTap: (_) {},
          textScale: 2,
        );
        expect(tester.takeException(), isNull);
        expect(find.byType(MarkdownView), findsOneWidget);
      });
    }
  });
}
