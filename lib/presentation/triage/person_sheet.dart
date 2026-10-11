import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/people/person_suggestions.dart';
import '../../domain/time/local_date.dart';
import '../../domain/tokens/token_suggestion.dart';
import '../../l10n/app_localizations.dart';
import '../tokens/token_suggestions.dart';

/// Asks for the person of a request or a wait (DD-018 points 3 and 7): a
/// name field with the stored people as suggestions (REQ-033) and "New:
/// …"; the people [namedWords] stand for (the words after `@` in the item's
/// text) first, marked "in the text". Returns the chosen name, `(name:
/// null)` for "Skip", or null when the sheet was closed (then nothing is
/// chosen at all). With [askExpected] (waiting, DD-018 point 10 (d)) an
/// optional line picks the day it is expected by, returned as `expected`.
Future<PersonChoice?> showPersonSheet(
  BuildContext context, {
  required String title,
  List<String> namedWords = const [],
  bool askExpected = false,
}) => showModalBottomSheet<PersonChoice>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (context) => _PersonSheet(
    title: title,
    namedWords: namedWords,
    askExpected: askExpected,
  ),
);

/// What the person sheet returns: the name (null: skipped) and, when it was
/// asked for, the expected day (null: none picked).
typedef PersonChoice = ({String? name, LocalDate? expected});

class _PersonSheet extends ConsumerStatefulWidget {
  const _PersonSheet({
    required this.title,
    required this.namedWords,
    required this.askExpected,
  });

  final String title;
  final List<String> namedWords;
  final bool askExpected;

  @override
  ConsumerState<_PersonSheet> createState() => _PersonSheetState();
}

class _PersonSheetState extends ConsumerState<_PersonSheet> {
  final _field = TextEditingController();
  List<NamedCandidate> _people = const [];
  LocalDate? _expected;

  @override
  void initState() {
    super.initState();
    // Loaded when the sheet opens; a failure only means no suggestions.
    unawaited(
      ref
          .read(tokenCandidateSourceProvider)
          .people()
          .then((people) {
            if (mounted) setState(() => _people = people);
          })
          .catchError((Object _) {}),
    );
  }

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  void _choose(String? name) =>
      Navigator.of(context).pop((name: name, expected: _expected));

  Future<void> _pickExpected() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expected?.toLocalDateTime() ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null && mounted) {
      setState(() => _expected = LocalDate.of(picked));
    }
  }

  /// Enter and Done take the top line, as in the suggestion list (DD-004
  /// point 9): a known person before a new one; with nothing typed it is
  /// the same as skipping.
  String? _top(List<PersonSuggestion> suggestions) =>
      _field.text.trim().isEmpty || suggestions.isEmpty
      ? null
      : suggestions.first.name;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final named = namedPeople(_people, widget.namedWords);
    final suggestions = suggestPeopleNamedFirst(_field.text, _people, named);
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
          Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(
            controller: _field,
            autofocus: true,
            decoration: InputDecoration(
              hintText: l10n.triagePersonHint,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _choose(_top(suggestions)),
          ),
          for (final s in suggestions)
            ListTile(
              leading: Icon(
                s.isNew ? Icons.person_add_alt : Icons.person_outline,
              ),
              title: Text(s.isNew ? l10n.tokenSuggestionNew(s.name) : s.name),
              trailing: !s.isNew && named.contains(s.name)
                  ? Text(
                      l10n.personInText,
                      style: Theme.of(context).textTheme.bodySmall,
                    )
                  : null,
              onTap: () => _choose(s.name),
            ),
          if (widget.askExpected)
            ListTile(
              leading: const Icon(Icons.event_outlined),
              title: Text(
                _expected == null
                    ? l10n.waitForExpected
                    : l10n.waitForExpectedDate(_expected!.toLocalDateTime()),
              ),
              subtitle: _expected == null
                  ? Text(l10n.waitForExpectedOptional)
                  : null,
              onTap: _pickExpected,
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(
                onPressed: () => _choose(null),
                child: Text(l10n.triageSkip),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => _choose(_top(suggestions)),
                child: Text(l10n.triagePersonDone),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
