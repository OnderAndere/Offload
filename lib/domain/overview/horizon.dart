import '../items/commitment.dart';
import '../items/item.dart';
import '../projects/project.dart';
import '../projects/project_overview.dart';
import '../time/local_date.dart';
import '../tokens/token_processing.dart';

/// How an item shows on the Horizon (REQ-052, DD-018 point 12 (a)). The
/// shape says who acts (a dot: I deliver; a ring: I wait), the colour
/// whether it needs attention now (orange) or not (blue).
enum HorizonMark {
  /// Filled orange: a deadline that has passed.
  overdue,

  /// Filled blue: a deadline of mine in the coming weeks.
  deliver,

  /// Orange ring: waiting past its expected day.
  late,

  /// Blue ring: waiting, expected in the coming weeks.
  waiting;

  /// Whether this is something I deliver: it counts for busy.
  bool get delivers => this == overdue || this == deliver;
}

/// One mark of one item: on [day], in the lane of the top-level project
/// [lane] (null: no project).
typedef HorizonEntry = ({
  Item item,
  HorizonMark mark,
  LocalDate day,
  String? lane,
});

/// One column of the Horizon: an ISO week. The first starts today.
class HorizonWeek {
  const HorizonWeek({
    required this.start,
    required this.end,
    required this.number,
    required this.entries,
    required this.busy,
  });

  /// The first day shown: today for the first week, else the Monday.
  final LocalDate start;

  /// The Sunday.
  final LocalDate end;

  /// The ISO week number.
  final int number;

  /// By day, then the mark (overdue, deliver, late, waiting), then the id.
  /// Overdue and late items are in the first week, on their own day.
  final List<HorizonEntry> entries;

  /// [toDeliver] reaches the threshold ([BusyFrom]).
  final bool busy;

  /// What I deliver this week: the busy count (DD-018 point 12).
  int get toDeliver => entries.where((e) => e.mark.delivers).length;

  /// What I wait for this week.
  int get waiting => entries.length - toDeliver;

  /// The entries in [lane].
  Iterable<HorizonEntry> inLane(String? lane) =>
      entries.where((e) => e.lane == lane);
}

/// The Horizon: [weeks] columns, and the lanes that have something in
/// them.
class Horizon {
  const Horizon({required this.weeks, required this.lanes});

  final List<HorizonWeek> weeks;

  /// Top-level project ids in the order of the projects given, then null
  /// (no project) when it has entries.
  final List<String?> lanes;

  /// How many items are on it (an item with a deadline and an expected
  /// day counts once).
  int get itemCount => {
    for (final week in weeks)
      for (final entry in week.entries) entry.item.id,
  }.length;
}

/// The columns of the Horizon: this week and the five after it (PO
/// 02-10-2026; a setting is parked).
const horizonWeekCount = 6;

/// "Busy from" (DD-018 point 12): a week with this many items to deliver
/// or more is busy. A setting of this device.
abstract final class BusyFrom {
  static const min = 3;
  static const max = 15;
  static const standard = 5;

  /// The stored number, or [standard] for a missing or unknown value.
  static int parse(String? stored) {
    final count = int.tryParse(stored ?? '');
    return count != null && count >= min && count <= max ? count : standard;
  }

  static bool isBusy(int toDeliver, int busyFrom) => toDeliver >= busyFrom;
}

/// The lane (Horizon) or tile (Standstill) of an item, among [projects]:
/// its project, or the parent for a subproject (DD-018 point 12); null for
/// no project, and for a project that is not among [projects].
String? Function(Item item) overviewLaneOf(List<Project> projects) {
  final byId = {for (final p in projects) p.id: p};
  return (item) {
    final project = item.projectId == null ? null : byId[item.projectId];
    if (project == null) return null;
    return project.parentId != null && byId.containsKey(project.parentId)
        ? project.parentId
        : project.id;
  };
}

/// The Horizon of [items] from [today] (REQ-052, DD-018 point 12):
/// - an open item ([countsAsOpen]) with a deadline is a mark of mine on
///   that day, overdue in the first week; a waiting item is one too, as
///   on *Today* (the deadline stays mine);
/// - a waiting item with an expected day is also a ring on that day, late
///   in the first week; without an expected day it is not waiting here;
/// - what lies beyond the last week is left out;
/// - the lane is the item's project, or its parent for a subproject;
///   [projects] gives the order (by name); an unknown project counts as no
///   project.
Horizon horizonOf(
  Iterable<Item> items, {
  required LocalDate today,
  required List<Project> projects,
  required int busyFrom,
  int weeks = horizonWeekCount,
}) {
  final laneOf = overviewLaneOf(projects);

  final firstMonday = today.monday;
  final lastDay = firstMonday.addDays(weeks * 7 - 1);
  final columns = [for (var i = 0; i < weeks; i++) <HorizonEntry>[]];
  int? columnOf(LocalDate day) {
    if (day.compareTo(today) < 0) return 0;
    if (day.compareTo(lastDay) > 0) return null;
    return day.daysSince(firstMonday) ~/ 7;
  }

  void add(Item item, LocalDate day, HorizonMark onTime, HorizonMark past) {
    final column = columnOf(day);
    if (column == null) return;
    columns[column].add((
      item: item,
      mark: day.compareTo(today) < 0 ? past : onTime,
      day: day,
      lane: laneOf(item),
    ));
  }

  for (final item in items) {
    if (!countsAsOpen(item)) continue;
    if (item.dueAt case final due?) {
      add(
        item,
        storedToDateOnly(due),
        HorizonMark.deliver,
        HorizonMark.overdue,
      );
    }
    if (item.expectedAt case final expected? when hasWaitingPart(item)) {
      add(item, expected, HorizonMark.waiting, HorizonMark.late);
    }
  }

  int order(HorizonEntry a, HorizonEntry b) {
    final byDay = a.day.compareTo(b.day);
    if (byDay != 0) return byDay;
    final byMark = a.mark.index.compareTo(b.mark.index);
    return byMark != 0 ? byMark : a.item.id.compareTo(b.item.id);
  }

  final used = {
    for (final column in columns)
      for (final entry in column) entry.lane,
  };
  return Horizon(
    weeks: [
      for (var i = 0; i < weeks; i++)
        () {
          final entries = columns[i]..sort(order);
          final monday = firstMonday.addDays(i * 7);
          final toDeliver = entries.where((e) => e.mark.delivers).length;
          return HorizonWeek(
            start: i == 0 ? today : monday,
            end: monday.addDays(6),
            number: monday.isoWeek,
            entries: List.unmodifiable(entries),
            busy: BusyFrom.isBusy(toDeliver, busyFrom),
          );
        }(),
    ],
    lanes: [
      // Top-level projects, and a subproject whose parent is unknown.
      for (final p in projects)
        if (used.contains(p.id)) p.id,
      if (used.contains(null)) null,
    ],
  );
}
