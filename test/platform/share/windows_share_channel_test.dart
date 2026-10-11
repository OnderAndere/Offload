import 'package:flutter_test/flutter_test.dart';
import 'package:offload/platform/share/share_channel.dart';
import 'package:offload/platform/share/windows_share_channel.dart';

/// The file name "Save as…" proposes (REQ-043, DD-014).
void main() {
  test('is the subject without the characters Windows forbids', () {
    expect(
      suggestedFileName('Offerte: renovatie/schuur?'),
      'Offerte renovatie schuur',
    );
    expect(suggestedFileName('Tab\there'), 'Tab here');
  });

  test('has no dot or space at the end', () {
    expect(suggestedFileName('Klaar...'), 'Klaar');
  });

  test('is cut to the maximum length', () {
    expect(suggestedFileName('a' * 100, maxLength: 60), 'a' * 60);
  });

  test('avoids reserved device names', () {
    expect(suggestedFileName('con'), 'con_');
    expect(suggestedFileName('LPT1.txt'), 'LPT1_.txt');
    expect(suggestedFileName('Console'), 'Console');
  });

  test('falls back to the app name when nothing is left', () {
    expect(suggestedFileName(''), 'Offload');
    expect(suggestedFileName('???'), 'Offload');
  });

  test('shareFile fails through its future, not synchronously', () {
    late Future<void> result;
    expect(
      () => result = WindowsShareChannel().shareFile(
        fileName: 'x.offload',
        mimeType: 'application/octet-stream',
        target: ShareTarget.system,
        write: (_) async {},
      ),
      returnsNormally,
    );
    expect(result, throwsArgumentError);
  });
}
