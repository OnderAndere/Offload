import 'package:flutter_test/flutter_test.dart';
import 'package:offload/domain/people/calling_country.dart';

/// International form of phone numbers (T3.6, DD-012; PO decisions
/// 02-10-2026).
void main() {
  final nl = callingCountryOf('NL');

  test('a Dutch number in national form', () {
    expect(e164('06-12345678', nl), '+31612345678');
    expect(e164('020 123 4567', nl), '+31201234567');
    expect(e164('(020) 123 45 67', nl), '+31201234567');
  });

  test('a country code as typed, with or without (0)', () {
    expect(e164('+31 6 1234 5678', nl), '+31612345678');
    expect(e164('+31 (0)20 123 4567', nl), '+31201234567');
    expect(e164('+380 67 123 4567', nl), '+380671234567');
  });

  test('the international prefix counts as +', () {
    expect(e164('0032 3 123 45 67', nl), '+3231234567');
    expect(e164('011 1 212 555 0100', callingCountryOf('US')), '+12125550100');
  });

  test('other home countries', () {
    expect(e164('0471 12 34 56', callingCountryOf('BE')), '+32471123456');
    // Italy keeps its 0; Spain has none to drop.
    expect(e164('02 1234 5678', callingCountryOf('IT')), '+390212345678');
    expect(e164('612 34 56 78', callingCountryOf('ES')), '+34612345678');
    // North America, with or without the 1.
    final us = callingCountryOf('US');
    expect(e164('(212) 555-0100', us), '+12125550100');
    expect(e164('1 212 555 0100', us), '+12125550100');
    // Hungary dials 06 before a national number.
    expect(e164('06 1 234 5678', callingCountryOf('HU')), '+3612345678');
  });

  test('none when it cannot be told', () {
    expect(e164('112', nl), isNull);
    expect(e164('612345678', nl), isNull); // no trunk 0
    expect(e164('+31 6 1234 5678 9012 345', nl), isNull); // too long
  });

  test('an unknown code gives the default country', () {
    expect(callingCountryOf('XX').isoCode, 'NL');
    expect(callingCountryOf(null), defaultCallingCountry);
  });

  test('every country in the list has a unique code', () {
    final codes = [for (final c in callingCountries) c.isoCode];
    expect(codes.toSet(), hasLength(codes.length));
  });

  test('Dutch mobile', () {
    expect(isDutchMobile('+31612345678'), isTrue);
    expect(isDutchMobile('+31201234567'), isFalse);
  });
}
