import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:offload/domain/app/build_info.dart';

import '../../tool/build_release.dart';

/// The release script numbers builds from git and writes the build info that
/// Settings shows (REQ-060).
void main() {
  group('versionName', () {
    test('takes the name without the build number', () {
      expect(versionName('name: offload\nversion: 0.1.0+1\n'), '0.1.0');
    });

    test('accepts a version without a build number', () {
      expect(versionName('version: 1.2.3\n'), '1.2.3');
    });

    test('is null without a version line', () {
      expect(versionName('name: offload\n'), isNull);
    });
  });

  group('buildNumber', () {
    test('reads the output of git rev-list --count', () {
      expect(buildNumber('54\n'), 54);
    });

    test('fits the Windows version resource', () {
      expect(buildNumber('$maxBuildNumber'), 65535);
      expect(() => buildNumber('65536'), throwsFormatException);
    });

    test('rejects zero and anything that is not a number', () {
      expect(() => buildNumber('0'), throwsFormatException);
      expect(() => buildNumber(''), throwsFormatException);
      expect(
        () => buildNumber('fatal: not a git repository'),
        throwsFormatException,
      );
    });
  });

  test('the build info is what BuildInfo reads', () {
    final info = buildInfo(
      version: '0.1.0',
      buildNumber: 54,
      builtAt: DateTime.utc(2026, 9, 28, 9, 5, 7, 123),
    );
    expect(info[BuildInfo.buildNumberKey], '54');
    expect(info[BuildInfo.builtAtKey], '2026-09-28T09:05:07Z');
    final parsed = BuildInfo.parse(
      version: info[BuildInfo.versionKey]!,
      buildNumber: info[BuildInfo.buildNumberKey]!,
      builtAt: info[BuildInfo.builtAtKey]!,
    );
    expect(parsed?.version, '0.1.0');
    expect(parsed?.buildNumber, '54');
    expect(parsed?.builtAt, DateTime.utc(2026, 9, 28, 9, 5, 7));
  });

  test('a local build moment is written in UTC', () {
    final local = DateTime(2026, 9, 28, 11, 5, 7);
    final info = buildInfo(version: '0.1.0', buildNumber: 1, builtAt: local);
    expect(
      DateTime.parse(info[BuildInfo.builtAtKey]!),
      DateTime.fromMillisecondsSinceEpoch(
        local.millisecondsSinceEpoch,
        isUtc: true,
      ),
    );
  });

  test('flutter builds a release with the number and the build info', () {
    expect(flutterBuildArgs('apk', 54), [
      'build',
      'apk',
      '--release',
      '--build-number=54',
      '--dart-define-from-file=build/build_info.json',
    ]);
  });

  test('debug leftovers are found, so a Windows release never ships them', () {
    final root = Directory.systemTemp.createTempSync('offload_leftovers');
    addTearDown(() => root.deleteSync(recursive: true));
    expect(debugLeftoversIn(root.path), isEmpty);
    final blob = File(
      '${root.path}${Platform.pathSeparator}$windowsReleaseDir'
      '/data/flutter_assets/kernel_blob.bin',
    )..createSync(recursive: true);
    expect(debugLeftoversIn(root.path), [
      '$windowsReleaseDir/data/flutter_assets/kernel_blob.bin',
    ]);
    blob.deleteSync();
    expect(debugLeftoversIn(root.path), isEmpty);
  });

  group('the manual belongs to the build (DD-020)', () {
    test('only a marker holding the current state counts', () {
      expect(docsCurrent('abc123\r\n', 'abc123'), isTrue);
      expect(docsCurrent('abc123', 'def456'), isFalse);
      expect(docsCurrent(null, 'abc123'), isFalse);
      expect(docsCurrent('  \n', ''), isFalse);
    });

    test('the code state leaves out what the docs-writer writes', () {
      expect(docsStateAddArgs(), [
        'add',
        '-A',
        '--',
        '.',
        ':!docs/user-manual',
        ':!docs/features.md',
        ':!CHANGELOG.md',
      ]);
    });

    test('the same paths as Get-DocsState, which records the marker', () {
      final common = File('.claude/hooks/common.ps1').readAsStringSync();
      final docsState = RegExp(
        r'function Get-DocsState \{(.*?)\n\}',
        dotAll: true,
      ).firstMatch(common)![1]!;
      final excluded = RegExp(
        r"':!([^']+)'",
      ).allMatches(docsState).map((m) => m[1]).toList();
      expect(excluded, docsOutputs);
    });
  });

  group('release copy (--copy)', () {
    final sep = Platform.pathSeparator;
    late Directory temp;
    setUp(() => temp = Directory.systemTemp.createTempSync('offload_copy'));
    tearDown(() => temp.deleteSync(recursive: true));

    test('a folder per build, named after version and build number', () {
      expect(
        releaseCopyPath('root', 'apk', '0.1.0', 68),
        'root${sep}0.1.0+68${sep}Offload-0.1.0+68.apk',
      );
      expect(
        releaseCopyPath('root', 'windows', '0.1.0', 68),
        'root${sep}0.1.0+68${sep}Offload-0.1.0+68-windows',
      );
    });

    test('copies the APK and never overwrites a copy', () {
      final apk = File('${temp.path}${sep}app.apk')
        ..writeAsBytesSync([1, 2, 3]);
      final to = releaseCopyPath(temp.path, 'apk', '0.1.0', 7);
      copyRelease('apk', apk.path, to);
      expect(File(to).readAsBytesSync(), [1, 2, 3]);
      expect(() => copyRelease('apk', apk.path, to), throwsStateError);
    });

    test('copies the whole Windows folder, subfolders included', () {
      final release = Directory('${temp.path}${sep}Release')..createSync();
      File('${release.path}${sep}offload.exe').writeAsStringSync('exe');
      File('${release.path}${sep}data${sep}app.so')
        ..createSync(recursive: true)
        ..writeAsStringSync('so');
      final to = releaseCopyPath(temp.path, 'windows', '0.1.0', 7);
      copyRelease('windows', release.path, to);
      expect(File('$to${sep}offload.exe').readAsStringSync(), 'exe');
      expect(File('$to${sep}data${sep}app.so').readAsStringSync(), 'so');
      expect(() => copyRelease('windows', release.path, to), throwsStateError);
    });

    test('leaves other files in the target directory alone', () {
      final photo = File('${temp.path}${sep}photo.jpg')..writeAsStringSync('x');
      final apk = File('${temp.path}${sep}app.apk')..writeAsBytesSync([9]);
      copyRelease('apk', apk.path, releaseCopyPath(temp.path, 'apk', '1.0', 1));
      expect(photo.readAsStringSync(), 'x');
    });

    test('refuses when a .partial is in the way', () {
      final release = Directory('${temp.path}${sep}Release')..createSync();
      File('${release.path}${sep}offload.exe').writeAsStringSync('exe');
      final to = releaseCopyPath(temp.path, 'windows', '0.1.0', 8);
      // A file where the copy wants its temporary folder makes it fail.
      File('$to.partial')
        ..createSync(recursive: true)
        ..writeAsStringSync('in the way');
      expect(() => copyRelease('windows', release.path, to), throwsStateError);
      expect(Directory(to).existsSync(), isFalse);
    });

    test('a copy that fails halfway removes what it wrote', () {
      final missing = '${temp.path}${sep}missing';
      for (final target in ['windows', 'apk']) {
        final to = releaseCopyPath(temp.path, target, '0.1.0', 9);
        expect(
          () => copyRelease(target, missing, to),
          throwsA(isA<FileSystemException>()),
        );
        expect(FileSystemEntity.typeSync(to), FileSystemEntityType.notFound);
        expect(
          FileSystemEntity.typeSync('$to.partial'),
          FileSystemEntityType.notFound,
        );
      }
    });
  });
}
