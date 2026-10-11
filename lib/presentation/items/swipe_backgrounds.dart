import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// What shows under a card being swiped left: the trash, grey and calm
/// (throwing away needs no attention, DD-017). "Left = away" is the same
/// in the inbox, in triage and on Today (DD-018 point 4).
class SwipeToTrash extends StatelessWidget {
  const SwipeToTrash({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return _SwipeBackground(
      color: colors.outline,
      alignment: AlignmentDirectional.centerEnd,
      children: [
        Text(label, style: TextStyle(color: colors.surface)),
        const SizedBox(width: 8),
        Icon(Icons.delete_outline, color: colors.surface),
      ],
    );
  }
}

/// What shows under a card being swiped right on Today: completing, in the
/// calm blue (done needs no attention, DD-017, DD-018 point 4).
class SwipeToComplete extends StatelessWidget {
  const SwipeToComplete({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => _SwipeBackground(
    color: calmColor,
    alignment: AlignmentDirectional.centerStart,
    children: [
      const Icon(Icons.check, color: Colors.white),
      const SizedBox(width: 8),
      Text(label, style: const TextStyle(color: Colors.white)),
    ],
  );
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.color,
    required this.alignment,
    required this.children,
  });

  final Color color;
  final AlignmentGeometry alignment;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    padding: const EdgeInsets.symmetric(horizontal: 20),
    alignment: alignment,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: children),
  );
}
