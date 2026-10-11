import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/search/drift_duplicate_dismissals.dart';
import '../../domain/ids/uuid_v7.dart';
import '../../domain/items/item.dart';
import '../../domain/items/item_headline.dart';
import '../../domain/links/item_link.dart';
import '../../domain/search/duplicates.dart';
import '../../domain/search/search_index.dart';
import '../../domain/time/local_date.dart';
import '../../l10n/app_localizations.dart';
import '../items/item_detail_screen.dart';
import '../items/item_providers.dart';
import '../messages.dart';
import '../startup/app_storage_provider.dart';
import '../tokens/token_display.dart';
import '../tokens/token_processor_provider.dart';
import 'search_providers.dart';

final _driftDismissalsProvider = Provider<DriftDuplicateDismissals>(
  (ref) => DriftDuplicateDismissals(ref.watch(storageProvider)),
);

/// Ignored pairs of the duplicate hint (AC REQ-053).
final duplicateDismissalsProvider = Provider<DuplicateDismissals>(
  (ref) => ref.watch(_driftDismissalsProvider),
);

/// Counts changes that may change a hint: the index was updated or a pair
/// was ignored. A new number each time, so the hints are worked out again.
final _hintChangesProvider = StreamProvider.autoDispose<int>((ref) {
  var count = 0;
  return ref.watch(_driftDismissalsProvider).changes().map((_) => ++count);
});

/// The older item that [item] seems to repeat, or null (REQ-053; PO
/// decisions 27-09-2026). Computed each time, never stored (hard rule 6);
/// a failure only means no hint.
final duplicateHintProvider = FutureProvider.autoDispose
    .family<SearchHit?, ({String id, String rawText})>((ref, item) async {
      ref.watch(_hintChangesProvider);
      try {
        return await DuplicateFinder(
          ref.watch(searchIndexProvider),
          ref.watch(duplicateDismissalsProvider),
          ref.watch(itemLinkRepositoryProvider),
        ).olderDuplicateOf(item.id, item.rawText);
      } catch (e, stack) {
        // Only the local developer log, never sent anywhere (REQ-015).
        developer.log(
          'Duplicate hint failed', // l10n-ignore: developer log
          name: 'offload.search', // l10n-ignore: log channel
          error: e,
          stackTrace: stack,
        );
        return null;
      }
    });

/// The duplicate hint (`duplicateHint`) under an inbox item, when it nearly repeats an
/// older one. Opens the comparison; never merges or deletes anything.
class DuplicateHint extends ConsumerWidget {
  const DuplicateHint({super.key, required this.item, this.onLink});

  final Item item;

  /// *Link* in the item detail: writes `[[label]]` into the text being
  /// edited. Null (inbox, triage): straight into the stored text.
  final Future<void> Function(String otherId, String label)? onLink;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final other = ref
        .watch(duplicateHintProvider((id: item.id, rawText: item.rawText)))
        .valueOrNull;
    if (other == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 16, 8),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton.icon(
          icon: const Icon(Icons.content_copy_outlined, size: 18),
          label: Text(AppLocalizations.of(context).duplicateHint),
          onPressed: () => _compare(context, ref, other),
        ),
      ),
    );
  }

  Future<void> _compare(
    BuildContext context,
    WidgetRef ref,
    SearchHit other,
  ) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context).textTheme;
    final captured = uuidV7Time(other.id).toLocal();
    final choice = await showDialog<_Choice>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.duplicateTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.duplicateThisItem, style: theme.labelLarge),
              const SizedBox(height: 4),
              Text(item.rawText),
              const SizedBox(height: 16),
              Text(
                l10n.duplicateOtherItem(captured, captured),
                style: theme.labelLarge,
              ),
              const SizedBox(height: 4),
              Text(other.title ?? other.text),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(_Choice.ignore),
            child: Text(l10n.duplicateIgnore),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(_Choice.link),
            child: Text(l10n.duplicateLink),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(_Choice.open),
            child: Text(l10n.duplicateOpen),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.duplicateClose),
          ),
        ],
      ),
    );
    if (choice == _Choice.open) {
      // Opening the other item (AC REQ-053, T2.3).
      if (context.mounted) await ItemDetailScreen.open(context, other.id);
      return;
    }
    if (choice == _Choice.link) {
      // The hint belongs to the newer item, which gets the link (decision
      // c, DD-004 point 13).
      final label = linkLabelFor(
        other.title ??
            itemHeadline(
              other.text,
              ref.read(inlineTokenRegistryProvider),
              parseContextOf(l10n, LocalDate.of(DateTime.now())),
            ).title,
      );
      try {
        final onLink = this.onLink;
        if (onLink != null) {
          await onLink(other.id, label);
        } else {
          await ref
              .read(itemRepositoryProvider)
              .appendLink(item.id, other.id, label);
          await ref.read(tokenProcessorProvider).process(item.id);
        }
      } catch (_) {
        showMessage(
          messenger,
          SnackBar(content: Text(l10n.duplicateLinkFailed)),
        );
      }
      return;
    }
    if (choice != _Choice.ignore) return;
    try {
      await ref.read(duplicateDismissalsProvider).dismiss(item.id, other.id);
    } catch (_) {
      showMessage(
        messenger,
        SnackBar(content: Text(l10n.duplicateIgnoreFailed)),
      );
    }
  }
}

enum _Choice { ignore, link, open }
