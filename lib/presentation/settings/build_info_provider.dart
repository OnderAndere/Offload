import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/app/build_info.dart';

/// The build of this app, or null for a development build (REQ-060).
final buildInfoProvider = Provider<BuildInfo?>(
  (ref) => BuildInfo.fromEnvironment(),
);
