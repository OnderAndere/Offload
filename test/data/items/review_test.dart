import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/items/drift_item_repository.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/domain/sync/change_operation.dart';

import '../../fakes/test_storage.dart';

/// What the weekly review reads and writes on items (T3.4 + T10.6, AC
/// REQ-051).
void main() {
  late AppStorage storage;
  late DriftItemRepository items;

  setUp(() async {
    storage = await openTestStorage();
    items = DriftItemRepository(storage);
  });
  tearDown(() => storage.close());

  test('an item knows when it changed, from its HLC', () async {
    final before = DateTime.now().toUtc().subtract(const Duration(seconds: 1));
    final id = await items.capture('Bel Jan', source: ItemSource.app);
    final item = (await items.watchLiveItems().first).single;
    expect(item.id, id);
    expect(item.changedAt!.isAfter(before), isTrue);
    expect(item.reviewedAt, isNull);
    expect(item.lastTouch, item.changedAt);
  });

  test('markReviewed records the moment through the change log', () async {
    final id = await items.capture('Bel Jan', source: ItemSource.app);
    await items.markReviewed(id);

    final item = (await items.watchLiveItems().first).single;
    expect(item.reviewedAt, isNotNull);
    final log = await (storage.database.select(
      storage.database.changeLog,
    )..where((e) => e.entityId.equals(id))).get();
    expect(log.last.operation, ChangeOperation.update);
    expect(log.last.payload, contains('reviewed_at'));
  });
}
