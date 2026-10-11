import '../items/item.dart';
import '../items/item_enums.dart';
import '../time/local_date.dart';
import '../tokens/token_processing.dart';
import 'project_tree.dart';

/// Whether an item counts as open in the project list (DD-018 point 6): not
/// done, not archived, and not a note, since action lists do not show notes
/// (AC REQ-010).
bool countsAsOpen(Item item) =>
    item.status != ItemStatus.done &&
    item.status != ItemStatus.archived &&
    item.type != ItemType.note;

/// Whether [item] has a deadline before [today].
bool isOverdue(Item item, LocalDate today) {
  final due = item.dueAt;
  return due != null && storedToDateOnly(due).compareTo(today) < 0;
}

/// The counts on a row of the project list.
typedef ProjectCount = ({int open, int overdue});

/// Open and overdue items per project id; the key null is *Without
/// project*, which also takes items of a project that no longer exists. A
/// top-level project counts its sub-projects too (PO: to be judged in use).
Map<String?, ProjectCount> projectCounts(
  Iterable<Item> items,
  ProjectTree tree,
  LocalDate today,
) {
  final open = <String?, int>{};
  final overdue = <String?, int>{};
  void add(String? key, bool late) {
    open[key] = (open[key] ?? 0) + 1;
    if (late) overdue[key] = (overdue[key] ?? 0) + 1;
  }

  for (final item in items) {
    if (!countsAsOpen(item)) continue;
    final late = isOverdue(item, today);
    final project = item.projectId == null ? null : tree[item.projectId!];
    if (project == null) {
      add(null, late);
      continue;
    }
    add(project.id, late);
    if (project.parentId case final parent?) add(parent, late);
  }
  return {
    for (final key in open.keys)
      key: (open: open[key]!, overdue: overdue[key] ?? 0),
  };
}

/// The groups of a project screen, in the order they are shown (DD-018
/// point 6).
enum ProjectGroup { inbox, active, waiting, scheduled, notes, done }

/// [items] of one project by group, keeping their order; only groups with
/// items. Notes that are not done form a group of their own; done items,
/// notes included, go to [ProjectGroup.done]; archived items are left out.
Map<ProjectGroup, List<Item>> groupProjectItems(Iterable<Item> items) {
  final groups = <ProjectGroup, List<Item>>{};
  for (final item in items) {
    final group = switch (item.status) {
      ItemStatus.archived => null,
      ItemStatus.done => ProjectGroup.done,
      _ when item.type == ItemType.note => ProjectGroup.notes,
      ItemStatus.inbox => ProjectGroup.inbox,
      ItemStatus.active => ProjectGroup.active,
      ItemStatus.waiting => ProjectGroup.waiting,
      ItemStatus.scheduled => ProjectGroup.scheduled,
    };
    if (group != null) groups.putIfAbsent(group, () => []).add(item);
  }
  return {for (final group in ProjectGroup.values) group: ?groups[group]};
}
