import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/settings/prefix_bar_mode.dart';
import '../startup/app_storage_provider.dart';

/// How the prefix bar is shown (REQ-034), stored in `local_state` and read
/// at start, so quick capture opens without a database read (REQ-001).
final prefixBarModeProvider =
    NotifierProvider<PrefixBarModeNotifier, PrefixBarMode>(
      PrefixBarModeNotifier.new,
    );

class PrefixBarModeNotifier extends Notifier<PrefixBarMode> {
  @override
  PrefixBarMode build() => ref.watch(storageProvider).prefixBarMode;

  /// Applies [mode] at once, then stores it. Throws when storing fails;
  /// the mode then still applies until the app restarts.
  Future<void> choose(PrefixBarMode mode) async {
    state = mode;
    await ref.read(storageProvider).savePrefixBarMode(mode);
  }
}

/// Whether a collapsed prefix bar shows its full buttons; remembered
/// between captures (AC REQ-034).
final prefixBarExpandedProvider =
    NotifierProvider<PrefixBarExpandedNotifier, bool>(
      PrefixBarExpandedNotifier.new,
    );

class PrefixBarExpandedNotifier extends Notifier<bool> {
  @override
  bool build() => ref.watch(storageProvider).prefixBarExpanded;

  /// Applies [expanded] at once. Storing is a convenience: if it fails, the
  /// bar is only back in its old state after a restart.
  Future<void> set(bool expanded) async {
    state = expanded;
    try {
      await ref.read(storageProvider).savePrefixBarExpanded(expanded);
    } catch (_) {
      // Not worth interrupting a capture for.
    }
  }
}
