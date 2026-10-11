import 'package:flutter_test/flutter_test.dart';
import 'package:offload/domain/backup/backup.dart';

/// The passphrase rules (T7.1, REQ-026; PO decision 03-10-2026).
void main() {
  test('shorter than 12 characters is too short', () {
    expect(passphraseStrength('elf tekens!'), PassphraseStrength.tooShort);
    expect(passphraseStrength(''), PassphraseStrength.tooShort);
  });

  test('characters count, not bytes: Cyrillic is not longer', () {
    expect(passphraseStrength('зеленеяблук'), PassphraseStrength.tooShort);
    expect(
      passphraseStrength('зелене яблук'),
      isNot(PassphraseStrength.tooShort),
    );
  });

  test('12 lower-case letters are fair', () {
    expect(passphraseStrength('abcdefghijkl'), PassphraseStrength.fair);
  });

  test('length and variety make it stronger', () {
    expect(passphraseStrength('vier losse woorden'), PassphraseStrength.good);
    expect(
      passphraseStrength('Vier losse woorden 2026'),
      PassphraseStrength.strong,
    );
    expect(
      passphraseStrength('vier losse woorden hier en daar'),
      PassphraseStrength.strong,
    );
  });

  test('a control character makes it invalid', () {
    expect(passphraseProblem('vier losse woorden'), isNull);
    expect(
      passphraseProblem('vier losse\twoorden'),
      BackupProblem.passphraseInvalid,
    );
    expect(passphraseProblem('kort'), BackupProblem.passphraseTooShort);
  });

  test(
    'room needed: the bytes, a tenth and 16 MiB (T7.2b, DD-007 point 5)',
    () {
      expect(roomNeeded(0), 16 << 20);
      expect(roomNeeded(100 << 20), (100 << 20) + (10 << 20) + (16 << 20));
    },
  );
}
