import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Where a new file goes on Android (DD-014): the share menu, or the
/// document picker to save it on the device.
enum FileDestination { share, save }

/// Asks where a new file goes, under [title] (the action, e.g. "Back-up
/// maken"); null when the sheet was closed. Only where files can be shared
/// (Android); Windows saves directly.
Future<FileDestination?> chooseFileDestination(
  BuildContext context,
  String title,
) => showModalBottomSheet<FileDestination>(
  context: context,
  showDragHandle: true,
  builder: (_) => _FileDestinationSheet(title: title),
);

class _FileDestinationSheet extends StatelessWidget {
  const _FileDestinationSheet({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          ListTile(
            leading: const Icon(Icons.share_outlined),
            title: Text(l10n.backupShare),
            onTap: () => Navigator.of(context).pop(FileDestination.share),
          ),
          ListTile(
            leading: const Icon(Icons.save_alt),
            title: Text(l10n.backupSaveOnDevice),
            onTap: () => Navigator.of(context).pop(FileDestination.save),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
