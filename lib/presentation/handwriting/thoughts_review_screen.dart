import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/help/help_topics.dart';
import '../../domain/items/item.dart';
import '../../domain/items/item_enums.dart';
import '../../l10n/app_localizations.dart';
import '../help/help_scope.dart';
import '../items/item_providers.dart';
import '../people/text_contacts.dart';
import '../tokens/token_display.dart';
import '../tokens/token_editor.dart';
import '../tokens/token_processor_provider.dart';

/// The review screen after reading handwriting (REQ-064 c, T6a.5, DD-021;
/// PO 12-10-2026): one candidate per thought, to correct or skip, with its
/// live token chips, so a misread date or sign shows. Nothing is saved
/// until *Save*; then the kept thoughts are stored together as inbox items
/// with the source `handwriting` and processed as any capture. Closes with
/// the number saved; back (asking first after an edit) closes with null.
class ThoughtsReviewScreen extends ConsumerStatefulWidget {
  const ThoughtsReviewScreen({super.key, required this.thoughts});

  final List<String> thoughts;

  @override
  ConsumerState<ThoughtsReviewScreen> createState() =>
      _ThoughtsReviewScreenState();
}

class _ThoughtsReviewScreenState extends ConsumerState<ThoughtsReviewScreen> {
  late final List<TextEditingController> _texts = [
    for (final thought in widget.thoughts) TextEditingController(text: thought),
  ];
  late final List<bool> _included = [for (final _ in widget.thoughts) true];
  bool _saving = false;
  bool _failed = false;

  @override
  void dispose() {
    for (final text in _texts) {
      text.dispose();
    }
    super.dispose();
  }

  /// The texts that will be saved: included and not empty.
  List<String> get _kept => [
    for (final (i, text) in _texts.indexed)
      if (_included[i] && hasCapturableText(text.text)) text.text.trim(),
  ];

  bool get _edited =>
      _included.contains(false) ||
      [
        for (final (i, text) in _texts.indexed) text.text != widget.thoughts[i],
      ].contains(true);

  Future<void> _save() async {
    final kept = _kept;
    if (_saving || kept.isEmpty) return;
    setState(() {
      _saving = true;
      _failed = false;
    });
    // Read before waiting: the screen closes after saving.
    final processor = ref.read(tokenProcessorProvider);
    final contacts = TextContactTaker.of(context, ref);
    final List<String> ids;
    try {
      ids = await ref
          .read(itemRepositoryProvider)
          .captureAll(kept, source: ItemSource.handwriting);
    } catch (_) {
      // Nothing was saved (one transaction); the texts stay.
      if (mounted) {
        setState(() {
          _saving = false;
          _failed = true;
        });
      }
      return;
    }
    // Saved first; tokens and contact details afterwards, as for any
    // capture (CLAUDE.md rule 7).
    for (final (i, id) in ids.indexed) {
      unawaited(processor.process(id).catchError((Object _) {}));
      unawaited(contacts.take(kept[i]));
    }
    if (mounted) Navigator.of(context).pop(ids.length);
  }

  Future<void> _leave() async {
    final l10n = AppLocalizations.of(context);
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.reviewThoughtsDiscardTitle),
        content: Text(l10n.reviewThoughtsDiscardBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.reviewThoughtsDiscard),
          ),
        ],
      ),
    );
    if ((discard ?? false) && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final count = _kept.length;
    return HelpScope(
      topic: HelpTopic.capture,
      child: PopScope(
        // An edit is not lost without asking; the photo stays behind. Not
        // while saving: the items are being stored (the pop that follows
        // carries their number).
        canPop: !_saving && !_edited,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && !_saving) unawaited(_leave());
        },
        child: CallbackShortcuts(
          bindings: {
            const SingleActivator(
              LogicalKeyboardKey.enter,
              control: true,
            ): () =>
                unawaited(_save()),
            const SingleActivator(LogicalKeyboardKey.escape): () =>
                Navigator.of(context).maybePop(),
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(l10n.reviewThoughtsTitle),
              actions: const [HelpButton()],
            ),
            body: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(
                          l10n.reviewThoughtsIntro(widget.thoughts.length),
                          style: theme.textTheme.bodyLarge,
                        ),
                        for (final (i, text) in _texts.indexed)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: _Candidate(
                              index: i,
                              text: text,
                              included: _included[i],
                              enabled: !_saving,
                              // A desktop starts in the first thought, for
                              // Tab and Ctrl+Enter; on a phone the keyboard
                              // would cover the list before it is read.
                              autofocus: i == 0 && isDesktop(context),
                              onIncluded: (value) =>
                                  setState(() => _included[i] = value),
                              onChanged: () => setState(() {}),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_failed)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Text(
                        l10n.reviewThoughtsSaveFailed,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: FilledButton.icon(
                        onPressed: _saving || count == 0
                            ? null
                            : () => unawaited(_save()),
                        icon: const Icon(Icons.check),
                        label: Text(l10n.reviewThoughtsSave(count)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One thought: *Include*, its text and what the text will become.
class _Candidate extends StatelessWidget {
  const _Candidate({
    required this.index,
    required this.text,
    required this.included,
    required this.enabled,
    required this.autofocus,
    required this.onIncluded,
    required this.onChanged,
  });

  final int index;
  final TextEditingController text;
  final bool included;
  final bool enabled;
  final bool autofocus;
  final ValueChanged<bool> onIncluded;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card.outlined(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 16, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Checkbox(
                  value: included,
                  semanticLabel: l10n.reviewThoughtsInclude,
                  onChanged: enabled
                      ? (value) => onIncluded(value ?? false)
                      : null,
                ),
                ExcludeSemantics(
                  child: Text(
                    l10n.reviewThoughtsInclude,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: text,
                    autofocus: autofocus,
                    enabled: enabled && included,
                    minLines: 1,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    onChanged: (_) => onChanged(),
                    decoration: InputDecoration(
                      labelText: l10n.reviewThoughtLabel(index + 1),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  // What will be recognised, as in capture (REQ-019): a
                  // misread date or sign shows here (DD-021).
                  if (included) ...[
                    const SizedBox(height: 8),
                    ValueListenableBuilder(
                      valueListenable: text,
                      builder: (context, value, _) =>
                          TokenChips(text: value.text, today: todayOnDevice()),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
