/// "Where was I" (T10.3, REQ-049, DD-018 point 13): on a switch of
/// context, the next step and what I had in mind, on an item or a project.
library;

/// What a note is about: an item or a project, never both.
sealed class SnapshotOwner {
  const SnapshotOwner();
}

final class ItemSnapshotOwner extends SnapshotOwner {
  const ItemSnapshotOwner(this.itemId);

  final String itemId;

  @override
  bool operator ==(Object other) =>
      other is ItemSnapshotOwner && other.itemId == itemId;

  @override
  int get hashCode => Object.hash(ItemSnapshotOwner, itemId);
}

final class ProjectSnapshotOwner extends SnapshotOwner {
  const ProjectSnapshotOwner(this.projectId);

  final String projectId;

  @override
  bool operator ==(Object other) =>
      other is ProjectSnapshotOwner && other.projectId == projectId;

  @override
  int get hashCode => Object.hash(ProjectSnapshotOwner, projectId);
}

/// An open note: at least one of [nextStep] and [inMind] is set.
class Snapshot {
  const Snapshot({
    required this.id,
    required this.owner,
    this.nextStep,
    this.inMind,
    this.savedAt,
  });

  final String id;
  final SnapshotOwner owner;
  final String? nextStep;
  final String? inMind;

  /// When it was last saved or updated: the time of its HLC; the "how
  /// long ago" on the resume card counts from here (PO 02-10-2026).
  final DateTime? savedAt;
}

/// The text of a note as stored: trimmed, an empty field null; null when
/// both are empty, which saves nothing (DD-018 point 13 (b)).
({String? nextStep, String? inMind})? snapshotText(
  String? nextStep,
  String? inMind,
) {
  String? clean(String? text) {
    final trimmed = text?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  final next = clean(nextStep);
  final mind = clean(inMind);
  if (next == null && mind == null) return null;
  return (nextStep: next, inMind: mind);
}

/// Stores the notes (DD-018 point 13).
abstract interface class SnapshotRepository {
  /// The open note of [owner], or null. With more than one open (two
  /// devices, after a sync), the one saved last.
  Stream<Snapshot?> watchOpen(SnapshotOwner owner);

  /// Every open note, one per item or project (the one saved last), for
  /// *Today* (T4b.2). Notes of items or projects in the trash are included;
  /// [notesForToday] leaves them out.
  Stream<List<Snapshot>> watchAllOpen();

  /// The open note of [owner] now, read once (the form fills in from it).
  Future<Snapshot?> open(SnapshotOwner owner);

  /// Saves the note of [owner]: updates the open one, or starts a new one.
  /// Both fields empty resumes the open one instead (PO 02-10-2026).
  /// Saving on an item counts as touching it (point 13 (f)).
  Future<void> save(SnapshotOwner owner, {String? nextStep, String? inMind});

  /// Resumes the open note of [owner] (every one, should a sync have made
  /// two): the card goes; the note stays as history. Not a touch.
  Future<void> resume(SnapshotOwner owner);
}
