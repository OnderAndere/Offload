import 'package:flutter_test/flutter_test.dart';
import 'package:offload/domain/projects/project.dart';
import 'package:offload/domain/projects/project_tree.dart';

/// The rules between projects (DD-018 point 6).
void main() {
  final archived = DateTime.utc(2026, 9, 1);
  final tree = ProjectTree([
    const Project(id: 'renovatie', name: 'Renovatie'),
    const Project(id: 'garden', name: 'Moestuin', parentId: 'renovatie'),
    const Project(id: 'team', name: 'Teamoverleg'),
    Project(id: 'beurs', name: 'Beurs', archivedAt: archived),
    Project(
      id: 'oud',
      name: 'Oud',
      parentId: 'renovatie',
      archivedAt: archived,
    ),
  ]);

  Matcher refused(ProjectProblem problem) => throwsA(
    isA<ProjectException>().having((e) => e.problem, 'problem', problem),
  );

  group('names', () {
    test('are trimmed and must not be empty', () {
      expect(tree.checkedName('  Nieuw  ', null), 'Nieuw');
      expect(
        () => tree.checkedName('   ', null),
        refused(ProjectProblem.emptyName),
      );
    });

    test('are unique per parent, ignoring case (Unicode)', () {
      expect(
        () => tree.checkedName('renovatie', null),
        refused(ProjectProblem.nameTaken),
      );
      expect(
        () => tree.checkedName('MOESTUIN', 'renovatie'),
        refused(ProjectProblem.nameTaken),
      );
      // The same name under another parent, or at another level, is free.
      expect(tree.checkedName('Moestuin', null), 'Moestuin');
      expect(tree.checkedName('Renovatie', 'renovatie'), 'Renovatie');
    });

    test('a renamed project may keep its own name', () {
      expect(
        tree.checkedName('RENOVATIE', null, exceptId: 'renovatie'),
        'RENOVATIE',
      );
    });

    test('an archived project leaves its name free', () {
      expect(tree.checkedName('Beurs', null), 'Beurs');
      expect(tree.checkedName('Oud', 'renovatie'), 'Oud');
    });

    test('a clash that arises by itself gets a number', () {
      expect(tree.freeName('Renovatie', null), 'Renovatie (2)');
      expect(
        tree
            .withProject(const Project(id: 'r2', name: 'Renovatie (2)'))
            .freeName('Renovatie', null),
        'Renovatie (3)',
      );
      expect(tree.freeName('Nieuw', null), 'Nieuw');
      expect(
        tree.freeName('Renovatie', null, exceptId: 'renovatie'),
        'Renovatie',
      );
    });
  });

  group('two levels', () {
    test('a parent must be a top-level project in use', () {
      tree.checkParent(null);
      tree.checkParent('renovatie');
      expect(() => tree.checkParent('garden'), refused(ProjectProblem.tooDeep));
      expect(
        () => tree.checkParent('beurs'),
        refused(ProjectProblem.notAvailable),
      );
      expect(
        () => tree.checkParent('gone'),
        refused(ProjectProblem.notAvailable),
      );
    });

    test('a project with sub-projects stays at the top level', () {
      expect(
        () => tree.checkMove('renovatie', 'team'),
        refused(ProjectProblem.tooDeep),
      );
      tree.checkMove('team', 'renovatie');
      tree.checkMove('garden', null);
    });

    test('nothing goes under itself', () {
      final lonely = ProjectTree([const Project(id: 'a', name: 'A')]);
      expect(() => lonely.checkMove('a', 'a'), refused(ProjectProblem.tooDeep));
    });

    test('an archived project cannot move', () {
      expect(
        () => tree.checkMove('beurs', null),
        refused(ProjectProblem.notAvailable),
      );
    });
  });

  test('children include archived sub-projects', () {
    expect(
      tree.childrenOf('renovatie').map((p) => p.id),
      unorderedEquals(['garden', 'oud']),
    );
    expect(tree.without('garden').childrenOf('renovatie').map((p) => p.id), [
      'oud',
    ]);
  });
}
