import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/presentation/theme/app_theme.dart';
import 'package:offload/presentation/theme/offload_colors.dart';
import 'package:offload/presentation/theme/typography.dart';

/// The theme: the typeface (T10.7 step A) and the meaning colours as an
/// extension (T8.1a, DD-017), with the contrast DD-017 and DD-018 recorded
/// (REQ-016).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// The WCAG 2.2 contrast ratio of [a] and [b].
  double contrast(Color a, Color b) {
    final la = a.computeLuminance(), lb = b.computeLuminance();
    final (hi, lo) = la > lb ? (la, lb) : (lb, la);
    return (hi + 0.05) / (lo + 0.05);
  }

  // The backgrounds the ratios of DD-017 and DD-018 were measured on: the
  // page of the reference sketches, and a white card.
  const page = Color(0xFFF3F1EC);
  const white = Color(0xFFFFFFFF);
  const light = OffloadColors.light;

  test('every text style uses IBM Plex Sans', () {
    final theme = offloadTheme();
    final styles = theme.textTheme;
    for (final style in [
      styles.bodyMedium,
      styles.titleLarge,
      styles.labelSmall,
      styles.displayLarge,
    ]) {
      expect(style?.fontFamily, sansFamily);
    }
    expect(theme.useMaterial3, isTrue);
  });

  test('the theme carries the light meaning colours', () {
    expect(offloadTheme().extension<OffloadColors>(), same(light));
  });

  test('the light colours are exactly those of DD-017 and DD-018', () {
    expect(light.attention, const Color(0xFFB35712));
    expect(light.attentionText, const Color(0xFF8F430E));
    expect(light.attentionChip, const Color(0xFFF6E1CC));
    expect(light.calm, const Color(0xFF245A8C));
    expect(light.calmChip, const Color(0xFFE3ECF5));
    expect(light.standstill, const [
      Color(0xFFDCE6F0),
      Color(0xFFF6E1CC),
      Color(0xFFE3A46C),
      Color(0xFFA34A12),
    ]);
    expect(light.standstillText, const [
      Color(0xFF1B1D20),
      Color(0xFF1B1D20),
      Color(0xFF1B1D20),
      Color(0xFFFFFFFF),
    ]);
    expect(light.connectionLine, const Color(0xFF6F8BA8));
    expect(light.connectionFarLine, const Color(0xFF8A8478));
    expect(light.connectionFarNode, const Color(0xFF6F86A0));
    expect(light.connectionFarProject, const Color(0xFF5E7EA0));
    expect(light.connectionNodeFill, white);
    expect(light.connectionNodeText, const Color(0xFF1B1D20));
    expect(light.connectionBadge, const Color(0xFF1B1D20));
    expect(light.connectionBadgeText, white);
    expect(light.previewShadow, const Color(0x40000000));
  });

  test('the contrast DD-017 and DD-018 record (REQ-016)', () {
    // Orange text on the page falls short; its darker shade does not.
    expect(contrast(light.attention, page), closeTo(4.34, 0.01));
    expect(contrast(light.attention, white), closeTo(4.90, 0.01));
    expect(contrast(light.attentionText, page), closeTo(6.25, 0.01));
    expect(
      contrast(light.attentionText, light.attentionChip),
      closeTo(5.56, 0.01),
    );
    expect(contrast(light.calm, light.calmChip), closeTo(6.03, 0.01));
    // White on the darkest standstill class; dark text on the others.
    expect(
      contrast(light.standstillText[3], light.standstill[3]),
      closeTo(5.9, 0.05),
    );
    for (var i = 0; i < 3; i++) {
      expect(
        contrast(light.standstillText[i], light.standstill[i]),
        greaterThanOrEqualTo(4.5),
      );
    }
    // Connections: every line and outline at least 3:1 on a white card.
    for (final (color, ratio) in [
      (light.connectionLine, 3.5),
      (light.connectionFarLine, 3.7),
      (light.connectionFarNode, 3.8),
      (light.connectionFarProject, 4.2),
    ]) {
      expect(contrast(color, white), closeTo(ratio, 0.05));
      expect(contrast(color, white), greaterThanOrEqualTo(3));
    }
  });

  test('standstill has four classes, each with a text colour', () {
    expect(light.standstill, hasLength(4));
    expect(light.standstillText, hasLength(light.standstill.length));
  });

  group('lerp', () {
    const black = Color(0xFF000000);
    final dark = light.copyWith(
      attention: black,
      standstill: const [black, black, black, black],
      previewShadow: white,
    );

    test('at 0 and 1 gives either end', () {
      expect(light.lerp(dark, 0).attention, light.attention);
      expect(light.lerp(dark, 1).attention, black);
      expect(light.lerp(dark, 1).standstill, dark.standstill);
      expect(light.lerp(dark, 0).standstill, light.standstill);
      expect(light.lerp(dark, 1).previewShadow, white);
    });

    test('at 0.5 is halfway, per colour and per list entry', () {
      final half = light.lerp(dark, 0.5);
      expect(half.attention, Color.lerp(light.attention, black, 0.5));
      for (var i = 0; i < 4; i++) {
        expect(half.standstill[i], Color.lerp(light.standstill[i], black, 0.5));
      }
      // Unchanged colours stay as they are.
      expect(half.calm, light.calm);
    });

    test('without another one stays itself', () {
      expect(light.lerp(null, 0.5), same(light));
    });
  });

  testWidgets('a theme without the colours says so clearly', (tester) async {
    late BuildContext captured;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            captured = context;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(() => captured.offloadColors, throwsStateError);
  });
}
