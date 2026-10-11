import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/items/item.dart';
import '../../domain/items/item_enums.dart';
import '../../domain/people/person.dart';
import '../../domain/people/person_overview.dart';
import '../../domain/tokens/stored_token.dart';
import '../../domain/tokens/token_processing.dart';
import '../../domain/tokens/token_types.dart';
import '../../l10n/app_localizations.dart';
import '../items/item_type_look.dart';
import 'people_providers.dart';

/// The icon of a person, on rows and chips.
const personIcon = Icons.person_outline;

/// The icon of the person who asked: the one of the type request.
final requesterIcon = itemTypeIcon(ItemType.request);

/// The icon of the person waited on, as in triage.
const waitingIcon = Icons.hourglass_empty;

/// The message for a refused person change (DD-018 point 7).
String personErrorText(Object error, AppLocalizations l10n) =>
    error is PersonException
    ? switch (error.problem) {
        PersonProblem.emptyName => l10n.personErrorEmptyName,
        PersonProblem.nameTaken => l10n.personErrorNameTaken,
        PersonProblem.notAvailable => l10n.personErrorNotAvailable,
        PersonProblem.samePerson => l10n.personErrorSamePerson,
      }
    : l10n.itemChangeFailed;

/// A round badge with the initials of a person; [quiet] for someone with
/// nothing open.
class PersonAvatar extends StatelessWidget {
  const PersonAvatar({
    super.key,
    required this.name,
    this.size = 32,
    this.quiet = false,
  });

  final String name;
  final double size;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: CircleAvatar(
        radius: size / 2,
        backgroundColor: quiet
            ? colors.surfaceContainerHighest
            : colors.secondaryContainer,
        foregroundColor: quiet
            ? colors.onSurfaceVariant
            : colors.onSecondaryContainer,
        child: Text(
          initialsOf(name),
          style: TextStyle(fontSize: size * 0.38, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

/// The people an item names with `@` in its processed tokens, by id.
Set<String> namedPersonIds(
  List<StoredToken> tokens,
  Map<String, String> personIdByName,
) => {
  for (final t in tokens)
    if (t.typeId == const PersonTokenType().id)
      ?personIdByName[nameKey(t.word)],
};

/// The requester and, while it waits, the person waited on, as grey chips
/// on a card (DD-018 point 7); not a person the text already names, and
/// not [hidePersonId] (the person whose screen shows the card).
List<Widget> personRoleChips(
  Item item, {
  required Set<String> named,
  String? hidePersonId,
}) => [
  if (item.requesterId case final id?
      when !named.contains(id) && id != hidePersonId)
    PersonRoleChip(personId: id, waiting: false),
  if (item.waitingOnId case final id?
      when isWaitingNow(item) && !named.contains(id) && id != hidePersonId)
    PersonRoleChip(personId: id, waiting: true),
];

/// One role of a person on a card: ✋ who asked, or ⏳ who it waits on.
/// Nothing when the person no longer exists.
class PersonRoleChip extends ConsumerWidget {
  const PersonRoleChip({
    super.key,
    required this.personId,
    required this.waiting,
  });

  final String personId;
  final bool waiting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final person = ref.watch(peopleByIdProvider)[personId];
    if (person == null) return const SizedBox.shrink();
    final kind = waiting ? l10n.personWaitingKind : l10n.personRequesterKind;
    return Tooltip(
      message: kind,
      child: Semantics(
        label: l10n.tokenChipSemantics(kind, person.name),
        excludeSemantics: true,
        child: Chip(
          avatar: Icon(waiting ? waitingIcon : requesterIcon, size: 16),
          label: Text(person.name),
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          labelPadding: const EdgeInsetsDirectional.only(end: 4),
        ),
      ),
    );
  }
}
