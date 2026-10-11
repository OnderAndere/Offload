import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/connections/connection_graph.dart';
import '../../domain/help/help_topics.dart';
import '../../domain/items/item.dart';
import '../../domain/items/item_enums.dart';
import '../../domain/items/item_headline.dart';
import '../../domain/items/item_repository.dart';
import '../../domain/items/item_status_machine.dart';
import '../../domain/items/revisit.dart';
import '../../domain/items/today.dart';
import '../../domain/links/item_link.dart';
import '../../domain/people/contacts_from_text.dart';
import '../../domain/projects/project_token.dart';
import '../../domain/repeats/repeat.dart';
import '../../domain/snapshots/snapshot.dart';
import '../../domain/time/local_date.dart';
import '../../domain/tokens/inline_token.dart';
import '../../domain/tokens/token_processing.dart';
import '../../domain/tokens/token_suggestion.dart';
import '../../domain/tokens/token_text.dart';
import '../../domain/tokens/token_types.dart';
import '../../l10n/app_localizations.dart';
import '../help/help_scope.dart';
import '../home/item_panes.dart';
import '../messages.dart';
import '../overview/connections_entry.dart';
import '../overview/connections_providers.dart';
import '../people/item_person_chips.dart';
import '../people/person_actions.dart';
import '../people/text_contacts.dart';
import '../photos/item_photos.dart';
import '../projects/project_actions.dart';
import '../projects/project_look.dart';
import '../projects/project_picker.dart';
import '../repeats/complete_repeat_sheet.dart';
import '../repeats/completion_history.dart';
import '../repeats/repeat_providers.dart';
import '../revisit/revisit_sheet.dart';
import '../search/duplicate_hint.dart';
import '../snapshots/where_was_i.dart';
import '../tokens/link_choices.dart';
import '../tokens/token_display.dart';
import '../tokens/token_editor.dart';
import '../tokens/token_processor_provider.dart';
import '../triage/person_sheet.dart';
import 'commitment_block.dart';
import 'complete_undo.dart';
import 'item_labels.dart';
import 'item_providers.dart';
import 'item_type_look.dart';
import 'linked_from.dart';
import 'share_preview.dart';
import 'trash_undo.dart';

/// One item, to read and edit (T2.3, REQ-018; design DD-018 point 1, "text
/// first"): the typed text is the only source and is edited like quick
/// capture; status and type are separate choices; the note below. Saved
/// automatically after a short pause and when leaving; Enter adds a line.
class ItemDetailScreen extends ConsumerStatefulWidget {
  const ItemDetailScreen({
    super.key,
    required this.itemId,
    this.embedded = false,
  });

  final String itemId;

  /// In the detail pane beside the list on a wide Windows window
  /// (DD-018 point 5) instead of a screen of its own: no back arrow,
  /// Escape hands the focus back to the list, and the trash clears the
  /// selection instead of closing a screen.
  final bool embedded;

  /// Opens item [id]: in the detail pane when there are two panes
  /// ([ItemPanes]), otherwise on top of the current screen.
  static Future<void> open(BuildContext context, String id) {
    final panes = ItemPanes.find(context);
    if (panes != null) {
      panes.select(id);
      return Future.value();
    }
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: routeName),
        builder: (_) => ItemDetailScreen(itemId: id),
      ),
    );
  }

  /// The name of its route as a screen of its own: on Windows a window made
  /// wide enough for two panes closes it, as the pane shows the item then.
  static const routeName = 'item'; // l10n-ignore: route name, not shown

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  /// Every save is a change-log entry that also travels in sync packages,
  /// hence a pause instead of saving on every key (DD-018).
  static const autosaveDelay = Duration(seconds: 2);

  final _text = TextEditingController();
  final _note = TextEditingController();
  final _textFocus = FocusNode();
  Timer? _pending;
  bool _loaded = false;
  bool _failed = false;
  Future<void>? _saving;
  String _savedText = '';
  String _savedNote = '';

  /// The text when the detail opened: numbers and addresses typed since go
  /// to the person named in the text when the detail is left (T3.6).
  String _openedText = '';
  TextContactTaker? _contacts;

  /// Items chosen from the `[[` list, saved with the text (DD-004 point 13).
  final _links = LinkChoices();

  /// Moved to the trash from here: leaving takes nothing from its text
  /// (saving is confirming, trashing is not; T3.6).
  bool _trashed = false;

  // Kept from the start, so leaving can still save after the screen is
  // gone.
  late final ItemRepository _items = ref.read(itemRepositoryProvider);
  late final ItemTokenProcessor _processor = ref.read(tokenProcessorProvider);

  /// The requests of the list to put the focus here (Enter in the list),
  /// when embedded in the detail pane.
  ValueNotifier<int>? _focusRequests;

  @override
  void initState() {
    super.initState();
    // Read now: in dispose the ref can no longer be used.
    _items;
    _processor;
    _text.addListener(_changed);
    _note.addListener(_changed);
    // Connections starts from the item opened last (DD-018 point 15); after
    // this build, as a provider may not change during one.
    final recent = ref.read(recentlyOpenedProvider.notifier);
    final opened = NodeRef.item(widget.itemId);
    unawaited(Future.microtask(() => recent.opened(opened)));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final requests = widget.embedded
        ? ItemPanes.maybeOf(context)?.detailFocusRequests
        : null;
    if (requests != _focusRequests) {
      _focusRequests?.removeListener(_focusText);
      _focusRequests = requests?..addListener(_focusText);
    }
    // Made again when the language changes, so the message follows it.
    _contacts = TextContactTaker.of(context, ref);
  }

  void _focusText() => _textFocus.requestFocus();

  @override
  void dispose() {
    _focusRequests?.removeListener(_focusText);
    // Leaving always saves what was typed (DD-018), also when another item
    // is selected in the list pane: that disposes this one. Then the newly
    // typed numbers and addresses go to the person in the text (T3.6).
    final contacts = _contacts;
    final opened = _openedText;
    final items = _items;
    final id = widget.itemId;
    unawaited(
      _save().then((_) async {
        if (_trashed || !_loaded || contacts == null) return;
        // Also not when it went to the trash elsewhere (the list) while it
        // was open here.
        if (!await items.isLive(id)) return;
        await contacts.take(_savedText, before: opened);
      }),
    );
    _text.dispose();
    _note.dispose();
    _textFocus.dispose();
    super.dispose();
  }

  /// Fills the fields once, from the stored item. Later changes to the
  /// item (status, type) never overwrite what is being typed.
  void _load(Item item) {
    _savedText = item.rawText;
    _openedText = item.rawText;
    _savedNote = item.body ?? '';
    _text.text = _savedText;
    _note.text = _savedNote;
    _loaded = true;
  }

  void _changed() {
    if (!_loaded) return;
    _pending?.cancel();
    _pending = Timer(autosaveDelay, () => unawaited(_save()));
    // The empty-text message follows the text.
    if (mounted) setState(() {});
  }

  /// Saves what changed, one save after the other, so leaving (which
  /// saves twice: on pop and in dispose) never writes the same text twice.
  ///
  /// Text and note are read right now: from dispose the save runs after
  /// the fields are gone.
  Future<void> _save() {
    _pending?.cancel();
    if (!_loaded) return _saving ?? Future.value();
    final text = _text.text;
    final note = _note.text;
    return _saving = (_saving ?? Future.value()).then(
      (_) => _saveNow(text, note),
    );
  }

  /// Empty text is never saved: the previous text is kept and the field
  /// says so. A failure keeps the edit on screen.
  Future<void> _saveNow(String text, String note) async {
    final id = widget.itemId;
    try {
      if (text != _savedText && hasCapturableText(text)) {
        await _items.editText(id, text, links: _links.forText(text));
        _savedText = text;
        // Tokens and deadline follow the text, after saving (rule 7).
        unawaited(_processor.process(id).catchError((Object _) {}));
      }
      if (note != _savedNote) {
        await _items.editNote(id, note);
        _savedNote = note;
      }
      if (_failed && mounted) setState(() => _failed = false);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  /// *Due* in the commitment block (DD-018 point 10 (b)): the picked day
  /// goes into the text as a fixed date, in place of the first date there,
  /// or at the end; the deadline follows the text (point 1).
  void _setDueInText(LocalDate day) {
    final l10n = AppLocalizations.of(context);
    final text = _text.text;
    final word = '!${fixedDateWord(day)}'; // l10n-ignore: the date token
    final first = ref
        .read(inlineTokenRegistryProvider)
        .parse(text, parseContextOf(l10n, todayOnDevice()))
        .where((m) => m.type is DateTokenType)
        .firstOrNull;
    _text.text = first == null
        ? '${text.trimRight()} $word' // l10n-ignore: joins typed text
        : text.replaceRange(first.start, first.end, word);
  }

  /// "Link to…" (T3.6, PO decision d): asks for the person, people named in
  /// the text first, and adds [contact] to them.
  Future<void> _linkContact(TextContact contact) async {
    final l10n = AppLocalizations.of(context);
    final contacts = _contacts;
    final choice = await showPersonSheet(
      context,
      title: l10n.contactLinkTitle,
      namedWords: personWordsIn(_text.text, ref, l10n),
    );
    final name = choice?.name;
    if (name == null || contacts == null) return;
    await contacts.link(contact, name);
  }

  /// The chip of a `^project` word that names no project (PO decision
  /// 03-10-2026): asks for the name, filled in from the word, creates the
  /// project and puts the item in it, as a choice in the picker. Typed text
  /// is saved first, as before the picker (DD-004 point 11).
  Future<void> _createProjectFromWord(NamesNoProject word) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    await _save();
    if (!mounted) return;
    final id = await createProject(
      context,
      ref,
      name: word.name,
      parentId: word.parentId,
    );
    if (id == null) return;
    try {
      await _items.setProject(widget.itemId, id);
    } catch (e) {
      showMessage(
        messenger,
        SnackBar(content: Text(projectErrorText(e, l10n))),
      );
    }
  }

  /// The "no item" chip of a `[[…]]` (DD-004 point 13 (b)): saves
  /// the text, then makes an inbox item with that text, linked from here.
  Future<void> _createLinked(String label) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    await _save();
    try {
      await _items.captureLinked(widget.itemId, label, source: ItemSource.app);
      await _processor.process(widget.itemId);
    } catch (_) {
      showMessage(
        messenger,
        SnackBar(content: Text(l10n.tokenLinkCreateFailed)),
      );
    }
  }

  /// *Link* in the duplicate hint, here: `[[label]]` goes at the end of
  /// the text through the field, so the pending save keeps it, and the
  /// choice is remembered and saved with it (DD-004 point 13).
  Future<void> _appendLink(String otherId, String label) async {
    final text = _text.text.trimRight();
    final word = linkLabelFor(label);
    _links.remember(word, otherId);
    _text.text = '$text [[$word]]'; // l10n-ignore: the link token
    await _save();
  }

  Future<void> _moveTo(ItemStatus status) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      await _items.moveTo(widget.itemId, status);
    } catch (_) {
      showMessage(messenger, SnackBar(content: Text(l10n.itemChangeFailed)));
    }
  }

  /// *Afronden* (the button, Ctrl+Enter; DD-018 point 18): the text is
  /// saved and processed first, so a repeat word just typed counts; a
  /// repeating task then moves on to its next time. With undo, as on
  /// *Today*.
  Future<void> _complete(Item item) async {
    // A second tap before the item shows its next time would complete the
    // next time too: the button stays for a repeating task (review T4.7).
    if (_completedAt != null && _completedAt == _completionKey(item)) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    _completedAt = _completionKey(item);
    await _save();
    await _processor.process(item.id).catchError((Object _) {});
    final done = await completeWithUndo(
      messenger: messenger,
      l10n: l10n,
      items: _items,
      item: item,
      // Undone: the same date may be completed again.
      onUndo: () => _completedAt = null,
    );
    if (!done) _completedAt = null;
  }

  /// The repeat words in [text] as it is on screen: what *Afronden en
  /// herhalen…* and *Herhaling stoppen* decide by, never stored tokens that
  /// may be behind (DD-018 point 18).
  List<TokenMatch> _repeatWords(String text) => ref
      .read(inlineTokenRegistryProvider)
      .parse(
        text,
        parseContextOf(AppLocalizations.of(context), todayOnDevice()),
      )
      .where((m) => m.type is RepeatTokenType)
      .toList();

  /// [text] is what is saved now, after a change made here (a repeat word
  /// added or removed): the field shows it, and processing follows.
  void _savedAs(String text) {
    if (!mounted) return;
    _savedText = text;
    _text.text = text;
    unawaited(_processor.process(widget.itemId).catchError((Object _) {}));
  }

  /// The item and date the last *Afronden* here started from.
  ///
  /// Cleared as soon as the item on screen differs (its status or date
  /// moved, or it was reopened), so only a tap before that rebuild is held.
  (String, DateTime?, ItemStatus)? _completedAt;

  static (String, DateTime?, ItemStatus) _completionKey(Item item) =>
      (item.id, item.dueAt, item.status);

  /// After an undo that put the old text back; text typed since stays.
  Future<void> _reloadText() async {
    final item = await _items.watchItem(widget.itemId).first;
    if (item != null && mounted && _text.text == _savedText) {
      _savedAs(item.rawText);
    }
  }

  /// *Afronden en herhalen…* (DD-018 point 18): asks the rhythm, then adds
  /// its word to the end of the text and completes this time, in one step
  /// with undo.
  Future<void> _completeAndRepeat(Item item) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    await _save();
    // A date just typed is the first time: processed before it is used.
    await _processor.process(item.id).catchError((Object _) {});
    if (!mounted) return;
    final today = todayOnDevice();
    // The sheet shows the dates from the item as on screen; the time the
    // repository records is the stored date, after the processing above.
    final dueAt = item.dueAt;
    final rhythm = await showCompleteAndRepeat(
      context,
      occurrence: dueAt == null ? today : storedToDateOnly(dueAt),
      today: today,
    );
    if (rhythm == null || !mounted) return;
    final word = repeatVocabularyOf(
      l10n,
    ).suggestions('').firstWhere((o) => o.rhythm == rhythm).word;
    final text = '${_savedText.trimRight()} !$word'; // l10n-ignore: token
    final done = await runCompletionWithUndo(
      messenger: messenger,
      l10n: l10n,
      items: _items,
      itemId: item.id,
      run: () => _items.completeAndRepeat(
        item.id,
        rawText: text,
        rhythm: rhythm,
        today: today,
      ),
      afterUndo: _reloadText,
    );
    if (done != null) _savedAs(text);
  }

  /// *Herhaling stoppen* (DD-018 point 18): removes the repeat words from
  /// the text and completes the item, in one step with undo.
  Future<void> _stopRepeating(Item item) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    await _save();
    if (!mounted) return;
    final without = withoutTokens(_savedText, _repeatWords(_savedText));
    // Only a repeat word in the text: it stays, the item is done anyway.
    final text = hasCapturableText(without) ? without : _savedText;
    final done = await runCompletionWithUndo(
      messenger: messenger,
      l10n: l10n,
      items: _items,
      itemId: item.id,
      run: () => _items.stopRepeating(item.id, rawText: text),
      message: l10n.repeatStopped,
      afterUndo: _reloadText,
    );
    if (done != null) _savedAs(text);
  }

  /// *Revisit on…* (DD-018 point 17): the text is saved first, as before
  /// every other change of the item.
  Future<void> _revisit(Item item) async {
    await _save();
    if (mounted) await revisitWithUndo(context, ref, item);
  }

  /// *Wait for…*: asks who, with the people in the text first (DD-018
  /// point 7).
  Future<void> _waitFor() =>
      waitForWithPerson(context, ref, itemId: widget.itemId, text: _text.text);

  Future<void> _stopRevisit(Item item) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      await _items.stopRevisit(item.id);
    } catch (_) {
      showMessage(messenger, SnackBar(content: Text(l10n.itemChangeFailed)));
    }
  }

  Future<void> _setType(ItemType? type) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      await _items.setType(widget.itemId, type);
    } catch (_) {
      showMessage(messenger, SnackBar(content: Text(l10n.itemChangeFailed)));
    }
  }

  /// To the trash, with undo in the message (DD-018; AC REQ-010).
  Future<void> _trash() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final panes = widget.embedded ? ItemPanes.find(context) : null;
    final l10n = AppLocalizations.of(context);
    await _save();
    final trashed = await trashWithUndo(
      messenger: messenger,
      l10n: l10n,
      items: _items,
      id: widget.itemId,
    );
    if (!trashed) return;
    _trashed = true;
    if (!mounted) return;
    if (panes != null) {
      panes.select(null);
      panes.listFocus.requestFocus();
    } else {
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final item = ref.watch(itemProvider(widget.itemId)).valueOrNull;
    if (item != null && !_loaded) _load(item);

    final screen = PopScope(
      onPopInvokedWithResult: (_, _) => unawaited(_save()),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: !widget.embedded,
          actions: [
            // Shares what is in the field now, also before it is saved
            // (REQ-043, DD-018 point 1).
            if (item != null)
              IconButton(
                icon: const Icon(Icons.share_outlined),
                tooltip: l10n.itemShare,
                onPressed: () => showSharePreview(
                  context,
                  rawText: _text.text,
                  knownDates:
                      ref
                          .read(storedDatesProvider(widget.itemId))
                          .valueOrNull ??
                      const {},
                ),
              ),
            const HelpButton(),
            if (item != null)
              PopupMenuButton<void>(
                itemBuilder: (_) => [
                  // Recurring tasks (DD-018 point 18), by the text on screen.
                  if (isOpen(item.status) &&
                      _repeatWords(_text.text).isEmpty &&
                      repeatsAs(item.type))
                    PopupMenuItem(
                      onTap: () => unawaited(_completeAndRepeat(item)),
                      child: ListTile(
                        leading: const Icon(Icons.repeat),
                        title: Text(l10n.completeAndRepeat),
                      ),
                    ),
                  if (isOpen(item.status) &&
                      repeatsAs(item.type) &&
                      _repeatWords(_text.text).isNotEmpty)
                    PopupMenuItem(
                      onTap: () => unawaited(_stopRepeating(item)),
                      child: ListTile(
                        leading: const Icon(Icons.stop_circle_outlined),
                        title: Text(l10n.stopRepeating),
                      ),
                    ),
                  // Parks the item until a date (DD-018 point 17).
                  if (isOpen(item.status))
                    PopupMenuItem(
                      onTap: () => unawaited(_revisit(item)),
                      child: ListTile(
                        leading: const Icon(Icons.update),
                        title: Text(l10n.revisitAction),
                      ),
                    ),
                  PopupMenuItem(
                    onTap: () => showConnectionsOf(
                      context,
                      ref,
                      NodeRef.item(widget.itemId),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.hub_outlined),
                      title: Text(l10n.connectionsShow),
                    ),
                  ),
                  PopupMenuItem(
                    onTap: () => unawaited(_trash()),
                    child: ListTile(
                      leading: const Icon(Icons.delete_outline),
                      title: Text(l10n.itemMoveToTrash),
                    ),
                  ),
                ],
              ),
          ],
        ),
        body: SafeArea(
          child: item == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: _loaded
                        ? Text(l10n.itemGone, textAlign: TextAlign.center)
                        : const SizedBox.shrink(),
                  ),
                )
              : _editor(context, item),
        ),
      ),
    );
    if (widget.embedded || !isDesktop(context)) {
      return HelpScope(topic: HelpTopic.item, child: screen);
    }
    // A screen of its own on Windows (a narrow window, a card of a person in
    // the right pane): Escape goes back also while the text has no focus
    // (DD-018); in the text its own Escape comes first.
    return HelpScope(
      topic: HelpTopic.item,
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): () =>
              Navigator.of(context).maybePop(),
          if (item != null)
            const SingleActivator(
              LogicalKeyboardKey.keyP,
              control: true,
              shift: true,
            ): () =>
                _whereWasI(item),
        },
        child: Focus(autofocus: true, child: screen),
      ),
    );
  }

  /// The headline of [item], for the form and card of "Where was I".
  String _title(Item item) => itemHeadline(
    item.rawText,
    ref.read(inlineTokenRegistryProvider),
    parseContextOf(AppLocalizations.of(context), LocalDate.of(DateTime.now())),
  ).title;

  /// "Where was I" on this item (DD-018 point 13).
  void _whereWasI(Item item) => unawaited(
    showWhereWasI(
      context,
      ref,
      ItemSnapshotOwner(item.id),
      title: _title(item),
    ),
  );

  Widget _editor(BuildContext context, Item item) {
    if (_completedAt != _completionKey(item)) _completedAt = null;
    final l10n = AppLocalizations.of(context);
    final next = nextStatuses(item.status);
    final primary = primaryNextStatus(item.status);
    final captured = item.capturedAt.toLocal();
    final emptyText = !hasCapturableText(_text.text);
    final title = _title(item);
    final owner = ItemSnapshotOwner(item.id);
    final repeat = ref.watch(repeatsProvider).valueOrNull?[item.id];
    final dueAt = item.dueAt;
    // The main step: complete (a repeating task moves on), or reopen.
    void mainStep() => primary == ItemStatus.done
        ? unawaited(_complete(item))
        : unawaited(_moveTo(primary));
    return TokenEditor(
      controller: _text,
      focusNode: _textFocus,
      scrollable: true,
      // A recurring task: its rhythm and this time (DD-018 point 18).
      repeat: repeat,
      thisTime: repeat != null && dueAt != null
          ? storedToDateOnly(dueAt)
          : null,
      repeatsForType: repeatsAs(item.type),
      knownDates:
          ref.watch(storedDatesProvider(widget.itemId)).valueOrNull ?? const {},
      // A person chip under the text opens the person (DD-018 point 7).
      onPersonTap: (name) => openPersonNamed(context, ref, name),
      // A number or address without one person in the text: whose is it?
      onContactTap: _linkContact,
      // A `^word` of no project yet: create it, with this item in it.
      onCreateProject: _createProjectFromWord,
      // Links between items (DD-018 point 14).
      linkChoices: _links,
      selfItemId: item.id,
      links: ref.watch(linksFromProvider(item.id)).valueOrNull ?? const {},
      unlinked:
          ref.watch(unlinkedLabelsProvider(item.id)).valueOrNull ?? const {},
      onOpenItem: (id) => ItemDetailScreen.open(context, id),
      onCreateLinked: _createLinked,
      decoration: InputDecoration(
        hintText: l10n.itemTextHint,
        errorText: emptyText
            ? l10n.itemTextEmpty
            : _failed
            ? l10n.itemSaveFailed
            : null,
        errorMaxLines: 3,
        border: const OutlineInputBorder(),
      ),
      // Windows (DD-018): Ctrl+Enter does the main step; Escape goes back
      // once the suggestion list is closed.
      shortcuts: {
        const SingleActivator(LogicalKeyboardKey.enter, control: true):
            mainStep,
        const SingleActivator(
          LogicalKeyboardKey.keyP,
          control: true,
          shift: true,
        ): () =>
            _whereWasI(item),
        const SingleActivator(LogicalKeyboardKey.escape): () {
          final panes = widget.embedded ? ItemPanes.find(context) : null;
          if (panes != null) {
            panes.listFocus.requestFocus();
          } else {
            Navigator.of(context).maybePop();
          }
        },
      },
      header: [
        // While a note is open, on top (DD-018 point 13 (d)).
        ResumeCard(
          owner: owner,
          title: title,
          margin: const EdgeInsets.only(bottom: 12),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ChoiceChip<ItemStatus>(
              label: l10n.status(item.status),
              tooltip: l10n.itemStatusTooltip,
              options: [
                for (final status in ItemStatus.values)
                  if (next.contains(status)) (status, l10n.status(status)),
              ],
              // Scheduled asks for the date: an item is no longer
              // scheduled without one (DD-018 point 17).
              onSelected: (status) => switch (status) {
                ItemStatus.waiting => _waitFor(),
                ItemStatus.scheduled => _revisit(item),
                _ => _moveTo(status),
              },
            ),
            _ChoiceChip<_TypeChoice>(
              icon: switch (item.type) {
                final type? => itemTypeIcon(type),
                null => null,
              },
              label: l10n.type(item.type),
              tooltip: l10n.itemTypeTooltip,
              options: [
                (const _TypeChoice(null), l10n.type(null)),
                for (final type in selectableItemTypes)
                  (_TypeChoice(type), l10n.type(type)),
              ],
              onSelected: (choice) => _setType(choice.type),
            ),
            ItemProjectChip(
              itemId: item.id,
              projectId: item.projectId,
              beforeOpen: _save,
            ),
            ...itemPersonChips(item, text: () => _text.text),
          ],
        ),
        if (parkedDayOf(item) case final day?)
          _RevisitLine(
            day: day,
            onChange: () => _revisit(item),
            onStop: () => _stopRevisit(item),
          ),
        const SizedBox(height: 12),
      ],
      footer: [
        // Who asked, what I promised, by when; or whom I wait on (T10.1).
        CommitmentBlock(item: item, onDue: _setDueInText),
        const SizedBox(height: 16),
        TextField(
          controller: _note,
          minLines: 2,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          decoration: InputDecoration(
            labelText: l10n.itemNoteLabel,
            hintText: l10n.itemNoteHint,
            border: const OutlineInputBorder(),
          ),
        ),
        // The photos of the item (DD-018 point 19).
        ItemPhotos(itemId: item.id),
        const SizedBox(height: 8),
        // Link writes [[…]] into this text, as if typed (AC REQ-053).
        DuplicateHint(item: item, onLink: _appendLink),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: mainStep,
              icon: Icon(primary == ItemStatus.done ? Icons.check : Icons.undo),
              label: Text(
                primary == ItemStatus.done
                    ? l10n.itemComplete
                    : l10n.itemReopen,
              ),
            ),
            // Asks who you wait for (DD-018 point 7).
            if (next.contains(ItemStatus.waiting))
              OutlinedButton(
                onPressed: _waitFor,
                child: Text(l10n.itemWaitFor),
              ),
            // Variant B (DD-018 point 13 (a)).
            WhereWasIButton(owner: owner, title: title),
            AddPhotoButton(itemId: item.id),
          ],
        ),
        // When each time of a recurring task was done (DD-018 point 18).
        CompletionHistory(itemId: item.id),
        LinkedFrom(itemId: item.id),
        const SizedBox(height: 16),
        Text(
          l10n.itemCapturedVia(captured, captured, l10n.source(item.source)),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// "Terugzien op ma 12 okt" under the status of a parked item (DD-018 point
/// 17): a tap opens the sheet again, ✕ is *Not any more*.
class _RevisitLine extends StatelessWidget {
  const _RevisitLine({
    required this.day,
    required this.onChange,
    required this.onStop,
  });

  final LocalDate day;
  final VoidCallback onChange;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Material(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onChange,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(start: 12),
            child: Row(
              children: [
                Icon(
                  Icons.update,
                  size: 20,
                  color: colors.onSecondaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.revisitLine(day.toLocalDateTime()),
                    style: TextStyle(color: colors.onSecondaryContainer),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: l10n.revisitStop,
                  onPressed: onStop,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A type choice, where "no type" is a choice too.
class _TypeChoice {
  const _TypeChoice(this.type);

  final ItemType? type;
}

/// A chip that opens a menu of [options].
class _ChoiceChip<T> extends StatelessWidget {
  const _ChoiceChip({
    this.icon,
    required this.label,
    required this.tooltip,
    required this.options,
    required this.onSelected,
  });

  /// Shown before [label], as on the cards (the type, T2.10).
  final IconData? icon;
  final String label;
  final String tooltip;
  final List<(T, String)> options;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) => PopupMenuButton<T>(
    tooltip: tooltip,
    onSelected: onSelected,
    itemBuilder: (_) => [
      for (final (value, text) in options)
        PopupMenuItem(value: value, child: Text(text)),
    ],
    child: Chip(
      avatar: icon == null ? null : Icon(icon, size: 18),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Text(label), const Icon(Icons.arrow_drop_down, size: 18)],
      ),
    ),
  );
}
