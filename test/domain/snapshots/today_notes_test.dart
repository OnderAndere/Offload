import 'package:flutter_test/flutter_test.dart';
import 'package:offload/domain/items/item.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/domain/projects/project.dart';
import 'package:offload/domain/snapshots/snapshot.dart';
import 'package:offload/domain/snapshots/today_notes.dart';
import 'package:offload/domain/time/local_date.dart';
import 'package:offload/domain/tokens/token_processing.dart';

/// The "Where was I" notes on Today (T4b.2, DD-018 point 13 (e)).
void main() {
  final today = LocalDate(2026, 10, 9);
  var nextId = 0;

  Item item(
    String id, {
    ItemStatus status = ItemStatus.active,
    LocalDate? revisit,
  }) => Item(
    id: id,
    rawText: id,
    status: status,
    source: ItemSource.app,
    revisitAt: revisit == null ? null : dateOnlyToStored(revisit),
  );

  Snapshot note(SnapshotOwner owner, {DateTime? savedAt}) => Snapshot(
    // Ids that sort in the order the notes were made, like UUIDv7.
    id: 'note-${(nextId++).toString().padLeft(4, '0')}',
    owner: owner,
    nextStep: 'next',
    savedAt: savedAt,
  );

  DateTime at(int hour) => DateTime.utc(2026, 10, 9, hour);

  List<String> owners(List<TodayNote> notes) => [
    for (final n in notes) n.item?.id ?? n.project!.id,
  ];

  test('newest first; items and projects together', () {
    final shown = notesForToday(
      [
        note(const ItemSnapshotOwner('kozijnen'), savedAt: at(8)),
        note(const ProjectSnapshotOwner('verbouwing'), savedAt: at(10)),
        note(const ItemSnapshotOwner('tuinplan'), savedAt: at(9)),
      ],
      items: [item('kozijnen'), item('tuinplan')],
      projects: const [Project(id: 'verbouwing', name: 'Verbouwing')],
      today: today,
    );
    expect(owners(shown), ['verbouwing', 'tuinplan', 'kozijnen']);
    expect(shown.first.item, isNull);
    expect(shown.last.project, isNull);
  });

  test('only notes of live items: not done, archived, parked or in the '
      'trash', () {
    final shown = notesForToday(
      [
        for (final id in [
          'open',
          'done',
          'archived',
          'parked',
          'back today',
          'in the trash',
          'inbox',
        ])
          note(ItemSnapshotOwner(id), savedAt: at(8)),
      ],
      items: [
        item('open'),
        item('done', status: ItemStatus.done),
        item('archived', status: ItemStatus.archived),
        item('parked', status: ItemStatus.scheduled, revisit: today.addDays(3)),
        // Due back today: no longer away, so shown.
        item('back today', status: ItemStatus.scheduled, revisit: today),
        item('inbox', status: ItemStatus.inbox),
        // 'in the trash' is not among the items outside the trash.
      ],
      projects: const [],
      today: today,
    );
    expect(owners(shown), ['inbox', 'back today', 'open']);
  });

  test('only notes of live projects: not archived or in the trash', () {
    final shown = notesForToday(
      [
        note(const ProjectSnapshotOwner('live'), savedAt: at(8)),
        note(const ProjectSnapshotOwner('archived'), savedAt: at(9)),
        note(const ProjectSnapshotOwner('gone'), savedAt: at(10)),
      ],
      items: const [],
      projects: [
        const Project(id: 'live', name: 'Live'),
        Project(id: 'archived', name: 'Old', archivedAt: at(7)),
      ],
      today: today,
    );
    expect(owners(shown), ['live']);
  });

  test('no age limit; a note without a readable time comes last', () {
    final shown = notesForToday(
      [
        note(const ItemSnapshotOwner('unknown')),
        note(const ItemSnapshotOwner('old'), savedAt: DateTime.utc(2025, 1, 1)),
        note(const ItemSnapshotOwner('new'), savedAt: at(8)),
      ],
      items: [item('unknown'), item('old'), item('new')],
      projects: const [],
      today: today,
    );
    expect(owners(shown), ['new', 'old', 'unknown']);
  });

  test('saved at the same moment: the note made later first', () {
    final shown = notesForToday(
      [
        note(const ItemSnapshotOwner('first'), savedAt: at(8)),
        note(const ItemSnapshotOwner('second'), savedAt: at(8)),
      ],
      items: [item('first'), item('second')],
      projects: const [],
      today: today,
    );
    expect(owners(shown), ['second', 'first']);
  });
}
