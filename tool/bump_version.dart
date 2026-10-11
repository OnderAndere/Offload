// Raises the version name of Offload (REQ-060, DD-008) in the commit that
// finishes a task.
//
// Usage:
//   dart run tool/bump_version.dart task        # 0.M.y -> 0.M.(y+1)
//   dart run tool/bump_version.dart milestone   # 0.M.y -> 0.(M+1).0
//
// Until v1 the name is 0.<milestone in progress>.<tasks finished in it>. The
// commit that finishes the last task of a milestone runs `milestone` instead
// of `task`. Fixes do not raise the name; `1.0.0` is set by hand, with the PO.
//
// Steps:
// 1. Rewrites only the version name in pubspec.yaml; the build number after
//    `+` stays (release builds take it from git, see build_release.dart).
// 2. Turns `## [Unreleased]` in CHANGELOG.md into `## [<version>] – <date>`
//    with a fresh empty `## [Unreleased]` above it. Warns when [Unreleased]
//    has no entries, but goes on.
// Both files are computed before either is written. A dirty tree is normal:
// the script runs before the commit.
import 'dart:io';

const pubspecPath = 'pubspec.yaml';
const changelogPath = 'CHANGELOG.md';

const unreleasedHeading = '## [Unreleased]';

final _versionLine = RegExp(
  r'^version:[ \t]*(\S+?)(\+\S+)?[ \t]*$',
  multiLine: true,
);

/// [version] raised by one [kind] step: `task` raises the last number,
/// `milestone` raises the middle one and resets the last to 0.
///
/// Throws a [FormatException] for anything but `0.M.y`: after v1 the scheme
/// is up to the PO.
String bumpVersion(String version, String kind) {
  final match = RegExp(r'^0\.(\d+)\.(\d+)$').firstMatch(version);
  if (match == null) {
    throw FormatException('version must be 0.M.y', version);
  }
  final milestone = int.parse(match[1]!);
  final tasks = int.parse(match[2]!);
  return switch (kind) {
    'task' => '0.$milestone.${tasks + 1}',
    'milestone' => '0.${milestone + 1}.0',
    _ => throw ArgumentError.value(kind, 'kind', 'must be task or milestone'),
  };
}

/// The version name in [pubspec] and the text with that name replaced by
/// [bump] applied to it; the build number after `+` is kept.
///
/// Throws a [FormatException] when there is no `version:` line.
({String from, String to, String text}) rewritePubspec(
  String pubspec,
  String Function(String version) bump,
) {
  final match = _versionLine.firstMatch(pubspec);
  if (match == null) throw const FormatException('no "version:" line');
  final from = match[1]!;
  final to = bump(from);
  final line = 'version: $to${match[2] ?? ''}';
  return (
    from: from,
    to: to,
    text: pubspec.replaceRange(match.start, match.end, line),
  );
}

/// [changelog] with its [unreleasedHeading] section turned into a release of
/// [version] on [date], under a new empty [unreleasedHeading]. `empty` says
/// whether the released section had no entries.
///
/// Throws a [FormatException] when there is no [unreleasedHeading] or
/// [version] was released already.
({String text, bool empty}) rewriteChangelog(
  String changelog,
  String version,
  DateTime date,
) {
  final lines = changelog.split('\n');
  final at = lines.indexWhere((l) => l.trimRight() == unreleasedHeading);
  if (at < 0) throw const FormatException('no "$unreleasedHeading" heading');
  if (lines.any((l) => l.startsWith('## [$version]'))) {
    throw FormatException('version already in the changelog', version);
  }
  final next = lines.indexWhere((l) => l.startsWith('## '), at + 1);
  final section = lines.sublist(at + 1, next < 0 ? lines.length : next);
  final empty = !section.any((l) => RegExp(r'^\s*[-*] ').hasMatch(l));
  lines.replaceRange(at, at + 1, [
    unreleasedHeading,
    '',
    '## [$version] – ${isoDate(date)}',
  ]);
  return (text: lines.join('\n'), empty: empty);
}

/// [date] as YYYY-MM-DD.
String isoDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

void main(List<String> args) {
  if (args.length != 1 || !{'task', 'milestone'}.contains(args.single)) {
    stderr.writeln('usage: dart run tool/bump_version.dart task|milestone');
    exit(64);
  }
  final kind = args.single;
  final pubspecFile = File(pubspecPath);
  final changelogFile = File(changelogPath);

  final ({String from, String to, String text}) pubspec;
  final ({String text, bool empty}) changelog;
  try {
    pubspec = rewritePubspec(
      pubspecFile.readAsStringSync(),
      (v) => bumpVersion(v, kind),
    );
    changelog = rewriteChangelog(
      changelogFile.readAsStringSync(),
      pubspec.to,
      DateTime.now(),
    );
  } on FormatException catch (e) {
    _fail('${e.message}${e.source == null ? '' : ', got "${e.source}"'}');
  } on FileSystemException catch (e) {
    _fail('${e.path}: ${e.message}');
  }

  if (changelog.empty) {
    stderr.writeln(
      'warning: [Unreleased] in $changelogPath has no entries; '
      '[${pubspec.to}] is released empty',
    );
  }
  pubspecFile.writeAsStringSync(pubspec.text);
  changelogFile.writeAsStringSync(changelog.text);
  stdout.writeln('version ${pubspec.from} -> ${pubspec.to}');
}

Never _fail(String message) {
  stderr.writeln('error: $message');
  exit(1);
}
