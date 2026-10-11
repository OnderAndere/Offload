/// Hybrid logical clock (HLC) timestamps for the sync-ready data model
/// (REQ-008, DD-003).
///
/// An [Hlc] combines physical wall-clock time with a logical counter, so
/// timestamps from one device are strictly increasing even when several
/// changes happen in the same millisecond or the wall clock jumps backwards.
/// The packed string form sorts lexicographically in timestamp order.
library;

/// A single HLC timestamp.
final class Hlc implements Comparable<Hlc> {
  /// Validates in all build modes, so an invalid timestamp can never be
  /// packed into a string that [Hlc.parse] would reject.
  Hlc(this.millis, this.counter, this.node) {
    if (millis < 0 || millis > maxMillis) {
      throw ArgumentError.value(millis, 'millis', 'out of range');
    }
    if (counter < 0 || counter > maxCounter) {
      throw ArgumentError.value(counter, 'counter', 'out of range');
    }
    if (!isValidNode(node)) {
      throw ArgumentError.value(node, 'node', 'must be non-empty without "-"');
    }
  }

  /// Parses the form produced by [pack].
  factory Hlc.parse(String packed) {
    final match = _packed.firstMatch(packed);
    if (match == null) throw FormatException('Not a packed HLC', packed);
    return Hlc(
      int.parse(match[1]!),
      int.parse(match[2]!, radix: 16),
      match[3]!,
    );
  }

  static const maxCounter = 0xFFFF;
  static const maxMillis = 999999999999999; // 15 decimal digits

  /// Whether [node] can be used as the node part of a packed HLC.
  static bool isValidNode(String node) =>
      node.isNotEmpty && !node.contains('-');

  static final _packed = RegExp(r'^(\d{15})-([0-9a-f]{4})-([^-]+)$');
  static const _millisDigits = 15;
  static const _counterDigits = 4;

  /// Physical time in milliseconds since the Unix epoch (UTC).
  final int millis;

  /// Logical counter for events within the same [millis].
  final int counter;

  /// Identifier of the device (node) that produced this timestamp.
  final String node;

  /// Fixed-width text form: `<millis:15 digits>-<counter:4 hex>-<node>`.
  String pack() =>
      '${millis.toString().padLeft(_millisDigits, '0')}-'
      '${counter.toRadixString(16).padLeft(_counterDigits, '0')}-'
      '$node';

  @override
  int compareTo(Hlc other) {
    if (millis != other.millis) return millis.compareTo(other.millis);
    if (counter != other.counter) return counter.compareTo(other.counter);
    return node.compareTo(other.node);
  }

  @override
  bool operator ==(Object other) =>
      other is Hlc &&
      other.millis == millis &&
      other.counter == counter &&
      other.node == node;

  @override
  int get hashCode => Object.hash(millis, counter, node);

  @override
  String toString() => pack();
}

/// Issues strictly increasing [Hlc] timestamps for one device.
///
/// Receiving remote timestamps (for sync) is deliberately not implemented:
/// synchronisation is out of scope for v1 (REQ-007).
class HlcClock {
  HlcClock({required this.node, this._last, int Function()? now})
    : _now = now ?? _wallClockMillis {
    if (!Hlc.isValidNode(node)) {
      throw ArgumentError.value(node, 'node', 'must be non-empty without "-"');
    }
    final last = _last;
    if (last != null && last.node != node) {
      throw ArgumentError.value(last, 'last', 'belongs to node ${last.node}');
    }
  }

  /// Identifier of this device; persisted by the data layer.
  final String node;

  final int Function() _now;
  Hlc? _last;

  /// The most recently issued timestamp, if any (to persist across restarts).
  Hlc? get last => _last;

  /// Returns a timestamp greater than every timestamp issued before.
  Hlc tick() {
    final wall = _now();
    final previous = _last;
    final Hlc next;
    if (previous == null || wall > previous.millis) {
      next = Hlc(wall, 0, node);
    } else if (previous.counter < Hlc.maxCounter) {
      // Same millisecond, or the wall clock went backwards: keep the
      // previous physical time and count up.
      next = Hlc(previous.millis, previous.counter + 1, node);
    } else {
      // Counter exhausted within one millisecond: borrow the next one.
      next = Hlc(previous.millis + 1, 0, node);
    }
    _last = next;
    return next;
  }

  static int _wallClockMillis() =>
      DateTime.now().toUtc().millisecondsSinceEpoch;
}

/// The physical time of the packed HLC [packed], in UTC, or null for text
/// that is no HLC.
DateTime? hlcTime(String packed) {
  try {
    return DateTime.fromMillisecondsSinceEpoch(
      Hlc.parse(packed).millis,
      isUtc: true,
    );
  } on FormatException {
    return null;
  }
}
