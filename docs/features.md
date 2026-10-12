# What Offload can do now

The current state of the app, kept up to date by the documentation agent (DD-020). It used to be
the first part of the user manual; the manual itself now only explains how to do things
([`user-manual/en/README.md`](user-manual/en/README.md)). Version history: [`CHANGELOG.md`](../CHANGELOG.md).

## Status

Offload is in early development. It opens on **Today**, with everything whose deadline is today
or has passed, and from there you switch to the **Inbox**; see [Today](user-manual/en/today.md)
and [Navigating](user-manual/en/navigating.md). You can capture thoughts and see them in the
inbox, also through the Android widget, the Android share menu and, on Windows, the keyboard
shortcut and the system tray; see [Capturing](user-manual/en/capturing.md). You can search them
([Searching](user-manual/en/searching.md)), open an item to edit its text and note, change its
status and type, complete it and move it to the trash
([The item detail](user-manual/en/item-detail.md)), and process your inbox card by card
([Processing your inbox](user-manual/en/triage.md)).

## Already built

- At start, Offload opens its encrypted data and then shows **Today**, with everything that has
  a deadline of today or earlier; see [Starting Offload](user-manual/en/starting.md) and
  [Today](user-manual/en/today.md). Everything you capture is stored encrypted on your device,
  with a key protected by the platform (Android Keystore and Windows DPAPI respectively). Without
  that key it is unreadable.
- Offload uses the IBM Plex typeface everywhere, on Android and Windows. It is bundled with the
  app and never downloaded; it also covers Cyrillic.
- On Android you switch at the bottom of the screen between **Today**, **Inbox**, **Projects**,
  **People** and **Insights**, with a number on **Inbox** for the unprocessed items; on Windows a
  bar on the left holds the same five places, the capture screen and **Settings**; see
  [Navigating](user-manual/en/navigating.md).
- **People** shows everyone you mentioned with `@name`, as a balance of what you owe and what you
  are waiting for, with the age of the oldest open item; a person is also your preparation for a
  one-to-one conversation. An item shows who asked for it and whom you are waiting for; see
  [People](user-manual/en/people.md).
- **Insights** shows at a glance what is coming (**Horizon**, the next six weeks per project, busy
  weeks in orange), what has stalled, and your balance per person. **Show connections** shows
  what is connected to one item, person or project; see [Insights](user-manual/en/insights.md).
- **Projects** groups items into projects and sub-projects, with the number of open and overdue
  items per project; you give an item a project in the item itself or while processing; see
  [Projects](user-manual/en/projects.md).
- You capture a thought with the **Capture** button and see it in the inbox at once, as a card
  with a title, how long ago you captured it and, once processed, chips for person, tag and date;
  on Android you swipe a card to the left to move it to the trash; see
  [Capturing](user-manual/en/capturing.md).
- On Windows, from a wider window, the list and an opened item sit side by side, with a search
  field above the list and keyboard shortcuts to navigate, search, choose items, complete them or
  move them to the trash; see [Navigating](user-manual/en/navigating.md).
- While you type, Offload recognises `@Jan` (person), `#renovation` (tag) and `!fri` (date) and
  shows them as chips below the text field, with a suggestion list of existing people, tags and
  dates that filters as you type. After saving, Offload links them: `@Jan` to the person Jan
  (created if he did not exist yet), `#renovation` to that tag, and the first date becomes the
  item's deadline if it had none. The chips also appear on the item's card in the inbox a moment
  later; see [Capturing](user-manual/en/capturing.md).
- On Android you can capture without opening Offload, with the **Capture** widget on your home
  screen (a navy tile with a white icon, which you can make wider); the item appears in the inbox
  as soon as you open Offload again; see [Capturing](user-manual/en/capturing.md).
- On Android there is also the **Offload bar** widget with buttons for **Capture**, **Today** and
  (wider) **Insights**, plus shortcuts on the app icon; see
  [Capturing](user-manual/en/capturing.md).
- Offload has its own app icon, on Android and on Windows.
- On Android you can share text or a link from another app to Offload (**Share** → **Offload**);
  the input window then opens filled with what you shared; see
  [Capturing](user-manual/en/capturing.md).
- On Windows Offload runs only once at a time; starting it again brings the open window to the
  front instead of opening a second one; see [Starting Offload](user-manual/en/starting.md).
- On Windows the keyboard shortcut **Win+Shift+B** opens the capture screen from any program;
  closing the Offload window keeps the app running in the background (in the system tray), so the
  shortcut keeps working; see [Capturing](user-manual/en/capturing.md) and
  [Starting Offload](user-manual/en/starting.md).
- On Android Offload takes no part in the system backup or in "transfer data to a new phone". You
  make a backup yourself with Offload's own encrypted backup: at the bottom of **Settings** choose
  **Make a backup** and **Restore a backup**; see [Settings](user-manual/en/settings.md). If the
  device holds attachments, a backup can include them (switch **With attachments**), with a progress
  bar and a free-space check. To keep
  your data readable, **Export** (not encrypted) writes Markdown or JSON, in the same place.
- Offload has a Dutch and an English interface and follows your device's language by default. You
  can also choose the language yourself in **Settings**; see
  [Settings](user-manual/en/settings.md).
- At the top of **Settings** you see which version and build of Offload you installed and when it
  was made; see [Settings](user-manual/en/settings.md).
- While capturing you see a bar with a button per input sign (**@ person**, **# tag**,
  **! date**) and a **?** button with an overview of all signs; under **Settings** → **Input**
  you can collapse or hide this bar; see [Capturing](user-manual/en/capturing.md) and
  [Settings](user-manual/en/settings.md).
- You can search items and people (on Android through the magnifier above the inbox, on Windows
  through the search field above the list): while you type you see what matches, best match
  first; see [Searching](user-manual/en/searching.md).
- When a new item looks a lot like an older one, the inbox shows the line **Looks like another
  item**; tapping it shows both texts, with the choice to open the older item or to ignore the
  hint for that pair; see [Capturing](user-manual/en/capturing.md).
- Type `[[` (or tap **[[ item** in the bar) to refer to another item; the link keeps working when
  you rename that item; see [Capturing](user-manual/en/capturing.md). The item detail shows which
  items refer to this one.
- You can open an item (from the inbox, a search result or the duplicate hint) and change its
  status (**Inbox**, **Active**, **Waiting**, **Scheduled**, **Done**, **Archived**) and type,
  edit the text and a note (with the same chips, suggestions and button bar as when capturing;
  saving is automatic), complete or reopen it, and move it to the trash with **Undo**; see
  [The item detail](user-manual/en/item-detail.md).
- With the **Process** button above the inbox you go through your inbox card by card and give each
  item a place: **Task**, **Idea**, **Request**, **Wait for**, **Note** or **Trash**, with **Undo**
  for the last choice; see [Processing your inbox](user-manual/en/triage.md).
- With **Revisit on…** you park an item until a day; then it is back in your inbox; see
  [Parking an item](user-manual/en/revisit.md).
- The **Weekly review** (icon at the top of **Today**) goes in five steps through your insights,
  your inbox, what you are waiting for, your deadlines and what has stalled; see
  [Weekly review](user-manual/en/weekly-review.md).
- From an opened item you can share its text: a share icon opens a preview without input signs
  that you can edit; then you share it through the Android share menu, or copy or save it on
  Windows; see [The item detail](user-manual/en/item-detail.md).
- With **Where was I** in an item or project you note in a few seconds what your next step is and
  what you had in mind; the note then stays as a card at the top until you choose **Resume**; see
  [Where was I](user-manual/en/where-was-i.md).
- With `!daily`, `!weekly` or `!monthly` in the text a task comes back; when you complete it once,
  it moves to its next date; see [Recurring tasks](user-manual/en/recurring.md).
- **Help** in the app: under **Settings** the row **Help** opens the manual, and a **?** in the
  title bar of each main screen (on Windows also **F1**) opens the part that belongs to that screen;
  see [Settings](user-manual/en/settings.md#help) and
  [Navigating](user-manual/en/navigating.md#help-on-each-screen).
- Storage use under **Settings**; see [Settings](user-manual/en/settings.md).
- **Photos** in an item: **Add photo** takes one from the camera or gallery (Android, no permission)
  or from an image file (Windows). Offload keeps it small, upright, without EXIF or location,
  encrypted, with a thumbnail. They show as a row under the note, open full screen with zoom and
  can be deleted; see [The item detail](user-manual/en/item-detail.md#photos).
- **Photos on the cards**: the newest photo shows as a small thumbnail on the item's card in the
  lists (Inbox, Today, projects, people, Weekly review) and in search results, with a number when
  there are more; see
  [Photos on the cards](user-manual/en/item-detail.md#photos-on-the-cards).
- **Models** under **Settings**: import the handwriting model (Qwen3-VL-2B-Instruct, about 1.6 GB)
  from files you choose yourself, with a free-space check, progress and **Stop**; remove it again,
  and choose **Accurate** or **Faster** for reading handwriting. Offload downloads nothing and
  models are not part of a backup; see [Settings](user-manual/en/settings.md#models).
- **Read handwriting from a photo** in **Capture**, once the model is imported: take or open a
  photo (Android: camera or gallery), optionally drag four corners onto a skewed page, and read.
  It shows progress and **Stop**; the text is added to the capture field to check and save, and
  the photo is never stored; see
  [Reading handwriting from a photo](user-manual/en/capturing.md#reading-handwriting-from-a-photo).
