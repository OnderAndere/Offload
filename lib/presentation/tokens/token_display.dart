import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/items/item_enums.dart';
import '../../domain/items/item_headline.dart';
import '../../domain/links/item_link.dart';
import '../../domain/people/contact_detail.dart';
import '../../domain/people/contacts_from_text.dart';
import '../../domain/projects/project.dart';
import '../../domain/projects/project_token.dart';
import '../../domain/projects/project_tree.dart';
import '../../domain/repeats/repeat.dart';
import '../../domain/time/local_date.dart';
import '../../domain/tokens/contact_token_types.dart';
import '../../domain/tokens/inline_token.dart';
import '../../domain/tokens/inline_token_registry.dart';
import '../../domain/tokens/token_types.dart';
import '../../l10n/app_localizations.dart';
import '../projects/project_look.dart';
import '../projects/project_providers.dart';
import '../theme/design_tokens.dart';
import 'link_choices.dart';

/// The inline syntax of this version (DD-004).
final inlineTokenRegistryProvider = Provider<InlineTokenRegistry>(
  (ref) => InlineTokenRegistry.standard(),
);

/// The date words of the active UI language, from the ARB files (DD-004
/// point 5, DD-009).
DateVocabulary dateVocabularyOf(AppLocalizations l10n) {
  final short = _words(l10n.tokenWeekdaysShort);
  final long = _words(l10n.tokenWeekdaysLong);
  if (short.length != 7 || long.length != 7) {
    // A mistake in the ARB files, found by test/l10n; never shown to users.
    throw StateError('Need seven weekdays'); // l10n-ignore: developer error
  }
  return DateVocabulary(
    today: _words(l10n.tokenDateToday),
    tomorrow: _words(l10n.tokenDateTomorrow),
    dayAfterTomorrow: _words(l10n.tokenDateDayAfterTomorrow),
    nextWeek: _words(l10n.tokenDateNextWeek),
    weekdays: [
      for (var i = 0; i < 7; i++) [short[i], long[i]],
    ],
  );
}

/// What the parser needs besides the text, in the active UI language: the
/// date and priority words (DD-004 point 5), with relative dates counting
/// from [today], and the repeat words of every app language (point 14).
/// One place, so every screen recognises the same.
ParseContext parseContextOf(AppLocalizations l10n, LocalDate today) =>
    ParseContext(
      today: today,
      dates: dateVocabularyOf(l10n),
      priorities: priorityVocabularyOf(l10n),
      repeats: allRepeatWords,
      repeatsShown: repeatVocabularyOf(l10n),
    );

/// The repeat chip of the item detail: the rhythm, the day it repeats on
/// and its first time ("Wekelijks · elke di, sinds 8 sep").
String repeatSinceText(ItemRepeat repeat, AppLocalizations l10n) {
  final since = repeat.anchor.toLocalDateTime();
  return switch (repeat.rhythm.unit) {
    RepeatUnit.day => l10n.repeatSinceDaily(since),
    RepeatUnit.week => l10n.repeatSinceWeekly(since, since),
    RepeatUnit.month => l10n.repeatSinceMonthly(repeat.anchor.day, since),
  };
}

/// The letter the ARB selects of a rhythm go by: `D`, `W` or `M`.
String rhythmLetter(Rhythm rhythm) => switch (rhythm.unit) {
  RepeatUnit.day => 'D', // l10n-ignore: ARB select key
  RepeatUnit.week => 'W', // l10n-ignore: ARB select key
  RepeatUnit.month => 'M', // l10n-ignore: ARB select key
};

/// The repeat words of one language, for its suggestion list (DD-004
/// point 14).
RepeatVocabulary repeatVocabularyOf(AppLocalizations l10n) => RepeatVocabulary(
  daily: _words(l10n.tokenRepeatDaily),
  weekly: _words(l10n.tokenRepeatWeekly),
  monthly: _words(l10n.tokenRepeatMonthly),
);

/// The repeat words of every app language: the parser recognises them all,
/// so a change of language never stops a series (DD-004 point 14).
final RepeatVocabulary allRepeatWords = RepeatVocabulary.merge([
  for (final locale in AppLocalizations.supportedLocales)
    repeatVocabularyOf(lookupAppLocalizations(locale)),
]);

/// The priority words of the active UI language, from the ARB files
/// (DD-004 points 3 and 5).
PriorityVocabulary priorityVocabularyOf(AppLocalizations l10n) =>
    PriorityVocabulary(
      high: _words(l10n.tokenPriorityHigh),
      low: _words(l10n.tokenPriorityLow),
    );

List<String> _words(String list) => [
  for (final word in list.split(','))
    if (word.trim().isNotEmpty) word.trim().toLowerCase(),
];

/// How a token type looks: icon, name and the example line of the syntax
/// overview (REQ-034). The domain types have no UI (DD-004, split between
/// the layers).
({IconData icon, String label, String? example}) tokenLook(
  InlineTokenType type,
  AppLocalizations l10n,
) => switch (type) {
  PersonTokenType() => (
    icon: Icons.person_outline,
    label: l10n.tokenPersonLabel,
    example: l10n.tokenPersonExample,
  ),
  TagTokenType() => (
    icon: Icons.tag,
    label: l10n.tokenTagLabel,
    example: l10n.tokenTagExample,
  ),
  DateTokenType() => (
    icon: Icons.event_outlined,
    label: l10n.tokenDateLabel,
    example: l10n.tokenDateExample,
  ),
  ProjectTokenType() => (
    icon: projectIcon,
    label: l10n.tokenProjectLabel,
    example: l10n.tokenProjectExample,
  ),
  LinkTokenType() => (
    icon: Icons.link,
    label: l10n.tokenLinkLabel,
    example: l10n.tokenLinkExample,
  ),
  RepeatTokenType() => (
    icon: Icons.repeat,
    label: l10n.tokenRepeatLabel,
    example: l10n.tokenRepeatExample,
  ),
  PriorityTokenType() => (
    icon: Icons.low_priority,
    label: l10n.tokenPriorityLabel,
    example: l10n.tokenPriorityExample,
  ),
  PhoneTokenType() => (
    icon: Icons.phone_outlined,
    label: l10n.tokenPhoneLabel,
    example: l10n.tokenPhoneExample,
  ),
  EmailTokenType() => (
    icon: Icons.mail_outline,
    label: l10n.tokenEmailLabel,
    example: l10n.tokenEmailExample,
  ),
  _ => (icon: Icons.label_outline, label: l10n.tokenOtherLabel, example: null),
};

/// The icon of a priority: an arrow up or down, two bars for normal, so the
/// meaning never depends on colour (DD-017).
IconData? priorityIcon(ItemPriority? priority) => switch (priority) {
  ItemPriority.high => Icons.keyboard_double_arrow_up,
  ItemPriority.normal => Icons.drag_handle,
  ItemPriority.low => Icons.keyboard_double_arrow_down,
  null => null,
};

/// Live chips for the tokens in the text being typed (REQ-019): what will
/// be recognised, before saving. Parsing is pure, so this costs no storage
/// access (REQ-001).
class TokenChips extends ConsumerWidget {
  const TokenChips({
    super.key,
    required this.text,
    required this.today,
    this.knownDates = const {},
    this.onPersonTap,
    this.onContactTap,
    this.onCreateProject,
    this.links = const {},
    this.unlinked = const {},
    this.choices,
    this.onOpenItem,
    this.onCreateLinked,
    this.repeat,
    this.thisTime,
    this.repeatsForType = true,
  });

  final String text;

  /// The stored rhythm and first time of the item (item detail, DD-004
  /// point 14): its repeat chip then says since when and on which day.
  final ItemRepeat? repeat;

  /// The date of the item's current time (item detail): with a repeat word
  /// in the text, one chip "Deze keer: …" stands for the date tokens.
  final LocalDate? thisTime;

  /// Whether the item's type repeats ([repeatsAs], decision 6b); if not,
  /// the repeat chip says it only repeats for a task.
  final bool repeatsForType;

  /// The items the saved links of this item point to, by label key (item
  /// detail, DD-018 point 14).
  final Map<String, LinkedItem> links;

  /// Label keys of the saved text that name no item.
  final Set<String> unlinked;

  /// The items chosen from the `[[` list while typing.
  final LinkChoices? choices;

  /// A tap on a link chip opens its item (item detail); null: not tappable.
  final ValueChanged<String>? onOpenItem;

  /// A tap on a "no item" chip creates the item (item detail).
  final ValueChanged<String>? onCreateLinked;

  /// A tap on the chip of a `^project` word that names no project yet
  /// (item detail: create it and put the item in it, PO decision
  /// 03-10-2026); null: that chip only tells (quick capture).
  final ValueChanged<NamesNoProject>? onCreateProject;

  /// A tap on a phone number or email address when the text names no
  /// person or several (item detail: "Link to…", T3.6); null: those chips
  /// are not tappable.
  final ValueChanged<TextContact>? onContactTap;

  /// A tap on a person chip, with the name as typed (item detail: opens the
  /// person, DD-018 point 7); null: the chips are not tappable.
  final ValueChanged<String>? onPersonTap;

  /// Relative dates count from here.
  final LocalDate today;

  /// Dates already worked out for words in the saved text (item detail):
  /// those keep their date, only newly typed ones count from [today]
  /// (DD-018 point 1).
  final Map<String, LocalDate> knownDates;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final matches = ref
        .watch(inlineTokenRegistryProvider)
        .parse(text, parseContextOf(l10n, today));
    // The projects load only once a `^` token is typed (rule 7).
    final projects = matches.any((m) => m.type is ProjectTokenType)
        ? ref.watch(projectsProvider)
        : null;
    // The one person the numbers and addresses go to (T3.6).
    final contacts = contactsInText(matches);
    final registry = ref.watch(inlineTokenRegistryProvider);
    String title(String rawText) =>
        itemHeadline(rawText, registry, parseContextOf(l10n, today)).title;
    final repeatMatch = matches
        .where((m) => m.type is RepeatTokenType)
        .firstOrNull;
    final series = repeatMatch != null && thisTime != null;
    final chips = <Widget>[];
    for (final match in matches) {
      if (match.type is RepeatTokenType) {
        // The first repeat word counts (DD-004 point 14).
        if (identical(match, repeatMatch)) {
          chips.addAll(_repeatChips(match.value as Rhythm, l10n));
        }
        continue;
      }
      // The date of a series is that of its current time, not the first.
      if (series && match.type is DateTokenType) continue;
      final chip = _chip(match, l10n, projects, contacts, title);
      if (chip != null) chips.add(chip);
    }
    if (chips.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 8, runSpacing: 4, children: chips);
  }

  Widget? _chip(
    TokenMatch match,
    AppLocalizations l10n,
    AsyncValue<List<Project>>? projects,
    ({String? person, List<TextContact> contacts}) contacts,
    String Function(String rawText) title,
  ) {
    if (match.type is ProjectTokenType) {
      return _projectChip(match.word, l10n, projects);
    }
    if (match.type is LinkTokenType) return _linkChip(match.word, l10n, title);
    if (match.type is PhoneTokenType || match.type is EmailTokenType) {
      return _contactChip(match, l10n, contacts);
    }
    var value = match.value;
    // A word removed and typed again before the save shows its old date
    // until the processor has anchored it anew; then this updates.
    if (value is LocalDate) value = knownDates[match.word] ?? value;
    final onPersonTap = this.onPersonTap;
    return TokenChip(
      type: match.type,
      word: match.word,
      date: value is LocalDate ? value : null,
      priority: value is ItemPriority ? value : null,
      today: today,
      onTap: onPersonTap != null && match.type is PersonTokenType
          ? () => onPersonTap(match.word)
          : null,
    );
  }

  /// The rhythm, and in the item detail the current time (DD-018 point 18).
  List<Widget> _repeatChips(Rhythm rhythm, AppLocalizations l10n) {
    final title = l10n.repeatRhythmTitle(rhythmLetter(rhythm));
    final stored = repeat;
    final thisTime = this.thisTime;
    if (!repeatsForType) {
      return [
        TokenChip(
          type: const RepeatTokenType(),
          word: l10n.repeatNotForType(title),
          date: null,
          today: today,
          muted: true,
        ),
        if (thisTime != null)
          TokenChip(
            type: const DateTokenType(),
            word: '',
            date: thisTime,
            today: today,
          ),
      ];
    }
    final since = stored == null || stored.rhythm != rhythm
        ? title
        : repeatSinceText(stored, l10n);
    return [
      TokenChip(
        type: const RepeatTokenType(),
        word: since,
        date: null,
        today: today,
      ),
      if (thisTime != null)
        TokenChip(
          type: const DateTokenType(),
          word: '',
          date: thisTime,
          today: today,
          thisTime: true,
        ),
    ];
  }

  /// A phone number or email address while typing: with the person it
  /// goes to after saving ("06-12345678 → Jan"), or, when the text names
  /// none or several, tappable to link it in the item detail.
  Widget _contactChip(
    TokenMatch match,
    AppLocalizations l10n,
    ({String? person, List<TextContact> contacts}) contacts,
  ) {
    final person = contacts.person;
    final contact = contacts.contacts.firstWhere(
      (c) => c.value == match.word,
      orElse: () => (
        kind: match.type is PhoneTokenType
            ? ContactKind.phone
            : ContactKind.email,
        value: match.word,
        label: null,
      ),
    );
    final onContactTap = this.onContactTap;
    final chip = TokenChip(
      type: match.type,
      word: person == null
          ? match.word
          : l10n.tokenContactFor(match.word, person),
      date: null,
      today: today,
      hint: person == null && onContactTap != null
          ? l10n.contactLinkTooltip
          : null,
      onTap: person == null && onContactTap != null
          ? () => onContactTap(contact)
          : null,
    );
    return person == null && onContactTap != null
        ? Tooltip(message: l10n.contactLinkTooltip, child: chip)
        : chip;
  }

  /// A link `[[…]]` (DD-018 point 14): the current title of its item, which
  /// a tap opens; "in trash" when it is in the trash; "no item" when
  /// processing found none, which in the item detail a tap creates. While
  /// typing, a chosen item shows its label, anything else the label as is.
  Widget _linkChip(
    String word,
    AppLocalizations l10n,
    String Function(String rawText) title,
  ) {
    final key = linkKey(word);
    final open = onOpenItem;
    final target = links[key];
    final chosen = choices?.itemFor(word);
    if (target != null) {
      final name = title(target.rawText);
      return TokenChip(
        type: const LinkTokenType(),
        word: target.trashed ? l10n.tokenLinkTrashed(name) : name,
        date: null,
        today: today,
        accent: !target.trashed,
        hint: open == null ? null : l10n.tokenLinkOpenTooltip,
        onTap: open == null ? null : () => open(target.itemId),
      );
    }
    if (chosen != null) {
      return TokenChip(
        type: const LinkTokenType(),
        word: word.trim(),
        date: null,
        today: today,
        accent: true,
        hint: open == null ? null : l10n.tokenLinkOpenTooltip,
        onTap: open == null ? null : () => open(chosen),
      );
    }
    if (unlinked.contains(key)) {
      final create = onCreateLinked;
      final chip = TokenChip(
        type: const LinkTokenType(),
        word: l10n.tokenLinkNone(word.trim()),
        date: null,
        today: today,
        hint: create == null ? null : l10n.tokenLinkCreateTooltip,
        onTap: create == null ? null : () => create(word.trim()),
      );
      return create == null
          ? chip
          : Tooltip(message: l10n.tokenLinkCreateTooltip, child: chip);
    }
    return TokenChip(
      type: const LinkTokenType(),
      word: word.trim(),
      date: null,
      today: today,
    );
  }

  /// A `^project` while typing: the project it names, as its path. A word
  /// that names no project in use says so, so saving never quietly links
  /// nothing (PO decision 03-10-2026); in the item detail a tap creates the
  /// project. No chip when the projects cannot be read; while they load the
  /// chip shows the word.
  Widget? _projectChip(
    String word,
    AppLocalizations l10n,
    AsyncValue<List<Project>>? projects,
  ) {
    if (projects == null || projects.hasError) return null;
    final loaded = projects.valueOrNull;
    if (loaded == null) {
      return TokenChip(
        type: const ProjectTokenType(),
        word: word,
        date: null,
        today: today,
      );
    }
    final onCreate = onCreateProject;
    switch (matchProjectWord(word, loaded)) {
      case NamesProject(:final id):
        final tree = ProjectTree(loaded);
        final project = tree[id];
        if (project == null) return null;
        return TokenChip(
          type: const ProjectTokenType(),
          word: projectPathOf(project, tree, l10n),
          date: null,
          today: today,
        );
      case NamesSeveral():
        return TokenChip(
          type: const ProjectTokenType(),
          word: l10n.tokenProjectSeveral(word),
          date: null,
          today: today,
        );
      case final NamesNoProject none:
        final tappable = onCreate != null && none.canCreate;
        final chip = TokenChip(
          type: const ProjectTokenType(),
          word: l10n.tokenProjectNone(word),
          date: null,
          today: today,
          hint: tappable ? l10n.tokenProjectCreateTooltip : null,
          onTap: tappable ? () => onCreate(none) : null,
        );
        return tappable
            ? Tooltip(message: l10n.tokenProjectCreateTooltip, child: chip)
            : chip;
    }
  }
}

/// One token as a chip: the word (a name or tag, without prefix) or the
/// date. A date that is today or overdue needs attention now (DD-017):
/// orange, with another icon, so it never depends on colour alone. The
/// capture field, the item detail and the inbox cards all use this.
class TokenChip extends StatelessWidget {
  const TokenChip({
    super.key,
    required this.type,
    required this.word,
    required this.date,
    required this.today,
    this.priority,
    this.dense = false,
    this.onTap,
    this.hint,
    this.accent = false,
    this.thisTime = false,
    this.muted = false,
  });

  final InlineTokenType type;

  /// A date chip that reads "Deze keer: …": the current time of a series.
  final bool thisTime;

  /// Greyed out: a repeat word that does not repeat on this type.
  final bool muted;

  /// In the calm accent colour: a link to an item (DD-018 point 14 (e)).
  final bool accent;

  /// The text after the prefix, as typed.
  final String word;

  /// For a date token: the date; null otherwise.
  final LocalDate? date;
  final LocalDate today;

  /// For a priority token: the priority; null otherwise.
  final ItemPriority? priority;

  /// Smaller, for inside a list card.
  final bool dense;

  /// Makes the chip a button (a person in the item detail).
  final VoidCallback? onTap;

  /// What a tap does, for screen readers.
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final look = tokenLook(type, l10n);
    final date = this.date;
    final priority = this.priority;
    final text = date != null
        ? (thisTime
              ? l10n.repeatThisTime(date.toLocalDateTime())
              : l10n.tokenDateChip(date.toLocalDateTime()))
        : priority != null
        ? l10n.tokenPriorityChip(priority.name)
        : word;
    final due = date?.compareTo(today);
    final attention = due != null && due <= 0;
    final icon = !attention
        ? priorityIcon(priority) ?? look.icon
        : due == 0
        ? Icons.today
        : Icons.event_busy;
    final accentColor = accent
        ? Theme.of(context).colorScheme.primary
        : muted
        ? Theme.of(context).colorScheme.onSurfaceVariant
        : null;
    final avatar = Icon(
      icon,
      size: dense ? 16 : 18,
      color: attention ? attentionColor : accentColor,
    );
    final label = Text(
      text,
      style: attention
          ? const TextStyle(color: attentionColor)
          : accentColor == null
          ? null
          : TextStyle(color: accentColor),
    );
    final side = attention
        ? const BorderSide(color: attentionColor)
        : accentColor == null
        ? null
        : BorderSide(color: accentColor);
    final onTap = this.onTap;
    return Semantics(
      label: l10n.tokenChipSemantics(look.label, text),
      hint: hint,
      button: onTap != null,
      // The chip's own tap is excluded with its semantics: a screen reader
      // taps here.
      onTap: onTap,
      excludeSemantics: true,
      child: onTap != null
          ? ActionChip(
              avatar: avatar,
              label: label,
              side: side,
              onPressed: onTap,
            )
          : Chip(
              avatar: avatar,
              label: label,
              side: side,
              visualDensity: dense ? VisualDensity.compact : null,
              materialTapTargetSize: dense
                  ? MaterialTapTargetSize.shrinkWrap
                  : null,
              labelPadding: dense
                  ? const EdgeInsetsDirectional.only(end: 4)
                  : null,
            ),
    );
  }
}

/// Today's date on this device: relative dates in chips and suggestions
/// count from here.
LocalDate todayOnDevice() => LocalDate.of(DateTime.now());
