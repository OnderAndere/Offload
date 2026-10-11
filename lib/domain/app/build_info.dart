/// Which build of Offload this is (REQ-060): the version from
/// `pubspec.yaml`, the build number (commits on HEAD) and the moment of the
/// build.
///
/// Set at build time by `tool/build_release.dart` through
/// `--dart-define-from-file=build/build_info.json`; a build without them
/// (development, tests) has no [BuildInfo].
class BuildInfo {
  const BuildInfo({
    required this.version,
    required this.buildNumber,
    required this.builtAt,
  });

  /// Keys of the build defines; also written by `tool/build_release.dart`.
  static const versionKey = 'OFFLOAD_VERSION';
  static const buildNumberKey = 'OFFLOAD_BUILD_NUMBER';
  static const builtAtKey = 'OFFLOAD_BUILD_TIME';

  /// Version name, e.g. `0.1.0`.
  final String version;

  /// Build number, e.g. `1`.
  final String buildNumber;

  /// Moment of the build, in UTC.
  final DateTime builtAt;

  /// The info this build was made with, or null for a development build.
  static BuildInfo? fromEnvironment() => parse(
    version: const String.fromEnvironment(versionKey),
    buildNumber: const String.fromEnvironment(buildNumberKey),
    builtAt: const String.fromEnvironment(builtAtKey),
  );

  /// Null unless all three values are present and [builtAt] is an ISO-8601
  /// moment in UTC.
  static BuildInfo? parse({
    required String version,
    required String buildNumber,
    required String builtAt,
  }) {
    if (version.isEmpty || buildNumber.isEmpty) return null;
    final moment = DateTime.tryParse(builtAt);
    if (moment == null || !moment.isUtc) return null;
    return BuildInfo(
      version: version,
      buildNumber: buildNumber,
      builtAt: moment,
    );
  }
}
