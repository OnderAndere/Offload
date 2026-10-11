import 'package:flutter/material.dart';

import 'offload_colors.dart';
import 'typography.dart';

/// The theme of Offload: Material 3 with IBM Plex Sans for every text and
/// the meaning colours of DD-017 as an extension (T10.7 step A, T8.1a).
/// The dark theme comes with T8.1.
ThemeData offloadTheme() =>
    ThemeData(fontFamily: sansFamily, extensions: const [OffloadColors.light]);
