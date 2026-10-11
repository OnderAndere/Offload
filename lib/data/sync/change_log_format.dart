/// Format of change-log entries (REQ-037, DD-003).
///
/// The change log is also the exchange format for manual sync (DD-013), so
/// the payload is versioned and self-contained:
/// - `insert`: every column of the new row except the managed columns;
/// - `update`: only the columns whose stored value changed, with their new
///   values;
/// - `delete`: the tombstone, `{"deleted_at": ...}`;
/// - `restore`: the tombstone cleared, `{"deleted_at": null}` (T2.3).
///
/// Keys are SQL column names; values are the SQL values as stored: text,
/// integers and null. Timestamps are ISO-8601 text in UTC, enums their name
/// (the database stores both as text). The entity id and the HLC are fields
/// of the log entry itself, never of the payload.
library;

import 'dart:convert';

/// Version of the payload format written by this build.
const changeLogFormatVersion = 1;

/// Columns every synchronisable table has; the writer and the replayer
/// manage them, so callers and payloads never set them directly.
const idColumn = 'id';
const hlcColumn = 'hlc';
const deletedAtColumn = 'deleted_at';
const managedColumns = {idColumn, hlcColumn, deletedAtColumn};

/// Encodes a payload of SQL values as JSON.
String encodePayload(Map<String, Object?> values) {
  for (final MapEntry(:key, :value) in values.entries) {
    if (value != null && value is! String && value is! int) {
      throw ArgumentError.value(value, key, 'not a text or integer SQL value');
    }
  }
  return jsonEncode(values);
}

/// Decodes a payload written by [encodePayload].
Map<String, Object?> decodePayload(String payload) {
  final decoded = jsonDecode(payload);
  if (decoded is! Map<String, Object?>) {
    throw FormatException('Change-log payload is not a JSON object', payload);
  }
  for (final MapEntry(:key, :value) in decoded.entries) {
    if (value != null && value is! String && value is! int) {
      throw FormatException('Unsupported value for column $key', payload);
    }
  }
  return decoded;
}
