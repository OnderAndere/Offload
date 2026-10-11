import 'package:flutter_test/flutter_test.dart';

import '../../tool/bump_version.dart';

/// The version name says how far the app is: `0.<milestone>.<tasks>` until v1
/// (REQ-060, DD-008).
void main() {
  group('bumpVersion', () {
    test('a task raises the last number', () {
      expect(bumpVersion('0.2.9', 'task'), '0.2.10');
    });

    test('a milestone raises the middle number and resets the last', () {
      expect(bumpVersion('0.2.11', 'milestone'), '0.3.0');
    });

    test('only 0.M.y: v1 and later are up to the PO', () {
      expect(() => bumpVersion('1.0.0', 'task'), throwsFormatException);
      expect(() => bumpVersion('0.2', 'task'), throwsFormatException);
      expect(() => bumpVersion('0.2.x', 'task'), throwsFormatException);
      expect(() => bumpVersion('0.2.9-dev', 'task'), throwsFormatException);
    });

    test('rejects an unknown kind', () {
      expect(() => bumpVersion('0.2.9', 'major'), throwsArgumentError);
    });
  });

  group('rewritePubspec', () {
    const pubspec =
        'name: offload\n'
        'description: "x"\n'
        'version: 0.2.9+1\n'
        '\n'
        'environment:\n'
        '  sdk: ^3.12.2\n';

    test('changes only the version name and keeps the build number', () {
      final result = rewritePubspec(pubspec, (v) => bumpVersion(v, 'task'));
      expect(result.from, '0.2.9');
      expect(result.to, '0.2.10');
      expect(result.text, pubspec.replaceFirst('0.2.9+1', '0.2.10+1'));
    });

    test('accepts a version without a build number', () {
      final result = rewritePubspec(
        'version: 0.2.9\n',
        (v) => bumpVersion(v, 'milestone'),
      );
      expect(result.text, 'version: 0.3.0\n');
    });

    test('fails without a version line', () {
      expect(
        () => rewritePubspec('name: offload\n', (v) => v),
        throwsFormatException,
      );
    });

    test('does not touch a version key of a dependency', () {
      const text = 'version: 0.2.9+1\ndeps:\n  version: 1.0.0\n';
      final result = rewritePubspec(text, (v) => bumpVersion(v, 'task'));
      expect(result.text, 'version: 0.2.10+1\ndeps:\n  version: 1.0.0\n');
    });
  });

  group('rewriteChangelog', () {
    final date = DateTime(2026, 9, 29, 21, 30);
    const changelog =
        '# Changelog\n'
        '\n'
        '## [Unreleased]\n'
        '\n'
        '### Fixed\n'
        '\n'
        '- Undo messages go away again.\n'
        '\n'
        '## [0.2.9] – 2026-09-28\n'
        '\n'
        '### Added\n'
        '\n'
        '- Triage.\n';

    test('releases [Unreleased] under a new empty [Unreleased]', () {
      final result = rewriteChangelog(changelog, '0.2.10', date);
      expect(result.empty, isFalse);
      expect(
        result.text,
        '# Changelog\n'
        '\n'
        '## [Unreleased]\n'
        '\n'
        '## [0.2.10] – 2026-09-29\n'
        '\n'
        '### Fixed\n'
        '\n'
        '- Undo messages go away again.\n'
        '\n'
        '## [0.2.9] – 2026-09-28\n'
        '\n'
        '### Added\n'
        '\n'
        '- Triage.\n',
      );
    });

    test('says when [Unreleased] has no entries', () {
      const text =
          '## [Unreleased]\n'
          '\n'
          '### Added\n'
          '\n'
          '## [0.2.9] – 2026-09-28\n'
          '\n'
          '- Triage.\n';
      expect(rewriteChangelog(text, '0.2.10', date).empty, isTrue);
    });

    test('an entry at the end of the file counts', () {
      const text = '## [Unreleased]\n\n### Added\n\n- First.\n';
      expect(rewriteChangelog(text, '0.2.9', date).empty, isFalse);
    });

    test('pads month and day', () {
      final text = rewriteChangelog(
        '## [Unreleased]\n',
        '0.1.1',
        DateTime(2026, 1, 5),
      ).text;
      expect(text, '## [Unreleased]\n\n## [0.1.1] – 2026-01-05\n');
    });

    test('fails without [Unreleased]', () {
      expect(
        () => rewriteChangelog('# Changelog\n', '0.2.10', date),
        throwsFormatException,
      );
    });

    test('never releases a version twice', () {
      expect(
        () => rewriteChangelog(changelog, '0.2.9', date),
        throwsFormatException,
      );
    });
  });
}
