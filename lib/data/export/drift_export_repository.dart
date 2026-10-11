import 'package:drift/drift.dart';

import '../../domain/export/export_data.dart';
import '../../domain/people/birthday.dart';
import '../../domain/people/contact_detail.dart';
import '../../domain/people/person.dart';
import '../../domain/projects/project.dart';
import '../../domain/sync/hlc.dart';
import '../../domain/tokens/token_processing.dart';
import '../database/app_database.dart';
import '../items/drift_item_repository.dart';
import '../storage/app_storage.dart';

/// Reads everything for the export (T7.3, REQ-014) in one transaction, so
/// the files show one moment: every row outside the trash (no tombstone),
/// and the merged people, whose names items may still use.
class DriftExportRepository implements ExportRepository {
  DriftExportRepository(this._storage);

  final AppStorage _storage;

  AppDatabase get _db => _storage.database;

  @override
  Future<ExportData> read() => _db.transaction(() async {
    final items = await (_db.select(
      _db.items,
    )..where((i) => i.deletedAt.isNull())).get();
    final projects = await (_db.select(
      _db.contexts,
    )..where((c) => c.deletedAt.isNull())).get();
    // Merged people too: a merge tombstones them, but an item restored
    // from the trash, or from a sync, may still name one (review).
    final people =
        await (_db.select(_db.people)..where(
              (p) =>
                  p.deletedAt.isNull() |
                  (p.deletedAt.isNotNull() & p.mergedIntoId.isNotNull()),
            ))
            .get();
    final aliases = await (_db.select(
      _db.personAliases,
    )..where((a) => a.deletedAt.isNull())).get();
    final details = await (_db.select(
      _db.contactDetails,
    )..where((c) => c.deletedAt.isNull())).get();
    final links = await (_db.select(
      _db.itemLinks,
    )..where((l) => l.deletedAt.isNull())).get();
    final completions = await (_db.select(
      _db.itemCompletions,
    )..where((c) => c.deletedAt.isNull())).get();
    final notes = await (_db.select(
      _db.snapshots,
    )..where((s) => s.deletedAt.isNull())).get();

    // Links, completions and notes only of what is exported: not of an item
    // or project in the trash.
    final itemIds = {for (final item in items) item.id};
    final projectIds = {for (final project in projects) project.id};
    final personIds = {for (final person in people) person.id};
    final aliasesOf = <String, List<String>>{};
    for (final alias in aliases) {
      aliasesOf.putIfAbsent(alias.personId, () => []).add(alias.alias);
    }
    return ExportData(
      items: [for (final row in items) DriftItemRepository.itemOf(row)],
      projects: [
        for (final row in projects)
          Project(
            id: row.id,
            name: row.name,
            parentId: row.parentId,
            archivedAt: row.archivedAt,
          ),
      ],
      people: [
        for (final row in people)
          ExportPerson(
            person: Person(
              id: row.id,
              name: row.name,
              aliases: [...?aliasesOf[row.id]]..sort(),
              birthday: row.birthdayDay == null || row.birthdayMonth == null
                  ? null
                  : Birthday.tryCreate(
                      row.birthdayDay!,
                      row.birthdayMonth!,
                      row.birthdayYear,
                    ),
              note: row.note,
              organisation: row.organisation,
              jobTitle: row.jobTitle,
            ),
            mergedIntoId: row.mergedIntoId,
          ),
      ],
      contactDetails: [
        for (final row in details)
          if (personIds.contains(row.personId))
            ContactDetail(
              id: row.id,
              personId: row.personId,
              kind: row.kind,
              value: row.value,
              label: row.label,
              sortOrder: row.sortOrder,
            ),
      ],
      links: [
        for (final row in links)
          if (itemIds.contains(row.fromItemId) &&
              itemIds.contains(row.toItemId))
            ExportLink(
              fromItemId: row.fromItemId,
              toItemId: row.toItemId,
              kind: row.kind,
              label: row.label,
            ),
      ],
      completions: [
        for (final row in completions)
          if (itemIds.contains(row.itemId))
            ExportCompletion(
              itemId: row.itemId,
              occurrenceOn: storedToDateOnly(row.occurrenceOn),
              completedOn: storedToDateOnly(row.completedOn),
            ),
      ],
      notes: [
        for (final row in notes)
          if (itemIds.contains(row.itemId) ||
              projectIds.contains(row.contextId))
            ExportNote(
              id: row.id,
              itemId: row.itemId,
              projectId: row.contextId,
              nextStep: row.nextStep,
              inMind: row.inMind,
              savedAt: hlcTime(row.hlc),
              resumedAt: row.resumedAt,
            ),
      ],
    );
  });
}
