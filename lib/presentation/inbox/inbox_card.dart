import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/items/commitment.dart';
import '../../domain/items/item.dart';
import '../../domain/items/item_enums.dart';
import '../../domain/items/item_headline.dart';
import '../../domain/items/revisit.dart';
import '../../domain/repeats/repeat.dart';
import '../../domain/time/local_date.dart';
import '../../domain/time/relative_age.dart';
import '../../domain/tokens/contact_token_types.dart';
import '../../domain/tokens/stored_token.dart';
import '../../domain/tokens/token_processing.dart';
import '../../domain/tokens/token_types.dart';
import '../../l10n/app_localizations.dart';
import '../home/item_panes.dart';
import '../items/item_detail_screen.dart';
import '../items/item_labels.dart';
import '../items/item_type_look.dart';
import '../people/people_providers.dart';
import '../people/person_look.dart';
import '../photos/card_photo.dart';
import '../projects/project_look.dart';
import '../projects/project_providers.dart';
import '../search/duplicate_hint.dart';
import '../theme/offload_colors.dart';
import '../tokens/token_display.dart';
import '../tokens/token_editor.dart';

/// Now, refreshed every minute, so relative times such as "just now" do not
/// go stale in an open list (DD-018 point 2).
final minuteClockProvider = StreamProvider.autoDispose<DateTime>((ref) async* {
  yield DateTime.now();
  yield* Stream.periodic(const Duration(minutes: 1), (_) => DateTime.now());
});

/// The relative time of a card, short for the eye and written out for
/// screen readers.
({String short, String long}) relativeAgeTexts(
  RelativeAge age,
  AppLocalizations l10n,
) => switch (age) {
  JustNow() => (short: l10n.ageJustNow, long: l10n.ageJustNow),
  MinutesAgo(:final minutes) => (
    short: l10n.ageMinutes(minutes),
    long: l10n.ageMinutesLong(minutes),
  ),
  HoursAgo(:final hours) => (
    short: l10n.ageHours(hours),
    long: l10n.ageHoursLong(hours),
  ),
  Yesterday() => (short: l10n.ageYesterday, long: l10n.ageYesterday),
  DaysAgo(:final days) => (
    short: l10n.ageDays(days),
    long: l10n.ageDaysLong(days),
  ),
  OnDate(:final date) => (
    short: l10n.ageDate(date.toLocalDateTime()),
    long: l10n.ageDateLong(date.toLocalDateTime()),
  ),
};

/// One item in the inbox list as a card (T2.8, DD-018 point 2): the first
/// line as the title without tokens, "+ N lines" for more, the chips of the
/// processed tokens and the relative time, and the newest photo on the
/// right (T5.4). Tapping opens the item detail.
class InboxCard extends ConsumerWidget {
  const InboxCard({
    super.key,
    required this.item,
    required this.tokens,
    required this.now,
    required this.showStatus,
    this.showInboxStatus = false,
    this.showAge = true,
    this.showProject = true,
    this.hidePersonId,
  });

  final Item item;

  /// The processed tokens of [item] (none yet right after capturing).
  final List<StoredToken> tokens;

  /// The moment relative times count from.
  final DateTime now;

  /// Whether to show the status next to the time: on Today, where items
  /// from several places meet (DD-018 point 4).
  final bool showStatus;

  /// Whether the status shows for an item still in the inbox too: on Today,
  /// where items from several places meet (DD-018 point 4).
  final bool showInboxStatus;

  /// Whether to show the time since capture; Today leaves it out, because
  /// the deadline is what counts there (DD-018 point 4).
  final bool showAge;

  /// Whether to show the project chip; not inside the project itself
  /// (DD-018 point 6).
  final bool showProject;

  /// The person whose screen shows the card: their chips are left out
  /// (DD-018 point 7).
  final String? hidePersonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final registry = ref.watch(inlineTokenRegistryProvider);
    final today = LocalDate.of(now);
    final parseContext = parseContextOf(l10n, today);
    final headline = itemHeadline(item.rawText, registry, parseContext);
    final age = relativeAgeTexts(
      relativeAge(item.capturedAt.toLocal(), now),
      l10n,
    );
    final status =
        showStatus && (showInboxStatus || item.status != ItemStatus.inbox)
        ? l10n.status(item.status)
        : null;
    final String? label;
    final String? spoken;
    if (!showAge) {
      label = spoken = status;
    } else if (status == null) {
      label = age.short;
      spoken = age.long;
    } else {
      label = l10n.inboxStatusAndTime(status, age.short);
      spoken = l10n.inboxStatusAndTime(status, age.long);
    }
    // The card selected in the list pane on Windows: tinted, with a blue
    // bar on the left (DD-018 points 2 and 5).
    final desktop = isDesktop(context);
    final selected = desktop && ref.watch(selectedItemProvider) == item.id;
    return Semantics(
      // Only where cards can be selected; a phone has no selection.
      selected: desktop ? selected : null,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        color: selected ? theme.colorScheme.secondaryContainer : null,
        clipBehavior: Clip.antiAlias,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: selected
                ? Border(
                    left: BorderSide(
                      color: context.offloadColors.calm,
                      width: 3,
                    ),
                  )
                : null,
          ),
          child: InkWell(
            onTap: () => ItemDetailScreen.open(context, item.id),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _content(context, headline, label, spoken)),
                  CardPhoto(
                    itemId: item.id,
                    padding: const EdgeInsetsDirectional.only(start: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The text of the card: the title with the time, "+ N lines", the chips
  /// and the duplicate hint.
  Widget _content(
    BuildContext context,
    ItemHeadline headline,
    String? label,
    String? spoken,
  ) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final today = LocalDate.of(now);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text(
                headline.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall,
              ),
            ),
            if (label != null) ...[
              const SizedBox(width: 12),
              Semantics(
                label: spoken,
                excludeSemantics: true,
                child: Text(label, style: muted),
              ),
            ],
          ],
        ),
        if (headline.moreLines > 0)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(l10n.inboxMoreLines(headline.moreLines), style: muted),
          ),
        StoredTokenChips(
          item: item,
          tokens: tokens,
          today: today,
          showProject: showProject,
          hidePersonId: hidePersonId,
        ),
        DuplicateHint(item: item),
      ],
    );
  }
}

/// The type of [item] as the first chip (T2.10), then its project (DD-018
/// point 6) unless [showProject] is off, then its priority (DD-004 point
/// 11), then its requester and the person
/// it waits on unless the text names them (DD-018 point 7), then chips for
/// its tokens that are processed, in the order of the text (DD-018 point
/// 2); a date shows the stored date, so an old `!morgen` does not move
/// along. Nothing for an item without a type whose tokens are not
/// processed yet. [hidePersonId] leaves out the chips of that person.
class StoredTokenChips extends ConsumerWidget {
  const StoredTokenChips({
    super.key,
    required this.item,
    required this.tokens,
    required this.today,
    this.showProject = true,
    this.hidePersonId,
  });

  final Item item;
  final List<StoredToken> tokens;
  final LocalDate today;
  final bool showProject;
  final String? hidePersonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final matches = ref
        .watch(inlineTokenRegistryProvider)
        .parse(item.rawText, parseContextOf(l10n, today));
    final stored = {for (final t in tokens) (t.typeId, t.word): t};
    final type = item.type;
    final projectId = showProject ? item.projectId : null;
    final priority = item.priority;
    final chips = <Widget>[
      if (type != null) ItemTypeChip(type: type, dense: true),
      if (projectId != null &&
          ref.watch(projectTreeProvider)[projectId] != null)
        ProjectChip(projectId: projectId),
      // A waiting item's expected day; late: orange with a warning icon and
      // how late, never by colour alone (DD-018 point 10 (c)).
      ?_expectedChip(item, today, l10n, context.offloadColors),
      // A parked item's day back, calm (DD-018 point 17).
      ?_revisitChip(item, l10n),
      // High, normal and low (PO decision 02-10-2026, DD-004 point 11).
      if (priority != null)
        TokenChip(
          type: const PriorityTokenType(),
          word: '',
          date: null,
          priority: priority,
          today: today,
          dense: true,
        ),
    ];
    final personIds = ref.watch(personIdByNameProvider);
    chips.addAll(
      personRoleChips(
        item,
        named: namedPersonIds(tokens, personIds),
        hidePersonId: hidePersonId,
      ),
    );
    // A repeating item (DD-018 point 18): its rhythm, and the date of its
    // current time instead of the first time in the text.
    final repeatMatch = matches
        .where(
          (m) =>
              m.type is RepeatTokenType &&
              stored.containsKey((m.type.id, m.word)),
        )
        .firstOrNull;
    final dueAt = item.dueAt;
    for (final match in matches) {
      final token = stored[(match.type.id, match.word)];
      if (token == null) continue;
      if (match.type is RepeatTokenType) {
        if (!identical(match, repeatMatch)) continue;
        chips.add(
          TokenChip(
            type: match.type,
            word: l10n.repeatRhythm(rhythmLetter(match.value as Rhythm)),
            date: null,
            today: today,
            dense: true,
          ),
        );
        if (dueAt != null) {
          chips.add(
            TokenChip(
              type: const DateTokenType(),
              word: '',
              date: storedToDateOnly(dueAt),
              today: today,
              dense: true,
            ),
          );
        }
        continue;
      }
      if (repeatMatch != null && match.type is DateTokenType) continue;
      // The project and priority have their own chip above, from the item;
      // a phone number or email address stays in the title (DD-018 point 2).
      // A link reads as its text in the title (DD-018 point 14).
      if (match.type is ProjectTokenType ||
          match.type is LinkTokenType ||
          match.type is PriorityTokenType ||
          match.type is PhoneTokenType ||
          match.type is EmailTokenType) {
        continue;
      }
      if (hidePersonId != null &&
          match.type is PersonTokenType &&
          personIds[nameKey(match.word)] == hidePersonId) {
        continue;
      }
      final isDate = match.type is DateTokenType;
      if (isDate && token.date == null) continue;
      chips.add(
        TokenChip(
          type: match.type,
          word: match.word,
          date: isDate ? token.date : null,
          today: today,
          dense: true,
        ),
      );
    }
    if (chips.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(spacing: 6, runSpacing: 4, children: chips),
    );
  }
}

/// The day a parked item comes back, as a calm chip (DD-018 point 17); only
/// while it is scheduled: a returned item keeps its past date, unseen.
Widget? _revisitChip(Item item, AppLocalizations l10n) {
  final day = parkedDayOf(item);
  if (day == null) return null;
  final date = day.toLocalDateTime();
  return Semantics(
    label: l10n.revisitLine(date),
    excludeSemantics: true,
    child: Chip(
      avatar: const Icon(Icons.update, size: 16),
      label: Text(l10n.revisitDate(date)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      labelPadding: const EdgeInsetsDirectional.only(end: 4),
    ),
  );
}

/// The expected day of a waiting item as a chip (T10.1): calm while ahead,
/// orange with a warning icon and "3 d te laat" once past.
Widget? _expectedChip(
  Item item,
  LocalDate today,
  AppLocalizations l10n,
  OffloadColors colors,
) {
  final expected = item.expectedAt;
  if (!hasWaitingPart(item) || expected == null) return null;
  final late = daysLate(item, today);
  final text = late == null
      ? l10n.commitmentExpectedChip(expected.toLocalDateTime())
      : l10n.commitmentLateChip(late);
  return Semantics(
    label: late == null ? text : l10n.commitmentLateChipLabel(late),
    excludeSemantics: true,
    child: Chip(
      avatar: Icon(
        late == null ? Icons.event_outlined : Icons.warning_amber,
        size: 16,
        color: late == null ? null : colors.attention,
      ),
      label: Text(
        text,
        style: late == null ? null : TextStyle(color: colors.attention),
      ),
      side: late == null ? null : BorderSide(color: colors.attention),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      labelPadding: const EdgeInsetsDirectional.only(end: 4),
    ),
  );
}
