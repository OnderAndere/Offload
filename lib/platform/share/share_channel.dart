import 'dart:io';

/// Where shared text or a file can go (DD-014).
enum ShareTarget {
  /// The platform's share menu: Android `ACTION_SEND`, the user picks the
  /// app. For a file: a copy in the app's own cache, handed over through a
  /// `FileProvider`.
  system,

  /// The clipboard (Windows).
  clipboard,

  /// A text file the user places with "Save as…" (Windows). Never deleted
  /// by the app (hard rule 2).
  file,
}

enum ShareResult {
  /// Handed over: copied, saved, or passed to the share menu (Android does
  /// not say whether the user then really sent it).
  done,

  /// The user closed the "Save as…" window without saving.
  cancelled,
}

/// Sending something out of the app (DD-014): one abstraction for sharing
/// an item (REQ-043), a backup (REQ-014) and later the vCard (REQ-040) and
/// the sync package (REQ-035).
abstract class ShareChannel {
  /// The targets for text on this platform, in the order to offer them.
  List<ShareTarget> get textTargets;

  /// Sends [text] exactly as given to [target], one of [textTargets].
  /// [subject] is the subject for the share menu and the proposed file
  /// name; [fileTypeName] names text files in the "Save as…" window, in the
  /// UI language. Throws [ShareChannelException] when it fails.
  Future<ShareResult> shareText(
    String text, {
    required ShareTarget target,
    String subject = '',
    String fileTypeName = '',
  });

  /// The targets for files on this platform, in the order to offer them;
  /// empty where files are not shared this way (Windows saves them with
  /// "Save as…" instead).
  List<ShareTarget> get fileTargets;

  /// Lets [write] write a file named [fileName] into the app's share
  /// folder, then sends it as [mimeType] to [target], one of [fileTargets].
  /// The folder holds one shared file at a time: an earlier one is removed
  /// first, and one left behind goes after a day (DD-014, SPEC Q12). Only a
  /// file the user chose to send, or an encrypted one, may be shared this
  /// way (CLAUDE.md rule 2). [subject] is the subject for the share menu.
  /// Throws [ShareChannelException] when the hand-over fails; what [write]
  /// throws passes through, and then nothing is shared.
  Future<ShareResult> shareFile({
    required String fileName,
    required String mimeType,
    required ShareTarget target,
    required Future<void> Function(File file) write,
    String subject = '',
  });
}

class ShareChannelException implements Exception {
  const ShareChannelException(this.message);

  final String message;

  @override
  String toString() => 'ShareChannelException: $message';
}
