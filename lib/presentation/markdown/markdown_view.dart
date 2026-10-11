import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../domain/markdown/markdown_document.dart';
import '../theme/typography.dart';

/// Draws Markdown [blocks] (DD-020, REQ-065; shared with notes, T10.10) in
/// the app's typeface, theme and text size. A tap on a link calls
/// [onLinkTap] with the target as written; without it links are plain
/// text. When [anchorKeys] is given, each heading gets the key stored under
/// its anchor (created when missing), so a screen can scroll to it.
///
/// Not scrollable itself: put it in a scroll view.
class MarkdownView extends StatefulWidget {
  const MarkdownView({
    super.key,
    required this.blocks,
    this.onLinkTap,
    this.anchorKeys,
  });

  final List<MarkdownBlock> blocks;
  final ValueChanged<String>? onLinkTap;
  final Map<String, GlobalKey>? anchorKeys;

  @override
  State<MarkdownView> createState() => _MarkdownViewState();
}

class _MarkdownViewState extends State<MarkdownView> {
  final _recognizers = <TapGestureRecognizer>[];

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _blocks(context, widget.blocks),
    );
  }

  List<Widget> _blocks(BuildContext context, List<MarkdownBlock> blocks) => [
    for (final (i, block) in blocks.indexed)
      Padding(
        padding: EdgeInsets.only(
          top: i == 0 ? 0 : (block is MarkdownHeading ? 20 : 12),
        ),
        child: _block(context, block),
      ),
  ];

  Widget _block(BuildContext context, MarkdownBlock block) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final colors = theme.colorScheme;
    switch (block) {
      case MarkdownHeading(:final level, :final content, :final anchor):
        final style = switch (level) {
          1 => text.headlineSmall,
          2 => text.titleLarge,
          3 => text.titleMedium,
          _ => text.titleSmall,
        };
        return Semantics(
          header: true,
          child: Text.rich(
            key: widget.anchorKeys?.putIfAbsent(anchor, GlobalKey.new),
            _spans(context, content, style!),
          ),
        );
      case MarkdownParagraph(:final content):
        return Text.rich(_spans(context, content, _body(context)));
      case MarkdownList(:final ordered, :final start, :final items):
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, item) in items.indexed)
              Padding(
                padding: EdgeInsets.only(top: i == 0 ? 0 : 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: ordered ? 32 : 20,
                      child: ExcludeSemantics(
                        excluding: !ordered,
                        child: Text(
                          _marker(ordered, start + i),
                          style: _body(context),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: _blocks(context, item),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      case MarkdownCodeBlock(text: final code):
        return DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: Text(code, style: _mono(context)),
          ),
        );
      case MarkdownTable(:final alignments, :final header, :final rows):
        return _table(context, alignments, header, rows);
      case MarkdownQuote(:final blocks):
        return DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: colors.outlineVariant, width: 3),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _blocks(context, blocks),
            ),
          ),
        );
      case MarkdownRule():
        return const Divider();
    }
  }

  Widget _table(
    BuildContext context,
    List<MarkdownAlignment> alignments,
    List<List<MarkdownInline>> header,
    List<List<List<MarkdownInline>>> rows,
  ) {
    final colors = Theme.of(context).colorScheme;
    final body = _body(context);
    TableRow row(List<List<MarkdownInline>> cells, {bool head = false}) =>
        TableRow(
          decoration: head
              ? BoxDecoration(color: colors.surfaceContainerHighest)
              : null,
          children: [
            for (var c = 0; c < alignments.length; c++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                // Wide columns wrap instead of making the table endless.
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 280),
                  child: Text.rich(
                    _spans(
                      context,
                      c < cells.length ? cells[c] : const [],
                      head ? body.copyWith(fontWeight: FontWeight.w600) : body,
                    ),
                    textAlign: switch (alignments[c]) {
                      MarkdownAlignment.start => TextAlign.start,
                      MarkdownAlignment.center => TextAlign.center,
                      MarkdownAlignment.end => TextAlign.end,
                    },
                  ),
                ),
              ),
          ],
        );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        defaultColumnWidth: const IntrinsicColumnWidth(),
        border: TableBorder.all(color: colors.outlineVariant),
        children: [
          row(header, head: true),
          for (final cells in rows) row(cells),
        ],
      ),
    );
  }

  static String _marker(bool ordered, int n) =>
      ordered ? '$n.' : '•'; // l10n-ignore: list number

  TextStyle _body(BuildContext context) =>
      Theme.of(context).textTheme.bodyLarge!;

  TextStyle _mono(BuildContext context) => _body(
    context,
  ).copyWith(fontFamily: monoFamily, fontSize: _body(context).fontSize! * 0.9);

  TextSpan _spans(
    BuildContext context,
    List<MarkdownInline> content,
    TextStyle style,
  ) {
    final colors = Theme.of(context).colorScheme;
    return TextSpan(
      style: style,
      children: [
        for (final run in content)
          TextSpan(
            text: run.text,
            style: TextStyle(
              fontWeight: run.bold ? FontWeight.w600 : null,
              fontStyle: run.italic ? FontStyle.italic : null,
              fontFamily: run.code ? monoFamily : null,
              backgroundColor: run.code ? colors.surfaceContainerHighest : null,
              color: run.link != null && widget.onLinkTap != null
                  ? colors.primary
                  : null,
              decoration: run.link != null && widget.onLinkTap != null
                  ? TextDecoration.underline
                  : null,
            ),
            recognizer: _recognizer(run.link),
          ),
      ],
    );
  }

  TapGestureRecognizer? _recognizer(String? link) {
    final onTap = widget.onLinkTap;
    if (link == null || onTap == null) return null;
    final recognizer = TapGestureRecognizer()..onTap = () => onTap(link);
    _recognizers.add(recognizer);
    return recognizer;
  }
}
