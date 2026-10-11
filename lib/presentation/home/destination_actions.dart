import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../search/search_screen.dart';
import '../settings/settings_screen.dart';
import '../tokens/token_editor.dart';

/// Search and Settings in the top bar of a destination on a phone. On
/// Windows both have a place of their own: the search field above the list
/// and Settings at the foot of the rail (DD-018 point 5).
List<Widget> destinationActions(BuildContext context) {
  if (isDesktop(context)) return const [];
  final l10n = AppLocalizations.of(context);
  return [
    IconButton(
      icon: const Icon(Icons.search),
      tooltip: l10n.searchTooltip,
      onPressed: () => SearchScreen.open(context),
    ),
    IconButton(
      icon: const Icon(Icons.settings_outlined),
      tooltip: l10n.openSettingsTooltip,
      onPressed: () => SettingsScreen.open(context),
    ),
  ];
}
