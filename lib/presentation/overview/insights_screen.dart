import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/help/help_topics.dart';
import '../../domain/time/local_date.dart';
import '../../l10n/app_localizations.dart';
import '../help/help_scope.dart';
import '../home/destination_actions.dart';
import '../inbox/inbox_card.dart';
import '../people/people_screen.dart';
import '../people/person_screen.dart';
import '../theme/typography.dart';
import 'connections_view.dart';
import 'horizon_view.dart';
import 'standstill_view.dart';

/// The segments of the Overview (DD-018 point 12); Connections came with
/// T10.14 (DD-018 point 15).
enum InsightsSegment { horizon, standstill, people, connections }

/// The segment [chosen] as shown: the weekly review has no Connections (it
/// needs a focus, DD-018 point 15) and shows the Horizon instead.
InsightsSegment shownSegment(
  InsightsSegment chosen, {
  required bool inReview,
}) => inReview && chosen == InsightsSegment.connections
    ? InsightsSegment.horizon
    : chosen;

/// The segment on screen; on Windows with two panes [InsightsSegment.horizon]
/// and [InsightsSegment.standstill] are one, side by side.
final insightsSegmentProvider = StateProvider<InsightsSegment>(
  (ref) => InsightsSegment.horizon,
);

/// The Overview destination, NL "Inzicht" (T10.7, REQ-052, DD-018 point
/// 12): the date and week in the top bar, then the segments.
class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key, this.wide = false});

  /// Windows with two panes: Horizon and Standstill side by side.
  final bool wide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final now = ref.watch(minuteClockProvider).valueOrNull ?? DateTime.now();
    final today = LocalDate.of(now);
    return HelpScope(
      topic: HelpTopic.insights,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.navInsights),
          actions: [
            Center(
              child: Text(
                l10n.insightsDate(today.toLocalDateTime(), today.isoWeek),
                style: TextStyle(
                  fontFamily: monoFamily,
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ...destinationActions(context),
            const HelpButton(),
          ],
        ),
        body: InsightsView(wide: wide),
      ),
    );
  }
}

/// The key of Horizon and Standstill side by side (`insightsSegment`).
const _both = 'both'; // l10n-ignore: a select key, not shown

/// The segments of the Overview and the one chosen: in its own destination
/// and as the first step of the weekly review ([inReview], DD-018 point 12
/// (g)).
class InsightsView extends ConsumerWidget {
  const InsightsView({super.key, this.wide = false, this.inReview = false});

  final bool wide;
  final bool inReview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final segment = shownSegment(
      ref.watch(insightsSegmentProvider),
      inReview: inReview,
    );
    // On Windows with two panes, Horizon and Standstill are one segment.
    final both =
        wide &&
        (segment == InsightsSegment.horizon ||
            segment == InsightsSegment.standstill);
    final choices = [
      if (wide)
        (_both, InsightsSegment.horizon)
      else ...[
        for (final s in [InsightsSegment.horizon, InsightsSegment.standstill])
          (s.name, s),
      ],
      (InsightsSegment.people.name, InsightsSegment.people),
      if (!inReview)
        (InsightsSegment.connections.name, InsightsSegment.connections),
    ];
    final chosen = both ? _both : segment.name;

    // A person opens over the Overview, back returns to it; in its own
    // destination on Windows the shell shows the person in the right pane
    // instead (DD-018 point 12 (d), (f)).
    void openPerson(String id) => unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PersonScreen(personId: id, standalone: true),
        ),
      ),
    );

    final Widget body = switch (segment) {
      InsightsSegment.people => PeopleBalance(
        segment: true,
        onOpen: wide && !inReview ? null : openPerson,
      ),
      InsightsSegment.connections => const ConnectionsView(),
      _ when both => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(child: HorizonView()),
          Expanded(child: StandstillView(inReview: inReview)),
        ],
      ),
      InsightsSegment.horizon => const HorizonView(),
      InsightsSegment.standstill => StandstillView(inReview: inReview),
    };

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              showSelectedIcon: false,
              style: const ButtonStyle(
                padding: WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 4),
                ),
              ),
              segments: [
                for (final (key, _) in choices)
                  ButtonSegment(
                    value: key,
                    // One line always; a long name in a narrow pane gets
                    // a little smaller instead (PO 04-10-2026).
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        l10n.insightsSegment(key),
                        maxLines: 1,
                        softWrap: false,
                      ),
                    ),
                  ),
              ],
              selected: {chosen},
              onSelectionChanged: (selected) {
                final key = selected.single;
                ref.read(insightsSegmentProvider.notifier).state = choices
                    .firstWhere((c) => c.$1 == key)
                    .$2;
              },
            ),
          ),
        ),
        Expanded(child: body),
      ],
    );
  }
}
