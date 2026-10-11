import 'package:flutter_test/flutter_test.dart';
import 'package:offload/domain/settings/prefix_bar_mode.dart';

/// The prefix bar setting (REQ-034).
void main() {
  test('reads back every stored mode', () {
    for (final mode in PrefixBarMode.values) {
      expect(PrefixBarMode.parse(mode.name), mode);
    }
  });

  test('nothing stored or an unknown value: always visible', () {
    expect(PrefixBarMode.parse(null), PrefixBarMode.always);
    expect(PrefixBarMode.parse('sometimes'), PrefixBarMode.always);
  });
}
