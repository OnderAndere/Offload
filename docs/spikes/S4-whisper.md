# Spike S4 · whisper.cpp via `dart:ffi`

## English summary

*The report below is in Dutch and kept as the historical record; only the example sentence and the word lists were replaced by fictional text on 02-10-2026 (results unchanged).*

- **Question:** can whisper.cpp transcribe Dutch speech fully on-device from Flutter on
  Windows and Android (DD-002, REQ-006), and which model: `base` or `small` (SPEC Q4)?
- **Outcome: GO.** whisper.cpp v1.9.4 builds for both platforms and runs through a small C
  shim and `dart:ffi` in an `Isolate.run`; no network and no extra permission.
- **Model, accepted:** `ggml-small-q5_1` (181 MB). As accurate as full `small` (8.6 % word
  error rate on a 58-word test text) at about half the memory; `base` makes real mistakes
  (15.5 %). On the PC 26.7 s of speech took 5 s.
- **Caveats:** the test audio was synthetic speech, so error rates are probably too
  favourable; phone speed was not measured (the emulator is 30–50× slower than the PC). With
  "audio first" (DD-002) slow transcription means waiting, not data loss.
- **PO decisions (24-09-2026):** Q4 closed with `small-q5_1` (DD-002); the phone measurement
  moved to T6.1; the models were removed after the spike (SHA-256 hashes in the report).

---

> **Datum:** 24-09-2026 · **Backlog:** S4 (M0) · **Toetst:** DD-002, REQ-006 · **Open vraag:**
> SPEC Q4 (base of small) · **Code:** `spikes/s4_whisper/` (wegwerpcode)
>
> ⚠️ **AI-disclaimer:** spike uitgevoerd en beschreven door een AI-assistent (Claude, Anthropic).
> Uitkomsten komen uit daadwerkelijk gedraaide metingen op deze pc en de emulator
> `Offload_API_36`, tenzij gemarkeerd als *niet getest* of *onzeker*.

## Conclusie

**GO voor DD-002.** whisper.cpp v1.9.4 bouwt voor Windows en Android, draait vanuit Flutter via
een eigen dunne koppeling en zet Nederlandse spraak volledig lokaal om in tekst. Er gaat
niets over het netwerk en er is geen extra permissie nodig.

**Advies Q4: `small`, in de gecomprimeerde variant `ggml-small-q5_1` (181 MB).**

- Even nauwkeurig als het volle `small` (465 MB), met ongeveer de helft van het geheugen.
- Duidelijk beter dan `base`, dat echte fouten maakt ("ontdien" voor "om tien",
  verhaspelde vakwoorden, "uiteelijke").
- Op de pc ruim sneller dan realtime (26,7 s spraak in 5 s).
- **Voorbehoud:** de snelheid op de telefoon is niet gemeten. De emulator is 30–50× trager dan
  de pc en daarom geen maatstaf. Omdat DD-002 "audio eerst" is (de opname wordt eerst veilig
  bewaard, de omzetting volgt later), is een tragere omzetting geen dataverlies, alleen wachttijd.

## Opzet

- whisper.cpp **v1.9.4** (commit `927cfce`, 10-09-2026), MIT-licentie, als broncode in
  `third_party/`.
- **C-shim** (`native/offload_whisper.c`, 6 functies: `ow_init`, `ow_transcribe`,
  `ow_n_segments`, `ow_segment_text`, `ow_system_info`, `ow_free`). whisper.cpp geeft grote
  structs *by value* door (`whisper_full_params` met tientallen velden en callbacks); die in Dart
  nabouwen is foutgevoelig en breekt bij elke nieuwe versie. De shim houdt de Dart-kant
  klein en stabiel.
- Eén gedeelde bibliotheek per platform, met whisper en ggml statisch erin:
  Windows `offload_whisper.dll` (1,5 MB, AVX2); Android `liboffload_whisper.so` voor arm64-v8a en
  x86_64 (≈ 22 MB ongestript; Gradle stript bij het verpakken).
- Dart: `dart:ffi` + pakket `ffi` (akkoord PO). Omzetten in een `Isolate.run`, dus de UI blijft
  vrij. Eigen WAV-lezer (16-bit PCM, mono/stereo, herbemonstering naar 16 kHz).
- **Testaudio:** de referentietekst (58 woorden) uitgesproken door de Windows-stem
  *Microsoft Frank (nl-NL)*, 26,7 s. Synthetische spraak is schoner dan echte spraak; de
  foutpercentages zijn daardoor waarschijnlijk **te gunstig**.
- **Foutmaat:** woordfoutpercentage (WER) na kleine letters en zonder leestekens.
- Modellen van Hugging Face (`ggerganov/whisper.cpp`), alleen op de ontwikkel-pc:

| Model | Grootte | SHA-256 |
|---|---|---|
| `ggml-base.bin` | 141 MB | `60ED5BC3DD14EEA856493D334349B405782DDCAF0028D4B5DF4088345FBA2EFE` |
| `ggml-small-q5_1.bin` | 181 MB | `AE85E4A935D7A567BD102FE55AFC16BB595BDB618E11B2FC7591BC08120411BB` |
| `ggml-small.bin` | 465 MB | `1BE3A9B2063867B937E64E2EC7483364A79917E157FA98C5D94B5C1FFFEA987B` |

Deze hashes kunnen dienen als de "bekende lijst" uit DD-002 voor de importcontrole (T6.1).

## Resultaten (26,7 s spraak, 4 threads, profile-build)

| Model | Fout (WER) | Windows-pc: omzetten | Geheugen (pc) | Emulator SSE3 | Emulator AVX2 |
|---|---|---|---|---|---|
| base | 15,5 % (9/58) | **1,9 s** | 266 MB | 90 s | 63 s |
| small-q5_1 | 8,6 % (5/58)* | **5,0 s** | 357 MB | 159 s | 95 s |
| small | 8,6 % (5/58) | **6,3 s** | 644 MB | 256 s | 100 s |

\* Op de emulator met SSE3 gaf small-q5_1 één fout meer (10,3 %); met AVX2 weer 8,6 %.

Laadtijd van het model: 0,3–0,9 s op de pc, 1,4–4,8 s op de emulator.

**Wat de "fouten" zijn.** Bij `small` zijn het vooral spellingsvarianten of vrijheden:
"10" i.p.v. "tien", vakwoorden anders gespeld of in twee delen, "Ideen". Bij `base`
komen daar echte verhaspelingen bij. Voor zoeken (REQ-011) en een geheugensteun is `small`
goed bruikbaar; `base` is merkbaar slordiger.

Voorbeeld `small-q5_1`: *"Morgen om 10 uur overleg met Jan over de renovatieplanning. Vraag Petra of
ze de aanhanger voor vrijdag kan vrijmaken. Idee, de planning van de verbouwing opnieuw
bekijken na de vakantie. …"* (Voorbeeldzin en woordenlijst op 02-10-2026 achteraf vervangen door
fictieve tekst; de meetuitkomsten hierboven zijn ongewijzigd.)

## Bevindingen en valkuilen

1. **Rekeninstructies maken het verschil.** Een "portable" Android-build zonder extra
   CPU-instructies was op de emulator 1,5–2,5× trager dan met AVX2. Voor telefoons betekent dit:
   bouwen met ARM-uitbreidingen (bijv. `GGML_CPU_ARM_ARCH=armv8.2-a+dotprod+fp16`), en op
   Windows een bewuste basis kiezen (AVX2 draait op vrijwel elke pc van na 2015). *Het effect op
   een telefoon is niet gemeten.*
2. **Modellen op Android plaatsen (ontwikkeling):** de map `Android/data/<pakket>/files` moet door
   de app zelf worden aangemaakt (`getExternalFilesDir`); een map die `adb` aanmaakt is voor de
   app onleesbaar. `flutter drive` verwijdert de app vóór installatie en daarmee ook de
   gepushte modellen; daarom draaide de Android-meting vanuit `main.dart`.
3. **Geheugen:** het volle `small` gebruikt ≈ 610–645 MB extra; op toestellen met weinig RAM
   is dat een risico. `small-q5_1` ≈ 325–357 MB.
4. **Geen netwerk, geen permissie** nodig voor het omzetten zelf. Opnemen (microfoon) is een
   aparte stap met eigen permissie en een eigen pakketkeuze: *buiten S4*.
5. Het model wordt per omzetting geladen (0,3–5 s). In de app kan het model tijdens een reeks
   omzettingen geladen blijven.

## Niet getest

- **Snelheid op de eigen telefoon** (ARM). Dit is voor Q4 de belangrijkste open meting.
- **Echte spraak** van de product owner (de map `fixtures/` staat klaar; een `.wav` erin zetten
  en de meting opnieuw draaien volstaat).
- Lange opnames (> 30 s), achtergrondgeluid, snel of binnensmonds spreken.
- Accuwaarde en warmte op de telefoon.
- Opnemen vanaf de microfoon (T6.2).

## Besluiten (product owner, 24-09-2026)

- Q4: **`ggml-small-q5_1` akkoord**; SPEC Q4 gesloten, vastgelegd in DD-002. Telefoonmeting in T6.1.
- Modellen en de testapp op de emulator zijn na de spike **verwijderd**. Opnieuw nodig? Download
  met de URL uit *Reproduceren* en controleer de SHA-256 hierboven.

### Oorspronkelijke vragen

1. **Q4:** akkoord met `small-q5_1` als aanbevolen model (onder voorbehoud van de toestelmeting)?
2. **Modellen van schijf:** zoals afgesproken kunnen de modellen (≈ 790 MB in
   `spikes/s4_whisper/models/`) en de app op de emulator nu weg. Wil je eerst je eigen opname
   laten meten? Dan wacht ik daarmee.

## Reproduceren

```powershell
cd spikes/s4_whisper
# modellen (alleen ontwikkeling):
#   curl.exe -L -o models/<naam> https://huggingface.co/ggerganov/whisper.cpp/resolve/main/<naam>
# native bouwen: zie native/CMakeLists.txt (Windows: VS 2026-generator; Android: NDK + Ninja)
powershell -File tool\synthesize.ps1                       # testaudio met Microsoft Frank
flutter drive --profile -d windows --driver=test_driver/integration_test.dart `
  --target=integration_test/s4_test.dart --dart-define=MODEL_DIR=<pad naar models>
# Android: app installeren en één keer starten, modellen pushen naar
#   /sdcard/Android/data/eu.marandos.offload.spike_s4/files/models/, app opnieuw starten,
#   resultaten in logcat (S4|...).
```
