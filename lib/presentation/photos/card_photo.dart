import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import 'attachment_image.dart';
import 'photo_providers.dart';

/// The side of the thumbnail on a card in a list (T5.4).
const cardPhotoSize = 40.0;

/// The newest photo of item [itemId] as a small thumbnail on its card in a
/// list (T5.4, DD-006 point 5), with the number of photos when there are
/// more. Only the thumbnail is decoded, at the size it is shown, and from
/// the image cache when it comes back into view. A tap goes to the card, so
/// it opens the item. [orElse] when the item has no photos.
class CardPhoto extends ConsumerWidget {
  const CardPhoto({
    super.key,
    required this.itemId,
    this.padding = EdgeInsets.zero,
    this.orElse = const SizedBox.shrink(),
  });

  final String itemId;

  /// Around the thumbnail; not around [orElse].
  final EdgeInsetsGeometry padding;

  final Widget orElse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(
      itemPhotoSummariesProvider.select((s) => s.valueOrNull?[itemId]),
    );
    final service = ref.watch(photoStorageProvider);
    if (summary == null || service == null) return orElse;
    final theme = Theme.of(context);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final id = summary.newestId;
    return Padding(
      padding: padding,
      child: Semantics(
        label: AppLocalizations.of(context).cardPhotos(summary.count),
        excludeSemantics: true,
        child: SizedBox.square(
          dimension: cardPhotoSize,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: ColoredBox(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Image(
                    image: ResizeImage.resizeIfNeeded(
                      (cardPhotoSize * dpr).round(),
                      null,
                      AttachmentImage(
                        id,
                        thumbnail: true,
                        load: () => service.thumbnail(id),
                      ),
                    ),
                    fit: BoxFit.cover,
                    excludeFromSemantics: true,
                    // Not in a restored backup, or unreadable: the item
                    // detail says which.
                    errorBuilder: (context, error, stack) => Icon(
                      Icons.hide_image_outlined,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              if (summary.count > 1)
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.inverseSurface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        MaterialLocalizations.of(
                          context,
                        ).formatDecimal(summary.count),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onInverseSurface,
                        ),
                      ),
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
