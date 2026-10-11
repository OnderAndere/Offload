// Runs an integration test with `flutter drive`, for measurements in profile
// mode (`flutter drive --profile`); `flutter test` runs debug builds only.
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();
