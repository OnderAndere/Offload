import '../items/item.dart';
import '../items/revisit.dart';
import '../items/today.dart';
import '../projects/project.dart';
import '../time/local_date.dart';
import 'snapshot.dart';

/// An open note shown on *Today*, with what it is about: an [item] or a
/// [project], never both.
typedef TodayNote = ({Snapshot note, Item? item, Project? project});

/// The open "Where was I" notes for *Today* (T4b.2, DD-018 point 13 (e)):
/// those of a live item (open, not parked until after [today]; [items] are
/// the items outside the trash) or of a live project (not archived;
/// [projects] are the projects outside the trash). Newest first, no age
/// limit (PO 09-10-2026).
List<TodayNote> notesForToday(
  Iterable<Snapshot> notes, {
  required Iterable<Item> items,
  required Iterable<Project> projects,
  required LocalDate today,
}) {
  final itemsById = {for (final item in items) item.id: item};
  final projectsById = {for (final project in projects) project.id: project};
  final shown = <TodayNote>[];
  for (final note in notes) {
    switch (note.owner) {
      case ItemSnapshotOwner(:final itemId):
        final item = itemsById[itemId];
        if (item == null || !isOpen(item.status) || isParked(item, today)) {
          continue;
        }
        shown.add((note: note, item: item, project: null));
      case ProjectSnapshotOwner(:final projectId):
        final project = projectsById[projectId];
        if (project == null || project.isArchived) continue;
        shown.add((note: note, item: null, project: project));
    }
  }
  shown.sort((a, b) {
    final aAt = a.note.savedAt;
    final bAt = b.note.savedAt;
    if (aAt != null && bAt != null) {
      final byTime = bAt.compareTo(aAt);
      if (byTime != 0) return byTime;
    } else if (aAt != bAt) {
      // A note without a readable time last.
      return aAt == null ? 1 : -1;
    }
    // UUIDv7 ids sort by creation; the newer first.
    return b.note.id.compareTo(a.note.id);
  });
  return shown;
}
