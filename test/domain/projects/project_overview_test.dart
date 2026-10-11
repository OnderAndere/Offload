import 'package:flutter_test/flutter_test.dart';
import 'package:offload/domain/items/item.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/domain/projects/project.dart';
import 'package:offload/domain/projects/project_overview.dart';
import 'package:offload/domain/projects/project_tree.dart';
import 'package:offload/domain/time/local_date.dart';
import 'package:offload/domain/tokens/token_processing.dart';

/// Counts and groups of the project screens (DD-018 point 6).
void main() {
  final today = LocalDate(2026, 9, 30);
  var next = 0;
  Item item({
    String? project,
    ItemStatus status = ItemStatus.active,
    ItemType? type = ItemType.task,
    LocalDate? due,
  }) => Item(
    // Any unique id: capturedAt is not used here.
    id: 'i${next++}',
    rawText: 'x',
    status: status,
    source: ItemSource.app,
    type: type,
    projectId: project,
    dueAt: due == null ? null : dateOnlyToStored(due),
  );

  final tree = ProjectTree([
    const Project(id: 'renovatie', name: 'Renovatie'),
    const Project(id: 'garden', name: 'Moestuin', parentId: 'renovatie'),
    const Project(id: 'team', name: 'Teamoverleg'),
  ]);

  group('projectCounts', () {
    test('counts open items; a parent includes its sub-projects', () {
      final counts = projectCounts(
        [
          item(project: 'renovatie'),
          item(project: 'garden', due: LocalDate(2026, 9, 29)),
          item(project: 'garden'),
          item(project: 'team', due: today),
          item(),
        ],
        tree,
        today,
      );

      expect(counts['renovatie'], (open: 3, overdue: 1));
      expect(counts['garden'], (open: 2, overdue: 1));
      expect(counts['team'], (open: 1, overdue: 0));
      expect(counts[null], (open: 1, overdue: 0));
    });

    test('leaves out done, archived and notes', () {
      final counts = projectCounts(
        [
          item(project: 'team', status: ItemStatus.done),
          item(project: 'team', status: ItemStatus.archived),
          item(project: 'team', type: ItemType.note),
          item(project: 'team', status: ItemStatus.inbox, type: null),
        ],
        tree,
        today,
      );

      expect(counts['team'], (open: 1, overdue: 0));
    });

    test('an item of a project that no longer exists is without project', () {
      expect(projectCounts([item(project: 'gone')], tree, today)[null], (
        open: 1,
        overdue: 0,
      ));
    });
  });

  group('groupProjectItems', () {
    test('groups by status in the order of the screen', () {
      final inbox = item(status: ItemStatus.inbox, type: null);
      final active = item();
      final waiting = item(status: ItemStatus.waiting);
      final later = item(status: ItemStatus.scheduled);
      final note = item(type: ItemType.note);
      final done = item(status: ItemStatus.done);
      final doneNote = item(status: ItemStatus.done, type: ItemType.note);
      final archived = item(status: ItemStatus.archived);

      final groups = groupProjectItems([
        done,
        note,
        archived,
        waiting,
        active,
        later,
        inbox,
        doneNote,
      ]);

      expect(groups.keys, [
        ProjectGroup.inbox,
        ProjectGroup.active,
        ProjectGroup.waiting,
        ProjectGroup.scheduled,
        ProjectGroup.notes,
        ProjectGroup.done,
      ]);
      expect(groups[ProjectGroup.notes], [note]);
      expect(groups[ProjectGroup.done], [done, doneNote]);
      expect(groups.values.expand((g) => g), isNot(contains(archived)));
    });

    test('only groups with items', () {
      expect(groupProjectItems([item()]).keys, [ProjectGroup.active]);
      expect(groupProjectItems([]), isEmpty);
    });
  });
}
