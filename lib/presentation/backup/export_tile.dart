import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/export/drift_export_repository.dart';
import '../../domain/export/export_data.dart';
import '../../domain/export/export_format.dart';
import '../../domain/export/export_json.dart';
import '../../domain/export/export_markdown.dart';
import '../../l10n/app_localizations.dart';
import '../../platform/share/share_channel.dart';
import '../messages.dart';
import '../settings/build_info_provider.dart';
import '../share_channel_provider.dart';
import '../startup/app_storage_provider.dart';
import 'backup_file_picker_provider.dart';
import 'busy_dialog.dart';
import 'export_labels.dart';
import 'file_destination.dart';

/// Reads everything for the export.
final exportRepositoryProvider = Provider<ExportRepository>(
  (ref) => DriftExportRepository(ref.watch(storageProvider)),
);

/// Settings → Backup and export → *Exporteren* (T7.3, REQ-014, DD-007):
/// everything as Markdown or JSON, unencrypted, after a warning confirmed
/// every time. On Android the share menu or the document picker, on Windows
/// "Save as…", as for a backup.
class ExportTile extends ConsumerWidget {
  const ExportTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      leading: const Icon(Icons.description_outlined),
      title: Text(l10n.exportRow),
      subtitle: Text(l10n.exportRowSubtitle),
      onTap: () => _export(context, ref),
    );
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final format = await showDialog<ExportFormat>(
      context: context,
      builder: (_) => const ExportDialog(),
    );
    if (format == null || !context.mounted) return;
    final share = ref.read(shareChannelProvider);
    var destination = FileDestination.save;
    if (share.fileTargets.contains(ShareTarget.system)) {
      final chosen = await chooseFileDestination(context, l10n.exportRow);
      if (chosen == null || !context.mounted) return;
      destination = chosen;
    }
    final name = l10n.exportFileName(_today());
    final labels = L10nExportLabels(l10n);
    final appVersion = ref.read(buildInfoProvider)?.version;
    final exports = ref.read(exportRepositoryProvider);
    Future<void> write(File file) async {
      final data = await exports.read();
      final now = DateTime.now().toUtc();
      final text = switch (format) {
        ExportFormat.markdown => exportMarkdown(data, labels, exportedAt: now),
        ExportFormat.json => exportJson(
          data,
          exportedAt: now,
          appVersion: appVersion,
        ),
      };
      await file.writeAsString(text, encoding: utf8, flush: true);
    }

    try {
      switch (destination) {
        case FileDestination.share:
          final result = await share.shareFile(
            fileName: '$name.${format.extension}', // l10n-ignore: a file name
            mimeType: format.mimeType,
            target: ShareTarget.system,
            subject: name,
            write: (file) => busy(context, write(file)),
          );
          // Android does not say whether it was really sent.
          if (result == ShareResult.done) {
            showMessage(
              messenger,
              SnackBar(content: Text(l10n.exportReadyToShare)),
            );
          }
        case FileDestination.save:
          final saved = await ref
              .read(backupFilePickerProvider)
              .saveFile(
                suggestedName: name,
                extension: format.extension,
                mimeType: format.mimeType,
                fileTypeName: switch (format) {
                  ExportFormat.markdown => l10n.exportMarkdownFileType,
                  ExportFormat.json => l10n.exportJsonFileType,
                },
                write: (file) => busy(context, write(file)),
              );
          if (saved) {
            showMessage(messenger, SnackBar(content: Text(l10n.exportSaved)));
          }
      }
    } catch (_) {
      showMessage(messenger, SnackBar(content: Text(l10n.exportFailed)));
    }
  }

  /// Today as year-month-day, for the file name.
  static String _today() {
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${now.year}-${two(now.month)}-${two(now.day)}'; // l10n-ignore: a date
  }
}

/// Chooses the format, with the warning that the export is not encrypted;
/// *Exporteren* confirms it (PO 09-10-2026: every time). Pops the format,
/// or null.
class ExportDialog extends StatefulWidget {
  const ExportDialog({super.key});

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  ExportFormat _format = ExportFormat.markdown;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(l10n.exportDialogTitle),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock_open, color: theme.colorScheme.error),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.exportWarning,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              RadioGroup<ExportFormat>(
                groupValue: _format,
                onChanged: (value) {
                  if (value != null) setState(() => _format = value);
                },
                child: Column(
                  children: [
                    RadioListTile<ExportFormat>(
                      contentPadding: EdgeInsets.zero,
                      value: ExportFormat.markdown,
                      title: Text(l10n.exportMarkdown),
                      subtitle: Text(l10n.exportMarkdownHint),
                    ),
                    RadioListTile<ExportFormat>(
                      contentPadding: EdgeInsets.zero,
                      value: ExportFormat.json,
                      title: Text(l10n.exportJson),
                      subtitle: Text(l10n.exportJsonHint),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.backupCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_format),
          child: Text(l10n.exportConfirm),
        ),
      ],
    );
  }
}
