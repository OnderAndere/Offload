/// Backup with a passphrase (REQ-014, REQ-026, DD-007): the rules that do not
/// depend on storage.
library;

/// The shortest passphrase accepted (PO decision 03-10-2026): about four
/// separate words.
const minPassphraseLength = 12;

/// How strong a passphrase looks, for the indicator in Settings → Backup.
/// A rough guide on length and variety, never a guarantee; anything below
/// [minPassphraseLength] is [tooShort] and cannot be saved.
enum PassphraseStrength { tooShort, fair, good, strong }

/// The strength of [passphrase]: its length (in characters, so Cyrillic counts
/// the same) plus a bonus for each kind of character beyond the first
/// (lower case, upper case, digits, anything else, among which spaces between
/// words).
PassphraseStrength passphraseStrength(String passphrase) {
  final length = passphrase.runes.length;
  if (length < minPassphraseLength) return PassphraseStrength.tooShort;
  var kinds = 0;
  for (final pattern in _kinds) {
    if (pattern.hasMatch(passphrase)) kinds++;
  }
  final score = length + 4 * (kinds - 1);
  if (score >= 28) return PassphraseStrength.strong;
  if (score >= 18) return PassphraseStrength.good;
  return PassphraseStrength.fair;
}

/// Why [passphrase] cannot be used, or null: too short, or holding a
/// control character (which a backup file's settings cannot carry; review
/// backup step A).
BackupProblem? passphraseProblem(String passphrase) {
  if (passphraseStrength(passphrase) == PassphraseStrength.tooShort) {
    return BackupProblem.passphraseTooShort;
  }
  if (_control.hasMatch(passphrase)) return BackupProblem.passphraseInvalid;
  return null;
}

/// The free space a backup or a restore of [bytes] asks for before it
/// starts (T7.2b, DD-007 point 5): the bytes, a tenth more for the database
/// pages around them and a journal, and 16 MiB the drive keeps to spare.
int roomNeeded(int bytes) => bytes + bytes ~/ 10 + (16 << 20);

final _control = RegExp(r'\p{Cc}', unicode: true);

final _kinds = [
  RegExp(r'\p{Ll}', unicode: true),
  RegExp(r'\p{Lu}', unicode: true),
  RegExp(r'\p{N}', unicode: true),
  RegExp(r'[^\p{L}\p{N}]', unicode: true),
];

/// Why a backup could not be made or restored. Nothing changed in any case.
enum BackupProblem {
  /// No passphrase is set yet (Settings → Backup).
  noPassphrase,

  /// The passphrase is shorter than [minPassphraseLength].
  passphraseTooShort,

  /// The passphrase holds a control character (a tab, a line break).
  passphraseInvalid,

  /// The passphrase does not open the file, or it is no backup of Offload:
  /// the two cannot be told apart, as the file is encrypted throughout.
  wrongPassphrase,

  /// Made by a newer version of the app: update the app first.
  tooNew,

  /// The file could not be read or written.
  unreadable,
}

class BackupException implements Exception {
  const BackupException(this.problem);

  final BackupProblem problem;

  @override
  String toString() => 'BackupException(${problem.name})';
}

/// What a backup holds, shown before restoring it. [withAttachments]: made
/// with the attachments, [attachments] of them in it (T7.2b); a backup from
/// before T7.2b has none.
typedef BackupInfo = ({
  int schemaVersion,
  int items,
  DateTime? newestChange,
  bool withAttachments,
  int attachments,
});
