# Viewing and editing an item

You open an item by tapping it: in the inbox, in a search result, or via **Open** in the "Is this
already there?" comparison at "Looks like another item".

## Status and type

At the top of the item are three chips.

- The first chip shows the status: **Inbox**, **Active**, **Waiting**, **Scheduled**, **Done** or
  **Archived**. Tap it to switch; the list only shows the steps that are allowed. You can never go
  back to **Inbox**. You can archive an open item directly (**Archived**), even without completing
  it first. You can reopen a completed item (back to **Active**) or archive it; an archived item
  can only be reopened. If you choose **Scheduled**, Offload always asks first on which day you
  want to see the item again, see [Parking an item](revisit.md). If you change the status of a
  parked item yourself, the revisit is dropped.
- The second chip shows the type: **No type**, **Task**, **Request**, **Idea** or **Note**, with the
  same icon as on the card, see [Capturing something](capturing.md); for **No type** there is no
  icon. Tap it to change the type. "Thought" is no longer offered as a choice.
- The third chip shows the project: **No project** or the name of the project, for an archived
  project as "Name (archived)". Tap it to open the **Project** window and choose a project, search,
  or create a new project, see [Projects](projects.md).

There can also be chips for people: ✋ for who asked for it (as soon as a person is set or the type
is **Request**) and ⏳ for who you are waiting for (as long as the status is **Waiting**, even
without a person). Tap them for the menu **Open «name»**, **Other person…** and **Remove**; without
a person you choose one from the window **Who asked for this?** or **Who are you waiting for?**, see
[People](people.md).

If a change fails, you see the message "The change failed. Please try again."

### Revisit on

If the item is parked, the line "Revisit on Mon, Oct 12" appears under the status. Tap it to choose
another day; with ✕ you choose **Not any more**. You park an item via the menu (⋮) with
**Revisit on…**, see [Parking an item](revisit.md).

## Editing the text

You edit the text in the same way as when capturing, see [Capturing something](capturing.md): chips
for people (`@Jan`), tags (`#renovation`) and dates (`!friday`) under the text field, the same
suggestion list while you type, and the same button bar (**@ person**, **# tag**, **! date**,
**?**).

A phone number or email address in the text also gets a chip here. When you leave the item, the
numbers and addresses you newly typed are added to the one person that the text mentions, with
"Added to Jan" and **Undo**. If the text mentions no person or several people, tap the chip
(**Link to a person**) and choose the person in **Whose is this?**. An item you move to the trash
adds nothing. See [Phone numbers and email addresses](capturing.md#phone-numbers-and-email-addresses).

Unlike when capturing, **Enter** here always makes a new line, on both Android and Windows: no save
button is needed, because saving happens automatically (see below).

Under the text field is a second field, **Note**, for extra text.

### Saving automatically

Offload saves your changes automatically: 2 seconds after you stop typing, and also as soon as you
leave the screen. There is no separate save button.

If you empty the text, that is not saved: the previous text is kept and the field shows the message
"An item needs text. The previous text is kept."

If saving fails, your change stays in the field with the message "Saving failed. Your change is
still there; please try again."

### The deadline follows the text

The item's deadline comes from the first date in the text, and follows that text:

- If you remove the date from the text, the deadline disappears.
- If you change the date, the deadline changes with it.
- A date that was already in the saved text keeps the date that was calculated earlier — if you
  typed `!tomorrow` last week, it keeps meaning that day, even when you look at the item again now.
  A date that you type for the first time now counts from today.

A date chip is orange, with a different icon, as soon as the date is today or has passed — so that
the meaning does not depend on colour alone.

At the bottom of the date suggestions is, as when capturing, the line **Pick a date…**; it opens a
calendar and puts the chosen day in the text as a fixed date (for example `!2-10-2026`). This line
no longer appears once you have typed a complete date yourself.

## Commitment

Under the text there can be a block **COMMITMENT**. It depends on the item's situation, not on the
type. Both parts can be visible at the same time; other items have no block.

**If someone asked for it** (a person is set at "Requested by", or the type is **Request**):

- **Asked on «date»** — by default (grey) the day you captured the item. Tap it to choose another
  day; it is then shown in black, with a **×** (**Reset**) to go back to the capture day.
- **Promised: «text»** — by default (grey) the item's title. Tap it for the window **What did you
  promise?** with the field **Promised** ("Empty: the item's title."); choose **Save** or
  **Cancel**. If you leave the field empty, the title applies again.
- **Due: «date»** — the item's deadline, the first date (`!date`) in the text. If the item has no
  deadline, you see **Add a date**. If you choose a day, Offload puts `!d-m-yyyy` in the text, in
  place of the first date that was already there.

**If the item is waiting** (status **Waiting**, even without a person):

- **Waiting for «name»**, or "Waiting (for no one in particular)".
- **Expected: «date»** — the day you expect it, separate from the deadline. If you have none, you
  see **Add an expected date**. Tap to choose a day; **×** removes it. If that day has passed, the
  line turns orange, with a warning icon: "Expected: «date» · 3 days late". Such items are also on
  [Today](today.md).
- **silent for «n» days** — only while the item is silent (no expected day, and nothing has
  happened with it for a number of days), with the button **Chased**. It records that you have
  chased it; the period starts again. See
  [Waiting items that stay silent](today.md#waiting-items-that-stay-silent).

If a change fails, you see "Saving failed." **Windows:** the lines are in the Tab order; **Enter**
opens the window or the calendar.

## Completing, reopening and waiting

Next to **Complete** and **Wait for…** is the button **Where was I?**, to record where you left off
when you do something else for a while, see [Where was I?](where-was-i.md).

Under the text are one or two buttons:

- **Complete** sets the item to **Done**, with the message "Completed" and **Undo**. If the item is
  already completed or archived, this button is called **Reopen** and sets the item back to
  **Active**. For a recurring task you only complete this time, see
  [Recurring tasks](recurring.md).
- **Wait for…** sets the status to **Waiting** and first asks "Who are you waiting for?", with the
  people from the text at the top ("in the text"). **Skip** sets the status without choosing
  anyone; if you close the window, nothing changes. Under the name field is an optional line
  **Expected by…** ("optional") with a calendar: the item then gets exactly that expected day, or
  none if you skip it (an old day never comes back). If the item is already waiting and you choose
  another person, the expected day stays unless you choose a new one. This also applies to
  **Waiting** in the status chip. This button is not shown for an item that is already
  **Waiting**, **Done** or **Archived**. See also [People](people.md).

Under the text, every `@name` appears as a chip; tap it to open that person, see
[People](people.md).

## Links between items

If `[[title]]` is in the text, the item shows a chip with the current title of the linked item, see
[Linking an item to another item](capturing.md#linking-an-item-to-another-item). Tap the chip
to open that item.

- If the linked item is in the trash, the chip says "title · in trash". If you tap it, the item
  opens, and there you can restore it. The link stays in place.
- If `[[Something]]` points to nothing (or to more than one item), the chip says "Something · no
  item". A tap makes a new inbox item with that text, linked to this item. Without that tap,
  Offload never makes an item by itself. If it fails, you see "The item could not be created".

Under the buttons is **Linked from · n**, with the items that refer to this item; tap an item to
open it. Items in the trash are not included.

## Looks like another item

If this item's text looks a lot like an older item, you also see the line "Looks like another item"
here, with the comparison "Is this already there?", including the buttons **Open** (to the older
item) and **Link**, see [Capturing something](capturing.md).

## Photos

Under the note you can keep photos with an item, for example of a leaking tap or a garden plan.

### Adding a photo

Choose **Add photo** (on Windows **Add photo…**) next to the other buttons below the note.

- **Android:** a sheet opens with **Take photo**, which uses your device's camera app, and
  **From gallery**, which uses Android's photo picker. Offload asks for no permission for this.
- **Windows:** the Open window appears, with the file type **Images**.

You add one photo at a time. While Offload prepares it you see a tile "Processing photo…". Offload
stores the photo at most 1600 pixels wide or high, the right way up, without EXIF data or location,
encrypted, together with a small thumbnail. Photos can only be added here in the item, not while
capturing.

Some camera apps keep their own copy of the photo in their gallery. Offload cannot prevent that.

### Looking at your photos

The photos appear under the note in a row **Photos · 3** (with your number), oldest first.

- Tap a photo to see it full screen. You zoom with two fingers, by double tapping or with the mouse
  wheel. **Esc** closes the viewer on Windows.
- In the viewer, the trash button deletes the photo.
- A long press on a thumbnail (on Windows: right click, or **Del** on a thumbnail that has the
  focus) opens a menu with **View** and **Delete**.

### Deleting a photo

Offload asks **Delete photo?** "The photo is removed from this item. This cannot be undone."
Choose **Delete** or **Cancel**. There is no undo.

If a photo belonged to an item restored from a backup that did not contain the attachments, its tile
says "Attachment not in this backup".

### Photo messages

- "Offload cannot read this photo."
- "This photo is too large."
- "The photo could not be opened."
- "The photo was not saved."
- "The photo was not deleted."

## To the trash

At the top right is a menu (⋮) with **Revisit on…** and **Move to trash**; for a task also
**Complete and repeat…**, and for a recurring task **Stop repeating**, see
[Recurring tasks](recurring.md). The screen then closes and you see the message "Moved to trash"
with the button **Undo**. This message disappears by itself after five seconds; if you use a screen
reader (TalkBack on Android), it stays until you tap **Undo**; a new message then immediately takes
its place, so this one can no longer be undone. If undoing fails, you see the message "Undo failed;
the item is still in the trash."

## Sharing an item as text

At the top of the item is a share icon (**Share**). It opens the preview **Share item**, with the
text as it is about to leave. The item itself stays unchanged.

The preview removes the input signs from the text:

- A person loses the `@`: `@Jan` becomes "Jan", exactly as you typed it (also for a nickname, `@jj`
  becomes "jj").
- A date is written out in the screen language, for example "Thursday, October 1". The year is only
  included if it is not this year. An old `!tomorrow` keeps the date it had when you typed it.
- Tags (`#renovation`) are left out. If you switch on the switch **Include tags**, they are back in,
  as you typed them. Every time you flip the switch, Offload makes a new proposal, and changes you
  already made in the preview are then lost.
- A `\@Jan` with a backslash goes out as "@Jan".

You can edit the text in the preview; under the field it says "Changes here do not change the
item." Only what is in the field is shared. The first line that is not empty becomes the subject
(Android) and the suggested file name (Windows). If the field is empty, you cannot share. The
preview starts from the text in the text field, even if it has not been saved yet. Attachments are
not sent.

- **Android:** the button **Share** opens Android's share menu, where you choose an app. Offload
  itself is not in it.
- **Windows:** **Copy** puts the text on the clipboard, with the message "Copied to the clipboard".
  **Save as…** opens the Windows window to save a file (type **Text file** (\*.txt), with a name
  from the first line); afterwards you see "Saved". If you close that window without saving, the
  preview stays open.
- **Cancel** closes the preview.

If it fails, you see "Sharing failed. Please try again." and the preview stays open.

### Sharing for Offload on another device

At the top of the preview is the switch **As typed (for Offload)**, with the line "With @, #, ^, *
and fixed dates: Offload on another device makes an item with the same text and tokens of it." If
it is on:

- the field shows the text exactly as you typed it, with all signs: `@person`, `#tag`, `^project`,
  `*priority` and `[[link]]`;
- a date word becomes the fixed date that the item has now. A `!tomorrow` becomes for example
  `!10-10-2026`, so that the deadline stays on the same day, whenever the other device reads the
  text. Repeat words such as `!weekly` stay as they are;
- the switch **Include tags** disappears: tags always go along.

This is how you use it:

- **Android:** choose an app in the share menu, for example mail or a chat to yourself. On the other
  device, share the text from that app to Offload.
- **Windows:** copy the text with **Copy** and paste it into **Capture**.

The other device makes a new item in the inbox from it. The person, the deadline, the tags, the
`^project` and the priority come back.

Not included: the status, the type, a project you chose in the project picker (only a `^project` in
the text goes along), the note under the item and the "Where was I" note. An unknown `@name` becomes
a new person there. An unknown `^project` or `[[item]]` gets the usual label "no project" or "no
item".

On the same phone, Offload itself is not in the share menu: sharing to yourself would only make the
item twice.

## At the bottom of the screen

At the bottom you see when and how you captured the item, for example "Captured Sep 27, 2026, 2:43
PM via the app". Instead of "the app" it can also say: "the widget", "sharing", "the hotkey" or
"the tray", depending on how you captured the item.

## Windows

- **Ctrl+Enter** does the same as the button **Complete**/**Reopen**; for a recurring task it
  completes once.
- **Ctrl+Shift+P** opens **Where was I?**, see [Where was I?](where-was-i.md).
- **Esc** goes back to where you came from; if the suggestion list is still open, **Esc** first
  closes only that list.
- If the window is narrow, the item opens as its own screen over the list; **Esc** then closes that
  screen. From a wider window width the item opens in the right-hand part, next to the list, and
  **Esc** goes back to the list (the focus, not a separate screen), see
  [Switching between Today, Inbox, Projects, People and Insights](navigating.md).
