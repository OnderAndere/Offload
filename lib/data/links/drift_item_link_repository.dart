import 'package:drift/drift.dart';

import '../../domain/links/item_link.dart';
import '../database/app_database.dart';
import '../storage/app_storage.dart';

/// The kind of an item link made by `[[…]]` in the text (DD-004 point 13).
const linkKind = 'link';

/// [ItemLinkRepository] on the encrypted Drift database (T10.9, REQ-054).
/// Writes go through the [AppStorage.writer] (REQ-008, DD-003).
class DriftItemLinkRepository implements ItemLinkRepository {
  DriftItemLinkRepository(this._storage);

  final AppStorage _storage;

  AppDatabase get _db => _storage.database;

  /// Links item [fromId] to [toId] under [label], the text between its
  /// brackets: the choice from the suggestion list. Keeps one live link per
  /// label (DD-004 point 13): a link with the same label to another item is
  /// removed, the same link is kept. Runs in the caller's transaction, so
  /// the text and its links are saved together; a link to itself is never
  /// made.
  Future<void> writeChosen(String fromId, String toId, String label) async {
    if (fromId == toId || label.trim().isEmpty) return;
    final key = linkKey(label);
    var kept = false;
    for (final link in await liveLinksFrom(fromId)) {
      if (linkKey(link.label ?? '') != key) continue;
      if (link.toItemId == toId && !kept) {
        kept = true;
      } else {
        await _storage.writer.delete(_db.itemLinks, link.id);
      }
    }
    if (kept) return;
    await _storage.writer.insert(
      _db.itemLinks,
      ItemLinksCompanion(
        fromItemId: Value(fromId),
        toItemId: Value(toId),
        kind: const Value(linkKind),
        label: Value(label.trim()),
      ),
    );
  }

  /// The live `[[…]]` links of item [fromId], by their last change, the
  /// oldest first (lowest HLC, then id): when two devices linked one label,
  /// the one changed first counts (a restored link has a new HLC).
  Future<List<ItemLink>> liveLinksFrom(String fromId) =>
      (_db.select(_db.itemLinks)
            ..where(
              (l) =>
                  l.fromItemId.equals(fromId) &
                  l.kind.equals(linkKind) &
                  l.deletedAt.isNull(),
            )
            ..orderBy([
              (l) => OrderingTerm.asc(l.hlc),
              (l) => OrderingTerm.asc(l.id),
            ]))
          .get();

  /// The removed `[[…]]` links of item [fromId], the last removed first:
  /// to restore a choice when its text comes back.
  Future<List<ItemLink>> removedLinksFrom(String fromId) =>
      (_db.select(_db.itemLinks)
            ..where(
              (l) =>
                  l.fromItemId.equals(fromId) &
                  l.kind.equals(linkKind) &
                  l.deletedAt.isNotNull(),
            )
            ..orderBy([(l) => OrderingTerm.desc(l.hlc)]))
          .get();

  @override
  Stream<List<LinkedItem>> watchLinksFrom(String itemId) {
    final link = _db.itemLinks;
    final target = _db.items;
    final query =
        _db.select(link).join([
            innerJoin(target, target.id.equalsExp(link.toItemId)),
          ])
          ..where(
            link.fromItemId.equals(itemId) &
                link.kind.equals(linkKind) &
                link.deletedAt.isNull(),
          )
          ..orderBy([OrderingTerm.asc(link.hlc), OrderingTerm.asc(link.id)]);
    return query.watch().map(
      (rows) => [
        for (final row in rows)
          LinkedItem(
            itemId: row.readTable(target).id,
            rawText: row.readTable(target).rawText,
            status: row.readTable(target).status,
            trashed: row.readTable(target).deletedAt != null,
            label: row.readTable(link).label,
          ),
      ],
    );
  }

  @override
  Stream<List<ItemLinkPair>> watchAllLinks() => _db
      .customSelect(
        'SELECT l.from_item_id, l.to_item_id FROM item_links l '
        'JOIN items f ON f.id = l.from_item_id AND f.deleted_at IS NULL '
        'JOIN items t ON t.id = l.to_item_id AND t.deleted_at IS NULL '
        'WHERE l.kind = ?1 AND l.deleted_at IS NULL',
        variables: [Variable.withString(linkKind)],
        readsFrom: {_db.itemLinks, _db.items},
      )
      .watch()
      .map(
        (rows) => [
          for (final row in rows)
            (
              from: row.read<String>('from_item_id'),
              to: row.read<String>('to_item_id'),
            ),
        ],
      );

  @override
  Stream<List<LinkedItem>> watchBacklinks(String itemId) {
    final link = _db.itemLinks;
    final source = _db.items;
    final query =
        _db.select(link).join([
            innerJoin(source, source.id.equalsExp(link.fromItemId)),
          ])
          ..where(
            link.toItemId.equals(itemId) &
                link.deletedAt.isNull() &
                source.deletedAt.isNull(),
          )
          ..orderBy([OrderingTerm.desc(source.id)]);
    return query.watch().map((rows) {
      final seen = <String>{};
      return [
        for (final row in rows)
          if (seen.add(row.readTable(source).id))
            LinkedItem(
              itemId: row.readTable(source).id,
              rawText: row.readTable(source).rawText,
              status: row.readTable(source).status,
              trashed: false,
            ),
      ];
    });
  }

  @override
  Stream<Set<String>> watchUnlinkedLabels(String itemId) {
    final query = _db.select(_db.tokens)
      ..where(
        (t) =>
            t.itemId.equals(itemId) &
            t.tokenType.equals(linkKind) &
            t.resolvedValue.isNull(),
      );
    return query.watch().map(
      (rows) => {for (final row in rows) linkKey(row.rawValue)},
    );
  }

  @override
  Future<bool> areLinked(String a, String b) async {
    final found =
        await (_db.select(_db.itemLinks)
              ..where(
                (link) =>
                    link.deletedAt.isNull() &
                    ((link.fromItemId.equals(a) & link.toItemId.equals(b)) |
                        (link.fromItemId.equals(b) & link.toItemId.equals(a))),
              )
              ..limit(1))
            .get();
    return found.isNotEmpty;
  }
}
