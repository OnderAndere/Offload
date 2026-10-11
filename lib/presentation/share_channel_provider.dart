import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../platform/share/platform_share_channel.dart';
import '../platform/share/share_channel.dart';

/// Sending text and files out of the app (DD-014): shared by the item's
/// share preview, the backup and the export.
final shareChannelProvider = Provider<ShareChannel>(
  (ref) => createPlatformShareChannel(),
);
