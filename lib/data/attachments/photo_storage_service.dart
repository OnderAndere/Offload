import 'dart:io';
import 'dart:typed_data';

import '../../domain/attachments/attachment.dart';
import '../../domain/attachments/image_policy.dart';
import 'attachment_format.dart';
import 'attachment_store.dart';
import 'drift_attachment_repository.dart';
import 'photo_compressor.dart';

/// Photos as attachments (REQ-027, DD-006 D1–D9): compressing, the
/// thumbnail, its path and deleting both. A photo is two encrypted files
/// under one attachment id: the display version is the attachment itself
/// (its record, `attachments/<id>`), the thumbnail is derived data in
/// `attachments/thumbs/<id>`, found by that convention and never in a column
/// (D3). No original is kept (D1).
///
/// The thumbnail folder sits inside the attachments folder, so it moves and
/// goes with it when a backup is restored; a backup never carries thumbnails
/// (D7) and a missing one is made again from the display version (D9).
class PhotoStorageService {
  PhotoStorageService({
    required this.attachments,
    required this.thumbnails,
    this.compressor = const PhotoCompressor(),
  });

  /// The records and the display versions.
  final DriftAttachmentRepository attachments;

  /// The thumbnails: a store on `AppStorage.thumbnailsDirectory`, of
  /// [AttachmentVariant.thumbnail].
  final AttachmentStore thumbnails;

  final PhotoCompressor compressor;

  /// Adds the picture [source] as a photo of [owner]; returns its id. The
  /// work stays off the UI thread but for the encryption of the small
  /// results. Throws [PhotoFormatException] for a picture the platform
  /// cannot decode; nothing is kept then.
  Future<String> add({
    required AttachmentOwner owner,
    required Uint8List source,
  }) async {
    final photo = await compressor.compress(source);
    final id = attachments.newId();
    // The thumbnail first: a record never exists without both files.
    await thumbnails.write(id, Stream.value(photo.thumbnail));
    try {
      return await attachments.add(
        owner: owner,
        mimeType: jpegMimeType,
        content: Stream.value(photo.display),
        pipelineVersion: photoPipelineVersion,
        id: id,
      );
    } catch (_) {
      try {
        await thumbnails.delete(id);
      } catch (_) {
        // The first error is the one to report; the thumbnail is an orphan
        // for T7.4 then.
      }
      rethrow;
    }
  }

  /// The display version of photo [id], verified.
  Future<Uint8List> display(String id) => attachments.files.readAll(id);

  /// Whether the display version of photo [id] is on this device: not after
  /// restoring a backup without attachments (DD-007 point 7a).
  bool hasDisplay(String id) => attachments.files.exists(id);

  /// The thumbnail of photo [id]. A missing or damaged one is made again
  /// from the display version and kept (DD-006/D9, REQ-032); asked again
  /// while that runs (two rows of a list), the same work is shared, so two
  /// writes never meet in one file (review T5.2).
  Future<Uint8List> thumbnail(String id) => _making[id] ??= _thumbnail(id)
      // A block, not an arrow: whenComplete would wait for the removed
      // future, which is this one.
      .whenComplete(() {
        _making.remove(id);
      });

  final _making = <String, Future<Uint8List>>{};

  Future<Uint8List> _thumbnail(String id) async {
    if (thumbnails.exists(id)) {
      try {
        return await thumbnails.readAll(id);
      } on AttachmentCorruptException {
        // Made again below.
      } on FileSystemException {
        // Gone in between: made again below.
      }
    }
    final made = await compressor.thumbnailOf(await display(id));
    await thumbnails.write(id, Stream.value(made));
    return made;
  }

  /// Removes photo [id]: the tombstone and the display version, then the
  /// thumbnail (DD-006/D8).
  Future<void> delete(String id) async {
    await attachments.delete(id);
    await thumbnails.delete(id);
  }

  static const jpegMimeType = 'image/jpeg';
}
