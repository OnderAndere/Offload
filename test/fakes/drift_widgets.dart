import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// [testWidgets] for screens that watch live Drift queries.
///
/// When a watched query loses its last listener, Drift closes it with a
/// timer. That timer runs in the test's fake time, so the test must unmount
/// the widget tree and let the timer fire before it ends. Otherwise
/// flutter_test reports a pending timer, and closing the database in a
/// tear-down then waits forever, which `--timeout` does not catch. This
/// wrapper does that clean-up, also when the test body fails.
void testDriftWidgets(
  String description,
  WidgetTesterCallback callback, {
  TestVariant<Object?> variant = const DefaultTestVariant(),
}) {
  testWidgets(description, (tester) async {
    try {
      await callback(tester);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    }
  }, variant: variant);
}
