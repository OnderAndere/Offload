import 'package:drift/drift.dart';

import '../../domain/attachments/attachment.dart';
import '../database/app_database.dart';

/// How much Offload holds, for Settings → Storage (T7.5): every item (the
/// trash included, as it is still in the database) and of those the ones in
/// the trash, the projects and the people outside the trash, and the size of
/// the live attachments per kind (T5.1; those of an item in the trash too,
/// their files are still there).
Future<
  ({
    int items,
    int trashedItems,
    int projects,
    int people,
    Map<AttachmentKind, int> attachmentBytes,
  })
>
readStorageCounts(AppDatabase db) => db.transaction(() async {
  Future<int> count<T extends HasResultSet, R>(
    ResultSetImplementation<T, R> table, [
    Expression<bool>? where,
  ]) async {
    final all = countAll();
    final query = db.selectOnly(table)..addColumns([all]);
    if (where != null) query.where(where);
    return (await query.getSingle()).read(all) ?? 0;
  }

  final size = db.attachments.sizeBytes.sum();
  final perType =
      await (db.selectOnly(db.attachments)
            ..addColumns([db.attachments.mimeType, size])
            ..where(db.attachments.deletedAt.isNull())
            ..groupBy([db.attachments.mimeType]))
          .get();
  final attachmentBytes = <AttachmentKind, int>{};
  for (final row in perType) {
    final kind = attachmentKindOf(row.read(db.attachments.mimeType)!);
    attachmentBytes[kind] =
        (attachmentBytes[kind] ?? 0) + (row.read(size) ?? 0);
  }

  return (
    items: await count(db.items),
    trashedItems: await count(db.items, db.items.deletedAt.isNotNull()),
    projects: await count(db.contexts, db.contexts.deletedAt.isNull()),
    people: await count(db.people, db.people.deletedAt.isNull()),
    attachmentBytes: attachmentBytes,
  );
});
