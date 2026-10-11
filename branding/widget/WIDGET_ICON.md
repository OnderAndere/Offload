# DD-019 · Widget icon: "drop one in"

> Included in `DESIGN.md` as DD-019 (28-09-2026). Status: design by the product owner; review by the architecture agent.

**Requirements:** REQ-001 (capture in ≤ 3 s through the home-screen widget), REQ-017 (global keyboard shortcut on Windows), REQ-005/REQ-029 (i18n of the widget labels).

## Decision

The widget icon reuses the form language of the app icon and changes exactly one thing:

| | App icon | Widget icon |
|---|---|---|
| Meaning | "what is in it" — the stored thoughts | "drop one in now" — capturing |
| Motif | tray + three falling amber dots (a trail) | tray + one large amber dot with a knocked-out **+** |
| Colours | navy `#22304F→#151E33`, tray `#F1F5FB`, amber `#E9A23B` | identical |

**Why:** the tray ties the icon directly to Offload, and the `+` is the universal sign for "add". One dot instead of a trail makes it an action (now, one thing) instead of a state (a collection). That way the app icon and the widget are related but not interchangeable side by side on the home screen.

**Rejected alternatives**
- Pencil/notepad: generic, no relation to Offload.
- Arrow down into the tray: reads as "download" — the wrong association, certainly for an offline app.
- Microphone as the main motif: puts the emphasis on speech (REQ-006, Should), while text (REQ-001, Must) is the primary channel.

## Files (`branding/widget/`)

| File | Use |
|---|---|
| `widget_glyph.svg` | 24 dp monochrome glyph, tinted through `android:tint`. The button in the widget, the Windows system tray. |
| `widget_icon.svg` | Colour tile 108×108 (preview, documentation). |
| `widget_icon_foreground.svg` / `_monochrome.svg` | Layers for a possible app shortcut "Capture" (NL: "Vastleggen") (adaptive/themed icon). |
| `widget_icon_192.png` | Raster version for checking and for the manual; also the `previewImage` fallback of the widget. |
| `widget_preview_sheet.png` | Overview: relation app/widget, glyph sizes, home-screen mock. |

## Implementation notes

- **No masks used.** The `+` is knocked out with `fill-rule="evenodd"`; that translates 1:1 to `android:fillType="evenOdd"` when imported as a Vector Asset.
- **Widget preview:** with minSdk 33 `android:previewLayout` can be used (follows theme and language); `previewImage` only as a fallback.
- **Dynamic colour:** in Material You mode tint the glyph with the system colour and keep the amber dot (duotone), so that the brand link stays.
- **Labels through i18n:** NL "Vastleggen" / "Leg iets vast…", EN "Capture" / "Capture something…".
- **The microphone button in the 4×1 mock is a proposal**, not a decision; it belongs to REQ-006 and needs its own trade-off (starting a recording from the widget).

## Open point

- **16 px (Windows system tray):** the `+` closes up into a dot. Readable as "dot in a tray", but for a sharp result make a hand-pixelled 16 px variant for the `.ico` file (SPEC Q25).

---
*AI-assisted design (Claude). Confidence: medium — checked visually at 16–192 px, not yet on a real device or in a Material You theme.*
