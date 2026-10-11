import '../items/item.dart';
import '../items/item_enums.dart';
import '../time/local_date.dart';
import 'person_balance.dart';

/// Whether [item] waits on someone now: status waiting (DD-018 point 7).
/// `waitingOnId` stays after the wait ends; then it only says who it was.
bool isWaitingNow(Item item) => item.status == ItemStatus.waiting;

/// The items linked to a person, and which of them name the person in
/// their text (`ItemRepository.watchPersonItems`).
typedef PersonItems = ({List<Item> items, Set<String> mentionedIds});

/// The lists of a person screen, in the order they are shown (DD-018 point
/// 7).
enum PersonList { requestedBy, waitingFor, mentionedIn }

/// One list of a person: its open part and its done part (folded).
typedef PersonListItems = ({List<Item> open, List<Item> done});

/// The items linked to person [personId], split into the lists of the
/// person screen; only lists with items. [mentionedIds] are the items whose
/// text names the person (stored person tokens). One item can be in both
/// [PersonList.requestedBy] and [PersonList.waitingFor]; an item is in
/// [PersonList.mentionedIn] only when it is in neither. Archived items are
/// left out. Each part is ordered by [personListOrder]; with [today] the
/// open parts of *Requested by* and *Waiting for* follow the 1-on-1
/// preparation instead (`preparationOrder`, DD-018 point 11).
Map<PersonList, PersonListItems> personLists(
  String personId,
  Iterable<Item> items,
  Set<String> mentionedIds, {
  LocalDate? today,
}) {
  final open = {for (final list in PersonList.values) list: <Item>[]};
  final done = {for (final list in PersonList.values) list: <Item>[]};
  for (final item in items) {
    if (item.status == ItemStatus.archived) continue;
    final isDone = item.status == ItemStatus.done;
    var listed = false;
    if (item.requesterId == personId) {
      (isDone ? done : open)[PersonList.requestedBy]!.add(item);
      listed = true;
    }
    if (item.waitingOnId == personId && (isDone || isWaitingNow(item))) {
      (isDone ? done : open)[PersonList.waitingFor]!.add(item);
      listed = true;
    }
    if (!listed && mentionedIds.contains(item.id)) {
      (isDone ? done : open)[PersonList.mentionedIn]!.add(item);
    }
  }
  Comparator<Item> openOrder(PersonList list) =>
      today == null || list == PersonList.mentionedIn
      ? personListOrder
      : preparationOrder(today, waiting: list == PersonList.waitingFor);
  return {
    for (final list in PersonList.values)
      if (open[list]!.isNotEmpty || done[list]!.isNotEmpty)
        list: (
          open: open[list]!..sort(openOrder(list)),
          done: done[list]!..sort(personListOrder),
        ),
  };
}

/// Items with a deadline first, earliest first; then the rest, newest
/// capture first (DD-018 point 7).
int personListOrder(Item a, Item b) {
  final dueA = a.dueAt;
  final dueB = b.dueAt;
  if (dueA != null && dueB != null) {
    final byDue = dueA.compareTo(dueB);
    return byDue != 0 ? byDue : a.id.compareTo(b.id);
  }
  if (dueA != null) return -1;
  if (dueB != null) return 1;
  return b.id.compareTo(a.id);
}
