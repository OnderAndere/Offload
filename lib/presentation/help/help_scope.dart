import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/help/help_topics.dart';
import '../../l10n/app_localizations.dart';
import '../tokens/token_editor.dart';
import 'help_screen.dart';

/// Names the part of the manual that belongs to the screen below it
/// (REQ-065, DD-020). The "?" button in its title bar and F1 read it.
class HelpScope extends InheritedWidget {
  const HelpScope({super.key, required this.topic, required super.child});

  final HelpTopic topic;

  /// The topic of the nearest scope above [context], if any.
  static HelpTopic? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<HelpScope>()?.topic;

  @override
  bool updateShouldNotify(HelpScope oldWidget) => oldWidget.topic != topic;
}

/// The "?" button for a title bar: opens the manual at the topic of the
/// nearest [HelpScope], or at the table of contents without one.
class HelpButton extends StatelessWidget {
  const HelpButton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return IconButton(
      icon: const Icon(Icons.help_outline),
      tooltip: isDesktop(context) ? l10n.helpTooltipWithKey : l10n.helpTooltip,
      onPressed: () => HelpScreen.open(
        context,
        HelpScope.maybeOf(context) ?? HelpTopic.contents,
      ),
    );
  }
}

/// F1 anywhere in the app opens the manual at the topic of the screen that
/// has the keyboard focus (the Windows habit), or at the table of contents.
/// Sits above the navigator, so it also hears keys from pushed screens; a
/// screen can handle F1 itself first (the help screen does).
class HelpKey extends StatelessWidget {
  const HelpKey({super.key, required this.navigatorKey, required this.child});

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
    bindings: {
      const SingleActivator(LogicalKeyboardKey.f1): () {
        final focused = FocusManager.instance.primaryFocus?.context;
        final topic =
            (focused != null && focused.mounted
                ? HelpScope.maybeOf(focused)
                : null) ??
            HelpTopic.contents;
        final navigator = navigatorKey.currentState;
        if (navigator != null) HelpScreen.push(navigator, topic);
      },
    },
    child: child,
  );
}
