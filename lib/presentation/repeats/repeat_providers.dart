import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repeats/repeat.dart';
import '../items/item_providers.dart';

/// The rhythm and first time of every live item with a repeat word
/// (REQ-061, DD-004 point 14), by item id.
final repeatsProvider = StreamProvider.autoDispose<Map<String, ItemRepeat>>(
  (ref) => ref.watch(itemRepositoryProvider).watchRepeats(),
);
