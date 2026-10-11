import '../items/item.dart';
import '../items/revisit.dart';
import '../projects/project.dart';
import '../projects/project_overview.dart';
import '../time/local_date.dart';
import 'horizon.dart';

/// How long something has stood still (DD-017): four classes from
/// blue-grey to dark orange.
enum StandstillLevel {
  /// Less than a week.
  fresh,

  /// One to three weeks.
  weeks,

  /// Three to six weeks.
  longer,

  /// Six weeks or more.
  longest;

  static StandstillLevel of(int days) => days < 7
      ? fresh
      : days < 21
      ? weeks
      : days < 42
      ? longer
      : longest;
}

/// One tile of the Standstill: a top-level project ([project], null: no
/// project) with its open items and how long since the most recent touch
/// of any of them.
typedef StandstillTile = ({
  String? project,
  int open,
  int ageDays,
  StandstillLevel level,
});

/// An open item with the days since its last touch and its tile.
typedef StandstillItem = ({Item item, int ageDays, String? lane});

/// The Standstill (REQ-052, DD-018 point 12 (c)).
class Standstill {
  const Standstill({required this.tiles, required this.items});

  /// Most open items first (the treemap lays them out in this order), then
  /// in the order of the projects given, no project last.
  final List<StandstillTile> tiles;

  /// Every open item that counts, untouched the longest first.
  final List<StandstillItem> items;

  /// The three untouched the longest, for the list under the tiles.
  List<StandstillItem> get oldest => items.take(3).toList();

  /// The open items of the tile of [project], untouched the longest first.
  List<StandstillItem> itemsOf(String? project) => [
    for (final entry in items)
      if (entry.lane == project) entry,
  ];
}

/// Days from [item]'s last touch to [now]; its capture when no touch is
/// known. Never negative.
int touchAgeDays(Item item, DateTime now) {
  final touched = item.lastTouch ?? item.capturedAt;
  final days = now.toUtc().difference(touched.toUtc()).inDays;
  return days < 0 ? 0 : days;
}

/// The Standstill of [items] at [now] (DD-018 point 12 (c)): a tile per
/// top-level project with open items ([countsAsOpen]), sized by their
/// number, aged by the most recent touch among them; and the open items,
/// untouched the longest first. A parked item (`isParked`) is left out, as
/// in the weekly review: it comes back by itself.
Standstill standstillOf(
  Iterable<Item> items, {
  required List<Project> projects,
  required DateTime now,
}) {
  final laneOf = overviewLaneOf(projects);
  final open = <String?, int>{};
  final youngest = <String?, int>{};
  final counted = <StandstillItem>[];
  final today = LocalDate.of(now);
  for (final item in items) {
    if (!countsAsOpen(item)) continue;
    if (isParked(item, today)) continue;
    final age = touchAgeDays(item, now);
    final lane = laneOf(item);
    open[lane] = (open[lane] ?? 0) + 1;
    final known = youngest[lane];
    if (known == null || age < known) youngest[lane] = age;
    counted.add((item: item, ageDays: age, lane: lane));
  }
  final order = {for (final (i, p) in projects.indexed) p.id: i};
  int byOrder(String? a, String? b) =>
      (order[a] ?? projects.length).compareTo(order[b] ?? projects.length);
  final lanes = open.keys.toList()
    ..sort((a, b) {
      final bySize = open[b]!.compareTo(open[a]!);
      return bySize != 0 ? bySize : byOrder(a, b);
    });
  return Standstill(
    tiles: [
      for (final lane in lanes)
        (
          project: lane,
          open: open[lane]!,
          ageDays: youngest[lane]!,
          level: StandstillLevel.of(youngest[lane]!),
        ),
    ],
    items: counted
      ..sort((a, b) {
        final byAge = b.ageDays.compareTo(a.ageDays);
        return byAge != 0 ? byAge : a.item.id.compareTo(b.item.id);
      }),
  );
}
