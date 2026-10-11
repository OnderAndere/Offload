import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/items/item_headline.dart';
import '../../domain/overview/standstill.dart';
import '../../domain/overview/treemap.dart';
import '../../domain/time/local_date.dart';
import '../../l10n/app_localizations.dart';
import '../home/destination.dart';
import '../inbox/inbox_card.dart';
import '../items/item_detail_screen.dart';
import '../projects/project_providers.dart';
import '../review/weekly_review_screen.dart';
import '../theme/design_tokens.dart';
import '../tokens/token_display.dart';
import '../tokens/token_editor.dart';
import 'list_arrows.dart';
import 'overview_providers.dart';

/// The Standstill of the Overview (T10.7 step C, REQ-052, DD-018 point 12
/// (c)): a treemap tile per top-level project, sized by its open items and
/// coloured by the time since the most recent touch; under it the three
/// items untouched the longest, or the items of the tapped tile. On
/// Windows ←/→ choose a tile while the treemap has the focus.
class StandstillView extends ConsumerStatefulWidget {
  const StandstillView({
    super.key,
    this.padding = const EdgeInsets.all(12),
    this.inReview = false,
  });

  final EdgeInsetsGeometry padding;

  /// Inside the weekly review: no link to it (DD-018 point 12 (g)).
  final bool inReview;

  @override
  ConsumerState<StandstillView> createState() => _StandstillViewState();
}

class _StandstillViewState extends ConsumerState<StandstillView> {
  /// The project of the tapped tile, kept by id: the tiles re-sort when
  /// the data changes. Null shows the oldest items; `(id: null)` is the
  /// tile of no project.
  ({String? id})? _tile;

  final _focus = FocusNode();
  bool _focused = false;

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  /// The index of the chosen tile in [tiles]; null when none is chosen or
  /// its project has no tile any more.
  int? _indexIn(List<StandstillTile> tiles) {
    final chosen = _tile;
    if (chosen == null) return null;
    final at = tiles.indexWhere((t) => t.project == chosen.id);
    return at < 0 ? null : at;
  }

  void _select(List<StandstillTile> tiles, int index) {
    setState(
      () =>
          _tile = index == _indexIn(tiles) ? null : (id: tiles[index].project),
    );
    // A click on a tile: the arrows go on from there (Windows).
    if (isDesktop(context)) _focus.requestFocus();
  }

  KeyEventResult _onKey(List<StandstillTile> tiles, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final step = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowLeft => -1,
      LogicalKeyboardKey.arrowRight => 1,
      _ => 0,
    };
    if (step == 0 || tiles.isEmpty) return KeyEventResult.ignored;
    final at = _indexIn(tiles) ?? (step > 0 ? -1 : tiles.length);
    final next = (at + step).clamp(0, tiles.length - 1);
    setState(() => _tile = (id: tiles[next].project));
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final standstill = ref.watch(standstillProvider);
    final tiles = standstill.tiles;
    final tile = _indexIn(tiles);
    // A tile that is gone is forgotten: it does not come back chosen when
    // its project gets open items again.
    if (tile == null) _tile = null;
    Widget map = _Treemap(
      tiles: tiles,
      selected: tile,
      focused: _focused,
      onSelect: (index) => _select(tiles, index),
    );
    if (isDesktop(context)) {
      map = Focus(
        focusNode: _focus,
        onKeyEvent: (_, event) => _onKey(tiles, event),
        onFocusChange: (focused) => setState(() => _focused = focused),
        child: map,
      );
    }
    return ListView(
      padding: widget.padding,
      children: [
        map,
        const SizedBox(height: 12),
        _ItemList(
          standstill: standstill,
          tile: tile == null ? null : tiles[tile],
          inReview: widget.inReview,
          onBack: () => setState(() => _tile = null),
        ),
      ],
    );
  }
}

/// An age as text: days below two weeks, else whole weeks.
String standstillAge(AppLocalizations l10n, int days) => days < 14
    ? l10n.standstillAgeDays(days)
    : l10n.standstillAgeWeeks(days ~/ 7);

String _spokenAge(AppLocalizations l10n, int days) => days < 14
    ? l10n.standstillAgeSpokenDays(days)
    : l10n.standstillAgeSpokenWeeks(days ~/ 7);

/// The card with the tiles and the legend.
class _Treemap extends ConsumerWidget {
  const _Treemap({
    required this.tiles,
    required this.selected,
    required this.focused,
    required this.onSelect,
  });

  final List<StandstillTile> tiles;
  final int? selected;
  final bool focused;
  final ValueChanged<int> onSelect;

  /// The space between tiles.
  static const _gap = 4.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final tree = ref.watch(projectTreeProvider);
    String name(String? project) => project == null
        ? l10n.horizonNoProject
        : tree[project]?.name ?? l10n.horizonNoProject;

    Widget tileAt(int index, TreemapRect rect) {
      final t = tiles[index];
      final fg = standstillTextColors[t.level.index];
      final age = standstillAge(l10n, t.ageDays);
      final large = rect.width >= 110 && rect.height >= 80;
      final title = Text(
        name(t.project),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleSmall?.copyWith(
          color: fg,
          // No italics: the typeface has none (DD-017).
          fontWeight: t.project == null ? FontWeight.w400 : null,
        ),
      );
      final mono = TextStyle(fontFamily: monoFamily, fontSize: 12, color: fg);
      return Positioned(
        left: rect.x + _gap / 2,
        top: rect.y + _gap / 2,
        width: math.max(0, rect.width - _gap),
        height: math.max(0, rect.height - _gap),
        child: Semantics(
          button: true,
          selected: index == selected,
          excludeSemantics: true,
          label: l10n.standstillTileSemantics(
            name(t.project),
            t.open,
            _spokenAge(l10n, t.ageDays),
          ),
          child: _TileTitle(
            text: l10n.standstillTileTooltip(name(t.project), t.open, age),
            child: Material(
              color: standstillColors[t.level.index],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: index == selected
                    ? const BorderSide(color: calmColor, width: 3)
                    : BorderSide.none,
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => onSelect(index),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                  // Every tile shows name, count and age, small ones too
                  // (DD-017): a large tile on three lines, a small one on
                  // two, scaled down when even that does not fit.
                  child: large
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(child: title),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(l10n.standstillOpen(t.open), style: mono),
                                Text(l10n.standstillStill(age), style: mono),
                              ],
                            ),
                          ],
                        )
                      : FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.topLeft,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              title,
                              Text(
                                l10n.standstillTileShort(t.open, age),
                                style: mono,
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: focused ? calmColor : theme.dividerColor,
          width: focused ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    l10n.standstillTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Text(
                  l10n.standstillSizeHint,
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (tiles.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  l10n.standstillEmpty,
                  style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final height = width < 500 ? 300.0 : 260.0;
                  final rects = squarify(
                    [for (final t in tiles) t.open],
                    width,
                    height,
                  );
                  return SizedBox(
                    height: height,
                    child: Stack(
                      children: [
                        for (final (i, rect) in rects.indexed) tileAt(i, rect),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 14,
              runSpacing: 4,
              children: [
                for (final level in StandstillLevel.values)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: standstillColors[level.index],
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l10n.standstillLevel(level.name),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: muted,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// On Windows the mouse pointer on a tile shows its name, count and age
/// (DD-018 point 12 (f)).
class _TileTitle extends StatelessWidget {
  const _TileTitle({required this.text, required this.child});

  final String text;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      isDesktop(context) ? Tooltip(message: text, child: child) : child;
}

/// The list under the tiles: the oldest three, or the tapped tile's items.
class _ItemList extends ConsumerWidget {
  const _ItemList({
    required this.standstill,
    required this.tile,
    required this.inReview,
    required this.onBack,
  });

  final Standstill standstill;
  final StandstillTile? tile;
  final bool inReview;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final tree = ref.watch(projectTreeProvider);
    final registry = ref.watch(inlineTokenRegistryProvider);
    final now = ref.watch(minuteClockProvider).valueOrNull ?? DateTime.now();
    final parseContext = parseContextOf(l10n, LocalDate.of(now));
    String name(String? project) => project == null
        ? l10n.horizonNoProject
        : tree[project]?.name ?? l10n.horizonNoProject;
    final tile = this.tile;
    final entries = tile == null
        ? standstill.oldest
        : standstill.itemsOf(tile.project);
    if (tile == null && entries.isEmpty) return const SizedBox.shrink();

    // Inside the review neither link: the review stays in front of the
    // project, and it is itself the review (DD-018 point 12 (g)).
    final Widget? link;
    if (inReview) {
      link = null;
    } else if (tile != null) {
      link = TextButton(
        onPressed: () {
          ref.read(destinationProvider.notifier).state = Destination.projects;
          ref.read(openProjectProvider.notifier).state = OpenProject(
            tile.project,
          );
        },
        child: Text(l10n.standstillOpenProject),
      );
    } else {
      link = TextButton(
        onPressed: () => WeeklyReviewScreen.open(context, ref),
        child: Text(l10n.standstillToReview),
      );
    }

    // ↑/↓ move between the rows, Enter opens one (Windows).
    return ListArrows(
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.dividerColor),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  if (tile != null)
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: l10n.standstillShowOldest,
                      onPressed: onBack,
                    ),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        tile == null
                            ? l10n.standstillOldest
                            : l10n.standstillProjectItems(
                                name(tile.project),
                                tile.open,
                              ),
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                  ),
                  ?link,
                ],
              ),
              for (final entry in entries)
                InkWell(
                  onTap: () => ItemDetailScreen.open(context, entry.item.id),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(2, 6, 8, 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                itemHeadline(
                                  entry.item.rawText,
                                  registry,
                                  parseContext,
                                ).title,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (tile == null)
                                Text(
                                  name(entry.lane),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: muted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          standstillAge(l10n, entry.ageDays),
                          style: TextStyle(
                            fontFamily: monoFamily,
                            fontWeight: FontWeight.w600,
                            // Orange from six weeks, as in the weekly review
                            // (DD-018 point 8).
                            color:
                                StandstillLevel.of(entry.ageDays) ==
                                    StandstillLevel.longest
                                ? attentionTextColor
                                : muted,
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
