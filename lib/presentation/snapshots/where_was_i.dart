import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/snapshots/drift_snapshot_repository.dart';
import '../../domain/snapshots/snapshot.dart';
import '../../domain/time/relative_age.dart';
import '../../l10n/app_localizations.dart';
import '../inbox/inbox_card.dart';
import '../items/item_providers.dart';
import '../messages.dart';
import '../startup/app_storage_provider.dart';
import '../theme/offload_colors.dart';
import '../tokens/token_editor.dart';

/// "Where was I" (T10.3, REQ-049, DD-018 point 13).
final snapshotRepositoryProvider = Provider<SnapshotRepository>(
  (ref) => DriftSnapshotRepository(ref.watch(storageProvider)),
);

/// The open note of an item or project, or null.
final openSnapshotProvider = StreamProvider.autoDispose
    .family<Snapshot?, SnapshotOwner>(
      (ref, owner) => ref.watch(snapshotRepositoryProvider).watchOpen(owner),
    );

/// The icon of "Where was I" (a pause).
const whereWasIIcon = Icons.pause_circle_outline;

/// Opens the form of [owner] (DD-018 point 13 (b)): a sheet on a phone, a
/// dialog on Windows; filled in with the open note. However it closes, what
/// was typed is saved (b′); both fields empty resumes the open note. Reads
/// only the open note: no lists (hard rule 7).
Future<void> showWhereWasI(
  BuildContext context,
  WidgetRef ref,
  SnapshotOwner owner, {
  required String title,
}) async {
  // Everything the save needs, read before the first wait: the screen that
  // opened the form may be gone when it closes.
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final repository = ref.read(snapshotRepositoryProvider);
  final items = ref.read(itemRepositoryProvider);
  final open = await repository.open(owner);
  if (!context.mounted) return;
  // Completed when the form is gone, after its closing animation, with
  // what is in it then (b′).
  final closed = Completer<({String nextStep, String inMind, bool changed})>();
  final form = _WhereWasIForm(
    title: title,
    nextStep: open?.nextStep,
    inMind: open?.inMind,
    onClosed: closed.complete,
  );
  if (isDesktop(context)) {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: form,
          ),
        ),
      ),
    );
  } else {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (sheet) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheet).bottom,
          ),
          child: form,
        ),
      ),
    );
  }
  final typed = await closed.future;
  // Unchanged: nothing to save (and no touch).
  if (!typed.changed) return;
  try {
    // An item that went to the trash meanwhile (a sync) cannot be touched.
    if (owner case ItemSnapshotOwner(:final itemId)) {
      if (!await items.isLive(itemId)) {
        throw StateError('item gone'); // l10n-ignore: never shown
      }
    }
    await repository.save(
      owner,
      nextStep: typed.nextStep,
      inMind: typed.inMind,
    );
  } catch (_) {
    showMessage(messenger, SnackBar(content: Text(l10n.whereWasISaveFailed)));
  }
}

/// The form; it owns its text and hands it over when it is gone.
class _WhereWasIForm extends StatefulWidget {
  const _WhereWasIForm({
    required this.title,
    required this.nextStep,
    required this.inMind,
    required this.onClosed,
  });

  final String title;
  final String? nextStep;
  final String? inMind;
  final ValueChanged<({String nextStep, String inMind, bool changed})> onClosed;

  @override
  State<_WhereWasIForm> createState() => _WhereWasIFormState();
}

class _WhereWasIFormState extends State<_WhereWasIForm> {
  late final TextEditingController _next;
  late final TextEditingController _mind;
  late final (String, String) _before;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _next = TextEditingController(text: widget.nextStep);
    _mind = TextEditingController(text: widget.inMind);
    _before = (_next.text, _mind.text);
  }

  @override
  void dispose() {
    widget.onClosed((
      nextStep: _next.text,
      inMind: _mind.text,
      changed: (_next.text, _mind.text) != _before,
    ));
    _next.dispose();
    _mind.dispose();
    super.dispose();
  }

  /// Closes once, also when Enter is held.
  void _close() {
    if (_closing) return;
    _closing = true;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final desktop = isDesktop(context);
    // Windows: Enter saves, Shift+Enter is a new line (AC REQ-049); the
    // dialog itself closes on Escape, and keeps the text then too. A phone:
    // the keyboard goes to the second field, and saves from there.
    Widget field(
      TextEditingController controller,
      String label, {
      String? hint,
      bool first = false,
    }) {
      final text = TextField(
        controller: controller,
        autofocus: first,
        minLines: first ? 1 : 2,
        maxLines: 6,
        keyboardType: TextInputType.multiline,
        textInputAction: desktop
            ? TextInputAction.newline
            : first
            ? TextInputAction.next
            : TextInputAction.done,
        onSubmitted: desktop || first ? null : (_) => _close(),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
      );
      if (!desktop) return text;
      return CallbackShortcuts(
        bindings: {
          const SingleActivator(
            LogicalKeyboardKey.enter,
            includeRepeats: false,
          ): _close,
          const SingleActivator(
            LogicalKeyboardKey.numpadEnter,
            includeRepeats: false,
          ): _close,
        },
        child: text,
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(20, desktop ? 20 : 0, 20, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.whereWasI, style: theme.textTheme.titleLarge),
          Text(
            widget.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          field(_next, l10n.whereWasINextStep, first: true),
          const SizedBox(height: 12),
          field(_mind, l10n.whereWasIInMind, hint: l10n.whereWasIInMindHint),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Keeps what was typed too (b′): Close, not Cancel.
              TextButton(onPressed: _close, child: Text(l10n.whereWasIClose)),
              const SizedBox(width: 8),
              FilledButton(onPressed: _close, child: Text(l10n.whereWasISave)),
            ],
          ),
        ],
      ),
    );
  }
}

/// The button by Complete in an item, and under a project's title (DD-018
/// point 13 (a), variant B).
class WhereWasIButton extends ConsumerWidget {
  const WhereWasIButton({super.key, required this.owner, required this.title});

  final SnapshotOwner owner;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final button = OutlinedButton.icon(
      onPressed: () =>
          unawaited(showWhereWasI(context, ref, owner, title: title)),
      icon: const Icon(whereWasIIcon),
      label: Text(l10n.whereWasI),
    );
    if (!isDesktop(context)) return button;
    return Tooltip(message: l10n.whereWasITooltipWithKey, child: button);
  }
}

/// The resume card at the top of an item or project while a note is open
/// (DD-018 point 13 (d)): both fields and how long ago it was saved;
/// *Update* opens the form filled in, *Resume* closes the note.
class ResumeCard extends ConsumerWidget {
  const ResumeCard({
    super.key,
    required this.owner,
    required this.title,
    this.margin = EdgeInsets.zero,
  });

  final SnapshotOwner owner;
  final String title;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final open = ref.watch(openSnapshotProvider(owner)).valueOrNull;
    if (open == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final now = ref.watch(minuteClockProvider).valueOrNull ?? DateTime.now();
    final saved = open.savedAt;
    final age = saved == null
        ? null
        : relativeAgeTexts(relativeAge(saved.toLocal(), now), l10n);

    Widget part(String label, String? text) => text == null
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
                Text(text, style: theme.textTheme.bodyMedium),
              ],
            ),
          );

    return Container(
      margin: margin,
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 0),
      decoration: BoxDecoration(
        color: context.offloadColors.calmChip,
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        border: Border(
          left: BorderSide(color: context.offloadColors.calm, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                Icon(
                  whereWasIIcon,
                  size: 16,
                  color: context.offloadColors.calm,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      l10n.resumeCardTitle.toUpperCase(),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: context.offloadColors.calm,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ),
                if (age != null)
                  Semantics(
                    label: age.long,
                    excludeSemantics: true,
                    child: Text(
                      age.short,
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                    ),
                  ),
              ],
            ),
          ),
          part(l10n.whereWasINextStep, open.nextStep),
          part(l10n.whereWasIInMind, open.inMind),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () =>
                    unawaited(showWhereWasI(context, ref, owner, title: title)),
                child: Text(l10n.resumeUpdate),
              ),
              TextButton(
                onPressed: () {
                  final messenger = ScaffoldMessenger.of(context);
                  final failed = l10n.itemChangeFailed;
                  unawaited(
                    ref
                        .read(snapshotRepositoryProvider)
                        .resume(owner)
                        .catchError(
                          (Object _) => showMessage(
                            messenger,
                            SnackBar(content: Text(failed)),
                          ),
                        ),
                  );
                },
                child: Text(l10n.resumeResume),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
