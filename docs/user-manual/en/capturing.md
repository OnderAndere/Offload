# Capturing something

## The inbox

The **Inbox** is the list of everything you have captured and not yet processed, newest first,
shown as cards. You open it through the navigation, see
[Switching between Today, Inbox, Projects, People and Insights](navigating.md). Offload itself
opens on **Today** when it starts, see [Today](today.md). Above the list you see the number of
items. As soon as the inbox contains items, there is also the **Process · N** button to process
them card by card, see [Processing your inbox](triage.md).

If you have not captured anything yet, you see "No items yet" instead of a list.

### What a card shows

- **Title** — the first line with text, in bold, without the signs `@Jan`, `#renovation`,
  `!friday`, `^renovation` or `*high` in it. If the line is too long for one line, it is cut
  off. If the first line consists only of such signs, you see it just as you typed it. The item
  itself always keeps the full text; you see it again when you open the item, see
  [Viewing and editing an item](item-detail.md).
- If your text has several lines (for example a shared email with the subject on the first
  line), the card shows only that first line, with "+ 3 lines" in small grey text below it for
  the rest ("+ 1 line" for one extra line).
- If the item has a type, the first chip under the title is the type, with an icon and the
  name: ☑ **Task**, 💡 **Idea**, ✋ **Request** or 📄 **Note**. A screen reader announces this as
  "type: Task". If the item has no type yet, this chip is missing.
- Then come **chips** for person, tags and date, in the order in which they appear in your
  text — but only once Offload has processed them; right after capturing they appear a moment
  later. A date chip is orange with its own icon as soon as the date is today or has passed; an
  old `!tomorrow` keeps the date it got when you typed it.
- To the right of the title is the moment you captured the item, shown relatively: "just now",
  "12 min", "1 h", "yesterday", "2 d" up to a week ago, and after that the date itself (for
  example "Mon, Sep 21"). This refreshes every minute. You see the exact moment in the item
  detail, see [Viewing and editing an item](item-detail.md). A screen reader announces it in
  full, such as "12 minutes ago".
- If the item has a project, it is shown as a grey chip after the type, see
  [Projects](projects.md). If your text has a priority, a chip follows: **High priority**,
  **Normal priority** or **Low priority**. Without a priority word there is no chip.
- If the item is waiting (status **Waiting**) and has an expected day, there is a chip
  "expected «date»". If that day has passed, the chip is orange, with a warning icon, and says
  for example "3 d late". See [Commitment](item-detail.md#commitment).
- The line "Looks like another item" (see below) stays on the card when it applies.

What you used to capture the item (the app, the widget, sharing, the hotkey or the system
tray) is no longer shown on the card, only in the item detail.

On Android, at the top right, there is a magnifying glass with which you can **search** items
and people, see [Searching](searching.md), and the cog with which you open **Settings**, see
[Settings](settings.md). On Windows, search and Settings have their own place, see
[Switching between Today, Inbox, Projects, People and Insights](navigating.md).

If you tap a card, the item opens, see [Viewing and editing an item](item-detail.md).

**To the trash.** On Android you swipe a card to the **left** to move the item to the trash;
you then see the message "Moved to trash" with the **Undo** button. This message disappears by
itself after five seconds. If you use a screen reader (TalkBack on Android), it stays until you
tap **Undo**, so that you have time to find the button. A new message (for example because of
a next swipe) immediately takes the place of the previous one, which can then no longer be
undone. Swiping to the right does nothing. On Windows you cannot swipe yet; use the
**Delete** key on a selected card there, or the menu in the item detail, see
[Switching between Today, Inbox, Projects, People and Insights](navigating.md) and
[Move to trash](item-detail.md). A screen reader (TalkBack on Android, Narrator on Windows)
offers the action "Move to trash" on every card, even without swiping.

The inbox shows only items that have not been processed yet. You find processed items under
**Projects**, in their project or under **Without project**, see [Projects](projects.md).

## Looks like another item

If you save an item that looks a lot like an older item, the line "Looks like another item"
(with a copy icon) appears under the new item in the inbox. Only the newer item of the pair
gets this line; the older item does not.

"Looks a lot like" means: capitals, accents and the signs `@`, `#` and `!` do not matter. It
is either exactly the same text, or at least 80% of the meaningful words (3 letters or more)
of the shorter item also appear in the other one, with at least three such words. Other forms
of a word ("ask" and "asking") do not count as the same — Offload would rather show a hint
too rarely than too often.

An older item that is already completed still counts; an item in the trash does not. Only
items are compared this way, not people.

If you tap the line, "Is this already there?" opens: at the top "This item" with the text of
the new item, below it "Looks like this item from «date», «time»" with the text of the older
item.

- **Ignore** — the hint for this pair disappears and stays away, also on other devices once
  synchronisation exists; for now this at least makes sure your choice is kept.
- **Open** — opens the older item, see [Viewing and editing an item](item-detail.md).
- **Link** — puts `[[…]]` with the other item at the end of the text of the newest item and
  links the two, see [Linking an item to another item](#linking-an-item-to-another-item).
  If that does not work, you see "Linking did not work" and nothing changes.
- **Close** — nothing changes; the hint stays.

Offload never merges items by itself here and deletes nothing automatically.

Two items that are linked to each other get no hint about each other. The text inside `[[…]]`
does not count in the comparison.

You also see this line in the item detail itself, see
[Viewing and editing an item](item-detail.md).

The hint may appear only a moment after saving: it is calculated in the background.

## Capturing a thought

On Android, at the bottom right, on both **Today** and **Inbox**, is the **Capture** button; on
Windows it is the **+** button at the top of the bar on the left, see
[Switching between Today, Inbox, Projects, People and Insights](navigating.md) (also the
shortcut **Ctrl+N**). It opens a screen with one text field; the cursor is already in it, so
you can start typing right away. As long as the field is empty, you see the text "What's on
your mind?" as a hint.

Your text is kept exactly as you type it.

### Saving

- **Windows:** **Enter** saves your text; **Shift+Enter** starts a new line.
- **Android:** the action key of the on-screen keyboard saves your text. Your text is one line
  that wraps by itself on the screen; you cannot type a new line yourself. If you paste text
  with line breaks in it, those line breaks are kept.

You can also tap the check mark **Save** in the title bar. This is possible only once there is
text in the field that does not consist of spaces alone.

After saving, the screen closes and the item is at the top of the inbox right away.

If saving fails once, your text simply stays in the field and you see the message "Saving
failed. Your text is still here; please try again." You do not have to type anything again;
just try once more.

## Button bar for the input signs

The capture screen has a bar with one button per sign: **@ person**, **# tag**, **! date**,
**^ project**, **\* priority** and **[[ item**, and all the way to the right a **?** button. On
Android this bar sits just above the on-screen keyboard and scrolls sideways if not all
buttons fit on your screen; on Windows it sits directly under the text field.

If you tap one of the sign buttons, Offload puts that sign at the cursor position (or in
place of selected text) and immediately opens the suggestion list for that sign, see below. If
the cursor was directly after a letter, digit or punctuation mark, Offload first puts a space
in front of it — for example "Call" becomes "Call @". If the cursor was directly after an
opening bracket such as `(`, no space is added. The keyboard stays open.

The **?** button opens the syntax overview: each sign with its name and an example line.
At the bottom, **More in the manual** opens the part of this manual about the signs.

- **@ person** — Call @Jan about the quote
- **# tag** — Clean the gutter #chores
- **! date** — Quote done !friday, or !tomorrow or !12-10
- **! repeat** — Go running !weekly !tue, also !daily or !monthly, see
  [Recurring tasks](recurring.md)
- **^ project** — Order window frames ^renovation, or ^old-barn or ^renovation/kitchen
- **\* priority** — Check the quote `*high`, or `*low` or `*1`, `*2`, `*3`
- **[[ item** — Order frames, see [[Compare window quotes]]
- **\ plain text** — Put \ in front: \@Jan is not recognised
- **phone number** — Call @Jan on 06-12345678 or +31 6 1234 5678
- **email address** — Mail @Jan at jan@example.org

The bar has no button for the phone number and the email address; you type them without a
sign.

On Android this overview appears as a panel that slides up from the bottom of the screen; on
Windows as a separate window, with the **Close** button.

On Windows, **Tab** moves the focus from the text field to the buttons of the bar as long as
the suggestion list is closed; if the list is open, **Tab** picks the highlighted suggestion,
as described below.

If you want to collapse this bar or hide it completely, you set that under **Settings** →
**Input** → **Prefix bar**, see [Settings](settings.md).

Saving never waits for this bar.

## People, tags, dates, projects and priority in your text

While you type in the capture screen, Offload recognises certain words and shows them as chips
under the text field:

- `@Jan` — a **person**, recognisable by the name icon.
- `#renovation` — a **tag**, recognisable by the hash sign.
- `!fri` — a **date**, recognisable by the calendar icon; on the chip you see the date itself,
  for example "Fri, Oct 2".
- `^renovation` — a **project**; on the chip you see the path of the project, so for a
  sub-project for example "Renovation › Kitchen".
- `*high` — a **priority**; the chip says **High priority**, **Low priority** or **Normal
  priority**.

A word only counts if it is at the start of your text, after a space, or directly after an
opening bracket (`(`, `[` or `{`) — so for example `(@Jan)` works too. An `@` in the middle of
a word, as in `jan@example.org`, does not make a person (the whole address is recognised as an
email address, see [Phone numbers and email addresses](#phone-numbers-and-email-addresses)).
If you put a backslash (`\`) right before a word, such as `\@Jan`, it is never recognised.
Punctuation directly after it (for example the comma in `@Jan,`, or an opening bracket at the
end, as in `#chore(`) is not part of the word. After `@` and `#` a letter must follow (in any
script, also Cyrillic); `@10:00` and `#1` therefore stay plain text. A word that Offload does
not recognise also stays plain text — no chip appears and nothing else happens.

For a date after `!` you can use:

- **today**, **tomorrow**, **dayafter**;
- a day of the week, short or in full (**mon** through **sun**, or **monday** through
  **sunday**): this is always the next day with that name, never today itself — so `!fri` on a
  Friday means the Friday after;
- **nextweek**: the Monday of next week;
- a date such as `!12-10` (day-month; the next time that date occurs, even if that is today)
  or `!12-10-2026` (day-month-year).

Capitals do not matter. These are the words when Offload is set to English; if Offload is set
to Dutch, the Dutch words apply instead.

### Phone numbers and email addresses

You recognise a phone number or email address in your text without a sign in front of it; you
do not have to put a backslash in front of it either. Offload recognises:

- a **phone number** that starts with `+` or `0` and has 9 to 15 digits, with spaces, `-`,
  `.`, `/` or brackets in between: `06-12345678`, `06 12 34 56 78`, `+31 6 1234 5678` or
  `+31 (0)20 123 4567`;
- an **email address**, such as `jan@example.org`.

A date with a year (`01-02-2026`), a time, a year number, an amount or an IBAN stays plain
text.

While you type, such a number or address gets a chip. If your text names exactly one person
with `@`, the name is shown with it, for example "06-12345678 → Jan": that way you see where
it is going.

**Saving is confirming.** If you save the item in the capture screen, or leave the
[item detail](item-detail.md), the numbers and addresses you newly typed are added to the
contact details of that person, see [People](people.md). At the bottom you then see "Added to
Jan" (or, with more details, for example "2 details added to Jan") with **Undo**; that removes
everything that was just added.

- A Dutch mobile number gets the label **Mobile**; other numbers and addresses get no label.
- If the person already has the number or address, it is not added again. `06-12345678` and
  `+31 6 12345678` count as the same number.
- Only what you newly type counts. Offload never reads through your older items, not even
  after an update.
- If you move an item to the trash, nothing is added.
- **Android:** an item that you capture with the widget or through **Share** adds nothing,
  because there is no screen there to confirm it. You can still link a number in such an item
  later in the item detail (see below).
- **Windows:** capturing with the hotkey or through the system tray also adds, because that
  opens the same capture screen.

**No person, or more than one.** If your text names no person or several, nothing happens by
itself. In the item detail you can then tap the chip of the number or address (**Link to a
person**). The **Whose is this?** window first shows the people from the text, then the
others; you can also type a new name. After your choice, the detail is with that person, with
the same message and **Undo**.

On cards a number or address gets no chip; it stays in the title.

You set how Offload reads a number without a `+country code` under **Settings** → **Country
for phone numbers**, see [Settings](settings.md).

### A project and a priority

**Project with `^`.** Put `^` in front of the name of a project: `^renovation`. Capitals,
spaces, hyphens and underscores do not matter: `^old-barn` and `^oldbarn` both find the
project "Old barn". For a sub-project you put a slash between the names:
`^renovation/kitchen`. Archived projects never count.

If there is no project with that name, the word does not become a project by itself: Offload
never creates a project by itself when saving. It does say so, with a chip such as
**greenhouse · no project**, while you type and in the item detail. If the name occurs among
sub-projects under different main projects, you see for example **kitchen · several
projects**; then pick the path from the suggestion list (see below). On cards nothing changes.

- **In the capture screen** the chip only tells you. You create a project with **Create
  project: name** in the suggestion list.
- **In the item detail** you can tap the chip **no project** (Windows: Tab to it and Enter).
  The **New project** window opens with the name from the word already filled in; hyphens and
  underscores have become spaces, and you can still adjust the name. With **Create** the
  project is made and the item is in it right away. If you typed `^parent/name` and the main
  project "parent" exists, it is already chosen under **Under**. If "parent" does not exist,
  the chip only tells you.
- **Created later.** If an item with `^word` was already saved while the project did not exist
  yet, Offload puts the item in that project the next time the app starts, as soon as a project
  with that name exists (also if you restore it from the archive). If in the meantime you
  yourself chose another project for the item, that choice stays.

A `^project` that you newly type works like choosing that project. If you then choose a
project in the item detail or while processing the inbox (the project chip or the **Project**
window), that choice wins over the word in your text. If you remove the word from your text,
the item keeps its project. If there are more `^` words, the first new one counts. In the item
detail you can choose a project right after you typed a `^` word; your text is then saved
first.

**Priority with `*`.** `*high` or `*1` is high priority, `*low` or `*3` low priority and `*2`
normal priority. If Offload is set to Dutch, `*hoog` and `*laag` work instead of `*high` and
`*low`. Ordinary Markdown such as `* list item`, `*emphasis*` and `**bold**` stays text, and
so does anything with a backslash in front (`\*high`). The priority follows your text: if you
remove the word, the item no longer has a priority.

### Suggestions while you type

If you type `@`, `#`, `!`, `^` or `*` (yourself, or through a button of the bar above), a list
appears under the text field with people, tags or dates that fit what you have typed so far;
the list filters further as you keep typing. If you put punctuation directly after it (as in
`@Jan.`), the list no longer appears.

For people and tags, names that start with what you typed are at the top, then names that
contain it somewhere, then the most used, and the rest alphabetically; the list shows at most
five. If a name does not exist yet, **New: name** is at the bottom of the list — something is
only really created once you save the item. A person whose name consists of several words (for
example "Jan de Vries") is inserted from this list with a one-word nickname; you see that
nickname below it. If such a person has no one-word nickname, that person is not in this
list.

For dates, **today**, **tomorrow** and **dayafter** come first, then the next days of the week
in date order, then **nextweek**; under each option you see the date itself. If you choose a
day of the week, Offload puts down the whole word (for example `!friday`); if you type a short
form such as `!fri` yourself, that simply keeps working, even without using the list.

After `^` the list shows your projects; for a sub-project the path is shown below it, for
example "Renovation › Kitchen". If no project fits what you typed, you see **Create project:
name**. If you choose that, Offload creates the project right away, as a main project, with
the name as you typed it. After `*` the list offers the words **high** and **low**, with
**High priority** and **Low priority** next to them.

If you choose a line from the list, a space is added after it at the end of your text; if you
are in the middle of the text, the rest (for example a closing bracket) stays exactly as it
was. After choosing, the list stays closed for that word.

On Windows the top suggestion is highlighted; the arrow keys move the highlight, **Enter** or
**Tab** picks the highlighted suggestion and **Escape** closes only the list (your text
stays). If the list is closed, **Enter** saves your text and **Shift+Enter** starts a new
line, as described above. On Android you tap a suggestion.

Saving never waits for this list: you can always save, even with a word you have not
finished.

### Linking an item to another item

With `[[` you refer to another item of your own. Type `[[` (or tap **[[ item** in the bar),
and a list of items opens. Without a search word the newest items are at the top; if you type
a word after it, Offload searches the search index: the start of words counts and accents do
not matter. Under each item you see the status and, if there is one, the project.

If you choose an item, Offload puts `[[title]]` in your text: the first line of the item,
shortened to about 60 characters with "…" if the title is long. Square brackets in that title
become round ones. When you save, the item is linked. On Windows you choose with the arrows
and **Enter** or **Tab**; **Esc** closes only the list.

- Every item can refer to every other item, whatever type or status it has; it cannot refer to
  itself. People, projects and tags have their own signs.
- Inside `[[…]]` Offload recognises nothing else: `[[Call @Jan]]` therefore does not make a
  person.
- If you type `[[Quote]]` yourself without choosing from the list, Offload links it when
  saving if exactly one other item has that title. Otherwise it stays a chip such as **Quote ·
  no item**. Offload never creates an item by itself; in the [item detail](item-detail.md) you
  can do so with a tap on the chip.
- If you remove `[[…]]` from the text, the link disappears. If you type it back, the same
  choice returns.

The chip under the text always shows the current title of the linked item, even if you rename
it later; your own text stays as you typed it. A tap on the chip opens the item, see
[Viewing and editing an item](item-detail.md#links-between-items). On cards a link
appears as plain text without brackets, without a chip.

### What Offload does with it

Right after saving, Offload processes the recognised words further, without the capture
screen waiting for it:

- `@Jan` is linked to the person Jan; if that person does not exist yet, he is created. Names
  are recognised regardless of capitals or small letters, also in another script (for example
  Cyrillic), and also through a nickname attached to a person. A nickname arises when you
  rename a person: the old name keeps working then (see [People](people.md)); adding nicknames
  separately is not possible yet. When capturing, `@Jan` is only a link; whether Jan asked you
  for something or whether you are waiting for Jan, you choose later when
  [processing the inbox](triage.md) or in the item itself.
- `#renovation` is linked to that tag; if it does not exist yet, it is created, recognised in
  the same way as for people.
- the first date in your text (`!fri` etc.) becomes the deadline of the item, but only if the
  item has no deadline yet. A date that is relative to today (such as `!tomorrow`) counts from
  the moment you captured the item, not from the moment Offload processes it: `!tomorrow` that
  you typed yesterday through the Android widget therefore means today, even if you only open
  Offload today.
- `^renovation` puts the item in that project and `*high` gives it its priority, as described
  above.
- `[[title]]` is linked to that item, as described above.
- your text itself always stays exactly as you typed it.

Items that you captured with the Android widget are processed as soon as Offload picks them up
(when starting or switching back to the app, see below). Items that you captured before this
version of Offload are processed the next time it starts. After the update, Offload reads each
item once more this way: older items with a `^` word or `*high` then get their project and
priority. An item that you put in a project yourself after capturing keeps that project.

The inbox shows the processed people, tags, date, project and priority as chips under the
title of the item, see above. Everyone you mention with `@` also appears under **People**, see
[People](people.md).

You only see these chips while you type in the capture screen of the app itself (through the
**Capture** button, the Windows hotkey or the system tray); the input window of the Android
widget does not show them. After saving, the processed tokens do appear as chips on the card in
the inbox, see above, whatever you used to capture the item.

## Capturing with the hotkey (Windows)

On Windows the hotkey **Win+Shift+B** works, even while you are in another program — Offload
does not have to be in the foreground, only running (in the window or in the system tray). The
hotkey brings the Offload window to the front and immediately opens the capture screen, with
the cursor already in the text field. Saving works as described above: **Enter** saves,
**Shift+Enter** starts a new line.

If you are already in the capture screen (for example opened with the **Capture** button) and
you press the hotkey, nothing extra happens: no second screen opens and your text stays.

After saving — or if you close the capture screen without saving — the window is back as it
was before: hidden in the system tray, minimised, or behind the program you were just working
in (that program then comes to the front again).

If the combination Win+Shift+B is already in use by another program, Offload does not register
it and the inbox shows the message "The shortcut Win+Shift+B is already used by another
program. You can capture from the system tray or with the Capture button." You can tap this
message away. There is no way yet to change the hotkey itself.

## Capturing through the system tray (Windows)

On Windows, Offload has its own icon in the system tray (the area with small icons next to the
clock). If you click it (or select it with the keyboard), the Offload window comes to the
front. If you right-click it, or open the menu with the menu key of your keyboard, you see:

- **New item** — opens the capture screen, just like the hotkey.
- **Open** — brings the Offload window to the front.
- **Quit** — really closes Offload, see [Starting Offload](starting.md).

The texts in the menu follow the display language you chose in Offload's **Settings**.

## Capturing with the widget (Android)

On Android you can capture a thought without opening Offload, with a widget on your home
screen.

### Adding the widget

The widget is called **Capture**, with the description in the widget picker "Capture a thought
with one tap". In the widget picker you immediately see a preview: a navy blue tile with a
white icon (the Offload postbox with one dot with a plus), at its smallest size 1×1. The exact
steps differ per device and launcher; in general:

1. Press and hold an empty spot on your home screen.
2. Choose **Widgets**.
3. Find **Offload** and drag **Capture** to your home screen.

If you make the widget wider (by dragging it at the side on your home screen), from about 3
cells wide (this differs per device) the text "Capture something…" also appears next to the
icon. The whole widget — however wide — is one button that opens the capture window, just like
at its smallest size. If you already had the widget from before this version of Offload, it
keeps its own size and shows the new tile after the update.

The widget does not fill its cell completely: at 1×1 it is a compact, square tile, and in the
wider form it is a low bar (60 dp high). Both sit in the middle of the cell.

### Using it

If you tap the widget, a small window opens over your home screen, with the keyboard already
open — Offload itself does not open. Type your text and tap the action key of the keyboard or
the **Save** button to save; the window then closes right away. Your text is kept exactly as
you type it. If your text consists only of spaces, you cannot save.

If saving fails once, your text stays in the window with the message "Saving failed. Your text
is still here; please try again."

The window and the widget follow the system language of your device (Dutch or English; any
other language gives English), not the language you chose in Offload's **Settings**.

### When you see the item again

An item that you capture with the widget is stored encrypted on your device and is not lost,
not even after a restart of your phone. You only see it in the inbox once you open Offload, or
switch back to it, afterwards. The time shown with the item is not that moment, but the
moment you tapped the widget.

If a captured item cannot be read (for example because it is damaged), it is kept separately,
never deleted, and the inbox shows a message: "1 captured item could not be read. It was set
aside, not deleted." (or the number, if there are several). You can tap this message away;
such items cannot be retrieved from within the app yet.

If fetching items from the widget fails once, the inbox shows: "Items from the widget could
not be fetched yet. They are kept; Offload will try again."

### Known limitations

- If you have **force stopped** Offload through Android's settings, the widget stops
  responding until you have opened Offload once more. This is standard Android behaviour for
  a stopped app.
- The widget probably does not work before the first unlock after a restart of your phone
  (not tested yet).

## The Offload bar and shortcuts (Android)

Besides the **Capture** widget there is a second widget, the **Offload bar**. With it you go
with one tap to capturing, to **Today** or to **Insights**.

### Adding the bar

You add it like the **Capture** widget: press and hold an empty spot on your home screen,
choose **Widgets**, find **Offload** and drag **Offload bar** to your home screen. At its
smallest size (2×1) it has two buttons: **Capture** and **Today**. If you make it wider (drag
the edge), at 3 cells wide it also gets the **Insights** button. It is a low bar (60 dp high),
in the middle of the cell.

### Using it

- **Capture** opens the same small input window as the **Capture** widget, see above.
- **Today** and **Insights** open Offload on that screen. This also works if Offload is
  already open on another screen. If a triage or weekly review is open there, it is ended; an
  open item is saved. If Offload has a capture screen open with typed text, that screen stays
  on top and your text is not lost; the screen below it does change.

### Shortcuts on the app icon

Press and hold the Offload icon on your home screen or in your app overview. You then see
**Capture**, **Open Today** and **Open Insights**, which work the same as the buttons of the
bar.

### Screen readers

A screen reader reads out each button as **Capture**, **Open Today** or **Open Insights**.

### Known limitation

If you have **force stopped** Offload through Android's settings, the bar and the widget also
do nothing until you have opened Offload once more (Android then cancels them, just like the
reminders).

On Windows there is no widget; the system tray menu has not changed.

## Sharing from another app (Android)

From another app (mail, chat, browser) you can send text or a link straight to Offload, via
**Share** → **Offload**. Offload is only offered for text and links, not for photos or files.

Sharing opens the same small window as the widget above, already filled in: the subject (for
example the mail subject or the page title) on the first line, the text or link below it; if
the subject is already in the text, only the text. Line breaks stay exactly as they were. The
window shows up to 10 lines; if the text is longer, it scrolls.

You can still add something to it, for example `@Jan` or `!friday`, and then save with the
action key of the keyboard, the **Save** button, or with Enter on a physical keyboard (also
Shift+Enter; typing never adds a line by itself). Afterwards you return to the app you shared
from. The item is in the inbox the next time you open Offload, just like with the widget; the
people, tags and dates in it are only processed after saving.

If the window is still open with text you had not saved yet, and you share something else, the
newly shared text goes on a new line below it; what you had already typed is not lost.

A link stays plain text: Offload never opens it and does not fetch a preview for it (no
internet connection).

If you close the window without saving (back button), nothing is kept; the text is still in
the app you shared from.

**Windows:** there is no share menu option; paste the text into the capture screen instead.
