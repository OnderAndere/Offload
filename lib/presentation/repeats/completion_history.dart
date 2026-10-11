import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repeats/repeat.dart';
import '../../l10n/app_localizations.dart';
import '../items/item_providers.dart';

/// The completed times of an item, the newest first (REQ-061).
final completionsProvider = StreamProvider.autoDispose
    .family<List<RepeatCompletion>, String>(
      (ref, itemId) =>
          ref.watch(itemRepositoryProvider).watchCompletions(itemId),
    );

/// The block *Gedaan* in the item detail (DD-018 point 18): how many times
/// it was done, then the newest five with the day done and "op tijd" or
/// how late, then *Alles tonen*. Nothing while there is none.
class CompletionHistory extends ConsumerStatefulWidget {
  const CompletionHistory({super.key, required this.itemId});

  final String itemId;

  static const shown = 5;

  @override
  ConsumerState<CompletionHistory> createState() => _CompletionHistoryState();
}

class _CompletionHistoryState extends ConsumerState<CompletionHistory> {
  bool _all = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final times =
        ref.watch(completionsProvider(widget.itemId)).valueOrNull ?? const [];
    if (times.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final visible = _all ? times : times.take(CompletionHistory.shown);
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Semantics(
              header: true,
              child: Text(
                l10n.completionsTitle(times.length),
                style: theme.textTheme.titleSmall,
              ),
            ),
          ),
          for (final time in visible)
            MergeSemantics(
              child: ListTile(
                dense: true,
                title: Text(
                  l10n.revisitDate(time.completedOn.toLocalDateTime()),
                ),
                trailing: Text(
                  time.daysLate == 0
                      ? l10n.completionOnTime
                      : l10n.completionLate(
                          time.occurrenceOn.toLocalDateTime(),
                          time.daysLate,
                        ),
                  style: muted,
                ),
              ),
            ),
          if (!_all && times.length > CompletionHistory.shown)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: () => setState(() => _all = true),
                child: Text(l10n.completionsShowAll(times.length)),
              ),
            ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
