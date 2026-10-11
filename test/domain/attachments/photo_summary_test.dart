import 'package:flutter_test/flutter_test.dart';
import 'package:offload/domain/attachments/photo_summary.dart';

/// The photos per item for the cards in the lists (T5.4).
void main() {
  ItemAttachmentRow row(
    String id,
    String itemId, [
    String mime = 'image/jpeg',
  ]) => (id: id, itemId: itemId, mimeType: mime);

  test('nothing without photos', () {
    expect(summarisePhotos(const []), isEmpty);
    expect(summarisePhotos([row('0192a001', 'a', 'audio/mp4')]), isEmpty);
  });

  test('the newest photo is the highest id, in any order, with the count', () {
    final summary = summarisePhotos([
      row('0192a002', 'a'),
      row('0192a003', 'a', 'image/png'),
      row('0192a001', 'a'),
      row('0192a004', 'b'),
    ]);
    expect(summary, {
      'a': (newestId: '0192a003', count: 3),
      'b': (newestId: '0192a004', count: 1),
    });
  });

  test('other attachments do not count, nor make an item newest', () {
    final summary = summarisePhotos([
      row('0192a001', 'a'),
      row('0192a009', 'a', 'application/pdf'),
      row('0192a00a', 'a', 'audio/mp4'),
    ]);
    expect(summary, {'a': (newestId: '0192a001', count: 1)});
  });
}
