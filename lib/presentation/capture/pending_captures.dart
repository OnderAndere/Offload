import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/items/item_repository.dart';
import '../../platform/capture/capture_channel.dart';
import '../../platform/capture/platform_capture_channel.dart';
import '../../platform/desktop_shell/desktop_shell.dart';
import '../../platform/desktop_shell/platform_desktop_shell.dart';
import '../items/item_providers.dart';
import '../tokens/token_processor_provider.dart';

/// Capture channels outside the app, such as the Android widget (DD-010).
final captureChannelProvider = Provider<CaptureChannel>(
  (ref) => createPlatformCaptureChannel(),
);

/// The app's presence outside its window: the Windows tray (DD-010).
final desktopShellProvider = Provider<DesktopShell>(
  (ref) => createPlatformDesktopShell(),
);

/// Whether the global capture hotkey is registered: false when another
/// program already owns it, null on platforms without one (REQ-017).
final hotkeyRegisteredProvider = FutureProvider<bool?>(
  (ref) => ref.watch(captureChannelProvider).hotkeyRegistered(),
);

/// The note that the hotkey is taken was closed this session.
final hotkeyNoticeDismissedProvider = StateProvider<bool>((ref) => false);

/// What [importPendingCaptures] did: the captures now in the inbox and how
/// many were set aside because they could not be read or stored.
typedef PendingImport = ({List<String> stored, int setAside});

/// Moves captures waiting outside the app into the inbox (REQ-001, DD-010).
///
/// Stores first, then acknowledges: if the app stops in between, the
/// captures come back and are stored once, because their ids are fixed at
/// the moment of capture. A capture the repository refuses is set aside,
/// never deleted, so it cannot block the ones after it. A failure of the
/// storage itself stops the import; what was not acknowledged comes back.
Future<PendingImport> importPendingCaptures(
  CaptureChannel channel,
  ItemRepository repository,
) async {
  final pending = await channel.pending();
  final stored = <String>[];
  final refused = <String>[];
  try {
    for (final capture in pending.captures) {
      try {
        // False when it was stored before: acknowledge it all the same.
        await repository.captureWithId(
          capture.id,
          capture.rawText,
          source: capture.source,
        );
        stored.add(capture.id);
      } on ArgumentError {
        refused.add(capture.id);
      }
    }
  } finally {
    if (stored.isNotEmpty) await channel.acknowledge(stored);
  }
  final setAside = refused.isEmpty ? 0 : await channel.setAside(refused);
  return (stored: stored, setAside: pending.newlyQuarantined + setAside);
}

/// What the inbox tells about captures from outside the app.
class PendingCaptureNotice {
  const PendingCaptureNotice({this.unreadable = 0, this.failed = false});

  /// Captures set aside this session because they could not be read.
  final int unreadable;

  /// The last attempt to fetch captures failed; they stay in the queue.
  final bool failed;
}

/// Fetches waiting captures at start and whenever the app comes back.
final pendingCapturesProvider =
    NotifierProvider<PendingCapturesNotifier, PendingCaptureNotice>(
      PendingCapturesNotifier.new,
    );

class PendingCapturesNotifier extends Notifier<PendingCaptureNotice> {
  Future<void>? _running;
  bool _startScanDone = false;

  @override
  PendingCaptureNotice build() => const PendingCaptureNotice();

  /// Imports the waiting captures; one run at a time.
  Future<void> fetch() => _running ??= _fetch().whenComplete(() {
    _running = null;
  });

  Future<void> _fetch() async {
    final processor = ref.read(tokenProcessorProvider);
    var imported = const <String>[];
    try {
      final result = await importPendingCaptures(
        ref.read(captureChannelProvider),
        ref.read(itemRepositoryProvider),
      );
      imported = result.stored;
      state = PendingCaptureNotice(
        unreadable: state.unreadable + result.setAside,
      );
    } catch (_) {
      // Nothing is lost: what was not acknowledged stays in the queue and
      // comes back at the next attempt.
      state = PendingCaptureNotice(unreadable: state.unreadable, failed: true);
    }
    // Persons, tags and deadline of the new captures (T2.2 step B); at the
    // first fetch after start also of every item still without them. Derived
    // work: a failure is retried at the next start.
    if (!_startScanDone) {
      _startScanDone = true;
      try {
        await processor.processOutdated();
      } catch (_) {
        // Retried at the next start.
      }
      return;
    }
    for (final id in imported) {
      try {
        await processor.process(id);
      } catch (_) {
        // This one is retried at the next start; the others go on.
      }
    }
  }

  /// Hides the note about unreadable captures.
  void dismissUnreadable() =>
      state = PendingCaptureNotice(failed: state.failed);
}
