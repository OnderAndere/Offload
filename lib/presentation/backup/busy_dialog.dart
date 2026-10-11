import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../settings/storage_section.dart';

/// Shows a modal "one moment" while [work] runs. With [progress] (bytes
/// done and the total), a bar and "12 MB of 85 MB" once the total is more
/// than a few MB (T7.2b, DD-007 point 5); no cancel button (point 7d).
Future<T> busy<T>(
  BuildContext context,
  Future<T> work, {
  ValueListenable<(int, int)?>? progress,
}) async {
  final navigator = Navigator.of(context);
  final l10n = AppLocalizations.of(context);
  final waiting = Row(
    children: [
      const CircularProgressIndicator(),
      const SizedBox(width: 24),
      Expanded(child: Text(l10n.backupBusy)),
    ],
  );
  unawaited(
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: progress == null
              ? waiting
              : ValueListenableBuilder(
                  valueListenable: progress,
                  builder: (context, value, _) => switch (value) {
                    (final done, final total) when total >= busyProgressFrom =>
                      _ProgressContent(done: done, total: total),
                    _ => waiting,
                  },
                ),
        ),
      ),
    ),
  );
  try {
    return await work;
  } finally {
    navigator.pop();
  }
}

/// From this total on, the progress shows as a bar with the sizes.
const busyProgressFrom = 4 << 20;

/// [busy] with progress for [work], which hears it through its argument.
Future<T> withProgress<T>(
  BuildContext context,
  Future<T> Function(void Function(int done, int total) onProgress) work,
) {
  // Not disposed: the closing dialog may still listen to it, and nothing
  // reports after [work] ends (its port closes first).
  final progress = ValueNotifier<(int, int)?>(null);
  return busy(
    context,
    work((done, total) => progress.value = (done, total)),
    progress: progress,
  );
}

/// The bar and the sizes while a backup or a restore runs.
class _ProgressContent extends StatelessWidget {
  const _ProgressContent({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.backupBusy),
        const SizedBox(height: 16),
        LinearProgressIndicator(value: total == 0 ? null : done / total),
        const SizedBox(height: 8),
        Text(l10n.backupProgress(sizeText(done, l10n), sizeText(total, l10n))),
      ],
    );
  }
}
