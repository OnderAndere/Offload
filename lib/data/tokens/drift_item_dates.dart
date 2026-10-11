import 'package:drift/drift.dart';

import '../../domain/time/local_date.dart';
import '../../domain/tokens/stored_token.dart';
import '../../domain/tokens/token_types.dart';
import '../database/app_database.dart';

/// The dates the token processor worked out for the date words in an
/// item's saved text, by word (DD-018 point 1). The item detail shows these
/// for words that were already there, so an existing `!morgen` keeps the
/// date it got when it was typed instead of moving along with today.
Stream<Map<String, LocalDate>> watchStoredDates(AppDatabase db, String itemId) {
  final query = db.select(db.tokens)
    ..where(
      (t) =>
          t.itemId.equals(itemId) &
          t.tokenType.equals(const DateTokenType().id) &
          t.resolvedValue.isNotNull(),
    );
  return query.watch().map(
    (rows) => {
      for (final row in rows)
        row.rawValue: ?parseStoredDate(row.resolvedValue!),
    },
  );
}

/// `yyyy-mm-dd`, as the processor stores a date; null for anything else.
LocalDate? parseStoredDate(String value) {
  final parts = value.split('-');
  if (parts.length != 3) return null;
  final [year, month, day] = [for (final p in parts) int.tryParse(p)];
  if (year == null || month == null || day == null) return null;
  return LocalDate.tryCreate(year, month, day);
}

/// The processed tokens of every live item, by item id: for each the type
/// id and the word, and for a date the date the processor worked out
/// (DD-018 point 2). The inbox rows show chips only for these, so a chip
/// never runs ahead of processing and an old `!morgen` keeps its date.
Stream<Map<String, List<StoredToken>>> watchLiveItemTokens(AppDatabase db) {
  final query = db.select(db.tokens).join([
    innerJoin(db.items, db.items.id.equalsExp(db.tokens.itemId)),
  ])..where(db.items.deletedAt.isNull());
  return query.watch().map((rows) {
    final byItem = <String, List<StoredToken>>{};
    for (final row in rows) {
      final token = row.readTable(db.tokens);
      final resolved = token.resolvedValue;
      byItem.putIfAbsent(token.itemId, () => []).add((
        typeId: token.tokenType,
        word: token.rawValue,
        date: token.tokenType == const DateTokenType().id && resolved != null
            ? parseStoredDate(resolved)
            : null,
      ));
    }
    return byItem;
  });
}
