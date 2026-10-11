import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/help/help_topics.dart';
import '../../domain/settings/prefix_bar_mode.dart';
import '../../domain/tokens/inline_token.dart';
import '../../domain/tokens/inline_token_registry.dart';
import '../../l10n/app_localizations.dart';
import '../help/help_screen.dart';
import '../settings/prefix_bar_provider.dart';
import 'token_display.dart';

/// The prefix bar in quick capture (REQ-034, DD-004 "Keuze — invoerhulp"):
/// a button per prefix token, so the syntax need not be remembered, and a
/// `?` for the syntax overview. Built from the registry, so a new token type
/// appears here by itself; static data only, nothing is loaded (REQ-001).
class PrefixBar extends ConsumerWidget {
  const PrefixBar({
    super.key,
    required this.mode,
    required this.onInsert,
    required this.onHelp,
  });

  /// [PrefixBarMode.off] is not shown at all; the caller leaves the bar out.
  final PrefixBarMode mode;

  /// Called with the sign of the tapped button, such as `@`, and its type:
  /// the repeat button shares `!` with the date (DD-004 point 14).
  final void Function(String sign, InlineTokenType type) onInsert;

  /// Called when `?` is tapped.
  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final registry = ref.watch(inlineTokenRegistryProvider);
    final expanded =
        mode == PrefixBarMode.always || ref.watch(prefixBarExpandedProvider);
    // Collapsed: one slim row with only the signs (PO decision 27-09-2026).
    final style = TextButton.styleFrom(
      minimumSize: expanded ? const Size(48, 48) : const Size(40, 36),
      padding: EdgeInsets.symmetric(horizontal: expanded ? 12 : 8),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textStyle: Theme.of(context).textTheme.titleMedium,
    );
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final (:type, :prefix) in prefixTokens(registry))
                  Tooltip(
                    message: l10n.prefixBarInsert(tokenLook(type, l10n).label),
                    child: TextButton(
                      style: style,
                      onPressed: () => onInsert(prefix, type),
                      child: Text(
                        expanded
                            ? l10n.prefixBarButton(
                                prefix,
                                tokenLook(type, l10n).label,
                              )
                            : prefix,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Tooltip(
          message: l10n.prefixBarHelp,
          child: TextButton(
            style: style,
            onPressed: onHelp,
            child: const Text('?'),
          ),
        ),
        if (mode == PrefixBarMode.collapsed)
          IconButton(
            tooltip: expanded ? l10n.prefixBarCollapse : l10n.prefixBarExpand,
            visualDensity: expanded ? null : VisualDensity.compact,
            icon: Icon(expanded ? Icons.unfold_less : Icons.unfold_more),
            onPressed: () =>
                ref.read(prefixBarExpandedProvider.notifier).set(!expanded),
          ),
      ],
    );
  }
}

/// The token types that start with a sign, in registry order; a type
/// that shares the sign of another ([InlineTokenType.sharesPrefix], the
/// repeat words on `!`) comes right after that one.
List<({InlineTokenType type, String prefix})> prefixTokens(
  InlineTokenRegistry registry,
) {
  final tokens = <({InlineTokenType type, String prefix})>[
    for (final type in registry.types)
      if (type.trigger case PrefixTrigger(:final prefix))
        (type: type, prefix: prefix)
      // `[[ item` (PO decision 03-10-2026, DD-004 point 13 (g)).
      else if (type.trigger case EnclosedTrigger(:final open))
        (type: type, prefix: open),
  ];
  final sharing = [
    for (final t in tokens)
      if (t.type.sharesPrefix) t,
  ];
  final ordered = [
    for (final t in tokens)
      if (!t.type.sharesPrefix) t,
  ];
  for (final token in sharing) {
    final owner = ordered.indexWhere((t) => t.prefix == token.prefix);
    ordered.insert(owner < 0 ? ordered.length : owner + 1, token);
  }
  return ordered;
}

/// Shows the syntax overview (AC REQ-034): every token with an example
/// line, and the escape. A dialog on a desktop, a bottom sheet on a phone.
Future<void> showSyntaxOverview(BuildContext context, {required bool desktop}) {
  final l10n = AppLocalizations.of(context);
  final navigator = Navigator.of(context);
  // Closes the overview and opens the manual at the signs (REQ-065).
  void openManual(BuildContext overview) {
    Navigator.of(overview).pop();
    HelpScreen.push(navigator, HelpTopic.syntax);
  }

  if (desktop) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.syntaxOverviewTitle),
        content: const SizedBox(width: 480, child: SyntaxOverview()),
        actions: [
          TextButton(
            onPressed: () => openManual(context),
            child: Text(l10n.syntaxOverviewManual),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.syntaxOverviewClose),
          ),
        ],
      ),
    );
  }
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                l10n.syntaxOverviewTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 8),
            const Flexible(child: SyntaxOverview()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextButton.icon(
                icon: const Icon(Icons.help_outline),
                label: Text(l10n.syntaxOverviewManual),
                onPressed: () => openManual(context),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// The list inside the syntax overview, fed by the registry (DD-004): a
/// new token type shows up here with its own example line.
class SyntaxOverview extends ConsumerWidget {
  const SyntaxOverview({super.key});

  static const _escape = r'\';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final registry = ref.watch(inlineTokenRegistryProvider);
    return ListView(
      shrinkWrap: true,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Text(l10n.syntaxOverviewIntro),
        ),
        // Every type, also one without an example line yet, so the overview
        // never lists less than the bar (review T2.2b).
        for (final type in registry.types)
          if (tokenLook(type, l10n) case (
            :final icon,
            :final label,
            :final example,
          ))
            ListTile(
              leading: Icon(icon),
              title: Text(switch (type.trigger) {
                PrefixTrigger(:final prefix) => l10n.prefixBarButton(
                  prefix,
                  label,
                ),
                EnclosedTrigger(:final open) => l10n.prefixBarButton(
                  open,
                  label,
                ),
                PatternTrigger() => label,
              }),
              subtitle: example == null ? null : Text(example),
            ),
        ListTile(
          leading: const Icon(Icons.text_fields),
          title: Text(l10n.prefixBarButton(_escape, l10n.syntaxEscapeLabel)),
          subtitle: Text(l10n.syntaxEscapeExample),
        ),
      ],
    );
  }
}
