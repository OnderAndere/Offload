import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../platform/app_directory/app_directory.dart';
import '../platform/app_directory/platform_app_directory.dart';

/// Where Offload keeps its files on this device.
final appDirectoryProvider = Provider<AppDirectory>(
  (ref) => createPlatformAppDirectory(),
);
