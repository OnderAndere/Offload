/// How photos are kept (REQ-027, DD-006/D1): a display version and a
/// thumbnail, no original. In one place, so the display size can be raised
/// to 2048 px when handwriting turns out unreadable (SPEC Q7).
library;

/// The version of the photo pipeline that made a photo's files (DD-006/D6),
/// stored with its attachment: a later recompression pass can find the ones
/// it has not done yet. 0 is any attachment outside the pipeline.
const photoPipelineVersion = 1;

class ImagePolicy {
  const ImagePolicy({
    this.displayMaxSide = 1600,
    this.displayQuality = 82,
    this.thumbnailMaxSide = 256,
    this.thumbnailQuality = 75,
  });

  /// The values of DD-006/D1.
  static const standard = ImagePolicy();

  /// The longest side of the display version, in pixels.
  final int displayMaxSide;

  /// JPEG quality of the display version (0–100).
  final int displayQuality;

  /// The longest side of the thumbnail, in pixels.
  final int thumbnailMaxSide;

  /// JPEG quality of the thumbnail (0–100).
  final int thumbnailQuality;
}

/// The size to ask a decoder for, so the upright image fits in [maxSide]:
/// only its long side is given, the other follows the aspect; both null when
/// it fits already (never enlarged). [width] and [height] are as stored;
/// an EXIF [orientation] of 5–8 turns the image a quarter, so the upright
/// sides swap. A decoder that applies the orientation takes the target as
/// the size of the upright image (spike S2).
({int? width, int? height}) decodeTarget({
  required int width,
  required int height,
  required int orientation,
  required int maxSide,
}) {
  final quarter = orientation >= 5 && orientation <= 8;
  final (uprightWidth, uprightHeight) = quarter
      ? (height, width)
      : (width, height);
  if (uprightWidth <= maxSide && uprightHeight <= maxSide) {
    return (width: null, height: null);
  }
  return uprightWidth >= uprightHeight
      ? (width: maxSide, height: null)
      : (width: null, height: maxSide);
}
