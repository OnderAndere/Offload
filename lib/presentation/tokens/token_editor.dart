import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/items/item_headline.dart';
import '../../domain/links/item_link.dart';
import '../../domain/people/contacts_from_text.dart';
import '../../domain/projects/project_token.dart';
import '../../domain/repeats/repeat.dart';
import '../../domain/settings/prefix_bar_mode.dart';
import '../../domain/time/local_date.dart';
import '../../domain/tokens/inline_token.dart';
import '../../domain/tokens/token_suggestion.dart';
import '../../domain/tokens/token_types.dart';
import '../../l10n/app_localizations.dart';
import '../messages.dart';
import '../projects/project_look.dart';
import '../projects/project_providers.dart';
import '../settings/prefix_bar_provider.dart';
import 'link_choices.dart';
import 'prefix_bar.dart';
import 'token_display.dart';
import 'token_suggestions.dart';

/// Whether the app runs on a desktop: keyboard and mouse, no screen
/// keyboard.
bool isDesktop(BuildContext context) => switch (Theme.of(context).platform) {
  TargetPlatform.windows ||
  TargetPlatform.linux ||
  TargetPlatform.macOS => true,
  TargetPlatform.android ||
  TargetPlatform.iOS ||
  TargetPlatform.fuchsia => false,
};

/// Editing text with inline tokens, the same in quick capture and in the
/// item detail (DD-018): live chips (REQ-019), the suggestion list
/// (REQ-033) and the prefix bar (REQ-034). The screen decides what Enter
/// does and what goes around the field ([header], [footer]).
///
/// Nothing is loaded when it opens: persons and tags only at the first
/// trigger (CLAUDE.md rule 7).
class TokenEditor extends ConsumerStatefulWidget {
  const TokenEditor({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.decoration,
    this.autofocus = false,
    this.readOnly = false,
    this.onSubmit,
    this.shortcuts = const {},
    this.header = const [],
    this.footer = const [],
    this.scrollable = false,
    this.knownDates = const {},
    this.repeat,
    this.thisTime,
    this.repeatsForType = true,
    this.onPersonTap,
    this.onContactTap,
    this.onCreateProject,
    this.linkChoices,
    this.selfItemId,
    this.links = const {},
    this.unlinked = const {},
    this.onOpenItem,
    this.onCreateLinked,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final InputDecoration decoration;
  final bool autofocus;
  final bool readOnly;

  /// Quick capture: Enter (desktop, with the list closed) or the keyboard's
  /// action key (phone) saves, and typing adds no line breaks on a phone.
  /// Null: Enter adds a new line, on both platforms (item detail).
  final VoidCallback? onSubmit;

  /// Extra desktop keys while the suggestion list is closed, e.g. Escape to
  /// go back; with the list open its own keys win (DD-004 point 9).
  final Map<ShortcutActivator, VoidCallback> shortcuts;

  /// Above the field, and below the chips.
  final List<Widget> header;
  final List<Widget> footer;

  /// Dates already worked out for words in the saved text; see
  /// [TokenChips.knownDates].
  final Map<String, LocalDate> knownDates;

  /// [TokenChips.repeat], [TokenChips.thisTime] and
  /// [TokenChips.repeatsForType] (item detail, DD-018 point 18).
  final ItemRepeat? repeat;
  final LocalDate? thisTime;
  final bool repeatsForType;

  /// See [TokenChips.onPersonTap].
  final ValueChanged<String>? onPersonTap;

  /// See [TokenChips.onContactTap].
  final ValueChanged<TextContact>? onContactTap;

  /// See [TokenChips.onCreateProject].
  final ValueChanged<NamesNoProject>? onCreateProject;

  /// Where items chosen from the `[[` list are remembered, so the screen
  /// saves them with the text (DD-004 point 13); null: no `[[` list.
  final LinkChoices? linkChoices;

  /// The item being edited: the `[[` list never offers it.
  final String? selfItemId;

  /// See [TokenChips.links], [TokenChips.unlinked], [TokenChips.onOpenItem]
  /// and [TokenChips.onCreateLinked].
  final Map<String, LinkedItem> links;
  final Set<String> unlinked;
  final ValueChanged<String>? onOpenItem;
  final ValueChanged<String>? onCreateLinked;

  /// True when the content can be taller than the screen (item detail): the
  /// whole content scrolls. False (quick capture): long text scrolls inside
  /// the field, and the chips stay visible.
  final bool scrollable;

  @override
  ConsumerState<TokenEditor> createState() => _TokenEditorState();
}

class _TokenEditorState extends ConsumerState<TokenEditor> {
  late final _suggester = TokenSuggester(
    ref.read(tokenCandidateSourceProvider),
    selfItemId: widget.selfItemId,
    titleOf: widget.linkChoices == null
        ? null
        : (raw, context) => itemHeadline(
            raw,
            ref.read(inlineTokenRegistryProvider),
            context,
          ).title,
  );
  ActiveToken? _active;

  /// A sign put in by a button of a type that shares it (the repeat button
  /// on `!`): the list of the token there is that type's, not the date's.
  ({int start, InlineTokenType type})? _sharedAt;
  List<TokenSuggestion> _suggestions = const [];
  int _highlighted = 0;
  int? _dismissedAt;
  int _lookups = 0;

  TextEditingController get _controller => widget.controller;
  FocusNode get _focusNode => widget.focusNode;

  bool get _listVisible => _active != null && _suggestions.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateSuggestions);
  }

  @override
  void didUpdateWidget(TokenEditor old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_updateSuggestions);
      widget.controller.addListener(_updateSuggestions);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_updateSuggestions);
    super.dispose();
  }

  ParseContext _parseContext() =>
      parseContextOf(AppLocalizations.of(context), todayOnDevice());

  /// Follows the token under the cursor. Never blocks typing: suggestions
  /// arrive when ready, and a late answer for older text is dropped.
  Future<void> _updateSuggestions() async {
    final value = _controller.value;
    final selection = value.selection;
    var active = selection.isValid && selection.isCollapsed
        ? ref
              .read(inlineTokenRegistryProvider)
              .tokenAt(value.text, selection.baseOffset)
        : null;
    final shared = _sharedAt;
    if (active == null || shared == null || active.start != shared.start) {
      _sharedAt = null;
    } else {
      active = (
        type: shared.type,
        start: active.start,
        end: active.end,
        query: active.query,
      );
    }
    if (active == null || active.start != _dismissedAt) _dismissedAt = null;
    final lookup = ++_lookups;
    final suggestions = active == null || active.start == _dismissedAt
        ? const <TokenSuggestion>[]
        : await _suggester.suggest(active, _parseContext());
    if (!mounted || lookup != _lookups) return;
    // Nothing to show before or after: no rebuild on every keystroke.
    if (_active == null && active == null && _suggestions.isEmpty) return;
    setState(() {
      _active = active;
      _suggestions = suggestions;
      _highlighted = 0;
    });
  }

  /// Replaces the word being typed with [suggestion]. At the end of the
  /// text a space follows, ready for the next word; elsewhere the rest of
  /// the text (a bracket, a comma, a space) stays exactly as it was and the
  /// cursor goes right after the chosen word.
  Future<void> _choose(TokenSuggestion suggestion) async {
    final active = _active;
    if (active == null) return;
    final itemId = suggestion.itemId;
    if (active.type is LinkTokenType && itemId != null) {
      _chooseItem(active, suggestion.insert, itemId);
      return;
    }
    var word = suggestion.insert;
    if (suggestion.pickDate) {
      final picked = await _pickDate();
      if (picked == null || !mounted) return;
      word = fixedDateWord(picked);
    }
    // "Create project": made right away, at the top level (AC REQ-050,
    // DD-004 point 11); if that fails, the word is not put in. A second
    // Enter or tap while it is being made does nothing.
    if (suggestion.isNew && active.type is ProjectTokenType) {
      if (_creating) return;
      _creating = true;
      try {
        if (!await _createProject(suggestion.label) || !mounted) return;
      } finally {
        _creating = false;
      }
    }
    final text = _controller.text;
    // The text may have changed while the calendar was open.
    if (active.end > text.length) return;
    final atEnd = active.end == text.length;
    final inserted = word + (atEnd ? ' ' : '');
    // Chosen: the list stays closed for this token, as after Escape, so
    // Enter then saves (PO decision 27-09-2026). Mid-text the cursor stays
    // in the token; leaving it opens the list again for the next one.
    _dismissedAt = active.start;
    _controller.value = TextEditingValue(
      text:
          text.substring(0, active.start + 1) +
          inserted +
          text.substring(active.end),
      selection: TextSelection.collapsed(
        offset: active.start + 1 + inserted.length,
      ),
    );
    _focusNode.requestFocus();
  }

  /// Puts `[[label]]` in place of the link being typed (its closing signs
  /// included, when there) and remembers the chosen item (DD-004 point 13).
  void _chooseItem(ActiveToken active, String label, String itemId) {
    final text = _controller.text;
    if (active.end > text.length) return;
    widget.linkChoices?.remember(label, itemId);
    final atEnd = active.end == text.length;
    final inserted =
        '[[$label]]${atEnd ? ' ' : ''}'; // l10n-ignore: the link token
    _dismissedAt = active.start;
    _controller.value = TextEditingValue(
      text:
          text.substring(0, active.start) +
          inserted +
          text.substring(active.end),
      selection: TextSelection.collapsed(
        offset: active.start + inserted.length,
      ),
    );
    _focusNode.requestFocus();
  }

  /// A project from "Create project" is being made.
  var _creating = false;

  Future<bool> _createProject(String name) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(projectRepositoryProvider).create(name);
      _suggester.forgetProjects();
      return true;
    } catch (e) {
      showMessage(
        messenger,
        SnackBar(content: Text(projectErrorText(e, l10n))),
      );
      return false;
    }
  }

  Future<LocalDate?> _pickDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: DateTime(today.year - 1),
      lastDate: DateTime(today.year + 10),
    );
    return picked == null ? null : LocalDate.of(picked);
  }

  /// A prefix bar button (AC REQ-034): puts [sign] at the cursor, or over
  /// the selected text, so the suggestion list opens. Right after a letter a
  /// space goes first, or the sign would start no token (PO decision
  /// 27-09-2026).
  void _insertPrefix(String sign, InlineTokenType type) {
    if (widget.readOnly) return;
    final value = _controller.value;
    final text = value.text;
    final selection = value.selection.isValid
        ? value.selection
        : TextSelection.collapsed(offset: text.length);
    final start = selection.start;
    final inserted =
        (ref.read(inlineTokenRegistryProvider).isTokenStart(text, start)
            ? ''
            : ' ') +
        sign;
    _sharedAt = type.sharesPrefix
        ? (start: start + inserted.length - sign.length, type: type)
        : null;
    _controller.value = TextEditingValue(
      text: text.replaceRange(start, selection.end, inserted),
      selection: TextSelection.collapsed(offset: start + inserted.length),
    );
    _focusNode.requestFocus();
  }

  Future<void> _showSyntax({required bool desktop}) async {
    await showSyntaxOverview(context, desktop: desktop);
    if (mounted) _focusNode.requestFocus();
  }

  void _moveHighlight(int step) {
    if (!_listVisible) return;
    setState(() {
      _highlighted = (_highlighted + step) % _suggestions.length;
    });
  }

  void _chooseHighlighted() => _choose(_suggestions[_highlighted]);

  /// Escape closes only the list, for this token (PO decision 27-09-2026).
  void _dismissList() => setState(() {
    _dismissedAt = _active?.start;
    _suggestions = const [];
  });

  @override
  Widget build(BuildContext context) {
    final desktop = isDesktop(context);
    final submit = widget.onSubmit;
    final barMode = ref.watch(prefixBarModeProvider);
    // Taps on the bar and the list count as taps in the field, so the phone
    // keyboard stays open.
    final bar = barMode == PrefixBarMode.off
        ? null
        : TextFieldTapRegion(
            child: PrefixBar(
              mode: barMode,
              onInsert: _insertPrefix,
              onHelp: () => _showSyntax(desktop: desktop),
            ),
          );

    // A single logical line on a phone only when the action key saves;
    // otherwise the keyboard shows its new-line key.
    final singleLine = !desktop && submit != null;
    Widget field = TextField(
      controller: _controller,
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      readOnly: widget.readOnly,
      minLines: 3,
      maxLines: null,
      keyboardType: singleLine ? TextInputType.text : TextInputType.multiline,
      textInputAction: singleLine
          ? TextInputAction.done
          : TextInputAction.newline,
      onSubmitted: singleLine ? (_) => submit() : null,
      decoration: widget.decoration,
    );
    if (desktop) {
      // With the suggestion list open, the arrows move through it, Enter or
      // Tab chooses and Escape closes the list; otherwise the screen's keys.
      // Shift+Enter is not bound and reaches the field as a new line.
      field = CallbackShortcuts(
        bindings: _listVisible
            ? {
                const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
                    _moveHighlight(1),
                const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
                    _moveHighlight(-1),
                const SingleActivator(LogicalKeyboardKey.enter):
                    _chooseHighlighted,
                const SingleActivator(LogicalKeyboardKey.numpadEnter):
                    _chooseHighlighted,
                const SingleActivator(LogicalKeyboardKey.tab):
                    _chooseHighlighted,
                const SingleActivator(LogicalKeyboardKey.escape): _dismissList,
              }
            : {
                if (submit != null) ...{
                  const SingleActivator(LogicalKeyboardKey.enter): submit,
                  const SingleActivator(LogicalKeyboardKey.numpadEnter): submit,
                },
                ...widget.shortcuts,
              },
        child: field,
      );
    }

    final list = _listVisible
        ? TextFieldTapRegion(
            child: TokenSuggestionList(
              type: _active!.type,
              suggestions: _suggestions,
              highlighted: desktop ? _highlighted : null,
              onChoose: _choose,
            ),
          )
        : null;
    // What will be recognised, live while typing (REQ-019).
    final chips = ValueListenableBuilder(
      valueListenable: _controller,
      builder: (context, value, _) => TokenChips(
        text: value.text,
        today: todayOnDevice(),
        knownDates: widget.knownDates,
        repeat: widget.repeat,
        thisTime: widget.thisTime,
        repeatsForType: widget.repeatsForType,
        onPersonTap: widget.onPersonTap,
        onContactTap: widget.onContactTap,
        onCreateProject: widget.onCreateProject,
        links: widget.links,
        unlinked: widget.unlinked,
        choices: widget.linkChoices,
        onOpenItem: widget.onOpenItem,
        onCreateLinked: widget.onCreateLinked,
      ),
    );
    final bounded = !widget.scrollable;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...widget.header,
        // Bounded (quick capture): long text scrolls inside the field and
        // the chips stay visible.
        if (bounded) Flexible(child: field) else field,
        // A desktop has no screen keyboard: the bar goes right under the
        // field (PO decision 27-09-2026).
        if (desktop && bar != null) ...[
          const SizedBox(height: 8),
          Align(alignment: AlignmentDirectional.centerStart, child: bar),
        ],
        if (list != null) ...[
          const SizedBox(height: 8),
          if (bounded) Flexible(child: list) else list,
        ],
        const SizedBox(height: 12),
        Align(alignment: AlignmentDirectional.centerStart, child: chips),
        ...widget.footer,
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: widget.scrollable
              ? SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: content,
                )
              : Padding(padding: const EdgeInsets.all(16), child: content),
        ),
        // On a phone the bar sits right above the keyboard (AC REQ-034):
        // the body shrinks when the keyboard opens.
        if (!desktop && bar != null)
          Material(
            color: Theme.of(context).colorScheme.surfaceContainer,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: bar,
            ),
          ),
      ],
    );
  }
}
