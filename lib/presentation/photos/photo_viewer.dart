import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/attachments/photo_storage_service.dart';
import '../../l10n/app_localizations.dart';
import 'attachment_image.dart';
import 'delete_photo.dart';

/// One photo full screen on black, with zoom (DD-018 point 19 (d)): pinch,
/// a double tap, or the mouse wheel; drag to move. 🗑 asks to delete it.
/// <kbd>Esc</kbd> closes, <kbd>Del</kbd> asks to delete. A photo whose file
/// was not in the restored backup says so instead. Viewing PDFs and opening
/// in another app are T5.6.
class PhotoViewer extends StatefulWidget {
  const PhotoViewer({
    super.key,
    required this.id,
    required this.present,
    required this.label,
    required this.service,
  });

  final String id;

  /// Whether the photo's file is on this device.
  final bool present;

  /// "Foto 2 van 3", for a screen reader.
  final String label;
  final PhotoStorageService service;

  /// Opens the viewer over the whole window, also from the detail pane.
  static Future<void> open(
    BuildContext context, {
    required String id,
    required bool present,
    required String label,
    required PhotoStorageService service,
  }) => Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(
      builder: (context) =>
          PhotoViewer(id: id, present: present, label: label, service: service),
    ),
  );

  @override
  State<PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<PhotoViewer> {
  final _zoom = TransformationController();
  Offset? _doubleTapAt;

  /// How far a double tap zooms in.
  static const _doubleTapScale = 2.5;

  @override
  void dispose() {
    _zoom.dispose();
    super.dispose();
  }

  /// A double tap zooms in on the tapped point, or back out.
  void _toggleZoom() {
    if (_zoom.value.getMaxScaleOnAxis() > 1) {
      _zoom.value = Matrix4.identity();
      return;
    }
    final at = _doubleTapAt ?? Offset.zero;
    const grow = _doubleTapScale - 1;
    _zoom.value = Matrix4.diagonal3Values(_doubleTapScale, _doubleTapScale, 1)
      ..setTranslationRaw(-at.dx * grow, -at.dy * grow, 0);
  }

  Future<void> _delete() async {
    if (await deletePhoto(context, widget.service, widget.id) && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).maybePop(),
        const SingleActivator(LogicalKeyboardKey.delete): _delete,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                onPressed: _delete,
                tooltip: l10n.photoDelete,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          body: Semantics(
            label: widget.label,
            image: true,
            child: widget.present
                ? GestureDetector(
                    onDoubleTapDown: (details) =>
                        _doubleTapAt = details.localPosition,
                    onDoubleTap: _toggleZoom,
                    child: InteractiveViewer(
                      transformationController: _zoom,
                      maxScale: 5,
                      child: SizedBox.expand(
                        child: Image(
                          image: AttachmentImage(
                            widget.id,
                            thumbnail: false,
                            load: () => widget.service.display(widget.id),
                          ),
                          fit: BoxFit.contain,
                          excludeFromSemantics: true,
                          errorBuilder: (context, error, stack) => const Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: Colors.white54,
                              size: 48,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                : _Missing(text: l10n.photoMissing),
          ),
        ),
      ),
    );
  }
}

class _Missing extends StatelessWidget {
  const _Missing({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white70),
      ),
    ),
  );
}
