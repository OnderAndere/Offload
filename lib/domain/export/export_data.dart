/// Export to Markdown and JSON (T7.3, REQ-014, DD-007): everything the user
/// made, outside the trash, read once. Unencrypted by nature: only on the
/// user's explicit action, after a warning.
library;

import '../items/item.dart';
import '../people/contact_detail.dart';
import '../people/person.dart';
import '../projects/project.dart';
import '../time/local_date.dart';

/// A link between two items: a `[[…]]` link (DD-004 point 13), or another
/// kind.
class ExportLink {
  const ExportLink({
    required this.fromItemId,
    required this.toItemId,
    required this.kind,
    this.label,
  });

  final String fromItemId;
  final String toItemId;

  /// `link` for a `[[…]]` link; other kinds (the conflict copy of DD-013)
  /// have no label.
  final String kind;

  /// The text between the brackets when the link was chosen.
  final String? label;
}

/// One completed time of a recurring task (REQ-061).
class ExportCompletion {
  const ExportCompletion({
    required this.itemId,
    required this.occurrenceOn,
    required this.completedOn,
  });

  final String itemId;
  final LocalDate occurrenceOn;
  final LocalDate completedOn;
}

/// A "Where was I" note (REQ-049), open or resumed: on an item or a
/// project, never both.
class ExportNote {
  const ExportNote({
    required this.id,
    this.itemId,
    this.projectId,
    this.nextStep,
    this.inMind,
    this.savedAt,
    this.resumedAt,
  });

  final String id;
  final String? itemId;
  final String? projectId;
  final String? nextStep;
  final String? inMind;

  /// When it was last saved: the time of its HLC, in UTC.
  final DateTime? savedAt;

  /// When it was resumed; null while it is open.
  final DateTime? resumedAt;

  bool get isOpen => resumedAt == null;
}

/// A person as exported: the profile, and where a merge sent them.
class ExportPerson {
  const ExportPerson({required this.person, this.mergedIntoId});

  final Person person;

  /// The person this one was merged into (DD-015); items may still name
  /// the merged person, so it stays in the export with this reference.
  final String? mergedIntoId;
}

/// Everything to export, outside the trash (PO 09-10-2026): items in every
/// status, projects (archived ones too), people with their contact details,
/// links, completions and notes. Not the sync internals (HLC, change log,
/// tombstones), the derived tokens or the device's own settings.
class ExportData {
  const ExportData({
    required this.items,
    required this.projects,
    required this.people,
    required this.contactDetails,
    required this.links,
    required this.completions,
    required this.notes,
  });

  final List<Item> items;
  final List<Project> projects;
  final List<ExportPerson> people;
  final List<ContactDetail> contactDetails;
  final List<ExportLink> links;
  final List<ExportCompletion> completions;
  final List<ExportNote> notes;
}

/// Reads [ExportData] in one go.
abstract interface class ExportRepository {
  Future<ExportData> read();
}
