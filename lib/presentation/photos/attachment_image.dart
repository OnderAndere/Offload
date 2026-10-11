import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// A photo attachment as an image (DD-006 point 5): the attachment id and
/// the variant are the cache key, so a list shows each thumbnail from the
/// image cache instead of decrypting and decoding it per frame, as a fresh
/// `MemoryImage` would. Use it with [ResizeImage] (`cacheWidth`) for a
/// thumbnail. [load] decrypts the bytes; it is not part of the key.
@immutable
class AttachmentImage extends ImageProvider<AttachmentImage> {
  const AttachmentImage(this.id, {required this.thumbnail, required this.load});

  final String id;

  /// The thumbnail, or the display version.
  final bool thumbnail;

  final Future<Uint8List> Function() load;

  @override
  Future<AttachmentImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    AttachmentImage key,
    ImageDecoderCallback decode,
  ) => MultiFrameImageStreamCompleter(codec: _codec(decode), scale: 1);

  Future<ui.Codec> _codec(ImageDecoderCallback decode) async =>
      decode(await ui.ImmutableBuffer.fromUint8List(await load()));

  @override
  bool operator ==(Object other) =>
      other is AttachmentImage &&
      other.id == id &&
      other.thumbnail == thumbnail;

  @override
  int get hashCode => Object.hash(id, thumbnail);

  @override
  String toString() => 'AttachmentImage($id, thumbnail: $thumbnail)'; // l10n-ignore: debug text
}
