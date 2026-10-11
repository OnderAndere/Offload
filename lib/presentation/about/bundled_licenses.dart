import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../domain/app/bundled_licenses.dart';

/// The [bundledLicenses] for [LicenseRegistry] (REQ-062); read only when
/// the licences are asked for, so nothing is loaded at start (REQ-001).
Stream<LicenseEntry> bundledLicenseEntries() async* {
  for (final license in bundledLicenses) {
    yield LicenseEntryWithLineBreaks(
      license.packages,
      await rootBundle.loadString(license.asset),
    );
  }
}
