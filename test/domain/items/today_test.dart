import 'package:flutter_test/flutter_test.dart';
import 'package:offload/domain/ids/uuid_v7.dart';
import 'package:offload/domain/items/item.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/domain/items/today.dart';
import 'package:offload/domain/time/local_date.dart';
import 'package:offload/domain/tokens/token_processing.dart';

/// Today: overdue and due today, high priority on top, then the oldest
/// deadline first (DD-018 point 4, T4b.1).
void main() {
  final today = LocalDate(2026, 9, 28);
  // One millisecond apart, so the ids sort in the order of capture.
  var clock = DateTime.utc(2026, 9, 20).millisecondsSinceEpoch;
  final ids = UuidV7Generator(now: () => clock++);

  Item item(
    String text, {
    LocalDate? due,
    ItemStatus status = ItemStatus.active,
    ItemPriority? priority,
  }) => Item(
    id: ids.next(),
    rawText: text,
    status: status,
    source: ItemSource.app,
    dueAt: due == null ? null : dateOnlyToStored(due),
    priority: priority,
  );

  List<String> texts(List<Item> items) => [for (final i in items) i.rawText];

  test('splits overdue from today and leaves out later and no deadline', () {
    final sections = todaySections([
      item('tomorrow', due: today.addDays(1)),
      item('today', due: today),
      item('none'),
      item('yesterday', due: today.addDays(-1)),
    ], today);
    expect(texts(sections.overdue), ['yesterday']);
    expect(texts(sections.today), ['today']);
  });

  test('oldest deadline first, then the order of capture', () {
    final first = item('first today', due: today);
    final old = item('three days late', due: today.addDays(-3));
    final second = item('second today', due: today);
    final late = item('one day late', due: today.addDays(-1));
    final sections = todaySections([second, late, first, old], today);
    expect(texts(sections.overdue), ['three days late', 'one day late']);
    expect(texts(sections.today), ['first today', 'second today']);
  });

  test('high priority on top; the rest keeps its order, low included', () {
    final low = item(
      'low, oldest',
      due: today.addDays(-5),
      priority: ItemPriority.low,
    );
    final none = item('no priority', due: today.addDays(-4));
    final high = item(
      'high, newest',
      due: today.addDays(-1),
      priority: ItemPriority.high,
    );
    final normal = item(
      'normal',
      due: today.addDays(-2),
      priority: ItemPriority.normal,
    );
    final sections = todaySections([normal, high, none, low], today);
    expect(texts(sections.overdue), [
      'high, newest',
      'low, oldest',
      'no priority',
      'normal',
    ]);
  });

  test('among high items too: oldest deadline first, then capture', () {
    final first = item('first high', due: today, priority: ItemPriority.high);
    final plain = item('plain', due: today);
    final second = item('second high', due: today, priority: ItemPriority.high);
    final older = item(
      'older high',
      due: today.addDays(-2),
      priority: ItemPriority.high,
    );
    final later = item(
      'later high',
      due: today.addDays(-1),
      priority: ItemPriority.high,
    );
    final sections = todaySections([plain, later, second, older, first], today);
    expect(texts(sections.today), ['first high', 'second high', 'plain']);
    expect(texts(sections.overdue), ['older high', 'later high']);
  });

  test('every open status counts, the inbox included; done and archived '
      'do not', () {
    final sections = todaySections([
      for (final status in ItemStatus.values)
        item(status.name, due: today, status: status),
    ], today);
    expect(texts(sections.today), [
      for (final status in ItemStatus.values)
        if (status != ItemStatus.done && status != ItemStatus.archived)
          status.name,
    ]);
  });

  test('isOpen', () {
    expect(isOpen(ItemStatus.inbox), isTrue);
    expect(isOpen(ItemStatus.waiting), isTrue);
    expect(isOpen(ItemStatus.done), isFalse);
    expect(isOpen(ItemStatus.archived), isFalse);
  });
}
