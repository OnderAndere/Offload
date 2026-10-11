import 'package:drift/drift.dart';
import 'package:drift/internal/versioned_schema.dart'
    show MigrationStepWithVersion;

import '../../domain/items/item_enums.dart';
import '../../domain/people/contact_detail.dart';
import '../../domain/sync/change_operation.dart';
import 'app_database.steps.dart';
import 'tables.dart';

part 'app_database.g.dart';

/// The Offload database. The [QueryExecutor] is injected so that the data
/// layer decides how the file is opened and encrypted (T1.4, DD-007); tests
/// use an in-memory executor.
@DriftDatabase(
  tables: [
    Items,
    People,
    PersonAliases,
    ContactDetails,
    Contexts,
    Tags,
    Attachments,
    ItemLinks,
    ItemCompletions,
    DuplicateDismissals,
    Snapshots,
    Tokens,
    ChangeLog,
    LocalState,
  ],
  include: {'search.drift'},
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// The schema version of this app, also for code without a database.
  static const currentSchemaVersion = 13;

  @override
  int get schemaVersion => currentSchemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    // Drift does not run migrations in a transaction. Stopped halfway, a
    // step would leave objects behind while the version stays old, and every
    // later start would fail on them. So all steps and the new version are
    // committed together, or nothing is (review T2.5).
    onUpgrade: (m, from, to) => transaction(() async {
      await m.runMigrationSteps(from: from, to: to, steps: _steps);
      await customStatement('PRAGMA user_version = $to');
    }),
    beforeOpen: (details) async {
      // SQLite leaves foreign keys off per connection unless enabled.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  MigrationStepWithVersion get _steps => migrationSteps(
    // Full-text search (T2.5, DD-016): the index, its map and queue, and
    // the triggers that fill the queue. Every live item and person goes
    // into the queue, so the indexer fills the index after start.
    from1To2: (m, schema) async {
      await m.create(schema.searchIndex);
      await m.create(schema.searchMap);
      await m.create(schema.searchPending);
      for (final trigger in [
        schema.itemsSearchInsert,
        schema.itemsSearchUpdate,
        schema.peopleSearchInsert,
        schema.peopleSearchUpdate,
        schema.personAliasesSearchInsert,
        schema.personAliasesSearchUpdate,
      ]) {
        await m.create(trigger);
      }
      await queueEverythingForSearch();
    },
    // Ignored pairs of the duplicate hint (T2.5 step C, AC REQ-053): a synchronised
    // table, created empty.
    from2To3: (m, schema) async {
      await m.create(schema.duplicateDismissals);
      await m.create(schema.duplicateDismissalsItemId);
      await m.create(schema.duplicateDismissalsOtherId);
    },
    // Archived projects (T3.1, DD-018 point 6): a nullable column, empty
    // for every existing project.
    from3To4: (m, schema) async {
      await m.addColumn(schema.contexts, schema.contexts.archivedAt);
    },
    // Merged people (T3.2b, DD-015): a nullable column, empty for every
    // existing person.
    from4To5: (m, schema) async {
      await m.addColumn(schema.people, schema.people.mergedIntoId);
    },
    // The weekly review (T3.4/T10.6, AC REQ-051): a nullable column, empty
    // for every existing item.
    from5To6: (m, schema) async {
      await m.addColumn(schema.items, schema.items.reviewedAt);
    },
    // Contact details (T3.5, REQ-038, DD-012): a new synchronisable table,
    // created empty, and two nullable columns on people. The search trigger
    // of people watches the new columns, so it is made again; contact
    // details get triggers of their own.
    from6To7: (m, schema) async {
      await m.addColumn(schema.people, schema.people.organisation);
      await m.addColumn(schema.people, schema.people.jobTitle);
      await m.create(schema.contactDetails);
      await m.create(schema.contactDetailsPersonId);
      await m.drop(schema.peopleSearchUpdate);
      await m.create(schema.peopleSearchUpdate);
      await m.create(schema.contactDetailsSearchInsert);
      await m.create(schema.contactDetailsSearchUpdate);
    },
    // Priority (T10.5, REQ-050): a nullable column, empty for every existing
    // item. The token processor fills it after the start, because the new
    // parser version processes every item again (DD-004 point 1).
    from7To8: (m, schema) async {
      await m.addColumn(schema.items, schema.items.priority);
    },
    // Commitments (T10.1, REQ-046, REQ-047): three nullable columns, empty
    // for every existing item (asked on = the capture day, promised = the
    // title, no expected date).
    from8To9: (m, schema) async {
      await m.addColumn(schema.items, schema.items.askedAt);
      await m.addColumn(schema.items, schema.items.promise);
      await m.addColumn(schema.items, schema.items.expectedAt);
    },
    // "Where was I" (T10.3, REQ-049): a new synchronisable table, created
    // empty.
    from9To10: (m, schema) async {
      await m.create(schema.snapshots);
      await m.create(schema.snapshotsItemId);
      await m.create(schema.snapshotsContextId);
    },
    // Links between items (T10.9, REQ-054): the label of a `[[…]]`, a
    // nullable column; the table had no rows yet. The new parser version
    // processes every item again, so texts with `[[…]]` link by first line.
    from10To11: (m, schema) async {
      await m.addColumn(schema.itemLinks, schema.itemLinks.label);
    },
    // Recurring tasks (T4.7, REQ-061): a new synchronisable table, created
    // empty. The new parser version processes every item again, so texts
    // with a repeat word get their series date.
    from11To12: (m, schema) async {
      await m.create(schema.itemCompletions);
      await m.create(schema.itemCompletionsItemId);
    },
    // No table changes (T7.2b, DD-007 "Backup with attachments" point 6): a
    // backup can now carry attachments, so an app from before refuses it as
    // "made with a newer version" instead of restoring it without files.
    from12To13: (m, schema) async {},
  );

  /// Puts every live item and person in the search queue: after the
  /// migration and when the index is rebuilt (DD-016).
  Future<void> queueEverythingForSearch() async {
    await customStatement(
      "INSERT OR IGNORE INTO search_pending (entity, entity_id) "
      "SELECT 'items', id FROM items WHERE deleted_at IS NULL",
    );
    await customStatement(
      "INSERT OR IGNORE INTO search_pending (entity, entity_id) "
      "SELECT 'people', id FROM people WHERE deleted_at IS NULL",
    );
  }
}
