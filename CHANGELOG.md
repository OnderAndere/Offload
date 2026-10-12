# Changelog

All notable user-facing changes to Offload are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

## [0.7.0] – 2026-10-12

### Changed

- **Read handwriting**: after reading, a new screen *Review thoughts* shows one field per thought (each line that
  starts with `-`; a line without `-` continues the thought before it), with the people, tags, dates and priority
  it will get, so a misread date or sign shows. Correct a thought, or untick *Include* to skip it; *Save* (on
  Windows also Ctrl+Enter) puts the kept thoughts in the inbox as items of their own, marked as captured via
  handwriting, and *Capture* closes when nothing was typed in it. Nothing is saved before that; going back returns
  to the photo, asking first when you changed something.

### Fixed

- *Read handwriting*: a photo that cannot be opened always gives a message instead of a screen that keeps saying
  "Opening the photo…"; when the model turns out to be missing or damaged, the button in *Capture* goes.

## [0.6.5] – 2026-10-12

### Added

- **Read handwriting from a photo** in *Capture*, once the handwriting model is imported: a new button takes a
  photo (Android) or opens one, and the photo screen lets you drag four corners onto a skewed board or page to
  straighten it, or read the whole photo. Reading takes from tens of seconds to a few minutes and shows its
  progress and a *Stop* button; the screen stays on (Android) or the PC stays awake (Windows). On Android, reading
  pauses while you are outside Offload. After 5 minutes it stops with the advice to close other apps. The text read
  is added to the capture field, to check and save; the photo is never stored.

### Fixed

- *Settings → Models*: when a model cannot be removed (on Windows, a file still in use), a message says so instead
  of nothing happening; when the model files cannot be looked at, the state reads "State unknown" instead of an
  import error, and the screen no longer fails.

## [0.6.4] – 2026-10-11

### Added

- **Settings → Models**: import the model for reading handwriting (Qwen3-VL-2B-Instruct, about 1.6 GB) with the
  system's file window: on Android also from a NAS or cloud app, on Windows also from a network drive. Pick one or
  both files at once; Offload recognises them by their checksum, not by name, copies them into its own storage with
  progress and a *Stop* button, and refuses a wrong or damaged file. It checks the free space first. The screen
  shows the source and licence, removes the model on request, and offers *Accurate / Faster* for reading
  handwriting on this device. Nothing is downloaded, and models never go into a backup.
- *Settings → Storage* shows the imported models as a row of their own.
- Restoring a backup on a device without the handwriting model says to import it again afterwards.

## [0.6.3] – 2026-10-11

### Added

- **Photos on the cards**: an item with photos shows the newest one as a small thumbnail on its card in the
  lists (Inbox, Today, projects, people, the weekly review) and in the search results, with the number when it
  has more. Tap the card to open the item and its photos.

### Changed

- The e-mail example in the Dutch syntax help uses `jan@example.org`, a domain reserved for examples.
- The build number in *Settings* keeps rising after the move to a fresh repository: the first new build is
  +261, above every earlier one, so Android still accepts it as an update.
- Windows: the file properties of `offload.exe` name the licence (GPL-3.0-or-later) instead of "All rights
  reserved".

## [0.6.2] – 2026-10-10

### Added

- **Photos in an item**: *Add photo* in the item detail. On Android you take a photo with the camera app or pick
  one from the gallery, without any permission; on Windows you choose an image file. Offload keeps it small
  (at most 1600 px), upright and without EXIF data or location, encrypted, with a thumbnail (REQ-024, REQ-027).
- The photos show as a row of thumbnails under the note; a tap opens one full screen with zoom. A long press
  (Windows: right click or Del) deletes a photo, after asking; there is no undo.
- A photo that was not in a restored backup shows *Attachment not in this backup*.

### Fixed

- When a restored backup cannot be opened, Offload brings back your data from before the restore, as it already
  did, and now also tells you so after it starts ("Restore did not work").
- Android: when saving a backup or an export fails, the empty file it had created in the place you chose is
  removed; a file you chose to overwrite stays as it was.

## [0.6.1] – 2026-10-10

### Added

- **Backups with attachments**: when this device has attachments, *Make a backup* first asks *With attachments
  (≈ size)*, on by default; they go encrypted into the same single backup file. Restoring such a backup brings
  them back, re-encrypted for this device and checked one by one (REQ-014).
- Making and restoring a large backup shows its progress ("12 MB of 85 MB"); there is no cancel button.
- Before a backup or a restore, Offload checks the free space and says so when there is too little, instead
  of failing halfway; nothing is written then.
- After making a backup, Offload says how many attachments were missing or damaged and are not in it.
- The restore confirmation says how many attachments the backup holds. For a backup without attachments it
  warns that attachments not belonging to the restored items will be gone; this device keeps its own files of
  the restored items.

### Fixed

- Putting the previous data back after a restored backup did not open is now safe if the app stops halfway:
  the next start finishes it.

## [0.6.0] – 2026-10-09

### Added

- **Help** in the app: *Settings → Help* opens the user manual, and a **?** in the title bar of each screen opens
  the part that belongs to that screen; on Windows **F1** does the same. Links between chapters open inside Help,
  Back retraces your path, and an internet address is only shown, never opened (REQ-065).
- The syntax overview of the input signs links to the part of the manual about them (REQ-065).

### Changed

- The user manual is now in English; with Offload in Dutch, Help says so at the top. A Dutch translation follows
  later (REQ-065).
- On *Today* the date moves from the title bar to the top of the page when the bar has no room for it, on a
  narrow screen or with large text, so the title is never cut off (REQ-016).

## [0.5.0] – 2026-10-09

### Added

- **Storage** in Settings: how large the encrypted database is, the temporary files on Android (a shared
  backup or export, removed after a day), and how many items (with those in the trash), projects and people
  Offload holds.

### Fixed

- Settings → *Storage*: a size just under a megabyte reads "1.0 MB" instead of "1000 kB"; temporary files
  that cannot be measured say so instead of the row disappearing.
- The line under *As typed (for Offload)* no longer promises the same item: an item with the same text and
  tokens is made; status, type and notes do not travel.

## [0.4.6] – 2026-10-09

### Added

- Sharing an item (REQ-043): the switch *As typed (for Offload)* shares the text with its @person, #tags,
  ^project, *priority and links as you typed them, with a date word replaced by its fixed date. Shared to
  Offload on another device, it becomes the same item there.

## [0.4.5] – 2026-10-09

### Added

- **Export** (REQ-014): Settings → *Backup and export* → *Export* saves everything you made, outside the
  trash, as one Markdown file (readable, items as you typed them, per project and status, then the people)
  or one JSON file (structured, for other programs). It is not encrypted; the dialog says so every time.
  On Android share it or save it on the device; on Windows *Save as*.

## [0.4.4] – 2026-10-09

### Added

- *Today* (REQ-049): your open *Where was I* notes at the top, newest first; at most three, *+n more* shows
  the rest. A tap opens the item or project with its resume card. Settings → *Today* switches it off on
  this device.

## [0.4.3] – 2026-10-09

### Changed

- *Today* (REQ-050): items with high priority come first within *Overdue* and *Today*; the rest keeps its
  order (oldest deadline first). Normal and low priority do not move.

## [0.4.2] – 2026-10-09

### Added

- Android: *Make a backup* (REQ-014) now asks where the backup goes: *Share…* hands the encrypted backup file to
  another app through the share menu (mail, a chat, cloud storage of your choice), *Save on this device…*
  saves it as before. After sharing, the message says the backup is ready to share; Android does not
  report whether it was really sent. The shared copy is replaced by the next one and removed after a day.

### Fixed

- Opening Offload again after Android had closed it in the background no longer opens the item or screen
  of an earlier reminder tap, Offload bar button or shortcut again; it starts on Today.

## [0.4.1] – 2026-10-06

### Added

- **Offload bar** (REQ-063): a second home-screen widget with *Capture* and *Today*; made wider also
  *Insights*. *Capture* opens the quick input window, as the capture widget does; *Today* and *Insights*
  open Offload there, also when it is already open on another screen. A long press on the app icon offers
  the same three actions. Text you are typing in the app stays.

### Changed

- The capture widget is a compact tile in the middle of its cell instead of filling the whole cell; made
  wider it is a low bar, like the Offload bar.

### Fixed

- A tap on a reminder no longer closes a capture screen with typed text in the app; the text stays.
- *About Offload* lists the licence of the Material icons.
- The Windows release no longer carries a 50 MB file of a debug build (`kernel_blob.bin`), which made
  0.4.0 twice as large; the build script removes it and refuses a release that still has it.

## [0.4.0] – 2026-10-06

### Added

- **Recurring tasks** (REQ-061): put `!dagelijks`, `!wekelijks` or `!maandelijks` in the text (EN
  `!daily`, `!weekly`, `!monthly`; the words of every app language work), or use the button *! repeat*
  in the prefix bar. A date in the text is the first time; without one, the day you typed the word.
  Completing a time (button, swipe, Ctrl+Enter, the weekly review) moves the task to its next date,
  "Done · next time Tue 13 Oct", with Undo; a time left for days is one overdue card, and the next time
  comes after today. Monthly on the 31st falls on the last day of shorter months. The item shows the
  rhythm, "This time: …" and a block *Done* with when each time was done and how late. ⋮ has *Complete
  and repeat…* for a task that does not repeat yet, and *Stop repeating*; removing the word, or *Done*
  or *Archived* in the status chip, stops a series too. Works for a task and for an item without a type;
  a repeating task is never stale in the weekly review, and the day's reminder comes on every date of
  the series.
- **Undo after *Complete* in the item** too, as on Today.

## [0.3.26] – 2026-10-04

### Added

- **Nudge for silent waiting items** (REQ-047): a waiting item without an expected date that nothing has
  happened to for 7 days ("Chase after" in Settings → Reminders, 3 to 21 days) shows on Today in the
  group "Stays silent", with *Received* and *Chased*; *Chased* starts the period again, also from the
  item's commitment block. On the day an item goes silent a notification comes, "Still waiting for
  Petra · silent for 7 days" (or the number of items); the lock screen shows no titles or names. Switch
  it off in Settings → Reminders.

## [0.3.25] – 2026-10-04

### Added

- **Birthdays** (REQ-031): on someone's birthday a notification at the time of the day's reminder,
  "Anna de Vries has a birthday today · turns 46" (or "2 birthdays today" with the names); a tap opens
  the person. The lock screen shows no names. On Today a line per person whose birthday is today. A
  birthday on 29 February comes on 28 February in other years. Switch it off in Settings → Reminders
  → Birthdays.

## [0.3.24] – 2026-10-04

### Added

- **Reminders on Windows** (REQ-020, REQ-021, REQ-022): while Offload runs, also hidden in the system
  tray, the day's reminder and the weekly-review reminder come as a Windows notification, with the
  titles. A click brings Offload to the front with the item, Today or the weekly review. Settings →
  Reminders is now on Windows too. After *Exit*, or after a restart before you open Offload, no
  notification comes; Today shows the items anyway. A reminder missed while the PC slept comes on
  waking up, if it is still the same day.

### Changed

- **Reminders** (Android): a new reminder removes the previous one of its kind that is still shown, so
  yesterday's deadline notification or last week's weekly-review notification no longer piles up.

## [0.3.23] – 2026-10-04

### Added

- **Weekly review reminder** (REQ-022, Android): in Settings → Reminders, off by default. On the day and
  time you choose (Friday 16:00 to start with) a notification "Weekly review due" with how long ago the
  last one was, only while a review is due, the same rule as the line on Today. A tap opens the weekly
  review.

## [0.3.22] – 2026-10-04

### Added

- **Reminders survive a restart** (REQ-020, REQ-021, Android): after a restart of the phone, an
  update of Offload or a change of time zone the planned reminders come back without opening the
  app. Until you open it they show only the count ("2 deadlines today"), not the titles; a reminder
  of today missed while the phone was off comes right after it starts. After *Force stop* they come
  back when you open the app.

### Changed

- **Revisit on**: on a Sunday *Next week* is now the Sunday a week later, not tomorrow's Monday.

## [0.3.21] – 2026-10-04

### Added

- **Revisit on** (NL "Terugzien op", REQ-021): park an item until a day — tomorrow, next week
  (Monday), in a month or a date you choose — from the menu of an item, by choosing *Scheduled* in its
  status, with *Later…* in triage (key 6 on Windows) and with *Later…* in the weekly review's step
  *Stale* (key 3). It leaves the inbox and your lists, its card shows the day it comes back, and every
  choice can be undone. On that day it is back in the inbox and on Today in the group "Back in your
  inbox" until you process it. On Android it is in the day's one reminder notification, with the
  deadlines ("1 deadline · 2 back in your inbox"); the notification channel is now called
  "Reminders". *Not any more* in the item cancels it.

### Changed

- Today shows the new day as soon as the app comes back to the front, not up to a minute later.

## [0.3.20] – 2026-10-04

### Added

- **Deadline reminders** (NL "Herinneringen", REQ-020, Android): on the day of a deadline one
  notification, by default at 09:00: "Deadline today" with its title, or "3 deadlines today" with the
  up to five titles below it; a tap opens the item or Today. The lock screen shows only the count.
  Android asks once for permission, when there is an open item with a deadline today or later (also
  right after updating); without it, deadlines stay on Today. In Settings → Reminders you switch them off or choose the time. A reminder can come up to
  ten minutes late, or later while the phone is in deep sleep. Overdue items are not reminded again.

## [0.3.19] – 2026-10-04

### Added

- **Connections** (NL "Verbanden", REQ-059): a fourth segment in Insights that shows what is linked
  to one item, person or project: its `[[…]]` links in both directions, its project and its people.
  Switch between 1 step and 2 steps (also what those are linked to). Tap a node to make it the focus
  and go back with Back; long press for a preview with *Open*. Choose the focus with *Change*, or
  with *Show connections* in the menu of an item, a person or a project; otherwise it starts from
  the item you opened last. An item due today or overdue is marked orange. The graph can be zoomed
  (pinch; on Windows Ctrl+scroll, Ctrl+plus/minus, Ctrl+0 to fit). On Windows the arrow keys move
  between nodes, Enter focuses, Space previews, and the focus is shown in the right pane.

### Changed

- The segment names in Insights stay on one line; a long name gets a little smaller instead of
  wrapping.

## [0.3.18] – 2026-10-03

### Added

- **Backup** (NL "Back-up", REQ-014, REQ-026): in Settings → Backup, set a passphrase once (at least
  12 characters), make an encrypted backup of everything in one file and save it where you choose,
  and restore one. On the same device restoring asks nothing; from another device it asks for the
  passphrase. Restoring replaces all data on this device after a confirmation; your settings on
  this device stay. A backup is a copy, not a sync.

### Changed

- While a backup is being made, saving waits for it instead of failing.

## [0.3.17] – 2026-10-03

### Added

- **About Offload** (NL "Over Offload", REQ-062): from Settings → About Offload, a screen with what
  the app is for, its version, its licence (GNU GPL 3.0 or later, with the full text) and the
  licences of its components, including the encrypted database library (SQLite3MultipleCiphers)
  and SQLite.

## [0.3.16] – 2026-10-03

### Added

- **Links between items** (REQ-054): type `[[` (or tap **[[ item** in the bar) and choose an item from
  the list; its title goes into your text between double brackets, and the item is linked. The
  link survives renaming: the chip under the text always shows the item's current title, and a tap
  opens it. An item in the trash keeps its link and says "in prullenbak". A `[[…]]` you type
  yourself links when exactly one item has that title; otherwise its chip says "geen item", and in
  the item detail a tap makes it a new inbox item, linked. Remove `[[…]]` from the text and the
  link is gone.
- **Linked from** (NL "Verwijst hiernaar"): below the buttons of an item, the items that link to it.
- **Link** (NL "Koppelen") in the duplicate hint: writes `[[…]]` with the other item into the newer
  one's text.

### Changed

- A word with `@`, `#`, `!`, `^` or `*` now ends before an opening bracket at its end, so `#klus(`
  is the tag "klus".

## [0.3.15] – 2026-10-03

### Added

- **A `^project` that names no project says so** (NL "kas · geen project"), while typing and in the
  item detail, so saving never quietly leaves the item without a project. In the item detail, tap
  the chip to create the project, with the name filled in from the word, and put the item in it.
  With `^parent/name` it becomes a sub-project of that parent. When sub-projects under different
  parents share the name, the chip says "several projects"; choose the path from the list.

### Fixed

- An item with `^project` whose project did not exist yet when you saved it now goes into that
  project at the next start, once the project exists or is back from the archive. Unless you
  chose another project for the item since.

## [0.3.14] – 2026-10-02

### Added

- **"Where was I?"** (NL "Waar was ik?", REQ-049): a button by *Complete* in an item, and under the
  title of a project (Windows: Ctrl+Shift+P). Write down the next step and what you had in mind in
  a few seconds; Enter saves, Shift+Enter is a new line. Closing keeps what you typed.
- **The resume card**: while a note is open, it is at the top of the item or project, with both
  fields and how long ago. *Update* opens it filled in; *Resume* closes it. A note counts as
  touching the item, so it does not show up as stale.

## [0.3.13] – 2026-10-02

### Added

- **Insights** (NL "Inzicht"), the fifth tab (REQ-052; Windows Ctrl+5), with three segments:
  - **Horizon:** the coming six weeks, a lane per project. A dot is something you deliver (a
    deadline), a ring something you wait for (an expected day); orange is overdue or late. Above
    each week a bar with how much you deliver; from 5 items the week is marked "busy". Tap a week
    for its list; an item with a deadline and an expected day that week is one row.
  - **Standstill:** a tile per project, as large as its open items, coloured by how long nothing
    in it was touched (under a week to over six weeks). Below it the three items untouched the
    longest, or the items of the tile you tap, with "Open project".
  - **People:** the balance from the People tab.
- **The weekly review starts with Insights**: the start screen shows five steps; "Continue" goes
  on to the inbox.
- **Settings → Insights → Busy from** (3 to 15 items, 5 by default).
- Windows: Horizon and Standstill side by side over the whole width, also in the review; ← and →
  choose a week or tile, ↑ and ↓ move through the list below, the mouse pointer on a dot or tile
  shows its title.

## [0.3.12] – 2026-10-02

### Changed

- **New typeface: IBM Plex** (REQ-052, DD-017), throughout the app on Android and Windows. It is part of the
  app itself, never downloaded, and includes Cyrillic. Licence: SIL Open Font License 1.1.

## [0.3.11] – 2026-10-02

### Added

- **People shows the balance** (REQ-048): at the top "I still have to deliver: 5 to 3 people"
  and "I am still waiting for: 4 from 2 people"; per person a bar from the middle, orange to the
  left for what you deliver, blue to the right for what you wait for, with the numbers, and the
  age of the oldest open item. From 21 days that age is orange, bold and has a timer icon.
  People with the most open items come first, alphabetical when equal; people with nothing open
  follow, subdued.
- **A person as the preparation for a 1-on-1**: the note right under the name, and in *Requested
  by* and *Waiting for* first what is overdue or late, then the oldest.
- **Settings → People → Old after** (7 to 60 days, 21 by default).

### Changed

- Windows: a person opens in the right pane, next to the balance; an item from the person's
  lists opens as a screen of its own (also with ↑/↓ and Enter). While you search, the right
  pane shows the item you chose; the person comes back when the search field is empty.
- Windows: Escape closes an item opened as a screen of its own, also when its text has no focus.

## [0.3.10] – 2026-10-02

### Added

- **Commitments** in the item detail (REQ-046, REQ-047). An item someone asked for (or a
  request) shows a block "Commitment" with *Asked on* (the day it was captured, or the day you
  pick), *Promised* (the title, or your own short text) and *Due* (the item's deadline; picking a
  day puts `!date` in the text). A waiting item shows whom it waits for and *Expected* (a day of
  its own, or none); past that day the line turns orange with a warning icon and says how late.
  The × next to a value you set puts it back.
- **"Wait for…"** asks, optionally, by when you expect it.
- **Today** has a third group, "Should have come in": waiting items past their expected day,
  the longest late first. A waiting item that is due today or overdue stays in its own group.
  Cards of waiting items show the expected day, or how late it is.

## [0.3.9] – 2026-10-02

### Added

- **Phone numbers and email addresses in your text** (REQ-039). Type `@Jan 06-12345678
  jan@example.org` and the number and address go to Jan's contact details when you save, with
  "2 details added to Jan" and Undo. A Dutch mobile number gets the label Mobile; a number or
  address Jan already has is not added twice (`06-…` and `+31 6 …` count as one). Only what you
  type new is added, never from older items. Names the text no person or several, then nothing is
  added; in the item detail the number is then a chip "Link to a person". While typing, the chip
  shows where it goes: "06-12345678 → Jan".
- **Settings → Country for phone numbers**: for numbers typed without a country code, the
  Netherlands by default. Search finds a number also by its international form (`+316…` finds
  `06-…`).

### Changed

- `*2` (normal priority) now also shows as a chip on cards, "Normal priority", like high and low;
  an item without a priority word has no chip. Items saved with `*2` before get it after the
  update.

## [0.3.8] – 2026-10-02

### Added

- **Project and priority while typing** (REQ-050). `^project` puts the item in a project:
  `^verbouwing`, `^oude-schuur` for "Oude schuur" (case, spaces and dashes do not matter) and
  `^verbouwing/keuken` for a sub-project. After `^` the suggestion list shows the projects; a
  name that does not exist yet can be made right away with "Create project: …". A project you
  choose later in the item detail or in triage wins over the `^` word in the text; removing the
  word keeps the project. `*hoog`/`*1` gives high priority, `*laag`/`*3` low, `*2` normal (EN
  `*high`, `*low`); the priority follows the text. Cards and the item detail show "High priority"
  or "Low priority" as a chip. The prefix bar and the syntax overview have both new signs.
- After this update every item is read once more, so a `^project` or `*hoog` already in older
  texts takes effect; an item you put in a project yourself keeps it.

## [0.3.7] – 2026-10-02

### Added

- **Contact details** on a person: phone numbers and email addresses, several of each, with a
  label (Mobile, Work, Private, Other, or an own label), and the job title and organisation as one
  line under the name. Add them with "+ Phone number" or "+ Email address"; the right keyboard
  opens. A tap on a number opens the dialler (Android; on Windows the number is copied), a tap on
  an address starts a message in the mail app. ⋮ on a detail: copy, change, delete (with undo).
  Search finds a person by number, address, job title or organisation (REQ-038).
- On Windows, on a contact detail: Enter does what a tap does, Delete deletes it, Shift+F10 opens
  its menu.

### Fixed

- Windows: Escape closes a menu that was opened with the keyboard (F10 no longer puts the window
  in menu mode).

## [0.3.6] – 2026-10-02

### Added

- Today has an icon at the top that starts the weekly review; on Windows its tooltip names
  Ctrl+Shift+W. While a review is due, a line on Today says how long ago the last one was
  ("Weekly review · last 9 d ago", or "not done yet") and starts it with a tap. A review counts
  once its end screen is reached (REQ-013).
- Settings: "Due again after", 3 to 28 days (7 by default), for this device.

### Changed

- The ⋮ menu on Today is gone: the weekly review has its own icon there.

### Fixed

- The example for a tag in the syntax help is now a neutral one ("Dakgoot schoonmaken #klussen",
  EN "Clean the gutter #chores").

## [0.3.5] – 2026-10-01

### Added

- **Weekly review**: from the ⋮ menu on Today (Windows: Ctrl+Shift+W). A start screen shows four
  steps with what is there: empty the inbox (process it), go through what you wait for, the
  deadlines (overdue and the next two weeks) and stale items, open items nobody touched for a while.
  A step with nothing to do is skipped. Per item you choose "Still waiting" or "Keep" (it is then no
  longer stale), complete, archive or trash it, with undo; handled cards stay in view with a check
  mark. An end screen says what you did (REQ-013, REQ-051).
- Settings: "Stale after", 1 to 12 weeks (3 by default), for this device.

### Changed

- An open item can now be archived directly, also from the status chip in the item; before, only
  completed items could be archived.

## [0.3.4] – 2026-10-01

### Added

- A person's profile: on their screen, under the name, "Add birthday" opens a small window with
  day, month and, if you know it, the year; the birthday then shows as "3 april", or with the year
  as "3 april 1980 · 46 jaar". Below it a note field for what you want to remember about the person;
  it saves itself, and search finds it (REQ-031).

## [0.3.3] – 2026-10-01

### Added

- Merge two people: in a person's ⋮ menu, "Merge with…" lists everyone else (with a search field);
  after you confirm, all items and nicknames go to the person you chose, who keeps their name, and
  the old name keeps working as a nickname. The message lets you undo it at once. Renaming someone
  to a name that is already taken now offers "Merge with …" (REQ-012).

## [0.3.2] – 2026-10-01

### Added

- **People**, the fourth destination (Windows: Ctrl+4). Everyone you named with `@` or chose while
  processing, alphabetically, with a field to find someone by name or nickname. Per person the
  number of open items they asked for (✋), the open items waiting on them (⏳) and, in orange, how
  many of those are overdue; people with nothing open are shown greyed out. Tap a person to see
  "Requested by", "Waiting for" and "Mentioned in" (items that name them with `@`), each with its
  done items folded. The ⋮ menu renames a person; the old name keeps working as a nickname, so
  `@oldname` in earlier items still points to them. Android Back and, on Windows, Esc go back to
  the list (REQ-012).
- The item shows who asked for it (✋) and who it waits on (⏳) as chips next to status, type and
  project; their menu opens the person, chooses another one or removes them. "Wait for…" now asks
  who, with the people named in the text at the top. Tap a name chip under the text to open that
  person; on Windows the list switches to the person and the item stays open (REQ-012).
- Cards on Today, in the Inbox, in a project and in search results show who asked and who it
  waits on, unless the text already names them. A person in the search results opens that person.

## [0.3.1] – 2026-09-30

### Added

- **Projects**, the third destination (Windows: Ctrl+3). The list starts with "Without project",
  then your projects with their sub-projects below them (two levels at most), each with the number
  of open items and, in orange, how many are overdue; archived projects are folded at the bottom.
  Create a project with + in the top bar. Tap a project to see its sub-projects and its items by
  status (Inbox, Active, Waiting for, Scheduled, Notes; Done folded). The ⋮ menu renames, moves,
  archives (with Undo) or deletes a project; deleting keeps the items, which lose the project, and
  can be undone at once. Android Back and, on Windows, Esc go back to the list (REQ-030).
- Give an item a project: the third chip in the item, next to status and type, and a chip on the
  card while processing (Windows: key P). Search the list, or type a new name to create a project
  on the spot. Cards on Today, in the Inbox and in search results show their project (REQ-030,
  REQ-018).

### Removed

- The temporary switch "Also show processed items" in the Inbox: processed items are now in
  Projects, under their project or "Without project".

## [0.3.0] – 2026-09-30

### Added

- Share an item as text: the share icon at the top of an item opens a preview of the text as it
  will go out. Names lose their `@` (`@Jan` becomes "Jan", as you typed it), dates are written out
  ("vrijdag 2 oktober", with the year only when it is not this year) and tags are left out unless
  you switch on "Include tags". You can edit the text first; that never changes the item, and only
  what is in the preview is sent. Android: "Share" opens the share menu, with the first line as the
  subject. Windows: "Copy" puts it on the clipboard, "Save as…" saves it as a text file where you
  choose (REQ-043).

## [0.2.11] – 2026-09-29

### Added

- Offload now opens on **Today**: everything with a deadline today or earlier that is not done
  or archived, in two parts, "Overdue" and "Today", oldest deadline first, whatever its status
  (the inbox included; the status shows on each card). At the top a line shows how many items wait in your
  inbox: tap it to go to the Inbox, or tap "Process" to sort them card by card and come back to
  Today. With nothing due you see "Nothing for today". Android: swipe a card right to complete it,
  left to move it to the trash, both with "Undo"; undoing a completion puts back the exact status
  it had. Screen readers offer both as actions (REQ-030, AC REQ-010).
- Navigation between **Today** and **Inbox**: on Android a bar at the bottom, on Windows a bar on the
  left with the capture button (+) at the top and Settings at the bottom. The Inbox shows how many
  items are unprocessed. On Android, Back goes from the Inbox to Today. The other destinations
  (Overview, Projects, People) are added once they exist (REQ-030).
- Windows: in a wide window the list and the item sit side by side: click a card (or a search
  result) and it opens on the right, where you can edit it straight away; with nothing chosen the
  right side says "Choose an item". A search field sits above the list; while it has text, the
  results take the place of the list, and Esc empties it. In a narrower window the item opens over
  the list and the bar on the left stays (REQ-030).
- Windows keys, in the list: ↑ and ↓ choose a card, Enter goes to its text, Esc from there back to
  the list, Delete moves the card to the trash, and on Today Ctrl+Enter completes it, both with
  "Undo", after which the next card is chosen. Anywhere, also while typing: Ctrl+1 and Ctrl+2 go to
  Today and Inbox (not during processing, which Esc ends), Ctrl+N opens capture and Ctrl+F the
  search field (REQ-030).

### Fixed

- With TalkBack on, a new message now replaces the one on screen instead of waiting behind it.
  Undo messages stay until you act when TalkBack is on, so after moving two cards to the trash
  the undo for the second one could not be reached; now it shows at once, and the undo of the
  first ends (AC REQ-010, REQ-016).

## [0.2.10] – 2026-09-29

### Added

- Cards now show what kind of item they are: the type is the first chip on the card, with an
  icon and its name (Task, Idea, Request or Note), in the inbox (also with "Also show processed
  items" on) and on the triage card. An item without a type shows no type chip. The type chip
  in an item's detail has the same icon. Screen readers read it as "type: Task" (AC REQ-010,
  REQ-016).

### Changed

- The triage button "Reference" is now called "Note" (Dutch: "Notitie" instead of
  "Referentie"), the same name the item detail uses for that type. It still files the item as
  a note; on Windows it is still key 5 (AC REQ-010).

## [0.2.9] – 2026-09-29

### Added

- Settings now starts with an "About Offload" section showing the installed version and
  build number (e.g. "Version 0.1.0 (build 1)") and when that build was made, in local time
  and the app's language (e.g. "Built on 27 Sep 2026, 14:43"), so you can check which build
  you're running after installing a new one. A development build (not made as a release)
  shows "Development build" instead (REQ-060).
- Dutch and English UI language, with a language picker in Settings
  (System language on top, then the other languages alphabetically by their
  own name: English, Nederlands). The app follows the device language by
  default, trying the device's preferred languages in order and falling
  back to English when none of them is offered (REQ-005, REQ-029). The
  choice is remembered across restarts; if it cannot be stored, a message
  says so and the choice applies until the app restarts.
- The app now opens its encrypted database at start, with a short loading
  indicator. The first start creates the key and the database (REQ-004).
  If the data cannot be opened, an explanation screen is shown instead of
  the app, with a "Try again" button and technical details; it covers a
  missing key, an unreadable key, and a database that cannot be opened.
  Nothing is changed or deleted in any of these cases.
- Offload now opens on the Inbox: captured items, newest first, each
  showing its text (up to three lines) and when it was captured, in the
  active language, with the item count above the list. An empty inbox
  shows "No items yet" (REQ-001).
- A **Capture** button on the inbox opens a one-field capture screen to
  jot down a thought; the text is saved exactly as typed (REQ-001,
  REQ-018). On Windows, Enter saves and Shift+Enter starts a new line; on
  Android, the keyboard's action key saves and the text is a single
  wrapping line (pasted text keeps its line breaks). A checkmark button in
  the title bar also saves once there is some text. After saving, the
  item appears in the inbox immediately; if saving fails, the text stays
  in the field with a message asking to try again.
- Windows: Offload now runs as a single instance. Starting it again while
  it is already open brings the existing window to the front instead of
  opening a second one, restoring it first if it was minimized or hidden
  in the system tray.
- Windows: the global shortcut Win+Shift+B opens the capture screen from
  any program, with the cursor already in the field (REQ-017). After
  saving, or closing the capture screen without saving, the window
  returns to how it was: hidden in the tray, minimized, or behind the
  program that was active before. If the shortcut is already used by
  another program, the inbox says so, with a way to dismiss the message;
  capturing still works from the tray icon or the Capture button. If a
  capture screen is already open when the shortcut is pressed, nothing
  else happens and the text already typed stays.
- Windows: a system tray icon for Offload. Clicking it (or selecting it
  with the keyboard) opens the window; the tray menu offers New item
  (opens the capture screen), Open, and Quit, in Offload's own language
  setting.
- Windows: closing the window now hides Offload to the system tray
  instead of quitting it, so the shortcut keeps working; use Quit in the
  tray menu to close Offload for real. Closing the window during start-up
  or from the start-up error screen still quits Offload.
- The capture screen now recognises special words while you type and shows
  them as chips under the text field (REQ-019): `@Name` for a person,
  `#word` for a tag, and `!word` for a date, showing the resolved date on
  the chip (e.g. `!fri` shows "Fri 2 Oct"). Date words follow the app's
  language, e.g. Dutch `!vandaag`, `!morgen`, `!overmorgen`, weekdays short
  or long (`!mon`…`!sun`, `!monday`…), `!nextweek`, or an explicit date
  (`!12-10` or `!12-10-2026`); a weekday always means the next such day,
  never today. A token only counts at the start of the text, after a
  space, or right after an opening bracket (`(@Name)`, `[#word]`,
  `{!fri}`), so an e-mail address stays plain text and a backslash before
  it (`\@Name`) escapes it; trailing punctuation is not part of the word.
- After saving, Offload now works out the recognised words without making
  you wait (REQ-019): `@Name` links to that person (creating them if
  needed) and `#word` links to that tag (creating it if needed), matching
  names and tags regardless of upper or lower case and script (e.g.
  Cyrillic), and also via a person's existing aliases. The first date in
  the text becomes the item's deadline, but only if it doesn't have one
  yet; a relative date such as `!morgen` counts from the moment you
  captured the item, not from when Offload processes it, so typing it in
  the Android widget yesterday means today. The item's text is always
  kept exactly as typed. Items captured through the Android widget are
  processed the next time Offload fetches them (at start or when you
  return to the app); items captured before this version are processed
  at the next start. Not yet visible: the inbox does not show the
  deadline or the linked person or tag, and there is no people or tags
  screen yet.
- Typing `@`, `#` or `!` in the capture screen now opens a list of matching
  people, tags or dates under the text field, filtering as you keep typing
  (REQ-033). People and tags are ranked: names starting with what you typed
  first, then names containing it, then the most used, then alphabetically;
  at most 5 lines. A name nothing matches yet is offered as "New: …" and is
  only created on saving. A person whose name has spaces is offered as a
  one-word alias (shown under the name); a person without one isn't offered
  here. Date suggestions show relative words first (today, tomorrow, the day
  after), then the coming weekdays by date, then next week; choosing one
  inserts the full word (e.g. `!friday`), while typing a short form yourself
  still works. Choosing a suggestion adds a space when it's at the end of the
  text; in the middle of the text, what comes after (like a closing bracket)
  stays as it was. On Windows the top suggestion is highlighted and the
  arrow keys, Enter, Tab and Escape work as expected (Escape closes only the
  list; Enter then saves); on Android you tap a suggestion. Saving never
  waits for the list, so an unfinished token can still be saved.
- The capture screen now shows a prefix bar: one button per sign
  (**@ persoon**, **# tag**, **! datum**) plus a **?** button on the far
  right (REQ-034). On Android it sits right above the keyboard; on
  Windows right under the text field. Tapping a sign button puts that
  sign at the cursor (or over selected text) and opens the suggestion
  list; a space is inserted first when needed so the sign starts a new
  word (e.g. "Bel" becomes "Bel @"), but not right after an opening
  bracket. The keyboard stays open. The **?** button opens a syntax
  overview listing every sign with its name and an example line, plus
  the `\` escape for plain text; a bottom sheet on Android, a window
  with a "Sluiten"/"Close" button on Windows. On Windows, Tab moves
  focus from the text field to the bar buttons when the suggestion list
  is closed (Tab still chooses the highlighted suggestion when the list
  is open). A new "Invoer" section in Settings lets you set the prefix
  bar to "Altijd zichtbaar" (default, full buttons), "Ingeklapt" (a
  single slim row with just the signs, still tappable, with a button to
  expand to the full buttons; whether it's expanded is remembered), or
  "Uit" (no bar); the setting applies per device. Saving never waits for
  the bar.
- Android: a home-screen widget, "Capture", lets you jot down a thought
  without opening Offload (REQ-001). Tapping it opens a small window over
  the home screen with the keyboard already open; the keyboard's action
  key or the "Save" button saves the text and closes the window. The
  window and widget follow the phone's system language, not the language
  chosen in Offload's settings. Captured items are kept encrypted on the
  phone, never lost (including across a restart), and appear in the inbox
  the next time Offload is opened or brought to the front, timestamped at
  the moment of the tap. An item that cannot be read is set aside, never
  deleted, and the inbox says so; a failed fetch attempt is also reported
  and retried automatically. Known limitation: after "Force stop" in
  Android settings, the widget does not respond until Offload has been
  opened once.
- Android: you can share text or a link from another app (mail, chat,
  browser) straight to Offload via Share → Offload, for text and links
  only (not photos or files yet). It opens the same small capture window
  as the widget, filled in with the subject on the first line and the
  text or link below it (only the text if it already contains the
  subject), line breaks kept as they were, showing up to 10 lines with
  the rest scrollable. Sharing again while the window is still open with
  unsaved text adds it on a new line, keeping what you had typed
  (REQ-002).
- A magnifier ("Zoeken") in the inbox's top bar opens a search screen,
  cursor already in the field ("Zoek in items en personen"); results
  appear while typing, best match first (REQ-011). Items and people are
  shown in one list, each with its own icon: an item shows its title (or
  else its text as captured) and when it was captured, a person the name
  and the first line of their note. Searched: an item's title, text and
  note; a person's name, aliases and note, so `#renovatie` is found via
  "renovatie" and `@Jan` via "jan", and a person created from `@Jan` is
  findable as a person too. Capitals and accents don't matter ("cafe"
  finds "café"); the start of a word is enough ("keur" finds
  "keuring", but not "uring"); with several words, all must occur;
  a hit in a title or name ranks higher. Items in the trash never appear.
  With nothing typed, the screen explains that the start of a word is
  enough; no results shows "Niets gevonden voor „…”"; a ✕ clears the
  field. Tapping a result does nothing yet. Everything stays on the
  device; the index is in the encrypted database.
- The inbox now shows "Lijkt op een ander item" under an item that nearly
  repeats an older one (REQ-053), on the newer item of the pair only.
  "Nearly repeats" ignores capitals, accents and the signs `@#!`, and
  matches on the same text or on a large, shared set of meaningful words;
  different word forms don't count, so Offload favours fewer hints over
  wrong ones. A done item still counts; a trashed item doesn't, and only
  items are compared, not people. Tapping the line opens "Bestaat dit al?"
  with both texts side by side, with **Negeren** (keeps this pair from
  being shown again) and **Sluiten** (changes nothing); Offload never
  merges or deletes anything by itself. The hint can appear a moment
  after saving, once it's worked out in the background. The database is
  upgraded automatically on first start after this update; your data
  stays as it is.

- A **Process · N** button (NL "Verwerken · N") above the inbox list (shown whenever the inbox has items) opens
  a triage screen that goes through the inbox card by card (REQ-010). Each card shows its
  title, the rest of the text, its chips, when it was captured, the duplicate hint, and an
  "Open" button; six buttons below it send the card to Task, Idea, Request, Wait for,
  Reference or the trash, changing its type and status accordingly. Request and Wait for
  first ask for a person ("Who asked for this?" / "Who are you waiting for?"), with suggestions
  of known people, "New: …" to add one, and a way to skip without a person. Sending a card
  somewhere shows an "Undo" message that can undo only that last choice, once. The top right shows
  progress ("3 of 12"); items captured during triage are added at the end. Closing triage at
  any point (the ✕, or Esc on Windows) keeps what was already chosen; skipped items stay in
  the inbox. Android: swipe a card right to skip it (it stays in the inbox) or left to trash
  it; screen readers get the same two actions without swiping. Windows: number keys 1-5 and
  Del choose a destination, → or space skips, Ctrl+Z undoes, Enter opens the card, Esc stops.
  A closing screen reports how many cards were sorted and how many were skipped, with a
  button back to the inbox.
- Tapping an item in the inbox, in a search result, or "Open" in the duplicate comparison
  now opens the item, to read and edit it (REQ-018). Two chips at the top show the status
  (Inbox, Active, Waiting for, Scheduled, Done, Archived) and the type (No type, Task,
  Request, Idea, Note; "Thought" is no longer offered); tapping either opens a menu with only
  the moves that are allowed — an item can never go back to Inbox, a done item can be
  reopened or archived, an archived one only reopened. The text is edited the same way as
  when capturing (chips, suggestions, the prefix bar), with a note field below it. Changes
  save automatically, 2 seconds after you stop typing and when you leave the screen; empty
  text is never saved. The deadline follows the text: changing or removing the date changes
  or removes the deadline, while a date already in the text keeps the date it had. "Pick a
  date…" (also in quick capture) opens a calendar and inserts the chosen day as a fixed date.
  Buttons "Complete" (or "Reopen" for a done or archived item) and "Waiting for…" change the
  status; a menu action moves the item to the trash, with an undo message. The bottom of the
  screen shows when and how the item was captured. On Windows, Ctrl+Enter completes/reopens
  and Esc goes back (closing an open suggestion list first); the item currently opens as its
  own screen. The duplicate comparison now also offers "Open" to jump to the older item.
- The inbox now has a temporary "Show processed items too" switch, off by default at every
  start, that lists every item not in the trash together with its status and when that
  happened (e.g. "Done · 27 Sep 2026, 14:43"); it will go once the Today and Projects screens
  exist (REQ-018). Tapping an item in a search result now opens it the same way; tapping a
  person still does nothing yet.

### Changed

- The inbox list now shows each item as a card (REQ-030, REQ-053). The title is the first
  line of text, bold and without its `@person`, `#tag` or `!date` words (the full text is
  still in the item's detail); a text of several lines shows only that first line plus a
  small grey count such as "+ 3 lines". Below the title, chips for the linked person, tags
  and date appear in the order they occur in the text, once the item has been processed; a
  date chip turns orange with its own icon once it is due today or overdue, while an already
  fixed relative date (e.g. "!tomorrow" typed earlier) keeps the day it was given. The time
  on the right is now relative and updates every minute ("just now", "12 min", "1 h",
  "yesterday", "2 d", then the date after a week); the exact moment is still in the item's
  detail, and screen readers hear it written out. The capture source (widget, share, …) is no
  longer shown in the list, only in the item's detail. With "Also show processed items" on, the
  status now shows next to the time. The "Looks like another item" hint still shows on the
  card.
- Android: you can now swipe a card in the inbox to the left to move it to the trash, with an
  "Undo" message; swiping right does nothing (REQ-030, AC REQ-010). Screen readers (TalkBack on
  Android, Narrator on Windows) offer "Move to trash" as an action on every card, no swipe
  needed; Windows has no swipe gesture yet.
- Android: the home-screen widget is now 1×1 by default (was 2×1), a navy tile with a white
  glyph instead of the earlier text-only button. It can still be made wider; from about 3
  cells wide it also shows the glyph plus "Capture something…". The whole widget, at any size,
  remains a single button that opens the capture window. An existing 2×1 widget keeps its size
  and shows the new tile after the update (REQ-001).
- Offload now has its own app icon, on Android (including a themed/monochrome variant for
  launchers that support it) and on Windows (application icon, taskbar, and system tray icon).
- The build number shown under "About Offload" in Settings is now set
  automatically from the number of commits, so each release has a higher
  build number than the last, and a new release APK installs as an update
  over the existing app, keeping your data (REQ-060).
- Groundwork for search: Offload now keeps an on-device, encrypted search
  index of items and people up to date after saving. On first start after
  this update, existing items and people are indexed in the background;
  the database is upgraded automatically and your data stays as it is.
  Nothing is sent anywhere (REQ-011).

### Fixed

- "Undo" messages (after moving an item to the trash, and after sending a card somewhere in triage) go
  away again after five seconds; they stayed on screen until tapped. With TalkBack on (Android)
  they stay until you act, so there is time to reach the button
  (AC REQ-010, REQ-016).

### Security

- Added encryption at rest for the database, with a key protected by the
  platform (Android Keystore / Windows DPAPI) (REQ-004).
- Excluded Offload's data from Android system backup and device-to-device
  transfer.
