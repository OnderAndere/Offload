import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/connections/connection_graph.dart';
import '../../domain/links/item_link.dart';
import '../items/item_providers.dart';
import '../people/people_providers.dart';
import '../projects/project_providers.dart';

/// Every live `[[…]]` link between live items (DD-018 point 15).
final allLinksProvider = StreamProvider.autoDispose<List<ItemLinkPair>>(
  (ref) => ref.watch(itemLinkRepositoryProvider).watchAllLinks(),
);

/// The people named in the text of each live item.
final mentionsProvider = StreamProvider.autoDispose<Map<String, Set<String>>>(
  (ref) => ref.watch(itemRepositoryProvider).watchMentions(),
);

/// What Connections draws from, or null while it loads (T10.14, DD-018
/// point 15).
final connectionDataProvider = Provider.autoDispose<ConnectionData?>((ref) {
  final items = ref.watch(liveItemsProvider).valueOrNull;
  final projects = ref.watch(projectsProvider).valueOrNull;
  final people = ref.watch(peopleProvider).valueOrNull;
  final merged = ref.watch(mergedIntoProvider).valueOrNull;
  final links = ref.watch(allLinksProvider).valueOrNull;
  final mentions = ref.watch(mentionsProvider).valueOrNull;
  if (items == null ||
      projects == null ||
      people == null ||
      merged == null ||
      links == null ||
      mentions == null) {
    return null;
  }
  return ConnectionData(
    items: items,
    projects: projects,
    people: people,
    mergedInto: merged,
    links: links,
    mentions: mentions,
  );
});

/// The items, people and projects opened last while the app runs, the
/// newest first, at most five (DD-018 point 15 (c)): the start focus and
/// the list in *Focus kiezen* before typing. Not stored.
final recentlyOpenedProvider =
    NotifierProvider<RecentlyOpenedNotifier, List<NodeRef>>(
      RecentlyOpenedNotifier.new,
    );

class RecentlyOpenedNotifier extends Notifier<List<NodeRef>> {
  static const kept = 5;

  @override
  List<NodeRef> build() => const [];

  /// [node] was opened: it goes to the front.
  void opened(NodeRef node) {
    if (state.isNotEmpty && state.first == node) return;
    state = [node, ...state.where((n) => n != node)].take(kept).toList();
  }
}

/// The focus of Connections, the foci before it (Back goes there) and the
/// depth (DD-018 point 15). Kept while the app runs, not stored.
class ConnectionsState {
  const ConnectionsState({
    this.focus,
    this.history = const [],
    this.twoSteps = false,
  });

  /// Chosen by the user; null: the item opened last.
  final NodeRef? focus;

  /// The earlier foci, the most recent last.
  final List<NodeRef> history;

  /// *2 stappen*; it starts on *1 stap* (decision (d)).
  final bool twoSteps;
}

final connectionsProvider =
    NotifierProvider<ConnectionsNotifier, ConnectionsState>(
      ConnectionsNotifier.new,
    );

class ConnectionsNotifier extends Notifier<ConnectionsState> {
  /// How many foci Back can return to.
  static const historyKept = 30;

  @override
  ConnectionsState build() => const ConnectionsState();

  /// Makes [node] the focus; the focus before it goes to the history.
  void focusOn(NodeRef node, {NodeRef? from}) {
    final previous = state.focus ?? from;
    if (previous == node) return;
    final history = [...state.history, ?previous];
    state = ConnectionsState(
      focus: node,
      history: history.length > historyKept
          ? history.sublist(history.length - historyKept)
          : history,
      twoSteps: state.twoSteps,
    );
  }

  /// Goes back to the previous focus; false when there is none.
  bool back() {
    if (state.history.isEmpty) return false;
    state = ConnectionsState(
      focus: state.history.last,
      history: state.history.sublist(0, state.history.length - 1),
      twoSteps: state.twoSteps,
    );
    return true;
  }

  void setTwoSteps(bool twoSteps) => state = ConnectionsState(
    focus: state.focus,
    history: state.history,
    twoSteps: twoSteps,
  );
}

/// The focus on screen: the one chosen, or else the item opened last
/// (decision (3)); null for the empty state.
final connectionsFocusProvider = Provider<NodeRef?>((ref) {
  final chosen = ref.watch(connectionsProvider.select((s) => s.focus));
  if (chosen != null) return chosen;
  for (final node in ref.watch(recentlyOpenedProvider)) {
    if (node.kind == NodeKind.item) return node;
  }
  return null;
});
