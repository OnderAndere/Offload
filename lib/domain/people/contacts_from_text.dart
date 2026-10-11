import '../tokens/contact_token_types.dart';
import '../tokens/inline_token.dart';
import '../tokens/token_processing.dart';
import '../tokens/token_types.dart';
import 'calling_country.dart';
import 'contact_detail.dart';

/// A phone number or email address typed in the text of an item (REQ-039,
/// T3.6), with the label it gets as a contact detail.
typedef TextContact = ({ContactKind kind, String value, String? label});

/// The contact details in [matches] (the tokens of one text) and the person
/// they belong to: the one person named with `@`, or null when the text
/// names none or several (PO decision d, 02-10-2026: then nothing is added
/// by itself; the item detail offers "Link to…"). A Dutch mobile number
/// gets the label *Mobile*, others none (PO decision e); a number without
/// country code is read in [home].
({String? person, List<TextContact> contacts}) contactsInText(
  List<TokenMatch> matches, {
  CallingCountry home = defaultCallingCountry,
}) {
  final people = <String, String>{};
  final contacts = <TextContact>[];
  for (final match in matches) {
    switch (match.type) {
      case PersonTokenType():
        people.putIfAbsent(nameKey(match.word), () => match.word);
      case PhoneTokenType():
        contacts.add((
          kind: ContactKind.phone,
          value: match.word,
          label: _mobileLabel(match.word, home),
        ));
      case EmailTokenType():
        contacts.add((kind: ContactKind.email, value: match.word, label: null));
      default:
        break;
    }
  }
  return (
    person: people.length == 1 ? people.values.single : null,
    contacts: contacts,
  );
}

/// The details of [now] that are not in [before] (the text as saved
/// earlier), each once: only newly typed numbers and addresses are taken
/// from the text (PO decision c). Compared as [contactKey], in [home].
List<TextContact> newContacts(
  List<TextContact> now,
  List<TextContact> before, {
  CallingCountry home = defaultCallingCountry,
}) {
  String key(TextContact c) => contactKey(c.kind, c.value, home: home);
  final seen = {for (final c in before) key(c)};
  return [
    for (final c in now)
      if (seen.add(key(c))) c,
  ];
}

String? _mobileLabel(String number, CallingCountry home) {
  final international = e164(number, home);
  return international != null && isDutchMobile(international)
      ? StandardContactLabel.mobile.name
      : null;
}
