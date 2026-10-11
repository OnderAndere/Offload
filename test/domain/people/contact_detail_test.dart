import 'package:flutter_test/flutter_test.dart';
import 'package:offload/domain/people/contact_detail.dart';
import 'package:offload/domain/people/person_merge.dart';

/// Contact details of a person (T3.5, REQ-038, DD-012).
void main() {
  ContactDetail detail(
    String id,
    ContactKind kind,
    String value, {
    int order = 0,
    String? label,
  }) => ContactDetail(
    id: id,
    personId: 'p',
    kind: kind,
    value: value,
    label: label,
    sortOrder: order,
  );

  group('checkContact', () {
    test('a phone number: digits, spaces and + ( ) . / -', () {
      expect(checkContact(ContactKind.phone, '06-12 34 56 78'), isNull);
      expect(checkContact(ContactKind.phone, '+31 (0)6 1234.5678'), isNull);
      expect(checkContact(ContactKind.phone, '112'), isNull);
      expect(checkContact(ContactKind.phone, '  '), ContactProblem.empty);
      expect(checkContact(ContactKind.phone, '12'), ContactProblem.invalid);
      expect(checkContact(ContactKind.phone, 'bel me'), ContactProblem.invalid);
      expect(checkContact(ContactKind.phone, '06+123'), ContactProblem.invalid);
    });

    test('an email address: one @ and a dot after it', () {
      expect(checkContact(ContactKind.email, 'jan@example.org'), isNull);
      expect(checkContact(ContactKind.email, ' олена@приклад.укр '), isNull);
      expect(checkContact(ContactKind.email, ''), ContactProblem.empty);
      expect(
        checkContact(ContactKind.email, 'jan@example'),
        ContactProblem.invalid,
      );
      expect(
        checkContact(ContactKind.email, 'jan @example.org'),
        ContactProblem.invalid,
      );
    });
  });

  test('contactKey: a number by its digits, an address ignoring case', () {
    expect(
      contactKey(ContactKind.phone, '06-12 34 56 78'),
      contactKey(ContactKind.phone, '0612345678'),
    );
    // In international form (T3.6): +31 and 0 are one number at home.
    expect(
      contactKey(ContactKind.phone, '+31 6 12345678'),
      contactKey(ContactKind.phone, '06 12345678'),
    );
    // A number that has no international form keeps its digits.
    expect(
      contactKey(ContactKind.phone, '112'),
      contactKey(ContactKind.phone, '1-1-2'),
    );
    expect(
      contactKey(ContactKind.email, ' Jan@Example.org'),
      contactKey(ContactKind.email, 'jan@example.org'),
    );
    expect(
      contactKey(ContactKind.email, 'ОЛЕНА@приклад.укр'),
      contactKey(ContactKind.email, 'олена@приклад.укр'),
    );
    expect(
      contactKey(ContactKind.phone, '123'),
      isNot(contactKey(ContactKind.email, '123')),
    );
  });

  test('a standard label is known by its name, any other is own text', () {
    expect(StandardContactLabel.of('work'), StandardContactLabel.work);
    expect(StandardContactLabel.of('Робота'), isNull);
    expect(StandardContactLabel.of(null), isNull);
  });

  test('sorted: phone numbers first, each kind by its order', () {
    final sorted = sortContactDetails([
      detail('e1', ContactKind.email, 'a@example.org'),
      detail('p2', ContactKind.phone, '222', order: 1),
      detail('p1', ContactKind.phone, '111'),
    ]);
    expect([for (final d in sorted) d.id], ['p1', 'p2', 'e1']);
  });

  test('merging: the same detail once, the target keeps its label', () {
    final into = [
      detail('i1', ContactKind.phone, '06-12345678', label: 'mobile'),
    ];
    final from = [
      detail('f1', ContactKind.phone, '06 1234 5678', label: 'work'),
      detail('f2', ContactKind.email, 'JAN@example.org'),
      detail('f3', ContactKind.email, 'jan@example.org', order: 1),
    ];
    final result = mergeContactDetails(into, from);
    expect([for (final d in result.move) d.id], ['f2']);
    expect([for (final d in result.drop) d.id], ['f1', 'f3']);
  });
}
