import 'package:markdown/markdown.dart' as md;

/// A Markdown text as blocks the app can draw (DD-020, REQ-065): the subset
/// the user manual uses, shared with Markdown in notes (T10.10). Parsing is
/// GitHub flavoured; what the app does not draw (HTML, images) is kept as
/// plain text, so nothing written is lost.
sealed class MarkdownBlock {
  const MarkdownBlock();
}

/// A heading of [level] 1–6. [anchor] is its link target within the text
/// (`chapter.md#anchor`), made as GitHub makes it, see [headingAnchor].
final class MarkdownHeading extends MarkdownBlock {
  const MarkdownHeading(this.level, this.content, this.anchor);

  final int level;
  final List<MarkdownInline> content;
  final String anchor;
}

final class MarkdownParagraph extends MarkdownBlock {
  const MarkdownParagraph(this.content);

  final List<MarkdownInline> content;
}

/// A bulleted or numbered list; each item holds blocks of its own, so lists
/// can nest. A numbered list counts from [start].
final class MarkdownList extends MarkdownBlock {
  const MarkdownList({
    required this.ordered,
    required this.start,
    required this.items,
  });

  final bool ordered;
  final int start;
  final List<List<MarkdownBlock>> items;
}

/// A fenced or indented code block, shown exactly as written.
final class MarkdownCodeBlock extends MarkdownBlock {
  const MarkdownCodeBlock(this.text);

  final String text;
}

/// A table: a [header] row and [rows], each a list of cells; [alignments]
/// holds one entry per column.
final class MarkdownTable extends MarkdownBlock {
  const MarkdownTable({
    required this.alignments,
    required this.header,
    required this.rows,
  });

  final List<MarkdownAlignment> alignments;
  final List<List<MarkdownInline>> header;
  final List<List<List<MarkdownInline>>> rows;
}

enum MarkdownAlignment { start, center, end }

final class MarkdownQuote extends MarkdownBlock {
  const MarkdownQuote(this.blocks);

  final List<MarkdownBlock> blocks;
}

final class MarkdownRule extends MarkdownBlock {
  const MarkdownRule();
}

/// A run of text with one style. A [link] holds the target as written
/// (`other.md#anchor`, `#anchor` or an external address); what a tap does
/// with it is up to the screen.
final class MarkdownInline {
  const MarkdownInline(
    this.text, {
    this.bold = false,
    this.italic = false,
    this.code = false,
    this.link,
  });

  final String text;
  final bool bold;
  final bool italic;
  final bool code;
  final String? link;

  @override
  bool operator ==(Object other) =>
      other is MarkdownInline &&
      other.text == text &&
      other.bold == bold &&
      other.italic == italic &&
      other.code == code &&
      other.link == link;

  @override
  int get hashCode => Object.hash(text, bold, italic, code, link);

  @override
  String toString() =>
      'MarkdownInline($text${bold ? ', bold' : ''}${italic ? ', italic' : ''}'
      '${code ? ', code' : ''}${link == null ? '' : ', link: $link'})';
}

/// The anchor GitHub gives a heading with [text]: lower case, everything
/// but letters, digits, `-`, `_` and spaces removed, spaces as `-`. A
/// repeated heading gets `-1`, `-2`… from [parseMarkdown].
String headingAnchor(String text) =>
    text.toLowerCase().replaceAll(_notInAnchor, '').replaceAll(' ', '-');

final _softBreak = RegExp(r'[ \t]*\r?\n[ \t]*');

final _notInAnchor = RegExp(r'[^\p{L}\p{M}\p{N}\p{Pc} -]', unicode: true);

/// Parses [source] into blocks.
List<MarkdownBlock> parseMarkdown(String source) {
  final nodes = md.Document(
    extensionSet: md.ExtensionSet.gitHubFlavored,
    encodeHtml: false,
  ).parse(source);
  return _Converter().blocks(nodes);
}

/// The anchors of every heading in [blocks], in order.
List<String> headingAnchors(List<MarkdownBlock> blocks) => [
  for (final block in blocks)
    ...switch (block) {
      MarkdownHeading(:final anchor) => [anchor],
      MarkdownList(:final items) => [
        for (final item in items) ...headingAnchors(item),
      ],
      MarkdownQuote(:final blocks) => headingAnchors(blocks),
      _ => const <String>[],
    },
];

class _Converter {
  final _anchorsSeen = <String, int>{};

  List<MarkdownBlock> blocks(List<md.Node> nodes) {
    final out = <MarkdownBlock>[];
    final loose = <md.Node>[];
    void flushLoose() {
      final content = inlines(loose);
      if (content.isNotEmpty) out.add(MarkdownParagraph(content));
      loose.clear();
    }

    for (final node in nodes) {
      final block = node is md.Element ? _block(node) : null;
      if (block == null) {
        // Inline content directly in a block, as in a tight list item.
        loose.add(node);
      } else {
        flushLoose();
        out.add(block);
      }
    }
    flushLoose();
    return out;
  }

  MarkdownBlock? _block(md.Element e) {
    switch (e.tag) {
      case 'h1' || 'h2' || 'h3' || 'h4' || 'h5' || 'h6':
        final content = inlines(e.children ?? const []);
        return MarkdownHeading(
          int.parse(e.tag.substring(1)),
          content,
          _uniqueAnchor(headingAnchor(content.map((i) => i.text).join())),
        );
      case 'p':
        return MarkdownParagraph(inlines(e.children ?? const []));
      case 'ul' || 'ol':
        return MarkdownList(
          ordered: e.tag == 'ol',
          start: int.tryParse(e.attributes['start'] ?? '') ?? 1,
          items: [
            for (final item in e.children ?? const <md.Node>[])
              if (item is md.Element && item.tag == 'li')
                blocks(item.children ?? const []),
          ],
        );
      case 'pre':
        final text = e.textContent;
        return MarkdownCodeBlock(
          text.endsWith('\n') ? text.substring(0, text.length - 1) : text,
        );
      case 'blockquote':
        return MarkdownQuote(blocks(e.children ?? const []));
      case 'hr':
        return const MarkdownRule();
      case 'table':
        return _table(e);
    }
    return null;
  }

  MarkdownTable _table(md.Element table) {
    final rows = <md.Element>[
      for (final section in table.children ?? const <md.Node>[])
        if (section is md.Element)
          for (final row in section.children ?? const <md.Node>[])
            if (row is md.Element && row.tag == 'tr') row,
    ];
    List<md.Element> cells(md.Element row) => [
      for (final cell in row.children ?? const <md.Node>[])
        if (cell is md.Element) cell,
    ];
    final head = rows.isEmpty ? <md.Element>[] : cells(rows.first);
    return MarkdownTable(
      alignments: [
        for (final cell in head)
          switch (cell.attributes['align']) {
            'center' => MarkdownAlignment.center,
            'right' => MarkdownAlignment.end,
            _ => MarkdownAlignment.start,
          },
      ],
      header: [for (final cell in head) inlines(cell.children ?? const [])],
      rows: [
        for (final row in rows.skip(1))
          [for (final cell in cells(row)) inlines(cell.children ?? const [])],
      ],
    );
  }

  String _uniqueAnchor(String anchor) {
    final seen = _anchorsSeen[anchor] ?? 0;
    _anchorsSeen[anchor] = seen + 1;
    return seen == 0 ? anchor : '$anchor-$seen';
  }

  /// The runs of [nodes], adjacent runs of the same style joined.
  List<MarkdownInline> inlines(List<md.Node> nodes) {
    final out = <MarkdownInline>[];
    void add(MarkdownInline run) {
      if (run.text.isEmpty) return;
      final last = out.isEmpty ? null : out.last;
      if (last != null &&
          last.bold == run.bold &&
          last.italic == run.italic &&
          last.code == run.code &&
          last.link == run.link) {
        out[out.length - 1] = MarkdownInline(
          last.text + run.text,
          bold: run.bold,
          italic: run.italic,
          code: run.code,
          link: run.link,
        );
      } else {
        out.add(run);
      }
    }

    void walk(md.Node node, MarkdownInline style) {
      if (node is md.Text) {
        // A single line break in the source is a soft break: a space. A
        // hard break (two spaces or a backslash) arrives as `br`.
        add(_with(style, node.text.replaceAll(_softBreak, ' ')));
        return;
      }
      if (node is! md.Element) {
        add(_with(style, node.textContent));
        return;
      }
      switch (node.tag) {
        case 'strong':
          style = _styled(style, bold: true);
        case 'em':
          style = _styled(style, italic: true);
        case 'code':
          add(
            _with(
              _styled(style, code: true),
              node.textContent.replaceAll(_softBreak, ' '),
            ),
          );
          return;
        case 'a':
          style = _styled(style, link: node.attributes['href'] ?? '');
        case 'br':
          add(_with(style, '\n'));
          return;
        case 'img':
          add(_with(style, node.attributes['alt'] ?? ''));
          return;
        case 'input':
          // A task list box (T10.10 will make it tickable).
          add(_with(style, node.attributes['checked'] == null ? '☐ ' : '☑ '));
          return;
      }
      for (final child in node.children ?? const <md.Node>[]) {
        walk(child, style);
      }
    }

    for (final node in nodes) {
      walk(node, const MarkdownInline(''));
    }
    return out;
  }

  static MarkdownInline _with(MarkdownInline style, String text) =>
      MarkdownInline(
        text,
        bold: style.bold,
        italic: style.italic,
        code: style.code,
        link: style.link,
      );

  static MarkdownInline _styled(
    MarkdownInline style, {
    bool? bold,
    bool? italic,
    bool? code,
    String? link,
  }) => MarkdownInline(
    '',
    bold: bold ?? style.bold,
    italic: italic ?? style.italic,
    code: code ?? style.code,
    link: link ?? style.link,
  );
}
