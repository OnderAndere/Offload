# Spike S3 · Homescreen-widget naar Flutter

## English summary

*The report below is in Dutch and kept unchanged as the historical record.*

- **Question:** how does a home-screen widget capture a thought fast (REQ-001, 3 s budget) and
  hand it to the Flutter app without losing it (DD-010)?
- **Outcome: GO for variant A.** A small native Android input window (Kotlin, no Flutter)
  writes the text to an encrypted, loss-free queue (AES-256-GCM, non-exportable Keystore key,
  the item ID as associated data); the app drains the queue on start and resume, stores the
  item first and only then acknowledges it. All 17 loss tests passed: confirmed items survive
  a reboot and crashes before and after storing, without duplicates; damaged or swapped files
  go to quarantine, never silently deleted. Variant A opens about twice as fast as opening
  Flutter directly (B). No new dependencies or permissions.
- **Caveat:** the emulator cannot prove the 3 s budget; a measurement on a real phone is
  needed.
- **PO decisions (24-09-2026):** the loss-free criterion was added to AC REQ-001; the phone
  measurement became optional and moved to T1.7.
- **Pitfalls found:** a Flutter keyboard request on cold start is ignored; the emulator's
  hardware keyboard hides the on-screen keyboard; one Enter can save twice (guard needed);
  after "Force stop" the widget does nothing until the app is opened once.

---

> **Datum:** 24-09-2026 · **Backlog:** S3 (M0) · **Toetst:** REQ-001, DD-010 (en regel 2 uit
> `CLAUDE.md`: alles versleuteld op schijf) · **Code:** `spikes/s3_widget/` (wegwerpcode)
>
> ⚠️ **AI-disclaimer:** spike uitgevoerd en beschreven door een AI-assistent (Claude, Anthropic).
> Uitkomsten komen uit daadwerkelijk gedraaide tests op de emulator `Offload_API_36`
> (Android 16), tenzij gemarkeerd als *niet getest* of *onzeker*.

## Conclusie

**Advies: variant A** — een klein native Android-invoervenster (Kotlin, zonder Flutter) dat
de tekst in een **versleutelde, verliesvrije wachtrij** zet; de Flutter-app haalt de wachtrij
leeg bij starten en hervatten.

- **Verliesvrij (eis product owner): bewezen.** 17 van 17 controles geslaagd: bevestigde
  items overleven een herstart van het toestel, een crash vóór en ná het opslaan in de app
  (zonder dubbelingen), en beschadigde of verwisselde bestanden gaan naar quarantaine in plaats
  van weg.
- **Snelheid: A is ruwweg twee keer zo snel als B**, maar de 3 s van REQ-001 is op de emulator
  **niet betrouwbaar te bewijzen** (zie *Metingen*). Een meting op het eigen toestel is nodig
  voordat REQ-001 als gehaald geldt.
- **Geen nieuwe dependencies, geen nieuwe permissies** (release-manifest gecontroleerd).

**GO voor DD-010 met variant A**, onder voorbehoud van de toestelmeting.

## Wat er gebouwd is

| Onderdeel | Wat het doet |
|---|---|
| `CaptureWidgetProvider` | Widget (RemoteViews, geen Glance) met twee knoppen: **A** en **B** |
| `QuickCaptureActivity` (A) | Dialoogvenster boven het beginscherm, invoerveld met focus en toetsenbord, Enter/Opslaan |
| `CaptureQueue` | Versleutelde wachtrij in `files/capture_queue/` |
| `MainActivity` + `lib/main.dart` | Kanaal `offload/capture_queue` (`drain`, `ack`); Flutter haalt de wachtrij leeg bij start en hervatten |
| B | De widget opent de Flutter-app direct in een invoerscherm |

De "inbox" in de spike is een JSON-bestand als vervanger van de versleutelde database uit S1.

### Zo werkt de wachtrij (verliesvrij ontwerp)

1. **Vast ID bij vastleggen** (UUID, REQ-008). Hetzelfde item twee keer ontvangen = één item.
2. **Pas "opgeslagen" na echt wegschrijven:** versleutelen → `<id>.tmp` → `fsync` → hernoemen
   naar `<id>.cq` → map `fsync`. Pas daarna sluit het venster. Mislukt het, dan blijft de tekst
   staan met een melding.
3. **Nooit half:** een `.tmp` is nooit aan de gebruiker bevestigd en wordt bij het ophalen
   opgeruimd.
4. **Eerst opslaan, dan pas uit de wachtrij:** Flutter zet het item in de database, en roept
   daarna pas `ack` aan; alleen `ack` verwijdert bestanden.
5. **Onleesbaar = quarantaine:** een bestand dat niet te ontsleutelen is gaat naar
   `quarantine/` en de app toont een waarschuwing. Nooit stil verwijderen.
6. **Versleuteling:** AES-256-GCM met een aparte, niet-exporteerbare sleutel in de Android
   Keystore (`offload_capture_queue_v1`), zonder ontgrendelprompt. Het ID is *associated data*:
   een bestand onder een ander ID zetten maakt het onleesbaar (getest).

## Metingen

### Verliestests (`tool/noloss.ps1`, debug-builds met foutinjectie) — alle geslaagd

| Test | Scenario | Resultaat |
|---|---|---|
| T1 | 3 items vastleggen, app nooit geopend, **toestel herstarten** | 3 bestanden overleven; app ontvangt ze precies één keer; wachtrij daarna leeg |
| T1 | Wachtrij op schijf bekijken | geen leesbare tekst (versleuteld) |
| T2 | App **crasht na ophalen, vóór opslaan** | items blijven in de wachtrij; volgende start: afgeleverd |
| T3 | App **crasht na opslaan, vóór bevestigen** | items opnieuw ontvangen, als dubbel herkend; inbox ongewijzigd |
| T4 | Beschadigd bestand, **verwisseld** bestand, half geschreven `.tmp` | geldige items afgeleverd; beide slechte bestanden in quarantaine; `.tmp` opgeruimd |

### Snelheid: start → invoerveld met toetsenbord

Gemeten met `am start` (tijdstempel op het toestel direct ervoor), release-build, 5 runs.
Dit meet de kosten van de app zelf, **zonder** de openingsanimatie van de launcher.

| | Koud (proces weg) | Warm (app op achtergrond) |
|---|---|---|
| **A: native venster** | 0,65–1,2 s (twee reeksen) | 0,42–0,86 s |
| B: Flutter-scherm | 1,9 s | 1,1–1,25 s |

Opslaan zelf (versleutelen + wegschrijven + fsync): **25–50 ms**.

**Echte tik op de widget** (widget op het beginscherm van de emulator): met de hand gemeten
1,4–1,8 s tot het toetsenbord bij A. Een geautomatiseerde reeks gaf 3,8–4,4 s. Die spreiding
komt door de emulator: haperende frames bij de toetsenbordanimatie ("Missed SF frame …
IME_INSETS_SHOW_ANIMATION") en de opstarttijd van het `input`-commando zelf. **De emulator
is voor deze meting niet betrouwbaar**; een telefoon zonder emulatielaag is nodig.

Budget REQ-001: 3 s vanaf de tik, *inclusief typen*. Met A blijft er naar verwachting 1,5–2 s
over voor een korte gedachte; met B bij een koude start ruim 1 s of minder.

## Bevindingen en valkuilen

1. **Flutter-toetsenbord bij koude start wordt genegeerd.** `autofocus` vraagt het toetsenbord
   aan voordat Android het venster "bedient": `Ignoring showSoftInput() … is not served`.
   Bij B moest daarom na het eerste frame herhaald `TextInput.show` worden aangeroepen.
   Variant A heeft dit probleem niet (`insetsController.show(ime)` na focus).
2. **Emulator met hardwaretoetsenbord onderdrukt het schermtoetsenbord.** Voor tests die zich
   als een telefoon moeten gedragen: `adb shell settings put secure show_ime_with_hard_keyboard 1`.
3. **Dubbel opslaan.** Eén Enter leverde twee items op (het toetsenbord stuurt zowel "Klaar" als
   de Enter-toets); ook dubbeltikken op Opslaan kan dit. Opgelost met een eenmalige vlag per
   venster. In productie ook nodig.
4. **Na "Geforceerd stoppen" reageert de widget niet meer** tot de app één keer is geopend
   (Android-gedrag bij een gestopte app). Een gewone procesbeëindiging door Android (geheugen)
   heeft dit effect niet. Vermelden in de handleiding.
5. **Back-up uitgeschakeld** (`allowBackup="false"`): de wachtrijsleutel is niet exporteerbaar,
   dus een teruggezette wachtrij op een ander toestel is onleesbaar. Past bij DD-007 (back-up
   loopt via de eigen versleutelde export).
6. **Kleine resterende kans:** sterft het proces precies tijdens het wegschrijven (25–50 ms),
   dan verdwijnt het venster zonder dat het item bestaat. Het item is dan nooit bevestigd; de
   verliesvrije garantie geldt voor *bevestigde* items.
7. **Concepten worden niet bewaard.** Verlaat je het venster met Home, dan blijft de tekst
   staan zolang het proces leeft; ruimt Android het proces op, dan is de onbevestigde tekst weg.
   Buiten de eis (niet bevestigd), maar een mogelijke verbetering.
8. **Meetgereedschap (ontwikkelomgeving):**
   - `Select-Object -First 1` in PowerShell stopt het native commando vroegtijdig (hier: `input
     tap` werd niet uitgevoerd). Eerst alle uitvoer inlezen.
   - `am start -W` kan op de emulator blijven hangen; zonder `-W` plus wachttijd werkt het.
   - Schermafbeelding: `adb shell screencap -p /sdcard/x.png` + `adb pull`; niet via `>`
     (PowerShell verminkt binaire uitvoer).
   - `run-as` (bestanden van de app bekijken) werkt alleen bij debug-builds.

## Niet getest

- **Echte telefoon** — de belangrijkste open meting (zie *Te besluiten*).
- Launchers van fabrikanten (Samsung, Pixel), donkere modus, meerdere widgets.
- **Vóór de eerste ontgrendeling na een herstart** (Direct Boot): de wachtrij staat in
  versleutelde gebruikersopslag en de Keystore-sleutel is dan vermoedelijk niet beschikbaar.
  De widget zal tot de eerste ontgrendeling niet werken. *Onzeker; niet getest.*
- Toegankelijkheid (TalkBack) van het venster.
- Variant B via een echte widgettik gaf in de geautomatiseerde reeks geen meetpunt; niet verder
  uitgezocht omdat A de voorkeur heeft.

## Aanbevelingen voor T1.7

- Variant A overnemen: `QuickCaptureActivity` + `CaptureQueue` in de `platform/`-laag,
  achter `CaptureChannel` (DD-010); Flutter haalt leeg bij start en `resume`.
- Teksten van het venster via Android-stringresources die uit dezelfde bron komen als de ARB's
  (DD-009); de spike gebruikt tijdelijk vaste Nederlandse strings.
- `exported="false"` voor het venster (de spike had `true` alleen voor de metingen).
- De verliestests T1–T4 als geautomatiseerde test behouden.

## Besluiten (product owner, 24-09-2026)

- Verliesvrij-criterium **akkoord** en toegevoegd aan AC REQ-001 in `SPEC.md`.
- Toestelmeting: **optioneel**; verschoven naar T1.7. Test-APK staat klaar
  (`spikes/s3_widget/build/app/outputs/flutter-apk/app-release.apk`).

### Oorspronkelijke vragen

1. **Toestelmeting.** Mag ik een test-APK maken die je op je telefoon installeert? Dan tik je
   een paar keer op de widget; een schermopname (met "tikken tonen") geeft de echte tijd van
   tik tot toetsenbord. Pas daarna is REQ-001 bewezen.
2. **Verliesvrij als eis vastleggen.** Voorstel voor een extra acceptatiecriterium bij REQ-001 in
   `SPEC.md`: *"Een bevestigd item gaat nooit verloren, ook niet bij een crash, herstart of
   beschadigd bestand, voordat het in de database staat; een onleesbaar item wordt bewaard in
   quarantaine en gemeld, nooit stil verwijderd."*

## Reproduceren

```powershell
cd spikes/s3_widget
flutter build apk --release; & $adb install -r build\app\outputs\flutter-apk\app-release.apk
powershell -File tool\measure.ps1 -Runs 5          # am start: A en B, koud en warm
# verliestests: drie debug-builds (normaal, CRASH_BEFORE_INSERT, CRASH_AFTER_INSERT)
#   als build\s3-normal.apk, build\s3-crash-before.apk, build\s3-crash-after.apk
powershell -File tool\noloss.ps1
powershell -File tool\measure_widget.ps1 -Runs 3   # echte widgettik (widget op beginscherm, adb root)
```
