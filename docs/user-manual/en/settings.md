# Settings

You open **Settings** with the gear at the top right of the home screen (tooltip
**Open settings**).

## About Offload

At the top of Settings you find **About Offload**. Below it you see which version and build you
have installed, for example "Version 0.6.2 (build 261)", and when that build was made, for example
"Built on Sep 29, 2026, 2:43 PM" (in your own time zone and screen language). This is handy for
checking that a new build was installed correctly. The build number goes up with every new build.
In a development version of the app (not built as a release) you see "Development build" here
instead.

### What Offload is for, and the licences

Below that is the row **What Offload is for, and the licences**. It opens the **About Offload**
screen. On that screen you see:

- the name Offload and the version;
- a short explanation of what Offload is for: emptying your head by quickly capturing ongoing
  work, what is still to come, ideas and requests from others, and processing them later, with
  everything on your own device, encrypted and without internet;
- **Licence** (GNU GPL 3.0 or later). Tap it to read the full licence text. It is in English, as
  the Free Software Foundation published it;
- **Licences of components**. This opens Flutter's licence overview with all bundled packages, the
  IBM Plex typefaces (OFL), the database library SQLite3MultipleCiphers with the third-party code
  inside it, and SQLite (public domain).

On Windows you go to a row with Tab, Enter opens that row and Esc takes you back.

## Help

Next to **About Offload** is the row **Help** ("The manual: how Offload works"). It opens this
manual inside the app, at the table of contents. In Help:

- Links between chapters, and to a heading inside a chapter, open inside Help.
- **Back** takes you back along the path you followed. On Windows Esc does the same.
- The button with the tooltip **Contents** goes straight to the table of contents.
- You can select the text.
- An internet address is never opened. Offload shows it as "Offload opens no internet addresses:
  ..." with the button **Copy**, so you can open it in a browser yourself.
- If Offload is in Dutch, a note at the top says "The manual is in English."

You can also open Help from any main screen with the **?** in the title bar, see
[Help on each screen](navigating.md#help-on-each-screen).

## Language

Offload has a Dutch and an English screen language. Under **Language** you choose between:

- **System language** — follows the language of your device. If you have set several languages on
  your device, Offload takes the first one it knows. If Offload knows none of them (for example
  only German), Offload shows English. This is the default.
- **English**
- **Nederlands**

**System language** is at the top of the list; below it the languages follow in alphabetical order
of their own name (**English**, **Nederlands**). Each language is shown in its own language. As
soon as you choose a language, the whole app switches at once; you do not have to restart the app.
Your choice is remembered: when you restart the app, the language is still as you set it.

> If saving your language choice fails, you see the message "The language choice could not be
> saved". The chosen language then stays active, but only until you restart the app.

## Weekly review

Under **Weekly review** you set two things, see [Weekly review](weekly-review.md):

- **Stale after** — how many weeks (1 to 12) an open item must go untouched before it appears in
  the last step of the review. The default is 3 weeks.
- **Due again after** — below it: after how many days (3, 5, 7, 10, 14, 21 or 28) the line on
  **Today** reminds you of a new review. The default is 7 days.

Both settings apply per device.

## Today

Under **Today** is the switch **Where was I on Today** ("Your open notes at the top of Today,
newest first."). It is on by default. If you switch it off, your notes no longer appear on Today;
they stay in the item or project, see [Where was I?](where-was-i.md). This setting applies per
device.

## Insights

Under **Insights** you find **Busy from** ("A week with this many items with a deadline, or more,
is busy on the Horizon."). Choose 3 to 15 items; the default is 5. A week with this many items to
deliver, or more, turns orange and is called **busy**, see [Insights](insights.md). This setting
applies per device.

## People

Under **People** you find **Old after** ("From this many days an open item with a person is old:
it stands out in the balance."). Choose 7, 10, 14, 21, 30, 45 or 60 days; the default is 21. An
open item that is this many days old or more shows its age at that person in orange, bold and with
a timer icon, see [People](people.md). This setting applies per device.

## Input

Under **Input** you set the **Prefix bar**: the row of buttons with **@ person**, **# tag**,
**! date** and **?** that you see when capturing, see [Capturing something](capturing.md). You
choose between:

- **Always visible** — the full bar with all buttons. This is the default.
- **Collapsed** — one slim row with only the signs @, # and ! and the question mark; you can still
  tap them. Next to it is a button to expand the bar to the full buttons and collapse it again;
  Offload remembers whether the bar is expanded or collapsed.
- **Off** — no bar.

This setting applies per device.

Below that is **Country for phone numbers** ("For numbers without a +country code, such as
06-12345678."). Choose from a list of 37 countries, shown for example as "Netherlands (+31)"; the
default is the Netherlands. The country determines how Offload reads a number without a
`+country code`: so that `06-12345678` and `+31 6 12345678` count as the same number, when
searching and for the label **Mobile**, see
[Phone numbers and email addresses](capturing.md#phone-numbers-and-email-addresses). Calling uses
the number as you typed it.

> If saving this setting fails, you see the message "The prefix bar setting could not be saved".
> The chosen setting then stays active, but only until you restart the app.

## Reminders

Under **Reminders** you set the notifications for deadlines and for revisiting, see
[Notifications for deadlines](today.md#notifications-for-deadlines) and
[Parking an item](revisit.md#notification). This section is available on Android and on Windows, with
the same choices:

- **Notifications for deadlines and revisits** ("On the day itself; one notification a day.") —
  the switch is on by default and applies to both. If you switch it off, no new notifications
  come. A notification whose time has already passed does still come.
- **Time** ("When that day's notification comes.") — tap it and use the time picker to choose when
  the notification comes. The default is 09:00.
- **Birthdays** ("On the day itself, at the time of the day's notification.") — on by default. If
  you switch it on and Android has never asked for permission for notifications, Offload asks for
  it now. See [Birthdays](people.md#birthday-notification).
- **Waiting items that stay silent** ("One notification on the day an item goes silent.") — on by
  default. If it is on, there is a waiting item without an expected day and Android has never asked
  for permission for notifications, Offload asks for it now. See
  [Waiting items that stay silent](today.md#waiting-items-that-stay-silent).
- **Chase after** ("That long without a change: then the item is on Today.") — after how many days
  a waiting item without an expected day is silent: 3, 5, 7, 10, 14 or 21 days. The default is 7.
  This choice determines the group **Stays silent** on Today, even when the switch is off.
- **Weekly review reminder** ("Only when the weekly review is due.") — off by default. If you
  switch it on and Android has never asked for permission for notifications, Offload asks for it
  now (Windows does not ask for permission). See
  [A reminder for the weekly review](weekly-review.md#a-reminder). Below it are two choices,
  which you can change as soon as it is on:
  - **Day** — a weekday, which you choose from a list like the other choices. The default is
    Friday.
  - **Time** — when the reminder comes, with the time picker. The default is 16:00.

If notifications for Offload are switched off in Android, you also see **Notifications are off in
Android** ("Deadlines and returned items are still on Today.") in this place, with the button
**Allow notifications**. It opens Android's notification settings for Offload. On Windows you can
switch notifications off in Windows itself (**Settings** → **System** → **Notifications**). These
settings apply per device.

## Backup and export

At the bottom of **Settings** is the section **Backup and export**, with four rows:
**Passphrase**, **Make a backup**, **Restore a backup** and **Export**. You can read about
**Export** [further down](#export). A backup is one file with all your data, encrypted with
your passphrase. Offload itself never connects to the internet; you choose where the file goes.

> A backup is a copy, not a sync. Restoring replaces everything on the device. Merging changes
> from two devices is not possible yet.

### Setting a passphrase

The **Passphrase** row shows **Set** or **Not set yet: needed for a backup**. Tap it to set or
change it:

1. Type the passphrase in **Passphrase** and once more in **Once more**. With **Show passphrase**
   you see what you type.
2. It must have at least 12 characters (for example four separate words) and must not contain a
   tab or a new line. An indicator **Strength** shows whether it is **too short**, **fair**,
   **good** or **strong**.
3. Confirm the warning "Without this passphrase the backup cannot be restored, not even by the
   app." with **I understand**, and choose **Save**.

If you change the passphrase later, older backups keep their old passphrase. The passphrase is
stored encrypted on this device and is not in the backup. You only need it to restore a backup on
another device.

### Making a backup

Choose **Make a backup**. If you have no passphrase yet, Offload asks for one first. If this
device holds attachments, a window **Make a backup** follows with a switch **With attachments
(≈ size)**, where the size is what they take now. It is on by default. Without them the backup is
smaller, but they are not in it. Choose **Continue** (or **Cancel**). If the device holds no
attachments, this step is skipped. Then you choose where the file goes. It is called `Offload-backup-<date>.offload`.

- **Android:** a sheet **Make a backup** opens with two choices:
  - **Share…**: the encrypted file goes to Android's share menu. You choose an app yourself, for
    example email, a chat or cloud storage. Afterwards you see "Backup ready to share". Android
    does not report whether the file was actually sent, so check that in that app. The shared copy
    stays in Offload's own storage: the next time you share it replaces it, and after more than 24
    hours it is removed the next time Offload starts. The file is always encrypted.
  - **Save on this device…**: the system file picker opens, for example to keep the file in
    Downloads or in another location of your choice.
- **Windows:** the **Save as** window.

Everything is in the backup, encrypted with your passphrase (the attachments too, if you kept the
switch on); device settings are not. While it is being made you see "One moment…" and capturing
waits briefly. From about 4 MB a progress bar shows, for example, "12.0 MB of 85.0 MB"; there is
no cancel button. After saving you see **Backup made**; if it fails, you see "The backup did not
work". If attachment files were missing or damaged, the message adds how many ("… 2 attachments
were missing and are not in it.").

Before it starts, Offload checks the free space for the database and the attachments you chose. If
there is too little, you see "Not enough free space: about X needed, Y free." and nothing is
written.

### Restoring a backup

1. Choose **Restore a backup** and then the file. On Android the file picker also shows other
   locations, such as Downloads, an SD card or USB stick, a NAS, or cloud apps (such as Google
   Drive or OneDrive) that offer their files there.
2. If the backup was made on this device with your current passphrase, Offload asks for nothing.
   If it comes from another device, or from before a change of your passphrase, Offload asks for
   **Passphrase of this backup**; type it and choose **Open**.
3. Offload shows **Replace everything?**, with the number of items in the backup and the date of
   the last change. If the backup holds attachments you also see "With N attachments."; they
   replace the attachments on this device, are encrypted again for this device and are checked.
   If the backup has no attachments and this device does have some, you see "This backup has no
   attachments; attachments that do not belong to the restored items will be gone." This device
   keeps its own files of the restored items. Choose **Restore** to continue.
4. Offload restarts with the data from the backup. Your settings on this device stay.

Before restoring, Offload checks that there is room for about twice the size of the backup file.
If not, you see "Not enough free space: about X needed, Y free." and nothing changes. A large
restore also shows a progress bar, without a cancel button.

If opening the restored data fails, the previous state comes back. After Offload starts you see
**Restore did not work**: "The restored backup could not be opened. Your data from before the
restore is back; nothing was lost."

Possible messages:

- "This passphrase does not fit, or the file is no Offload backup."
- "This backup comes from a newer version of Offload. Update the app first." A backup from an older
  version is simply brought up to date.
- "The file could not be read or written."

### Export

The **Export** row ("Readable, not encrypted (Markdown or JSON)") saves everything you made
yourself as one readable file, for example to read it in a text editor or use it in another
program. An export is **not encrypted**: anyone with the file can read everything. You cannot
restore an export in Offload; to restore data, use a [backup](#restoring-a-backup).

1. Tap **Export**. The **Export** window shows the warning "This export is not encrypted. Anyone
   with the file can read everything." You see it every time.
2. Choose the format:
   - **Markdown** ("Readable, in any text editor")
   - **JSON** ("Structured, for other programs")
3. Confirm with **Export**.
4. Choose where the file goes. It is called `Offload-export-<yyyy-mm-dd>.md` or `.json` (UTF-8).
   - **Android:** the sheet with **Share…** and **Save on this device…**, just like with a backup.
     After sharing you see "Export ready to share". The shared copy stays, **not encrypted**, in
     Offload's own storage: the next time you share it replaces it, and after more than 24 hours it
     is removed the next time Offload starts. After saving on the device you see "Export saved".
   - **Windows:** the **Save as** window, with file type "Markdown file" or "JSON file".

If it fails, you see "The export did not work".

**What is in it:** everything you made yourself, except the trash: items in every status, projects
(also archived ones), people with their other names, birthday, note and contact details, links
between items, the history of done dates of recurring tasks and your "Where was I" notes. **Not
included:** the trash, device settings and internal synchronisation data.

**Markdown:** at the top a title and a line with the date and the numbers. Then per project
(sub-projects after their main project; archived projects with "(archived)") the items per status,
then "Without project" and finally "People". Each item appears exactly as you typed it, so with
@Jan, !fri and #tag. On the line below are the type, deadline, priority, requested by or waiting
for, and the date of capture. Below that are the open "Where was I" note, for recurring tasks the
dates after "Done:", and the item's note as a quote.

**JSON:** meant for other programs, with a fixed structure (format "offload-export", version 1).

## Storage

At the bottom of **Settings**, below **Backup and export**, is the section **Storage**. It shows
how much space Offload uses on this device and how much you have captured. You cannot set or delete
anything here. The numbers are calculated as soon as you open **Settings**. Sizes are shown in kB,
MB and GB, in steps of 1000, as Android shows them too.

- **Database** ("Encrypted: everything you captured") — on the right is how big the encrypted
  database is.
- **Temporary files** ("A shared backup or export; removed after a day") — on the right is how big
  the copies are that Offload keeps temporarily after you have shared a backup or export, see
  [Making a backup](#making-a-backup). If Offload cannot measure it, you see **Cannot be
  determined**. There is no button to delete them: they disappear by themselves after a day. This
  row is only on Android; on Windows Offload keeps no temporary files.
- **Content** — how much you have captured, for example "8 items, 1 of them in the trash · 2
  projects · 3 people". Items in the trash count, because they are still in the database. Archived
  projects count as a project. People who have been merged do not count separately.

On Windows these rows do not take keyboard focus; use PageDown to scroll to them.
