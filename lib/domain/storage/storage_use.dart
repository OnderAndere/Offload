import '../attachments/attachment.dart';

/// Storage use in Settings (T7.5, DD-006; PO decisions 09-10-2026): what
/// Offload keeps on this device. Attachments per type and the speech model
/// join when they exist (T5.1, T6.1).
class StorageUse {
  const StorageUse({
    required this.databaseBytes,
    required this.temporaryBytes,
    this.temporaryUnknown = false,
    required this.items,
    required this.trashedItems,
    required this.projects,
    required this.people,
    this.attachmentBytes = const {},
  });

  /// The encrypted database with its companion files.
  final int databaseBytes;

  /// Offload's own temporary copies (a shared backup or export); null where
  /// the platform keeps none (Windows).
  final int? temporaryBytes;

  /// The temporary copies could not be measured: shown as such, not left
  /// out as if there were none (review).
  final bool temporaryUnknown;

  /// Every item, the ones in the trash included.
  final int items;

  /// Of [items], those in the trash: still in the database (PO).
  final int trashedItems;

  /// Projects outside the trash, archived ones included.
  final int projects;

  /// People outside the trash; merged ones are not counted.
  final int people;

  /// The size of the attachments per kind; empty when there are none, and
  /// then Settings shows no row for them (T5.1, PO 09-10-2026).
  final Map<AttachmentKind, int> attachmentBytes;
}

/// The units a size is shown in: decimal, as Android's own storage screen.
enum ByteUnit { kilobytes, megabytes, gigabytes }

/// [bytes] as a value in the unit that suits it: whole kilobytes below a
/// megabyte (at least 1 kB for any content, 0 kB for nothing), else
/// megabytes or gigabytes with one decimal. The unit is chosen after
/// rounding, so 999,999 bytes are 1.0 MB, never "1000 kB" (review).
({double value, ByteUnit unit}) byteAmount(int bytes) {
  const kilo = 1000;
  const mega = kilo * kilo;
  const giga = mega * kilo;
  if (bytes <= 0) return (value: 0, unit: ByteUnit.kilobytes);
  final kilobytes = (bytes / kilo).ceilToDouble();
  if (kilobytes < kilo) return (value: kilobytes, unit: ByteUnit.kilobytes);
  final megabytes = _oneDecimal(bytes / mega);
  if (megabytes < kilo) return (value: megabytes, unit: ByteUnit.megabytes);
  return (value: _oneDecimal(bytes / giga), unit: ByteUnit.gigabytes);
}

double _oneDecimal(double value) => (value * 10).roundToDouble() / 10;
