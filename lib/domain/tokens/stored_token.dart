import '../time/local_date.dart';

/// One processed token of an item, as the token processor stored it
/// (DD-004 point 8): its type id, the word as typed (without prefix) and,
/// for a date, the date worked out when it was typed.
typedef StoredToken = ({String typeId, String word, LocalDate? date});
