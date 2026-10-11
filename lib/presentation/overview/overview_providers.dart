import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/overview/horizon.dart';
import '../../domain/overview/standstill.dart';
import '../../domain/time/local_date.dart';
import '../inbox/inbox_card.dart';
import '../projects/project_providers.dart';
import '../startup/app_storage_provider.dart';

/// "Busy from" in items (DD-018 point 12): a setting of this device.
final busyFromProvider = NotifierProvider<BusyFromNotifier, int>(
  BusyFromNotifier.new,
);

class BusyFromNotifier extends Notifier<int> {
  @override
  int build() => ref.watch(storageProvider).busyFromItems;

  /// Applies [count] at once, then stores it. Throws when storing fails;
  /// the choice then still applies until the app restarts.
  Future<void> choose(int count) async {
    final kept = count.clamp(BusyFrom.min, BusyFrom.max);
    state = kept;
    await ref.read(storageProvider).saveBusyFromItems(kept);
  }
}

/// The Horizon from today (T10.7, REQ-052, DD-018 point 12): six weeks,
/// a lane per top-level project.
final horizonProvider = Provider.autoDispose<Horizon>((ref) {
  final now = ref.watch(minuteClockProvider).valueOrNull ?? DateTime.now();
  return horizonOf(
    ref.watch(liveItemsProvider).valueOrNull ?? const [],
    today: LocalDate.of(now),
    projects: ref.watch(projectsProvider).valueOrNull ?? const [],
    busyFrom: ref.watch(busyFromProvider),
  );
});

/// The Standstill now (T10.7, REQ-052, DD-018 point 12 (c)): a tile per
/// top-level project, and the open items untouched the longest first.
final standstillProvider = Provider.autoDispose<Standstill>((ref) {
  final now = ref.watch(minuteClockProvider).valueOrNull ?? DateTime.now();
  return standstillOf(
    ref.watch(liveItemsProvider).valueOrNull ?? const [],
    projects: ref.watch(projectsProvider).valueOrNull ?? const [],
    now: now,
  );
});
