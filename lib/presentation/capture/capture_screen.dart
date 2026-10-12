import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/help/help_topics.dart';
import '../../domain/items/item.dart';
import '../../domain/items/item_enums.dart';
import '../../l10n/app_localizations.dart';
import '../../platform/handwriting/handwriting_reader.dart';
import '../handwriting/handwriting_providers.dart';
import '../handwriting/handwriting_screen.dart';
import '../help/help_scope.dart';
import '../items/item_providers.dart';
import '../people/text_contacts.dart';
import '../tokens/link_choices.dart';
import '../tokens/token_editor.dart';
import '../tokens/token_processor_provider.dart';

/// Quick capture (REQ-001, REQ-018): one text field with the focus in it,
/// nothing else loaded (CLAUDE.md rule 7). Saving stores the text unchanged
/// as an inbox item and closes the screen; if saving fails the text stays.
///
/// Keyboard (PO decision 25-09-2026): on a desktop Enter saves and
/// Shift+Enter starts a new line; on a phone the keyboard's action key saves
/// and the text has no line breaks.
class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({super.key, this.source = ItemSource.app});

  /// Recorded as the item's source: the app's own button, or the Windows
  /// hotkey or tray menu (DD-010).
  final ItemSource source;

  /// Quick capture as a full-screen dialog; completes when it closes, saved
  /// or not.
  static Route<void> route({ItemSource source = ItemSource.app}) =>
      CaptureRoute._(source);

  /// Opens quick capture on top of the current screen.
  static Future<void> open(BuildContext context) =>
      Navigator.of(context).push(route());

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  /// Items chosen from the `[[` list, saved with the text (DD-004 point 13).
  final _links = LinkChoices();
  bool _saving = false;
  bool _failed = false;

  /// Whether to look for the handwriting model: only after the first frame,
  /// so the field and the keyboard come first (CLAUDE.md rule 7).
  bool _lookForModel = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_tellRoute);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _lookForModel = true);
    });
  }

  /// The route this screen is on, when it is a [CaptureRoute].
  CaptureRoute? _route;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    _route = route is CaptureRoute ? route : null;
  }

  /// Lets the route know whether text is typed ([CaptureRoute.hasText]).
  void _tellRoute() => _route?.hasText = hasCapturableText(_controller.text);

  @override
  void dispose() {
    _controller.removeListener(_tellRoute);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _controller.text;
    if (_saving || !hasCapturableText(text)) return;
    setState(() {
      _saving = true;
      _failed = false;
    });
    // Read before waiting: the screen may be closed while saving.
    final processor = ref.read(tokenProcessorProvider);
    final contacts = TextContactTaker.of(context, ref);
    final String id;
    try {
      id = await ref
          .read(itemRepositoryProvider)
          .capture(text, source: widget.source, links: _links.forText(text));
    } catch (_) {
      // The text stays in the field; the message below says so.
      if (mounted) {
        setState(() {
          _saving = false;
          _failed = true;
        });
        _focusNode.requestFocus();
      }
      return;
    }
    // Saved first; persons, tags and the deadline are worked out afterwards
    // without waiting (CLAUDE.md rule 7). A failure is retried at the next
    // start (processOutdated).
    unawaited(processor.process(id).catchError((Object _) {}));
    // Numbers and addresses go to the person named in the text; saving is
    // confirming (T3.6, PO decision c). The message shows after closing.
    unawaited(contacts.take(text));
    if (mounted) Navigator.of(context).pop();
  }

  /// Reads handwriting from a photo into the field (REQ-064, T6a.4): after
  /// what is typed already, on a line of its own. Until the review screen
  /// of T6a.5 the text is saved as one item (PO 12-10-2026).
  Future<void> _readPhoto(HandwritingModel model) async {
    final text = await readHandwriting(context, ref, model);
    if (text == null || !mounted) return;
    final before = _controller.text.trimRight();
    final joined = before.isEmpty
        ? text
        : '$before\n$text'; // l10n-ignore: joins two texts
    _controller.value = TextEditingValue(
      text: joined,
      selection: TextSelection.collapsed(offset: joined.length),
    );
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Only with a model and a reader on this device (AC REQ-064).
    final model = _lookForModel
        ? ref.watch(handwritingModelProvider).valueOrNull
        : null;
    return HelpScope(
      topic: HelpTopic.capture,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.captureTitle),
          actions: [
            if (model != null)
              IconButton(
                icon: const Icon(Icons.document_scanner_outlined),
                tooltip: l10n.handwritingButton,
                onPressed: _saving ? null : () => unawaited(_readPhoto(model)),
              ),
            ValueListenableBuilder(
              valueListenable: _controller,
              builder: (context, value, _) => IconButton(
                icon: const Icon(Icons.check),
                tooltip: l10n.captureSave,
                onPressed: !_saving && hasCapturableText(value.text)
                    ? _save
                    : null,
              ),
            ),
            const HelpButton(),
          ],
        ),
        body: SafeArea(
          // On a desktop Enter saves and Shift+Enter starts a new line; on a
          // phone the keyboard's action key saves (PO decision 25-09-2026).
          child: TokenEditor(
            controller: _controller,
            focusNode: _focusNode,
            autofocus: true,
            readOnly: _saving,
            onSubmit: _save,
            linkChoices: _links,
            decoration: InputDecoration(
              hintText: l10n.captureHint,
              errorText: _failed ? l10n.captureSaveFailed : null,
              errorMaxLines: 3,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
      ),
    );
  }
}

/// The route of [CaptureScreen], recognisable by [CaptureRouteObserver].
class CaptureRoute extends MaterialPageRoute<void> {
  CaptureRoute._(ItemSource source)
    : super(
        fullscreenDialog: true,
        builder: (_) => CaptureScreen(source: source),
      );

  /// Whether text is typed on it: a request from outside (a reminder, the
  /// Offload bar) then leaves it on top, so nothing typed is lost (REQ-063).
  bool hasText = false;
}

/// Knows whether a capture screen is open, however it was opened (the
/// in-app button, the Windows hotkey or the tray), so a request from outside
/// the window never stacks a second one on top of unsaved text.
class CaptureRouteObserver extends NavigatorObserver {
  final _open = <Route<dynamic>>{};
  Completer<void>? _allClosed;

  bool get captureOpen => _open.isNotEmpty;

  /// Completes when no capture screen is open any more.
  Future<void> whenClosed() {
    if (_open.isEmpty) return Future.value();
    return (_allClosed ??= Completer<void>()).future;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is CaptureRoute) _open.add(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _closed(route);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _closed(route);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute is CaptureRoute) _open.add(newRoute);
    if (oldRoute != null) _closed(oldRoute);
  }

  void _closed(Route<dynamic> route) {
    if (!_open.remove(route) || _open.isNotEmpty) return;
    _allClosed?.complete();
    _allClosed = null;
  }
}
