import 'package:drift/drift.dart';

import '../../domain/attachments/attachment.dart';
import '../../domain/attachments/photo_summary.dart';
import '../database/app_database.dart';
import '../storage/app_storage.dart';
import 'attachment_store.dart';

/// The attachments of items and people (REQ-023, DD-006): a record in the
/// database, written through the change log (REQ-008, DD-003), and an
/// encrypted file in the [AttachmentStore]. A file never exists without its
/// record for long: the file is written first and removed again when the
/// record cannot be written; removing sets the tombstone first and then
/// removes the file. A file left without a record by a crash in between is
/// for the clean-up of orphans (T7.4).
class DriftAttachmentRepository {
  DriftAttachmentRepository(this._storage, this.files);

  final AppStorage _storage;

  /// The encrypted files.
  final AttachmentStore files;

  AppDatabase get _db => _storage.database;

  /// The relative path of attachment [id]'s file, as the record keeps it.
  static String storagePathOf(String id) => 'attachments/$id';

  /// A fresh attachment id, for an attachment whose other files are
  /// written before it (a photo's thumbnail, DD-006/D3).
  String newId() => _storage.writer.ids.next();

  /// Adds [content] as an attachment of [owner] with [mimeType]; returns its
  /// id: [id] when given (from [newId]), else a fresh one. [pipelineVersion]
  /// is that of the photo pipeline (DD-006/D6), 0 for anything else.
  Future<String> add({
    required AttachmentOwner owner,
    required String mimeType,
    required Stream<List<int>> content,
    int pipelineVersion = 0,
    String? id,
  }) async {
    id ??= newId();
    final stored = await files.write(id, content);
    try {
      final inserted = await _storage.writer.insertWithId(
        _db.attachments,
        id,
        AttachmentsCompanion(
          itemId: Value(owner is ItemOwner ? owner.id : null),
          personId: Value(owner is PersonOwner ? owner.id : null),
          mimeType: Value(mimeType),
          sizeBytes: Value(stored.size),
          storagePath: Value(storagePathOf(id)),
          pipelineVersion: Value(pipelineVersion),
        ),
      );
      // A fresh id never exists already; if it did, its file was just
      // overwritten, and that must not pass silently.
      if (!inserted) throw StateError('attachment $id exists already');
    } catch (_) {
      await files.delete(id);
      rethrow;
    }
    return id;
  }

  /// Removes attachment [id]: the tombstone, then the file.
  Future<void> delete(String id) async {
    await _storage.writer.delete(_db.attachments, id);
    await files.delete(id);
  }

  /// The live attachments of [owner], the oldest first.
  Future<List<Attachment>> liveFor(AttachmentOwner owner) =>
      _liveFor(owner).get();

  /// [liveFor] as it changes: the photos of an item on screen (T5.3).
  Stream<List<Attachment>> watchFor(AttachmentOwner owner) =>
      _liveFor(owner).watch();

  /// The photos of every item, by item id, as they change: for the cards in
  /// the lists (T5.4). One query for the whole list, and only the columns
  /// the summary needs.
  Stream<Map<String, PhotoSummary>> watchItemPhotoSummaries() {
    final a = _db.attachments;
    final query = _db.selectOnly(a)
      ..addColumns([a.id, a.itemId, a.mimeType])
      ..where(a.itemId.isNotNull() & a.deletedAt.isNull());
    return query.watch().map(
      (rows) => summarisePhotos(
        rows.map(
          (row) => (
            id: row.read(a.id)!,
            itemId: row.read(a.itemId)!,
            mimeType: row.read(a.mimeType)!,
          ),
        ),
      ),
    );
  }

  SimpleSelectStatement<$AttachmentsTable, Attachment> _liveFor(
    AttachmentOwner owner,
  ) => _db.select(_db.attachments)
    ..where(
      (a) =>
          (owner is ItemOwner
              ? a.itemId.equals(owner.id)
              : a.personId.equals(owner.id)) &
          a.deletedAt.isNull(),
    )
    ..orderBy([(a) => OrderingTerm.asc(a.id)]);

  /// The content of attachment [id], verified a segment at a time.
  Stream<Uint8List> read(String id) => files.read(id);
}
