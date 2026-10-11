import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/help/help_topics.dart';
import '../../domain/markdown/markdown_document.dart';
import '../../l10n/app_localizations.dart';
import '../markdown/markdown_view.dart';
import '../messages.dart';

/// The user manual inside the app (REQ-065, DD-020): one chapter at a time,
/// from the app's own bundle. Links to chapters and headings open here, with
/// Back retracing the reader's own path before it closes the screen; an
/// internet address is only shown (REQ-003).
class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key, required this.start});

  /// Where the screen opens.
  final ManualPlace start;

  /// Opens the manual at [topic] over the current screen.
  static Future<void> open(BuildContext context, HelpTopic topic) =>
      push(Navigator.of(context), topic);

  static Future<void> push(NavigatorState navigator, HelpTopic topic) =>
      navigator.push(
        MaterialPageRoute<void>(builder: (_) => HelpScreen(start: topic.place)),
      );

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

/// A place the reader visited, with how far they had scrolled.
class _Visit {
  _Visit(this.place);

  final ManualPlace place;
  double offset = 0;
}

class _HelpScreenState extends State<HelpScreen> {
  late final List<_Visit> _path = [_Visit(widget.start)];
  final _scroll = ScrollController();
  final _loaded = <String, List<MarkdownBlock>>{};
  final _failed = <String>{};
  final _loading = <String>{};
  var _anchorKeys = <String, GlobalKey>{};
  String? _language;

  /// Where to scroll once the current chapter is on screen: a heading, or
  /// else an offset (the top of a new place, or where the reader was).
  ({String? anchor, double offset})? _pending;

  _Visit get _here => _path.last;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final language = manualLanguageFor(
      Localizations.localeOf(context).languageCode,
    );
    if (language != _language) {
      _language = language;
      _loaded.clear();
      _failed.clear();
      _show(_here, anchor: _here.place.anchor);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Loads [name] from the bundle once; the screen rebuilds when it is in.
  void _load(String name) {
    if (_loaded.containsKey(name) ||
        _failed.contains(name) ||
        !_loading.add(name)) {
      return;
    }
    final language = _language!;
    DefaultAssetBundle.of(context)
        // Not in the bundle's own cache: this screen keeps the parsed
        // chapters itself.
        .loadString(manualAsset(language, name), cache: false)
        .then<void>(
          (text) {
            _loaded[name] = parseMarkdown(text);
          },
          onError: (Object _) {
            _failed.add(name);
          },
        )
        .whenComplete(() {
          _loading.remove(name);
          if (!mounted || language != _language) return;
          setState(() {});
          if (name == _here.place.chapter) _scrollAfterFrame();
        });
  }

  /// Shows [visit]: at [anchor] when given, otherwise at its saved offset.
  /// Loads its chapter when needed; the scroll follows once it is drawn.
  void _show(_Visit visit, {String? anchor}) {
    _anchorKeys = {};
    _pending = (anchor: anchor, offset: visit.offset);
    if (_loaded.containsKey(visit.place.chapter)) {
      _scrollAfterFrame();
    } else {
      _load(visit.place.chapter);
    }
  }

  /// Scrolls to [_pending] after the next frame, which draws the chapter.
  void _scrollAfterFrame() {
    final pending = _pending;
    if (pending == null) return;
    _pending = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final target = pending.anchor == null
          ? null
          : _anchorKeys[pending.anchor];
      if (target?.currentContext case final context?) {
        Scrollable.ensureVisible(context);
      } else {
        _scroll.jumpTo(
          pending.offset.clamp(0, _scroll.position.maxScrollExtent),
        );
      }
    });
  }

  void _go(ManualPlace place) {
    // Already there (F1 or Contents on the contents): no extra step back.
    if (place == _here.place && place.anchor == null) return;
    if (_scroll.hasClients) _here.offset = _scroll.offset;
    final visit = _Visit(place);
    setState(() {
      _path.add(visit);
      _show(visit, anchor: place.anchor);
    });
  }

  void _back() {
    setState(() {
      _path.removeLast();
      _show(_here);
    });
  }

  void _openLink(String target) {
    switch (resolveManualLink(_here.place.chapter, target)) {
      case final ManualPlace place:
        _go(place);
      case ExternalLink(:final address):
        final l10n = AppLocalizations.of(context);
        showMessage(
          ScaffoldMessenger.of(context),
          SnackBar(
            content: Text(l10n.helpExternalLink(address)),
            action: SnackBarAction(
              label: l10n.helpCopy,
              onPressed: () => Clipboard.setData(ClipboardData(text: address)),
            ),
          ),
        );
      case null:
        // Leads nowhere the app may go.
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final contents = HelpTopic.contents.place;
    final inOtherLanguage =
        _language != Localizations.localeOf(context).languageCode;
    return PopScope(
      canPop: _path.length <= 1,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): () =>
              Navigator.of(context).maybePop(),
          const SingleActivator(LogicalKeyboardKey.f1): () => _go(contents),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            appBar: AppBar(
              title: Text(l10n.helpTitle),
              actions: [
                if (_here.place != contents)
                  IconButton(
                    icon: const Icon(Icons.toc),
                    tooltip: l10n.helpContents,
                    onPressed: () => _go(contents),
                  ),
              ],
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (inOtherLanguage)
                  ColoredBox(
                    color: colors.surfaceContainerHighest,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.translate, color: colors.onSurfaceVariant),
                          const SizedBox(width: 12),
                          Expanded(child: Text(l10n.helpInEnglish)),
                        ],
                      ),
                    ),
                  ),
                Expanded(child: _body(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    final chapter = _here.place.chapter;
    if (_failed.contains(chapter)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            AppLocalizations.of(context).helpLoadFailed,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final blocks = _loaded[chapter];
    if (blocks == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scrollbar(
      controller: _scroll,
      child: SingleChildScrollView(
        controller: _scroll,
        // Clear of Android's navigation buttons at the bottom.
        padding: const EdgeInsets.all(
          16,
        ).add(EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom)),
        child: Center(
          child: ConstrainedBox(
            // A comfortable line length on a wide Windows window.
            constraints: const BoxConstraints(maxWidth: 720),
            child: SelectionArea(
              child: MarkdownView(
                // A new view per chapter, with its own heading keys.
                key: ValueKey(chapter),
                blocks: blocks,
                onLinkTap: _openLink,
                anchorKeys: _anchorKeys,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
