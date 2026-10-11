import '../time/local_date.dart';
import 'item_classification.dart';

/// What completing an item did (REQ-061, DD-018 point 18), so its undo can
/// put everything back exactly: a repeating item got a record of its time
/// and moved on to [nextDue]; any other item became done.
class Completion {
  const Completion({
    required this.itemId,
    required this.before,
    required this.dueBefore,
    this.recordId,
    this.nextDue,
    this.textBefore,
    this.textAfter,
  });

  final String itemId;

  /// Type, status, people and revisit date before completing.
  final ItemClassification before;

  /// The stored `due_at` before completing.
  final DateTime? dueBefore;

  /// The record of the completed time (a UUIDv5, `completionId`), or null
  /// when the item was simply done.
  final String? recordId;

  /// The next time of the series, or null when the item was simply done.
  final LocalDate? nextDue;

  /// The text before, when completing changed it (*Afronden en herhalen*
  /// added a repeat word, *Herhaling stoppen* removed it); undo writes it
  /// back as a new version.
  final String? textBefore;

  /// The text completing wrote: undo puts [textBefore] back only while the
  /// text is still this, so an edit made since is never overwritten.
  final String? textAfter;

  /// Whether a time of a series was completed, rather than the item.
  bool get repeated => recordId != null;
}
