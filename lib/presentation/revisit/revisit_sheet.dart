import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/items/item.dart';
import '../../domain/items/item_classification.dart';
import '../../domain/items/revisit.dart';
import '../../domain/time/local_date.dart';
import '../../l10n/app_localizations.dart';
import '../items/item_providers.dart';
import '../messages.dart';
import '../tokens/token_editor.dart';

/// What the sheet "Revisit on" answers: a day, or [stopRevisiting] for
/// *Not any more*. Closing the sheet answers null: nothing changes.
typedef RevisitChoice = ({LocalDate? day});

/// *Not any more*: the item is no longer parked (DD-018 point 17).
const RevisitChoice stopRevisiting = (day: null);

/// The sheet "Revisit on" (DD-018 point 17): tomorrow, next week, in a
/// month and the date picker (from tomorrow). For an item parked until
/// [current] that day is marked and *Not any more* is offered. On Windows
/// a small dialog, with the arrows, Enter and Esc.
Future<RevisitChoice?> showRevisitSheet(
  BuildContext context, {
  LocalDate? current,
}) async {
  final today = LocalDate.of(DateTime.now());
  final choice = isDesktop(context)
      ? await showDialog<_Pick>(
          context: context,
          builder: (context) => _RevisitDialog(today: today, current: current),
        )
      : await showModalBottomSheet<_Pick>(
          context: context,
          showDragHandle: true,
          builder: (context) => SafeArea(
            child: _RevisitOptions(today: today, current: current),
          ),
        );
  if (choice == null || !context.mounted) return null;
  return switch (choice) {
    _Day(:final day) => (day: day),
    _Stop() => stopRevisiting,
    _ChooseDate() => await _pickDate(context, today, current),
  };
}

Future<RevisitChoice?> _pickDate(
  BuildContext context,
  LocalDate today,
  LocalDate? current,
) async {
  final l10n = AppLocalizations.of(context);
  final first = firstRevisitDay(today);
  final initial = current != null && current.compareTo(first) >= 0
      ? current
      : first;
  final picked = await showDatePicker(
    context: context,
    helpText: l10n.revisitSheetTitle,
    initialDate: initial.toLocalDateTime(),
    firstDate: first.toLocalDateTime(),
    lastDate: today.addDays(5 * 366).toLocalDateTime(),
  );
  return picked == null ? null : (day: LocalDate.of(picked));
}

/// What a tap in the sheet chose.
sealed class _Pick {
  const _Pick();
}

class _Day extends _Pick {
  const _Day(this.day);

  final LocalDate day;
}

class _Stop extends _Pick {
  const _Stop();
}

class _ChooseDate extends _Pick {
  const _ChooseDate();
}

class _RevisitDialog extends StatelessWidget {
  const _RevisitDialog({required this.today, required this.current});

  final LocalDate today;
  final LocalDate? current;

  @override
  Widget build(BuildContext context) => Dialog(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: _RevisitOptions(today: today, current: current),
      ),
    ),
  );
}

class _RevisitOptions extends StatelessWidget {
  const _RevisitOptions({required this.today, required this.current});

  final LocalDate today;
  final LocalDate? current;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final choices = revisitChoices(today);
    Widget day(
      IconData icon,
      String label,
      LocalDate date, {
      bool autofocus = false,
    }) {
      final text = l10n.revisitDate(date.toLocalDateTime());
      return ListTile(
        autofocus: autofocus,
        leading: Icon(icon),
        title: Text(label),
        trailing: Text(text),
        selected: date == current,
        onTap: () => Navigator.of(context).pop(_Day(date)),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          child: Semantics(
            header: true,
            child: Text(
              l10n.revisitSheetTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
        day(
          Icons.wb_sunny_outlined,
          l10n.revisitTomorrow,
          choices.tomorrow,
          autofocus: isDesktop(context),
        ),
        day(Icons.date_range_outlined, l10n.revisitNextWeek, choices.nextWeek),
        day(Icons.event_outlined, l10n.revisitInAMonth, choices.inAMonth),
        ListTile(
          leading: const Icon(Icons.edit_calendar_outlined),
          title: Text(l10n.revisitChooseDate),
          trailing: current == null
              ? null
              : Text(l10n.revisitDate(current!.toLocalDateTime())),
          onTap: () => Navigator.of(context).pop(const _ChooseDate()),
        ),
        if (current != null) ...[
          const Divider(),
          ListTile(
            leading: const Icon(Icons.close),
            title: Text(l10n.revisitStop),
            onTap: () => Navigator.of(context).pop(const _Stop()),
          ),
        ],
      ],
    );
  }
}

/// *Revisit on…* for [item] from the item detail or the status chip (DD-018
/// point 17): the sheet, then parks it with a message and Undo, which puts
/// back the status and date it had; *Not any more* makes it active again.
Future<void> revisitWithUndo(
  BuildContext context,
  WidgetRef ref,
  Item item,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  final keep = keepUndoMessage(context);
  final items = ref.read(itemRepositoryProvider);
  final before = ItemClassification.of(item);
  final choice = await showRevisitSheet(context, current: parkedDayOf(item));
  if (choice == null) return;
  final day = choice.day;
  try {
    if (day == null) {
      await items.stopRevisit(item.id);
      return;
    }
    await items.revisitOn(item.id, day);
  } catch (_) {
    showMessage(messenger, SnackBar(content: Text(l10n.itemChangeFailed)));
    return;
  }
  showMessage(
    messenger,
    undoSnackBar(
      message: l10n.revisitBackOn(day.toLocalDateTime()),
      l10n: l10n,
      keep: keep,
      onUndo: () => unawaited(
        items.classify(item.id, before).catchError((Object _) {
          showMessage(messenger, SnackBar(content: Text(l10n.itemUndoFailed)));
        }),
      ),
    ),
  );
}
