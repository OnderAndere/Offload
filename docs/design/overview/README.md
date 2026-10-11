# Overview – reference sketches (design v1)

Screen sketches of the four views in the **Overview** tab (*Overzicht*). They serve as a
visual reference for the backlog items of the Overview (Horizon, Standstill), the commitment
balance in the people view, and Connections.

| File | View | Answers the question |
|---|---|---|
| `01-horizon.png` | Timeline today + 6 weeks, one lane per project | What is coming my way? |
| `02-standstill.png` | Treemap: size = open items, colour = time since last touched | What has stalled? |
| `03-people.png` | Commitment balance per person (I deliver ↔ I am waiting for) | Where do I stand with X? |
| `04-connections.png` | Local graph of links around one focus item, 1–2 steps | How does this fit together? |

## How to use

- **Indicative, not a pixel specification.** The backlog items and the design/decision
  document lead; where they differ, the text wins.
- **Sample data.** Names, projects and numbers are made up.
- **Format:** phone 390×844 dp, rendered at 2× (780×1688 px).
- **Source:** each PNG is rendered from the `.html` file next to it with headless Chrome
  (`--force-device-scale-factor=2 --window-size=390,844`). Redrawn on 02-10-2026 with fictional
  sample data (household, garden, club), same layout and colours as the approved v1; the font falls
  back to Segoe UI where IBM Plex is not installed.
- **Status:** design v1, approved by the user; to be re-assessed after 2–4 weeks of use.

## Visual conventions (see the decision document)

- Orange `#B35712` = needs my attention *now* (I have to deliver, overdue, old, busy); blue
  `#245A8C` = calm (I am waiting, fresh, planned later). In Horizon the shape distinguishes
  "I deliver" (filled dot) from "waiting for someone else" (ring). Colour-blind safe; see
  DD-017 (colour rule approved by the PO 27-09-2026).
- Standstill classes: `#DCE6F0` < 1 wk · `#F6E1CC` 1–3 wk · `#E3A46C` 3–6 wk ·
  `#A34A12` > 6 wk.
- Background `#F3F1EC`, text `#1B1D20`, secondary `#5A5F66`.
- Typeface in the sketch: IBM Plex Sans / IBM Plex Mono (numbers and week numbers in
  monospace). Choice still to be reviewed by the architecture agent.
- Touch targets ≥ 44 dp; information never through colour alone.

---
*These sketches and this document were made with the help of AI (Claude) and assessed by the
user.*
*Confidence: medium — the visual concept is approved, but details are only validated in use.*
