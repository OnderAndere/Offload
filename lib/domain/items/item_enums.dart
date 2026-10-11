/// Enumerations of the item model (SPEC.md section 7, DD-004).
///
/// The enum names are stored as text in the database and in exports, so
/// renaming a value is a data migration, not a refactoring.
library;

/// Life cycle of an item: inbox -> active -> waiting -> scheduled -> done ->
/// archived (DD-004).
enum ItemStatus { inbox, active, waiting, scheduled, done, archived }

/// Optional classification (REQ-018). No type (null) means "not classified
/// yet". A thought is an idea (SPEC Q20): there is no separate type.
enum ItemType { task, request, idea, note }

/// Channel through which an item was captured (DD-010).
enum ItemSource { app, widget, share, hotkey, tray, voice }

/// Priority from `*hoog`, `*2`, `*laag` in the text (REQ-050, DD-004 point
/// 11). All three are stored: an item with `*2` has [normal], one without
/// a priority token none (PO decision 02-10-2026: normal gets a chip too).
enum ItemPriority { high, normal, low }
