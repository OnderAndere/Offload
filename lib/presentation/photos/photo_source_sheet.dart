import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// The sheet that asks where a photo comes from, under [title] ("Foto
/// toevoegen" for an item, "Handschrift lezen" for handwriting): true for the
/// camera, false for the gallery, null when closed. Only where a photo can
/// be taken (Android); elsewhere the Open window comes straight away.
Future<bool?> choosePhotoSource(BuildContext context, {required String title}) {
  final l10n = AppLocalizations.of(context);
  return showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text(l10n.photoTake),
            onTap: () => Navigator.of(context).pop(true),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(l10n.photoFromGallery),
            onTap: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    ),
  );
}
