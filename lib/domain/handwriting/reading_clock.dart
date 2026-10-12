/// The time a reading has had (DD-021, PO 12-10-2026): it stops after
/// `ReadingPolicy.maxReadingTime`. Where the platform pauses reading
/// outside the app (Android freezes it), only the time in the app counts.
class ReadingClock {
  /// [now] is a clock that only goes forward, such as a started
  /// [Stopwatch]'s `elapsed`.
  ReadingClock(this._now);

  final Duration Function() _now;
  Duration _counted = Duration.zero;
  Duration? _since;

  bool get isRunning => _since != null;

  /// Counts from now on; nothing when it already does.
  void run() => _since ??= _now();

  /// Stops counting until [run].
  void pause() {
    final since = _since;
    if (since == null) return;
    _counted += _now() - since;
    _since = null;
  }

  Duration get elapsed {
    final since = _since;
    return since == null ? _counted : _counted + (_now() - since);
  }
}
