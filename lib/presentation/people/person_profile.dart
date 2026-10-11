import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/people/birthday.dart';
import '../../domain/people/people_repository.dart';
import '../../domain/people/person.dart';
import '../../domain/time/local_date.dart';
import '../../l10n/app_localizations.dart';
import '../inbox/inbox_card.dart';
import '../items/item_providers.dart';
import '../messages.dart';
import 'person_contacts.dart';
import 'person_look.dart';

/// The profile of a person on their screen (REQ-031, DD-012, DD-018 point
/// 7): the birthday as a line that opens a small dialog, and the note as a
/// field that saves itself, as the note of an item. One per person: the
/// screen gives it a key of its own.
class PersonProfile extends ConsumerStatefulWidget {
  const PersonProfile({super.key, required this.person});

  final Person person;

  @override
  ConsumerState<PersonProfile> createState() => PersonProfileState();
}

class PersonProfileState extends ConsumerState<PersonProfile> {
  /// As the item detail: every save is a change-log entry (DD-018 point 1).
  static const autosaveDelay = Duration(seconds: 2);

  late final _note = TextEditingController(text: widget.person.note ?? '');
  // Kept from the start, so leaving can still save after the screen is
  // gone.
  late final PeopleRepository _people;
  late String _saved = widget.person.note ?? '';
  Timer? _pending;
  bool _failed = false;

  /// The field is being set to the stored note: no save for that.
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _people = ref.read(peopleRepositoryProvider);
    _note.addListener(_changed);
  }

  /// A newer stored note (a merge, its undo, another device) replaces the
  /// field, but only while nothing typed is unsaved: typing is never
  /// overwritten (DD-018 point 7).
  @override
  void didUpdateWidget(PersonProfile oldWidget) {
    super.didUpdateWidget(oldWidget);
    final stored = widget.person.note ?? '';
    final unsaved = _note.text != _saved || (_pending?.isActive ?? false);
    if (stored != _saved && !unsaved) {
      _syncing = true;
      _note.text = stored;
      _syncing = false;
      _saved = stored;
    }
  }

  /// Saves what was typed now, without waiting for the pause: before the
  /// person goes away in a merge.
  Future<void> flush() => _save();

  @override
  void dispose() {
    // Leaving always saves what was typed.
    unawaited(_save());
    _note.dispose();
    super.dispose();
  }

  void _changed() {
    if (_syncing) return;
    _pending?.cancel();
    _pending = Timer(autosaveDelay, () => unawaited(_save()));
  }

  /// Read now: from dispose the field is gone after this.
  Future<void> _save() async {
    _pending?.cancel();
    final note = _note.text;
    if (note == _saved) return;
    try {
      await _people.setNote(widget.person.id, note);
      _saved = note;
      if (_failed && mounted) setState(() => _failed = false);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _editBirthday() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final choice = await showDialog<({Birthday? birthday})>(
      context: context,
      builder: (_) => _BirthdayDialog(initial: widget.person.birthday),
    );
    if (choice == null) return;
    try {
      await _people.setBirthday(widget.person.id, choice.birthday);
    } catch (e) {
      showMessage(messenger, SnackBar(content: Text(personErrorText(e, l10n))));
    }
  }

  Future<void> _editWork() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final work = await showDialog<({String jobTitle, String organisation})>(
      context: context,
      builder: (_) => _WorkDialog(
        jobTitle: widget.person.jobTitle,
        organisation: widget.person.organisation,
      ),
    );
    if (work == null) return;
    try {
      await _people.setWork(
        widget.person.id,
        organisation: work.organisation,
        jobTitle: work.jobTitle,
      );
    } catch (e) {
      showMessage(messenger, SnackBar(content: Text(personErrorText(e, l10n))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final now = ref.watch(minuteClockProvider).valueOrNull ?? DateTime.now();
    final birthday = widget.person.birthday;
    final age = birthday?.ageOn(LocalDate.of(now));
    final date = birthday?.displayDate.toLocalDateTime();
    final birthdayText = date == null
        ? null
        : age == null
        ? l10n.personBirthday(date)
        : l10n.personBirthdayWithAge(date, age);
    final jobTitle = widget.person.jobTitle;
    final organisation = widget.person.organisation;
    final workText = jobTitle != null && organisation != null
        ? l10n.personWork(jobTitle, organisation)
        : jobTitle ?? organisation;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProfileLine(
            icon: Icons.work_outline,
            text: workText,
            addText: l10n.personWorkAdd,
            tooltip: l10n.personWorkTooltip,
            semantics: l10n.personWorkSemantics,
            onTap: _editWork,
          ),
          // The note on top: what to remember before a 1-on-1 (DD-018 point
          // 11).
          const SizedBox(height: 4),
          TextField(
            controller: _note,
            minLines: 2,
            maxLines: 8,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              labelText: l10n.personNoteLabel,
              hintText: l10n.personNoteHint,
              errorText: _failed ? l10n.itemSaveFailed : null,
              errorMaxLines: 3,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 4),
          _ProfileLine(
            icon: Icons.cake_outlined,
            text: birthdayText,
            addText: l10n.personBirthdayAdd,
            tooltip: l10n.personBirthdayTooltip,
            semantics: l10n.personBirthdaySemantics,
            onTap: _editBirthday,
          ),
          PersonContacts(personId: widget.person.id),
        ],
      ),
    );
  }
}

/// Day, month and an optional year (REQ-031). Returns the birthday, `null`
/// in it for *Remove*, or nothing when closed.
class _BirthdayDialog extends StatefulWidget {
  const _BirthdayDialog({required this.initial});

  final Birthday? initial;

  @override
  State<_BirthdayDialog> createState() => _BirthdayDialogState();
}

class _BirthdayDialogState extends State<_BirthdayDialog> {
  late final _day = TextEditingController(
    text: widget.initial?.day.toString() ?? '',
  );
  late final _year = TextEditingController(
    text: widget.initial?.year?.toString() ?? '',
  );
  late int? _month = widget.initial?.month;
  bool _invalid = false;

  @override
  void dispose() {
    _day.dispose();
    _year.dispose();
    super.dispose();
  }

  void _submit() {
    // Read now, not from the last build (CLAUDE.md, enterText pitfall).
    final day = int.tryParse(_day.text.trim());
    final yearText = _year.text.trim();
    final year = yearText.isEmpty ? null : int.tryParse(yearText);
    final month = _month;
    final birthday =
        day == null || month == null || (yearText.isNotEmpty && year == null)
        ? null
        : Birthday.tryCreate(day, month, year);
    if (birthday == null) {
      setState(() => _invalid = true);
      return;
    }
    Navigator.of(context).pop((birthday: birthday));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final digits = [FilteringTextInputFormatter.digitsOnly];
    return AlertDialog(
      title: Text(l10n.personBirthdayTitle),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 280, maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 72,
                  child: TextField(
                    controller: _day,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: digits,
                    maxLength: 2,
                    decoration: InputDecoration(
                      labelText: l10n.personBirthdayDay,
                      counterText: '',
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() => _invalid = false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _month,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: l10n.personBirthdayMonth,
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      for (var m = 1; m <= 12; m++)
                        DropdownMenuItem(
                          value: m,
                          child: Text(l10n.personMonthName(DateTime(2000, m))),
                        ),
                    ],
                    onChanged: (m) => setState(() {
                      _month = m;
                      _invalid = false;
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _year,
              keyboardType: TextInputType.number,
              inputFormatters: digits,
              maxLength: 4,
              decoration: InputDecoration(
                labelText: l10n.personBirthdayYear,
                counterText: '',
                errorText: _invalid ? l10n.personBirthdayInvalid : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() => _invalid = false),
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        if (widget.initial != null)
          TextButton(
            onPressed: () => Navigator.of(context).pop((birthday: null)),
            child: Text(l10n.personRemove),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.personCancel),
        ),
        TextButton(onPressed: _submit, child: Text(l10n.personSave)),
      ],
    );
  }
}

/// A line of the profile that opens a dialog (DD-018 points 7 and 9): its
/// [text] with [icon], or, while empty, a quiet [addText] with a plus.
class _ProfileLine extends StatelessWidget {
  const _ProfileLine({
    required this.icon,
    required this.text,
    required this.addText,
    required this.tooltip,
    required this.semantics,
    required this.onTap,
  });

  final IconData icon;
  final String? text;
  final String addText;
  final String tooltip;
  final String Function(String value) semantics;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final shown = text ?? addText;
    final hint = text == null ? addText : tooltip;
    return Tooltip(
      message: hint,
      child: Semantics(
        button: true,
        label: semantics(shown),
        hint: hint,
        excludeSemantics: true,
        onTap: onTap,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                Icon(text == null ? Icons.add : icon, size: 20, color: muted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    shown,
                    style: text == null
                        ? theme.textTheme.bodyMedium?.copyWith(color: muted)
                        : theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Job title and organisation of a person (REQ-038, DD-018 point 9): two
/// optional fields; an empty field removes it. Returns both, or nothing
/// when closed.
class _WorkDialog extends StatefulWidget {
  const _WorkDialog({required this.jobTitle, required this.organisation});

  final String? jobTitle;
  final String? organisation;

  @override
  State<_WorkDialog> createState() => _WorkDialogState();
}

class _WorkDialogState extends State<_WorkDialog> {
  late final _jobTitle = TextEditingController(text: widget.jobTitle);
  late final _organisation = TextEditingController(text: widget.organisation);

  @override
  void dispose() {
    _jobTitle.dispose();
    _organisation.dispose();
    super.dispose();
  }

  // Read now, not from the last build (CLAUDE.md, enterText pitfall).
  void _submit() => Navigator.of(
    context,
  ).pop((jobTitle: _jobTitle.text, organisation: _organisation.text));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.personWorkTitle),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 280, maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _jobTitle,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.personJobTitle,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _organisation,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: l10n.personOrganisation,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.personCancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.personSave)),
      ],
    );
  }
}
