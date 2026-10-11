import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/connections/connection_graph.dart';
import '../../domain/items/item_headline.dart';
import '../../domain/items/today.dart';
import '../../domain/projects/project.dart';
import '../../domain/search/search_index.dart';
import '../../domain/tokens/token_processing.dart';
import '../../l10n/app_localizations.dart';
import '../home/destination.dart';
import '../items/item_detail_screen.dart';
import '../items/item_labels.dart';
import '../items/item_type_look.dart';
import '../people/person_screen.dart';
import '../projects/project_providers.dart';
import '../search/search_providers.dart';
import '../theme/offload_colors.dart';
import 'connections_look.dart';
import 'connections_providers.dart';

/// The icon of a node in a list: the type icon of an item, a person, a
/// project (DD-018 point 15).
IconData nodeIcon(NodeLook look) => switch (look.node.kind) {
  NodeKind.person => Icons.person_outline,
  NodeKind.project => Icons.folder_outlined,
  NodeKind.item => switch (look.item?.type) {
    null => Icons.inbox_outlined,
    final type => look.done ? Icons.check_box : itemTypeIcon(type),
  },
};

/// Opens [node] on its own screen: an item in the detail (the right pane
/// on Windows), a person over the current screen, a project in Projects.
void openNode(BuildContext context, WidgetRef ref, NodeRef node) {
  switch (node.kind) {
    case NodeKind.item:
      unawaited(ItemDetailScreen.open(context, node.id));
    case NodeKind.person:
      unawaited(
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => PersonScreen(personId: node.id, standalone: true),
          ),
        ),
      );
    case NodeKind.project:
      ref.read(openProjectProvider.notifier).state = OpenProject(node.id);
      ref.read(destinationProvider.notifier).state = Destination.projects;
  }
}

/// The preview of [node] (long press, Space on Windows): what it is, without
/// leaving the graph, with *Focussen* and *Openen* (DD-018 point 15).
Future<void> showNodePreview(
  BuildContext context,
  WidgetRef ref,
  NodeRef node, {
  required bool isFocus,
}) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  builder: (sheet) => Consumer(
    builder: (sheet, ref, _) {
      final l10n = AppLocalizations.of(sheet);
      final data = ref.watch(connectionDataProvider);
      if (data == null || !data.contains(node)) return const SizedBox();
      final looks = nodeLooksOf(ref, data, l10n);
      final look = looks.of(node);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: _Preview(
            look: look,
            data: data,
            looks: looks,
            onFocus: isFocus
                ? null
                : () {
                    Navigator.of(sheet).pop();
                    ref
                        .read(connectionsProvider.notifier)
                        .focusOn(
                          node,
                          from: ref.read(connectionsFocusProvider),
                        );
                  },
            onOpen: () {
              Navigator.of(sheet).pop();
              openNode(context, ref, node);
            },
          ),
        ),
      );
    },
  ),
);

class _Preview extends StatelessWidget {
  const _Preview({
    required this.look,
    required this.data,
    required this.looks,
    required this.onFocus,
    required this.onOpen,
  });

  final NodeLook look;
  final ConnectionData data;
  final NodeLooks looks;
  final VoidCallback? onFocus;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final item = look.item;
    final neighbours = data.neighboursOf(look.node);
    final rows = <(String, Widget)>[];
    final String subtitle;
    String? body;
    if (item != null) {
      subtitle = l10n.connectionsJoin(look.kind, l10n.status(item.status));
      final project = item.projectId == null
          ? null
          : data.project(item.projectId!);
      if (project != null) {
        rows.add((l10n.connectionsPreviewProject, Text(project.name)));
      }
      final dueAt = item.dueAt;
      if (dueAt != null) {
        final urgent = look.urgency != Urgency.none;
        final date = Text(
          urgent
              ? l10n.connectionsUrgency(look.urgency.name)
              : l10n.connectionsPreviewDate(
                  storedToDateOnly(dueAt).toLocalDateTime(),
                ),
          style: urgent
              ? TextStyle(
                  color: context.offloadColors.attentionText,
                  fontWeight: FontWeight.w600,
                )
              : null,
        );
        rows.add((
          l10n.connectionsPreviewDeadline,
          urgent
              ? Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: context.offloadColors.attentionText,
                    ),
                    const SizedBox(width: 4),
                    date,
                  ],
                )
              : date,
        ));
      }
      final people = [
        for (final n in neighbours)
          if (n.node.kind == NodeKind.person) looks.of(n.node).title,
      ];
      if (people.isNotEmpty) {
        rows.add((
          l10n.connectionsPreviewPeople,
          Text(people.reduce(l10n.connectionsList)),
        ));
      }
      final note = (item.body ?? '').trim();
      body = note.isNotEmpty ? note : textAfterFirstLine(item.rawText);
    } else {
      final open = neighbours.where((n) {
        final linked = n.node.kind == NodeKind.item
            ? data.item(n.node.id)
            : null;
        return linked != null && isOpen(linked.status);
      }).length;
      final person = look.node.kind == NodeKind.person
          ? data.person(look.node.id)
          : null;
      final work = [
        ?person?.jobTitle,
        ?person?.organisation,
      ].where((s) => s.trim().isNotEmpty).toList();
      subtitle = work.fold(look.caption, l10n.connectionsJoin);
      body = l10n.connectionsPreviewOpenItems(open);
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(look.title, style: theme.textTheme.titleMedium),
        Text(subtitle, style: muted),
        const SizedBox(height: 8),
        for (final (label, value) in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 96, child: Text(label, style: muted)),
                Expanded(child: value),
              ],
            ),
          ),
        if (body.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            body,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: muted,
          ),
        ],
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (onFocus != null)
              OutlinedButton(
                onPressed: onFocus,
                child: Text(l10n.connectionsFocusAction),
              ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: onOpen,
              child: Text(l10n.connectionsOpenAction),
            ),
          ],
        ),
      ],
    );
  }
}

/// *Focus kiezen* (decision (c)): a search field over items, people and
/// projects; before typing, what was opened last. Gives the node chosen.
Future<NodeRef?> chooseFocus(BuildContext context) =>
    showModalBottomSheet<NodeRef>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _ChooseFocus(),
    );

class _ChooseFocus extends ConsumerStatefulWidget {
  const _ChooseFocus();

  @override
  ConsumerState<_ChooseFocus> createState() => _ChooseFocusState();
}

class _ChooseFocusState extends ConsumerState<_ChooseFocus> {
  final _query = TextEditingController();
  Timer? _wait;
  List<SearchHit> _hits = const [];
  var _searched = '';

  @override
  void dispose() {
    _wait?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _changed(String text) {
    _wait?.cancel();
    _wait = Timer(const Duration(milliseconds: 150), () async {
      final query = text.trim();
      final hits = query.isEmpty
          ? const <SearchHit>[]
          : await ref.read(searchIndexProvider).search(query, limit: 20);
      if (!mounted || _query.text.trim() != query) return;
      setState(() {
        _hits = hits;
        _searched = query;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final data = ref.watch(connectionDataProvider);
    final looks = data == null ? null : nodeLooksOf(ref, data, l10n);
    final query = _query.text.trim();

    Widget row(NodeRef node) {
      final look = looks!.of(node);
      final item = look.item;
      return ListTile(
        leading: Icon(nodeIcon(look)),
        title: Text(look.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Text(
          item == null ? look.kind : l10n.status(item.status),
          style: theme.textTheme.bodySmall,
        ),
        onTap: () => Navigator.of(context).pop(node),
      );
    }

    Widget header(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        text,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );

    final children = <Widget>[];
    if (looks != null && data != null) {
      if (query.isEmpty) {
        final recent = [
          for (final node in ref.watch(recentlyOpenedProvider))
            if (data.contains(node)) node,
        ];
        if (recent.isNotEmpty) {
          children
            ..add(header(l10n.connectionsRecent))
            ..addAll(recent.map(row));
        }
      } else if (query == _searched) {
        NodeRef refOf(SearchHit hit) => hit.entity == SearchEntity.item
            ? NodeRef.item(hit.id)
            : NodeRef.person(hit.id);
        final items = [
          for (final hit in _hits)
            if (hit.entity == SearchEntity.item && data.contains(refOf(hit)))
              refOf(hit),
        ];
        final people = [
          for (final hit in _hits)
            if (hit.entity == SearchEntity.person && data.contains(refOf(hit)))
              refOf(hit),
        ];
        final key = nameKey(query);
        final projects = [
          for (final project
              in ref.watch(projectsProvider).valueOrNull ?? const <Project>[])
            if (nameKey(project.name).contains(key))
              NodeRef.project(project.id),
        ];
        if (items.isNotEmpty) {
          children
            ..add(header(l10n.connectionsChooseItems))
            ..addAll(items.map(row));
        }
        if (people.isNotEmpty) {
          children
            ..add(header(l10n.connectionsChoosePeople))
            ..addAll(people.map(row));
        }
        if (projects.isNotEmpty) {
          children
            ..add(header(l10n.connectionsChooseProjects))
            ..addAll(projects.map(row));
        }
        if (children.isEmpty) {
          children.add(
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.connectionsNoResults),
            ),
          );
        }
      }
    }
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                l10n.connectionsChooseTitle,
                style: theme.textTheme.titleMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _query,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: l10n.connectionsChooseHint,
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                  ),
                ),
                onChanged: (text) {
                  setState(() {});
                  _changed(text);
                },
              ),
            ),
            Expanded(child: ListView(children: children)),
          ],
        ),
      ),
    );
  }
}

/// The list behind "+n meer": every direct connection of the focus, with
/// why it is linked; a tap makes it the focus, a long press previews it.
Future<void> showAllConnections(
  BuildContext context,
  WidgetRef ref,
  ConnectionGraph graph,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  // A Consumer of its own: the sheet may outlive the screen that opened it.
  builder: (sheet) => Consumer(
    builder: (sheet, ref, _) {
      final l10n = AppLocalizations.of(sheet);
      final theme = Theme.of(sheet);
      final data = ref.watch(connectionDataProvider);
      if (data == null) return const SizedBox();
      final looks = nodeLooksOf(ref, data, l10n);
      final focus = looks.of(graph.focus);
      return SizedBox(
        height: MediaQuery.sizeOf(sheet).height * 0.75,
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Text(
                l10n.connectionsAllTitle(focus.title, graph.direct.length),
                style: theme.textTheme.titleMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Text(
                l10n.connectionsDirectHeader(graph.direct.length),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            for (final n in graph.direct)
              Builder(
                builder: (row) {
                  final look = looks.of(n.node);
                  return ListTile(
                    leading: Icon(nodeIcon(look)),
                    title: Text(
                      look.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(look.caption),
                    trailing: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 140),
                      child: Text(
                        looks
                            .reasons(graph.focus, n.node, n.ties)
                            .reduce(l10n.connectionsJoin),
                        textAlign: TextAlign.end,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(sheet).pop();
                      ref
                          .read(connectionsProvider.notifier)
                          .focusOn(n.node, from: graph.focus);
                    },
                    onLongPress: () =>
                        showNodePreview(context, ref, n.node, isFocus: false),
                  );
                },
              ),
          ],
        ),
      );
    },
  ),
);
