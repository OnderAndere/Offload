import 'package:flutter_test/flutter_test.dart';
import 'package:offload/domain/ids/uuid_v7.dart';
import 'package:offload/domain/items/item.dart';
import 'package:offload/domain/items/item_enums.dart';

void main() {
  test('capture time is derived from the id (CLAUDE.md rule 6)', () {
    final created = DateTime.utc(2026, 9, 27, 8, 15);
    final item = Item(
      id: UuidV7Generator(now: () => created.millisecondsSinceEpoch).next(),
      rawText: 'Call Jan',
      status: ItemStatus.inbox,
      source: ItemSource.app,
    );

    expect(item.capturedAt, created);
  });

  group('hasCapturableText (REQ-018)', () {
    test('any visible text can be captured', () {
      expect(hasCapturableText('x'), isTrue);
      expect(hasCapturableText('  Call Jan  '), isTrue);
      expect(hasCapturableText('line one\nline two'), isTrue);
    });

    test('empty or only white space cannot be captured', () {
      expect(hasCapturableText(''), isFalse);
      expect(hasCapturableText('   '), isFalse);
      expect(hasCapturableText('\n\t '), isFalse);
    });
  });
}
