import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/help/help_topics.dart';
import '../../domain/items/item.dart';
import '../../domain/items/item_classification.dart';
import '../../domain/items/item_enums.dart';
import '../../domain/items/item_headline.dart';
import '../../domain/time/local_date.dart';
import '../../domain/time/relative_age.dart';
import '../../domain/triage/triage.dart';
import '../../l10n/app_localizations.dart';
import '../help/help_scope.dart';
import '../inbox/inbox_card.dart';
import '../items/item_detail_screen.dart';
import '../items/item_providers.dart';
import '../items/item_type_look.dart';
import '../messages.dart';
import '../projects/project_picker.dart';
import '../revisit/revisit_sheet.dart';
import '../search/duplicate_hint.dart';
import '../tokens/token_display.dart';
import '../tokens/token_editor.dart';
import 'person_sheet.dart';

/// Triage (T2.4, REQ-010; design DD-018 point 3): the inbox card by card,
/// each card to one of six destinations with a button; swiping only moves
/// on (right = skip) or throws away (left = trash). Every choice can be
/// undone at once. Closing stops; what was chosen stays.
class TriageScreen extends ConsumerStatefulWidget {
  const TriageScreen({super.key, required this.inbox, this.fromToday = false});

  /// The inbox at the start, in its order.
  final List<String> inbox;

  /// Started from the inbox line on Today: the end then says "Back"
  /// instead of "Back to the inbox" (DD-018 point 4).
  final bool fromToday;

  static Future<void> open(
    BuildContext context,
    List<String> inbox, {
    bool fromToday = false,
  }) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: routeName),
      builder: (_) => TriageScreen(inbox: inbox, fromToday: fromToday),
    ),
  );

  /// The name of its route: on Windows the keys that switch destination
  /// leave triage alone (DD-018 point 5).
  static const routeName = 'triage'; // l10n-ignore: route name, not shown

  @override
  ConsumerState<TriageScreen> createState() => _TriageScreenState();
}

class _TriageScreenState extends ConsumerState<TriageScreen> {
  late final _session = TriageSession(widget.inbox);

  /// Takes the last choice back, or null when there is nothing to undo.
  /// Single use: it clears itself, so an undo is never one step too many.
  Future<void> Function()? _undoLast;

  /// A choice is being written (or its person looked up): further choices
  /// wait, so one card is never sorted twice.
  var _busy = false;

  /// Records the choice for card [id]; false when that card is no longer
  /// current (a late or double choice), and then nothing happens. Every
  /// new choice ends the previous one's undo, message included.
  bool _decided(String id, TriageOutcome outcome) {
    if (!_session.decide(id, outcome)) return false;
    ScaffoldMessenger.of(context).clearSnackBars();
    setState(() => _undoLast = null);
    return true;
  }

  Future<void> _skip(String id) async {
    if (_busy || !_decided(id, TriageOutcome.skipped)) return;
    _undoLast = () async {
      _undoLast = null;
      if (mounted) setState(() => _session.undo(id));
    };
  }

  Future<void> _send(Item item, TriageDestination destination) async {
    if (_busy) return;
    _busy = true;
    try {
      await _sendNow(item, destination);
    } finally {
      _busy = false;
    }
  }

  Future<void> _sendNow(Item item, TriageDestination destination) async {
    final l10n = AppLocalizations.of(context);
    final keep = keepUndoMessage(context);
    final messenger = ScaffoldMessenger.of(context);
    final items = ref.read(itemRepositoryProvider);
    String? personId;
    LocalDate? expected;
    if (destination.asksForPerson) {
      final choice = await showPersonSheet(
        context,
        title: destination == TriageDestination.request
            ? l10n.triageWhoAsked
            : l10n.triageWaitingOn,
        // Waiting: optionally by when (DD-018 point 10 (d)).
        askExpected: destination == TriageDestination.waitingFor,
      );
      if (choice == null || !mounted) return; // the sheet was closed
      expected = choice.expected;
      final name = choice.name;
      if (name != null) {
        try {
          personId = await ref.read(peopleRepositoryProvider).idFor(name);
        } catch (_) {
          showMessage(
            messenger,
            SnackBar(content: Text(l10n.itemChangeFailed)),
          );
          return;
        }
      }
    }
    final before = ItemClassification.of(item);
    if (!mounted || !_decided(item.id, TriageOutcome.sorted)) return;
    try {
      if (destination == TriageDestination.trash) {
        await items.moveToTrash(item.id);
      } else {
        // Waiting: exactly the day chosen, none included, in the same
        // change (DD-018 point 10 (d)).
        await items.classify(
          item.id,
          sortInto(item, destination, personId: personId),
          expected: destination == TriageDestination.waitingFor
              ? (day: expected)
              : null,
        );
      }
    } catch (_) {
      if (mounted) setState(() => _session.undo(item.id));
      showMessage(messenger, SnackBar(content: Text(l10n.itemChangeFailed)));
      return;
    }
    var used = false;
    Future<void> undo() async {
      // Only the last choice, and only once (PO decision 28-09-2026).
      if (used || _busy || !_session.canUndo(item.id)) return;
      used = true;
      _undoLast = null;
      // No new choice while the undo is written: it could not step back.
      _busy = true;
      try {
        if (destination == TriageDestination.trash) {
          await items.restoreFromTrash(item.id);
        } else {
          await items.classify(
            item.id,
            before,
            expected: destination == TriageDestination.waitingFor
                ? (day: item.expectedAt)
                : null,
          );
        }
      } catch (_) {
        showMessage(messenger, SnackBar(content: Text(l10n.itemUndoFailed)));
        return;
      } finally {
        _busy = false;
      }
      if (mounted) setState(() => _session.undo(item.id));
    }

    _undoLast = undo;
    showMessage(
      messenger,
      undoSnackBar(
        l10n: l10n,
        keep: keep,
        message: destination == TriageDestination.trash
            ? l10n.itemMovedToTrash
            : l10n.triageMovedTo(destinationLabel(destination, l10n)),
        onUndo: () => unawaited(undo()),
      ),
    );
  }

  /// *Later…* (DD-018 point 17): parks the card until a date from the
  /// sheet. It counts as processed, with the usual message and undo.
  Future<void> _later(Item item) async {
    if (_busy) return;
    _busy = true;
    try {
      await _laterNow(item);
    } finally {
      _busy = false;
    }
  }

  Future<void> _laterNow(Item item) async {
    final l10n = AppLocalizations.of(context);
    final keep = keepUndoMessage(context);
    final messenger = ScaffoldMessenger.of(context);
    final items = ref.read(itemRepositoryProvider);
    final day = (await showRevisitSheet(context))?.day;
    if (day == null || !mounted) return;
    final before = ItemClassification.of(item);
    if (!_decided(item.id, TriageOutcome.sorted)) return;
    try {
      await items.revisitOn(item.id, day);
    } catch (_) {
      if (mounted) setState(() => _session.undo(item.id));
      showMessage(messenger, SnackBar(content: Text(l10n.itemChangeFailed)));
      return;
    }
    var used = false;
    Future<void> undo() async {
      if (used || _busy || !_session.canUndo(item.id)) return;
      used = true;
      _undoLast = null;
      _busy = true;
      try {
        await items.classify(item.id, before);
      } catch (_) {
        showMessage(messenger, SnackBar(content: Text(l10n.itemUndoFailed)));
        return;
      } finally {
        _busy = false;
      }
      if (mounted) setState(() => _session.undo(item.id));
    }

    _undoLast = undo;
    showMessage(
      messenger,
      undoSnackBar(
        l10n: l10n,
        keep: keep,
        message: l10n.revisitBackOn(day.toLocalDateTime()),
        onUndo: () => unawaited(undo()),
      ),
    );
  }

  Future<void> _open(Item item) async {
    await ItemDetailScreen.open(context, item.id);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    ref.listen(inboxProvider, (_, next) {
      final items = next.valueOrNull;
      if (items != null) {
        setState(() => _session.update([for (final i in items) i.id]));
      }
    });
    final inbox = {
      for (final item in ref.watch(inboxProvider).valueOrNull ?? const <Item>[])
        item.id: item,
    };
    final currentId = _session.current;
    final item = currentId == null ? null : inbox[currentId];
    final desktop = isDesktop(context);
    final done = currentId == null;

    Future<void> send(TriageDestination d) async {
      if (item != null) await _send(item, d);
    }

    Future<void> skip() async {
      if (item != null) await _skip(item.id);
    }

    Future<void> later() async {
      if (item != null) await _later(item);
    }

    final shortcuts = <ShortcutActivator, VoidCallback>{
      if (!done) ...{
        for (final (i, d) in _numbered.indexed) ...{
          SingleActivator(_digitKeys[i]): () => unawaited(send(d)),
          SingleActivator(_numpadKeys[i]): () => unawaited(send(d)),
        },
        const SingleActivator(LogicalKeyboardKey.delete): () =>
            unawaited(send(TriageDestination.trash)),
        // The key after the numbered destinations (DD-018 point 17).
        SingleActivator(_digitKeys[_laterIndex]): () => unawaited(later()),
        SingleActivator(_numpadKeys[_laterIndex]): () => unawaited(later()),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
            unawaited(skip()),
        const SingleActivator(LogicalKeyboardKey.space): () =>
            unawaited(skip()),
        if (item != null) ...{
          const SingleActivator(LogicalKeyboardKey.enter): () =>
              unawaited(_open(item)),
          // The project of the card; it does not process the card (DD-018
          // point 6).
          const SingleActivator(LogicalKeyboardKey.keyP): () => unawaited(
            chooseProjectFor(
              context,
              ref,
              itemId: item.id,
              currentId: item.projectId,
            ),
          ),
        },
      },
      // Not on key repeat: holding Ctrl+Z is still one undo.
      const SingleActivator(
        LogicalKeyboardKey.keyZ,
        control: true,
        includeRepeats: false,
      ): () {
        final undo = _undoLast;
        if (undo != null) unawaited(undo());
      },
      const SingleActivator(LogicalKeyboardKey.escape): () =>
          Navigator.of(context).maybePop(),
    };

    return HelpScope(
      topic: HelpTopic.triage,
      child: CallbackShortcuts(
        bindings: shortcuts,
        child: Focus(
          autofocus: true,
          child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close),
                tooltip: l10n.triageStop,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              title: Text(l10n.triageTitle),
              actions: [
                if (!done)
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Center(
                      child: Text(
                        l10n.triageProgress(_session.position, _session.total),
                      ),
                    ),
                  ),
                const HelpButton(),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: LinearProgressIndicator(
                  value: _session.total == 0
                      ? 1
                      : (_session.position - 1) / _session.total,
                ),
              ),
            ),
            body: done
                ? _Finished(
                    processed: _session.processed,
                    skipped: _session.skipped,
                    fromToday: widget.fromToday,
                  )
                : item == null
                // Briefly, while the inbox catches up with an undo.
                ? const Center(child: CircularProgressIndicator())
                : _Card(
                    item: item,
                    desktop: desktop,
                    onSkip: skip,
                    onSend: send,
                    onOpen: () => _open(item),
                    canSwipe: () => !_busy,
                  ),
            // In the bottom bar, so the undo message appears above the
            // buttons instead of covering them.
            bottomNavigationBar: done || item == null
                ? null
                : SafeArea(
                    child: Center(
                      heightFactor: 1,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _Buttons(desktop: desktop, onSend: send),
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 8,
                                children: [
                                  if (desktop)
                                    TextButton.icon(
                                      onPressed: skip,
                                      icon: const Icon(Icons.skip_next),
                                      label: Text(l10n.triageSkip),
                                    ),
                                  // Parks the card (DD-018 point 17).
                                  TextButton.icon(
                                    onPressed: later,
                                    icon: const Icon(Icons.update),
                                    label: Text(
                                      desktop
                                          ? l10n.revisitLaterWithKey(
                                              (_laterIndex + 1).toString(),
                                            )
                                          : l10n.revisitLater,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// The destinations with a number key on Windows, in button order.
const _numbered = [
  TriageDestination.task,
  TriageDestination.idea,
  TriageDestination.request,
  TriageDestination.waitingFor,
  TriageDestination.note,
];

const _digitKeys = [
  LogicalKeyboardKey.digit1,
  LogicalKeyboardKey.digit2,
  LogicalKeyboardKey.digit3,
  LogicalKeyboardKey.digit4,
  LogicalKeyboardKey.digit5,
  LogicalKeyboardKey.digit6,
];

const _numpadKeys = [
  LogicalKeyboardKey.numpad1,
  LogicalKeyboardKey.numpad2,
  LogicalKeyboardKey.numpad3,
  LogicalKeyboardKey.numpad4,
  LogicalKeyboardKey.numpad5,
  LogicalKeyboardKey.numpad6,
];

/// *Later…* takes the key after the numbered destinations; its button shows
/// that number (DD-018 point 17).
final _laterIndex = _numbered.length;

/// The name of a destination on its button and in the message.
String destinationLabel(TriageDestination d, AppLocalizations l10n) =>
    switch (d) {
      TriageDestination.task => l10n.itemTypeTask,
      TriageDestination.idea => l10n.itemTypeIdea,
      TriageDestination.request => l10n.itemTypeRequest,
      TriageDestination.waitingFor => l10n.triageWaitFor,
      TriageDestination.note => l10n.itemTypeNote,
      TriageDestination.trash => l10n.triageTrash,
    };

/// The icon of a destination; the types look as on the cards (T2.10).
IconData _icon(TriageDestination d) => switch (d) {
  TriageDestination.task => itemTypeIcon(ItemType.task),
  TriageDestination.idea => itemTypeIcon(ItemType.idea),
  TriageDestination.request => itemTypeIcon(ItemType.request),
  TriageDestination.waitingFor => Icons.hourglass_empty,
  TriageDestination.note => itemTypeIcon(ItemType.note),
  TriageDestination.trash => Icons.delete_outline,
};

/// One card with the six destinations below it (DD-018 point 3).
class _Card extends ConsumerWidget {
  const _Card({
    required this.item,
    required this.desktop,
    required this.onSkip,
    required this.onSend,
    required this.onOpen,
    required this.canSwipe,
  });

  final Item item;
  final bool desktop;
  final Future<void> Function() onSkip;
  final Future<void> Function(TriageDestination) onSend;
  final VoidCallback onOpen;

  /// False while a choice is being written: a swipe then snaps back instead
  /// of leaving a dismissed card that nothing replaces.
  final bool Function() canSwipe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final now = ref.watch(minuteClockProvider).valueOrNull ?? DateTime.now();
    final today = LocalDate.of(now);
    final tokens = ref.watch(liveItemTokensProvider).valueOrNull ?? const {};
    final headline = itemHeadline(
      item.rawText,
      ref.watch(inlineTokenRegistryProvider),
      parseContextOf(l10n, today),
    );
    final rest = textAfterFirstLine(item.rawText);
    final age = relativeAgeTexts(
      relativeAge(item.capturedAt.toLocal(), now),
      l10n,
    );
    Widget card = Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(headline.title, style: theme.textTheme.titleMedium),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (rest.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(rest, style: theme.textTheme.bodyMedium),
                      ),
                    StoredTokenChips(
                      item: item,
                      tokens: tokens[item.id] ?? const [],
                      today: today,
                      showProject: false,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: ItemProjectChip(
                        itemId: item.id,
                        projectId: item.projectId,
                      ),
                    ),
                    DuplicateHint(item: item),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Semantics(
                  label: age.long,
                  excludeSemantics: true,
                  child: Text(
                    age.short,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const Spacer(),
                TextButton(onPressed: onOpen, child: Text(l10n.triageOpen)),
              ],
            ),
          ],
        ),
      ),
    );
    card = Semantics(
      customSemanticsActions: {
        CustomSemanticsAction(label: l10n.triageSkip): () =>
            unawaited(onSkip()),
        CustomSemanticsAction(label: l10n.triageTrash): () =>
            unawaited(onSend(TriageDestination.trash)),
      },
      child: card,
    );
    if (!desktop) {
      // Swipes only move on or throw away (DD-018 point 3).
      card = Dismissible(
        key: ValueKey(item.id),
        background: _SwipeHint(
          label: l10n.triageSkip,
          icon: Icons.skip_next,
          alignment: AlignmentDirectional.centerStart,
        ),
        secondaryBackground: _SwipeHint(
          label: l10n.triageTrash,
          icon: Icons.delete_outline,
          alignment: AlignmentDirectional.centerEnd,
        ),
        confirmDismiss: (_) async => canSwipe(),
        onDismissed: (direction) => unawaited(
          direction == DismissDirection.startToEnd
              ? onSkip()
              : onSend(TriageDestination.trash),
        ),
        child: card,
      );
    }
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: card,
        ),
      ),
    );
  }
}

/// The six destinations as a 3×2 grid of large buttons; on Windows each
/// shows its key.
class _Buttons extends StatelessWidget {
  const _Buttons({required this.desktop, required this.onSend});

  final bool desktop;
  final Future<void> Function(TriageDestination) onSend;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget button(TriageDestination d) {
      final index = _numbered.indexOf(d);
      final key = desktop
          ? (index >= 0 ? (index + 1).toString() : l10n.triageDeleteKey)
          : null;
      final trash = d == TriageDestination.trash;
      final color = trash
          ? Theme.of(context).colorScheme.onSurfaceVariant
          : null;
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 64),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              foregroundColor: color,
            ),
            onPressed: () => unawaited(onSend(d)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_icon(d)),
                const SizedBox(height: 4),
                Text(
                  key == null
                      ? destinationLabel(d, l10n)
                      : l10n.triageButtonWithKey(
                          destinationLabel(d, l10n),
                          key,
                        ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            button(TriageDestination.task),
            button(TriageDestination.idea),
            button(TriageDestination.request),
          ],
        ),
        Row(
          children: [
            button(TriageDestination.waitingFor),
            button(TriageDestination.note),
            button(TriageDestination.trash),
          ],
        ),
      ],
    );
  }
}

/// What shows under a card being swiped: skip or trash, calm and grey.
class _SwipeHint extends StatelessWidget {
  const _SwipeHint({
    required this.label,
    required this.icon,
    required this.alignment,
  });

  final String label;
  final IconData icon;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      alignment: alignment,
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: colors.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: colors.onSurfaceVariant)),
        ],
      ),
    );
  }
}

/// After the last card: a positive confirmation, never a blank screen
/// (SPEC §5 edge cases).
class _Finished extends StatelessWidget {
  const _Finished({
    required this.processed,
    required this.skipped,
    required this.fromToday,
  });

  final int processed;
  final int skipped;
  final bool fromToday;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(l10n.triageDoneTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(l10n.triageDoneProcessed(processed)),
            if (skipped > 0) Text(l10n.triageDoneSkipped(skipped)),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: Text(fromToday ? l10n.triageBack : l10n.triageBackToInbox),
            ),
          ],
        ),
      ),
    );
  }
}
