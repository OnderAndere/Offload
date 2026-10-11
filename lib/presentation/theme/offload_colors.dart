import 'package:flutter/material.dart';

/// The colours of Offload that carry a meaning (DD-017), as part of the
/// theme: a screen reads them with `context.offloadColors`, never as a
/// constant, so a dark variant (T8.1) is one more instance. Dynamic colours
/// (T8.1) never recolour these. The contrast ratios below are those of
/// [light] on its background (REQ-016).
@immutable
class OffloadColors extends ThemeExtension<OffloadColors> {
  const OffloadColors({
    required this.attention,
    required this.attentionText,
    required this.attentionChip,
    required this.calm,
    required this.calmChip,
    required this.standstill,
    required this.standstillText,
    required this.connectionLine,
    required this.connectionFarLine,
    required this.connectionFarNode,
    required this.connectionFarProject,
    required this.connectionNodeFill,
    required this.connectionNodeText,
    required this.connectionBadge,
    required this.connectionBadgeText,
    required this.previewShadow,
  });

  /// "Needs attention now" (DD-017): overdue, late, busy, what I deliver.
  final Color attention;

  /// Orange text on the page background: [attention] reaches only 4.34:1
  /// there, so text uses this darker shade (6.25:1; DD-017, DD-018 point 4).
  final Color attentionText;

  /// The background of an orange label, such as "busy" (DD-018 point 12);
  /// [attentionText] on it reaches 5.56:1.
  final Color attentionChip;

  /// "Calm" (DD-017): done, later, the ball is with someone else.
  final Color calm;

  /// The background of a calm label or a selected week (DD-018 point 12);
  /// [calm] on it reaches 6.03:1.
  final Color calmChip;

  /// Standstill (DD-017): the time since the last touch in four classes,
  /// < 1 week, 1–3 weeks, 3–6 weeks and > 6 weeks, from blue-grey to dark
  /// orange. The first two are equal in lightness, so a tile always shows
  /// its age as text too.
  final List<Color> standstill;

  /// The text on each of [standstill]: dark on the light three, white on the
  /// darkest (5.9:1).
  final List<Color> standstillText;

  /// Connections (DD-018 point 15): a direct line, and on the second step
  /// the dotted line, a node's outline and a project's fill. Each reaches
  /// 3:1 on a white card (REQ-016): 3.5, 3.7, 3.8 and 4.2.
  final Color connectionLine;
  final Color connectionFarLine;
  final Color connectionFarNode;
  final Color connectionFarProject;

  /// The inside of a person's circle and an item's square in Connections.
  final Color connectionNodeFill;

  /// The initials in a person's circle.
  final Color connectionNodeText;

  /// The "+7" badge of second-step nodes not drawn, and its text.
  final Color connectionBadge;
  final Color connectionBadgeText;

  /// The shadow under the preview of a node (Windows, on hover).
  final Color previewShadow;

  /// The light theme: the values of DD-017 and DD-018.
  static const light = OffloadColors(
    attention: Color(0xFFB35712),
    attentionText: Color(0xFF8F430E),
    attentionChip: Color(0xFFF6E1CC),
    calm: Color(0xFF245A8C),
    calmChip: Color(0xFFE3ECF5),
    standstill: [
      Color(0xFFDCE6F0),
      Color(0xFFF6E1CC),
      Color(0xFFE3A46C),
      Color(0xFFA34A12),
    ],
    standstillText: [
      Color(0xFF1B1D20),
      Color(0xFF1B1D20),
      Color(0xFF1B1D20),
      Color(0xFFFFFFFF),
    ],
    connectionLine: Color(0xFF6F8BA8),
    connectionFarLine: Color(0xFF8A8478),
    connectionFarNode: Color(0xFF6F86A0),
    connectionFarProject: Color(0xFF5E7EA0),
    connectionNodeFill: Color(0xFFFFFFFF),
    connectionNodeText: Color(0xFF1B1D20),
    connectionBadge: Color(0xFF1B1D20),
    connectionBadgeText: Color(0xFFFFFFFF),
    previewShadow: Color(0x40000000),
  );

  @override
  OffloadColors copyWith({
    Color? attention,
    Color? attentionText,
    Color? attentionChip,
    Color? calm,
    Color? calmChip,
    List<Color>? standstill,
    List<Color>? standstillText,
    Color? connectionLine,
    Color? connectionFarLine,
    Color? connectionFarNode,
    Color? connectionFarProject,
    Color? connectionNodeFill,
    Color? connectionNodeText,
    Color? connectionBadge,
    Color? connectionBadgeText,
    Color? previewShadow,
  }) => OffloadColors(
    attention: attention ?? this.attention,
    attentionText: attentionText ?? this.attentionText,
    attentionChip: attentionChip ?? this.attentionChip,
    calm: calm ?? this.calm,
    calmChip: calmChip ?? this.calmChip,
    standstill: standstill ?? this.standstill,
    standstillText: standstillText ?? this.standstillText,
    connectionLine: connectionLine ?? this.connectionLine,
    connectionFarLine: connectionFarLine ?? this.connectionFarLine,
    connectionFarNode: connectionFarNode ?? this.connectionFarNode,
    connectionFarProject: connectionFarProject ?? this.connectionFarProject,
    connectionNodeFill: connectionNodeFill ?? this.connectionNodeFill,
    connectionNodeText: connectionNodeText ?? this.connectionNodeText,
    connectionBadge: connectionBadge ?? this.connectionBadge,
    connectionBadgeText: connectionBadgeText ?? this.connectionBadgeText,
    previewShadow: previewShadow ?? this.previewShadow,
  );

  @override
  OffloadColors lerp(covariant OffloadColors? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    List<Color> each(List<Color> a, List<Color> b) => [
      for (var i = 0; i < a.length; i++) c(a[i], b[i]),
    ];
    return OffloadColors(
      attention: c(attention, other.attention),
      attentionText: c(attentionText, other.attentionText),
      attentionChip: c(attentionChip, other.attentionChip),
      calm: c(calm, other.calm),
      calmChip: c(calmChip, other.calmChip),
      standstill: each(standstill, other.standstill),
      standstillText: each(standstillText, other.standstillText),
      connectionLine: c(connectionLine, other.connectionLine),
      connectionFarLine: c(connectionFarLine, other.connectionFarLine),
      connectionFarNode: c(connectionFarNode, other.connectionFarNode),
      connectionFarProject: c(connectionFarProject, other.connectionFarProject),
      connectionNodeFill: c(connectionNodeFill, other.connectionNodeFill),
      connectionNodeText: c(connectionNodeText, other.connectionNodeText),
      connectionBadge: c(connectionBadge, other.connectionBadge),
      connectionBadgeText: c(connectionBadgeText, other.connectionBadgeText),
      previewShadow: c(previewShadow, other.previewShadow),
    );
  }
}

/// The meaning colours of the current theme (DD-017).
extension OffloadColorsOf on BuildContext {
  OffloadColors get offloadColors {
    final colors = Theme.of(this).extension<OffloadColors>();
    if (colors == null) {
      // A developer error, never shown to users.
      const message =
          'No OffloadColors in the theme: use offloadTheme(), also in a test'; // l10n-ignore: developer error
      throw StateError(message);
    }
    return colors;
  }
}
