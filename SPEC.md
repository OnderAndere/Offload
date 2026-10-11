# Offload — Specification (SPEC.md)

> **Status:** draft v0.4 · 27-09-2026 (v0.4: follow-up, overview and connections — REQ-046 to REQ-059, additions to REQ-010 and REQ-011, REQ-030 to five destinations, REQ-060 version in Settings; v0.3: sync through files, contact details, sharing an item — REQ-035 to REQ-045). Translated from Dutch to English on 28-09-2026 (PO decision); content unchanged.
> **Owner:** the product owner
> **Relation:** design decisions are in [`DESIGN.md`](DESIGN.md) (DD-xxx). Every requirement below refers to the DDs that realise it.
> **Language:** screen names and UI texts are given in English, as in `app_en.arb`; the Dutch source texts are in `app_nl.arb` (DD-009). Where the exact Dutch text matters, it is quoted.
>
> ⚠️ **AI disclaimer:** this document was drafted with the help of an AI assistant (Claude, Anthropic) based on the conversations with the product owner. The content has been discussed with the product owner but not yet formally reviewed by the architecture agent.
>
> **Confidence: medium-high** — the functional requirements were explicitly agreed with the product owner and the photo pipeline was taken from a proven spec; some technical choices (scheduled notifications on Windows) are still open, see §9.

---

## 1. Problem statement

A senior researcher and integrator constantly carries a large number of open threads in their head: ongoing work, future work, ideas and requests that others hand to them. Existing tools are either tied to the cloud (privacy risk) or too rigid (capturing takes too much effort, so it does not happen). The result: things slip through, and the head is used as storage instead of as room to think.

## 2. Persona

**Robin** — senior researcher and integrator, experienced software developer, former product owner.

- Highly technical; values efficient input (keyboard shortcuts, inline syntax) over wizard-like forms.
- Receives requests from many different people; "who asked this?" and "what am I waiting for?" are key questions.
- Works on an Android phone and a Windows 11 PC.
- Privacy is non-negotiable: data does not leave the device unless they explicitly send it out themselves.

## 3. Goals

| # | Goal | Measurable as |
|---|---|---|
| G1 | Capture thoughts without friction | Widget tap → saved item in ≤ 3 s (REQ-001) |
| G2 | Nothing slips through | The inbox is empty after a weekly review; every item has a status |
| G3 | Instant overview per person | "What is open with X?" answered in ≤ 2 taps (REQ-012) |
| G4 | Demonstrable privacy | The release build demonstrably has no `INTERNET` permission (REQ-003, CI check) |
| G5 | One way of working on two platforms | Same functionality on Android and Windows 11, with platform-native input (REQ-009) |

## 4. Non-goals (v1)

| Non-goal | Why |
|---|---|
| Automatic synchronisation between devices (LAN or cloud) | Breaks REQ-003; the data model is made sync-ready though (REQ-008) — see DD-003. Manual sync through encrypted files follows after v1 (REQ-035, DD-013) |
| Collaborating with others | Personal app. Sharing a single item as text is allowed (REQ-043); a recipient cannot write back |
| AI classification of items | Unpredictable and heavy; the inline syntax is deterministic (DD-004) |
| App lock / biometrics | Deliberate choice: the device lock is enough (DD-007) |
| Full contact management (CRM, addresses, sync with contacts) | The person profile stays a memory aid: birthday, free-form note (REQ-031) and contact details with vCard export (REQ-038, REQ-040). No sync with the contact list and no contacts permission. More would become a second app |
| iOS / macOS / Linux | Not needed; Flutter keeps the door open |
| Fetching link previews | Needs the network; URLs are stored as text |

## 5. User stories (prioritised)

1. As an integrator I want to capture a thought from my home screen in a few seconds, so that I do not interrupt my conversation or work.
2. As an integrator I want to share text or a link from another app to Offload, so that I do not have to retype a request from mail or chat.
3. As an integrator I want to add a person, tag or date while typing (`@Jan #renovatie !vr`), so that structure costs no extra step.
4. As an integrator I want to go through my inbox card by card and give each item a place with one gesture, so that triage is quick and calm.
5. As an integrator I want to see per person what they ask of me and what I am waiting on them for, so that I go into a meeting well prepared.
6. As an integrator I want a notification at a deadline and items that return to my inbox at a chosen moment, so that I do not have to remember anything.
7. As an integrator I want to attach a photo of a whiteboard or a PDF to an item, so that context stays together.
8. As an integrator I want to record a voice note that is transcribed locally, so that I can also capture hands-free on the go.
9. As an integrator I want to capture something on my Windows PC with a keyboard shortcut, so that I do not have to reach for my phone.
10. As an integrator I want to make an encrypted backup with a passphrase of my choice, so that I can restore everything if I lose a device.
11. As an integrator I want to keep my work phone and work laptop in step by exchanging an encrypted package through Signal or mail, so that I have the same overview on both devices without Offload going online.
12. As an integrator I want to add a phone number or email address to a person while capturing and export it later as a contact card, so that a new contact does not end up on a loose note.
13. As an integrator I want to share one item as text with someone, so that I can forward a request or agreement without retyping it.
14. As an integrator I want to record per request who asked it, when, what I promised and by when, and get a nudge when someone I am waiting for stays silent too long, so that agreements in both directions do not fade.
15. As an integrator I want to record in ten seconds where I was when I get interrupted, so that I can pick up later without searching.
16. As an integrator I want to see in the weekly review what has stalled and what is coming my way in the next weeks, so that nothing goes stale unnoticed or takes me by surprise.
17. As an integrator I want to link items and see from one item how it relates to questions, decisions and people, so that context stays together without maintaining a full knowledge base.
18. As an integrator I want to keep a journal of decisions per project that cannot be changed afterwards, so that I can later trace why something was decided.

**Edge cases:** empty inbox (positive confirmation, no blank screen), no speech model imported (clear message + import button, the audio is still kept), notifications refused (the feature works, reminder shown in the app itself), backup passphrase forgotten (not recoverable — explicitly warned).

## 6. Requirements

Priority according to MoSCoW. **AC** = acceptance criteria.

### 6.1 Capture

| ID | Requirement | Prio | DD |
|---|---|---|---|
| REQ-001 | Capture a thought in ≤ 3 s from the home-screen widget | Must | DD-010, DD-019 |
| REQ-002 | Receive text and links through the Android share menu | Must | DD-010 |
| REQ-006 | Offline voice input; audio never leaves the device | Should | DD-002 |
| REQ-017 | Global keyboard shortcut for quick capture (Windows) | Should | DD-010, DD-019 |
| REQ-018 | Capturing needs only text; type and project are optional | Must | DD-004 |
| REQ-019 | Inline syntax `@person #tag !date` with live chips | Should | DD-004 |
| REQ-028 | The inline syntax can be extended without breaking existing items | Must | DD-004 |
| REQ-033 | Suggestion list on a trigger: filters while typing, create from the list | Must | DD-004 |
| REQ-034 | Prefix bar as a memory aid, with the setting Always / Collapsed / Off | Should | DD-004 |
| REQ-039 | Phone number and email address recognised by pattern (without prefix) and linked to the `@person` in the same item | Should | DD-004, DD-012 |
| REQ-063 | Second home-screen widget "Offload bar": buttons to capture, to open *Today* and (3 cells) *Insights* (PO request 05-10-2026) | Should (v1, PO 06-10-2026) | DD-010, DD-019 |
| REQ-064 | Capture thoughts from a photo of handwriting (whiteboard, notebook): recognised offline into text, reviewed per thought before anything is saved (PO 09-10-2026) | Should (to be reviewed after spike S6) | DD-010, DD-002, DD-004 |

**AC REQ-001**
- Given the widget is on the home screen, When the user taps, enters text and confirms, Then the item is saved with status `inbox` and source `widget`, within 3 s measured from the tap (warm start).
- Keyboard focus is directly in the input field; there is no intermediate screen.
- A confirmed item is never lost, not even on a crash, reboot or damaged file, before it is in the database; an unreadable item is kept in quarantine and reported, never silently deleted. *(Added 24-09-2026 after spike S3, approved by the product owner.)*

**AC REQ-006**
- Audio is first stored locally (encrypted), and only transcribed afterwards.
- Without an imported model: the item is created with an audio attachment and the message "transcription available after importing a speech model".
- The transcription is searchable (REQ-011).

**AC REQ-019 / REQ-028**
- The raw input text is always kept as the source of truth; recognised tokens are derived metadata.
- A token that is not recognised stays plain text (no error message, no data loss).
- Adding a new token type only requires a new token definition in the registry (see DD-004), no change to the parser core or the data model.
- `\@` prevents recognition (escape).
- Date words work in the active UI language (NL: `!vr`, `!morgen`; EN: `!fri`, `!tomorrow`).

**AC REQ-033 (suggestion list)**
- A trigger (`@`, `#`, `!`) opens a list of at most five suggestions, which filters as you keep typing.
- The content comes from the token type itself: people, tags, or semantic date options (today, tomorrow, Friday, next week).
- No match → the list offers "New: create *&lt;typed text&gt;*", without going to another screen.
- The list never blocks: typing on filters, Escape closes, saving is always possible — also with an unfinished token (REQ-001).
- Windows: fully operable with the keyboard (arrows, Enter or Tab to choose, Escape cancels).
- New token types appear automatically in the list and the bar; there is no separate list implementation per token (REQ-028).

**AC REQ-034 (prefix bar)**
- A bar directly above the keyboard with a button per token: sign plus label (`@ person`, `# tag`, `! date`).
- Tapping inserts the sign at the cursor position and opens the suggestion list.
- Setting in Settings → Input with three values: **Always visible** (default), **Collapsed** (one line high, expandable, remembers its state) and **Off**.
- A `?` button on the far right opens the syntax overview: all tokens with an example line each.
- The bar costs no loading time when opening quick capture (REQ-001).

**AC REQ-039 (phone and email in the input)**
- `@Jan 06-12345678 jan@example.org` yields three chips; after confirming, the number and address are added to Jan as contact details (REQ-038).
- A number or address without an `@person` in the same item stays plain text with the chip "link to…"; nothing is ever lost (REQ-028).
- When saved as contact details, a phone number keeps the text as typed; its E.164 form (`+31…`) is derived, never stored (PO decision 02-10-2026, DD-012), so the raw text stays unchanged.
- For this the registry supports tokens recognised by pattern, without prefix (DD-004 point 3a). They appear in the syntax overview, not in the prefix bar.
- `+` is not a token prefix: `+31 6 …` is always a phone number (Q11).
- *PO decisions 02-10-2026 (T3.6, DD-004 point 12):* saving is confirming: after saving (quick capture) or leaving the item detail, newly typed numbers and addresses are added to the one `@person` in the text, with a message and Undo; never by the processing of old texts after an update. No person or several: nothing is added, the item detail offers "Link to a person". A Dutch mobile number gets the label *Mobile*. A number starts with `+` or `0` and has 9 to 15 digits. E.164 by an own rule with a short list of countries; the country for numbers without a country code is chosen in Settings (the Netherlands by default).

**AC REQ-063 (Offload bar)** (PO request 05-10-2026; PO decisions 06-10-2026, Q39–Q42; DD-010, DD-019; sketch `21-offload-bar`)
- A **second widget** in the widget picker, "Offload-balk" (EN "Offload bar"), next to the capture widget of REQ-001. **2×1** by default: *Vastleggen* (Capture) and *Vandaag* (Today); made wider to **3×1**: also *Inzicht* (Insights). One widget that scales (`RemoteViews` with a size map, as the capture widget); the 1×1 capture widget and its wide variant keep their function (their height changed, see *Height* below).
- **Vastleggen** opens the same native input window as the 1×1 widget (source `widget`) and does not start the Flutter app (REQ-001, hard rule 7, DD-010).
- **Vandaag** and **Inzicht** open the app on that destination, from a cold start and when the app is already open on another screen. *(Q40)* As a tap on a reminder does now (DD-005), except for typed text: an open triage or weekly review ends (choices made are saved already; an unfinished review does not count as completed), an open item detail saves on leaving; but an in-app capture screen with typed text stays on top, so nothing typed is lost, and the destination is set underneath (a screen below the capture screen, such as an open item, stays too). (A reminder tap now pops that screen and loses the typed text: found 06-10-2026, to be fixed with T1.11, which shares the path.) The app still starts on *Today* when opened any other way (DD-018 point 5): the widget is a request, not a remembered place.
- **App shortcuts (Q41a):** a long press on the app icon offers the same three actions (static shortcuts, no permission), with the same texts and icons.
- **Three buttons (Q42);** a fourth (e.g. Inbox on 4×1) is judged after use. The Windows tray menu stays as it is (Q41b).
- **Height (PO 06-10-2026, while building):** the widgets do not fill a tall launcher cell: the bar is a strip of 60 dp in the middle of its cells, and the 1×1 capture widget became a square tile of the same height (its wide variant a bar of that height), so they sit calmly next to the app icons.
- **No counts or content** on the widget: it reads no database and keeps no numbers outside it (DD-007).
- Icons: the capture glyph of DD-019 and, for *Vandaag* and *Inzicht*, the icons of the navigation bar; each button at least 48 dp with a description for screen readers (REQ-016); texts from the ARB files (DD-009).
- No new permission: `tool/check_permissions.sh` keeps passing.
- Checked on the emulator in 2×1 and 3×1, from a cold start and with the app open; TalkBack reads the buttons.

**AC REQ-064 (handwriting from a photo)** (PO decisions 09-10-2026; spike S6 tests the engine and the model; DD-010, DD-002, DD-004)
- **A new input channel:** a photo of handwriting becomes text in the input field, which then goes through the existing inline parser (DD-004) like typed text. The raw text stays the source (REQ-028).
- **(a) Literal transcription:** tokens (`@ ! # ^ *`) appear only where the user wrote them; the model adds, completes or corrects nothing. Letting the model *suggest* tokens is a later idea (BACKLOG, Parked).
- **(b) One line is one thought.** A thought starts with `-`; a line without `-` belongs to the previous thought. *(Whether this convention is needed, or plain lines are split well enough, is tested in S6; SPEC Q44.)*
- **(c) Review screen:** one candidate per thought, each to edit or skip; only after the user confirms are the kept candidates saved, as items with status `inbox`. Nothing is saved without the user.
- **(d) The photo is discarded after confirming:** it does not become an attachment, so this needs neither T5.1 nor M5. A copy in between exists only in memory or encrypted (CLAUDE.md hard rule 2).
- **(e) Fully offline:** the model is imported by hand and checked with SHA-256 against a list in the app, as for speech (DD-002); the app downloads nothing (REQ-003).
- **(f) Quick text capture is untouched:** the route of REQ-001 loads no model and no extra state (hard rule 7).
- **Size is a GO criterion (PO):** the model files (GGUF plus `mmproj`) take at most **1.5 GB** on Android (raised from 1 GB by the PO on 09-10-2026, after the first S6 results: the only model without errors on the synthetic test, Qwen3-VL-2B, takes 1.55 GB). The advice is the smallest model that is good enough; S6 sets quality against size.
- **Only with a model:** without an imported and verified model there is no button in capture, only an entry in Settings. A model that is gone or damaged: the button disappears and Settings says why.
- **Models are never in a backup** (DD-007): after a restore the app says the model has to be imported again. The model size is a row of its own in Settings → *Storage* (*Opslag*, T7.5).

### 6.2 Organising and finding

| ID | Requirement | Prio | DD |
|---|---|---|---|
| REQ-010 | Triage mode: the inbox card by card, with swipe actions | Must | DD-004, DD-018 |
| REQ-011 | Full-text search, also in transcriptions | Must | DD-001, DD-016 |
| REQ-012 | Person overview: open requests from and to someone | Must | DD-004, DD-015 |
| REQ-013 | Guided weekly review (inbox empty, go through *waiting for*) | Should | DD-004 |
| REQ-030 | Navigation with five destinations; the app opens on *Today* (revised 27-09-2026, Q18) | Must | DD-011 |
| REQ-031 | Person profile: birthday and free-form note fields | Should | DD-012 |
| REQ-038 | A person has contact details: phone numbers and email addresses (a list, with label), organisation and job title | Should | DD-012 |
| REQ-040 | Export a person as vCard 3.0 (`.vcf`, UTF-8) to import into the Contacts app | Should | DD-012, DD-014 |
| REQ-041 | Photo of a business card as an attachment to a person | Should | DD-006, DD-012 |
| REQ-042 | Read a business card offline and automatically (OCR) into contact details | Could | DD-012 (spike S5, Q14) |

**AC REQ-010 (triage, extended 27-09-2026)**
- A card is processed with one swipe or one tap to one of six destinations (Q20, PO decision 27-09-2026):
  - **task** → type *task*, status *active*;
  - **idea** → type *idea*, status *active*. A thought is an idea; the separate type *thought* (Q10) is dropped;
  - **request** → type *request*, status *active*, asking who asked it (REQ-046);
  - **waiting for** → status *waiting*, asking for whom; the type stays unchanged. An item without a type may leave the inbox: the type is optional (REQ-018), "empty" only means that no type was chosen;
  - **note** → type *note*, status *active*: findable, but action lists do not show notes. The button was called *Reference* until 29-09-2026; the PO renamed it to *Note* (NL *Notitie*), the same word as the type in the item detail;
  - **trash** → deleted (tombstone): gone from all lists, undoable immediately. Not *archive*: that keeps the item, finished or no longer relevant (an open item can be archived as well, PO decision 01-10-2026). Undo clears `deletedAt` with a new HLC; in sync that newer change wins, as every newer change of a tombstone wins (DD-013).
- Android: swipe actions plus buttons for all destinations (touch targets ≥ 44 dp). Swipe right skips the card (the item stays in the inbox), swipe left sends it to the trash; the six destinations are buttons (DD-018 point 3, PO decision 28-09-2026). Windows: fully with the keyboard (one key per destination, arrows for the next card); swiping with the mouse is not needed.
- For *request* and *waiting for* a person can be chosen straight away (suggestion list, REQ-033); skipping is allowed.
- Every triage action can be undone immediately; *trash* never deletes permanently (tombstone, DD-003).
- A possible duplicate is flagged on the card (REQ-053).
- *Later…* parks a card until a date ("revisit on", AC REQ-021; since T4.2); it is not a seventh destination and counts as processed.
- A card can be skipped without a choice; the item stays in the inbox. After the last card the app confirms that every card has been handled and says how many items were skipped (PO decision 28-09-2026).
- In the inbox list itself (outside triage mode) a row swiped left goes to the trash on Android, with the same undo; swiping right does nothing there. Windows: `Del` on the selected row (Q26, PO decision 28-09-2026).

**AC REQ-011 (search foundation, extended 27-09-2026, DD-016)**
- Searched are the titles, text and notes of items, person notes, contact details and transcribed speech.
- Search is diacritic-insensitive (`café` finds `cafe` and vice versa) and supports prefix search (`keur` finds `keuring`).
- Results are ranked by relevance (`bm25`), with a hit in the title above a hit in the text.
- The index is updated directly *after* saving, never during it (REQ-001); a deleted item (tombstone) can no longer be found afterwards.
- Demonstrated with an integration test on Android and Windows (FTS5, diacritic insensitivity, prefix, ranking).

**AC REQ-012**
- From a person two lists are visible: *requested by* (items where they are the requester) and *waiting for* (items with status `waiting` linked to that person).
- Reachable in ≤ 2 taps from the main screen or through an `@person` chip.
- *(PO decisions 01-10-2026, DD-018 point 7)* *People* is a destination. Its list holds every person alphabetically, with a filter field (name and alias); per person the number of open items in *requested by* and in *waiting for*, and how many of those are overdue; people with nothing open are shown subdued.
- A person also shows a third list, *mentioned in*: items that name the person with `@` (also through an alias) and are in neither of the two others. One item can be in both *requested by* and *waiting for*. Every list shows its open items first and its done items folded (for *waiting for*: open means status `waiting`, done means done items that waited on the person); archived items and the trash are not shown. Open counts leave out done, archived and notes, as in Projects; an overdue item in both lists counts once.
- The item detail shows and changes the requester and the person waited on; moving an item to *waiting for* there asks for the person (skipping is allowed). A tap on an `@person` chip in the item detail, or on a person in the search results, opens that person. Cards on *Today*, in the *Inbox*, in a project and in search results show the requester and the person waited on, unless the text already names them.
- A person can be renamed; the old name becomes an alias, so `@oldname` in existing items keeps pointing to the same person (DD-015). The name or an alias of another person is refused, with an offer to merge.
- *(T3.2b, PO decisions 01-10-2026)* A person A can be merged into another person B, after confirmation and with an immediate undo: every item, attachment and alias of A goes to B, the name of A becomes an alias of B, B keeps its name, and nothing of the profile is lost. A reference to A that arrives later (sync) counts for B.

**AC REQ-030**
- Bottom bar (Android) or side bar (Windows): *Today · Inbox · Overview · Projects · People*. At most five destinations (revised 27-09-2026, Q18).
- Search is in the top bar and reachable from every destination; it is *not* a destination.
- Capturing is not a destination: that goes through the widget, FAB or keyboard shortcut.
- Triage is a mode that starts from *Inbox*, or from the inbox line on *Today*, and ends again, not a separate destination.

**AC REQ-030 — Today** (PO decisions 28-09-2026, DD-018 point 4)
- *Today* shows every live item that is not done or archived and whose deadline is today or earlier, in any status (the inbox included), in two sections: overdue and today, each oldest deadline first. Items without a deadline are not on *Today*; a waiting item appears only through its own deadline. No days ahead.
- At the top a line with the number of inbox items and a way to start triage; hidden when the inbox is empty.
- Nothing for today: a positive confirmation, never a blank screen (§5).
- Android: swiping a card right completes the item, swiping it left sends it to the trash; both can be undone at once, and undo restores the exact previous status. Windows: the same with `Ctrl+Enter` and `Del` on the selected row (with the list pane, T2.6).
- Returned "revisit on" items (REQ-021) appear on *Today* in a group of their own (since T4.2, AC REQ-021). Later: waiting items that stay silent too long (AC REQ-047) also appear on *Today*.

**AC REQ-030 — Projects** (PO decisions 30-09-2026, DD-018 point 6)
- *Projects* is a destination. Its list starts with *Without project*, then the projects (at most two levels, sub-projects under their parent), each with its number of open items and of overdue items; archived projects are folded at the bottom.
- A project shows its sub-projects first, then its own items grouped by status (inbox, active, waiting for, scheduled, notes); done items are folded, archived items are not shown.
- An item gets or loses its project in the item detail and on the triage card, through one picker that can also create a project. Choosing a project in triage does not process the card.
- A project can be created, renamed, moved (within two levels), archived and restored, and deleted. Deleting keeps the items (they lose the project) and moves sub-projects to the top level; it can be undone at once. Names are unique per parent among the projects that are not archived, case-insensitive; a name that is taken is refused, and where a clash arises by itself the project gets a number.
- Counts of open items leave out done, archived and notes.
- Cards on *Today*, in the *Inbox* and in search results show the item's project.
- Capturing stays the same everywhere: a new item goes to the inbox without a project (REQ-001).

**AC REQ-013 (weekly review)** (PO decisions 01-10-2026, DD-018 point 8)
- The weekly review starts from *Today* (and on Windows with a key) and leads through four steps: the inbox empty (triage), the items *waiting for* (still waiting, done, or another person), deadlines (overdue and the next 14 days) and stale items (AC REQ-051). A step with nothing to do is skipped.
- Nothing is remembered between two reviews; the review can be ended at any step.
- *Today* has an icon for the review in its top bar (with a tooltip; on Windows it names the key) and, while a review is due, a line that starts it: due when no review was completed yet or the last one is N days ago or longer. N is a device setting, 3 to 28 days, 7 by default; the moment of the last completed review (end screen reached) is device-local (PO decisions 02-10-2026, DD-018 points 4 and 8).

**AC REQ-031**
- Per person: birthday (optional, day+month or a full date) and a free-form note field in Markdown.
- A birthday can get a yearly recurring reminder; it uses the same mechanism as REQ-020.
- No link with the device's contact list and no contacts permission.
- The note field is searchable through REQ-011.

**AC REQ-038 / REQ-040 / REQ-041 (contact details)**
- Phone numbers and email addresses are a list per person (kind, value, optional label such as "work" or "mobile"); several per person are possible. Organisation and job title are optional fields.
- Contact details are searchable through REQ-011.
- The export creates a vCard 3.0 file (UTF-8) with name, phone numbers, email addresses, organisation, job title and the birthday if any. The free-form note is not included.
- The file goes out through the share menu or "Save as…" (DD-014). The app asks for no contacts permission and never reads the contact list.
- An exported `.vcf` can be imported by the Contacts app on the user's Android 16 device (manual test; vCard 4.0 support varies per app, hence 3.0). Cyrillic names stay correct (AC REQ-005).
- A business card goes through the same photo pipeline as item attachments (REQ-024, REQ-027): encrypted, EXIF stripped, display version plus thumbnail.
- Without OCR (REQ-042) the user types the details over, with the photo in view.

### 6.3 Reminders

| ID | Requirement | Prio | DD |
|---|---|---|---|
| REQ-020 | Deadline notifications (inexact, window 10 min; Q38) | Must | DD-005 |
| REQ-021 | "Revisit on": the item returns to the inbox on that date | Must | DD-005 |
| REQ-022 | Configurable weekly-review reminder | Should | DD-005 |
| REQ-061 | Recurring tasks: a task can come back daily, weekly or monthly (PO request 02-10-2026) | Should (v1, M4; PO 02-10-2026) | DD-003, DD-004, DD-005, DD-018 |

**AC REQ-020**
- The app asks for the notification permission only when the first reminder is set.
- The app does not declare `SCHEDULE_EXACT_ALARM` or `USE_EXACT_ALARM`.
- A reminder comes within a window of 10 minutes after its time; while the phone is in deep sleep (Doze), Android may hold it until the phone wakes up (Q38, PO 04-10-2026).
- If the permission is refused: the reminder stays visible in the app (badge / "Today" list).
- After a restart of the phone, an update of the app or a change of time zone the planned reminders come back without opening the app; until the app is opened they show only the count, not the titles (T4.3, DD-005, PO 04-10-2026). After *Force stop* they come back when the app is opened.

**AC REQ-021 ("revisit on")** (PO decisions 04-10-2026, DD-005, DD-018 point 17)
- *Revisit on…* (NL "Terugzien op…") parks an item that is not done or archived until a date: from the item detail, in triage (*Later…*), in the step *Stale* of the weekly review and by choosing *Scheduled* in the status chip. The choices: tomorrow, next week (Monday; on a Monday the Monday after, on a Sunday the Sunday after, PO 04-10-2026), in a month, or a date from the date picker (from tomorrow).
- A parked item has status *scheduled* and the date. From the start of that day it returns to *inbox*, at the latest when the app starts or comes back to the front; a notification cannot change the encrypted database, so this check is the mechanism and the notification the signal.
- Changing a parked item's status by hand cancels the revisit; *Not any more* (NL "Niet meer terugzien") makes it active again. Parking can be undone at once.
- On *Today* a returned item is in a group "Back in your inbox" (NL "Terug in je inbox") until it is processed.
- On its date the item is in the one reminder notification of the day (AC REQ-020), at the time set; with deadlines on the same day it is one notification. The notification permission is also asked when the first item is parked.
- No inline token: revisiting is for existing items, not for what is being captured (PO 04-10-2026).
- Windows: returning works; the notification follows with T4.5.

**AC REQ-061 (recurring tasks)** (PO decisions 06-10-2026, Q29–Q35; DD-004 point 14, DD-005, DD-018 point 18; sketch `20-recurring-tasks`)
- An item of type *task*, or without a type yet (captured, not triaged), can repeat **daily, weekly or monthly**; fixed on the calendar. Examples: running every Tuesday, a daily exercise ticked off at the end of the day. On an idea, request or note the repetition does nothing (its chip says so); changing the type never moves the item's date, and making it a task again resumes the series.
- **A token in the text** (the raw text is the only source, DD-004, DD-018 point 1): `!dagelijks`, `!wekelijks`, `!maandelijks` (EN `!daily`, `!weekly`, `!monthly`). The words of **every** app language are recognised, so a change of UI language never stops a series. The prefix bar has a button *! herhalen* (EN "! repeat") that offers the three words; for a task that does not repeat yet the ⋮ menu of the item has *Afronden en herhalen…* (EN "Complete and repeat…"), which adds the token to the end of the text (a user edit) and completes this time, in one step with undo.
- **The first time** of the series is the first date token of the text; without one, the first time done, else the day the token entered the text. Weekly repeats on that weekday; monthly on that day of the month, on the last day of a shorter month (the 31st gives 30 November and 28 or 29 February, then the 31st again; never drifting). Dates are calendar dates: summer and winter time play no part.
- **Completing** a time records it on the item (*Gedaan*, EN "Done": when, and whether late) and moves the item to the next time: the first date of the series after both the completed time's date and today. Missed periods never pile up: a daily task left for three days is **one** overdue task, and after completing it the next is tomorrow. One item per series: search, projects and the archive hold it once (Q32, model B).
- **Elsewhere:** on *Today* on its date like any deadline; in the one notification of the day on every date of the series, also while an earlier time is still open (DD-005); never *stale* in the weekly review (AC REQ-051); on the Horizon only the next time; completing counts as a touch for the Standstill.
- **Stopping:** removing the token makes it an ordinary task with the date of its text; ⋮ *Herhaling stoppen* (EN "Stop repeating") removes the token and completes the item, with undo; *Afgerond* or *Gearchiveerd* in the status chip ends the series too (reopening gives one overdue time). What was done stays.
- **Undo** right after completing takes back the record and puts the item's date and status back exactly. *Afronden* in the item detail gets the undo message as well, for every item (PO 06-10-2026).
- **Sync (M9):** two devices that both complete the same time make the same record (a predictable id from the item and the date), never two items or two records.
- No exact alarms (DD-005): a reminder for a time uses the mechanism of REQ-020.

### 6.4 Attachments

| ID | Requirement | Prio | DD |
|---|---|---|---|
| REQ-023 | Attachments of any file type, encrypted per file | Must | DD-006 |
| REQ-024 | Take or import a photo; EXIF location stripped | Should | DD-006 |
| REQ-025 | Opening in an external app only explicitly; the temporary copy is cleaned up | Must | DD-006 |
| REQ-027 | Photos are stored as a display version plus thumbnail; no full-size original | Must | DD-006 |
| REQ-032 | Missing thumbnail: fall back to the display version and regenerate lazily | Must | DD-006 |

**AC REQ-024 / REQ-027 / REQ-032**
- One photo yields exactly two files: **display** (longest side ≤ 1600 px, JPEG q ≈ 82) and **thumbnail** (longest side ≤ 256 px, JPEG q ≈ 75). No original is left behind.
- List and grid views load only the thumbnail; detail and full-screen views the display version.
- Orientation: the EXIF rotation is applied to the pixels *before* all EXIF data (including GPS) is removed. A photo taken in portrait is upright in both files.
- The thumbnail path is **derived by convention** from that of the display version; there is no second column in the database (see DD-006).
- Deleting or replacing a photo deletes both files; no orphans are left behind (REQ-025).
- A thumbnail deleted by hand leads to a fallback view and is then created again; never a crash or a broken image.
- Backups contain no thumbnails; they are regenerated on restore.

### 6.5 Privacy and security

| ID | Requirement | Prio | DD |
|---|---|---|---|
| REQ-003 | No `INTERNET` permission in the release build | Must | DD-008 |
| REQ-004 | Database and attachments encrypted with a device-bound key, without an unlock prompt | Must | DD-007 |
| REQ-004b | Optional app lock (PIN) | Won't (v1) | DD-007 |
| REQ-015 | No telemetry, crash or analytics SDKs | Must | DD-008 |

**AC REQ-003**
- The release gate `tool/check_permissions.sh` fails if the release APK requests `android.permission.INTERNET` (or any other permission that is not allowed). While the repo is local, this check is part of the Definition of Done; CI on GitHub Actions follows on publication (backlog T8.7, PO decision 25-09-2026).

### 6.6 Backup and export

| ID | Requirement | Prio | DD |
|---|---|---|---|
| REQ-014 | Export to Markdown/JSON; backup encrypted with a passphrase (Argon2id) | Must | DD-007 |
| REQ-026 | Set and change the backup passphrase through Settings → Backup | Must | DD-007 |

**AC REQ-014 (export; PO decisions 09-10-2026, T7.3)**
- Settings → *Backup and export* (NL "Back-up en export") → *Export* (NL "Exporteren") exports everything the user made, outside the trash: items in every status, projects (archived ones too), people with aliases, birthday, note and contact details, `[[…]]` links, completed times of recurring tasks and "Where was I" notes. Not: sync internals (HLC, change log, tombstones), derived tokens, device settings.
- One format per export, chosen in the dialog: **Markdown** (one readable file) or **JSON** (one structured file); `Offload-export-<date>.md` or `.json`, UTF-8; Cyrillic stays correct.
- Markdown: per project (sub-projects after their parent, archived ones marked) the items grouped by status, then the items without a project, then the people; each item as typed (tokens intact) with a line of facts under it (type, deadline, priority, people, captured on).
- JSON: `"format": "offload-export"`, `"version": 1`, UUIDs, moments in ISO 8601 UTC, English keys, every field of the records that the app uses.
- The dialog warns every time that the export is not encrypted ("Anyone with the file can read everything."); the export button confirms it. No "don't show again".
- Android: *Share…* or *Save on this device…*, as for a backup; the shared copy follows the clean-up rule of SPEC Q12. Windows: *Save as*.
- Importing the JSON is not part of this; a backup is how data comes back (REQ-014).

**AC REQ-014 (backup with attachments; PO decisions 09-10-2026, T7.2b, DD-007)**
- A backup can include the attachments: when making one, a switch *With attachments (≈ size)* shows the actual total size of the attachments on this device; it is on by default and shown only when there are attachments.
- The backup stays one file, encrypted with the passphrase; attachments are never unencrypted on disk while making or restoring. Photos are included as display versions; thumbnails are made again after a restore.
- Restoring is all or nothing: the database and the attachments are replaced together, or nothing changes. A backup without attachments restored onto a device with attachments keeps this device's files that belong to a restored record (they still open with this device's key and are verified when read; PO 09-10-2026, revising "all gone"); the other files go, and the confirmation says so beforehand. Items whose file is in neither show *Attachment not in this backup*.
- An attachment whose file is missing does not stop the backup; the app says how many were missing.
- Before making a backup the app checks the free space and refuses with a message rather than failing halfway; with more than a few MB it shows progress. No cancel button in v1.
- A backup from a newer version of Offload is refused with a message.

**AC REQ-026**
- The user sets the passphrase on the first backup or beforehand through Settings → Backup.
- Entered twice, with a strength indicator; a minimum length is enforced.
- Explicit warning (confirmation required): "Without this passphrase the backup cannot be restored, not even by the app."
- A change applies to new backups; the app says that older backups keep the old passphrase.
- Restoring tries this device's own passphrase first and asks for the passphrase only when it does not open the file, as for a backup from another device or from before a change (PO decision 03-10-2026, DD-007). Restoring is always confirmed, as it replaces everything.

### 6.7 Platform, language and accessibility

| ID | Requirement | Prio | DD |
|---|---|---|---|
| REQ-005 | UI in Dutch and English; Dutch is the source language of the texts. **Ukrainian follows later** (added 24-09-2026, see Q9) | Must (NL/EN) · later (UK) | DD-009 |
| REQ-029 | Language choice in Settings (System, then English / Nederlands; later also Українська) | Must | DD-009 |
| REQ-009 | Buildable and usable on Windows 11 | Must | DD-001, DD-010 |
| REQ-016 | Light/dark theme, scalable text, TalkBack/Narrator | Should | DD-001 |
| REQ-060 | Settings show the version and build moment of the app at the top | Should | DD-008 |
| REQ-062 | A screen *About Offload*: what the app is for, its own licence and the licences of its components | Should | DD-008 |
| REQ-065 | The user manual inside the app: Settings → *Help*, plus a "?" per screen that opens the matching chapter (PO 09-10-2026) | Should | DD-020 |

**AC REQ-029** (product owner decision 25-09-2026, see Q17)
- By default the language choice is **System**: the app follows the device's system language.
- The device can have several preferred languages; the app takes the first of them that it offers (e.g. German, then Dutch → Dutch). If the app offers none of the preferred languages (e.g. only German), the UI becomes **English**.
- If the user chooses Nederlands or English, that language applies, regardless of the system language.
- Date and number formats follow the language that is active at that moment.
- In Settings **System** is at the top, then the languages alphabetically by their own name (English, Nederlands, later Українська).

**AC REQ-005 (Ukrainian, once it is added)**
- Cyrillic script is shown correctly everywhere: on all screens, in the widget, in notifications and in the Windows system tray, and in everything the app creates, such as exports (Markdown/JSON, UTF-8) and any PDFs.
- The fonts used contain the Cyrillic characters; nowhere boxes or replacement characters.
- An item with Ukrainian text stays correct after export and after backup and restore.

**AC REQ-009**
- Android: `minSdk = 33`, `targetSdk = 36` (both of the user's devices run Android 16).
- Windows 11 (x86-64) builds from the same codebase; all chosen packages support Windows (photo compression: see DD-006/D5, decided after spike S2).

**AC REQ-060** (product owner request 27-09-2026)
- At the top of Settings is *About Offload* with the version (from `pubspec.yaml`), the build number and the build moment: date and time in local time, in the format of the active language.
- The build number is determined automatically, not by hand: the number of commits up to and including the built commit. So it always rises (Android only accepts an update with a higher number) and it can be traced back to a commit (product owner decision 28-09-2026).
- The build moment is recorded when building, not when starting; every release build carries this information.
- A build without this information (development, tests) shows "Development build" (NL: "Ontwikkelversie").
- No new dependency and no network (REQ-003).

**AC REQ-062** (product owner request 02-10-2026; built 03-10-2026, T8.10)
- What Settings shows now under *About Offload* (REQ-060: version, build number, build moment) stays; the screen is extra, reached from that section.
- The screen says in two or three sentences what Offload is for (text proposed by the developer, decided by the PO), and shows the version again.
- **Licence of Offload: GNU GPL 3.0 or later** (`GPL-3.0-or-later`; PO decisions 02-10-2026: a free, open-source app; "or later" as the FSF recommends, Q37). The screen names the licence and shows its text, bundled in the app.
- *Licences of components* opens the licence overview that Flutter collects (`showLicensePage`, through `LicenseRegistry`): every shipped package plus the bundled fonts (IBM Plex, OFL-1.1). Translated by Flutter's own localisations, no extra package.
- Checked 02-10-2026: every shipped package (`tool/allowed_packages.txt`) is under MIT, BSD-3-Clause or Apache-2.0, all compatible with GPL-3.0; the OFL fonts may be bundled with it.
- No network (REQ-003); all texts through ARB (DD-009).
- *PO decisions 03-10-2026:* the purpose text reads (NL) "Offload maakt je hoofd leeg. Lopend werk, wat nog komt, ideeën en verzoeken van anderen leg je in een paar seconden vast, en je verwerkt ze als het jou uitkomt. Alles blijft op je eigen apparaat, versleuteld en zonder internet." The overview also lists SQLite3MultipleCiphers and SQLite, which Flutter does not collect; a test keeps the list complete for every shipped native library and typeface.

**AC REQ-065 (Help in the app)** (PO decisions 09-10-2026; DD-020)
- **Settings → *Help*** (NL "Help") opens the manual's index (`docs/user-manual/en/README.md`): a task-oriented table of contents, not a status overview.
- **One manual, English as its base (PO 09-10-2026, revising the earlier "the manual is Dutch"):** the manual is translated once into English and from then on only the English text is kept up to date. The Dutch text leaves the app; a Dutch translation, made from the English, follows with T8.5. Until a chapter exists in the app language, the viewer shows the English one with a short note ("The manual is in English", through ARB). The UI texts keep Dutch as their source (REQ-005, DD-009).
- **Rendering:** headings (with an id for anchors), paragraphs, lists, bold/italic, inline code and code blocks, links and tables; IBM Plex, the light or dark theme and the text size of the app (REQ-016). The renderer is shared with Markdown in notes (T10.10).
- **Links:** a link to another chapter or to a heading opens it inside the viewer; Back returns to where the user was. An external link only shows its URL; the app opens nothing on the network (REQ-003). Images and other assets come only from the app's own bundle.
- **Help in context:** a "?" on each screen opens the chapter, or the heading in it, that belongs to that screen. One table maps screen → `chapter.md#anchor`; a test fails when a chapter or anchor in it does not exist (any more).
- **The manual belongs to the build:** the bundled manual is the one written for the code being built. The documentation agent runs *before* a release build for use, and the build script refuses to make such a build when the manual does not belong to the current code (DD-020).
- What the manual's index used to list as "Status" and "Already built" moves to `docs/features.md` (English), kept up to date by the documentation agent, outside the app.
- The licence of the Markdown package is shown under *About Offload* (REQ-062). No network, no new permission.

### 6.8 Sync

| ID | Requirement | Prio | DD |
|---|---|---|---|
| REQ-007 | Automatic synchronisation between own devices | Won't (v1); manual: see REQ-035 | DD-003 |
| REQ-008 | Sync-ready data model (UUID, HLC, tombstones, change log) | Must | DD-003 |
| REQ-035 | Manual synchronisation between own devices through an encrypted change package (`.offload`), exchangeable through any channel (share menu, file) | Should (after v1) | DD-013 |
| REQ-036 | Pair devices with a one-time QR code (default) or a passphrase (fallback) | Should (after v1) | DD-013 |
| REQ-037 | The change log can be replayed on its own: the payload contains the full new field values | Must (before T1.6) | DD-003 |

**AC REQ-035 / REQ-036 (manual sync)**
- Use case: keep the work phone and work laptop in step without Offload itself making a network connection. The transport (Signal, mail, USB) is up to the user.
- A package contains the changes the other device does not have yet, tracked per paired device with the highest received HLC. A full package (everything) stays possible.
- The package is always encrypted (AES-256-GCM) with the pairing key; mail is not an end-to-end channel.
- Import is idempotent: reading the same package twice, or packages in a different order, gives the same end state.
- Conflicts: last-writer-wins per field on the HLC. If `rawText` changed on both sides, a conflict copy is created; text is never silently lost.
- Tombstones are included: deleted stays deleted.
- People or tags with the same name on both devices are shown as a merge proposal, not merged automatically.
- A package from a device that is not paired, with a wrong key or damaged, is refused with a clear message. The import is one transaction; the database is then left untouched.
- Receiving: Android through the share menu (REQ-002) or the file picker; Windows through the file picker, drag and drop or a file association.
- Pairing: one device shows a QR code with a random 256-bit key, the other scans it. Fallback: a passphrase, derived through Argon2id. Unpairing is always possible; after that a package from that device is refused.
- No network permission; `tool/check_permissions.sh` stays green. A `CAMERA` permission for scanning, if any, needs approval from the product owner (Q13).

**AC REQ-037 (change log)**
- Every log entry contains the entity, id, HLC, operation and the full new values of the changed fields; never a reference to the current database state.
- The state of every entity can be reconstructed from the change log alone. Test: replaying the log on an empty database gives the same content (derived tokens not counted).
- The format has a version number.

### 6.9 Sharing

| ID | Requirement | Prio | DD |
|---|---|---|---|
| REQ-043 | Share one item as text: share menu (Android), clipboard or "Save as…" (Windows), with an editable preview | Should | DD-014 |
| REQ-044 | Share an item with its attachments | Could | DD-014, DD-006 |
| REQ-045 | Show an item as a QR code on screen, to hand it over on the spot | Could | DD-014 |

**AC REQ-043**
- Tokens are converted: `@Jan` → "Jan", `!vr` → the date written out in the UI language. `#tags` are left out by default; a switch includes them. *Revised 09-10-2026 (PO):* `*priority` stays as typed, as built in T2.7 (`*priority` came later, T10.5, and never joined the tags switch); kept that way.
- The user sees and edits the text before sending; nothing goes out that was not in the preview.
- An edit in the preview does not change the item itself.
- Attachments are not included (see REQ-044).
- *Added 09-10-2026 (PO, T2.7a):* a switch *As typed (for Offload)* (NL "Zoals getypt (voor Offload)") shares the raw text with every token, a date word replaced by its fixed date (`!morgen` → `!10-10-2026`; repeat words stay); the tags switch is then hidden, tags always go along. Shared to Offload on another device, it becomes the same item text: person, deadline, tags, project token and priority come back; status, type, a project chosen in the picker, the note and the "Where was I" note do not.
- Sharing goes through `ShareChannel` (DD-014), the same abstraction as for the vCard (REQ-040) and the sync package (REQ-035).
- No new permission.

### 6.10 Follow-up, overview and connections

Added 27-09-2026 at the request of the product owner. The PO gave priority *high* or *medium*; the translation to MoSCoW (high → Should, medium → Could) is an assumption, to be confirmed. Priority high belongs to v1, priority medium comes after v1 (Q22, PO decision 27-09-2026); the place in the build order is in `BACKLOG.md`. Visual reference: [`docs/design/overview/`](docs/design/overview/README.md); the text below and DD-017 lead.

| ID | Requirement | Prio | DD |
|---|---|---|---|
| REQ-046 | Commitment per item: who asked it, when, what did I promise and by when | Should (PO: high) | DD-015 |
| REQ-047 | Waiting for: what others owe me, with a reminder (nudge) if it stays silent after X days | Should (PO: high) | DD-005, DD-015 |
| REQ-048 | People view with commitment balance and 1-on-1 preparation | Should (PO: high) | DD-015, DD-017 |
| REQ-049 | "Where was I" snapshot on a context switch, with a resume card when resuming | Should (PO: high) | DD-003, DD-018 |
| REQ-050 | Smart quick capture: person, deadline, project and priority in one line; relative dates; recognised parts visible before saving | Should (PO: high) | DD-004, DD-015 |
| REQ-051 | Stale detection: items not touched for X weeks appear in the weekly review | Should (PO: high) | DD-003 |
| REQ-052 | Overview (Horizon, Standstill, People, Connections), embedded in the weekly review and as its own destination | Should (PO: high) | DD-011, DD-017 |
| REQ-053 | Duplicate detection when capturing and in triage ("Does this already exist?") | Should (PO: high) | DD-016 |
| REQ-054 | Links between items with `[[…]]`, autocomplete and backlinks | Should (PO: high) | DD-004, DD-016 |
| REQ-055 | Markdown formatting in notes, including checklists and code blocks | Could (PO: medium) | DD-004 |
| REQ-056 | Open questions and hypotheses as an item type, with status open / tested / rejected | Could (PO: medium) | DD-004 |
| REQ-057 | Decision log / lab journal per project: append only, a correction is a new entry | Could (PO: medium) | DD-003 |
| REQ-058 | Advanced search: phrase and `NEAR`, snippets with highlighting, saved searches as smart lists | Could (PO: medium) | DD-016 |
| REQ-059 | Connections: local graph of links around one focus item, depth 1 or 2 | Could (PO: medium) | DD-017 |

**For all requirements in 6.10:** fully offline (REQ-003); all texts through ARB, Dutch by default and English supported (REQ-005); Android and Windows 11, with platform differences named per requirement (REQ-009); touch targets ≥ 44 dp, text contrast ≥ 4.5:1 and information never through colour alone (REQ-016). New entities and fields follow REQ-008 (UUID, HLC, tombstone, change log). Capturing never gets slower (REQ-001).

**AC REQ-046 / REQ-047 (commitment ledger)**
- Per item can be recorded: requester (person), moment of asking (by default the moment of capture, adjustable), what I promised (by default the title) and by when.
- Conversely an item can be *waiting for* a person, optionally with a date by which I expect it.
- Given an item is *waiting for* and nothing has changed on it for X days, When that period passes, Then a nudge follows through the reminder mechanism (REQ-020, inexact) and the item is on *Today*. X is configurable (default still to be decided); the nudge is visible in the app also without the notification permission. *PO decisions 04-10-2026 (T10.1, DD-018 point 10):* X is 7 days by default (3–21); only waiting items **without** an expected date (with one, the expected date and "Should have come in" apply); one notification on the day the item becomes silent, its own, with a switch; *Today* has a group "Stays silent".
- From the nudge I can finish the item as received or mark it "chased"; then the period starts again. ("Chased" has no undo, as *Keep* in the weekly review: putting the moment back would itself be a touch.)
- People come from the light person entity (DD-015); an unknown `@Name` creates the person.
- *PO decisions 02-10-2026 (T10.1 without the nudge; DD-018 point 10, sketch `10-commitments`):* one commitment per item; *by when* is the item's deadline (`!datum`); asked on = capture moment unless changed; what I promised = own short text, empty = the title; *expected by* a date of its own for waiting items, also in "Wacht op…"; a waiting item past its expected date shows on *Today* in a group "Should have come in". The block shows for items with a requester (or a request) and for waiting items, whatever their type. The nudge waits for T4.1.

**AC REQ-048 (people view and commitment balance)**
- At the top two totals: "I still have to deliver: N to X people" and "I am still waiting for: N from Y people".
- Below that, per person a diverging bar from a central axis: left (orange) what I deliver, right (blue) what I am waiting for, with the count in the bar. The direction (left/right) and the number carry the meaning, not only the colour.
- Per person the age of the oldest open item, highlighted (colour and font weight or symbol) above a configurable threshold, default 21 days.
- Tapping a person opens the 1-on-1 preparation: what I deliver and what I am waiting for, oldest and overdue items first, with date and project, plus the person note (REQ-031). Reachable in ≤ 2 taps (G3).
- Screen readers get a textual summary per person.
- Windows: balance and preparation side by side (list–detail, DD-011).
- *PO decisions 02-10-2026 (T10.2; DD-018 point 11, sketch `11-people-balance`):* people with open items first, the most open items on top, alphabetical when equal, then the others subdued; age of what I deliver from the day it was asked, of what I wait for from the capture day; threshold "Old after" 7–60 days, 21 by default, an age of N days or more counts as old; the 1-on-1 preparation is the person screen with the note on top and late and oldest first (to be judged after use); on Windows the person opens in the right pane.

**AC REQ-049 ("where was I" snapshot)**
- From an item or project one action starts a compact form with two fields: *next step* and *what I had in mind*. The focus is directly in the first field; capturing takes about 10 seconds.
- The form loads no lists or heavy state (REQ-001); a confirmed snapshot is never lost.
- Given there is a snapshot on an item or project, When I open that item or project again, Then a resume card with both fields and how long ago it was is at the top. The card can be closed ("resumed") or updated.
- Windows: Enter saves, Shift+Enter gives a new line (like quick capture).
- *Added 09-10-2026 (PO, T4b.2, a trial):* the open notes also show at the top of *Today*, newest first, at most 3 until unfolded; a tap opens the item or project. A setting of the device switches this off (on by default).

**AC REQ-050 (smart quick capture)**
- Person, deadline, project and priority can be given in one line, with the tokens from DD-004: `@person`, `!date`, `^project` and `*priority` (Q19, PO decision 27-09-2026). Example: `bel Jan @Jan !vr ^renovatie *hoog`. `#` stays tag.
- `^project` and `*priority` were reserved (DD-004 point 3) and become active with this; the recorded strict grammar applies to `*`.
- Relative dates are only recognised *with* `!`, at least *today*, *tomorrow*, weekdays (`!vr`, `!vrijdag`) and *next week*. `vr` or `morgen` without prefix stays plain text.
- Date words work in the active UI language (AC REQ-019): NL `!vr`, EN `!fri`.
- A token is one word. *Next week* comes as an option from the suggestion list (AC REQ-033); the typed word and the exact meaning are recorded in the ARB files in T2.2.
- An unknown project is created through "New: create …" in the suggestion list (AC REQ-033). Creating automatically on save applies only to people (DD-015).
- Recognised parts are visible as chips before saving (REQ-019); an unrecognised part stays text.
- Saving never waits for recognition (REQ-001); an unknown person is created after saving (DD-015).
- *PO decisions 02-10-2026 (T10.5, DD-004 point 11):* `^oudeschuur` and `^Oude-schuur` name "Oude schuur" (no case, spaces, `-`, `_`); `^renovatie/keuken` names a sub-project. A newly typed `^project` sets the project like a choice in the picker; a later choice in the picker wins, removing the token keeps the project. "New: create …" creates the project at once, as a top-level project; an unknown name stays text. `*1`/`*hoog` = high, `*3`/`*laag` = low, `*2` = normal; the priority follows the text. High, normal and low show as a chip on cards and in the detail (normal added later the same day, for consistency); no priority token, no chip; the order of the lists stays, except on *Today*: high priority on top of *Overdue* and *Today*, the rest in its order (PO 06-10 and 09-10-2026, T4b.1).
- *PO decision 03-10-2026 (after use):* an unknown `^word` is still not created on saving, but says so before and after saving: a chip "kas · geen project" (or "· meerdere projecten" when sub-projects under different parents share the name). In the item detail tapping it creates the project (name from the word, editable) with the item in it; in quick capture it only tells. An item whose `^word` names a project created later is linked at the next start.

**AC REQ-051 (stale detection)**
- An open item (not *done* or *archived*) that has not been changed for X weeks appears in a step of its own in the weekly review (REQ-013), oldest first, with its age. X is configurable per device, 1 to 12 weeks, 3 by default (PO decision 01-10-2026); notes count too.
- "Touched" means changed; only opening does not count. There is no column with the derived last touch (hard rule 6): it is the maximum of the time in the item's HLC and the moment of the last *Keep* or *Still waiting* (step 2 of the review).
- Per item: keep, archive, trash or *Later…* ("revisit on", AC REQ-021, since T4.2). Items with a future "revisit on" do not count. *Keep* is a user fact, not derived data: the moment is recorded as a field of its own that is synchronised (`items.reviewed_at`), because a change without content yields no HLC (DD-003).

**AC REQ-052 (Overview)**
- The Overview (UI name NL "Inzicht", EN "Insights"; Q27) has four segments: *Horizon*, *Standstill*, *People* (the balance of REQ-048) and *Connections* (REQ-059). It is embedded in the weekly review and reachable as the fifth destination in the main navigation (REQ-030, DD-011, Q18). *Connections* is not part of the weekly review: it needs a focus item and answers no review question (PO decision 04-10-2026, DD-018 point 15).
- **Horizon:** timeline of today plus six weeks; columns are ISO weeks (number and start date), one lane per top-level project (a subproject's items in its parent's lane; DD-018 point 12). Markers: filled blue dot = I deliver (deadline or commitment), open blue ring = waiting for someone else, filled orange dot = overdue. Orange means "needs my attention *now*" everywhere; the difference between delivering and waiting is in the shape (DD-017, Q21). Per week a small bar for how busy it is; a week above a configurable threshold gets the label "busy" (text, not only colour). Tapping a week shows the items of that week with person, date and project.
- **Busy (PO 02-10-2026):** the bar of a week counts only what I deliver: open items with a deadline in that week (the promised day of a commitment is its deadline, DD-018 point 10); what I wait for does not count (that work is with someone else). A week with **5 or more** such items is busy (as with "Old after", the threshold itself counts). Settings → *Insights* (NL "Inzicht") → *Busy from* (NL "Druk vanaf"), 3–15, default 5; a setting of this device.
- **Standstill:** treemap per top-level project (DD-018 point 12); area = number of open items, colour = time since the last touch in four classes (< 1 wk, 1–3 wk, 3–6 wk, > 6 wk). Every tile shows name, count and age as text. Tapping a tile shows the items of that project. Below it the three items untouched the longest, with age and a link to the weekly review.
- Windows: Horizon and Standstill side by side.
- Status: design v1 (sketches approved); re-assess after 2–4 weeks of use (DD-017).

**AC REQ-053 (duplicate detection)**
- After saving, asynchronously, the app searches the FTS index for very similar items; never before saving (REQ-001).
- A possible duplicate appears as the hint "Does this already exist?" (NL: "Bestaat dit al?") in the inbox and on the triage card, with the item found. Actions: open, link (REQ-054) or ignore.
- The app never merges automatically and deletes nothing.
- The hint itself is computed, not stored (hard rule 6). The choice "ignore" is user data though: it is stored and synchronised, so that the hint does not come back for that pair.

**AC REQ-054 (links)**
- `[[` opens a suggestion list of items, fed by the FTS index (prefix search); choosing one creates a link.
- Every item shows its backlinks: the items that refer to it.
- `[[…]]` is a token type in the registry (DD-004); the raw text stays the source of truth and an unknown link stays text.
- A link survives renaming its target.
- Light Zettelkasten: no global graph, no block references or embedded content.
- *PO decisions 03-10-2026 (T10.9, DD-004 point 13, sketch 14):* every item can link to every other item. The link is stored on the UUIDs with the label as typed, so renaming the target breaks nothing; removing `[[…]]` from the text removes the link. A target in the trash keeps its link and the chip says so. `[[…]]` never creates an item by itself: typed without choosing it links when exactly one item has that first line, otherwise it says "geen item" and the item detail offers to create one. *Koppelen* in the duplicate hint writes `[[…]]` into the text of the newer item. Backlinks in a section *Verwijst hiernaar* below the buttons; the inserted text is about 60 characters; a `[[ item` button in the prefix bar.

**AC REQ-055 (Markdown)**
- Notes of items and people are shown formatted: headings, lists, emphasis, checklists (`- [ ]`) and code blocks (monospace).
- A checklist point can be ticked in the view; that is an ordinary change through the change log.
- Images or other content from the internet are never loaded; a link is not opened or previewed automatically (REQ-003, §4).
- The inline syntax keeps working: `*priority` does not clash with Markdown emphasis (DD-004 point 3).

**AC REQ-056 (questions and hypotheses)**
- An item can get the type *question* or *hypothesis*, with a status of its own: open, tested or rejected.
- Filtering on type and status is possible; open questions per project are visible in the project.

**AC REQ-057 (decision log / lab journal)**
- Per project a journal of entries with a timestamp.
- Entries can only be added: not edited or deleted. A correction is a new entry that refers to the corrected one; the original shows that there is a correction.
- Entries are searchable (REQ-011) and are included in export, backup and sync.

**AC REQ-058 (advanced search)**
- Phrase search (`"oude schuur"`) and proximity (`NEAR`).
- Results show a fragment with the hit highlighted.
- A search can be saved as a smart list that updates live.
- Whether searching on part of a word (trigram tokenizer) comes follows from an evaluation; the outcome goes into DD-016.

**AC REQ-059 (Connections)**
- A local graph around one focus item with a depth of 1 or 2 steps (switch). There is no global graph.
- Node shape per type: project, task, decision, question/hypothesis, person, note; every node also has a text label with the type.
- Direct links are solid lines; the second step is dotted and dimmed (dimmed text still reaches 4.5:1).
- Tapping a node makes it the new focus; a long press shows a preview. Windows: the mouse pointer shows the preview, the keyboard moves the focus.
- Screen readers get the same information as a list ("directly linked", "through an intermediate step").

## 7. Information model (conceptual)

| Entity | Key fields |
|---|---|
| **Item** | `id` (UUID), `rawText`, `title`, `body` (Markdown), `type` (empty = not classified yet / task / request / idea / note; the type "thought" was dropped, a thought is an idea, see Q20), `status`, `source`, `dueAt`, `revisitAt`, `requesterId`, `waitingOnId`, `contextId`, `reviewedAt` (optional; last *Keep* or *Still waiting* in the weekly review, AC REQ-051), `priority` (optional; high, normal or low from `*hoog`, `*2`, `*laag` in the text, AC REQ-050), `hlc`, `deletedAt` |
| **Status** | `inbox → active → waiting → scheduled → done → archived` |
| **Person** | `id`, `name`, `aliases` (for `@` recognition), `birthday` (optional), `note` (Markdown, free field), `organisation`, `jobTitle` (both optional, REQ-038), `mergedIntoId` (optional; the person a merged person went into, DD-015) |
| **ContactDetail** | `id`, `personId`, `kind` (phone / email), `value` (as typed; E.164 is derived, never stored), `label` (optional: a standard label or own text), `sortOrder`, `hlc`, `deletedAt` (REQ-038, DD-012) |
| **Context/project** | `id`, `name`, `parentId` (max. 2 levels), `archivedAt` (optional; archived project, DD-018 point 6) |
| **Tag** | `id`, `name` |
| **Attachment** | `id`, `itemId` *or* `personId` (business card, REQ-041), `mimeType`, `size`, `encrypted file path` (photo: the display version), `pipelineVersion`. *No* thumbnail column: that path is derived (DD-006) |
| **ItemLink** | `fromId`, `toId`, `kind` |
| **Token** | `itemId`, `tokenType`, `rawValue`, `resolvedValue`, `parserVersion` |
| **ChangeLog** | append-only: `entity`, `id`, `hlc`, `operation`, `payload` (full new field values, REQ-037), `formatVersion` |
| **PairedDevice** | `deviceId`, `name`, `pairingKey` (encrypted with a key derived from the master key, DD-007), `highestReceivedHlc`, `highestSentHlc` — local, not synchronised itself (REQ-035, REQ-036) |

Extensions for REQ-046 to REQ-059 (commitment, expected-by date, snapshot, journal entry, saved search, priority, FTS index) are designed during the build and submitted for review; see the items in M10 of `BACKLOG.md`. The FTS index is derived data, like `tokens` (DD-016).

## 8. Traceability

| DD | Realises |
|---|---|
| DD-001 Stack | REQ-009, REQ-011, REQ-016 |
| DD-002 Speech (and models imported by hand) | REQ-006, REQ-064 |
| DD-003 No sync, but sync-ready | REQ-007, REQ-008, REQ-037, REQ-051, REQ-057, REQ-061 |
| DD-004 Hybrid model + inline syntax | REQ-010, REQ-012, REQ-013, REQ-018, REQ-019, REQ-028, REQ-033, REQ-034, REQ-039, REQ-050, REQ-054, REQ-055, REQ-056, REQ-061, REQ-064 |
| DD-005 Reminders | REQ-020, REQ-021, REQ-022, REQ-047, REQ-061 |
| DD-006 Attachments and photos | REQ-023, REQ-024, REQ-025, REQ-027, REQ-032, REQ-041, REQ-044 |
| DD-007 Key management and backup | REQ-004, REQ-004b, REQ-014, REQ-026 |
| DD-008 Network-free build | REQ-003, REQ-015, REQ-060, REQ-062 |
| DD-009 Internationalisation | REQ-005, REQ-029 |
| DD-010 Input channels per platform | REQ-001, REQ-002, REQ-009, REQ-017, REQ-063, REQ-064 |
| DD-011 Navigation and screen structure | REQ-030, REQ-052 |
| DD-012 Person profile | REQ-031, REQ-038, REQ-039, REQ-040, REQ-041, REQ-042 |
| DD-013 Manual sync through packages | REQ-035, REQ-036 |
| DD-014 Sharing through one ShareChannel | REQ-040, REQ-043, REQ-044, REQ-045 |
| DD-015 People as a light entity | REQ-012, REQ-046, REQ-047, REQ-048, REQ-050 |
| DD-016 Search in two steps | REQ-011, REQ-053, REQ-054, REQ-058 |
| DD-017 Visualisations | REQ-048, REQ-052, REQ-059 |
| DD-018 Screen layout (Q5b) | REQ-010, REQ-018, REQ-030, REQ-033, REQ-034, REQ-053, REQ-054, REQ-061 |
| DD-019 Widget icon | REQ-001, REQ-017, REQ-063 |
| DD-020 Help in the app | REQ-065 |

## 9. Open questions

| # | Question | For | Blocking? |
|---|---|---|---|
| Q5b | Detailed layout per screen (Today grouping, triage gestures, Windows panes) — *in progress, per screen in DD-018; item detail decided 27-09-2026 (text first), inbox row 28-09-2026 (card), triage card 28-09-2026 (button grid), Today 28-09-2026 (two sections), navigation and Windows two panes 29-09-2026 (rail with capture and settings, only built destinations); all screens of the round decided* | Product owner + design | Yes, per screen before it is built |
| Q6 | Design system: own style or derived from Spirit Safe? | Product owner | No |
| Q7 | Display size: 1600 px (port spec) or 2048 px for readable whiteboards and diagrams? | Product owner | No (starts at 1600, configurable) |
| Q8 | Content of the onboarding: which screens on first start, and what role does the syntax overview play in it? | Product owner | No |
| Q9 | Ukrainian as the third UI language (REQ-005, REQ-029): who checks the translation (native speaker)? Do the date words of the inline syntax (`!пт`, `!завтра`) and speech recognition (REQ-006) also apply in Ukrainian? | Product owner | No (before T8.6) |
| Q12 | Sharing files (vCard REQ-040, attachments REQ-044): how long does a temporary copy stay? The receiving app sometimes reads it only later (mail draft), so cleaning up on return or on the next start can give a broken attachment | Architecture agent + product owner | **Partly answered 09-10-2026 (PO, DD-014) for the backup (encrypted):** one shared file in `cache/share/`, replaced by a new share, removed at app start when older than 24 hours. **The same for the export (unencrypted, PO 09-10-2026, T7.3):** the folder is the app's private storage on an encrypted device. Still open for the vCard and attachments; no (before T3.7 and REQ-044) |
| Q13 | QR pairing (REQ-036): scanning in the app needs the `CAMERA` permission and a scanning library (ML Kit may bring Google dependencies; alternative e.g. zxing-cpp through FFI). Allow it, or pair only through a passphrase? | Product owner + architecture agent | No (before T9.1) |
| Q14 | OCR for business cards (REQ-042): ML Kit (Android only; check permissions and GMS), Windows.Media.Ocr (does it work without package identity? see Q2) or Tesseract through FFI (both platforms). Spike S5 | Architecture agent | No |
| Q15 | Device id after restoring a backup (REQ-014, REQ-035): a restored database on a new device must get a new device id (HLC node), otherwise two devices share one id and their HLCs clash in sync. How does the app recognise a restore, and what happens to existing pairings? | Architecture agent | **Answered 03-10-2026 (PO, DD-007):** a backup holds no `local_state`; restoring keeps this device's own and always gives a new device id. Pairings do not exist yet (M9 decides then). |
| Q22 | **Order after v1.** First the manual sync (M9, REQ-035/REQ-036) or first the medium-priority items from M10 (REQ-055 to REQ-059)? Advice: M9 first, because the PO already works on two devices | Product owner | No |
| Q24 | **Deadline with or without time (REQ-020).** `!vr` yields a date without time, stored as midnight UTC in `due_at` (DD-004 point 8). A deadline with a time that happens to fall on 00:00 UTC cannot be told apart from it. Deadline notifications need that difference, plus a notification moment for a deadline without time (e.g. 09:00 local). A column or flag of its own, or another convention? | Architecture agent + product owner | **Answered 04-10-2026 (PO, DD-005):** in v1 a deadline stays a date without time; its reminder comes on that day at a set time of day (Settings → Reminders, 09:00 by default). A time in a deadline comes later and then gets a column of its own, not a convention on `due_at`. |
| Q25 | **16 px variant for the Windows system tray (`.ico`).** Downscaled to 16 px the `+` of the widget glyph (DD-019) closes up into a dot: readable as "dot in a tray", but not sharp. Draw a hand-pixelled 16 px variant for the tray icon, or accept the downscaled one? | Product owner (design) | No (before T8.9) |
| Q28 | **Git history before publishing on GitHub.** The sample data in tests, sketches and docs was made fictional on 02-10-2026 (nothing traceable to the PO's work), but earlier commits still contain the old examples. Rewrite the history (e.g. `git filter-repo`, or publish a fresh squashed history) before a first push to a public repository? | Product owner | **Answered 11-10-2026 (PO):** a fresh history. The content of the last private commit (tree `7883e02`) became the first commit of a new repository; the private history stays local and is never pushed. The build number keeps rising through a base (DD-008, T8.16). |
| Q29 | **Recurring tasks (REQ-061): where to set the repetition.** Only when completing ("Complete and repeat…", the PO's first idea), or also when capturing and in the item detail? The raw text is the only source (DD-004, DD-018 point 1), which points to a token, e.g. `!dagelijks`, `!wekelijks`, `!maandelijks` (or `!elke maandag`), with a button that puts the token in the text | Product owner + design | **Answered 06-10-2026 (PO):** a token (`!dagelijks`/`!wekelijks`/`!maandelijks`, EN `!daily`/`!weekly`/`!monthly`), recognised in every app language; a button *! herhalen* in the prefix bar (sketched as ↻) and *Afronden en herhalen…* in the ⋮ menu → AC REQ-061, DD-004 point 14. |
| Q30 | **Recurring tasks: rhythm.** Fixed on the calendar (every Monday, the 1st of the month) or counted from completing (7 days after the last time)? Possibly both, as two token forms | Product owner | **Answered 06-10-2026 (PO):** fixed on the calendar only; "N days after completing" may come later as a second token form, the rhythm is modelled with a mode for it → DD-004 point 14. |
| Q31 | **Recurring tasks: missed periods.** A daily task left for three days is one overdue task, not a pile of three (draft AC). When it is finally done, is the next one due tomorrow (from today) or on the next calendar date of the series? | Product owner | **Answered 06-10-2026 (PO):** one overdue task; the next time is the first date of the series after both the completed time and today → AC REQ-061. |
| Q32 | **Recurring tasks: model.** Does the same item move on to the next date (lists stay clean; history only in the change log), or does every occurrence become a new item (history visible: when done)? A middle way: one series item plus a light record per completed occurrence | Architecture agent + product owner | **Answered 06-10-2026 (PO, advice of the architecture agent):** one series item plus a record per completed time (`item_completions`); the history shows in the item as *Gedaan* → DD-003, DD-018 point 18. |
| Q33 | **Recurring tasks and sync (DD-003).** When two devices both complete an occurrence and create the next one, no duplicates may arise: a predictable id per series and date (e.g. a UUIDv5 from the series id and the date) makes both creations the same row | Architecture agent | **Answered 06-10-2026:** the record of a time gets a UUIDv5 from the item id and the date, so two devices make the same row; what M9 must do with an insert of an existing row is recorded in DD-003. |
| Q34 | **Recurring tasks and the rest of the app.** *Today* (point 4: due today and overdue), stale items in the weekly review (a repeating task is never stale), the reminders of M4 (one notification per occurrence?), the Overview's Horizon (T10.7: one marker per occurrence or one per series?) | Product owner + design | **Answered 06-10-2026 (PO):** a line in the day notification on every series date (also while a time is open); never stale; the Horizon shows the next time only; completing is a touch → AC REQ-061, DD-005. |
| Q35 | **Recurring tasks: stopping and undo.** How does a series end (remove the token, a menu action "Stop repeating", an end date)? What does Undo after completing do (take back the completion and remove the next occurrence)? | Product owner | **Answered 06-10-2026 (PO):** remove the token, ⋮ *Herhaling stoppen* (token out and complete, undo) or done/archived in the status chip; undo takes back the record and restores date and status → AC REQ-061. |
| Q39 | **Offload bar (REQ-063): v1 or later, and where in the order?** Proposal: v1, as task T1.11 right after T4.7 (small: one provider, two layouts, one launch path), so it is in use during the weeks of M4b | Product owner | **Answered 06-10-2026 (PO):** v1, as T1.11 right after T4.7 (a `task` bump; the M4 milestone stays with T4.7). |
| Q40 | **Offload bar: opening a destination over an open screen.** Proposal in AC REQ-063: as a reminder tap (modes end, the detail saves, a capture screen with text stays on top) | Product owner | **Answered 06-10-2026 (PO):** as proposed in AC REQ-063: modes end, the item detail saves, a capture screen with typed text stays on top. |
| Q41 | **Offload bar: the same actions elsewhere.** (a) App shortcuts on a long press of the app icon (Vastleggen, Vandaag, Inzicht) in the same task? (b) Windows: *Vandaag* and *Inzicht* in the tray menu (T8.9), next to *Nieuw item* / *Openen* / *Afsluiten*? | Product owner | **Answered 06-10-2026 (PO):** (a) yes, app shortcuts with the same three actions in T1.11; (b) no change to the Windows tray menu. |
| Q42 | **Offload bar: a fourth button later** (e.g. Inbox or the weekly review on 4×1), or three at most? | Product owner | **Answered 06-10-2026 (PO):** three buttons for now; the layouts are built from a list of actions, a fourth is judged after use (M4b). |
| Q43 | **Image input before speech?** If spike S6 gives GO, image input (REQ-064) comes before speech (M6), as proposed in `BACKLOG.md` (M6a) | Product owner | No (after S6) |
| Q44 | **Handwriting: is the `-` convention needed (REQ-064 b)?** Or does the model split plain lines into thoughts well enough, including a thought that runs over two lines? | Spike S6 → product owner | No (after S6) |
| Q45 | **Cropping and straightening a photo.** Should Offload let the user crop a photo and straighten a skewed one (a whiteboard or notebook photographed at an angle, by pointing at its four corners) before it is kept or read? Not in REQ-024/027 now. Spike S6 measures whether straightening helps the handwriting model; then decide whether it belongs to M6a, and whether the photo capture of T5.3 gets it too (a simple *rotate 90°* would be cheap there) | Spike S6 → product owner (raised by the PO 10-10-2026) | No (after S6) |
| Q38 | **Reminder window (REQ-020) against Android.** REQ-020 asked for a window of at most 5 minutes, but from Android 12 an inexact alarm (`setWindow`) has a window of at least 10 minutes, and in deep sleep (Doze) Android holds it until a maintenance window or until the phone is woken. Being on time in deep sleep needs exact alarms, which DD-005 rules out. | Architecture agent + product owner | **Answered 04-10-2026 (PO):** a window of 10 minutes; in deep sleep the reminder may come later, at the latest when the phone is used. REQ-020 and its AC updated, DD-005 records the limit. |

**Answered since v0.1:** Q2 (Windows notifications while the app is fully closed: no MSIX needed, but an app id in the registry, a COM component for the click and texts kept by Windows; not for v1 — reminders come through the tray icon while the app runs, DD-005, T4.5; looked at again with T8.3; PO 04-10-2026), Q37 (licence GPL-3.0-or-later; PO 02-10-2026), Q27 (the Overview tab is NL "Inzicht", EN "Insights"; the weekly review keeps "Weekoverzicht"; PO 02-10-2026), Q16 (E.164: an own rule with a short list of countries, the home country a setting, the Netherlands by default → DD-004 point 12; PO 02-10-2026), Q1 (old numbering, photo parameters → DD-006), Q1 (compression library → Flutter engine codec + `package:image`, DD-006/D5, spike S2, 24-09-2026), Q3 (API level → `minSdk 33`, REQ-009), Q4 (whisper model → `ggml-small-q5_1`, 181 MB, DD-002, spike S4, 24-09-2026; measure the speed on the phone in T6.1), Q5 (navigation structure → REQ-030, DD-011), Q10 (item type: empty = not classified yet, `thought` = deliberately classified as a thought → DD-004; PO 25-09-2026; revised by Q20: `thought` is dropped), Q11 (prefix for priority → `*` with a strict grammar; `+` freed for phone numbers → DD-004; PO 25-09-2026), Q17 (default language and fallback language: by default the app follows the first preferred language of the device that it offers; otherwise English → AC REQ-029, DD-009; PO 25-09-2026), Q19 (syntax of smart quick capture: stick to the tokens of DD-004 — `@person`, `!date`, `#tag`, `^project`, `*priority`; dates only with a prefix, in the active UI language → AC REQ-050; PO 27-09-2026), Q18 (navigation: five destinations, *Overview* added → REQ-030, DD-011; PO 27-09-2026), Q20 (triage destinations → type and status in AC REQ-010; the type *thought* is dropped, a thought is an idea; PO 27-09-2026), Q21 (colour rule: orange = needs attention *now*, blue = calm; deliver/wait through the shape → DD-017; PO 27-09-2026), Q22 partly (priority high = v1, medium = after v1; Markdown rendering after v1 → `BACKLOG.md`; PO 27-09-2026), Q23 (no separate field *role*; *job title* is enough, reconsidered after a period of use → DD-015; PO 27-09-2026), Q26 (swiping an inbox row to the trash → AC REQ-010, left = trash as in triage, right does nothing in the list; PO 28-09-2026), Q36 (recurring tasks → v1, milestone M4 after T4.1 and T4.2, BACKLOG T4.7; PO 02-10-2026), Q24 (a deadline stays a date in v1, reminded at a set time → DD-005; PO 04-10-2026), Q38 (reminder window 10 minutes, later in deep sleep → AC REQ-020, DD-005; PO 04-10-2026), Q39–Q42 (Offload bar: v1 as T1.11 after T4.7, opening over an open screen as a reminder tap but keeping typed text, app shortcuts yes, no tray change, three buttons → AC REQ-063; PO 06-10-2026), Q29–Q35 (recurring tasks: a token in every app language, fixed on the calendar, one overdue time, one series item with a record per time, UUIDv5 records, reminders on every series date, stopping three ways → AC REQ-061, DD-003, DD-004 point 14, DD-005, DD-018 point 18; PO 06-10-2026).

## 10. Parking lot (look at later)

- File-based sync through a folder chosen by the user (e.g. with Syncthing) — the app stays network-free. Can reuse the package format of REQ-035.
- Extra inline tokens: `~duration`, `?question`. (`^project` and `*priority` are included in REQ-050.)
- Periodic check "do you still remember your backup passphrase?".
- Statistics: lead time of requests per person.
- Field *role* (relation to me) on a person, if it turns out that grouping or filtering on it is needed (Q23, DD-015).
