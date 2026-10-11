import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../tokens/token_editor.dart';

/// On Windows ↑/↓ move the focus between the rows of a list under a chart
/// of the Overview, Enter opens the focused row (DD-018 point 12 (f)). In
/// direction, not reading order: reading order jumps to the other chart
/// (CLAUDE.md). ←/→ are left to the chart and the weekly review.
class ListArrows extends StatelessWidget {
  const ListArrows({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!isDesktop(context)) return child;
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
          return KeyEventResult.ignored;
        }
        final direction = switch (event.logicalKey) {
          LogicalKeyboardKey.arrowDown => TraversalDirection.down,
          LogicalKeyboardKey.arrowUp => TraversalDirection.up,
          _ => null,
        };
        final focused = FocusManager.instance.primaryFocus;
        if (direction == null || focused == null) {
          return KeyEventResult.ignored;
        }
        // Past the first or last row the focus may go to what lies beyond
        // (such as the review's buttons); the key is used up either way, so
        // the list never scrolls instead.
        focused.focusInDirection(direction);
        return KeyEventResult.handled;
      },
      child: child,
    );
  }
}
