import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/attachments/photo_compressor.dart';
import '../../data/attachments/photo_storage_service.dart';
import '../../domain/attachments/attachment.dart';
import '../../l10n/app_localizations.dart';
import '../../platform/photo_source/photo_source.dart';
import '../messages.dart';
import 'attachment_image.dart';
import 'delete_photo.dart';
import 'photo_providers.dart';
import 'photo_source_sheet.dart';
import 'photo_viewer.dart';

/// The side of a thumbnail in the row, in logical pixels.
const photoTileSize = 88.0;

/// The photos of an item under its note (DD-018 point 19): "Foto's · n" and
/// a row of thumbnails, the oldest first, scrolling sideways, with a tile
/// while a new photo is made ready. Nothing when there are none.
class ItemPhotos extends ConsumerWidget {
  const ItemPhotos({super.key, required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(photoStorageProvider);
    final photos = ref.watch(itemPhotosProvider(itemId)).valueOrNull ?? [];
    final processing =
        ref.watch(photoAddingProvider(itemId)) == PhotoAdding.processing;
    if (service == null || (photos.isEmpty && !processing)) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.photosHeader(photos.length),
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: photoTileSize,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final (index, photo) in photos.indexed)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _PhotoTile(
                      key: ValueKey(photo.id),
                      photo: photo,
                      label: l10n.photoSemantics(index + 1, photos.length),
                      service: service,
                    ),
                  ),
                if (processing) const _ProcessingTile(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// *Foto toevoegen*, next to the other buttons of the item (DD-018 point
/// 19): on Android a sheet with camera and gallery, on Windows the Open
/// window. Dimmed while a photo is added; absent without attachment files
/// (tests).
class AddPhotoButton extends ConsumerWidget {
  const AddPhotoButton({super.key, required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(photoStorageProvider) == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final idle = ref.watch(photoAddingProvider(itemId)) == PhotoAdding.idle;
    final camera = ref.watch(photoSourceProvider).canTakePhoto;
    return OutlinedButton.icon(
      onPressed: idle ? () => addPhoto(context, itemId) : null,
      icon: const Icon(Icons.add_a_photo_outlined),
      label: Text(camera ? l10n.photoAdd : l10n.photoAddOpen),
    );
  }
}

/// Adds a photo to item [itemId]: taken or chosen, then made small, upright
/// and without EXIF, and encrypted (T5.2). One at a time per item. Carries on
/// when the item detail closes; a failure is a message, and nothing is kept.
Future<void> addPhoto(BuildContext context, String itemId) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final container = ProviderScope.containerOf(context, listen: false);
  final source = container.read(photoSourceProvider);
  final photos = container.read(photoStorageProvider);
  final adding = container.read(photoAddingProvider(itemId).notifier);
  if (photos == null || adding.state != PhotoAdding.idle) return;
  var take = false;
  if (source.canTakePhoto) {
    final choice = await choosePhotoSource(context, title: l10n.photoAdd);
    if (choice == null) return;
    take = choice;
  }
  if (adding.state != PhotoAdding.idle) return;
  adding.state = PhotoAdding.choosing;
  void fail(String message) =>
      showMessage(messenger, SnackBar(content: Text(message)));
  try {
    final Uint8List? bytes;
    try {
      bytes = take
          ? await source.takePhoto()
          : await source.pickPhoto(fileTypeName: l10n.photoFileTypeName);
    } on PhotoSourceException catch (e) {
      fail(
        e.failure == PhotoSourceFailure.tooLarge
            ? l10n.photoTooLarge
            : l10n.photoSourceFailed,
      );
      return;
    }
    if (bytes == null) return;
    adding.state = PhotoAdding.processing;
    try {
      await photos.add(owner: ItemOwner(itemId), source: bytes);
    } on PhotoFormatException {
      fail(l10n.photoUnreadable);
    } catch (_) {
      fail(l10n.photoSaveFailed);
    }
  } finally {
    adding.state = PhotoAdding.idle;
  }
}

/// What the menu of a thumbnail offers.
enum _TileAction { view, delete }

/// One thumbnail: a tap opens the photo; a long press, a right click or
/// <kbd>Del</kbd> offers to delete it.
class _PhotoTile extends StatefulWidget {
  const _PhotoTile({
    super.key,
    required this.photo,
    required this.label,
    required this.service,
  });

  final ItemPhoto photo;

  /// "Foto 2 van 3", for a screen reader and the viewer.
  final String label;
  final PhotoStorageService service;

  @override
  State<_PhotoTile> createState() => _PhotoTileState();
}

class _PhotoTileState extends State<_PhotoTile> {
  final _focus = FocusNode();

  ItemPhoto get photo => widget.photo;
  PhotoStorageService get service => widget.service;

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  /// Opens the viewer. The thumbnail takes the focus first, so it has it
  /// again when the viewer closes: <kbd>Del</kbd> then means this photo,
  /// not the item selected in the list (seen on Windows).
  void _open(BuildContext context) {
    _focus.requestFocus();
    PhotoViewer.open(
      context,
      id: photo.id,
      present: photo.present,
      label: widget.label,
      service: service,
    );
  }

  Future<void> _menu(BuildContext context, Offset at) async {
    final l10n = AppLocalizations.of(context);
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final action = await showMenu<_TileAction>(
      context: context,
      position: RelativeRect.fromRect(
        at & Size.zero,
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(value: _TileAction.view, child: Text(l10n.photoView)),
        PopupMenuItem(value: _TileAction.delete, child: Text(l10n.photoDelete)),
      ],
    );
    if (!context.mounted) return;
    switch (action) {
      case _TileAction.view:
        _open(context);
      case _TileAction.delete:
        await deletePhoto(context, service, photo.id);
      case null:
    }
  }

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    );
    return Semantics(
      label: widget.label,
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.delete): () =>
              deletePhoto(context, service, photo.id),
        },
        child: Material(
          shape: shape,
          clipBehavior: Clip.antiAlias,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: InkWell(
            focusNode: _focus,
            customBorder: shape,
            onTap: () => _open(context),
            onLongPress: () {
              final box = context.findRenderObject()! as RenderBox;
              _menu(context, box.localToGlobal(box.size.center(Offset.zero)));
            },
            onSecondaryTapUp: (details) =>
                _menu(context, details.globalPosition),
            child: SizedBox.square(
              dimension: photoTileSize,
              child: photo.present
                  ? Image(
                      image: ResizeImage.resizeIfNeeded(
                        (photoTileSize * dpr).round(),
                        null,
                        AttachmentImage(
                          photo.id,
                          thumbnail: true,
                          load: () => service.thumbnail(photo.id),
                        ),
                      ),
                      fit: BoxFit.cover,
                      excludeFromSemantics: true,
                      errorBuilder: (context, error, stack) =>
                          const Icon(Icons.broken_image_outlined),
                    )
                  : const _MissingTile(),
            ),
          ),
        ),
      ),
    );
  }
}

/// In place of a thumbnail whose photo was not in the restored backup.
class _MissingTile extends StatelessWidget {
  const _MissingTile();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.hide_image_outlined,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context).photoMissing,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// "Foto verwerken…" at the end of the row while a new photo is made ready.
class _ProcessingTile extends StatelessWidget {
  const _ProcessingTile();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: photoTileSize,
      height: photoTileSize,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context).photoProcessing,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}
