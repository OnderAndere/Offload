import 'dart:io';

import 'package:offload/platform/app_directory/app_directory.dart';

/// [AppDirectory] that points at a directory chosen by the test.
class FakeAppDirectory implements AppDirectory {
  FakeAppDirectory(this.directory);

  final Directory directory;

  @override
  Future<Directory> dataDirectory() => directory.create(recursive: true);

  /// What [temporaryFilesSize] answers; it throws when [failTemporary].
  int? temporaryBytes;
  bool failTemporary = false;

  @override
  Future<int?> temporaryFilesSize() async {
    if (failTemporary) throw const FileSystemException('fake failure');
    return temporaryBytes;
  }

  /// What [freeBytes] answers; null: unknown.
  int? free;

  @override
  Future<int?> freeBytes(Directory directory) async => free;
}
