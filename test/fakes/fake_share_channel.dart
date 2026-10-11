import 'dart:io';

import 'package:offload/platform/share/share_channel.dart';

/// Records what the app shares; answers with [result], or fails when
/// [fail] is set. A shared file is written into [fileDirectory] when one is
/// given; without it the writer does not run.
class FakeShareChannel implements ShareChannel {
  FakeShareChannel({
    this.textTargets = const [ShareTarget.system],
    this.fileTargets = const [ShareTarget.system],
    this.result = ShareResult.done,
    this.fail = false,
    this.fileDirectory,
  });

  @override
  final List<ShareTarget> textTargets;

  @override
  final List<ShareTarget> fileTargets;

  final Directory? fileDirectory;

  ShareResult result;
  bool fail;

  final shared =
      <
        ({String text, ShareTarget target, String subject, String fileTypeName})
      >[];

  @override
  Future<ShareResult> shareText(
    String text, {
    required ShareTarget target,
    String subject = '',
    String fileTypeName = '',
  }) async {
    if (fail) throw const ShareChannelException('fake failure');
    shared.add((
      text: text,
      target: target,
      subject: subject,
      fileTypeName: fileTypeName,
    ));
    return result;
  }

  final sharedFiles =
      <
        ({String fileName, String mimeType, ShareTarget target, String subject})
      >[];

  @override
  Future<ShareResult> shareFile({
    required String fileName,
    required String mimeType,
    required ShareTarget target,
    required Future<void> Function(File file) write,
    String subject = '',
  }) async {
    if (fail) throw const ShareChannelException('fake failure');
    final directory = fileDirectory;
    if (directory != null) await write(File('${directory.path}/$fileName'));
    sharedFiles.add((
      fileName: fileName,
      mimeType: mimeType,
      target: target,
      subject: subject,
    ));
    return result;
  }
}
