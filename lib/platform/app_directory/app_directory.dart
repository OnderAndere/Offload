import 'dart:io';

/// The directory where Offload keeps its own files: the encrypted database
/// now, encrypted attachments later (DD-006, DD-007). Never shared storage.
abstract class AppDirectory {
  /// Returns the directory; it exists when the future completes.
  Future<Directory> dataDirectory();

  /// The size of Offload's own temporary copies in its cache (a shared
  /// backup or export, a copy for the document picker; T7.5), or null
  /// where the platform keeps none.
  Future<int?> temporaryFilesSize();

  /// The bytes Offload may still write on the drive that holds [directory]
  /// (T7.2b: a backup or a restore checks it first, DD-007 point 5), or
  /// null when the platform cannot tell.
  Future<int?> freeBytes(Directory directory);
}
