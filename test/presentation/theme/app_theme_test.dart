import 'package:flutter_test/flutter_test.dart';
import 'package:offload/presentation/theme/app_theme.dart';
import 'package:offload/presentation/theme/design_tokens.dart';

/// The typeface and the licence that comes with it (T10.7 step A, DD-017).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every text style uses IBM Plex Sans', () {
    final theme = offloadTheme();
    final styles = theme.textTheme;
    for (final style in [
      styles.bodyMedium,
      styles.titleLarge,
      styles.labelSmall,
      styles.displayLarge,
    ]) {
      expect(style?.fontFamily, sansFamily);
    }
    expect(theme.useMaterial3, isTrue);
  });

  test('standstill has four classes, each with a text colour', () {
    expect(standstillColors, hasLength(4));
    expect(standstillTextColors, hasLength(standstillColors.length));
  });
}
