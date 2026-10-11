# Recurring tasks

Some tasks keep coming back: **Go running** every week, **Clean the cooker hood filter** every
month. You create such a task once. When you complete it once, it moves on to the next date by
itself.

## Making a task recur

Put one of these words in the text:

- `!daily` — every day;
- `!weekly` — every week, on the day of the week of the first time;
- `!monthly` — every month, on the day of the month of the first time.

The words of every display language are recognised, whichever language you have set. In Dutch they
are `!dagelijks`, `!wekelijks` and `!maandelijks`.

You can type the word yourself. In the button bar when capturing, **! repeat** shows only these
three words. If you type `!we…`, `!weekly` appears among the date words in the suggestion list, see
[Capturing something](capturing.md).

Example: `Go running !weekly !tue` — every Tuesday.

### When is the first time?

- If there is a date in the text (for example `!tue` or `!6-10`), the first date is the first time.
- If there is no date in it, the first time is the day on which you typed the word. If you have
  already completed it once, Offload uses the first completed time: if you remove the word and type
  it again, a weekly task stays on the same day of the week.
- A monthly task on the 31st falls on the last day of the month in a shorter month, and then goes
  back to the 31st.

### For which items?

Repeating works for a **Task** and for an item without a type (for example an item from the
widget). If you put the word in an **Idea**, **Request** or **Note**, the chip says "Weekly ·
repeats only for a task" and completing is just completing: the item does not keep coming back.

## Completing one time

If you complete a recurring task, only this time is done. You can do that with the **Complete**
button, on Android by swiping right on **Today**, on Windows with **Ctrl+Enter**, and in the
[weekly review](weekly-review.md). You see the message "Done · next time Tue, Oct 13" with
**Undo**.

- The status becomes **Active** (not **Done**) and the item gets the next date of the series: the
  first date that falls after this time and after today.
- If you let a time slip, you see one card that is late, never a pile of missed times.

## What you see

- **Card:** a chip "↻ weekly" and the date of this time.
- **Item:** a chip such as "Weekly · every Tue, since Sep 8" and the line "This time: …". That
  line is orange as soon as the date is today or has passed.
- **Done · n×:** a block with every time you completed it: the day, and "on time" or "time of … ·
  n days late". The five newest are there; with **Show all (n)** you see the rest.

## Complete and repeat…

Is an ordinary task (or an item without a type) done, but do you want it to come back? Open the
menu (⋮) and choose **Complete and repeat…**. Choose **Daily**, **Weekly** or **Monthly**; next to
each choice is the next date. Offload puts the word after your text and completes this time.
**Undo** reverses both.

On Android the choice opens as a panel at the bottom, on Windows as a window.

## Stopping the repetition

- In the menu (⋮) choose **Stop repeating**: Offload removes the word from the text and completes
  the item, with "Repeat stopped · done" and **Undo**.
- If you remove the word from the text yourself, it is an ordinary task with the date that is
  still in the text.
- If you set the status to **Done** or **Archived**, the series stops as well.
- If you reopen such an item, you get one time that is late.

## Elsewhere in Offload

- In the [weekly review](weekly-review.md), a recurring task never appears under **Stale**.
- The notification of the day comes on every date of the series, even if an earlier time is still
  open.
- Under **Horizon** you only see the next time, see [Insights](insights.md).

## Also new with Complete

If you complete an item in the item detail, you now always see the message with **Undo**, just as
on **Today**, see [Viewing and editing an item](item-detail.md).
