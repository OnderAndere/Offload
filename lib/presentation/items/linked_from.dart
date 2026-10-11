import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/items/item_headline.dart';
import '../../domain/time/local_date.dart';
import '../../l10n/app_localizations.dart';
import '../tokens/token_display.dart';
import 'item_detail_screen.dart';
import 'item_labels.dart';
import 'item_providers.dart';

/// *Linked from · n* (DD-018 point 14): the live
/// items whose text links to item [itemId], below the buttons of the item
/// detail, only when there are any. A row opens its item; on Windows each
/// row is a Tab stop and Enter opens it.
class LinkedFrom extends ConsumerWidget {
  const LinkedFrom({super.key, required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backlinks = ref.watch(backlinksProvider(itemId)).valueOrNull;
    if (backlinks == null || backlinks.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final registry = ref.watch(inlineTokenRegistryProvider);
    final context_ = parseContextOf(l10n, LocalDate.of(DateTime.now()));
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.itemLinkedFrom(backlinks.length),
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          for (final link in backlinks)
            Card(
              margin: const EdgeInsets.symmetric(vertical: 2),
              child: ListTile(
                dense: true,
                title: Text(
                  itemHeadline(link.rawText, registry, context_).title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  l10n.status(link.status),
                  style: theme.textTheme.bodySmall,
                ),
                onTap: () => ItemDetailScreen.open(context, link.itemId),
              ),
            ),
        ],
      ),
    );
  }
}
