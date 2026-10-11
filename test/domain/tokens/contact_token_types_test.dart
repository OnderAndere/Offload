import 'package:flutter_test/flutter_test.dart';
import 'package:offload/domain/people/calling_country.dart';
import 'package:offload/domain/people/contact_detail.dart';
import 'package:offload/domain/people/contacts_from_text.dart';
import 'package:offload/domain/time/local_date.dart';
import 'package:offload/domain/tokens/inline_token.dart';
import 'package:offload/domain/tokens/inline_token_registry.dart';

/// Phone numbers and email addresses in the text (T3.6, REQ-039, DD-004
/// point 3a; PO decisions 02-10-2026).
void main() {
  final registry = InlineTokenRegistry.standard();
  final context = ParseContext(
    today: LocalDate(2026, 10, 2),
    dates: DateVocabulary.empty,
  );

  List<(String, String)> found(String text) => [
    for (final m in registry.parse(text, context)) (m.type.id, m.word),
  ];

  group('phone numbers', () {
    test('the usual ways of writing one', () {
      for (final number in [
        '06-12345678',
        '0612345678',
        '06 12 34 56 78',
        '06-12 34 56 78',
        '020-1234567',
        '020 123 4567',
        '+31 6 1234 5678',
        '+31612345678',
        '+31 (0)20 123 4567',
        '+380 67 123 4567',
        '0032 3 123 45 67',
      ]) {
        expect(found('bel $number nu'), [('phone', number)], reason: number);
      }
    });

    test('a number in brackets or with punctuation after it', () {
      expect(found('(06-12345678)'), [('phone', '06-12345678')]);
      expect(found('bel 06-12345678, morgen'), [('phone', '06-12345678')]);
    });

    test('stops where the number ends', () {
      expect(found('06-12345678 10 uur'), [('phone', '06-12345678')]);
      expect(found('020 123 4567 of later'), [('phone', '020 123 4567')]);
    });

    test('years, times, dates, amounts and codes stay text', () {
      for (final text in [
        'in 2026',
        'om 08:30',
        'op 01-02-2026',
        'op 01-02-2026 10 uur',
        'kost 0,50',
        'NL91ABNA0417164300',
        'postcode 1234 AB',
        'bel 06-1234', // too short
        'x0612345678',
        '0612345678x',
      ]) {
        expect(found(text), isEmpty, reason: text);
      }
    });

    test('a date token is never a phone number', () {
      expect(found('klaar !01-02-2026'), [('date', '01-02-2026')]);
    });
  });

  group('email addresses', () {
    test('found, also with punctuation after them', () {
      expect(found('mail jan@example.org'), [('email', 'jan@example.org')]);
      expect(found('(petra.de-vries+offerte@post.example.org).'), [
        ('email', 'petra.de-vries+offerte@post.example.org'),
      ]);
    });

    test('not without a domain, and @Jan stays a person', () {
      expect(found('jan@voorbeeld'), isEmpty);
      expect(found('@Jan'), [('person', 'Jan')]);
    });
  });

  group('contactsInText', () {
    final nl = callingCountryOf('NL');
    ({String? person, List<TextContact> contacts}) read(String text) =>
        contactsInText(registry.parse(text, context), home: nl);

    test('the one person and the details, a Dutch mobile labelled', () {
      final result = read('@Jan 06-12345678 020-1234567 jan@example.org');
      expect(result.person, 'Jan');
      expect(
        [for (final c in result.contacts) (c.kind, c.value, c.label)],
        [
          (ContactKind.phone, '06-12345678', 'mobile'),
          (ContactKind.phone, '020-1234567', null),
          (ContactKind.email, 'jan@example.org', null),
        ],
      );
    });

    test('no person, or several: none', () {
      expect(read('06-12345678').person, isNull);
      expect(read('@Jan @Piet 06-12345678').person, isNull);
      // The same person twice is one.
      expect(read('@Jan en @jan 06-12345678').person, 'Jan');
    });

    test('newContacts: only what was not there before, once', () {
      final before = read('@Jan +31 6 1234 5678').contacts;
      final now = read(
        '@Jan 06-12345678 jan@example.org JAN@example.org',
      ).contacts;
      expect(
        [for (final c in newContacts(now, before, home: nl)) c.value],
        ['jan@example.org'],
      );
    });
  });
}
