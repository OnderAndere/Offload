import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:offload/data/database/app_database.dart';
import 'package:offload/data/export/drift_export_repository.dart';
import 'package:offload/data/items/drift_item_repository.dart';
import 'package:offload/data/people/drift_people_repository.dart';
import 'package:offload/data/projects/drift_project_repository.dart';
import 'package:offload/data/snapshots/drift_snapshot_repository.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/domain/export/export_json.dart';
import 'package:offload/domain/export/export_markdown.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/domain/people/contact_detail.dart';
import 'package:offload/domain/snapshots/snapshot.dart';
import 'package:offload/domain/time/local_date.dart';
import 'package:offload/domain/tokens/token_processing.dart';
import 'package:offload/l10n/app_localizations.dart';
import 'package:offload/presentation/backup/export_labels.dart';

import '../../fakes/test_storage.dart';

/// Reading everything for the export (T7.3, REQ-014): outside the trash.
void main() {
  late AppStorage storage;
  late DriftItemRepository items;

  // The Markdown labels format dates outside a widget test.
  setUpAll(() => initializeDateFormatting('en'));

  setUp(() async {
    storage = await openTestStorage();
    items = DriftItemRepository(storage);
  });
  tearDown(() => storage.close());

  AppDatabase db() => storage.database;

  test('everything outside the trash, and what hangs on the trash stays '
      'out', () async {
    final kept = await items.capture(
      'Offerte kozijnen',
      source: ItemSource.app,
    );
    final trashed = await items.capture('Weg ermee', source: ItemSource.app);
    final project = await DriftProjectRepository(storage).create('Verbouwing');
    final archived = await DriftProjectRepository(storage).create('Tuin');
    await DriftProjectRepository(storage).archive(archived);
    final notes = DriftSnapshotRepository(storage);
    await notes.save(ItemSnapshotOwner(kept), nextStep: 'Prijzen');
    await notes.save(ItemSnapshotOwner(trashed), nextStep: 'Niet mee');
    await notes.save(ProjectSnapshotOwner(project), inMind: 'Budget');
    final writer = storage.writer;
    final person = await writer.insert(
      db().people,
      const PeopleCompanion(
        name: Value('Олена'),
        birthdayDay: Value(4),
        birthdayMonth: Value(5),
      ),
    );
    await writer.insert(
      db().personAliases,
      PersonAliasesCompanion(
        personId: Value(person),
        alias: const Value('Lena'),
      ),
    );
    await writer.insert(
      db().contactDetails,
      ContactDetailsCompanion(
        personId: Value(person),
        kind: const Value(ContactKind.email),
        value: const Value('olena@example.org'),
        sortOrder: const Value(0),
      ),
    );
    for (final to in [kept, trashed]) {
      await writer.insert(
        db().itemLinks,
        ItemLinksCompanion(
          fromItemId: Value(kept),
          toItemId: Value(to),
          kind: const Value('link'),
        ),
      );
    }
    await writer.insert(
      db().itemCompletions,
      ItemCompletionsCompanion(
        itemId: Value(trashed),
        occurrenceOn: Value(dateOnlyToStored(LocalDate(2026, 10, 1))),
        completedOn: Value(dateOnlyToStored(LocalDate(2026, 10, 1))),
      ),
    );
    await items.moveToTrash(trashed);

    final data = await DriftExportRepository(storage).read();

    expect([for (final i in data.items) i.rawText], ['Offerte kozijnen']);
    expect({for (final p in data.projects) p.name}, {'Verbouwing', 'Tuin'});
    expect(
      data.projects.singleWhere((p) => p.id == archived).isArchived,
      isTrue,
    );
    final olena = data.people.single.person;
    expect(olena.name, 'Олена');
    expect(olena.aliases, ['Lena']);
    expect((olena.birthday?.day, olena.birthday?.month), (4, 5));
    expect(data.contactDetails.single.value, 'olena@example.org');
    expect(data.links.single.toItemId, kept);
    expect(data.completions, isEmpty);
    expect(
      {for (final n in data.notes) n.nextStep ?? n.inMind},
      {'Prijzen', 'Budget'},
    );
    expect(data.notes.every((n) => n.savedAt != null), isTrue);
  });

  test('a merged person stays, so an item restored after the merge still '
      'names someone (review)', () async {
    final writer = storage.writer;
    final from = await writer.insert(
      db().people,
      const PeopleCompanion(name: Value('Jantje')),
    );
    final into = await writer.insert(
      db().people,
      const PeopleCompanion(name: Value('Jan Jansen')),
    );
    final item = await items.capture('Fiets lenen', source: ItemSource.app);
    await items.setRequester(item, from);
    // In the trash during the merge: not re-pointed.
    await items.moveToTrash(item);
    await DriftPeopleRepository(storage).merge(from, into);
    await items.restoreFromTrash(item);

    final data = await DriftExportRepository(storage).read();

    expect(data.items.single.requesterId, from);
    final merged = data.people.singleWhere((p) => p.person.id == from);
    expect(merged.mergedIntoId, into);

    final json = exportJson(
      data,
      exportedAt: DateTime.utc(2026, 10, 9),
      appVersion: null,
    );
    expect(json, contains('"mergedIntoId": "$into"'));
    final markdown = exportMarkdown(
      data,
      L10nExportLabels(lookupAppLocalizations(const Locale('en'))),
      exportedAt: DateTime.utc(2026, 10, 9),
    );
    expect(markdown, contains('requested by Jan Jansen'));
    // Listed once, under the name it was merged into.
    expect(markdown, isNot(contains('### Jantje')));
  });
}
