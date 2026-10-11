import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/people/contact_detail.dart';
import '../../l10n/app_localizations.dart';
import '../../platform/contact_launcher/contact_launcher.dart';
import '../../platform/contact_launcher/platform_contact_launcher.dart';
import '../items/item_providers.dart';
import '../messages.dart';
import '../tokens/token_editor.dart';

/// The live contact details of a person, in the order shown (REQ-038).
final contactDetailsProvider = StreamProvider.autoDispose
    .family<List<ContactDetail>, String>(
      (ref, personId) =>
          ref.watch(peopleRepositoryProvider).watchContactDetails(personId),
    );

/// Dialling a number and mailing an address (DD-018 point 9); a fake in
/// tests.
final contactLauncherProvider = Provider<ContactLauncher>(
  (ref) => createPlatformContactLauncher(),
);

/// The [label] of a contact detail as shown: a standard label translated, an own
/// label as typed; null without one.
String? contactLabelText(String? label, AppLocalizations l10n) {
  if (label == null) return null;
  final standard = StandardContactLabel.of(label);
  return standard == null ? label : l10n.contactStandardLabel(standard.name);
}

String _kindText(ContactKind kind, AppLocalizations l10n) => switch (kind) {
  ContactKind.phone => l10n.contactKindPhone,
  ContactKind.email => l10n.contactKindEmail,
};

String _problemText(
  ContactProblem problem,
  ContactKind kind,
  AppLocalizations l10n,
) => switch (problem) {
  ContactProblem.empty => l10n.contactEmpty,
  ContactProblem.invalid => switch (kind) {
    ContactKind.phone => l10n.contactInvalidPhone,
    ContactKind.email => l10n.contactInvalidEmail,
  },
  ContactProblem.notAvailable => l10n.contactSaveFailed,
};

/// The section *Contact details* of a person (REQ-038, DD-018 point 9):
/// phone numbers, then email addresses, each with its label, and two
/// buttons to add one. The header and buttons are always there.
class PersonContacts extends ConsumerWidget {
  const PersonContacts({super.key, required this.personId});

  final String personId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final details =
        ref.watch(contactDetailsProvider(personId)).valueOrNull ?? const [];
    final header = theme.textTheme.labelMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      letterSpacing: 0.6,
    );
    Widget addButton(ContactKind kind) {
      final title = kind == ContactKind.phone
          ? l10n.contactAddPhone
          : l10n.contactAddEmail;
      return Tooltip(
        message: title,
        child: TextButton.icon(
          icon: const Icon(Icons.add),
          label: Text(_kindText(kind, l10n)),
          onPressed: () =>
              showContactSheet(context, personId: personId, kind: kind),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
          child: Semantics(
            header: true,
            child: Text(l10n.contactSection.toUpperCase(), style: header),
          ),
        ),
        for (final detail in details)
          ContactRow(key: ValueKey(detail.id), detail: detail),
        Wrap(
          spacing: 4,
          children: [
            addButton(ContactKind.phone),
            addButton(ContactKind.email),
          ],
        ),
      ],
    );
  }
}

enum _RowAction { open, copy, edit, delete }

/// One phone number or email address (DD-018 point 9): a tap dials a
/// number and mails an address; where there is no dialler (Windows) it
/// copies the number. ⋮ has *Call* or *Mail*, *Copy*, *Change…* and
/// *Delete*. On Windows, while the row has the focus, Enter does what a tap
/// does, Delete deletes, Shift+F10 or the menu key opens ⋮, and ↑/↓ move to
/// the control above or below; these keys act on the row, never on a
/// selected card of the person's lists.
class ContactRow extends ConsumerStatefulWidget {
  const ContactRow({super.key, required this.detail});

  final ContactDetail detail;

  @override
  ConsumerState<ContactRow> createState() => _ContactRowState();
}

class _ContactRowState extends ConsumerState<ContactRow> {
  final _focus = FocusNode();
  final _menu = GlobalKey<PopupMenuButtonState<_RowAction>>();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  ContactDetail get _detail => widget.detail;

  void _edit() => showContactSheet(
    context,
    personId: _detail.personId,
    kind: _detail.kind,
    existing: _detail,
  );

  Future<void> _copy() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    await Clipboard.setData(ClipboardData(text: _detail.value));
    showMessage(messenger, SnackBar(content: Text(l10n.contactCopied)));
  }

  Future<void> _delete() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final people = ref.read(peopleRepositoryProvider);
    final keep = keepUndoMessage(context);
    // Taken before the await: the row is gone once the detail is.
    final id = _detail.id;
    final kind = _detail.kind;
    try {
      await people.deleteContactDetail(id);
    } catch (_) {
      showMessage(messenger, SnackBar(content: Text(l10n.contactSaveFailed)));
      return;
    }
    showMessage(
      messenger,
      undoSnackBar(
        message: kind == ContactKind.phone
            ? l10n.contactDeletedPhone
            : l10n.contactDeletedEmail,
        l10n: l10n,
        keep: keep,
        onUndo: () => unawaited(
          people
              .restoreContactDetail(id)
              .then((back) {
                if (!back) {
                  showMessage(
                    messenger,
                    SnackBar(content: Text(l10n.contactUndoFailed)),
                  );
                }
              })
              .catchError((Object _) {
                showMessage(
                  messenger,
                  SnackBar(content: Text(l10n.contactUndoFailed)),
                );
              }),
        ),
      ),
    );
  }

  /// Whether a tap opens the detail elsewhere (dialler, mail app) rather
  /// than copying it.
  bool get _opens =>
      _detail.kind == ContactKind.email ||
      ref.read(contactLauncherProvider).canDial;

  /// A tap, Enter or the screen reader's tap: dial or mail, or copy a
  /// number where there is no dialler (Windows).
  Future<void> _primary() async {
    if (!_opens) return _copy();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final launcher = ref.read(contactLauncherProvider);
    try {
      if (_detail.kind == ContactKind.phone) {
        await launcher.dial(_detail.value);
      } else {
        await launcher.mail(_detail.value);
      }
    } catch (_) {
      showMessage(messenger, SnackBar(content: Text(l10n.contactLaunchFailed)));
    }
  }

  void _act(_RowAction action) => switch (action) {
    _RowAction.open => unawaited(_primary()),
    _RowAction.copy => unawaited(_copy()),
    _RowAction.edit => _edit(),
    _RowAction.delete => unawaited(_delete()),
  };

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final shift = HardwareKeyboard.instance.isShiftPressed;
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      unawaited(_primary());
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.delete) {
      unawaited(_delete());
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.contextMenu ||
        (shift && key == LogicalKeyboardKey.f10)) {
      _menu.currentState?.showButtonMenu();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      // Down on screen, not the next in reading order: with the detail pane
      // open that would be in the other pane.
      _focus.focusInDirection(TraversalDirection.down);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      _focus.focusInDirection(TraversalDirection.up);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final detail = _detail;
    final label = contactLabelText(detail.label, l10n);
    final kind = _kindText(detail.kind, l10n);
    final row = Row(
      children: [
        Icon(
          detail.kind == ContactKind.phone
              ? Icons.phone_outlined
              : Icons.mail_outline,
          size: 20,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(detail.value, style: theme.textTheme.bodyLarge),
              if (label != null)
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        // Reached by Shift+F10 or the menu key, not by Tab: the row is the
        // one stop per detail.
        ExcludeFocus(
          child: PopupMenuButton<_RowAction>(
            key: _menu,
            tooltip: l10n.contactMenuTooltip,
            onSelected: _act,
            itemBuilder: (_) => [
              if (_opens)
                PopupMenuItem(
                  value: _RowAction.open,
                  child: Text(
                    detail.kind == ContactKind.phone
                        ? l10n.contactCall
                        : l10n.contactMail,
                  ),
                ),
              PopupMenuItem(
                value: _RowAction.copy,
                child: Text(l10n.contactCopy),
              ),
              PopupMenuItem(
                value: _RowAction.edit,
                child: Text(l10n.contactEdit),
              ),
              PopupMenuItem(
                value: _RowAction.delete,
                child: Text(l10n.contactDelete),
              ),
            ],
          ),
        ),
      ],
    );
    return Semantics(
      container: true,
      button: true,
      excludeSemantics: true,
      label: label == null
          ? l10n.contactRowSemantics(detail.value, kind)
          : l10n.contactRowSemanticsWithLabel(detail.value, label, kind),
      onTap: () => unawaited(_primary()),
      customSemanticsActions: {
        CustomSemanticsAction(label: l10n.contactEdit): _edit,
        CustomSemanticsAction(label: l10n.contactCopy): () =>
            unawaited(_copy()),
        CustomSemanticsAction(label: l10n.contactDelete): () =>
            unawaited(_delete()),
      },
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: isDesktop(context) ? _onKey : null,
        child: InkWell(
          focusNode: _focus,
          borderRadius: BorderRadius.circular(8),
          onTap: () => unawaited(_primary()),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 0, 4),
            child: row,
          ),
        ),
      ),
    );
  }
}

/// Adds a phone number or email address to person [personId], or changes
/// [existing], in a bottom sheet (DD-018 point 9). The sheet saves itself
/// and stays open with the reason when the value does not fit.
Future<void> showContactSheet(
  BuildContext context, {
  required String personId,
  required ContactKind kind,
  ContactDetail? existing,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) =>
      _ContactSheet(personId: personId, kind: kind, existing: existing),
);

class _ContactSheet extends ConsumerStatefulWidget {
  const _ContactSheet({
    required this.personId,
    required this.kind,
    this.existing,
  });

  final String personId;
  final ContactKind kind;
  final ContactDetail? existing;

  @override
  ConsumerState<_ContactSheet> createState() => _ContactSheetState();
}

class _ContactSheetState extends ConsumerState<_ContactSheet> {
  late final _value = TextEditingController(text: widget.existing?.value);
  late final _ownLabel = TextEditingController(
    text: _ownLabelOf(widget.existing?.label),
  );

  /// The chosen standard label; null for none or an own label.
  late StandardContactLabel? _standard = widget.existing == null
      ? (widget.kind == ContactKind.phone ? StandardContactLabel.mobile : null)
      : StandardContactLabel.of(widget.existing!.label);
  late bool _own = _ownLabelOf(widget.existing?.label) != null;
  String? _error;
  bool _saving = false;

  static String? _ownLabelOf(String? label) =>
      label != null && StandardContactLabel.of(label) == null ? label : null;

  @override
  void dispose() {
    _value.dispose();
    _ownLabel.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final l10n = AppLocalizations.of(context);
    // Read now, not from the last build (CLAUDE.md, enterText pitfall).
    final value = _value.text;
    final problem = checkContact(widget.kind, value);
    if (problem != null) {
      setState(() => _error = _problemText(problem, widget.kind, l10n));
      return;
    }
    final label = _own ? _ownLabel.text : _standard?.name;
    final people = ref.read(peopleRepositoryProvider);
    setState(() => _saving = true);
    try {
      final existing = widget.existing;
      if (existing == null) {
        await people.addContactDetail(
          widget.personId,
          widget.kind,
          value,
          label: label,
        );
      } else {
        await people.updateContactDetail(existing.id, value, label: label);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e is ContactException
            ? _problemText(e.problem, widget.kind, l10n)
            : l10n.contactSaveFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final phone = widget.kind == ContactKind.phone;
    final title = widget.existing == null
        ? (phone ? l10n.contactAddPhone : l10n.contactAddEmail)
        : (phone ? l10n.contactEditPhone : l10n.contactEditEmail);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          TextField(
            controller: _value,
            autofocus: true,
            keyboardType: phone
                ? TextInputType.phone
                : TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            enableSuggestions: !phone,
            decoration: InputDecoration(
              labelText: _kindText(widget.kind, l10n),
              errorText: _error,
              errorMaxLines: 3,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            onSubmitted: (_) => unawaited(_save()),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final standard in StandardContactLabel.values)
                ChoiceChip(
                  label: Text(l10n.contactStandardLabel(standard.name)),
                  selected: !_own && _standard == standard,
                  onSelected: (on) => setState(() {
                    _own = false;
                    _standard = on ? standard : null;
                  }),
                ),
              ChoiceChip(
                label: Text(l10n.contactOwnLabel),
                selected: _own,
                onSelected: (on) => setState(() {
                  _own = on;
                  if (on) _standard = null;
                }),
              ),
            ],
          ),
          if (_own) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _ownLabel,
              autofocus: true,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: l10n.contactOwnLabelField,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => unawaited(_save()),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.personCancel),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _saving ? null : () => unawaited(_save()),
                child: Text(l10n.personSave),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
