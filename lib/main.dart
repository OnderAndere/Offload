import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'presentation/about/bundled_licenses.dart';
import 'presentation/app.dart';

void main() {
  // Read only when the licences are asked for: no cost at start (REQ-001).
  LicenseRegistry.addLicense(bundledLicenseEntries);
  runApp(const ProviderScope(child: OffloadApp()));
}
