import 'attachment.dart';

/// The photos of one item as a card in a list shows them (T5.4, DD-006
/// point 5): the newest photo, whose thumbnail the card shows, and how
/// many there are.
typedef PhotoSummary = ({String newestId, int count});

/// One live attachment of an item, as [summarisePhotos] reads it.
typedef ItemAttachmentRow = ({String id, String itemId, String mimeType});

/// The photos per item id among [rows]: only photos count (any `image/`
/// type), and the newest is the one with the highest id, as UUIDv7 ids
/// sort by the moment they were made (DD-003).
Map<String, PhotoSummary> summarisePhotos(Iterable<ItemAttachmentRow> rows) {
  final byItem = <String, PhotoSummary>{};
  for (final row in rows) {
    if (attachmentKindOf(row.mimeType) != AttachmentKind.photo) continue;
    final known = byItem[row.itemId];
    byItem[row.itemId] = known == null
        ? (newestId: row.id, count: 1)
        : (
            newestId: row.id.compareTo(known.newestId) > 0
                ? row.id
                : known.newestId,
            count: known.count + 1,
          );
  }
  return byItem;
}
