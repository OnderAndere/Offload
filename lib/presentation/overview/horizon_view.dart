import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/items/item_headline.dart';
import '../../domain/overview/horizon.dart';
import '../../domain/time/local_date.dart';
import '../../l10n/app_localizations.dart';
import '../inbox/inbox_card.dart';
import '../items/item_detail_screen.dart';
import '../people/people_providers.dart';
import '../projects/project_providers.dart';
import '../theme/offload_colors.dart';
import '../theme/typography.dart';
import '../tokens/token_display.dart';
import '../tokens/token_editor.dart';
import 'list_arrows.dart';
import 'overview_providers.dart';

/// The Horizon of the Overview (T10.7 step B, REQ-052, DD-018 point 12
/// (a) and (b)): six weeks from today, a lane per top-level project, a
/// mark per deadline or expected day, a busy bar per week; under it the
/// list of the chosen week. A tap on a week chooses it; on Windows ←/→ do
/// too while the timeline has the focus.
class HorizonView extends ConsumerStatefulWidget {
  const HorizonView({super.key, this.padding = const EdgeInsets.all(12)});

  final EdgeInsetsGeometry padding;

  @override
  ConsumerState<HorizonView> createState() => _HorizonViewState();
}

class _HorizonViewState extends ConsumerState<HorizonView> {
  /// The chosen week: this week until another is chosen.
  int _week = 0;

  final _focus = FocusNode();
  bool _focused = false;

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final step = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowLeft => -1,
      LogicalKeyboardKey.arrowRight => 1,
      _ => 0,
    };
    if (step == 0) return KeyEventResult.ignored;
    setState(() => _week = (_week + step).clamp(0, horizonWeekCount - 1));
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final horizon = ref.watch(horizonProvider);
    final week = horizon.weeks[_week.clamp(0, horizon.weeks.length - 1)];
    Widget timeline = _Timeline(
      horizon: horizon,
      selected: _week,
      focused: _focused,
      onSelect: (index) {
        setState(() => _week = index);
        // A click on a week: the arrows go on from there (Windows).
        if (isDesktop(context)) _focus.requestFocus();
      },
    );
    if (isDesktop(context)) {
      timeline = Focus(
        focusNode: _focus,
        onKeyEvent: _onKey,
        onFocusChange: (focused) => setState(() => _focused = focused),
        child: timeline,
      );
    }
    return ListView(
      padding: widget.padding,
      children: [
        timeline,
        const SizedBox(height: 12),
        _WeekList(week: week),
      ],
    );
  }
}

/// The card with the timeline: week headers, lanes, legend.
class _Timeline extends ConsumerWidget {
  const _Timeline({
    required this.horizon,
    required this.selected,
    required this.focused,
    required this.onSelect,
  });

  final Horizon horizon;
  final int selected;
  final bool focused;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final tree = ref.watch(projectTreeProvider);
    final weeks = horizon.weeks;
    final most = weeks.fold(1, (m, w) => w.toDeliver > m ? w.toDeliver : m);
    const mono = TextStyle(fontFamily: monoFamily, fontSize: 12);

    Widget week(int index) {
      final w = weeks[index];
      final color = w.busy ? context.offloadColors.attentionText : null;
      return Expanded(
        child: Semantics(
          button: true,
          selected: index == selected,
          excludeSemantics: true,
          label: l10n.horizonWeekSemantics(
            w.number,
            w.start.toLocalDateTime(),
            w.end.toLocalDateTime(),
            w.toDeliver,
            '${w.busy}', // l10n-ignore: select value true/false
            w.waiting,
          ),
          child: InkWell(
            onTap: () => onSelect(index),
            child: Container(
              color: index == selected ? context.offloadColors.calmChip : null,
              padding: const EdgeInsets.only(top: 4, bottom: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${w.toDeliver}', // l10n-ignore: a number
                    style: mono.copyWith(
                      fontSize: 10,
                      color: color ?? muted,
                      fontWeight: w.busy ? FontWeight.w600 : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    width: 14,
                    height: 2 + 38 * w.toDeliver / most,
                    decoration: BoxDecoration(
                      color: w.busy
                          ? context.offloadColors.attention
                          : context.offloadColors.calm.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${w.number}', // l10n-ignore: a week number
                    style: mono.copyWith(
                      color: color,
                      fontWeight: w.busy ? FontWeight.w600 : null,
                    ),
                  ),
                  Text(
                    l10n.horizonDay(w.start.toLocalDateTime()),
                    style: mono.copyWith(fontSize: 10, color: muted),
                  ),
                  Text(
                    w.busy ? l10n.horizonBusy : '',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: context.offloadColors.attentionText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    Widget lane(String? id, double labelWidth) {
      final name = id == null ? l10n.horizonNoProject : tree[id]?.name ?? '';
      return DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: theme.dividerColor)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: labelWidth,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  name,
                  // Two lines, so "Geen project" fits a narrow pane.
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: id == null ? muted : null,
                    fontWeight: id == null ? FontWeight.w400 : null,
                  ),
                ),
              ),
            ),
            // A cell chooses its week too (the column, DD-018 point 12
            // (b)); the week header carries the semantics.
            for (var i = 0; i < weeks.length; i++)
              Expanded(
                child: ExcludeSemantics(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onSelect(i),
                    child: _CellTitles(
                      entries: weeks[i].inLane(id).toList(),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 42),
                        color: i == selected
                            ? context.offloadColors.calmChip
                            : null,
                        alignment: Alignment.center,
                        child: _Marks([
                          for (final e in weeks[i].inLane(id)) e.mark,
                        ]),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: focused ? context.offloadColors.calm : theme.dividerColor,
          width: focused ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final labelWidth = constraints.maxWidth >= 560 ? 120.0 : 92.0;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: Text(
                        l10n.horizonTitle(horizonWeekCount),
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    Text(
                      l10n.horizonSummary(
                        horizon.lanes.length,
                        horizon.itemCount,
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: labelWidth,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 22),
                        child: Text(
                          l10n.horizonWeekColumn,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: muted,
                          ),
                        ),
                      ),
                    ),
                    for (var i = 0; i < weeks.length; i++) week(i),
                  ],
                ),
                if (horizon.lanes.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      l10n.horizonEmpty(horizonWeekCount),
                      style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                    ),
                  )
                else
                  for (final id in horizon.lanes) lane(id, labelWidth),
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: theme.dividerColor)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      spacing: 14,
                      runSpacing: 4,
                      children: [
                        for (final (mark, text) in [
                          (HorizonMark.deliver, l10n.horizonLegendDeliver),
                          (HorizonMark.waiting, l10n.horizonLegendWaiting),
                          (HorizonMark.overdue, l10n.horizonLegendOverdue),
                          (HorizonMark.late, l10n.horizonLegendLate),
                        ])
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _Mark(mark),
                              const SizedBox(width: 4),
                              Text(
                                text,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: muted,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// On Windows the mouse pointer on a cell shows the titles of its items
/// (hover instead of a long press, DD-018 point 12 (f)).
class _CellTitles extends ConsumerWidget {
  const _CellTitles({required this.entries, required this.child});

  final List<HorizonEntry> entries;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (entries.isEmpty || !isDesktop(context)) return child;
    final l10n = AppLocalizations.of(context);
    final registry = ref.watch(inlineTokenRegistryProvider);
    final now = ref.watch(minuteClockProvider).valueOrNull ?? DateTime.now();
    final parseContext = parseContextOf(l10n, LocalDate.of(now));
    return Tooltip(
      message: {
        for (final e in entries)
          itemHeadline(e.item.rawText, registry, parseContext).title,
      }.join('\n'), // l10n-ignore: a line break between titles
      child: child,
    );
  }
}

/// The marks in one cell: at most four, then "+n".
class _Marks extends StatelessWidget {
  const _Marks(this.marks);

  final List<HorizonMark> marks;

  static const _shown = 4;

  @override
  Widget build(BuildContext context) {
    if (marks.isEmpty) return const SizedBox.shrink();
    final extra = marks.length - _shown;
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 3,
      runSpacing: 3,
      children: [
        for (final mark in marks.take(_shown)) _Mark(mark),
        if (extra > 0)
          Text(
            '+$extra', // l10n-ignore: a number
            style: const TextStyle(fontFamily: monoFamily, fontSize: 10),
          ),
      ],
    );
  }
}

/// One mark: a dot (I deliver) or a ring (I wait), orange when it needs
/// attention now, blue when calm (DD-017).
class _Mark extends StatelessWidget {
  const _Mark(this.mark);

  final HorizonMark mark;

  @override
  Widget build(BuildContext context) {
    final color = switch (mark) {
      HorizonMark.overdue ||
      HorizonMark.late => context.offloadColors.attention,
      HorizonMark.deliver || HorizonMark.waiting => context.offloadColors.calm,
    };
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: mark.delivers ? color : null,
        border: mark.delivers ? null : Border.all(color: color, width: 2),
      ),
    );
  }
}

/// The list of one week (DD-018 point 12 (b)).
class _WeekList extends ConsumerWidget {
  const _WeekList({required this.week});

  final HorizonWeek week;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final registry = ref.watch(inlineTokenRegistryProvider);
    final people = ref.watch(peopleByIdProvider);
    final tree = ref.watch(projectTreeProvider);
    // The clock of the Horizon itself, so both agree around midnight.
    final now = ref.watch(minuteClockProvider).valueOrNull ?? DateTime.now();
    final parseContext = parseContextOf(l10n, LocalDate.of(now));
    final first = week.start != week.end.addDays(-6);
    final title = first
        ? l10n.horizonWeekFrom(week.number, week.start.toLocalDateTime())
        : l10n.horizonWeekRange(
            week.number,
            week.start.toLocalDateTime(),
            week.end.toLocalDateTime(),
          );

    String dateText(HorizonEntry e) {
      final day = e.day.toLocalDateTime();
      final waitingOn = e.item.waitingOnId == null
          ? null
          : people[e.item.waitingOnId]?.name;
      return switch (e.mark) {
        HorizonMark.deliver => l10n.horizonEntryDue(day),
        HorizonMark.overdue => l10n.horizonEntryOverdue(day),
        HorizonMark.late => l10n.horizonEntryLate(day),
        HorizonMark.waiting =>
          waitingOn == null
              ? l10n.horizonEntryWaitingNobody(day)
              : l10n.horizonEntryWaiting(waitingOn, day),
      };
    }

    // One row per item (PO 02-10-2026): a deadline and an expected day in
    // the same week share a line.
    final rows = <List<HorizonEntry>>[];
    final rowOf = <String, List<HorizonEntry>>{};
    for (final e in week.entries) {
      final row = rowOf[e.item.id];
      if (row != null) {
        row.add(e);
      } else {
        rows.add(rowOf[e.item.id] = [e]);
      }
    }

    String line(List<HorizonEntry> row) {
      var text = dateText(row.first);
      for (final e in row.skip(1)) {
        text = l10n.horizonEntryMore(text, dateText(e));
      }
      final item = row.first.item;
      final project = item.projectId == null
          ? null
          : tree[item.projectId!]?.name;
      if (project != null) text = l10n.horizonEntryMore(text, project);
      final requester = item.requesterId == null
          ? null
          : people[item.requesterId]?.name;
      if (requester != null) {
        text = l10n.horizonEntryMore(text, l10n.horizonEntryFor(requester));
      }
      return text;
    }

    final count = week.toDeliver;
    return ListArrows(
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.dividerColor),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(title, style: theme.textTheme.titleSmall),
                    ),
                  ),
                  if (count > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: week.busy
                            ? context.offloadColors.attentionChip
                            : context.offloadColors.calmChip,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        week.busy
                            ? l10n.horizonToDeliverBusy(count)
                            : l10n.horizonToDeliver(count),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: week.busy
                              ? context.offloadColors.attentionText
                              : context.offloadColors.calm,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              if (week.entries.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    l10n.horizonWeekEmpty,
                    style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                  ),
                ),
              for (final row in rows)
                InkWell(
                  onTap: () =>
                      ItemDetailScreen.open(context, row.first.item.id),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 2,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 5, right: 10),
                          // What I deliver first: the deadline is mine.
                          child: _Mark(
                            row
                                .firstWhere(
                                  (e) => e.mark.delivers,
                                  orElse: () => row.first,
                                )
                                .mark,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                itemHeadline(
                                  row.first.item.rawText,
                                  registry,
                                  parseContext,
                                ).title,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                line(row),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: row.every((e) => e.mark.isCalm)
                                      ? muted
                                      : context.offloadColors.attentionText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

extension on HorizonMark {
  /// Blue: nothing needs attention now.
  bool get isCalm => this == HorizonMark.deliver || this == HorizonMark.waiting;
}
