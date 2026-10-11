import 'package:flutter/painting.dart';

// The design tokens of Offload (DD-017, T10.7 step A): the colours that
// carry a meaning and the typefaces, in one place. Dynamic colours (T8.1)
// never recolour these.

/// "Needs attention now" (DD-017): overdue, late, busy, what I deliver.
const attentionColor = Color(0xFFB35712);

/// Orange text on the page background: [attentionColor] reaches only
/// 4.34:1 there, so text uses this darker shade (6.25:1; DD-017, DD-018
/// point 4).
const attentionTextColor = Color(0xFF8F430E);

/// The background of an orange label, such as "busy" (DD-018 point 12);
/// [attentionTextColor] on it reaches 5.56:1.
const attentionChipColor = Color(0xFFF6E1CC);

/// "Calm" (DD-017): done, later, the ball is with someone else.
const calmColor = Color(0xFF245A8C);

/// The background of a calm label or a selected week (DD-018 point 12);
/// [calmColor] on it reaches 6.03:1.
const calmChipColor = Color(0xFFE3ECF5);

/// Standstill (DD-017): the time since the last touch in four classes,
/// < 1 week, 1–3 weeks, 3–6 weeks and > 6 weeks, from blue-grey to dark
/// orange. The first two are equal in lightness, so a tile always shows
/// its age as text too.
const standstillColors = [
  Color(0xFFDCE6F0),
  Color(0xFFF6E1CC),
  Color(0xFFE3A46C),
  Color(0xFFA34A12),
];

/// The text on each of [standstillColors]: dark on the light three, white
/// on the darkest (5.9:1).
const standstillTextColors = [
  Color(0xFF1B1D20),
  Color(0xFF1B1D20),
  Color(0xFF1B1D20),
  Color(0xFFFFFFFF),
];

/// The typeface of the app, bundled as an asset (DD-017; OFL-1.1, see
/// `assets/fonts/`).
const sansFamily = 'IBM Plex Sans'; // l10n-ignore: font family, not shown

/// Numbers and week numbers in the Overview, so columns line up (DD-017).
const monoFamily = 'IBM Plex Mono'; // l10n-ignore: font family, not shown

/// Connections (DD-018 point 15): a direct line, and on the second step the
/// dotted line, a node's outline and a project's fill. Each reaches 3:1 on
/// a white card (REQ-016): 3.5, 3.7, 3.8 and 4.2.
const connectionLineColor = Color(0xFF6F8BA8);
const connectionFarLineColor = Color(0xFF8A8478);
const connectionFarNodeColor = Color(0xFF6F86A0);
const connectionFarProjectColor = Color(0xFF5E7EA0);
