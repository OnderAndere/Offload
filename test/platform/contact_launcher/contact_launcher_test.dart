import 'package:flutter_test/flutter_test.dart';
import 'package:offload/platform/contact_launcher/contact_launcher.dart';

/// The links a number or address opens with (T3.5 step C, DD-018 point 9).
void main() {
  test('a tel: link keeps only digits and a leading +', () {
    expect(telUri('06-12 34 56 78').toString(), 'tel:0612345678');
    expect(telUri(' +31 20 123.4567 ').toString(), 'tel:+31201234567');
    // A trunk zero in brackets is not dialled after a country code…
    expect(telUri('+31 (0)20 123 4567').toString(), 'tel:+31201234567');
    // …but without one it is the number's own zero.
    expect(telUri('(0)20 123 4567').toString(), 'tel:0201234567');
  });

  test('a mailto: link for the address, also outside ASCII', () {
    expect(mailtoUri(' jan@example.org ').toString(), 'mailto:jan@example.org');
    expect(mailtoUri('олена@приклад.укр').scheme, 'mailto');
    // Percent-encoded, as RFC 6068 asks; the mail app decodes it.
    expect(
      Uri.decodeComponent(mailtoUri('олена@приклад.укр').path),
      'олена@приклад.укр',
    );
  });
}
