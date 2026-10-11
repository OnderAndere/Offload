import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/tokens/drift_token_candidates.dart';
import '../../domain/projects/project.dart';
import '../../domain/tokens/inline_token.dart';
import '../../domain/tokens/token_suggestion.dart';
import '../../domain/tokens/token_types.dart';
import '../../l10n/app_localizations.dart';
import '../items/item_labels.dart';
import '../startup/app_storage_provider.dart';
import 'token_display.dart';

/// Stored persons, tags and projects for the suggestion list (REQ-033).
final tokenCandidateSourceProvider = Provider<TokenCandidateSource>(
  (ref) => DriftTokenCandidates(ref.watch(storageProvider).database),
);

/// The token being typed: see `InlineTokenRegistry.tokenAt`.
typedef ActiveToken = ({
  InlineTokenType type,
  int start,
  int end,
  String query,
});

/// Works out the suggestions for the token being typed. Persons and tags
/// are loaded once, at the first trigger, never when the screen opens
/// (CLAUDE.md rule 7); a failure to load means no stored names, and typing
/// and saving go on as before. Projects are loaded at every `^` trigger
/// that starts a new token, so one just created is in the list.
class TokenSuggester {
  TokenSuggester(this._source, {this.selfItemId, this.titleOf});

  final TokenCandidateSource _source;

  /// The item being edited: never suggested for `[[`.
  final String? selfItemId;

  /// The title of an item's text, as lists show it.
  final String Function(String rawText, ParseContext context)? titleOf;
  Future<List<NamedCandidate>>? _people;
  Future<List<NamedCandidate>>? _tags;
  Future<ProjectCandidates>? _projects;
  int? _projectsFor;

  static const maxSuggestions = 5;

  Future<List<TokenSuggestion>> suggest(
    ActiveToken token,
    ParseContext context,
  ) async {
    final type = token.type;
    bool isValidNew(String word) => type.parse(word, context) != null;
    switch (type) {
      case RepeatTokenType():
        // Opened by the repeat button of the prefix bar: only the rhythms.
        return _repeats(token.query, context);
      case DateTokenType():
        // The repeat words share `!`; once a letter is typed they join the
        // dates (without one, the five lines are dates, DD-004 point 14).
        final repeats = token.query.isEmpty
            ? const <TokenSuggestion>[]
            : _repeats(token.query, context);
        final complete =
            type.parse(token.query, context) != null ||
            context.repeats.resolve(token.query) != null;
        return [
          for (final option
              in context.dates
                  .suggestions(token.query, context.today)
                  .take(maxSuggestions - repeats.length))
            TokenSuggestion(
              insert: option.word,
              label: option.word,
              date: option.date,
            ),
          ...repeats,
          // A complete date or repeat word typed by hand needs no calendar,
          // and then Enter still saves instead of opening one.
          if (token.query.isEmpty || !complete)
            const TokenSuggestion.pickDate(),
        ];
      case PersonTokenType():
        final people = await (_people ??= _load(_source.people));
        return suggestNames(token.query, people, isValidNew: isValidNew);
      case TagTokenType():
        final tags = await (_tags ??= _load(_source.tags));
        return suggestNames(token.query, tags, isValidNew: isValidNew);
      case ProjectTokenType():
        // Once per token being typed, not per keystroke.
        if (_projectsFor != token.start) {
          _projectsFor = token.start;
          _projects = _source.projects().catchError(
            (Object _) => (projects: <Project>[], uses: <String, int>{}),
          );
        }
        final found = await _projects!;
        return suggestProjects(
          token.query,
          found.projects,
          uses: found.uses,
          isValidNew: isValidNew,
        );
      case PriorityTokenType():
        return suggestPriorities(token.query, context.priorities);
      case LinkTokenType():
        // From the search index while typing; nothing is ever created here.
        final titleOf = this.titleOf;
        if (titleOf == null) return const [];
        final items = await _source
            .items(token.query, excludeId: selfItemId, limit: maxSuggestions)
            .catchError((Object _) => <ItemCandidate>[]);
        return suggestItems(items, (raw) => titleOf(raw, context));
      default:
        return const [];
    }
  }

  static List<TokenSuggestion> _repeats(String query, ParseContext context) => [
    for (final option in context.repeatsShown.suggestions(query))
      TokenSuggestion(
        insert: option.word,
        label: option.word,
        rhythm: option.rhythm,
      ),
  ];

  /// Forgets the loaded projects, after one was created.
  void forgetProjects() => _projectsFor = null;

  static Future<List<NamedCandidate>> _load(
    Future<List<NamedCandidate>> Function() load,
  ) => load().catchError((Object _) => <NamedCandidate>[]);
}

/// The suggestion list under the capture field: at most five lines, one list
/// for every token type (REQ-028). Tapping a line chooses it; on a desktop
/// [highlighted] follows the arrow keys.
class TokenSuggestionList extends StatelessWidget {
  const TokenSuggestionList({
    super.key,
    required this.type,
    required this.suggestions,
    required this.highlighted,
    required this.onChoose,
  });

  final InlineTokenType type;
  final List<TokenSuggestion> suggestions;

  /// The line Enter or Tab would choose; null on a phone.
  final int? highlighted;
  final ValueChanged<TokenSuggestion> onChoose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final look = tokenLook(type, l10n);
    final prefix = switch (type.trigger) {
      PrefixTrigger(:final prefix) => prefix,
      EnclosedTrigger(:final open) => open,
      PatternTrigger() => '',
    };
    return Card(
      margin: EdgeInsets.zero,
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 4),
        children: [
          for (final (index, suggestion) in suggestions.indexed)
            if (suggestion.pickDate)
              ListTile(
                dense: true,
                minTileHeight: 48,
                selected: index == highlighted,
                leading: const Icon(Icons.edit_calendar_outlined),
                title: Text(l10n.tokenSuggestionPickDate),
                onTap: () => onChoose(suggestion),
              )
            else
              ListTile(
                dense: true,
                minTileHeight: 48,
                selected: index == highlighted,
                leading: Icon(
                  suggestion.isNew
                      ? Icons.add
                      : suggestion.rhythm != null
                      ? tokenLook(const RepeatTokenType(), l10n).icon
                      : priorityIcon(suggestion.priority) ?? look.icon,
                ),
                title: Text(
                  suggestion.isNew
                      ? (type is ProjectTokenType
                            ? l10n.tokenSuggestionNewProject(suggestion.label)
                            : l10n.tokenSuggestionNew(suggestion.label))
                      : suggestion.label,
                ),
                subtitle: _detail(suggestion, prefix, l10n),
                onTap: () => onChoose(suggestion),
              ),
        ],
      ),
    );
  }

  Widget? _detail(
    TokenSuggestion suggestion,
    String prefix,
    AppLocalizations l10n,
  ) {
    // An item: its status, and its project.
    final status = suggestion.status;
    if (status != null) {
      final project = suggestion.parent;
      return Text(
        project == null
            ? l10n.status(status)
            : l10n.tokenSuggestionItemDetail(l10n.status(status), project),
      );
    }
    final date = suggestion.date;
    if (date != null) return Text(l10n.tokenDateChip(date.toLocalDateTime()));
    final rhythm = suggestion.rhythm;
    if (rhythm != null) return Text(l10n.repeatEvery(rhythmLetter(rhythm)));
    final priority = suggestion.priority;
    if (priority != null) return Text(l10n.tokenPriorityChip(priority.name));
    final parent = suggestion.parent;
    // A sub-project: where it is.
    if (parent != null) return Text(l10n.projectPath(parent, suggestion.label));
    // A name with spaces goes in as one of its aliases: show which.
    if (!suggestion.isNew && suggestion.insert != suggestion.label) {
      return Text(prefix + suggestion.insert);
    }
    return null;
  }
}
