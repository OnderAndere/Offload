import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/help/help_topics.dart';
import '../../domain/people/person.dart';
import '../../domain/people/person_balance.dart';
import '../../domain/time/local_date.dart';
import '../../l10n/app_localizations.dart';
import '../help/help_scope.dart';
import '../home/destination_actions.dart';
import '../home/item_panes.dart';
import '../inbox/inbox_card.dart';
import '../theme/offload_colors.dart';
import '../tokens/token_editor.dart';
import 'people_providers.dart';
import 'person_look.dart';
import 'person_screen.dart';

/// The People destination (DD-011, DD-018 points 7 and 11): the balance of
/// every person, or on a phone the person opened from it in its place. On
/// Windows with two panes the list stays and the person opens in the right
/// pane (DD-018 point 11).
class PeopleScreen extends ConsumerWidget {
  const PeopleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final open = ref.watch(openPersonProvider);
    final twoPanes = ItemPanes.maybeOf(context) != null;
    if (open != null && !twoPanes) {
      return PersonScreen(key: ValueKey(open), personId: open);
    }
    return const PeopleBalance();
  }
}

/// The balance (AC REQ-048, DD-018 point 11): two totals, then every live
/// person with a filter field; per row a bar from a central axis, what I
/// deliver to the left and what I wait for to the right, and the age of
/// the oldest open item. People with open items first, the most on top,
/// alphabetical when equal; then the others, subdued, alphabetical. The
/// Overview shows the same list as its segment *People* (DD-018 point 12
/// (d)): without the filter field and the screen around it.
class PeopleBalance extends ConsumerStatefulWidget {
  const PeopleBalance({super.key, this.segment = false, this.onOpen});

  /// As a segment of the Overview: no filter field, no screen of its own.
  final bool segment;

  /// Opens a person; by default in the People destination.
  final ValueChanged<String>? onOpen;

  @override
  ConsumerState<PeopleBalance> createState() => _PeopleBalanceState();
}

class _PeopleBalanceState extends ConsumerState<PeopleBalance> {
  final _ownFocus = FocusNode();
  final _filter = TextEditingController();

  /// The row chosen with ↑/↓ on Windows.
  int? _highlight;

  @override
  void dispose() {
    _ownFocus.dispose();
    _filter.dispose();
    super.dispose();
  }

  void _open(String id) {
    final open = widget.onOpen;
    if (open != null) {
      open(id);
    } else {
      ref.read(openPersonProvider.notifier).state = id;
    }
  }

  KeyEventResult _onKey(List<String> targets, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (targets.isEmpty) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowUp) {
      final at = _highlight ?? -1;
      final next = key == LogicalKeyboardKey.arrowDown
          ? (at + 1).clamp(0, targets.length - 1)
          : (at <= 0 ? 0 : at - 1);
      setState(() => _highlight = next);
      return KeyEventResult.handled;
    }
    final enter =
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter;
    if (enter && _highlight != null && _highlight! < targets.length) {
      _open(targets[_highlight!]);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final people = ref.watch(peopleProvider).valueOrNull;
    final balances = ref.watch(personBalancesProvider);
    final oldAfter = ref.watch(oldAfterProvider);
    final now = ref.watch(minuteClockProvider).valueOrNull ?? DateTime.now();
    final today = LocalDate.of(now);
    final open = ref.watch(openPersonProvider);
    final query = _filter.text.trim();
    final rows =
        [
          for (final p in people ?? const <Person>[])
            if (query.isEmpty || p.matches(query))
              (name: p.name, balance: balances[p.id], person: p),
        ]..sort(
          (a, b) => balanceOrder(
            (id: a.person.id, name: a.name, balance: a.balance),
            (id: b.person.id, name: b.name, balance: b.balance),
          ),
        );
    final targets = [for (final r in rows) r.person.id];
    final totals = balanceTotals(balances);
    // The longest bar part fills its half; the others scale to it.
    final longest = [
      for (final b in balances.values) ...[b.deliver, b.waiting],
    ].fold(1, (a, b) => a > b ? a : b);

    final list = ListView(
      // Room at the bottom so the capture button never hides the last row.
      padding: const EdgeInsets.only(top: 4, bottom: 96),
      children: [
        if (!widget.segment)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: TextField(
              controller: _filter,
              decoration: InputDecoration(
                hintText: l10n.peopleFilterHint,
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: const OutlineInputBorder(),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: l10n.searchClear,
                        onPressed: () => setState(_filter.clear),
                      ),
              ),
              onChanged: (_) => setState(() => _highlight = null),
              // Enter opens the only person left.
              onSubmitted: (_) {
                final matching = [
                  for (final p in people ?? const <Person>[])
                    if (p.matches(_filter.text.trim())) p,
                ];
                if (matching.length == 1) _open(matching.single.id);
              },
            ),
          ),
        if (balances.isNotEmpty) ...[_Totals(totals: totals), const _Legend()],
        for (final (index, row) in rows.indexed)
          _PersonRow(
            person: row.person,
            balance: row.balance,
            longest: longest,
            today: today,
            oldAfter: oldAfter,
            // The open person, else the row chosen with the keys.
            highlighted: open != null
                ? open == row.person.id
                : _highlight == index,
            onTap: () {
              // The keys go on from here once the person closes.
              setState(() => _highlight = index);
              _open(row.person.id);
            },
          ),
        if (people != null && rows.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Text(
              people.isEmpty ? l10n.peopleEmpty : l10n.peopleNoMatch,
              style: theme.textTheme.bodyMedium,
            ),
          ),
      ],
    );
    final body = isDesktop(context)
        ? Focus(
            focusNode: ItemPanes.maybeOf(context)?.listFocus ?? _ownFocus,
            autofocus: !widget.segment,
            onKeyEvent: (_, event) => _onKey(targets, event),
            child: list,
          )
        : list;
    if (widget.segment) return body;
    return HelpScope(
      topic: HelpTopic.people,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.navPeople),
          actions: [...destinationActions(context), const HelpButton()],
        ),
        body: body,
      ),
    );
  }
}

/// "Ik moet nog leveren · 5 aan 3 personen" and "Ik wacht nog op · 4 van 2
/// personen" (AC REQ-048).
class _Totals extends StatelessWidget {
  const _Totals({required this.totals});

  final BalanceTotals totals;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    Widget box(String title, String value, Color color) => Expanded(
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.titleSmall?.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Row(
        children: [
          box(
            l10n.peopleDeliverTitle,
            l10n.peopleDeliverTotal(totals.deliver, totals.deliverPeople),
            context.offloadColors.attentionText,
          ),
          const SizedBox(width: 8),
          box(
            l10n.peopleWaitTitle,
            l10n.peopleWaitTotal(totals.waiting, totals.waitingPeople),
            context.offloadColors.calm,
          ),
        ],
      ),
    );
  }
}

/// The legend above the bars (DD-017: every view has one): left I deliver,
/// right I wait, the age column.
class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 2),
        child: Row(
          children: [
            const SizedBox(width: _PersonRow.nameWidth),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // On a narrow phone the words may not both fit.
                  Flexible(
                    child: Text(
                      l10n.peopleLegendDeliver,
                      style: style,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      l10n.peopleLegendWait,
                      style: style,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: _PersonRow.ageWidth,
              child: Text(
                l10n.peopleLegendOldest,
                style: style,
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One row of the balance: the name, the bar and the oldest age; subdued
/// when nothing is open. Direction and number carry the meaning, not only
/// the colour; an old age is orange, bold and gets ⏱ (DD-017).
class _PersonRow extends StatelessWidget {
  const _PersonRow({
    required this.person,
    required this.balance,
    required this.longest,
    required this.today,
    required this.oldAfter,
    required this.highlighted,
    required this.onTap,
  });

  static const nameWidth = 112.0;
  static const ageWidth = 56.0;

  final Person person;
  final PersonBalance? balance;
  final int longest;
  final LocalDate today;
  final int oldAfter;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final balance = this.balance;
    final quiet = balance == null;
    final age = balance == null ? null : balanceAge(balance.oldest, today);
    final old = age != null && OldAfter.isOld(age, oldAfter);
    final spoken = balance == null
        ? person.name
        : l10n.peopleRowSemantics(
            person.name,
            balance.deliver,
            balance.waiting,
            age!,
          );
    return Semantics(
      button: true,
      // The row's own tap is excluded with its semantics (REQ-016).
      onTap: onTap,
      label: old ? l10n.peopleRowSemanticsOld(spoken) : spoken,
      excludeSemantics: true,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        color: highlighted
            ? colors.secondaryContainer
            : quiet
            // Fixed in every theme: a quiet row has no card of its own.
            ? Colors.transparent
            : null,
        elevation: quiet ? 0 : null,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: nameWidth,
                  child: Row(
                    children: [
                      PersonAvatar(name: person.name, quiet: quiet, size: 28),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          person.name,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: quiet ? FontWeight.w400 : null,
                            color: quiet ? colors.onSurfaceVariant : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: balance == null
                      ? const SizedBox.shrink()
                      : _Bar(balance: balance, longest: longest),
                ),
                SizedBox(
                  width: ageWidth,
                  child: age == null
                      ? null
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (old) ...[
                              Icon(
                                Icons.timer_outlined,
                                size: 14,
                                color: context.offloadColors.attentionText,
                              ),
                              const SizedBox(width: 2),
                            ],
                            Flexible(
                              child: Text(
                                l10n.peopleAge(age),
                                overflow: TextOverflow.fade,
                                softWrap: false,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: old
                                      ? context.offloadColors.attentionText
                                      : colors.onSurfaceVariant,
                                  fontWeight: old ? FontWeight.w700 : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The diverging bar: from the central axis, what I deliver to the left in
/// orange and what I wait for to the right in blue, each with its count
/// (AC REQ-048). Lengths relative to the [longest] part of any person.
class _Bar extends StatelessWidget {
  const _Bar({required this.balance, required this.longest});

  final PersonBalance balance;
  final int longest;

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.outline;
    Widget part(int count, Color color, {required bool left}) => LayoutBuilder(
      builder: (context, constraints) {
        if (count == 0) return const SizedBox(height: 20);
        // Room for the number in even the shortest part, as far as the
        // width allows (a narrow window).
        final room = constraints.maxWidth;
        final width = (room * count / longest).clamp(
          room < 24 ? room : 24.0,
          room,
        );
        return Align(
          alignment: left ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: width,
            height: 20,
            alignment: left ? Alignment.centerLeft : Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              color: color,
              borderRadius: left
                  ? const BorderRadius.horizontal(left: Radius.circular(4))
                  : const BorderRadius.horizontal(right: Radius.circular(4)),
            ),
            child: Text(
              '$count', // l10n-ignore: a number
              // White on a meaning colour: check the contrast again with
              // the dark variant (T8.1).
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
    return Row(
      children: [
        Expanded(
          child: part(
            balance.deliver,
            context.offloadColors.attention,
            left: true,
          ),
        ),
        Container(width: 2, height: 22, color: outline),
        Expanded(
          child: part(balance.waiting, context.offloadColors.calm, left: false),
        ),
      ],
    );
  }
}
