// Builds a release of Offload for one target, with the build info Settings
// shows (REQ-060) and an automatic build number.
//
// Usage, one target per call (never both in one command, see CLAUDE.md):
//   dart run tool/build_release.dart apk [--copy]
//   dart run tool/build_release.dart windows [--copy]
//
// Steps:
// 1. Build number = number of commits on HEAD (`git rev-list --count HEAD`):
//    always rising, so Android accepts the APK as an update, and traceable to
//    a commit. A dirty working tree gets the number of HEAD, with a warning.
//    A shallow clone is refused: its count is too low.
// 2. Writes build/build_info.json with the version name from pubspec.yaml
//    (raised by tool/bump_version.dart, never by hand before v1), the build
//    number and the moment of the build in UTC. The keys match
//    BuildInfo in lib/domain/app/build_info.dart.
// 3. For the APK: stops the Gradle daemon first, because a daemon that lost
//    its console makes the build hang (CLAUDE.md). Needs JAVA_HOME.
// 4. Runs `flutter build <target> --release --build-number=<n>
//    --dart-define-from-file=build/build_info.json`.
// 5. Fails unless the output file was written by this build: exit code 0
//    alone does not prove that.
// 6. With --copy: copies the release to a folder per build under the
//    directory in the environment variable OFFLOAD_RELEASE_DIR (a local
//    setting, never in the repository): `<version>+<n>/Offload-<version>+<n>.apk`
//    or `<version>+<n>/Offload-<version>+<n>-windows/`. Only from a clean
//    tree, so the build number names a commit; an existing copy is never
//    overwritten. Checked before building, so a refused copy costs no build.
// 7. The user manual belongs to the build (DD-020, REQ-065): the docs-writer
//    runs before a release for use and records the code state it documented
//    in .claude/.docs-marker. With --copy the build is refused when that is
//    not the current state; without --copy (a test build) it only warns.
import 'dart:convert';
import 'dart:io';

import 'package:offload/domain/app/build_info.dart';

/// Largest build number the Windows version resource can hold: each of its
/// four fields is 16 bits (FILEVERSION in windows/runner/Runner.rc).
const maxBuildNumber = 65535;

const buildInfoPath = 'build/build_info.json';

/// Output file per target, relative to the project root, that every build
/// rewrites. For Windows that is the compiled Dart code, which holds the build
/// info: the exe is only relinked when the runner or the build number changes.
const releaseOutputs = {
  'apk': 'build/app/outputs/flutter-apk/app-release.apk',
  'windows': 'build/windows/x64/runner/Release/data/app.so',
};

/// The environment variable with the directory for release copies.
const releaseDirVariable = 'OFFLOAD_RELEASE_DIR';

final _separator = Platform.pathSeparator;

/// Where the copy of [target] goes under [root]: a folder per build, with
/// the APK file or the whole Windows release folder in it.
String releaseCopyPath(String root, String target, String version, int n) {
  final name = 'Offload-$version+$n';
  final folder = '$root$_separator$version+$n';
  return target == 'apk'
      ? '$folder$_separator$name.apk'
      : '$folder$_separator$name-windows';
}

/// The directory whose contents make up the Windows release.
const windowsReleaseDir = 'build/windows/x64/runner/Release';

/// Files of a debug build that a Windows release must not hold. A debug run
/// (`flutter run`, `flutter test integration_test -d windows`) leaves its
/// JIT code `kernel_blob.bin` (about 50 MB) in `build/flutter_assets`, and
/// the release build copies that folder into its `data/flutter_assets`
/// without removing it: harmless (the release runs its AOT code), but the
/// release grew from 37 to 86 MB (found in 0.4.0+209, 06-10-2026).
const debugLeftovers = [
  'build/flutter_assets/kernel_blob.bin',
  '$windowsReleaseDir/data/flutter_assets/kernel_blob.bin',
];

/// Where the docs-writer records the code state it documented
/// (`.claude/hooks/mark-docs.ps1`; local, not in the repository).
const docsMarkerPath = '.claude/.docs-marker';

/// The paths the docs-writer writes, left out of the code state so its own
/// output does not make the manual look outdated. Must equal the exclusions
/// in `Get-DocsState` (`.claude/hooks/common.ps1`); a test compares them.
const docsOutputs = ['docs/user-manual', 'docs/features.md', 'CHANGELOG.md'];

/// The `git add` arguments that stage the code state without [docsOutputs].
List<String> docsStateAddArgs() => [
  'add',
  '-A',
  '--',
  '.',
  for (final path in docsOutputs) ':!$path',
];

/// Whether [marker] (the content of [docsMarkerPath], or null when missing)
/// records [state], the current code state.
bool docsCurrent(String? marker, String state) =>
    marker != null && marker.trim().isNotEmpty && marker.trim() == state.trim();

/// Those of [debugLeftovers] that exist under [root] (the project root).
List<String> debugLeftoversIn(String root) => [
  for (final path in debugLeftovers)
    if (File('$root$_separator$path').existsSync()) path,
];

/// Copies the release of [target] from [source] (the APK file, or the
/// Windows release folder) to [destination] and checks that every byte
/// arrived. The copy is made under a temporary `.partial` name and only
/// renamed to [destination] when complete, so a failed copy never looks
/// like a finished one; a failed copy removes what it wrote. Throws a
/// [StateError] when [destination] exists already or the copy differs; the
/// PO's own files next to it are never touched.
void copyRelease(String target, String source, String destination) {
  final partial = '$destination.partial';
  for (final path in [destination, partial]) {
    if (FileSystemEntity.typeSync(path) != FileSystemEntityType.notFound) {
      throw StateError('$path exists already; not overwritten');
    }
  }
  Directory(File(destination).parent.path).createSync(recursive: true);
  try {
    if (target == 'apk') {
      File(source).copySync(partial);
      _sameBytes(source, partial);
      File(partial).renameSync(destination);
      return;
    }
    final from = Directory(source);
    Directory(partial).createSync();
    for (final entity in from.listSync(recursive: true)) {
      final to = '$partial${entity.path.substring(from.path.length)}';
      if (entity is Directory) {
        Directory(to).createSync(recursive: true);
      } else if (entity is File) {
        Directory(File(to).parent.path).createSync(recursive: true);
        entity.copySync(to);
        _sameBytes(entity.path, to);
      }
    }
    Directory(partial).renameSync(destination);
  } catch (_) {
    final left = FileSystemEntity.typeSync(partial);
    if (left == FileSystemEntityType.file) File(partial).deleteSync();
    if (left == FileSystemEntityType.directory) {
      Directory(partial).deleteSync(recursive: true);
    }
    rethrow;
  }
}

void _sameBytes(String a, String b) {
  final left = File(a).readAsBytesSync();
  final right = File(b).readAsBytesSync();
  var same = left.length == right.length;
  for (var i = 0; same && i < left.length; i++) {
    same = left[i] == right[i];
  }
  if (!same) throw StateError('copy of $a differs');
}

/// The version name from the `version:` line of [pubspec], without the build
/// number (that comes from git), or null when there is no such line.
String? versionName(String pubspec) => RegExp(
  r'^version:\s*([^\s+]+)(\+\S+)?\s*$',
  multiLine: true,
).firstMatch(pubspec)?[1];

/// The build number from the output of `git rev-list --count HEAD`.
///
/// Throws a [FormatException] when it is not a number from 1 to
/// [maxBuildNumber].
int buildNumber(String revListCount) {
  final n = int.tryParse(revListCount.trim());
  if (n == null || n < 1 || n > maxBuildNumber) {
    throw FormatException(
      'build number must be 1..$maxBuildNumber',
      revListCount.trim(),
    );
  }
  return n;
}

/// The content of build/build_info.json.
Map<String, String> buildInfo({
  required String version,
  required int buildNumber,
  required DateTime builtAt,
}) => {
  BuildInfo.versionKey: version,
  BuildInfo.buildNumberKey: '$buildNumber',
  // Whole seconds, e.g. 2026-09-27T14:30:05Z.
  BuildInfo.builtAtKey:
      '${builtAt.toUtc().toIso8601String().substring(0, 19)}Z',
};

/// The arguments for `flutter` that build [target].
List<String> flutterBuildArgs(String target, int buildNumber) => [
  'build',
  target,
  '--release',
  '--build-number=$buildNumber',
  '--dart-define-from-file=$buildInfoPath',
];

Future<void> main(List<String> args) async {
  final copy = args.contains('--copy');
  final rest = [...args]..remove('--copy');
  if (rest.length != 1 || !releaseOutputs.containsKey(rest.single)) {
    stderr.writeln(
      'usage: dart run tool/build_release.dart '
      '<${releaseOutputs.keys.join('|')}> [--copy]',
    );
    exit(64);
  }
  final target = rest.single;

  final version = versionName(File('pubspec.yaml').readAsStringSync());
  if (version == null) _fail('pubspec.yaml has no "version:" line');

  if (_git(['rev-parse', '--is-shallow-repository']).trim() == 'true') {
    _fail('shallow clone: the commit count is too low for a build number');
  }
  final int number;
  try {
    number = buildNumber(_git(['rev-list', '--count', 'HEAD']));
  } on FormatException catch (e) {
    _fail('${e.message}, got "${e.source}"');
  }
  final dirty = _git(['status', '--porcelain']).trim().isNotEmpty;
  if (dirty) {
    stderr.writeln(
      'warning: uncommitted changes; build number $number is that of HEAD. '
      'Build a release copy from a clean tree.',
    );
  }
  String? copyTo;
  if (copy) {
    final root = Platform.environment[releaseDirVariable];
    if (root == null || !Directory(root).existsSync()) {
      _fail('--copy needs $releaseDirVariable set to an existing directory');
    }
    if (dirty) _fail('--copy only from a clean tree (commit first)');
    copyTo = releaseCopyPath(root, target, version, number);
    for (final path in [copyTo, '$copyTo.partial']) {
      if (FileSystemEntity.typeSync(path) != FileSystemEntityType.notFound) {
        _fail('$path exists already; not overwritten');
      }
    }
  }
  final marker = File(docsMarkerPath);
  if (!docsCurrent(
    marker.existsSync() ? marker.readAsStringSync() : null,
    _docsState(),
  )) {
    const advice =
        'the user manual was not written for this code state: run the '
        'docs-writer, commit its changes, then build (DD-020)';
    if (copy) _fail(advice);
    stderr.writeln('warning: $advice. Fine for a test build.');
  }

  final started = DateTime.now();
  final info = buildInfo(
    version: version,
    buildNumber: number,
    builtAt: started,
  );
  File(buildInfoPath)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(const JsonEncoder.withIndent('  ').convert(info));
  stdout.writeln('wrote $buildInfoPath: $info');

  if (target == 'apk') await _stopGradleDaemon();
  if (target == 'windows') {
    for (final path in debugLeftoversIn('.')) {
      File(path).deleteSync();
      stdout.writeln('removed debug leftover $path');
    }
  }

  final code = await _run('flutter', flutterBuildArgs(target, number));
  if (code != 0) _fail('flutter build $target failed (exit code $code)');

  final output = File(releaseOutputs[target]!);
  // File times can have a coarser resolution than DateTime.now().
  final notBefore = started.subtract(const Duration(seconds: 2));
  if (!output.existsSync() || output.lastModifiedSync().isBefore(notBefore)) {
    _fail('${output.path} was not written by this build');
  }
  stdout.writeln('built ${output.path}: $version+$number');
  if (target == 'windows') {
    final left = debugLeftoversIn('.');
    if (left.isNotEmpty) {
      _fail('debug files in the release: ${left.join(', ')}');
    }
  }

  if (copyTo != null) {
    final source = target == 'apk' ? releaseOutputs['apk']! : windowsReleaseDir;
    try {
      copyRelease(target, source, copyTo);
    } on Object catch (e) {
      _fail('copy failed: $e');
    }
    stdout.writeln('copied to $copyTo');
  }
}

String _git(List<String> args, {Map<String, String>? environment}) {
  final result = Process.runSync('git', args, environment: environment);
  if (result.exitCode != 0) _fail('git ${args.join(' ')}: ${result.stderr}');
  return result.stdout as String;
}

/// The code state as `Get-DocsState` computes it: the tree of every file
/// that is not ignored, without [docsOutputs], staged in a temporary index so
/// the real index is untouched. A fresh folder per run, so an index left by a
/// run that stopped on a git error is never reused.
String _docsState() {
  final folder = Directory.systemTemp.createTempSync('offload-docs-index-');
  final env = {'GIT_INDEX_FILE': '${folder.path}${_separator}index'};
  try {
    _git(docsStateAddArgs(), environment: env);
    return _git(const ['write-tree'], environment: env).trim();
  } finally {
    folder.deleteSync(recursive: true);
  }
}

Future<void> _stopGradleDaemon() async {
  if (Platform.environment['JAVA_HOME'] == null) {
    _fail('set JAVA_HOME to a Java 17+ (see CLAUDE.md) to build the APK');
  }
  final gradlew = Platform.isWindows
      ? r'android\gradlew.bat'
      : 'android/gradlew';
  final code = await _run(gradlew, ['-p', 'android', '--stop']);
  if (code != 0) _fail('stopping the Gradle daemon failed (exit code $code)');
}

Future<int> _run(String executable, List<String> args) async {
  stdout.writeln('> $executable ${args.join(' ')}');
  final process = await Process.start(
    executable,
    args,
    // flutter and gradlew are batch files on Windows.
    runInShell: true,
    mode: ProcessStartMode.inheritStdio,
  );
  return process.exitCode;
}

Never _fail(String message) {
  stderr.writeln('error: $message');
  exit(1);
}
