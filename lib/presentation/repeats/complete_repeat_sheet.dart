import 'package:flutter/material.dart';

import '../../domain/repeats/repeat.dart';
import '../../domain/time/local_date.dart';
import '../../domain/tokens/token_types.dart';
import '../../l10n/app_localizations.dart';
import '../tokens/token_display.dart';
import '../tokens/token_editor.dart';

/// The sheet "Afronden en herhalen" (DD-018 point 18): daily, weekly or
/// monthly, each with its next time, counted from [occurrence] (the item's
/// date, or today) and after [today]. On Windows a small dialog, with the
/// arrows, Enter and Esc. Closing it answers null: nothing changes.
Future<Rhythm?> showCompleteAndRepeat(
  BuildContext context, {
  required LocalDate occurrence,
  required LocalDate today,
}) {
  final options = _Options(occurrence: occurrence, today: today);
  return isDesktop(context)
      ? showDialog<Rhythm>(
          context: context,
          builder: (context) => Dialog(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: options,
              ),
            ),
          ),
        )
      : showModalBottomSheet<Rhythm>(
          context: context,
          showDragHandle: true,
          // Grows to fit; scrolls on a small screen or with large text.
          isScrollControlled: true,
          builder: (context) =>
              SafeArea(child: SingleChildScrollView(child: options)),
        );
}

/// The next time of a new series from [occurrence] in [rhythm], once that
/// time is done on [today].
LocalDate nextTimeOf(Rhythm rhythm, LocalDate occurrence, LocalDate today) =>
    repeatDue(occurrence, rhythm, [
      RepeatCompletion(occurrenceOn: occurrence, completedOn: today),
    ]);

class _Options extends StatelessWidget {
  const _Options({required this.occurrence, required this.today});

  final LocalDate occurrence;
  final LocalDate today;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final muted = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 2),
          child: Text(
            l10n.completeAndRepeatTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          child: Text(l10n.completeAndRepeatQuestion, style: muted),
        ),
        for (final (index, rhythm) in const [
          Rhythm.daily,
          Rhythm.weekly,
          Rhythm.monthly,
        ].indexed)
          ListTile(
            autofocus: index == 0,
            leading: Icon(tokenLook(const RepeatTokenType(), l10n).icon),
            title: Text(l10n.repeatRhythmTitle(rhythmLetter(rhythm))),
            trailing: Text(
              l10n.revisitDate(
                nextTimeOf(rhythm, occurrence, today).toLocalDateTime(),
              ),
            ),
            onTap: () => Navigator.of(context).pop(rhythm),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
          child: Text(l10n.completeAndRepeatNote, style: muted),
        ),
      ],
    );
  }
}
