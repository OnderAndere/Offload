/// Kind of change recorded in the append-only change log (REQ-008, DD-003).
///
/// Deletions are tombstones (`deleted_at`), never physical deletes; the
/// `delete` operation records that a tombstone was set, and `restore` that
/// it was cleared again ("undo" after the trash, AC REQ-010). The names are
/// stored in the log: add values, never rename them.
enum ChangeOperation { insert, update, delete, restore }
