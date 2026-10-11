/// Contact details of a person (REQ-038, DD-012): phone numbers and email
/// addresses, a list per person with an optional label.
library;

import 'calling_country.dart';

/// What a contact detail is.
enum ContactKind { phone, email }

/// The standard labels, shown translated (PO decision 02-10-2026): a label
/// the user picks from these stays right when the app language changes. Any
/// other label is the user's own text, kept as typed.
enum StandardContactLabel {
  work,
  mobile,
  private,
  other;

  /// The standard label stored as [label], or null for an own label.
  static StandardContactLabel? of(String? label) {
    for (final standard in values) {
      if (standard.name == label) return standard;
    }
    return null;
  }
}

/// A phone number or email address of a person.
class ContactDetail {
  const ContactDetail({
    required this.id,
    required this.personId,
    required this.kind,
    required this.value,
    this.label,
    required this.sortOrder,
  });

  final String id;
  final String personId;
  final ContactKind kind;

  /// The text as typed, without outer white space; never normalised in
  /// storage (E.164 is derived later, T3.6).
  final String value;

  /// A [StandardContactLabel] name or the user's own text; optional.
  final String? label;

  /// The order within the person's list.
  final int sortOrder;

  /// The key under which two details count as the same ([contactKey]).
}

/// Why a contact detail is refused.
enum ContactProblem {
  /// The value is empty.
  empty,

  /// The value does not look like a phone number or email address.
  invalid,

  /// The detail is deleted or unknown.
  notAvailable,
}

class ContactException implements Exception {
  const ContactException(this.problem);

  final ContactProblem problem;

  @override
  String toString() => 'ContactException(${problem.name})';
}

final _phoneCharacters = RegExp(r'^\+?[0-9 ()./-]+$');
final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// The digits of a phone number: "06-12 34 56 78" → "0612345678". Used to
/// find a number however it was typed, in search and when merging.
String phoneDigits(String value) => value.replaceAll(RegExp(r'[^0-9]'), '');

/// Whether [value] is acceptable as a detail of [kind]: a phone number has
/// at least three digits and only digits, spaces and `+ ( ) . / -`; an
/// email address has one `@` and a dot after it. Light checks: the text is
/// kept as typed.
ContactProblem? checkContact(ContactKind kind, String value) {
  final text = value.trim();
  if (text.isEmpty) return ContactProblem.empty;
  final ok = switch (kind) {
    ContactKind.phone =>
      _phoneCharacters.hasMatch(text) && phoneDigits(text).length >= 3,
    ContactKind.email => _email.hasMatch(text),
  };
  return ok ? null : ContactProblem.invalid;
}

/// When two details are the same (merging, DD-015; taking them from the
/// text, T3.6): a phone number by its international form ([e164], with
/// [home] for a number typed without country code), so "+31 6…" and "06…"
/// are one, or else by its digits and a leading `+`; an email address
/// ignoring case.
String contactKey(
  ContactKind kind,
  String value, {
  CallingCountry home = defaultCallingCountry,
}) {
  final text = value.trim();
  return switch (kind) {
    ContactKind.phone =>
      'phone:${e164(text, home) ?? '${text.startsWith('+') ? '+' : ''}${phoneDigits(text)}'}',
    ContactKind.email => 'email:${text.toLowerCase()}',
  };
}

/// The details of a person in the order shown: phone numbers, then email
/// addresses, each by their order and then by id.
List<ContactDetail> sortContactDetails(Iterable<ContactDetail> details) =>
    [...details]..sort((a, b) {
      final byKind = a.kind.index.compareTo(b.kind.index);
      if (byKind != 0) return byKind;
      final byOrder = a.sortOrder.compareTo(b.sortOrder);
      return byOrder != 0 ? byOrder : a.id.compareTo(b.id);
    });
