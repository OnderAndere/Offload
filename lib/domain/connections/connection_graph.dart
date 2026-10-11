import '../items/item.dart';
import '../items/today.dart';
import '../links/item_link.dart';
import '../people/person.dart';
import '../projects/project.dart';
import '../time/local_date.dart';
import '../tokens/token_processing.dart';

/// What a node of Connections is (REQ-059, DD-018 point 15). Decisions and
/// questions come with T10.11 and T10.12.
enum NodeKind { item, project, person }

/// One node: its kind and the id of the item, project or person.
class NodeRef {
  const NodeRef(this.kind, this.id);

  const NodeRef.item(this.id) : kind = NodeKind.item;
  const NodeRef.project(this.id) : kind = NodeKind.project;
  const NodeRef.person(this.id) : kind = NodeKind.person;

  final NodeKind kind;
  final String id;

  @override
  bool operator ==(Object other) =>
      other is NodeRef && other.kind == kind && other.id == id;

  @override
  int get hashCode => Object.hash(kind, id);

  @override
  String toString() => '${kind.name}:$id';
}

/// The kind of a line. Each is stored one way: from an item to the item it
/// links to (`[[…]]`), to its project and to its people, from a sub-project
/// to its parent.
enum TieKind { link, project, parentProject, requester, waitingOn, mention }

/// One line between two nodes as seen from one of them: [outgoing] when
/// that node is where the line starts (it links to the other, the other is
/// its project, its parent, or the person it was asked by, waits on or
/// names).
typedef Tie = ({TieKind kind, bool outgoing});

/// How urgent an item is by its deadline: the rule of the date chip
/// (DD-017, DD-018 point 15 (a)).
enum Urgency { none, today, overdue }

/// The urgency of [item] on [today]: only an open item with a deadline
/// today or earlier.
Urgency urgencyOf(Item item, LocalDate today) {
  final dueAt = item.dueAt;
  if (dueAt == null || !isOpen(item.status)) return Urgency.none;
  final order = storedToDateOnly(dueAt).compareTo(today);
  return order < 0
      ? Urgency.overdue
      : order == 0
      ? Urgency.today
      : Urgency.none;
}

/// The limits of the graph (DD-018 point 15, revised by the PO 04-10-2026
/// after measuring the layout on a phone): direct nodes on one step and on
/// two steps (the last one "+n meer" when there are more), second-step
/// nodes per direct node and in all.
const maxDirectOneStep = 12;
const maxDirectTwoSteps = 8;
const maxSecondPerNode = 2;
const maxSecondNodes = 8;

/// The most direct nodes drawn, one or two steps deep.
int maxDirectNodes({required bool twoSteps}) =>
    twoSteps ? maxDirectTwoSteps : maxDirectOneStep;

/// Everything Connections draws from: live items (done and archived
/// included, the trash not), live projects, live people with the merges,
/// live links and the people named in the text of each item. Built once
/// per change of the data; [graphOf] then works for any focus.
class ConnectionData {
  ConnectionData({
    required Iterable<Item> items,
    required Iterable<Project> projects,
    required Iterable<Person> people,
    Map<String, String> mergedInto = const {},
    Iterable<ItemLinkPair> links = const [],
    Map<String, Set<String>> mentions = const {},
  }) {
    for (final item in items) {
      _items[item.id] = item;
    }
    for (final project in projects) {
      _projects[project.id] = project;
    }
    for (final person in people) {
      _people[person.id] = person;
    }
    // A merged person is shown as the one it was merged into (DD-015).
    String? livePerson(String? id) {
      final seen = <String>{};
      while (id != null && !_people.containsKey(id)) {
        if (!seen.add(id)) return null;
        id = mergedInto[id];
      }
      return id;
    }

    void tie(NodeRef from, NodeRef to, TieKind kind) {
      if (from == to) return;
      (_ties[from] ??= {}).putIfAbsent(to, () => {}).add((
        kind: kind,
        outgoing: true,
      ));
      (_ties[to] ??= {}).putIfAbsent(from, () => {}).add((
        kind: kind,
        outgoing: false,
      ));
    }

    for (final item in _items.values) {
      final at = NodeRef.item(item.id);
      final project = item.projectId;
      if (project != null && _projects.containsKey(project)) {
        tie(at, NodeRef.project(project), TieKind.project);
      }
      final requester = livePerson(item.requesterId);
      if (requester != null) {
        tie(at, NodeRef.person(requester), TieKind.requester);
      }
      final waitingOn = livePerson(item.waitingOnId);
      if (waitingOn != null) {
        tie(at, NodeRef.person(waitingOn), TieKind.waitingOn);
      }
      for (final named in mentions[item.id] ?? const <String>{}) {
        final person = livePerson(named);
        if (person != null) tie(at, NodeRef.person(person), TieKind.mention);
      }
    }
    for (final project in _projects.values) {
      final parent = project.parentId;
      if (parent != null && _projects.containsKey(parent)) {
        tie(
          NodeRef.project(project.id),
          NodeRef.project(parent),
          TieKind.parentProject,
        );
      }
    }
    for (final link in links) {
      if (_items.containsKey(link.from) && _items.containsKey(link.to)) {
        tie(NodeRef.item(link.from), NodeRef.item(link.to), TieKind.link);
      }
    }
  }

  final _items = <String, Item>{};
  final _projects = <String, Project>{};
  final _people = <String, Person>{};
  final _ties = <NodeRef, Map<NodeRef, Set<Tie>>>{};

  Item? item(String id) => _items[id];
  Project? project(String id) => _projects[id];
  Person? person(String id) => _people[id];

  /// Whether [node] is live: an item outside the trash, a live project or
  /// a person who was not merged away.
  bool contains(NodeRef node) => switch (node.kind) {
    NodeKind.item => _items.containsKey(node.id),
    NodeKind.project => _projects.containsKey(node.id),
    NodeKind.person => _people.containsKey(node.id),
  };

  /// The nodes tied to [node], with the lines, in the order of [graphOf].
  List<Neighbour> neighboursOf(NodeRef node) {
    final tied = _ties[node] ?? const {};
    final list = [
      for (final MapEntry(:key, :value) in tied.entries)
        Neighbour(key, Set.unmodifiable(value)),
    ];
    list.sort(_order);
    return list;
  }

  /// `[[…]]` links first, then people and projects, then the rest; open
  /// before done; the most recently touched first (DD-018 point 15).
  int _order(Neighbour a, Neighbour b) {
    int group(Neighbour n) => n.ties.any((t) => t.kind == TieKind.link)
        ? 0
        : n.node.kind == NodeKind.item
        ? 2
        : 1;
    var c = group(a).compareTo(group(b));
    if (c != 0) return c;
    // Projects before people within a group.
    c = a.node.kind.index.compareTo(b.node.kind.index);
    if (c != 0) return c;
    c = (_isOpen(a.node) ? 0 : 1).compareTo(_isOpen(b.node) ? 0 : 1);
    if (c != 0) return c;
    final ta = _touched(a.node), tb = _touched(b.node);
    if (ta != null && tb != null) {
      c = tb.compareTo(ta);
      if (c != 0) return c;
    }
    c = _name(a.node).compareTo(_name(b.node));
    return c != 0 ? c : a.node.id.compareTo(b.node.id);
  }

  bool _isOpen(NodeRef node) => switch (node.kind) {
    NodeKind.item => isOpen(_items[node.id]!.status),
    NodeKind.project => _projects[node.id]!.archivedAt == null,
    NodeKind.person => true,
  };

  DateTime? _touched(NodeRef node) {
    if (node.kind != NodeKind.item) return null;
    final item = _items[node.id]!;
    return item.lastTouch ?? item.capturedAt;
  }

  String _name(NodeRef node) => switch (node.kind) {
    NodeKind.item => '',
    NodeKind.project => nameKey(_projects[node.id]!.name),
    NodeKind.person => nameKey(_people[node.id]!.name),
  };

  /// The graph around [focus], one or two steps deep (DD-018 point 15).
  /// Empty when the focus is no longer live.
  ConnectionGraph graphOf(NodeRef focus, {required bool twoSteps}) {
    if (!contains(focus)) {
      return ConnectionGraph._(
        focus,
        twoSteps,
        const [],
        const [],
        const [],
        const {},
      );
    }
    final direct = neighboursOf(focus);
    final limit = maxDirectNodes(twoSteps: twoSteps);
    final shown = direct.length > limit ? direct.sublist(0, limit - 1) : direct;
    if (!twoSteps) {
      return ConnectionGraph._(focus, false, direct, shown, const [], const {});
    }

    // Never on the second step: the focus and every direct node, shown or
    // behind "+n meer".
    final taken = {focus, for (final n in direct) n.node};
    final candidates = [
      for (final d in shown)
        [
          for (final n in neighboursOf(d.node))
            if (!taken.contains(n.node)) n,
        ],
    ];
    // Round by round, so with many direct nodes each gets its first one
    // before any gets a second.
    final placed = <NodeRef, SecondNode>{};
    final counts = List.filled(shown.length, 0);
    for (var round = 0; round < maxSecondPerNode; round++) {
      for (var i = 0; i < shown.length; i++) {
        if (placed.length >= maxSecondNodes) break;
        for (final n in candidates[i]) {
          if (counts[i] > round) break;
          if (placed.containsKey(n.node)) continue;
          placed[n.node] = SecondNode(n.node, shown[i].node, n.ties);
          counts[i]++;
          break;
        }
      }
    }
    // A node already drawn under another direct node gets a line to this
    // one too; what is not drawn anywhere counts as "+n" on the node.
    final hidden = <NodeRef, int>{};
    for (var i = 0; i < shown.length; i++) {
      var notDrawn = 0;
      for (final n in candidates[i]) {
        final drawn = placed[n.node];
        if (drawn == null) {
          notDrawn++;
        } else if (drawn.parent != shown[i].node) {
          drawn._via.add(shown[i].node);
        }
      }
      if (notDrawn > 0) hidden[shown[i].node] = notDrawn;
    }
    // In the order of their direct node, so the layout keeps them together.
    final second = [
      for (final d in shown)
        for (final s in placed.values)
          if (s.parent == d.node) s,
    ];
    return ConnectionGraph._(focus, true, direct, shown, second, hidden);
  }
}

/// A node tied to another, with every line between the two.
class Neighbour {
  const Neighbour(this.node, this.ties);

  final NodeRef node;
  final Set<Tie> ties;
}

/// A node on the second step: [parent] is the direct node it is drawn
/// next to; [via] every direct node it is tied to, [parent] first.
class SecondNode {
  SecondNode(this.node, this.parent, this.ties) : _via = [parent];

  final NodeRef node;
  final NodeRef parent;

  /// The lines to [parent].
  final Set<Tie> ties;
  final List<NodeRef> _via;

  List<NodeRef> get via => List.unmodifiable(_via);
}

/// The graph around one focus (REQ-059, DD-018 point 15).
class ConnectionGraph {
  const ConnectionGraph._(
    this.focus,
    this.twoSteps,
    this.direct,
    this.shownDirect,
    this.second,
    this._hidden,
  );

  final NodeRef focus;
  final bool twoSteps;

  /// Every direct node, in order; the list behind "+n meer" shows them all.
  final List<Neighbour> direct;

  /// The second-step nodes drawn, grouped by their direct node.
  final List<SecondNode> second;

  final Map<NodeRef, int> _hidden;

  /// The direct nodes drawn: all, or as many as fit next to "+n meer".
  final List<Neighbour> shownDirect;

  /// The direct nodes behind "+n meer"; 0 when all are drawn.
  int get hiddenDirect => direct.length - shownDirect.length;

  /// The second-step nodes of [node] that are not drawn: its "+n".
  int hiddenBehind(NodeRef node) => _hidden[node] ?? 0;

  /// The second-step nodes drawn next to [node].
  List<SecondNode> secondOf(NodeRef node) => [
    for (final s in second)
      if (s.parent == node) s,
  ];
}
