import 'package:flutter_test/flutter_test.dart';
import 'package:offload/domain/connections/connection_graph.dart';
import 'package:offload/domain/ids/uuid_v7.dart';
import 'package:offload/domain/items/item.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/domain/people/person.dart';
import 'package:offload/domain/projects/project.dart';
import 'package:offload/domain/time/local_date.dart';

/// The graph of Connections (T10.14, REQ-059, DD-018 point 15).
void main() {
  final now = DateTime.utc(2026, 10, 4, 12);
  var n = 0;

  /// An item touched [touchedDaysAgo] days before now; its id says when it
  /// was captured.
  Item item(
    String text, {
    int touchedDaysAgo = 0,
    ItemStatus status = ItemStatus.active,
    String? project,
    String? requester,
    String? waitingOn,
    DateTime? dueAt,
  }) {
    final at = now.subtract(Duration(days: 30, milliseconds: n++));
    return Item(
      id: UuidV7Generator(now: () => at.millisecondsSinceEpoch).next(),
      rawText: text,
      status: status,
      source: ItemSource.app,
      type: ItemType.task,
      projectId: project,
      requesterId: requester,
      waitingOnId: waitingOn,
      dueAt: dueAt,
      changedAt: now.subtract(Duration(days: touchedDaysAgo)),
    );
  }

  const garden = Project(id: 'garden', name: 'Tuin');
  const henhouse = Project(id: 'henhouse', name: 'Kippen', parentId: 'garden');
  const sanne = Person(id: 'sanne', name: 'Sanne');
  const joris = Person(id: 'joris', name: 'Joris');

  List<NodeRef> nodes(Iterable<Neighbour> list) => [
    for (final n in list) n.node,
  ];

  group('lines', () {
    test('a link ties two items, seen from either side', () {
      final a = item('Kippenhok bouwen');
      final b = item('Gaas kopen');
      final data = ConnectionData(
        items: [a, b],
        projects: const [],
        people: const [],
        links: [(from: a.id, to: b.id)],
      );
      final fromA = data.graphOf(NodeRef.item(a.id), twoSteps: false);
      expect(nodes(fromA.direct), [NodeRef.item(b.id)]);
      expect(fromA.direct.single.ties, {(kind: TieKind.link, outgoing: true)});
      final fromB = data.graphOf(NodeRef.item(b.id), twoSteps: false);
      expect(fromB.direct.single.ties, {(kind: TieKind.link, outgoing: false)});
    });

    test('an item ties to its project and its people', () {
      final a = item(
        'Kippenhok bouwen met Sanne',
        project: 'garden',
        requester: 'joris',
        waitingOn: 'sanne',
      );
      final data = ConnectionData(
        items: [a],
        projects: const [garden],
        people: const [sanne, joris],
        mentions: {
          a.id: {'sanne'},
        },
      );
      final graph = data.graphOf(NodeRef.item(a.id), twoSteps: false);
      expect(nodes(graph.direct), [
        const NodeRef.project('garden'),
        const NodeRef.person('joris'),
        const NodeRef.person('sanne'),
      ]);
      expect(graph.direct.last.ties, {
        (kind: TieKind.waitingOn, outgoing: true),
        (kind: TieKind.mention, outgoing: true),
      });
      final ofSanne = data.graphOf(
        const NodeRef.person('sanne'),
        twoSteps: false,
      );
      expect(nodes(ofSanne.direct), [NodeRef.item(a.id)]);
      expect(ofSanne.direct.single.ties.every((t) => !t.outgoing), isTrue);
    });

    test('a sub-project ties to its parent', () {
      final data = ConnectionData(
        items: const [],
        projects: const [garden, henhouse],
        people: const [],
      );
      final graph = data.graphOf(
        const NodeRef.project('garden'),
        twoSteps: false,
      );
      expect(nodes(graph.direct), [const NodeRef.project('henhouse')]);
      expect(graph.direct.single.ties, {
        (kind: TieKind.parentProject, outgoing: false),
      });
    });

    test('a merged person shows as the one merged into', () {
      final a = item('Bellen', requester: 'old');
      final data = ConnectionData(
        items: [a],
        projects: const [],
        people: const [sanne],
        mergedInto: const {'old': 'sanne'},
      );
      final graph = data.graphOf(NodeRef.item(a.id), twoSteps: false);
      expect(nodes(graph.direct), [const NodeRef.person('sanne')]);
    });

    test('what is not live is left out', () {
      final a = item('Kippenhok bouwen', project: 'trashed', requester: 'x');
      final data = ConnectionData(
        items: [a],
        projects: const [],
        people: const [],
        links: [(from: a.id, to: 'trashed-item')],
        mentions: {
          a.id: {'gone'},
        },
      );
      final graph = data.graphOf(NodeRef.item(a.id), twoSteps: false);
      expect(graph.direct, isEmpty);
      expect(
        data
            .graphOf(const NodeRef.item('trashed-item'), twoSteps: false)
            .direct,
        isEmpty,
      );
    });

    test('done and archived items stay', () {
      final a = item('Kippenhok bouwen');
      final done = item('Hout ophalen', status: ItemStatus.done);
      final archived = item('Oud plan', status: ItemStatus.archived);
      final data = ConnectionData(
        items: [a, done, archived],
        projects: const [],
        people: const [],
        links: [(from: a.id, to: done.id), (from: archived.id, to: a.id)],
      );
      expect(
        data.graphOf(NodeRef.item(a.id), twoSteps: false).direct,
        hasLength(2),
      );
    });
  });

  group('order and limits', () {
    test('links first, then projects and people, then the most recent', () {
      final focus = item('Tuin', project: 'garden');
      final old = item('Oud', project: 'garden', touchedDaysAgo: 9);
      final recent = item('Recent', project: 'garden', touchedDaysAgo: 1);
      final done = item('Af', project: 'garden', status: ItemStatus.done);
      final data = ConnectionData(
        items: [focus, old, recent, done],
        projects: const [garden, henhouse],
        people: const [],
      );
      final graph = data.graphOf(
        const NodeRef.project('garden'),
        twoSteps: false,
      );
      expect(nodes(graph.direct), [
        const NodeRef.project('henhouse'),
        NodeRef.item(focus.id),
        NodeRef.item(recent.id),
        NodeRef.item(old.id),
        NodeRef.item(done.id),
      ]);

      final linked = item('Gekoppeld', touchedDaysAgo: 20);
      final withLink = ConnectionData(
        items: [focus, linked],
        projects: const [garden],
        people: const [sanne],
        links: [(from: linked.id, to: focus.id)],
        mentions: {
          focus.id: {'sanne'},
        },
      );
      expect(
        nodes(withLink.graphOf(NodeRef.item(focus.id), twoSteps: false).direct),
        [
          NodeRef.item(linked.id),
          const NodeRef.project('garden'),
          const NodeRef.person('sanne'),
        ],
      );
    });

    test('one step draws 12, or 11 and "+n meer"', () {
      List<Item> many(int count) => [
        for (var i = 0; i < count; i++) item('Item $i', requester: 'sanne'),
      ];
      ConnectionGraph of(int count) => ConnectionData(
        items: many(count),
        projects: const [],
        people: const [sanne],
      ).graphOf(const NodeRef.person('sanne'), twoSteps: false);
      expect(of(12).shownDirect, hasLength(12));
      expect(of(12).hiddenDirect, 0);
      expect(of(13).shownDirect, hasLength(11));
      expect(of(13).hiddenDirect, 2);
      expect(of(13).direct, hasLength(13));
    });

    test('two steps draw 8 direct nodes, or 7 and "+n meer"', () {
      final items = [
        for (var i = 0; i < 9; i++) item('Item $i', requester: 'sanne'),
      ];
      final graph = ConnectionData(
        items: items,
        projects: const [],
        people: const [sanne],
      ).graphOf(const NodeRef.person('sanne'), twoSteps: true);
      expect(graph.shownDirect, hasLength(7));
      expect(graph.hiddenDirect, 2);
    });

    test('second step: at most 2 per node and 8 in all, round by round', () {
      // Sanne asked eight items; each item is in a project of its own with
      // three more items.
      final projects = [
        for (var p = 0; p < 8; p++) Project(id: 'p$p', name: 'Project $p'),
      ];
      final asked = [
        for (var p = 0; p < 8; p++)
          item('Gevraagd $p', requester: 'sanne', project: 'p$p'),
      ];
      final others = [
        for (var p = 0; p < 8; p++)
          for (var k = 0; k < 3; k++) item('Ander $p.$k', project: 'p$p'),
      ];
      final graph = ConnectionData(
        items: [...asked, ...others],
        projects: projects,
        people: const [sanne],
      ).graphOf(const NodeRef.person('sanne'), twoSteps: true);
      expect(graph.shownDirect, hasLength(8));
      expect(graph.second, hasLength(maxSecondNodes));
      // Each direct item gets its project first: one each, none a second.
      for (final d in graph.shownDirect) {
        final of = graph.secondOf(d.node);
        expect(of, hasLength(1));
        expect(of.single.node.kind, NodeKind.project);
        // Behind the project: nothing more of this item (the project is
        // its only other tie).
        expect(graph.hiddenBehind(d.node), 0);
      }
    });

    test('second step: never more than 8, every node its first', () {
      // Sanne asked eight items; each has a project and a person of its
      // own: two candidates each, sixteen in all.
      final projects = [
        for (var p = 0; p < 8; p++) Project(id: 'p$p', name: 'Project $p'),
      ];
      final helpers = [
        for (var p = 0; p < 8; p++) Person(id: 'h$p', name: 'Helper $p'),
      ];
      final asked = [
        for (var p = 0; p < 8; p++)
          item(
            'Gevraagd $p',
            requester: 'sanne',
            project: 'p$p',
            waitingOn: 'h$p',
          ),
      ];
      final graph = ConnectionData(
        items: asked,
        projects: projects,
        people: [sanne, ...helpers],
      ).graphOf(const NodeRef.person('sanne'), twoSteps: true);
      expect(graph.shownDirect, hasLength(8));
      expect(graph.second, hasLength(maxSecondNodes));
      for (final d in graph.shownDirect) {
        expect(graph.secondOf(d.node), hasLength(1));
        expect(graph.hiddenBehind(d.node), 1);
      }
    });

    test('a node behind two direct nodes is drawn once, with both', () {
      final focus = item('Kippenhok bouwen', project: 'garden');
      final gaas = item('Gaas kopen', waitingOn: 'joris');
      final data = ConnectionData(
        items: [focus, gaas],
        projects: const [garden],
        people: const [joris],
        links: [(from: focus.id, to: gaas.id)],
        mentions: {
          focus.id: {'joris'},
        },
      );
      // Joris is direct (named), so not on the second step.
      final graph = data.graphOf(NodeRef.item(focus.id), twoSteps: true);
      expect(
        graph.second.map((s) => s.node),
        isNot(contains(const NodeRef.person('joris'))),
      );

      // Two linked items both wait on Joris: he is drawn once, next to the
      // first, with a line to both.
      final paal = item('Paal zetten', waitingOn: 'joris', touchedDaysAgo: 3);
      final two = ConnectionData(
        items: [focus, gaas, paal],
        projects: const [],
        people: const [joris],
        links: [(from: focus.id, to: gaas.id), (from: focus.id, to: paal.id)],
      ).graphOf(NodeRef.item(focus.id), twoSteps: true);
      final joined = two.second.where(
        (s) => s.node == const NodeRef.person('joris'),
      );
      expect(joined, hasLength(1));
      expect(joined.single.parent, NodeRef.item(gaas.id));
      expect(joined.single.via, [NodeRef.item(gaas.id), NodeRef.item(paal.id)]);
      expect(two.hiddenBehind(NodeRef.item(paal.id)), 0);
    });

    test('"+n" counts the second-step nodes not drawn', () {
      final focus = item('Kippenhok bouwen', project: 'garden');
      final more = [
        for (var i = 0; i < 5; i++) item('Tuin $i', project: 'garden'),
      ];
      final graph = ConnectionData(
        items: [focus, ...more],
        projects: const [garden],
        people: const [],
      ).graphOf(NodeRef.item(focus.id), twoSteps: true);
      expect(graph.secondOf(const NodeRef.project('garden')), hasLength(2));
      expect(graph.hiddenBehind(const NodeRef.project('garden')), 3);
    });

    test('one step has no second step', () {
      final focus = item('Kippenhok bouwen', project: 'garden');
      final other = item('Tuin 1', project: 'garden');
      final graph = ConnectionData(
        items: [focus, other],
        projects: const [garden],
        people: const [],
      ).graphOf(NodeRef.item(focus.id), twoSteps: false);
      expect(graph.second, isEmpty);
      expect(graph.hiddenBehind(const NodeRef.project('garden')), 0);
    });

    test('a focus no longer live gives an empty graph', () {
      final graph = ConnectionData(
        items: const [],
        projects: const [],
        people: const [],
      ).graphOf(const NodeRef.item('gone'), twoSteps: true);
      expect(graph.direct, isEmpty);
      expect(graph.second, isEmpty);
    });
  });

  group('urgency', () {
    final today = LocalDate(2026, 10, 4);
    test('today and overdue only for open items', () {
      expect(
        urgencyOf(item('a', dueAt: DateTime.utc(2026, 10, 4)), today),
        Urgency.today,
      );
      expect(
        urgencyOf(item('b', dueAt: DateTime.utc(2026, 10, 1)), today),
        Urgency.overdue,
      );
      expect(
        urgencyOf(item('c', dueAt: DateTime.utc(2026, 10, 9)), today),
        Urgency.none,
      );
      expect(
        urgencyOf(
          item('d', dueAt: DateTime.utc(2026, 10, 1), status: ItemStatus.done),
          today,
        ),
        Urgency.none,
      );
      expect(urgencyOf(item('e'), today), Urgency.none);
    });
  });
}
