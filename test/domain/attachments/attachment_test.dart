import 'package:flutter_test/flutter_test.dart';
import 'package:offload/domain/attachments/attachment.dart';

/// The kinds of Settings → Storage (T5.1).
void main() {
  test('images are photos, sounds are audio, the rest is other', () {
    expect(attachmentKindOf('image/jpeg'), AttachmentKind.photo);
    expect(attachmentKindOf(' IMAGE/PNG '), AttachmentKind.photo);
    expect(attachmentKindOf('audio/mp4'), AttachmentKind.audio);
    expect(attachmentKindOf('application/pdf'), AttachmentKind.other);
    expect(attachmentKindOf('video/mp4'), AttachmentKind.other);
    expect(attachmentKindOf(''), AttachmentKind.other);
  });
}
