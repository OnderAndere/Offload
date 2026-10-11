import 'package:drift/drift.dart';

import '../../domain/repeats/repeat.dart';
import '../../domain/tokens/token_processing.dart';
import '../../domain/tokens/token_types.dart';
import '../database/app_database.dart';

/// Reading the records of completed times and the stored repeat token
/// (REQ-061, DD-018 point 18); shared by the token processor and the item
/// repository, so both work out the same date.
extension RepeatReads on AppDatabase {
  /// The live records of item [itemId].
  Future<List<RepeatCompletion>> liveCompletions(String itemId) async {
    final rows = await (select(
      itemCompletions,
    )..where((c) => c.itemId.equals(itemId) & c.deletedAt.isNull())).get();
    return [for (final row in rows) completionOf(row)];
  }

  /// What the stored repeat token of item [itemId] says, or null when its
  /// text has none (or it is not processed yet).
  Future<ItemRepeat?> storedRepeat(String itemId) async {
    final rows =
        await (select(tokens)..where(
              (t) =>
                  t.itemId.equals(itemId) &
                  t.tokenType.equals(const RepeatTokenType().id) &
                  t.resolvedValue.isNotNull(),
            ))
            .get();
    for (final row in rows) {
      final repeat = ItemRepeat.decode(row.resolvedValue);
      if (repeat != null) return repeat;
    }
    return null;
  }
}

/// The domain value of a stored record.
RepeatCompletion completionOf(ItemCompletion row) => RepeatCompletion(
  occurrenceOn: storedToDateOnly(row.occurrenceOn),
  completedOn: storedToDateOnly(row.completedOn),
);
