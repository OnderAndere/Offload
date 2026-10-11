/// A country whose phone numbers Offload can write in international form
/// (E.164) when they are typed without a country code (T3.6, DD-012; PO
/// decision 02-10-2026: an own short list, extended when someone misses a
/// country). The home country is chosen in Settings; the Netherlands by
/// default.
class CallingCountry {
  const CallingCountry(
    this.isoCode,
    this.callingCode, {
    this.trunkPrefix = '0',
    this.keepsTrunk = false,
    this.trunkOptional = false,
    this.internationalPrefix = '00',
  });

  /// ISO 3166-1 alpha-2, also the key of its name in the ARB files
  /// (`countryName`) and of the setting.
  final String isoCode;

  /// The country code without `+`: "31".
  final String callingCode;

  /// What a national number starts with and the international form leaves
  /// out: "0" in most countries, "" where there is none (Spain), "1" in
  /// North America.
  final String trunkPrefix;

  /// Italy keeps its leading 0 after the country code (+39 02…).
  final bool keepsTrunk;

  /// North America: a number is often typed without its trunk prefix 1.
  final bool trunkOptional;

  /// What dials abroad from this country: "00", or "011" in North America.
  final String internationalPrefix;

  @override
  String toString() => 'CallingCountry($isoCode)';
}

/// The countries of the list, by ISO code (DD-012). Numbers typed with `+`
/// or the international prefix work for every country; this list only
/// matters for numbers typed in national form.
const callingCountries = [
  CallingCountry('NL', '31'),
  CallingCountry('BE', '32'),
  CallingCountry('LU', '352', trunkPrefix: ''),
  CallingCountry('DE', '49'),
  CallingCountry('FR', '33'),
  CallingCountry('GB', '44'),
  CallingCountry('IE', '353'),
  CallingCountry('ES', '34', trunkPrefix: ''),
  CallingCountry('PT', '351', trunkPrefix: ''),
  CallingCountry('IT', '39', keepsTrunk: true),
  CallingCountry('AT', '43'),
  CallingCountry('CH', '41'),
  CallingCountry('DK', '45', trunkPrefix: ''),
  CallingCountry('SE', '46'),
  CallingCountry('NO', '47', trunkPrefix: ''),
  CallingCountry('FI', '358'),
  CallingCountry('IS', '354', trunkPrefix: ''),
  CallingCountry('PL', '48', trunkPrefix: ''),
  CallingCountry('CZ', '420', trunkPrefix: ''),
  CallingCountry('SK', '421'),
  CallingCountry('HU', '36', trunkPrefix: '06'),
  CallingCountry('GR', '30', trunkPrefix: ''),
  CallingCountry('HR', '385'),
  CallingCountry('SI', '386'),
  CallingCountry('RO', '40'),
  CallingCountry('BG', '359'),
  CallingCountry('EE', '372', trunkPrefix: ''),
  CallingCountry('LV', '371', trunkPrefix: ''),
  CallingCountry('UA', '380'),
  CallingCountry('TR', '90'),
  CallingCountry('MA', '212'),
  CallingCountry('SR', '597', trunkPrefix: ''),
  CallingCountry('ZA', '27'),
  CallingCountry(
    'US',
    '1',
    trunkPrefix: '1',
    trunkOptional: true,
    internationalPrefix: '011',
  ),
  CallingCountry(
    'CA',
    '1',
    trunkPrefix: '1',
    trunkOptional: true,
    internationalPrefix: '011',
  ),
  CallingCountry('AU', '61', internationalPrefix: '0011'),
  CallingCountry('NZ', '64'),
];

/// The default home country.
const defaultCallingCountry = CallingCountry('NL', '31');

/// The country with [isoCode], or the default when it is not in the list.
CallingCountry callingCountryOf(String? isoCode) =>
    callingCountries.where((c) => c.isoCode == isoCode).firstOrNull ??
    defaultCallingCountry;

final _nonDigits = RegExp(r'[^0-9]');

/// [typed] in international form (E.164, "+31612345678"), or null when it
/// cannot be told (too few or too many digits, or a national number
/// without its trunk prefix in a country that has one). Derived, never
/// stored (DD-012, rule 6): the text stays as typed.
///
/// - `+31 (0)6 …`: the "(0)" after a country code is left out;
/// - the international prefix of [home] ("00", "011") counts as `+`;
/// - otherwise the number is national in [home]: its trunk prefix goes,
///   the country code comes in front (Italy keeps its 0).
String? e164(String typed, CallingCountry home) {
  var text = typed.trim();
  String international;
  if (text.startsWith('+')) {
    text = text.replaceAll('(0)', '');
    international = text.replaceAll(_nonDigits, '');
  } else {
    final digits = text.replaceAll(_nonDigits, '');
    if (digits.startsWith(home.internationalPrefix)) {
      international = digits.substring(home.internationalPrefix.length);
    } else if (home.keepsTrunk) {
      international = home.callingCode + digits;
    } else if (home.trunkPrefix.isEmpty) {
      international = home.callingCode + digits;
    } else if (digits.startsWith(home.trunkPrefix)) {
      international =
          home.callingCode + digits.substring(home.trunkPrefix.length);
    } else if (home.trunkOptional) {
      international = home.callingCode + digits;
    } else {
      return null;
    }
  }
  // E.164 has at most 15 digits; fewer than 8 is no whole number.
  if (international.length < 8 || international.length > 15) return null;
  if (international.startsWith('0')) return null;
  return '+$international';
}

/// Whether [international] (from [e164]) is a Dutch mobile number, which
/// gets the label *Mobile* when taken from the text (T3.6, PO decision e).
bool isDutchMobile(String international) => international.startsWith('+316');
