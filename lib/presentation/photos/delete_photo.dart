import 'package:flutter/material.dart';

import '../../data/attachments/photo_storage_service.dart';
import '../../l10n/app_localizations.dart';
import '../messages.dart';

/// Asks "Foto verwijderen?" and then removes photo [id] with its thumbnail,
/// without undo (DD-018 point 19 (c)). True when it was removed.
Future<bool> deletePhoto(
  BuildContext context,
  PhotoStorageService service,
  String id,
) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final sure = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.photoDeleteTitle),
      content: Text(l10n.photoDeleteBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.photoDeleteCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.photoDelete),
        ),
      ],
    ),
  );
  if (sure != true) return false;
  try {
    await service.delete(id);
    return true;
  } catch (_) {
    showMessage(messenger, SnackBar(content: Text(l10n.photoDeleteFailed)));
    return false;
  }
}
