import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/attachments/attachment_format.dart';
import '../../data/attachments/attachment_store.dart';
import '../../data/attachments/drift_attachment_repository.dart';
import '../../data/attachments/photo_storage_service.dart';
import '../../domain/attachments/attachment.dart';
import '../../platform/cipher/aead_cipher.dart';
import '../../platform/cipher/platform_aead_cipher.dart';
import '../../platform/photo_source/photo_source.dart';
import '../../platform/photo_source/platform_photo_source.dart';
import '../startup/app_storage_provider.dart';

/// Where a new photo comes from (T5.3): camera app, photo picker or Open
/// window.
final photoSourceProvider = Provider<PhotoSource>(
  (ref) => createPlatformPhotoSource(),
);

/// AES-256-GCM of the platform for the attachment files (DD-006).
final attachmentCipherProvider = Provider<AeadCipher>(
  (ref) => createPlatformAeadCipher(),
);

/// The photos of the opened storage (T5.2); null for a storage without
/// files (tests).
final photoStorageProvider = Provider<PhotoStorageService?>((ref) {
  final storage = ref.watch(storageProvider);
  final key = storage.attachmentsKey;
  final files = storage.attachmentsDirectory;
  final thumbnails = storage.thumbnailsDirectory;
  if (key == null || files == null || thumbnails == null) return null;
  final cipher = ref.watch(attachmentCipherProvider);
  return PhotoStorageService(
    attachments: DriftAttachmentRepository(
      storage,
      AttachmentStore(directory: files, attachmentsKey: key, cipher: cipher),
    ),
    thumbnails: AttachmentStore(
      directory: thumbnails,
      attachmentsKey: key,
      cipher: cipher,
      variant: AttachmentVariant.thumbnail,
    ),
  );
});

/// A photo of an item on screen: its id, and whether its file is on this
/// device (not after restoring a backup without attachments, DD-007 point
/// 7a).
typedef ItemPhoto = ({String id, bool present});

/// The photos of item [itemId], the oldest first (DD-018 point 19).
final itemPhotosProvider = StreamProvider.autoDispose
    .family<List<ItemPhoto>, String>((ref, itemId) {
      final photos = ref.watch(photoStorageProvider);
      if (photos == null) return Stream.value(const []);
      return photos.attachments
          .watchFor(ItemOwner(itemId))
          .map(
            (records) => [
              for (final record in records)
                if (attachmentKindOf(record.mimeType) == AttachmentKind.photo)
                  (id: record.id, present: photos.hasDisplay(record.id)),
            ],
          );
    });

/// What adding a photo to an item is doing: one at a time per item
/// (DD-018 point 19 (b)).
enum PhotoAdding { idle, choosing, processing }

/// Not auto-disposed: an add carries on when the item detail closes, and
/// sets this back when it ends.
final photoAddingProvider = StateProvider.family<PhotoAdding, String>(
  (ref, itemId) => PhotoAdding.idle,
);
