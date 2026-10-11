import 'item_enums.dart';

/// Which statuses an item may move to (REQ-018, DD-018 point 1). The inbox
/// is where items arrive, never a place to move back to. Archiving is
/// possible from every status but archived: "no longer relevant, kept"
/// does not require done (PO decision 01-10-2026, DD-018 point 8).
Set<ItemStatus> nextStatuses(ItemStatus from) => switch (from) {
  ItemStatus.inbox => const {
    ItemStatus.active,
    ItemStatus.waiting,
    ItemStatus.scheduled,
    ItemStatus.done,
    ItemStatus.archived,
  },
  ItemStatus.active => const {
    ItemStatus.waiting,
    ItemStatus.scheduled,
    ItemStatus.done,
    ItemStatus.archived,
  },
  ItemStatus.waiting => const {
    ItemStatus.active,
    ItemStatus.scheduled,
    ItemStatus.done,
    ItemStatus.archived,
  },
  ItemStatus.scheduled => const {
    ItemStatus.active,
    ItemStatus.waiting,
    ItemStatus.done,
    ItemStatus.archived,
  },
  ItemStatus.done => const {ItemStatus.active, ItemStatus.archived},
  ItemStatus.archived => const {ItemStatus.active},
};

/// The one button for the logical next step: complete an open item, reopen
/// one that is done or archived.
ItemStatus primaryNextStatus(ItemStatus from) => switch (from) {
  ItemStatus.done || ItemStatus.archived => ItemStatus.active,
  _ => ItemStatus.done,
};

/// Types offered when classifying: all of them. A thought is an idea
/// (SPEC Q20).
const selectableItemTypes = [
  ItemType.task,
  ItemType.request,
  ItemType.idea,
  ItemType.note,
];
