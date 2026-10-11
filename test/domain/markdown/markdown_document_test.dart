import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:offload/domain/markdown/markdown_document.dart';

/// Markdown as blocks the app draws (DD-020, REQ-065): the user manual's
/// subset, with heading anchors as GitHub makes them.
void main() {
  group('headingAnchor', () {
    test('is lower case with hyphens for spaces', () {
      expect(headingAnchor('Capturing a thought'), 'capturing-a-thought');
    });

    test('drops punctuation but keeps hyphens, underscores and letters', () {
      expect(
        headingAnchor('Who asked for this? / Who are you waiting for?'),
        'who-asked-for-this--who-are-you-waiting-for',
      );
      expect(
        headingAnchor('The menu of a project (⋮)'),
        'the-menu-of-a-project-',
      );
      expect(headingAnchor('Step 1: Insights'), 'step-1-insights');
      expect(headingAnchor('snake_case and Ünïcode'), 'snake_case-and-ünïcode');
    });
  });

  group('parseMarkdown', () {
    test('headings get their level, text and a unique anchor', () {
      final blocks = parseMarkdown(
        '# Searching\n\n## Searching\n\n### *What* is `searched`\n',
      );
      final headings = blocks.cast<MarkdownHeading>();
      expect([for (final h in headings) h.level], [1, 2, 3]);
      expect(
        [for (final h in headings) h.anchor],
        ['searching', 'searching-1', 'what-is-searched'],
      );
      expect(headingAnchors(blocks), [
        'searching',
        'searching-1',
        'what-is-searched',
      ]);
    });

    test('a paragraph keeps bold, italic, code and links as runs', () {
      final p =
          parseMarkdown(
                'Tap **Capture**, then *type* `@Jan` or see '
                '[Today](today.md#groups).',
              ).single
              as MarkdownParagraph;
      expect(p.content, const [
        MarkdownInline('Tap '),
        MarkdownInline('Capture', bold: true),
        MarkdownInline(', then '),
        MarkdownInline('type', italic: true),
        MarkdownInline(' '),
        MarkdownInline('@Jan', code: true),
        MarkdownInline(' or see '),
        MarkdownInline('Today', link: 'today.md#groups'),
        MarkdownInline('.'),
      ]);
    });

    test('a single line break is a space, a hard break stays', () {
      final p =
          parseMarkdown(
                'What you see is\narranged `in\ngroups`.  \nNext line.',
              ).single
              as MarkdownParagraph;
      expect(
        p.content.map((i) => i.text).join(),
        'What you see is arranged in groups.\nNext line.',
      );
    });

    test('text is not HTML-escaped', () {
      final p = parseMarkdown('Fish & chips <3').single as MarkdownParagraph;
      expect(p.content.map((i) => i.text).join(), 'Fish & chips <3');
    });

    test('lists nest, and a numbered list keeps its start', () {
      final list =
          parseMarkdown('3. one\n4. two\n   - inner\n').single as MarkdownList;
      expect(list.ordered, isTrue);
      expect(list.start, 3);
      expect(list.items, hasLength(2));
      expect(
        (list.items[0].single as MarkdownParagraph).content.single.text,
        'one',
      );
      final inner = list.items[1][1] as MarkdownList;
      expect(inner.ordered, isFalse);
      expect(
        (inner.items.single.single as MarkdownParagraph).content.single.text,
        'inner',
      );
    });

    test('a code block keeps its text exactly, without the last newline', () {
      final code =
          parseMarkdown('```\n@Jan  !fri\n  #tag\n```\n').single
              as MarkdownCodeBlock;
      expect(code.text, '@Jan  !fri\n  #tag');
    });

    test('a table has its header, rows and alignment', () {
      final table =
          parseMarkdown(
                '| Key | Does |\n|:---|---:|\n| `N` | **New** item |\n',
              ).single
              as MarkdownTable;
      expect(table.alignments, [
        MarkdownAlignment.start,
        MarkdownAlignment.end,
      ]);
      expect(table.header, [
        const [MarkdownInline('Key')],
        const [MarkdownInline('Does')],
      ]);
      expect(table.rows.single, [
        const [MarkdownInline('N', code: true)],
        const [MarkdownInline('New', bold: true), MarkdownInline(' item')],
      ]);
    });

    test('quotes and rules', () {
      final blocks = parseMarkdown('> quoted\n\n---\n');
      expect(blocks.first, isA<MarkdownQuote>());
      expect(blocks.last, isA<MarkdownRule>());
    });

    test('HTML and images stay as text, nothing is loaded', () {
      final p =
          parseMarkdown('<b>bold?</b> ![a garden](garden.png)').single
              as MarkdownParagraph;
      expect(p.content.map((i) => i.text).join(), '<b>bold?</b> a garden');
    });
  });

  group('the user manual', () {
    final dir = Directory('docs/user-manual/en');
    final chapters = {
      for (final f in dir.listSync().whereType<File>())
        if (f.path.endsWith('.md'))
          f.uri.pathSegments.last: parseMarkdown(f.readAsStringSync()),
    };

    test('has chapters, each starting with a title', () {
      expect(chapters, contains('README.md'));
      for (final MapEntry(:key, :value) in chapters.entries) {
        expect(value.first, isA<MarkdownHeading>(), reason: key);
        expect((value.first as MarkdownHeading).level, 1, reason: key);
      }
    });

    test('every link between chapters reaches a chapter and a heading', () {
      final broken = <String>[];
      for (final MapEntry(key: chapter, value: blocks) in chapters.entries) {
        for (final link in _links(blocks)) {
          if (link.contains(':')) continue; // External: shown, not followed.
          final [file, ...rest] = link.split('#');
          final target = file.isEmpty ? chapter : file;
          final anchors = chapters[target];
          if (anchors == null ||
              (rest.isNotEmpty &&
                  !headingAnchors(anchors).contains(rest.join('#')))) {
            broken.add('$chapter → $link');
          }
        }
      }
      expect(broken, isEmpty);
    });
  });
}

Iterable<String> _links(List<MarkdownBlock> blocks) sync* {
  Iterable<String> runs(List<MarkdownInline> content) =>
      content.map((i) => i.link).whereType<String>();
  for (final block in blocks) {
    switch (block) {
      case MarkdownHeading(:final content) || MarkdownParagraph(:final content):
        yield* runs(content);
      case MarkdownList(:final items):
        for (final item in items) {
          yield* _links(item);
        }
      case MarkdownQuote(:final blocks):
        yield* _links(blocks);
      case MarkdownTable(:final header, :final rows):
        for (final cell in [...header, for (final row in rows) ...row]) {
          yield* runs(cell);
        }
      case MarkdownCodeBlock() || MarkdownRule():
        break;
    }
  }
}
