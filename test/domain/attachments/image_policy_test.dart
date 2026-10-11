import 'package:flutter_test/flutter_test.dart';
import 'package:offload/domain/attachments/image_policy.dart';

/// The sizes of the photo pipeline (REQ-027, DD-006/D1, spike S2).
void main() {
  test('the standard is 1600/82 and 256/75 (DD-006/D1)', () {
    const p = ImagePolicy.standard;
    expect(
      (
        p.displayMaxSide,
        p.displayQuality,
        p.thumbnailMaxSide,
        p.thumbnailQuality,
      ),
      (1600, 82, 256, 75),
    );
  });

  group('decodeTarget', () {
    test('a landscape photo: its width', () {
      expect(
        decodeTarget(width: 8192, height: 6144, orientation: 1, maxSide: 1600),
        (width: 1600, height: null),
      );
    });

    test('a portrait photo stored on its side (orientation 6): the upright '
        'height', () {
      // As a phone stores a portrait photo: wide, with orientation 6.
      expect(
        decodeTarget(width: 8192, height: 6144, orientation: 6, maxSide: 1600),
        (width: null, height: 1600),
      );
    });

    test('orientations 5 to 8 swap the sides, 1 to 4 do not', () {
      for (final o in [5, 6, 7, 8]) {
        expect(
          decodeTarget(width: 4000, height: 3000, orientation: o, maxSide: 256),
          (width: null, height: 256),
        );
      }
      for (final o in [1, 2, 3, 4]) {
        expect(
          decodeTarget(width: 4000, height: 3000, orientation: o, maxSide: 256),
          (width: 256, height: null),
        );
      }
    });

    test('a square takes the width', () {
      expect(
        decodeTarget(width: 3000, height: 3000, orientation: 1, maxSide: 256),
        (width: 256, height: null),
      );
    });

    test('a picture that fits is never enlarged', () {
      expect(
        decodeTarget(width: 1600, height: 900, orientation: 1, maxSide: 1600),
        (width: null, height: null),
      );
      expect(
        decodeTarget(width: 200, height: 100, orientation: 6, maxSide: 256),
        (width: null, height: null),
      );
    });
  });
}
