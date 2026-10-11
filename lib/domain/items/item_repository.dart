import '../people/person_overview.dart';
import '../repeats/repeat.dart';
import '../time/local_date.dart';
import 'completion.dart';
import 'item.dart';
import 'item_classification.dart';
import 'item_enums.dart';

/// Stores and reads items (REQ-001, REQ-018).
abstract class ItemRepository {
  /// Stores [rawText] unchanged as a new item with status inbox and returns
  /// its id. Nothing is parsed here: saving comes first, parsing and
  /// indexing later (CLAUDE.md rule 7).
  ///
  /// Throws [ArgumentError] when [rawText] has no text
  /// ([hasCapturableText]).
  ///
  /// [links] are the items chosen from the `[[` suggestion list while
  /// typing, by the label in [rawText]; they are saved with the item, in one
  /// transaction (DD-004 point 13).
  Future<String> capture(
    String rawText, {
    required ItemSource source,
    Map<String, String> links = const {},
  });

  /// Stores a capture made outside the app (for example in the Android
  /// widget) under its own [id], a version 7 UUID from the moment of capture.
  /// Returns false, and changes nothing, when an item with [id] already
  /// exists, also a deleted one: a capture delivered twice is stored once.
  ///
  /// Throws [ArgumentError] when [id] is not a version 7 UUID or [rawText]
  /// has no text.
  Future<bool> captureWithId(
    String id,
    String rawText, {
    required ItemSource source,
  });

  /// The items in the inbox, newest capture first; emits again on every
  /// change.
  Stream<List<Item>> watchInbox();

  /// Every item that is not in the trash, newest capture first: the
  /// temporary "also processed" view of the inbox, until the other
  /// destinations exist (T2.3, PO decision 27-09-2026).
  Stream<List<Item>> watchLiveItems();

  /// Every item not in the trash, not done and not archived, whose
  /// deadline is on [day] or earlier: what Today shows (DD-018 point 4),
  /// before [todaySections] splits it. Emits again on every change.
  Stream<List<Item>> watchDueThrough(LocalDate day);

  /// Item [id] as it changes; null when it does not exist or is in the
  /// trash.
  Stream<Item?> watchItem(String id);

  /// Every waiting item not in the trash whose expected date is before
  /// [day]: late on [day] (REQ-047, DD-018 point 10 (e)), the longest late
  /// first. Emits again on every change.
  Stream<List<Item>> watchLateWaiting(LocalDate day);

  /// The items of project [projectId] not in the trash, its sub-projects'
  /// items not included, newest capture first (DD-018 point 6). Null gives
  /// the items without a project, together with those whose project no
  /// longer exists.
  Stream<List<Item>> watchProjectItems(String? projectId);

  /// The items not in the trash that are linked to person [personId]: as
  /// requester, as the person waited on, or named in the text (a stored
  /// person token), newest capture first, with the ids of the named ones
  /// (DD-018 point 7). Someone merged into the person counts as the person
  /// (DD-015): such a reference comes back as [personId]. Emits again on
  /// every change, also of the tokens and the people.
  Stream<PersonItems> watchPersonItems(String personId);

  /// The people named in the text of each item not in the trash: stored
  /// person tokens resolved to a person, by item id (Connections, DD-018
  /// point 15). A person merged away comes back as stored; the caller
  /// follows the merges (DD-015).
  Stream<Map<String, Set<String>>> watchMentions();

  /// Replaces the text of item [id] (DD-018): the user's edit, stored as
  /// typed, with the [links] chosen while typing (label to item, see
  /// [capture]) in the same transaction. Throws [ArgumentError] when
  /// [rawText] has no text.
  Future<void> editText(
    String id,
    String rawText, {
    Map<String, String> links = const {},
  });

  /// *Link* in the duplicate hint (AC REQ-053, DD-004 point 13): adds
  /// ` [[label]]` to the end of the text of item [fromId] (after trailing
  /// spaces; [label] made a valid label with `linkLabelFor`) and links it to
  /// item [toId], in one transaction. A user edit, as typed in the detail.
  Future<void> appendLink(String fromId, String toId, String label);

  /// A tap on "no item" (DD-004 point 13 (b)): a new inbox item with the
  /// text [label], linked from item [fromId] under that label, in one
  /// transaction. Returns the new item's id.
  Future<String> captureLinked(
    String fromId,
    String label, {
    required ItemSource source,
  });

  /// Replaces the note; empty or white space removes it.
  Future<void> editNote(String id, String note);

  /// Moves item [id] to [status]; its current status is a no-op. Throws
  /// [StateError] when the status machine does not allow it
  /// (`nextStatuses`). A parked item that leaves *scheduled* this way loses
  /// its revisit date (DD-005): moving it by hand cancels the revisit. So
  /// does moving to *scheduled*: that is a revisit without a date, which
  /// never returns by itself; parking goes through [revisitOn].
  Future<void> moveTo(String id, ItemStatus status);

  /// Completes item [id] (*Afronden*: the button, a swipe, Ctrl+Enter, the
  /// weekly review; REQ-061, DD-018 point 18). A repeating item (an open
  /// task, or one without a type, with a repeat word) gets a record of its
  /// current time and moves to the next date of its series after that time
  /// and [today]; it becomes active when it was inbox, waiting or scheduled
  /// and never becomes done this way. Any other item becomes done, as
  /// [moveTo]. One transaction; [undoComplete] takes it back.
  Future<Completion> complete(String id, {required LocalDate today});

  /// *Afronden en herhalen…* (DD-018 point 18): sets [rawText] (the text
  /// with a repeat word for [rhythm] added) and completes this time of the
  /// new series, in one transaction. Its first time is the item's date, or
  /// [today] without one, and so is this time.
  Future<Completion> completeAndRepeat(
    String id, {
    required String rawText,
    required Rhythm rhythm,
    required LocalDate today,
  });

  /// *Herhaling stoppen* (DD-018 point 18): sets [rawText] (the text
  /// without its repeat words) and makes the item done, in one transaction.
  Future<Completion> stopRepeating(String id, {required String rawText});

  /// Takes back [completion] exactly: removes the record of the time, and
  /// puts back the status, revisit date and date the item had, and its text
  /// when that was not edited since.
  Future<void> undoComplete(Completion completion);

  /// The stored repeat token per live item: its rhythm and first time
  /// (DD-004 point 14), whatever its type.
  Stream<Map<String, ItemRepeat>> watchRepeats();

  /// The completed times of item [itemId], the newest first (*Gedaan*).
  Stream<List<RepeatCompletion>> watchCompletions(String itemId);

  /// Parks item [id] until [day] (REQ-021, DD-018 point 17): status
  /// scheduled with that revisit date, in one change; a parked item gets
  /// the new date. Throws [StateError] for an item that is done or
  /// archived. Any day is accepted; the app offers tomorrow or later, and
  /// an earlier day returns at the next check ([returnRevisited]).
  Future<void> revisitOn(String id, LocalDate day);

  /// *Not any more* (DD-018 point 17): parked item [id] becomes active and
  /// loses its revisit date. Throws [StateError] when it is not scheduled.
  Future<void> stopRevisit(String id);

  /// Puts every live item that is scheduled with a revisit date of [today]
  /// or earlier back in the inbox, each as its own change (DD-005). The
  /// date stays, for the group on Today. The inbox is otherwise never a
  /// status to move back to; this, [classify] and its undo are the
  /// exceptions. Returns the ids of the items that came back.
  Future<List<String>> returnRevisited(LocalDate today);

  /// Sets or clears (null) the type (REQ-018).
  Future<void> setType(String id, ItemType? type);

  /// Puts item [id] in project [projectId], or in none (null) (DD-018
  /// point 6). Throws a `ProjectException` when the project is deleted or
  /// archived.
  Future<void> setProject(String id, String? projectId);

  /// Sets or clears (null) who asked for item [id] (DD-018 point 7). Throws
  /// a `PersonException` when the person is not a live person.
  Future<void> setRequester(String id, String? personId);

  /// Sets or clears (null) who item [id] waits on, without changing its
  /// status (DD-018 point 7). Throws a `PersonException` when the person is
  /// not a live person.
  Future<void> setWaitingOn(String id, String? personId);

  /// Moves item [id] to waiting on [personId] in one change (DD-018 point
  /// 7); null keeps the person it had, as in triage. A parked item loses
  /// its revisit date, as with [moveTo]. Throws [StateError]
  /// when the status machine does not allow waiting, and a
  /// `PersonException` when the person is not a live person.
  ///
  /// [expected] is the day it is expected by (DD-018 point 10 (d)). An item
  /// that starts waiting gets exactly that, none included, so an old date
  /// from an earlier wait never comes back; one already waiting keeps its
  /// date unless a new one is given.
  Future<void> waitFor(String id, String? personId, {LocalDate? expected});

  /// Sets type, status, people and revisit date of item [id] in one change
  /// (triage, REQ-010), or puts back the classification it had: the undo of
  /// a triage choice, of completing an item from Today (DD-018 point 4) and
  /// of parking it (DD-018 point 17).
  /// Unlike [moveTo], this may put an item back in the inbox, because undo
  /// restores exactly what was there; only those two use it.
  ///
  /// [expected], when given, also sets the expected day in the same change
  /// (triage *Waiting for*, and its undo); `(day: null)` clears it.
  Future<void> classify(
    String id,
    ItemClassification classification, {
    ({LocalDate? day})? expected,
  });

  /// Records that the user looked at item [id] in the weekly review
  /// (*Keep*, *Still waiting*; AC REQ-051): `reviewed_at` becomes now, so
  /// the item is not stale for another X weeks.
  Future<void> markReviewed(String id);

  /// Sets the day item [id] was asked (REQ-046, DD-018 point 10); null
  /// goes back to the capture day.
  Future<void> setAskedOn(String id, LocalDate? day);

  /// Sets what I promised for item [id] (REQ-046); empty or null goes back
  /// to the title. The text is kept as typed, without outer white space.
  Future<void> setPromise(String id, String? promise);

  /// Sets the day I expect waiting item [id] by (REQ-047); null clears it.
  Future<void> setExpectedBy(String id, LocalDate? day);

  /// Moves item [id] to the trash: a tombstone, never a physical delete.
  Future<void> moveToTrash(String id);

  /// Whether item [id] exists and is not in the trash.
  Future<bool> isLive(String id);

  /// Takes item [id] out of the trash again (undo, AC REQ-010).
  Future<void> restoreFromTrash(String id);
}
