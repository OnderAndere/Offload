import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/items/commitment.dart';
import '../../domain/items/item.dart';
import '../../domain/items/item_headline.dart';
import '../../domain/items/item_repository.dart';
import '../../domain/items/nudge.dart';
import '../../domain/time/local_date.dart';
import '../../domain/tokens/token_processing.dart';
import '../../l10n/app_localizations.dart';
import '../messages.dart';
import '../people/people_providers.dart';
import '../reminders/reminder_providers.dart';
import '../theme/design_tokens.dart';
import '../tokens/token_display.dart';
import 'chase.dart';
import 'item_providers.dart';

/// The commitment of [item] in the item detail (REQ-046, REQ-047; DD-018
/// point 10): the request part (asked on, promised, due) for an item with
/// a requester or a request, the waiting part (waits on, expected) for a
/// waiting item. Nothing for other items. Every line can be changed; a grey
/// value is the default.
class CommitmentBlock extends ConsumerWidget {
  const CommitmentBlock({super.key, required this.item, required this.onDue});

  final Item item;

  /// A day picked for *Due*: the detail puts it in the text as `!d-m-yyyy`
  /// (DD-018 point 1); the deadline follows the text.
  final ValueChanged<LocalDate> onDue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final request = hasRequestPart(item);
    final waiting = hasWaitingPart(item);
    if (!request && !waiting) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = TextStyle(color: theme.colorScheme.onSurfaceVariant);
    final today = todayOnDevice();
    final registry = ref.watch(inlineTokenRegistryProvider);
    final title = itemHeadline(
      item.rawText,
      registry,
      parseContextOf(l10n, today),
    ).title;
    final due = item.dueAt == null ? null : storedToDateOnly(item.dueAt!);
    final expected = item.expectedAt;
    final late = daysLate(item, today);
    final waitingOn = item.waitingOnId == null
        ? null
        : ref.watch(peopleByIdProvider)[item.waitingOnId];

    // A default value (the capture day, the title) is grey; one set is not.
    Widget value(String text, {required bool set}) =>
        Text(text, style: set ? null : muted);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(
            l10n.commitmentHeader.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0.6,
            ),
          ),
        ),
        if (request) ...[
          _Line(
            icon: Icons.event_note_outlined,
            text: value(
              l10n.commitmentAskedOn(askedOn(item).toLocalDateTime()),
              set: item.askedAt != null,
            ),
            onTap: () => _pickAskedOn(context, ref),
            onReset: item.askedAt == null
                ? null
                : () =>
                      _store(context, ref, (r) => r.setAskedOn(item.id, null)),
          ),
          _Line(
            icon: Icons.edit_outlined,
            text: value(
              l10n.commitmentPromised(item.promise ?? title),
              set: item.promise != null,
            ),
            onTap: () => _editPromise(context, ref),
          ),
          _Line(
            icon: Icons.schedule,
            text: Text(
              due == null
                  ? l10n.commitmentDueAdd
                  : l10n.commitmentDue(due.toLocalDateTime()),
            ),
            onTap: () => _pickDue(context, due),
          ),
        ],
        if (waiting) ...[
          _Line(
            icon: Icons.hourglass_empty,
            text: Text(
              waitingOn == null
                  ? l10n.commitmentWaitsOnNobody
                  : l10n.commitmentWaitsOn(waitingOn.name),
            ),
          ),
          // Silent for X days: Chased starts the period again (T10.1).
          if (silentDays(item, today, ref.watch(nudgeAfterProvider))
              case final days?)
            _Line(
              icon: Icons.notifications_paused_outlined,
              text: Text(l10n.nudgeSilentDays(days)),
              trailing: OutlinedButton(
                onPressed: () => unawaited(
                  chase(
                    messenger: ScaffoldMessenger.of(context),
                    l10n: l10n,
                    items: ref.read(itemRepositoryProvider),
                    item: item,
                  ),
                ),
                child: Text(l10n.nudgeChased),
              ),
            ),
          _Line(
            icon: late != null ? Icons.warning_amber : Icons.event_outlined,
            color: late != null ? attentionTextColor : null,
            text: Text(
              expected == null
                  ? l10n.commitmentExpectedAdd
                  : late != null
                  ? l10n.commitmentExpectedLate(
                      expected.toLocalDateTime(),
                      late,
                    )
                  : l10n.commitmentExpected(expected.toLocalDateTime()),
              style: late != null
                  ? const TextStyle(color: attentionTextColor)
                  : null,
            ),
            onTap: () => _pickExpected(context, ref),
            onReset: expected == null
                ? null
                : () => _store(
                    context,
                    ref,
                    (r) => r.setExpectedBy(item.id, null),
                  ),
          ),
        ],
      ],
    );
  }

  Future<LocalDate?> _pickDay(BuildContext context, LocalDate initial) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.toLocalDateTime(),
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 10),
    );
    return picked == null ? null : LocalDate.of(picked);
  }

  Future<void> _pickAskedOn(BuildContext context, WidgetRef ref) async {
    final day = await _pickDay(context, askedOn(item));
    if (day == null || !context.mounted) return;
    await _store(context, ref, (r) => r.setAskedOn(item.id, day));
  }

  Future<void> _pickExpected(BuildContext context, WidgetRef ref) async {
    final day = await _pickDay(context, item.expectedAt ?? todayOnDevice());
    if (day == null || !context.mounted) return;
    await _store(context, ref, (r) => r.setExpectedBy(item.id, day));
  }

  Future<void> _pickDue(BuildContext context, LocalDate? due) async {
    final day = await _pickDay(context, due ?? todayOnDevice());
    if (day != null) onDue(day);
  }

  Future<void> _editPromise(BuildContext context, WidgetRef ref) async {
    final text = await showDialog<String>(
      context: context,
      builder: (_) => _PromiseDialog(initial: item.promise ?? ''),
    );
    if (text == null || !context.mounted) return;
    await _store(context, ref, (r) => r.setPromise(item.id, text));
  }

  Future<void> _store(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function(ItemRepository repository) change,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      await change(ref.read(itemRepositoryProvider));
    } catch (_) {
      showMessage(
        messenger,
        SnackBar(content: Text(l10n.commitmentChangeFailed)),
      );
    }
  }
}

/// One line of the block: an icon, the text, tappable, with an optional
/// button that clears a value set by hand.
class _Line extends StatelessWidget {
  const _Line({
    required this.icon,
    required this.text,
    this.onTap,
    this.onReset,
    this.color,
    this.trailing,
  });

  final IconData icon;
  final Widget text;
  final VoidCallback? onTap;
  final VoidCallback? onReset;
  final Color? color;

  /// At the end of the line when there is nothing to reset.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final onReset = this.onReset;
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      minTileHeight: 44,
      leading: Icon(icon, size: 20, color: color),
      title: text,
      onTap: onTap,
      trailing: onReset == null
          ? trailing
          : IconButton(
              icon: const Icon(Icons.close, size: 18),
              tooltip: l10n.commitmentReset,
              onPressed: onReset,
            ),
    );
  }
}

/// What I promised: one field, empty means the title (DD-018 point 10 (b)).
class _PromiseDialog extends StatefulWidget {
  const _PromiseDialog({required this.initial});

  final String initial;

  @override
  State<_PromiseDialog> createState() => _PromiseDialogState();
}

class _PromiseDialogState extends State<_PromiseDialog> {
  late final _field = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  void _save() => Navigator.of(context).pop(_field.text);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.commitmentPromiseTitle),
      content: TextField(
        controller: _field,
        autofocus: true,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _save(),
        decoration: InputDecoration(
          labelText: l10n.commitmentPromiseField,
          helperText: l10n.commitmentPromiseHint,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.personCancel),
        ),
        FilledButton(onPressed: _save, child: Text(l10n.personSave)),
      ],
    );
  }
}
