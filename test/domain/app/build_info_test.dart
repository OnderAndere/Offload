import 'package:flutter_test/flutter_test.dart';
import 'package:offload/domain/app/build_info.dart';

void main() {
  test('reads version, build number and build moment (REQ-060)', () {
    final info = BuildInfo.parse(
      version: '0.1.0',
      buildNumber: '7',
      builtAt: '2026-09-27T14:30:05Z',
    )!;

    expect(info.version, '0.1.0');
    expect(info.buildNumber, '7');
    expect(info.builtAt, DateTime.utc(2026, 9, 27, 14, 30, 5));
    expect(info.builtAt.isUtc, isTrue);
  });

  test('missing or invalid values mean a development build', () {
    BuildInfo? parse(String v, String n, String t) =>
        BuildInfo.parse(version: v, buildNumber: n, builtAt: t);

    expect(parse('', '7', '2026-09-27T14:30:05Z'), isNull);
    expect(parse('0.1.0', '', '2026-09-27T14:30:05Z'), isNull);
    expect(parse('0.1.0', '7', ''), isNull);
    expect(parse('0.1.0', '7', 'yesterday'), isNull);
    // A moment without time zone is ambiguous: refused.
    expect(parse('0.1.0', '7', '2026-09-27T14:30:05'), isNull);
  });

  test('a build without defines, like this test run, has no info', () {
    expect(BuildInfo.fromEnvironment(), isNull);
  });
}
