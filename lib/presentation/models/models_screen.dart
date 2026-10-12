import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/model_store.dart';
import '../../domain/handwriting/reading_policy.dart';
import '../../domain/models/model_catalog.dart';
import '../../l10n/app_localizations.dart';
import '../../platform/model_files/model_file_source.dart';
import '../handwriting/handwriting_providers.dart';
import '../settings/storage_section.dart';
import 'model_providers.dart';

/// Settings → *Models* (T6a.3, DD-002, DD-021; PO 11-10-2026): per model
/// what it is for, its name, size and state, where it is published and its
/// licence, and import or remove. Under the handwriting model the choice
/// *Accurate / Faster*. Shared with speech (M6).
class ModelsScreen extends ConsumerWidget {
  const ModelsScreen({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const ModelsScreen()));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).maybePop(),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          appBar: AppBar(title: Text(l10n.modelsTitle)),
          body: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(l10n.modelsIntro),
              ),
              for (final spec in ref.watch(modelCatalogProvider)) ...[
                const Divider(),
                _ModelSection(spec: spec),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// One model: its state and actions, and for the handwriting model the
/// reading speed.
class _ModelSection extends ConsumerWidget {
  const _ModelSection({required this.spec});

  final ModelSpec spec;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final status = ref.watch(modelStatusProvider(spec));
    final state = switch (status) {
      AsyncData(:final value) when value.isComplete => l10n.modelReady,
      AsyncData(:final value) when value.isEmpty => l10n.modelNotImported,
      AsyncData(:final value) => l10n.modelMissing(
        value.missing.map((f) => f.name).join(', '),
      ),
      AsyncError() => l10n.modelStateUnknown,
      _ => '',
    };
    // valueOrNull: `value` throws the error again while a state is unknown.
    final current = status.valueOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          leading: Icon(_iconOf(spec.kind)),
          title: Text(_kindLabel(spec.kind, l10n)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.modelNameSize(spec.name, sizeText(spec.sizeBytes, l10n)),
              ),
              Text(state),
            ],
          ),
          isThreeLine: true,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            l10n.modelSource(spec.source, spec.licence),
            style: theme.textTheme.bodySmall,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              if (current != null && !current.isEmpty)
                TextButton(
                  onPressed: () => unawaited(_remove(context, ref)),
                  child: Text(l10n.modelRemove),
                ),
              if (current != null && !current.isComplete)
                FilledButton(
                  onPressed: () => unawaited(importModel(context, ref, spec)),
                  child: Text(l10n.modelImport),
                ),
            ],
          ),
        ),
        if (spec.kind == ModelKind.handwriting) const _ReadingSpeedChoice(),
      ],
    );
  }

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.modelRemoveTitle),
        content: Text(
          l10n.modelRemoveBody(spec.name, sizeText(spec.sizeBytes, l10n)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.modelRemove),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false)) return;
    var failed = false;
    try {
      await ref.read(modelStoreProvider).remove(spec);
    } on ModelRemoveFailed {
      // On Windows a file still opened by a reading cannot be deleted; what
      // is left shows in the state below.
      failed = true;
    } finally {
      ref
        ..invalidate(modelStatusProvider(spec))
        ..invalidate(modelBytesProvider)
        ..invalidate(handwritingModelProvider);
    }
    if (failed && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.modelRemoveFailed)));
    }
  }

  static IconData _iconOf(ModelKind kind) => switch (kind) {
    ModelKind.handwriting => Icons.draw_outlined,
  };

  static String _kindLabel(ModelKind kind, AppLocalizations l10n) =>
      switch (kind) {
        ModelKind.handwriting => l10n.modelKindHandwriting,
      };
}

/// *Accurate / Faster* (DD-021), per device.
class _ReadingSpeedChoice extends ConsumerWidget {
  const _ReadingSpeedChoice();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final speed = ref.watch(readingSpeedProvider).valueOrNull;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.readingSpeedLabel),
          const SizedBox(height: 8),
          SegmentedButton<ReadingSpeed>(
            segments: [
              ButtonSegment(
                value: ReadingSpeed.accurate,
                label: Text(l10n.readingSpeedAccurate),
              ),
              ButtonSegment(
                value: ReadingSpeed.faster,
                label: Text(l10n.readingSpeedFaster),
              ),
            ],
            selected: {speed ?? ReadingSpeed.accurate},
            onSelectionChanged: speed == null
                ? null
                : (chosen) => unawaited(
                    ref
                        .read(readingSpeedProvider.notifier)
                        .choose(chosen.single),
                  ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.readingSpeedHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Imports files for [spec] (PO 11-10-2026): the file window, a copy with
/// progress and a stop button, then one message with what happened. The
/// platform's technical messages never show (DD-009).
Future<void> importModel(
  BuildContext context,
  WidgetRef ref,
  ModelSpec spec,
) async {
  final l10n = AppLocalizations.of(context);
  final store = ref.read(modelStoreProvider);
  final List<PickedModelFile> picked;
  try {
    picked = await ref
        .read(modelFileSourceProvider)
        .pickFiles(fileTypeName: l10n.modelFileTypeName);
  } on ModelFileException {
    if (context.mounted) await _tell(context, [l10n.modelImportFailed]);
    return;
  }
  if (picked.isEmpty || !context.mounted) return;

  final cancel = ModelFileCancel();
  final progress = ValueNotifier<(int, int)?>(null);
  final navigator = Navigator.of(context);
  final dialog = showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: _ImportProgressDialog(progress: progress, cancel: cancel),
    ),
  );
  // Disposed once the dialog is popped; nothing sets it after that.
  unawaited(dialog.whenComplete(progress.dispose));
  List<String> lines;
  try {
    final result = await store.import(
      spec,
      picked,
      // A file of unknown size counts as the largest; never past the end.
      onProgress: (done, total) =>
          progress.value = (done > total ? total : done, total),
      cancel: cancel,
    );
    lines = [
      if (result.status.isComplete && result.imported.isNotEmpty)
        l10n.modelImportReady
      else if (!result.status.isComplete)
        l10n.modelMissing(result.status.missing.map((f) => f.name).join(', ')),
      if (result.unknown.isNotEmpty)
        l10n.modelImportUnknown(result.unknown.join(', ')),
      if (result.alreadyPresent.isNotEmpty)
        l10n.modelImportAlready(result.alreadyPresent.join(', ')),
    ];
  } on ModelImportNoRoom catch (e) {
    lines = [
      l10n.modelImportNoRoom(sizeText(e.needed, l10n), sizeText(e.free, l10n)),
    ];
  } on ModelFileException catch (e) {
    lines = [
      switch (e.failure) {
        ModelFileFailure.noSpace => l10n.modelImportFull,
        ModelFileFailure.cancelled => l10n.modelImportStopped,
        ModelFileFailure.unavailable => l10n.modelImportFailed,
      },
    ];
  } on Exception {
    // A file of the store that could not be written or renamed.
    lines = [l10n.modelImportFailed];
  } finally {
    navigator.pop();
    ref
      ..invalidate(modelStatusProvider(spec))
      ..invalidate(modelBytesProvider)
      ..invalidate(handwritingModelProvider);
  }
  if (context.mounted) await _tell(context, lines);
}

Future<void> _tell(BuildContext context, List<String> lines) =>
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).modelImportTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (i, line) in lines.indexed)
              Padding(
                padding: EdgeInsets.only(top: i == 0 ? 0 : 12),
                child: Text(line),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(MaterialLocalizations.of(context).okButtonLabel),
          ),
        ],
      ),
    );

/// The bar and the sizes while a model is copied, with a stop button.
class _ImportProgressDialog extends StatefulWidget {
  const _ImportProgressDialog({required this.progress, required this.cancel});

  final ValueListenable<(int, int)?> progress;
  final ModelFileCancel cancel;

  @override
  State<_ImportProgressDialog> createState() => _ImportProgressDialogState();
}

class _ImportProgressDialogState extends State<_ImportProgressDialog> {
  bool _stopping = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      content: ValueListenableBuilder(
        valueListenable: widget.progress,
        builder: (context, value, _) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.modelImporting),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: switch (value) {
                (final done, final total) when total > 0 => done / total,
                _ => null,
              },
            ),
            const SizedBox(height: 8),
            Text(switch (value) {
              (final done, final total) => l10n.modelImportProgress(
                sizeText(done, l10n),
                sizeText(total, l10n),
              ),
              null => '',
            }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _stopping
              ? null
              : () {
                  setState(() => _stopping = true);
                  widget.cancel.cancel();
                },
          child: Text(l10n.modelImportStop),
        ),
      ],
    );
  }
}
