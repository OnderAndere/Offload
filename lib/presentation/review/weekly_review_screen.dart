import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/help/help_topics.dart';
import '../../domain/items/item.dart';
import '../../domain/items/item_classification.dart';
import '../../domain/items/item_enums.dart';
import '../../domain/review/weekly_review.dart';
import '../../domain/time/local_date.dart';
import '../../l10n/app_localizations.dart';
import '../help/help_scope.dart';
import '../home/destination.dart';
import '../home/item_panes.dart';
import '../home/list_keys.dart';
import '../inbox/inbox_card.dart';
import '../items/complete_undo.dart';
import '../items/item_providers.dart';
import '../items/swipe_backgrounds.dart';
import '../items/trash_undo.dart';
import '../messages.dart';
import '../overview/insights_screen.dart';
import '../people/person_actions.dart';
import '../projects/project_providers.dart';
import '../repeats/repeat_providers.dart';
import '../revisit/revisit_sheet.dart';
import '../theme/design_tokens.dart';
import '../tokens/token_editor.dart';
import '../triage/triage_screen.dart';
import 'review_providers.dart';

/// The review's own card keys: on a phone it lies over *Today*, which can
/// show the same items (DD-018 point 8).
const Object _cardScope = #weeklyReview;

/// What the user did with a card in the review; it stays in view with
/// this mark (DD-018 point 8).
enum _Handled { waiting, kept, done, archived, trashed, parked }

/// The weekly review (REQ-013, AC REQ-051, DD-018 point 8): a start screen
/// with four steps, one step per screen, and an end screen. Nothing is
/// remembered between two reviews. On Windows it is a mode in the list
/// pane ([embedded]), the detail pane shows the selected item; on a phone
/// it is a screen of its own.
class WeeklyReviewScreen extends ConsumerStatefulWidget {
  const WeeklyReviewScreen({super.key, this.embedded = false});

  final bool embedded;

  /// Starts the review: on Windows in the list pane, on a phone as a
  /// screen over the current one.
  static void open(BuildContext context, WidgetRef ref) {
    if (isDesktop(context)) {
      ref.read(selectedItemProvider.notifier).state = null;
      ref.read(weeklyReviewWideProvider.notifier).state = false;
      ref.read(weeklyReviewOpenProvider.notifier).state = true;
      return;
    }
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const WeeklyReviewScreen()),
      ),
    );
  }

  @override
  ConsumerState<WeeklyReviewScreen> createState() => _WeeklyReviewScreenState();
}

class _WeeklyReviewScreenState extends ConsumerState<WeeklyReviewScreen> {
  /// The step on screen; null is the start screen.
  ReviewStep? _step;
  bool _ended = false;

  /// Steps 2 and 4 keep the items they opened with, so a handled card
  /// stays in view (DD-018 point 8).
  final _snapshot = <ReviewStep, List<Item>>{};
  final _handled = <String, _Handled>{};

  /// The day each card parked with *Later…* comes back (DD-018 point 17).
  final _parkedOn = <String, LocalDate>{};

  /// The list's focus in a narrow window; with panes the list pane's.
  final _listFocus = FocusNode();

  @override
  void dispose() {
    _listFocus.dispose();
    super.dispose();
  }

  /// Puts the focus in the list of the step, so its keys work at once: the
  /// review held it on the start screen, and a later autofocus does not
  /// take it over (DD-018 point 8).
  void _focusList() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      (ItemPanes.maybeOf(context)?.listFocus ?? _listFocus).requestFocus();
    });
  }

  DateTime get _now =>
      ref.read(minuteClockProvider).valueOrNull ?? DateTime.now();

  List<Item> get _live => ref.read(liveItemsProvider).valueOrNull ?? const [];

  void _close() {
    _setWide(false);
    if (widget.embedded) {
      ref.read(weeklyReviewOpenProvider.notifier).state = false;
    } else {
      Navigator.of(context).maybePop();
    }
  }

  void _toToday() {
    ref.read(destinationProvider.notifier).state = Destination.today;
    _close();
  }

  /// What step [step] has to do now.
  int _workIn(ReviewStep step) {
    final live = _live;
    return switch (step) {
      // Always shown: it is the whole picture (DD-018 point 12 (g)).
      ReviewStep.insights => 1,
      ReviewStep.inbox => ref.read(inboxProvider).valueOrNull?.length ?? 0,
      ReviewStep.waiting => waitingForReview(live).length,
      ReviewStep.deadlines => () {
        final d = deadlinesForReview(live, LocalDate.of(_now));
        return d.overdue.length + d.upcoming.length;
      }(),
      ReviewStep.stale => staleItems(
        live,
        _now,
        ref.read(staleAfterProvider),
        repeats: ref.read(repeatsProvider).valueOrNull ?? const {},
      ).length,
    };
  }

  void _open(ReviewStep step) {
    final live = _live;
    setState(() {
      _step = step;
      _ended = false;
      switch (step) {
        case ReviewStep.waiting:
          _snapshot[step] = waitingForReview(live);
        case ReviewStep.stale:
          _snapshot[step] = staleItems(
            live,
            _now,
            ref.read(staleAfterProvider),
            repeats: ref.read(repeatsProvider).valueOrNull ?? const {},
          );
        case ReviewStep.insights || ReviewStep.inbox || ReviewStep.deadlines:
          break;
      }
    });
    ref.read(selectedItemProvider.notifier).state = null;
    _setWide(step == ReviewStep.insights);
    _focusList();
  }

  /// On Windows the Overview step takes both panes (DD-018 point 12 (g)).
  void _setWide(bool wide) =>
      ref.read(weeklyReviewWideProvider.notifier).state = wide;

  /// The next step with something to do, or the end screen.
  void _next() {
    final from = _step == null ? 0 : _step!.index + 1;
    for (final step in ReviewStep.values.skip(from)) {
      if (_workIn(step) > 0) return _open(step);
    }
    setState(() {
      _step = null;
      _ended = true;
    });
    _setWide(false);
    ref.read(selectedItemProvider.notifier).state = null;
    // Reaching the end screen completes the review (DD-018 point 8). A
    // failed write only means Today asks again after a restart.
    unawaited(
      ref.read(lastReviewProvider.notifier).complete(_now).catchError((_) {}),
    );
  }

  /// The previous step with something to do, or the start screen.
  void _previous() {
    final step = _step;
    if (step == null) return;
    for (final earlier
        in ReviewStep.values.take(step.index).toList().reversed) {
      if (_workIn(earlier) > 0) return _open(earlier);
    }
    setState(() => _step = null);
    _setWide(false);
  }

  void _mark(String id, _Handled? handled) {
    if (!mounted) return;
    setState(() {
      if (handled == null) {
        _handled.remove(id);
      } else {
        _handled[id] = handled;
      }
    });
  }

  Future<void> _reviewed(Item item, _Handled handled) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(itemRepositoryProvider).markReviewed(item.id);
      _mark(item.id, handled);
    } catch (_) {
      showMessage(messenger, SnackBar(content: Text(l10n.itemChangeFailed)));
    }
  }

  Future<void> _complete(Item item) async {
    final done = await completeWithUndo(
      messenger: ScaffoldMessenger.of(context),
      l10n: AppLocalizations.of(context),
      items: ref.read(itemRepositoryProvider),
      item: item,
      onUndo: () => _mark(item.id, null),
    );
    if (done) _mark(item.id, _Handled.done);
  }

  Future<void> _trash(Item item) async {
    final trashed = await trashWithUndo(
      messenger: ScaffoldMessenger.of(context),
      l10n: AppLocalizations.of(context),
      items: ref.read(itemRepositoryProvider),
      id: item.id,
      onUndo: () => _mark(item.id, null),
    );
    if (trashed) _mark(item.id, _Handled.trashed);
  }

  /// Archives [item] with undo, which puts back exactly the status it had
  /// (as completing from Today does).
  Future<void> _archive(Item item) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final keep = keepUndoMessage(context);
    final items = ref.read(itemRepositoryProvider);
    final before = ItemClassification.of(item);
    try {
      await items.moveTo(item.id, ItemStatus.archived);
    } catch (_) {
      showMessage(messenger, SnackBar(content: Text(l10n.itemChangeFailed)));
      return;
    }
    _mark(item.id, _Handled.archived);
    showMessage(
      messenger,
      undoSnackBar(
        message: l10n.reviewArchived,
        l10n: l10n,
        keep: keep,
        onUndo: () {
          _mark(item.id, null);
          unawaited(
            items.classify(item.id, before).catchError((Object _) {
              showMessage(
                messenger,
                SnackBar(content: Text(l10n.itemChangeFailed)),
              );
            }),
          );
        },
      ),
    );
  }

  /// *Later…* (DD-018 point 17): parks [item] until a date from the sheet,
  /// with undo, which puts back the status and date it had.
  Future<void> _later(Item item) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final keep = keepUndoMessage(context);
    final items = ref.read(itemRepositoryProvider);
    final before = ItemClassification.of(item);
    final day = (await showRevisitSheet(context))?.day;
    if (day == null || !mounted) return;
    try {
      await items.revisitOn(item.id, day);
    } catch (_) {
      showMessage(messenger, SnackBar(content: Text(l10n.itemChangeFailed)));
      return;
    }
    _parkedOn[item.id] = day;
    _mark(item.id, _Handled.parked);
    showMessage(
      messenger,
      undoSnackBar(
        message: l10n.revisitBackOn(day.toLocalDateTime()),
        l10n: l10n,
        keep: keep,
        onUndo: () {
          _mark(item.id, null);
          unawaited(
            items.classify(item.id, before).catchError((Object _) {
              showMessage(
                messenger,
                SnackBar(content: Text(l10n.itemUndoFailed)),
              );
            }),
          );
        },
      ),
    );
  }

  Future<void> _otherPerson(Item item) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final choice = await askPerson(
      context,
      ref,
      title: l10n.triageWaitingOn,
      namedWords: personWordsIn(item.rawText, ref, l10n),
    );
    final id = choice?.id;
    if (id == null || !mounted) return;
    try {
      await ref.read(itemRepositoryProvider).setWaitingOn(item.id, id);
    } catch (_) {
      showMessage(messenger, SnackBar(content: Text(l10n.itemChangeFailed)));
    }
  }

  /// A key on the selected card (Windows, DD-018 point 8): 1 still waiting
  /// or keep, 2 archive and 3 later (step 4, point 17).
  void _keyOnSelected(int digit) {
    final step = _step;
    final id = ref.read(selectedItemProvider);
    if (step == null || id == null || _handled.containsKey(id)) return;
    final item = _byId(id);
    if (item == null) return;
    // As Delete and Ctrl+Enter do: the next open card is selected.
    final open = [
      for (final i in _snapshot[step] ?? const <Item>[])
        if (!_handled.containsKey(i.id)) i.id,
    ];
    final at = open.indexOf(id);
    final neighbour = at < 0 || open.length == 1
        ? null
        : at + 1 < open.length
        ? open[at + 1]
        : open[at - 1];
    void selectNeighbour() =>
        ref.read(selectedItemProvider.notifier).state = neighbour;
    switch ((step, digit)) {
      case (ReviewStep.waiting, 1):
        selectNeighbour();
        unawaited(_reviewed(item, _Handled.waiting));
      case (ReviewStep.stale, 1):
        selectNeighbour();
        unawaited(_reviewed(item, _Handled.kept));
      case (ReviewStep.stale, 2):
        selectNeighbour();
        unawaited(_archive(item));
      case (ReviewStep.stale, 3):
        // The sheet first; the selection moves on once a date is chosen.
        unawaited(
          _later(item).then((_) {
            if (_handled[item.id] == _Handled.parked) selectNeighbour();
          }),
        );
      default:
        break;
    }
  }

  Item? _byId(String id) {
    for (final item in _live) {
      if (item.id == id) return item;
    }
    for (final list in _snapshot.values) {
      for (final item in list) {
        if (item.id == id) return item;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Watched, so counts and cards follow every change.
    ref.watch(liveItemsProvider);
    ref.watch(repeatsProvider);
    ref.watch(inboxProvider);
    ref.watch(staleAfterProvider);
    ref.watch(minuteClockProvider);
    final step = _step;
    final title = switch (step) {
      null => l10n.reviewTitle,
      ReviewStep.insights => l10n.reviewStepInsights,
      ReviewStep.inbox => l10n.reviewStepInbox,
      ReviewStep.waiting => l10n.reviewStepWaiting,
      ReviewStep.deadlines => l10n.reviewStepDeadlines,
      ReviewStep.stale => l10n.reviewStepStale,
    };
    final Widget body = _ended
        ? _end(context)
        : step == null
        ? _start(context)
        : _stepBody(context, step);
    return HelpScope(
      topic: HelpTopic.weeklyReview,
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): _close,
          if (step != null) ...{
            const SingleActivator(LogicalKeyboardKey.arrowRight): _next,
            const SingleActivator(LogicalKeyboardKey.arrowLeft): _previous,
            const SingleActivator(LogicalKeyboardKey.digit1): () =>
                _keyOnSelected(1),
            const SingleActivator(LogicalKeyboardKey.numpad1): () =>
                _keyOnSelected(1),
            const SingleActivator(LogicalKeyboardKey.digit2): () =>
                _keyOnSelected(2),
            const SingleActivator(LogicalKeyboardKey.numpad2): () =>
                _keyOnSelected(2),
            const SingleActivator(LogicalKeyboardKey.digit3): () =>
                _keyOnSelected(3),
            const SingleActivator(LogicalKeyboardKey.numpad3): () =>
                _keyOnSelected(3),
          },
        },
        // The review holds the focus, so Esc and the arrows work also where
        // no list has it (the start and end screens).
        child: Focus(
          autofocus: true,
          child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close),
                tooltip: l10n.reviewClose,
                onPressed: _close,
              ),
              title: Text(title),
              actions: [
                if (step != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Center(
                      child: Text(
                        l10n.reviewStepOf(
                          step.index + 1,
                          ReviewStep.values.length,
                        ),
                      ),
                    ),
                  ),
                const HelpButton(),
              ],
              bottom: step == null
                  ? null
                  : PreferredSize(
                      preferredSize: const Size.fromHeight(8),
                      child: _Progress(step: step),
                    ),
            ),
            body: body,
            bottomNavigationBar: step == null
                ? null
                : SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: Row(
                        children: [
                          OutlinedButton(
                            onPressed: _previous,
                            child: Text(l10n.reviewPrevious),
                          ),
                          const Spacer(),
                          FilledButton(
                            onPressed: _next,
                            child: Text(switch (step) {
                              ReviewStep.insights => l10n.reviewContinue,
                              ReviewStep.stale => l10n.reviewFinish,
                              _ => l10n.reviewNext,
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _start(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final live = _live;
    final deadlines = deadlinesForReview(live, LocalDate.of(_now));
    final weeks = ref.read(staleAfterProvider);
    String summary(ReviewStep step, int work) {
      // The Overview always has its summary, never "nothing to do".
      if (work == 0 && step != ReviewStep.insights) return l10n.reviewNothing;
      return switch (step) {
        ReviewStep.insights => l10n.reviewInsightsSummary,
        ReviewStep.inbox => l10n.reviewInboxCount(work),
        ReviewStep.waiting => l10n.reviewWaitingCount(work),
        ReviewStep.deadlines => l10n.reviewDeadlinesCount(
          deadlines.overdue.length,
          deadlines.upcoming.length,
        ),
        ReviewStep.stale => l10n.reviewStaleCount(work, weeks),
      };
    }

    String name(ReviewStep step) => switch (step) {
      ReviewStep.insights => l10n.reviewStepInsights,
      ReviewStep.inbox => l10n.reviewStepInbox,
      ReviewStep.waiting => l10n.reviewStepWaiting,
      ReviewStep.deadlines => l10n.reviewStepDeadlines,
      ReviewStep.stale => l10n.reviewStepStale,
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final step in ReviewStep.values)
          Card(
            child: ListTile(
              leading: CircleAvatar(
                radius: 14,
                child: Text(
                  '${step.index + 1}', // l10n-ignore: a number
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              title: Text(name(step), style: theme.textTheme.titleSmall),
              subtitle: Text(summary(step, _workIn(step))),
            ),
          ),
        const SizedBox(height: 16),
        FilledButton(onPressed: _next, child: Text(l10n.reviewStart)),
      ],
    );
  }

  Widget _end(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    int count(Iterable<_Handled> kinds) =>
        _handled.values.where(kinds.contains).length;
    final kept = count([_Handled.kept]);
    final waiting = count([_Handled.waiting]);
    final done = count([_Handled.done]);
    final archived = count([_Handled.archived]);
    final trashed = count([_Handled.trashed]);
    final parked = count([_Handled.parked]);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.reviewEndTitle, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 12),
            if (_handled.isEmpty) Text(l10n.reviewEndNothing),
            if (waiting > 0) Text(l10n.reviewEndWaiting(waiting)),
            if (kept > 0) Text(l10n.reviewEndKept(kept)),
            if (done > 0) Text(l10n.reviewEndDone(done)),
            if (archived > 0) Text(l10n.reviewEndArchived(archived)),
            if (trashed > 0) Text(l10n.reviewEndTrashed(trashed)),
            if (parked > 0) Text(l10n.reviewEndParked(parked)),
            const SizedBox(height: 20),
            FilledButton(onPressed: _toToday, child: Text(l10n.reviewEndBack)),
          ],
        ),
      ),
    );
  }

  Widget _stepBody(BuildContext context, ReviewStep step) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final now = _now;
    final tokens = ref.watch(liveItemTokensProvider).valueOrNull ?? const {};
    final liveById = {for (final item in _live) item.id: item};
    final header = theme.textTheme.labelMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      letterSpacing: 0.6,
    );

    Widget card(Item item) => KeyedSubtree(
      key: ListKeys.cardKey(item.id, scope: _cardScope),
      child: InboxCard(
        item: item,
        tokens: tokens[item.id] ?? const [],
        now: now,
        showStatus: true,
        showInboxStatus: true,
      ),
    );

    switch (step) {
      case ReviewStep.insights:
        // Wide on Windows with two panes: the review takes both then.
        return InsightsView(
          inReview: true,
          wide:
              isDesktop(context) &&
              MediaQuery.sizeOf(context).width >= twoPaneMinWidth,
        );
      case ReviewStep.inbox:
        final inbox = ref.watch(inboxProvider).valueOrNull ?? const <Item>[];
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: inbox.isEmpty
                ? Text(
                    l10n.reviewInboxEmpty,
                    style: theme.textTheme.titleMedium,
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.reviewInboxCount(inbox.length),
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        icon: const Icon(Icons.style_outlined),
                        label: Text(l10n.reviewProcess),
                        onPressed: () => TriageScreen.open(context, [
                          for (final item in inbox) item.id,
                        ], fromToday: true),
                      ),
                    ],
                  ),
          ),
        );

      case ReviewStep.deadlines:
        final d = deadlinesForReview(_live, LocalDate.of(now));
        Widget dated(Item item) => Dismissible(
          key: ValueKey((#review, item.id)),
          direction: isDesktop(context)
              ? DismissDirection.none
              : DismissDirection.horizontal,
          background: SwipeToComplete(label: l10n.itemComplete),
          secondaryBackground: SwipeToTrash(label: l10n.itemMoveToTrash),
          onDismissed: (direction) => direction == DismissDirection.startToEnd
              ? _complete(item)
              : _trash(item),
          child: card(item),
        );
        final ids = [
          for (final item in [...d.overdue, ...d.upcoming]) item.id,
        ];
        return ListKeys(
          scope: _cardScope,
          focusNode: _listFocus,
          ids: ids,
          onTrash: (id) => liveById[id] == null ? null : _trash(liveById[id]!),
          onComplete: (id) =>
              liveById[id] == null ? null : _complete(liveById[id]!),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              if (d.overdue.isNotEmpty)
                _Header(
                  text: l10n.reviewOverdue(d.overdue.length).toUpperCase(),
                  style: header?.copyWith(color: attentionTextColor),
                ),
              for (final item in d.overdue) dated(item),
              if (d.upcoming.isNotEmpty)
                _Header(
                  text: l10n.reviewUpcoming(d.upcoming.length).toUpperCase(),
                  style: header,
                ),
              for (final item in d.upcoming) dated(item),
            ],
          ),
        );

      case ReviewStep.waiting || ReviewStep.stale:
        final items = [
          for (final item in _snapshot[step] ?? const <Item>[])
            liveById[item.id] ?? item,
        ];
        final open = [
          for (final item in items)
            if (!_handled.containsKey(item.id)) item.id,
        ];
        final weeks = ref.read(staleAfterProvider);
        return ListKeys(
          scope: _cardScope,
          focusNode: _listFocus,
          ids: open,
          onTrash: (id) => liveById[id] == null ? null : _trash(liveById[id]!),
          onComplete: step == ReviewStep.waiting
              ? (id) => liveById[id] == null ? null : _complete(liveById[id]!)
              : null,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              if (step == ReviewStep.stale)
                _Header(
                  text: l10n
                      .reviewStaleHeader(weeks, items.length)
                      .toUpperCase(),
                  style: header,
                ),
              for (final item in items)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Opacity(
                      opacity: _handled.containsKey(item.id) ? 0.55 : 1,
                      child: card(item),
                    ),
                    _Actions(
                      item: item,
                      step: step,
                      handled: _handled[item.id],
                      parkedOn: _parkedOn[item.id],
                      now: now,
                      onStillWaiting: () => _reviewed(item, _Handled.waiting),
                      onKeep: () => _reviewed(item, _Handled.kept),
                      onComplete: () => _complete(item),
                      onArchive: () => _archive(item),
                      onTrash: () => _trash(item),
                      onLater: () => _later(item),
                      onOtherPerson: () => _otherPerson(item),
                    ),
                  ],
                ),
            ],
          ),
        );
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.text, required this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Semantics(header: true, child: Text(text, style: style)),
  );
}

/// Four segments, filled up to the step on screen.
class _Progress extends StatelessWidget {
  const _Progress({required this.step});

  final ReviewStep step;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
        child: Row(
          children: [
            for (final s in ReviewStep.values) ...[
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: s.index <= step.index
                        ? colors.primary
                        : colors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (s != ReviewStep.values.last) const SizedBox(width: 4),
            ],
          ],
        ),
      ),
    );
  }
}

/// The choices under a card in steps 2 and 4, or what was done with it;
/// and how long it was not touched (AC REQ-051).
class _Actions extends StatelessWidget {
  const _Actions({
    required this.item,
    required this.step,
    required this.handled,
    required this.parkedOn,
    required this.now,
    required this.onStillWaiting,
    required this.onKeep,
    required this.onComplete,
    required this.onArchive,
    required this.onTrash,
    required this.onLater,
    required this.onOtherPerson,
  });

  final Item item;
  final ReviewStep step;
  final _Handled? handled;
  final LocalDate? parkedOn;
  final DateTime now;
  final VoidCallback onStillWaiting;
  final VoidCallback onKeep;
  final VoidCallback onComplete;
  final VoidCallback onArchive;
  final VoidCallback onTrash;
  final VoidCallback onLater;
  final VoidCallback onOtherPerson;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final touched = item.lastTouch;
    final days = touched == null
        ? null
        : now.toUtc().difference(touched).inDays;
    final age = days == null
        ? null
        : days < 14
        ? l10n.reviewAgeDays(days)
        : l10n.reviewAgeWeeks(days ~/ 7);
    final old = days != null && days >= 42;
    final done = switch (handled) {
      null => null,
      _Handled.waiting => l10n.reviewHandledWaiting,
      _Handled.kept => l10n.reviewHandledKept,
      _Handled.done => l10n.reviewHandledDone,
      _Handled.archived => l10n.reviewHandledArchived,
      _Handled.trashed => l10n.reviewHandledTrashed,
      _Handled.parked => l10n.reviewHandledParked(
        (parkedOn ?? LocalDate.of(now)).toLocalDateTime(),
      ),
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 16, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (age != null)
            Text(
              age,
              style: theme.textTheme.bodySmall?.copyWith(
                color: old ? attentionTextColor : null,
                fontWeight: old ? FontWeight.w600 : null,
              ),
            ),
          if (done != null)
            Text(done, style: theme.textTheme.labelLarge)
          else if (step == ReviewStep.waiting) ...[
            OutlinedButton(
              onPressed: onStillWaiting,
              child: Text(l10n.reviewStillWaiting),
            ),
            OutlinedButton(
              onPressed: onComplete,
              child: Text(l10n.itemComplete),
            ),
            IconButton(
              icon: const Icon(Icons.person_search_outlined),
              tooltip: l10n.personChange,
              onPressed: onOtherPerson,
            ),
          ] else ...[
            OutlinedButton(onPressed: onKeep, child: Text(l10n.reviewKeep)),
            OutlinedButton(
              onPressed: onArchive,
              child: Text(l10n.reviewArchive),
            ),
            // Parks it until a date (DD-018 point 17).
            OutlinedButton.icon(
              onPressed: onLater,
              icon: const Icon(Icons.update),
              label: Text(l10n.revisitLater),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: l10n.itemMoveToTrash,
              onPressed: onTrash,
            ),
          ],
        ],
      ),
    );
  }
}
