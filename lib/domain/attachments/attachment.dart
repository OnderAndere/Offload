/// What an attachment belongs to (DD-006): an item, or a person (a business
/// card, REQ-041). The database enforces exactly one of the two.
sealed class AttachmentOwner {
  const AttachmentOwner(this.id);

  final String id;
}

final class ItemOwner extends AttachmentOwner {
  const ItemOwner(super.id);
}

final class PersonOwner extends AttachmentOwner {
  const PersonOwner(super.id);
}

/// The kinds Settings → Storage shows an attachment's size under (T5.1, PO
/// 09-10-2026).
enum AttachmentKind { photo, audio, other }

/// The kind of an attachment with [mimeType]: a photo for any image, audio
/// for any sound, everything else other.
AttachmentKind attachmentKindOf(String mimeType) {
  final type = mimeType.trim().toLowerCase();
  if (type.startsWith('image/')) return AttachmentKind.photo;
  if (type.startsWith('audio/')) return AttachmentKind.audio;
  return AttachmentKind.other;
}
