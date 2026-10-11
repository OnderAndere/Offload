import '../ids/uuid_v7.dart';
import '../time/local_date.dart';
import 'item_enums.dart';

/// A captured item (SPEC.md section 7). Holds only the fields the app uses
/// so far; the others follow with their backlog items.
class Item {
  const Item({
    required this.id,
    required this.rawText,
    required this.status,
    required this.source,
    this.type,
    this.body,
    this.dueAt,
    this.requesterId,
    this.waitingOnId,
    this.projectId,
    this.revisitAt,
    this.changedAt,
    this.reviewedAt,
    this.priority,
    this.askedAt,
    this.promise,
    this.expectedAt,
  });

  final String id;

  /// The text as typed, at capture or later in the item detail; the source
  /// of truth for tokens (DD-004, DD-018). The app never changes it.
  final String rawText;

  /// Free note under the text (Markdown later), or null.
  final String? body;

  /// Deadline, worked out from the first date in [rawText] (DD-018).
  final DateTime? dueAt;

  /// Who asked for this (a person id; REQ-012, chosen in triage).
  final String? requesterId;

  /// Who this is waiting on (a person id; REQ-012, chosen in triage).
  final String? waitingOnId;

  /// The project it belongs to, or null (DD-018 point 6).
  final String? projectId;

  /// "Revisit on": when it comes back to the inbox (REQ-021, T4.2).
  final DateTime? revisitAt;

  /// When it last changed: the physical time in its HLC (DD-003), in UTC.
  /// Read from the HLC, never stored separately (rule 6).
  final DateTime? changedAt;

  /// When the user last chose *Keep* or *Still waiting* in the weekly
  /// review (AC REQ-051), in UTC.
  final DateTime? reviewedAt;

  /// High, normal or low from `*hoog`, `*2`, `*laag` in [rawText]
  /// (REQ-050); null when the text has no priority.
  final ItemPriority? priority;

  /// The day it was asked, when set (REQ-046); see `askedOn`.
  final LocalDate? askedAt;

  /// What I promised, when set (REQ-046); else the title.
  final String? promise;

  /// For a waiting item: the day I expect it by (REQ-047).
  final LocalDate? expectedAt;

  /// The last touch: the later of [changedAt] and [reviewedAt] (AC
  /// REQ-051); opening does not count. Null when neither is known.
  DateTime? get lastTouch {
    final changed = changedAt;
    final reviewed = reviewedAt;
    if (changed == null) return reviewed;
    if (reviewed == null) return changed;
    return reviewed.isAfter(changed) ? reviewed : changed;
  }

  /// Null means "not classified yet" (REQ-018).
  final ItemType? type;
  final ItemStatus status;
  final ItemSource source;

  /// Moment of capture, read from the UUIDv7 [id]; not stored separately
  /// (CLAUDE.md rule 6). In UTC.
  DateTime get capturedAt => uuidV7Time(id);
}

/// Whether [rawText] may be captured: capturing needs only text (REQ-018),
/// but some text, not just white space.
bool hasCapturableText(String rawText) => rawText.trim().isNotEmpty;
