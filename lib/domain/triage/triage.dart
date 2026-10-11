import '../items/item.dart';
import '../items/item_classification.dart';
import '../items/item_enums.dart';

/// Where triage sends an inbox card (REQ-010, AC REQ-010, DD-018 point 3).
/// The trash is a destination too, but it is a tombstone, not a
/// classification (DD-003).
enum TriageDestination { task, idea, request, waitingFor, note, trash }

/// The destinations that ask for a person, and which role they fill.
extension TriageDestinationPerson on TriageDestination {
  bool get asksForPerson =>
      this == TriageDestination.request || this == TriageDestination.waitingFor;
}

/// What sending [item] to [destination] sets (AC REQ-010): task, idea and
/// note become active with that type; a request becomes active with
/// [personId] as the requester; waiting for keeps the type and waits on
/// [personId]. Without a person the role stays as it was. Not for the
/// trash, which is no classification.
ItemClassification sortInto(
  Item item,
  TriageDestination destination, {
  String? personId,
}) {
  ItemClassification active(ItemType type) => ItemClassification(
    type: type,
    status: ItemStatus.active,
    requesterId: item.requesterId,
    waitingOnId: item.waitingOnId,
    revisitAt: item.revisitAt,
  );
  return switch (destination) {
    TriageDestination.task => active(ItemType.task),
    TriageDestination.idea => active(ItemType.idea),
    TriageDestination.note => active(ItemType.note),
    TriageDestination.request => ItemClassification(
      type: ItemType.request,
      status: ItemStatus.active,
      requesterId: personId ?? item.requesterId,
      waitingOnId: item.waitingOnId,
      revisitAt: item.revisitAt,
    ),
    TriageDestination.waitingFor => ItemClassification(
      type: item.type,
      status: ItemStatus.waiting,
      requesterId: item.requesterId,
      waitingOnId: personId ?? item.waitingOnId,
      revisitAt: item.revisitAt,
    ),
    TriageDestination.trash => throw ArgumentError.value(
      destination,
      'destination',
      'the trash is no classification',
    ),
  };
}

/// One run through the inbox, card by card (DD-018 point 3). Pure state:
/// the screen feeds it the live inbox and the choices.
///
/// The cards are the inbox at the start, in its order; items captured
/// during triage come at the end and raise the total ("3 of 13"). A card
/// that left the inbox some other way (e.g. trashed in the detail) is
/// passed over and not counted.
class TriageSession {
  TriageSession(Iterable<String> inbox) : _cards = [...inbox];

  final List<String> _cards;
  var _index = 0;
  final _outcomes = <String, TriageOutcome>{};

  /// A card brought back by [undo] whose item is not back in the inbox
  /// yet: an older inbox update must not make it drop out.
  String? _returning;

  /// The live inbox changed: new items join at the end; cards not handled
  /// yet that are no longer in the inbox drop out.
  void update(Iterable<String> inbox) {
    final live = inbox.toSet();
    if (live.contains(_returning)) _returning = null;
    for (var i = _cards.length - 1; i >= _index; i--) {
      if (!live.contains(_cards[i]) && _cards[i] != _returning) {
        _cards.removeAt(i);
      }
    }
    final known = _cards.toSet();
    _cards.addAll(inbox.where((id) => !known.contains(id)));
  }

  /// The card to handle now, or null when every card has been handled.
  String? get current => _index < _cards.length ? _cards[_index] : null;

  /// 1-based position of [current] ("3 of 12"); total + 1 at the end.
  int get position => _index + 1;
  int get total => _cards.length;

  int get processed =>
      _outcomes.values.where((o) => o == TriageOutcome.sorted).length;
  int get skipped =>
      _outcomes.values.where((o) => o == TriageOutcome.skipped).length;

  /// Card [id] was sorted (or trashed) or skipped; the next card comes.
  /// Refused (false) unless [id] is [current]: a late or double choice for
  /// a card that already moved on never counts for the next one.
  bool decide(String id, TriageOutcome outcome) {
    if (current != id) return false;
    _outcomes[id] = outcome;
    _index++;
    return true;
  }

  /// Whether card [id] is the last decision, the only one [undo] takes back.
  bool canUndo(String id) => _index > 0 && _cards[_index - 1] == id;

  /// Takes the decision on card [id] back: it is current again. Refused
  /// (false) unless it was the last decision, so an undo can never step
  /// back over another card.
  bool undo(String id) {
    if (!canUndo(id)) return false;
    _index--;
    _outcomes.remove(id);
    _returning = id;
    return true;
  }
}

/// What happened to a card in triage.
enum TriageOutcome { sorted, skipped }
