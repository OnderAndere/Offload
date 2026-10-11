import 'birthday.dart';
import 'contact_detail.dart';
import 'contacts_from_text.dart';
import 'person.dart';
import 'person_merge.dart';

/// People as a light entity (DD-015): found by name or alias, created when
/// unknown, renamed with the old name kept as an alias, merged.
abstract class PeopleRepository {
  /// The live person called [name], by name or alias and ignoring case
  /// (Unicode); created when there is none. Never two people for one name,
  /// also when called twice at the same moment.
  Future<String> idFor(String name);

  /// The live person called [name], by name or alias, or null; creates
  /// nothing (an `@name` chip that opens its person, DD-018 point 7).
  Future<String?> find(String name);

  /// The live people with their aliases, by name (DD-018 point 7); emits
  /// again on every change.
  Stream<List<Person>> watchPeople();

  /// Renames person [id] to [name] (DD-015, DD-018 point 7). The old name
  /// becomes an alias, so `@oldname` keeps finding the person; renaming to
  /// one of the person's own aliases swaps the two; a new name with the
  /// same `nameKey` (only case or outer spaces differ) adds no alias. Throws
  /// a [PersonException] when [name] is empty, belongs to another live
  /// person, or [id] is not a live person.
  Future<void> rename(String id, String name);

  /// The merged people, each with the person it was merged into (DD-015):
  /// for reading a reference to a merged person as one to that person.
  Stream<Map<String, String>> watchMergedInto();

  /// Merges person [fromId] into [intoId] (DD-015, T3.2b) in one
  /// transaction through the change log: every reference to [fromId] goes
  /// to [intoId], the name and aliases of [fromId] become aliases of
  /// [intoId] (once each), the profiles are joined ([mergeProfiles]), the
  /// contact details move, those [intoId] already has once
  /// ([mergeContactDetails]), and [fromId] gets a tombstone with
  /// `merged_into_id`. Throws a
  /// [PersonException] when either is not a live person, or they are the
  /// same.
  Future<PersonMerge> merge(String fromId, String intoId);

  /// Undoes [merge] right after it: puts back what nothing else changed in
  /// between.
  Future<void> undoMerge(PersonMerge merge);

  /// Sets or removes (null) the birthday of person [id] (REQ-031). Throws a
  /// [PersonException] when [id] is not a live person.
  Future<void> setBirthday(String id, Birthday? birthday);

  /// Replaces the note of person [id]; empty or white space removes it
  /// (REQ-031). Throws a [PersonException] when [id] is not a live person.
  Future<void> setNote(String id, String note);

  /// Sets both the organisation and the job title of person [id]
  /// (REQ-038): pass what should stay too; null, empty or white space
  /// removes one. Throws a [PersonException] when [id] is not a live
  /// person.
  Future<void> setWork(
    String id, {
    required String? organisation,
    required String? jobTitle,
  });

  /// The live contact details of person [personId] in the order shown
  /// ([sortContactDetails]); emits again on every change.
  Stream<List<ContactDetail>> watchContactDetails(String personId);

  /// Adds a phone number or email address to person [personId], after the
  /// others of its kind; the value is kept as typed, without outer white
  /// space. Returns its id. Throws a [ContactException] when the value is
  /// empty or does not fit [kind] ([checkContact]), a [PersonException]
  /// when [personId] is not a live person.
  Future<String> addContactDetail(
    String personId,
    ContactKind kind,
    String value, {
    String? label,
  });

  /// Adds the details taken from the text of an item to person [personId]
  /// (REQ-039, T3.6), each as [addContactDetail]; one the person already
  /// has ([contactKey], in this device's home country) is skipped. Returns
  /// the ids of the added ones, for undo. All or nothing.
  Future<List<String>> addContactsFromText(
    String personId,
    List<TextContact> contacts,
  );

  /// Changes the value and label of contact detail [id]; checks as
  /// [addContactDetail]. Throws a [ContactException].
  Future<void> updateContactDetail(String id, String value, {String? label});

  /// Sends contact detail [id] to the trash (a tombstone, with undo).
  Future<void> deleteContactDetail(String id);

  /// Sends the contact details [ids] to the trash together: all or none
  /// (the Undo of [addContactsFromText]).
  Future<void> deleteContactDetails(List<String> ids);

  /// Undoes [deleteContactDetail]. Returns false when nothing came back:
  /// the detail is not deleted, or its person is no longer live (merged or
  /// deleted meanwhile; their details went with the merge).
  Future<bool> restoreContactDetail(String id);
}
