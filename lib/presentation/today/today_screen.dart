import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/help/help_topics.dart';
import '../../domain/items/item.dart';
import '../../domain/items/nudge.dart';
import '../../domain/items/revisit.dart';
import '../../domain/items/today.dart';
import '../../domain/people/person.dart';
import '../../domain/reminders/birthday_reminders.dart';
import '../../domain/review/weekly_review.dart';
import '../../domain/time/local_date.dart';
import '../../l10n/app_localizations.dart';
import '../help/help_scope.dart';
import '../home/destination.dart';
import '../home/destination_actions.dart';
import '../home/list_keys.dart';
import '../inbox/inbox_card.dart';
import '../items/chase.dart';
import '../items/complete_undo.dart';
import '../items/item_providers.dart';
import '../items/swipe_backgrounds.dart';
import '../items/trash_undo.dart';
import '../people/people_providers.dart';
import '../people/person_actions.dart';
import '../projects/project_providers.dart';
import '../reminders/reminder_providers.dart';
import '../review/review_providers.dart';
import '../review/weekly_review_screen.dart';
import '../theme/offload_colors.dart';
import '../tokens/token_editor.dart';
import '../triage/triage_screen.dart';
import 'today_notes.dart';

/// The open items due on a day or earlier (DD-018 point 4); a new day
/// gives a new query, so Today moves along at midnight.
final dueItemsProvider = StreamProvider.autoDispose
    .family<List<Item>, LocalDate>(
      (ref, day) => ref.watch(itemRepositoryProvider).watchDueThrough(day),
    );

/// The waiting items late on a day (T10.1, DD-018 point 10 (e)).
final lateWaitingProvider = StreamProvider.autoDispose
    .family<List<Item>, LocalDate>(
      (ref, day) => ref.watch(itemRepositoryProvider).watchLateWaiting(day),
    );

/// Today, the start screen (T2.6, DD-011, DD-018 point 4): a line for the
/// inbox, then what is overdue and what is due today, oldest deadline
/// first. Swiping right completes, left sends to the trash, both with
/// undo; screen readers get both as actions.
class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  /// The last list shown: at midnight the new day's query starts empty,
  /// and the old list stays until it answers, instead of a spinner.
  List<Item>? _shown;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final now = ref.watch(minuteClockProvider).valueOrNull ?? DateTime.now();
    final today = LocalDate.of(now);
    final due = ref.watch(dueItemsProvider(today));
    final items = due.valueOrNull ?? (due.isLoading ? _shown : null);
    // Remembered while building, on purpose: the next build, for the new
    // day, falls back to it until its own query answers.
    if (due.hasValue) _shown = due.value;
    final theme = Theme.of(context);
    final date = l10n.todayDate(now);
    final dateStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final actions = [
      ...destinationActions(context),
      // The entry to the weekly review (DD-018 point 8); on Windows the
      // tooltip teaches its key.
      IconButton(
        icon: const Icon(Icons.fact_check_outlined),
        tooltip: isDesktop(context)
            ? l10n.reviewStartTooltipWithKey
            : l10n.reviewTitle,
        onPressed: () => WeeklyReviewScreen.open(context, ref),
      ),
      const HelpButton(),
    ];
    final body = items != null
        ? _TodayList(items: items, today: today, now: now)
        : due.hasError
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(l10n.todayLoadFailed, textAlign: TextAlign.center),
            ),
          )
        : const Center(child: CircularProgressIndicator());
    return HelpScope(
      topic: HelpTopic.today,
      // The date stays in the title bar when it fits there with the title
      // and the buttons; on a narrow screen or with large text it moves to
      // the top of the page, so the title is never cut (REQ-016, T8.14).
      child: LayoutBuilder(
        builder: (context, constraints) {
          final inBar = _dateFitsInBar(
            context,
            width: constraints.maxWidth,
            title: l10n.navToday,
            date: date,
            dateStyle: dateStyle,
            buttons: actions.length,
          );
          return Scaffold(
            appBar: AppBar(
              title: Text(l10n.navToday),
              actions: [
                if (inBar) ...[
                  Center(child: Text(date, style: dateStyle)),
                  const SizedBox(width: 8),
                ],
                ...actions,
              ],
            ),
            body: inBar
                ? body
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                        child: Text(date, style: dateStyle),
                      ),
                      Expanded(child: body),
                    ],
                  ),
          );
        },
      ),
    );
  }
}

/// Whether [date] fits in the title bar next to [title] and [buttons]
/// icon buttons, in a bar [width] wide, at the current text size.
bool _dateFitsInBar(
  BuildContext context, {
  required double width,
  required String title,
  required String date,
  required TextStyle? dateStyle,
  required int buttons,
}) {
  final scaler = MediaQuery.textScalerOf(context);
  final direction = Directionality.of(context);
  double measure(String text, TextStyle? style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: direction,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    final w = painter.width;
    painter.dispose();
    return w;
  }

  final theme = Theme.of(context);
  final titleStyle =
      theme.appBarTheme.titleTextStyle ?? theme.textTheme.titleLarge;
  // The Material 3 AppBar defaults: the title starts 16 in and keeps 16
  // from the actions (no leading widget on Today), each icon button is 48
  // wide; plus the 8 after the date. Checked on the emulator at 1x, 1.5x
  // and 2x text (T8.14).
  final needed =
      16 + measure(title, titleStyle) + 16 + measure(date, dateStyle) + 8;
  return needed + buttons * 48 <= width;
}

class _TodayList extends ConsumerStatefulWidget {
  const _TodayList({
    required this.items,
    required this.today,
    required this.now,
  });

  final List<Item> items;
  final LocalDate today;
  final DateTime now;

  @override
  ConsumerState<_TodayList> createState() => _TodayListState();
}

class _TodayListState extends ConsumerState<_TodayList> {
  /// Cards swiped away that the list has not caught up with yet: a
  /// dismissed card may not come back for a frame.
  final _gone = <String>{};

  @override
  void didUpdateWidget(_TodayList oldWidget) {
    super.didUpdateWidget(oldWidget);
    final ids = {
      for (final item in widget.items) item.id,
      // The late group comes from a stream of its own, which may answer
      // later than the due one (review T10.1).
      for (final item
          in ref.read(lateWaitingProvider(widget.today)).valueOrNull ??
              const <Item>[])
        item.id,
      // And the waiting items that can go silent (T10.1).
      for (final item
          in ref.read(liveItemsProvider).valueOrNull ?? const <Item>[])
        if (canGoSilent(item)) item.id,
      // So is the inbox, for the items back from "revisit on".
      for (final item in ref.read(inboxProvider).valueOrNull ?? const <Item>[])
        item.id,
    };
    _gone.retainWhere(ids.contains);
  }

  Future<void> _complete(Item item) async {
    // Already under way: the card is gone already, nothing to do.
    if (isCompleting(item.id)) return;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    setState(() => _gone.add(item.id));
    final done = await completeWithUndo(
      messenger: messenger,
      l10n: l10n,
      items: ref.read(itemRepositoryProvider),
      item: item,
      onUndo: () {
        if (mounted) setState(() => _gone.remove(item.id));
      },
    );
    if (!done && mounted) setState(() => _gone.remove(item.id));
  }

  Future<void> _trash(Item item) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    setState(() => _gone.add(item.id));
    final trashed = await trashWithUndo(
      messenger: messenger,
      l10n: l10n,
      items: ref.read(itemRepositoryProvider),
      id: item.id,
      onUndo: () {
        if (mounted) setState(() => _gone.remove(item.id));
      },
    );
    if (!trashed && mounted) setState(() => _gone.remove(item.id));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sections = todaySections([
      for (final item in widget.items)
        if (!_gone.contains(item.id)) item,
    ], widget.today);
    final tokens = ref.watch(liveItemTokensProvider).valueOrNull ?? const {};
    final swipe = !isDesktop(context);
    // Waiting items past their expected day, once only: one already due
    // above stays there (DD-018 point 10 (e)).
    final dueIds = {for (final item in widget.items) item.id};
    final late = [
      for (final item
          in ref.watch(lateWaitingProvider(widget.today)).valueOrNull ??
              const <Item>[])
        if (!dueIds.contains(item.id) && !_gone.contains(item.id)) item,
    ];
    // Back from "revisit on" and still in the inbox, once only: one with a
    // deadline stays above (DD-018 point 17).
    final back = [
      for (final item in backInInbox(
        ref.watch(inboxProvider).valueOrNull ?? const <Item>[],
        widget.today,
      ))
        if (!dueIds.contains(item.id) && !_gone.contains(item.id)) item,
    ];
    // Waiting items without a touch for X days and without an expected
    // date (T10.1); one shown above stays there.
    final above = {
      ...dueIds,
      for (final item in late) item.id,
      for (final item in back) item.id,
    };
    final silent = [
      for (final item in silentItems(
        ref.watch(liveItemsProvider).valueOrNull ?? const <Item>[],
        widget.today,
        ref.watch(nudgeAfterProvider),
      ))
        if (!above.contains(item.id) && !_gone.contains(item.id)) item,
    ];

    Widget card(Item item) {
      final child = KeyedSubtree(
        key: ListKeys.cardKey(item.id),
        child: Semantics(
          customSemanticsActions: {
            CustomSemanticsAction(label: l10n.itemComplete): () =>
                _complete(item),
            CustomSemanticsAction(label: l10n.itemMoveToTrash): () =>
                _trash(item),
          },
          child: InboxCard(
            item: item,
            tokens: tokens[item.id] ?? const [],
            now: widget.now,
            showStatus: true,
            showInboxStatus: true,
            showAge: false,
          ),
        ),
      );
      if (!swipe) return child;
      return Dismissible(
        key: ValueKey(item.id),
        background: SwipeToComplete(label: l10n.itemComplete),
        secondaryBackground: SwipeToTrash(label: l10n.itemMoveToTrash),
        onDismissed: (direction) => direction == DismissDirection.startToEnd
            ? _complete(item)
            : _trash(item),
        child: child,
      );
    }

    final empty =
        sections.overdue.isEmpty &&
        sections.today.isEmpty &&
        back.isEmpty &&
        late.isEmpty &&
        silent.isEmpty;
    final shown = [
      ...sections.overdue,
      ...sections.today,
      ...back,
      ...late,
      ...silent,
    ];
    Item byId(String id) => shown.firstWhere((item) => item.id == id);
    return ListKeys(
      ids: [for (final item in shown) item.id],
      onTrash: (id) => _trash(byId(id)),
      // Completing from the list only on Today (PO decision 29-09-2026).
      onComplete: (id) => _complete(byId(id)),
      child: ListView(
        // Room at the bottom so the capture button never hides the last item.
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          const _InboxLine(),
          _ReviewLine(today: widget.today),
          _BirthdayLines(today: widget.today),
          // The open "Where was I" notes (T4b.2); not deadlines, so the
          // empty message still shows below them.
          TodayNotes(today: widget.today, now: widget.now),
          if (empty) const _NothingForToday(),
          if (sections.overdue.isNotEmpty) ...[
            _SectionHeader(
              text: l10n.todayOverdue(sections.overdue.length),
              overdue: true,
            ),
            for (final item in sections.overdue) card(item),
          ],
          if (sections.today.isNotEmpty) ...[
            _SectionHeader(
              text: l10n.todayDueToday(sections.today.length),
              overdue: false,
            ),
            for (final item in sections.today) card(item),
          ],
          if (back.isNotEmpty) ...[
            _SectionHeader(
              text: l10n.todayBackSection(back.length),
              overdue: false,
            ),
            for (final item in back) card(item),
          ],
          if (late.isNotEmpty) ...[
            _SectionHeader(
              text: l10n.todayLateSection(late.length),
              overdue: true,
            ),
            for (final item in late) card(item),
          ],
          if (silent.isNotEmpty) ...[
            _SectionHeader(
              text: l10n.todaySilentSection(silent.length),
              overdue: false,
            ),
            for (final item in silent)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  card(item),
                  _SilentActions(
                    item: item,
                    today: widget.today,
                    onReceived: () => _complete(item),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}

/// "5 in je inbox · Verwerken ›" (DD-018 point 4): the line goes to the
/// Inbox, the button starts triage, which comes back here. Hidden when the
/// inbox is empty.
class _InboxLine extends ConsumerWidget {
  const _InboxLine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final inbox = ref.watch(inboxProvider).valueOrNull ?? const <Item>[];
    if (inbox.isEmpty) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      color: colors.secondaryContainer,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () =>
            ref.read(destinationProvider.notifier).state = Destination.inbox,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
          child: Row(
            children: [
              Icon(Icons.inbox_outlined, color: colors.onSecondaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.todayInboxLine(inbox.length),
                  style: TextStyle(
                    color: colors.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton.icon(
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.chevron_right),
                label: Text(l10n.todayProcess),
                onPressed: () => TriageScreen.open(context, [
                  for (final item in inbox) item.id,
                ], fromToday: true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Weekoverzicht · laatste 9 d geleden ›" (DD-018 point 4): only while a
/// weekly review is due; the whole line starts it. Calm, not orange: a
/// review is not overdue work (DD-017).
class _ReviewLine extends ConsumerWidget {
  const _ReviewLine({required this.today});

  final LocalDate today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final last = ref.watch(lastReviewProvider);
    if (!reviewDue(last, today, ref.watch(reviewDueAfterProvider))) {
      return const SizedBox.shrink();
    }
    final days = daysSinceReview(last, today);
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      color: colors.surfaceContainerLow,
      child: Semantics(
        button: true,
        excludeSemantics: true,
        label: days == null
            ? l10n.todayReviewLineNeverLabel
            : l10n.todayReviewLineLabel(days),
        onTap: () => WeeklyReviewScreen.open(context, ref),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => WeeklyReviewScreen.open(context, ref),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            child: Row(
              children: [
                Icon(Icons.fact_check_outlined, color: colors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    days == null
                        ? l10n.todayReviewLineNever
                        : l10n.todayReviewLine(days),
                  ),
                ),
                Icon(Icons.chevron_right, color: colors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Under a silent card (T10.1): how long it has been silent, *Ontvangen*
/// (completes, with undo) and *Nagevraagd* (a touch, no undo).
class _SilentActions extends ConsumerWidget {
  const _SilentActions({
    required this.item,
    required this.today,
    required this.onReceived,
  });

  final Item item;
  final LocalDate today;
  final VoidCallback onReceived;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final days = silentDays(item, today, ref.watch(nudgeAfterProvider));
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 16, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (days != null)
            Text(
              l10n.nudgeSilentDays(days),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          OutlinedButton(
            onPressed: onReceived,
            child: Text(l10n.nudgeReceived),
          ),
          OutlinedButton(
            onPressed: () => unawaited(
              chase(
                messenger: ScaffoldMessenger.of(context),
                l10n: l10n,
                items: ref.read(itemRepositoryProvider),
                item: item,
              ),
            ),
            child: Text(l10n.nudgeChased),
          ),
        ],
      ),
    );
  }
}

/// "Jan Bakker wordt vandaag 46" for each person whose birthday is today
/// (REQ-031, T4.6, decision f); a tap opens the person. Gone the next day.
class _BirthdayLines extends ConsumerWidget {
  const _BirthdayLines({required this.today});

  final LocalDate today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final people = ref.watch(peopleProvider).valueOrNull ?? const <Person>[];
    final born = birthdaysOn(people, today);
    return Column(
      children: [
        for (final person in born)
          Card(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            color: colors.surfaceContainerLow,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => openPerson(context, ref, person.id),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                child: Row(
                  children: [
                    Icon(Icons.cake_outlined, color: colors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(switch (ageTurningOn(
                        person.birthday!,
                        today,
                      )) {
                        final age? => l10n.todayBirthdayAge(person.name, age),
                        null => l10n.todayBirthday(person.name),
                      }),
                    ),
                    Icon(Icons.chevron_right, color: colors.primary),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// "Verlopen · 2" or "Vandaag · 2". Overdue is in a darker orange than the
/// chips, for contrast on the page, with an icon of its own (DD-017).
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.text, required this.overdue});

  final String text;
  final bool overdue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = overdue
        ? context.offloadColors.attentionText
        : theme.colorScheme.onSurfaceVariant;
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Row(
          children: [
            if (overdue) ...[
              Icon(Icons.warning_amber, size: 16, color: color),
              const SizedBox(width: 6),
            ],
            // Long headers ("Had binnen moeten zijn · 2") wrap on a narrow
            // phone instead of running off the screen.
            Flexible(
              child: Text(
                text,
                style: theme.textTheme.titleSmall?.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Nothing due: a positive confirmation, never a blank screen (SPEC §5).
class _NothingForToday extends StatelessWidget {
  const _NothingForToday();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 96, 32, 0),
      child: Column(
        children: [
          Icon(
            Icons.wb_sunny_outlined,
            size: 48,
            color: context.offloadColors.calm,
          ),
          const SizedBox(height: 12),
          Text(l10n.todayEmptyTitle, style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            l10n.todayEmptyText,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
