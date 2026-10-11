import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/items/item_headline.dart';
import '../../domain/projects/project.dart';
import '../../domain/snapshots/snapshot.dart';
import '../../domain/snapshots/today_notes.dart';
import '../../domain/time/local_date.dart';
import '../../domain/time/relative_age.dart';
import '../../l10n/app_localizations.dart';
import '../home/destination.dart';
import '../inbox/inbox_card.dart';
import '../items/item_detail_screen.dart';
import '../projects/project_look.dart';
import '../projects/project_providers.dart';
import '../snapshots/where_was_i.dart';
import '../startup/app_storage_provider.dart';
import '../theme/offload_colors.dart';
import '../tokens/token_display.dart';

/// Whether the open "Where was I" notes show on *Today* (T4b.2): a setting
/// of this device, on by default (PO 09-10-2026).
final todayNotesOnProvider = NotifierProvider<TodayNotesOnNotifier, bool>(
  TodayNotesOnNotifier.new,
);

class TodayNotesOnNotifier extends Notifier<bool> {
  @override
  bool build() => ref.watch(storageProvider).todayNotesOn;

  /// Applies [on] at once, then stores it. Throws when storing fails; the
  /// choice then still applies until the app restarts.
  Future<void> choose(bool on) async {
    state = on;
    await ref.read(storageProvider).saveTodayNotesOn(on);
  }
}

/// Every open note, one per item or project.
final openNotesProvider = StreamProvider.autoDispose<List<Snapshot>>(
  (ref) => ref.watch(snapshotRepositoryProvider).watchAllOpen(),
);

/// "⏸ Waar was ik · 5" at the top of *Today* (T4b.2, DD-018 point 13 (e),
/// variant A of sketch 22): the open notes, newest first, at most
/// [collapsedCount] until "+n meer" unfolds the rest in place. A tap opens
/// the item or project, where the resume card has *Bijwerken* and *Hervat*.
/// No buttons and no swipe here: a note is not the item (PO 09-10-2026).
class TodayNotes extends ConsumerStatefulWidget {
  const TodayNotes({super.key, required this.today, required this.now});

  final LocalDate today;
  final DateTime now;

  /// How many notes show before "+n meer".
  static const collapsedCount = 3;

  @override
  ConsumerState<TodayNotes> createState() => _TodayNotesState();
}

class _TodayNotesState extends ConsumerState<TodayNotes> {
  bool _unfolded = false;

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(todayNotesOnProvider)) return const SizedBox.shrink();
    final notes = notesForToday(
      ref.watch(openNotesProvider).valueOrNull ?? const [],
      items: ref.watch(liveItemsProvider).valueOrNull ?? const [],
      projects: ref.watch(projectsProvider).valueOrNull ?? const <Project>[],
      today: widget.today,
    );
    if (notes.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final hidden = _unfolded
        ? 0
        : (notes.length - TodayNotes.collapsedCount).clamp(0, notes.length);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Icon(
                  whereWasIIcon,
                  size: 16,
                  color: context.offloadColors.calm,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    l10n.todayNotesSection(notes.length),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: context.offloadColors.calm,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        for (final note in notes.take(notes.length - hidden))
          _NoteCard(note: note, today: widget.today, now: widget.now),
        if (hidden > 0)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: TextButton(
                onPressed: () => setState(() => _unfolded = true),
                child: Text(l10n.todayNotesMore(hidden)),
              ),
            ),
          ),
      ],
    );
  }
}

/// One note: the title of its item or project, the next step on one line
/// (else what was in mind), and how long ago it was saved.
class _NoteCard extends ConsumerWidget {
  const _NoteCard({required this.note, required this.today, required this.now});

  final TodayNote note;
  final LocalDate today;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final item = note.item;
    final project = note.project;
    final title = item != null
        ? itemHeadline(
            item.rawText,
            ref.watch(inlineTokenRegistryProvider),
            parseContextOf(l10n, today),
          ).title
        : project!.name;
    final snapshot = note.note;
    final step = snapshot.nextStep;
    final line = step ?? l10n.todayNoteInMind(snapshot.inMind ?? '');
    final saved = snapshot.savedAt;
    final age = saved == null
        ? null
        : relativeAgeTexts(relativeAge(saved.toLocal(), now), l10n);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: context.offloadColors.calmChip,
        clipBehavior: Clip.antiAlias,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        child: InkWell(
          onTap: () => _open(context, ref),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: context.offloadColors.calm, width: 4),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    if (project != null) ...[
                      Semantics(
                        label: l10n.todayNoteProject,
                        child: Icon(projectIcon, size: 16, color: muted),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    if (age != null) ...[
                      const SizedBox(width: 12),
                      Semantics(
                        label: age.long,
                        excludeSemantics: true,
                        child: Text(
                          age.short,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: muted,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  line,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: step == null ? muted : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The item in the detail (pane), or the project in its destination, as
  /// from *Verbanden* (DD-018 point 15).
  void _open(BuildContext context, WidgetRef ref) {
    final item = note.item;
    if (item != null) {
      unawaited(ItemDetailScreen.open(context, item.id));
      return;
    }
    ref.read(openProjectProvider.notifier).state = OpenProject(
      note.project!.id,
    );
    ref.read(destinationProvider.notifier).state = Destination.projects;
  }
}
