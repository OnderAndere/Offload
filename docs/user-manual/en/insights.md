# Insights

The **Insights** tab is the fifth place in Offload. It shows at a glance what is coming
(**Horizon**), what has stalled (**Standstill**) and where you stand with others (**People**). At
the top is today's date with the week number, for example "Mon, Oct 5 · wk 41".

You open **Insights** via the bar at the bottom (Android) or on the left (Windows), see
[Switching between Today, Inbox, Projects, People and Insights](navigating.md).

- **Windows:** **Ctrl+5**.

At the top you choose between four segments: **Horizon**, **Standstill**, **People** and
**Connections**. On **Windows**, **Horizon** and **Standstill** are side by side, see
[Windows](#windows).

## Horizon

The **Horizon** shows the coming weeks: this week (from today) and the five weeks after it. Each
main project has a lane of its own; items of sub-projects are in the lane of the parent project.
Items without a project are last, in the lane **No project**.

### The marks

Every item with a date is a mark in the week in which that date falls:

- a filled dot: **I deliver** (a deadline);
- a ring: **waiting for someone** (the expected day);
- an orange dot: **overdue** (the deadline has passed);
- an orange ring: **late** (you were waiting for something that should have come in already).

Overdue and late items are in the first week.

### Busy

Above each week is a bar with the number of items you have to deliver. From a number that you set
yourself (5 items by default, see [Busy from](#settings)) the week turns orange and says
**busy**. The deadline of an item you are waiting for counts as your deadline. Waiting itself never
counts.

### Looking at a week

Tap a week, or a cell in a lane, to see the list for that week. If an item has both a deadline and
an expected day in the same week, it appears as one row. Tap an item to open it, see
[Viewing and editing an item](item-detail.md).

## Standstill

**Standstill** shows a tile per main project, plus a tile **No project**. The bigger the tile, the
more open items. The colour says how long ago you last touched anything in that project, of any
open item: less than 1 week, 1–3 weeks, 3–6 weeks or more than 6 weeks. Every tile also shows the
name, the number and the age, so colour is not the only sign.

An item with a later "revisit" date does not count.

Below the tiles is **Untouched the longest**: the three open items you have not touched for the
longest time; from 6 weeks on, the age is shown in orange. With **To the weekly review →** you
start the [Weekly review](weekly-review.md).

Tap a tile to see the items of that project. With **Open project →** you go to the project, see
[Projects](projects.md). With **✕** or by tapping the tile again, you go back to **Untouched the
longest**.

## People

This segment shows the same balance as the **People** tab, without the search field: what you have
to deliver and what you are waiting for, per person. Tap a person to open them; with back you
return to the balance. See [People](people.md).

## Connections

**Connections** shows what is connected to one item, person or project: a graph with that one
point, the **focus**, in the middle. If you are working on the item "Paint the shed", for example,
you see the items it refers to with `[[…]]`, the items that refer to it, the project "Garden" and
the people involved, such as Jos from the garden club.

### What you see

- A solid line is **directly linked**; a dotted line is **through a step**.
- With **1 step** you only see what hangs directly on the focus. With **2 steps** you also see what
  hangs on those items, people and projects in turn.
- An item that is due today or overdue has an orange border and the name is followed by **today**
  or **overdue**.
- With **1 step** there are at most 12 points around the focus. With **2 steps** there are 8 direct
  points and 8 through a step. The rest is behind **+n more**; tap it for the full list, with for
  each point why it is linked. A number such as **+7** on a point means that even more hangs behind
  that point than is shown.
- Connections are not part of the [Weekly review](weekly-review.md).

### Choosing the focus

- Tap a point: that point becomes the new focus. You go back to the previous focus with back
  (Android: the back button; Windows: **Esc** or **Alt+←**).
- Tap **Change** to open **Choose a focus**. Search for an item, person or project. As long as you
  type nothing, **Recently opened** is at the top.
- Choose **Show connections** in the menu (⋮) of an item, a person or a project to start with that
  point as the focus.
- If you choose nothing, **Connections** starts at the item you opened last, as long as the app is
  running. If there was none, it says "How does it fit together?" with the button **Choose an
  item**. If the focus has nothing linked yet, it says **Nothing linked yet**.

### Looking at a preview

Press and hold a point for a **Preview**. In it you choose **Focus** (the point becomes the focus)
or **Open** (the item, person or project itself).

### Zooming

- **Android:** pinch to zoom.
- **Windows:** **Ctrl+scroll**, **Ctrl++** and **Ctrl+-** zoom; **Ctrl+0** fits the graph to the
  screen. Plain scrolling moves the graph.
- If the graph does not fit, the button **Fit** appears.

### Connections on Windows

- With the arrow keys you go from point to point. **Enter** makes the chosen point the focus; on
  the focus itself it shows a preview, and on **+n more** it opens the list. **Space** shows a
  preview.
- If you point at a point, a small preview card appears.
- The focus is shown on the right in the detail pane: the item, the person or the project.

## Windows

- **Horizon** and **Standstill** are side by side, across the full width (the segment is then
  called **Horizon and standstill**). That also applies in the first step of the Weekly review. In
  **People** the balance stays on the left and the person on the right.
- With **←** and **→** you choose a week or tile, as soon as the chart has focus: click it first.
  In the Weekly review, **←** and **→** change step elsewhere.
- With **↑** and **↓** you move through the list below it, with **Enter** you open an item and with
  **Esc** you go back.
- If you hold the mouse pointer over a dot or a tile, the titles appear.
- Search shows results with the detail pane next to it, see [Search](searching.md).

## Settings

Under **Settings** → **Insights** is **Busy from**: from how many items with a deadline in one
week the week is called busy (3 to 15; default 5). This setting applies per device, see
[Settings](settings.md).
