import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/connections/connection_graph.dart';
import '../../domain/items/item.dart';
import '../../domain/items/item_enums.dart';
import '../../domain/items/item_headline.dart';
import '../../domain/time/local_date.dart';
import '../../l10n/app_localizations.dart';
import '../inbox/inbox_card.dart';
import '../items/item_labels.dart';
import '../tokens/token_display.dart';

/// What a node of Connections shows (DD-018 point 15): its title, its type
/// line and whether it needs attention now.
class NodeLook {
  const NodeLook({
    required this.node,
    required this.title,
    required this.kind,
    required this.caption,
    this.item,
    this.urgency = Urgency.none,
    this.done = false,
    this.archived = false,
  });

  final NodeRef node;
  final String title;

  /// The type word alone: "Taak", "Persoon", "Project".
  final String kind;

  /// The type line: the type word, with "vandaag", "af" or "gearchiveerd".
  final String caption;
  final Item? item;
  final Urgency urgency;
  final bool done;
  final bool archived;
}

/// Turns nodes into what they show, with the words of the app.
class NodeLooks {
  NodeLooks(this.data, this.l10n, this._title, this.today);

  final ConnectionData data;
  final AppLocalizations l10n;
  final String Function(String rawText) _title;
  final LocalDate today;

  final _cache = <NodeRef, NodeLook>{};

  NodeLook of(NodeRef node) => _cache[node] ??= _look(node);

  NodeLook _look(NodeRef node) {
    switch (node.kind) {
      case NodeKind.item:
        final item = data.item(node.id);
        if (item == null) {
          const none = ''; // l10n-ignore: no text for a node gone
          return NodeLook(node: node, title: none, kind: none, caption: none);
        }
        final kind = item.type == null
            ? l10n.connectionsKind(NodeKind.item.name)
            : l10n.type(item.type);
        final urgency = urgencyOf(item, today);
        final done = item.status == ItemStatus.done;
        final archived = item.status == ItemStatus.archived;
        final extra = urgency != Urgency.none
            ? l10n.connectionsUrgency(urgency.name)
            : done
            ? l10n.connectionsDone
            : archived
            ? l10n.connectionsArchived
            : null;
        return NodeLook(
          node: node,
          title: _title(item.rawText),
          kind: kind,
          caption: extra == null ? kind : l10n.connectionsJoin(kind, extra),
          item: item,
          urgency: urgency,
          done: done,
          archived: archived,
        );
      case NodeKind.project:
        final project = data.project(node.id);
        final kind = l10n.connectionsKind(NodeKind.project.name);
        final archived = project?.archivedAt != null;
        return NodeLook(
          node: node,
          title: project?.name ?? kind,
          kind: kind,
          caption: archived
              ? l10n.connectionsJoin(kind, l10n.connectionsArchived)
              : kind,
          archived: archived,
        );
      case NodeKind.person:
        final kind = l10n.connectionsKind(NodeKind.person.name);
        return NodeLook(
          node: node,
          title: data.person(node.id)?.name ?? kind,
          kind: kind,
          caption: kind,
        );
    }
  }

  /// Why [other] is linked to [self], in words, one per line between them
  /// ("koppeling", "wacht op Sanne").
  List<String> reasons(NodeRef self, NodeRef other, Set<Tie> ties) {
    final person = self.kind == NodeKind.person
        ? self
        : other.kind == NodeKind.person
        ? other
        : null;
    final name = person == null
        ? l10n.connectionsKind(NodeKind.person.name)
        : of(person).title;
    final order = TieKind.values;
    final sorted = ties.toList()
      ..sort((a, b) => order.indexOf(a.kind).compareTo(order.indexOf(b.kind)));
    return [
      for (final tie in sorted)
        switch (tie.kind) {
          TieKind.link => l10n.connectionsReason(
            tie.outgoing ? 'linksTo' : 'linkedFrom', // l10n-ignore: select key
          ),
          TieKind.project => l10n.connectionsReason(
            tie.outgoing ? 'project' : 'inProject', // l10n-ignore: select key
          ),
          TieKind.parentProject => l10n.connectionsReason(
            tie.outgoing ? 'parent' : 'sub', // l10n-ignore: select key
          ),
          TieKind.requester ||
          TieKind.waitingOn ||
          TieKind.mention => l10n.connectionsReasonPerson(tie.kind.name, name),
        },
    ];
  }
}

/// The looks of the nodes for [data], with today's words.
NodeLooks nodeLooksOf(
  WidgetRef ref,
  ConnectionData data,
  AppLocalizations l10n,
) {
  final now = ref.watch(minuteClockProvider).valueOrNull ?? DateTime.now();
  final today = LocalDate.of(now);
  final registry = ref.watch(inlineTokenRegistryProvider);
  final context = parseContextOf(l10n, today);
  return NodeLooks(
    data,
    l10n,
    (rawText) => itemHeadline(rawText, registry, context).title,
    today,
  );
}
