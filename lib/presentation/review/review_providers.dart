import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../startup/app_storage_provider.dart';

/// Whether the weekly review is open in the list pane on Windows (DD-018
/// point 8): a mode, as triage, that the rail or Esc ends. On a phone the
/// review is a screen of its own instead.
final weeklyReviewOpenProvider = StateProvider<bool>((ref) => false);

/// Whether the open review takes both panes on Windows: during its
/// Overview step, as the Overview destination does (DD-018 point 12 (g)).
final weeklyReviewWideProvider = StateProvider<bool>((ref) => false);

/// After how many weeks an untouched open item is stale (AC REQ-051): a
/// setting of this device, read at start from `local_state`.
final staleAfterProvider = NotifierProvider<StaleAfterNotifier, int>(
  StaleAfterNotifier.new,
);

/// After how many days since the last completed review a new one is due
/// (DD-018 point 8): a setting of this device.
final reviewDueAfterProvider = NotifierProvider<ReviewDueAfterNotifier, int>(
  ReviewDueAfterNotifier.new,
);

class ReviewDueAfterNotifier extends Notifier<int> {
  @override
  int build() => ref.watch(storageProvider).reviewDueAfterDays;

  /// Applies [days] at once, then stores it. Throws when storing fails;
  /// the choice then still applies until the app restarts.
  Future<void> choose(int days) async {
    state = days;
    await ref.read(storageProvider).saveReviewDueAfterDays(days);
  }
}

/// When a weekly review last reached its end screen on this device; null
/// when never (DD-018 point 8).
final lastReviewProvider = NotifierProvider<LastReviewNotifier, DateTime?>(
  LastReviewNotifier.new,
);

class LastReviewNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() => ref.watch(storageProvider).lastReviewCompletedAt;

  /// Records a completed review at [moment]: Today hides its line at once,
  /// even when storing fails (then it comes back after a restart).
  Future<void> complete(DateTime moment) async {
    state = moment.toUtc();
    await ref.read(storageProvider).saveLastReviewCompletedAt(moment);
  }
}

class StaleAfterNotifier extends Notifier<int> {
  @override
  int build() => ref.watch(storageProvider).staleAfterWeeks;

  /// Applies [weeks] at once, then stores it. Throws when storing fails;
  /// the choice then still applies until the app restarts.
  Future<void> choose(int weeks) async {
    state = weeks;
    await ref.read(storageProvider).saveStaleAfterWeeks(weeks);
  }
}
