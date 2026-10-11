import 'item.dart';
import 'item_enums.dart';

/// Type, status, people and revisit date of an item: what triage sets, and
/// what an undo puts back.
class ItemClassification {
  const ItemClassification({
    required this.type,
    required this.status,
    required this.requesterId,
    required this.waitingOnId,
    this.revisitAt,
  });

  /// The classification [item] has now.
  factory ItemClassification.of(Item item) => ItemClassification(
    type: item.type,
    status: item.status,
    requesterId: item.requesterId,
    waitingOnId: item.waitingOnId,
    revisitAt: item.revisitAt,
  );

  final ItemType? type;
  final ItemStatus status;
  final String? requesterId;
  final String? waitingOnId;

  /// "Revisit on" (REQ-021): kept by triage, put back by an undo of
  /// parking, completing or archiving a parked item.
  final DateTime? revisitAt;

  @override
  bool operator ==(Object other) =>
      other is ItemClassification &&
      other.type == type &&
      other.status == status &&
      other.requesterId == requesterId &&
      other.waitingOnId == waitingOnId &&
      other.revisitAt == revisitAt;

  @override
  int get hashCode =>
      Object.hash(type, status, requesterId, waitingOnId, revisitAt);
}
