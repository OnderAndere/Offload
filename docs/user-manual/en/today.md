# Today

Offload opens on **Today**: everything with a deadline of today or earlier that is not yet done
or archived, including items that are still in your **Inbox**. Today's date, for example "Mon, Sep 28",
is next to the title when there is room for it. On a narrow screen or with large text it moves to
the top of the page, so the title is never cut off.

If nothing has a deadline of today or earlier, you see "Nothing for today" with the explanation
"No deadlines today and nothing overdue."

## Groups

Today also shows the new day straight away when the app comes back to the front. What you see is
arranged in groups. The first two have the oldest deadline at the top:

- **Back in your inbox · N** — items you parked with **Revisit on…** and that came back today,
  until you have processed them, see [Parking an item](revisit.md).
- **Overdue · N** — with an exclamation-mark icon, in orange: items whose deadline has already
  passed.
- **Today · N** — items with a deadline of today.
- **Should have come in · N** — items with the status **Waiting** whose expected day has passed,
  with the longest overdue at the top. The card shows in orange, with a warning icon, how many days
  late it is, for example "3 d late". You set that expected day on the item, see
  [Viewing and editing an item](item-detail.md#commitment). If a waiting item also has a deadline
  of today or earlier, it only appears in the group of that deadline.
- **Stays silent · N** — items with the status **Waiting** and no expected day that have not been
  touched for a while, with the longest silent at the top. See
  [Waiting items that stay silent](#waiting-items-that-stay-silent).

**High priority first.** Within **Overdue** and **Today**, items with high priority (`*high` or
`*1`, see [Capturing something](capturing.md)) are at the top. The rest follows in the usual
order: the oldest deadline first, then the order of capture. Only high priority moves up; items
with normal or low priority and items without priority keep their place among the rest. No extra
heading is added; the chip on the card shows the priority. The other groups and the daily
notification do not change because of this.

A list with only waiting items that are late therefore also counts as filled: you only see
"Nothing for today" when all groups are empty.

Every item shows the same card as in the inbox (title, chips for person/tag/date, how long ago
you captured it, and the project as a grey chip), and also the status (for example "Inbox" or
"Waiting"), so you can see at a glance where an item stands, see
[Capturing something](capturing.md). If you tap a card, the item opens, see
[Viewing and editing an item](item-detail.md).

## Where was I

If you have open **Where was I?** notes, see [Where was I?](where-was-i.md), a group
**Where was I · n** with a pause icon appears at the top of Today. It sits below the lines for
your inbox and the weekly review and below the birthdays, and above **Overdue**.

- **Which notes.** Notes of items that are still open (not done, not archived, not in the trash and
  not parked with **Revisit on…** until a later day) and of projects that are not archived. The
  newest is at the top. A note does not disappear because of age.
- **How many.** At most three are shown. If there are more, **+n more** shows the rest in the same
  place.
- **The card.** You see the title of the item (or of the project, with a folder symbol), the next
  step on one line, or "In mind: …" if you only filled in that field, and how long ago you saved
  the note.
- **Opening.** If you tap a card, the item opens with the **Where was I** card (with **Update** and
  **Resume**), or the project opens in **Projects**. On Windows an item opens in the right-hand
  pane. These cards have no buttons and you cannot swipe them.
- **Windows:** ↑/↓, Delete and Ctrl+Enter belong to the item cards. You reach a note card with the
  mouse or with Tab and open it with Enter.
- **Resume.** If you choose **Resume** in the item, the note disappears from Today.

A note is not a deadline: if nothing has a deadline, "Nothing for today" still appears below the
notes.

If you do not want the notes on Today, turn them off in [Settings](settings.md#today).

## Waiting items that stay silent

If you are waiting for something or someone and you have not set an expected day, Offload does not
know when it is late. That is why such an item goes **silent** when nothing has happened to it for
a number of days. It then appears on Today in the group **Stays silent · N**, below **Should have
come in**.

- **When is an item silent?** When it has the status **Waiting**, has no expected day and has not
  been touched for longer than the number of days you set. Touching means: changing the item,
  choosing **Still waiting** in the [Weekly review](weekly-review.md), or choosing **Chased**. You
  set the number of days under **Chase after** in [Settings](settings.md#reminders).
- **The card.** Besides the usual details it shows, for example, "silent for 12 days", and two
  buttons:
  - **Received** — the item has come in and becomes **Done**. You can reverse it with **Undo**.
  - **Chased** — you have chased it up. The period starts again and the item leaves the group until
    it is silent again. You briefly see the message "Chased"; you cannot undo this one.
- **Swiping** works like on the other cards on Today, see below.
- **Expected day.** Items with an expected day never appear here; once the day has passed, they
  appear under **Should have come in**.

The group is also there if you do not allow notifications or the switch for the notification is
off. See [Notification for silent waiting items](#notification-for-silent-waiting-items).

## The line for your inbox

If something is still in your **Inbox**, a line such as "3 in your inbox" with the button
**Process** appears at the top of Today:

- If you tap the line itself, you go to the **Inbox**.
- If you tap **Process**, you start the same processing screen as from the inbox, card by card, see
  [Processing your inbox](triage.md). When you finish or stop halfway, you return to **Today**
  instead of to the Inbox: the final button is called **Back** here.

If your inbox is empty, this line is not there.

## Birthdays

If someone has a birthday today, there is a line per person below the lines for your inbox and the
weekly review: "Anna turns 46 today", or "Anna has a birthday today" if you do not know the year.
If you tap the line, the person opens. The line is gone the next day. See
[Birthday notification](people.md#birthday-notification) for the related notification.

## Completing an item or moving it to the trash (Android)

On Android you swipe a card:

- to the **right** — **Complete**: the item gets the status **Done** and disappears from Today. For
  an item in **Should have come in** this means you have received it. If you reverse this with
  **Undo**, the item gets back exactly the status it had (for example **Waiting** instead of
  **Active**).
- to the **left** — **Move to trash**, with **Undo**, just like in the inbox, see
  [Capturing something](capturing.md).

For a recurring task, swiping right completes only this time, with the message "Done · next time
Tue, Oct 13", see [Recurring tasks](recurring.md).

On Windows this is not possible with swiping yet. A screen reader (TalkBack on Android, Narrator on
Windows) offers the actions "Complete" and "Move to trash" on every card, even without swiping.

The message with **Undo** disappears by itself after five seconds; if you use a screen reader
(TalkBack), it stays until you tap it.

## Starting the Weekly review

At the top of Today is an icon with a checklist (tooltip **Weekly review**). It starts the review
in five steps, see [Weekly review](weekly-review.md).

- **Android:** the icon is in the bar at the top.
- **Windows:** the icon is in the header of the list column; the tooltip is **Weekly review
  (Ctrl+Shift+W)**. That shortcut also works without the icon.

### The line for the Weekly review

If it is time for a new review, a line such as **Weekly review · last 9 d ago**, or **Weekly review
· not done yet** if you have never completed it, appears below the inbox line. Tap the line to start
the review. If it is not time yet, the line is not there. You set after how many days a review is
due again in [Settings](settings.md).

## Notifications for deadlines

On the day of a deadline you get one notification, by default at 09:00. On Android this is an
Android notification; on Windows a Windows notification, see
[Notifications on Windows](#notifications-on-windows).

- One deadline: **Deadline today**, with the title of the item. If you tap it, the item opens.
- More deadlines: **3 deadlines today** (the number varies), with the titles below, at most five.
  If there are more, it says, for example, **and 2 more** at the bottom. If you tap it, **Today**
  opens.

If a parked item has also come back, it is in the same notification, see
[Parking an item](revisit.md#notification).

If yesterday's notification is still there, it disappears as soon as the new one arrives: those
items are now on Today.

Items whose deadline has already passed (**Overdue**) get no new notification; they are on Today.
On Android, the lock screen only shows the number, never a title.

**Permission (Android).** Android asks once whether Offload may send notifications, as soon as
there is an open item with a deadline of today or later, or as soon as you park your first item
with **Revisit on…**. If you already have such items and you update the app, the question comes
right afterwards. If you choose **Don't allow**, you see the message "Without notifications you see
deadlines and returned items on Today." once, with the button **Settings**. Offload does not ask
again by itself afterwards; you can allow it later in Android or via **Settings** →
**Reminders**.

**Time.** On Android a notification can arrive up to ten minutes after the set time, and later if
the phone is in deep sleep: at the latest as soon as you use the phone. You find the time and the
switch under [Settings](settings.md#reminders).

### After a restart, update or different time zone (Android)

You do not need to open the app to get your notifications back. After a restart of the phone, an
update of Offload or a different time zone, Offload schedules them again by itself. What you need
to know:

- As long as you have not opened the app, such a notification only shows the count line (for
  example "2 deadlines today" or "Back in your inbox"), not the titles. If you tap it, the item or
  **Today** still opens. As soon as you open the app, the titles are back.
- If today's notification did not come through because the phone was off, it comes right after the
  phone has started. Notifications of earlier days no longer come; those items are on Today.
- After an update, a notification that Android had kept keeps its titles.
- If you change time zone, 09:00 simply stays 09:00 local time.
- If you stopped Offload with **Force stop** (in the Android app info), no notification comes
  until you open Offload again.

No item titles are stored for this: only dates, times and the count lines, encrypted on the
device.

### Notifications on Windows

- **When.** On Windows the notification comes as long as Offload is running. That also applies if
  you have closed the window: closing hides Offload in the system tray, and only **Quit** in the
  tray menu stops the app. Offload does not start by itself when you sign in.
- **How.** The notification appears at the bottom right, from "Offload", with the same texts and
  titles as on Android, for example **Deadline today** with the title of the item. A click brings
  Offload to the front and opens the item (in the right-hand pane) or **Today**.
- **After Quit or a restart of the PC.** No notification comes until you open Offload again.
  **Today** does show your items.
- **PC asleep.** If the time had passed while the PC was asleep, the notification comes when it
  wakes up, if it is still the same day. Notifications of earlier days no longer come.
- **Stays in the notification centre.** Windows shows the notification for a few seconds and then
  keeps it in the notification centre. Windows keeps notifications that have been shown, with their
  titles, until you remove them yourself.
- **Permission.** Windows does not ask for permission. If you do not want notifications, you can
  turn them off in Windows itself (**Settings** → **System** → **Notifications**) or with the
  switch in Offload.

### Notification for silent waiting items

When a waiting item goes silent, you get one notification about it on that day, at the time of the
daily notification. It never comes again for the same item.

- One item: **Still waiting for Joris · silent for 7 days**, with the title of the item below it.
  If you tap it, the item opens.
- More items: **3 waiting items stay silent**, with the titles below. If you tap it, **Today**
  opens.
- On the lock screen it only says **Waiting item stays silent** or the number, never a title or
  name.
- On Windows the same notification comes via the system tray, as long as Offload is running.

The switch **Waiting items that stay silent** is under [Settings](settings.md#reminders) and is
on by default.

## Navigating

Today is one of the places you can choose through the navigation, next to **Inbox** and
**Projects**, see
[Switching between Today, Inbox, Projects, People and Insights](navigating.md).
