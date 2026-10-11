# Spike S2 · Compressiebibliotheek met Windows-ondersteuning

## English summary

*The report below is in Dutch and kept unchanged as the historical record.*

- **Question:** which image compression library works on Android and Windows for the photo
  pipeline of DD-006 (downscaling, EXIF orientation, stripping EXIF/GPS), SPEC Q1?
- **Outcome:** both candidates fail. `image_compress_plus` 4.0.0 crashes optimised Windows
  builds on every photo, ignores the EXIF orientation on Android, needs vcpkg and blocks the
  Windows platform thread. `ironpress` 0.2.0 ignores the EXIF orientation everywhere and is a
  96 MB package of an unverified uploader with unattested binaries.
- **Recommendation, accepted:** no separate library. Decode, orient and downscale with
  Flutter's engine codec (`dart:ui` `instantiateImageCodec` with `targetWidth`/`targetHeight`);
  encode only the small result as JPEG with the pure-Dart `package:image` in an
  `Isolate.run`. The only route that passed every check on both platforms, without UI jank;
  a 50 MP photo takes about 1 s (display) plus 0.1–0.2 s (thumbnail) on the PC.
- **PO decisions (24-09-2026):** `image` approved as a production dependency; DD-006/D5 and
  point 4 updated; SPEC Q1 closed.
- **Pitfalls found:** `package:image` keeps EXIF (GPS) unless cleared; pick the target side
  after reading the orientation; measure in profile mode, not debug; Kotlin plugins with the
  project and pub cache on different drives need `kotlin.incremental=false`; no BOM in Gradle
  files.

---

> **Datum:** 24-09-2026 · **Backlog:** S2 (M0) · **Toetst:** DD-006 (D1, D4, D5, punt 4),
> REQ-009, REQ-024, REQ-027 · **Open vraag:** SPEC Q1
> **Code:** `spikes/s2_image_compress/` (wegwerpcode, geen productiecode)
>
> ⚠️ **AI-disclaimer:** spike uitgevoerd en beschreven door een AI-assistent (Claude, Anthropic).
> Alle uitkomsten komen uit daadwerkelijk gedraaide tests op deze machine, tenzij gemarkeerd als
> *niet getest* of *onzeker*.

## Conclusie

**Beide kandidaten uit SPEC Q1 vallen af.**

- **`image_compress_plus` 4.0.0**: crasht het proces in een geoptimaliseerde Windows-build
  (profile/release) bij élke foto, en past op Android bij `compressWithList` de EXIF-oriëntatie
  **niet** toe. Daarnaast vereist hij vcpkg op Windows en blokkeert hij daar de platformthread.
- **`ironpress` 0.2.0**: snel, maar past de EXIF-oriëntatie op geen enkel platform toe
  (D4 faalt). Daarnaast is het een 96 MB-pakket van een ongeverifieerde uploader, met prebuilt
  binaries zonder herkomstbewijs.

**Aanbeveling: geen aparte compressiebibliotheek.** Gebruik Flutter's eigen engine-codec
(`dart:ui` `instantiateImageCodec` met `targetWidth`/`targetHeight`) voor decoderen, oriëntatie
en verkleinen, en **`package:image`** (pure Dart) alleen voor het JPEG-coderen van het kleine
resultaat. Dit was de enige route die op **beide platforms, in debug én profile**, alle
controles haalde: juiste afmetingen, oriëntatie 1/3/6/8 goed, geen EXIF/GPS in de uitvoer, geen
UI-haperingen. Snelheid: een 50 MP-foto van jouw toestel in ≈ 1 s (display) + ≈ 0,1–0,2 s
(miniatuur).

**Go voor DD-006, mits D5 wordt aangepast** naar "engine-codec + `package:image`". Daarvoor zijn
twee besluiten van de product owner nodig (zie *Te besluiten*).

## Opzet

- Flutter 3.44.4; app-ID `eu.marandos.offload.spike_s2`; Android `minSdk 33`/`targetSdk 36`.
- Per kandidaat de pijplijn in het geheugen: JPEG-bytes → **display** (langste zijde ≤ 1600,
  q82) en **miniatuur** (≤ 256, q75), volgens DD-006/D1.
- **Testfoto's** (`tool/make_fixtures.dart`): 4000×3000 (12 MP) met vier gekleurde kwadranten,
  pixels opgeslagen zoals een camera dat doet, met EXIF-oriëntatie 1, 3, 6 en 8 plus GPS-tags;
  en een 800×600-foto (geen opschaling). Zelfcontrole van de fixtures met `package:image` als
  referentie.
- **Echte foto's:** twee foto's van het Android 16-toestel van de product owner: 6144×8192
  (50 MP), 7–9 MB, **oriëntatie 6, met GPS**. Dit bevestigt dat D4 in de praktijk telt: het
  toestel draait de pixels niet zelf.
- **Automatische controles** (`integration_test/s2_test.dart`): langste zijde, beeldverhouding,
  staand/liggend, kleur per kwadrant (dus: staat de foto rechtop), geen APP1-EXIF-segment in de
  uitvoer. Plus: grootste pauze tussen frames en de latentie van een platformkanaal tijdens het
  comprimeren (DD-006 punt 4).
- Visuele controle van de echte foto's (miniaturen bekeken).
- Tijden in **profile-modus (AOT)** via `flutter drive --profile`; debug-tijden wijken sterk af.

### Kandidaten

| # | Kandidaat | Techniek |
|---|---|---|
| A | `image_compress_plus` 4.0.0 (+ `_android` 3.0.0, `_windows` 3.0.0) | Android: systeemcodecs via Pigeon-kanaal, threadpool. Windows: C++ met libjpeg-turbo, libpng, libwebp, exiv2 via vcpkg |
| B | `ironpress` 0.2.0 | Rust via `dart:ffi`, prebuilt binaries in het pakket |
| C | `image` 4.10.1 (pure Dart) | decoderen, `bakeOrientation`, `copyResize`, `encodeJpg` in een `Isolate.run` |
| D | **engine-codec + `image`** | `dart:ui` decodeert en verkleint native (EXIF-oriëntatie inbegrepen); `image` codeert alleen het resultaat in een `Isolate.run` |

C en D zijn met akkoord van de product owner toegevoegd (C) of zonder nieuwe dependency
bijgekomen tijdens de spike (D, gebruikt alleen `dart:ui` en het al toegevoegde `image`).

## Resultaten: correctheid

| Controle | A Windows | A Android | B Windows | C beide | **D beide** |
|---|---|---|---|---|---|
| Langste zijde ≤ 1600 / ≤ 256, geen opschaling | ✅ | ✅ | ✅ | ✅ | ✅ |
| Oriëntatie 1 | ✅ | ✅ | ✅ | ✅ | ✅ |
| Oriëntatie 3 / 6 / 8 (synthetisch) | ✅ | ❌ | ❌ | ✅ | ✅ |
| Echte foto (oriëntatie 6) rechtop | ✅ (debug) | ❌ gekanteld | ❌ gekanteld | ✅ | ✅ |
| Geen EXIF/GPS in uitvoer | ✅ | ✅ | ✅ | ✅ *(alleen na expliciet wissen)* | ✅ |
| Werkt in geoptimaliseerde build | ❌ **crash** | ✅ | ✅ | ✅ | ✅ |

B is alleen op Windows gedraaid; na het oriëntatie-resultaat is hij uit de spike gehaald
(de oriëntatie zit in de Rust-kern, dus platformonafhankelijk; *Android niet getest*).

## Resultaten: tijd en grootte (profile-modus)

Windows 11-pc; Android = emulator `Offload_API_36` (x86_64 op dezelfde pc). **Emulatortijden
zeggen weinig over een echt ARM-toestel.**

| Kandidaat | Platform | 12 MP → display / miniatuur | 50 MP (echt) → display / miniatuur |
|---|---|---|---|
| A `image_compress_plus` | Windows | *crasht* (debug: 640 / 382 ms) | *crasht* (debug: 4,1 / 3,4 s) |
| A `image_compress_plus` | Android | 418 / 193 ms | *(fout gedraaid)* |
| B `ironpress` | Windows | 227 / 97 ms | 509 / 354 ms *(fout gedraaid)* |
| C `image` | Windows | 2,4 / 1,8 s | 9,1 / 8,4 s; in één doorgang ≈ 9,5 s totaal |
| C `image` | Android | 2,5 / 1,8 s | in één doorgang ≈ 9,5 s totaal |
| **D engine + `image`** | **Windows** | **769 / 65 ms** | **≈ 930 / 120 ms** |
| **D engine + `image`** | **Android** | **≈ 750 / 120 ms** | **≈ 1,0 s / 220 ms** |

Uitvoergrootte display (12 MP synthetisch / 50 MP echt): D ≈ 145 KB / 254–400 KB; C ≈ 161 KB;
A ≈ 175–197 KB; B ≈ 75 KB. Miniatuur 4–17 KB bij alle kandidaten.

**UI tijdens het comprimeren** (grootste pauze tussen frames, met een draaiende indicator):

| | Windows | Android (emulator) |
|---|---|---|
| A | **646 ms** (debug) — venster staat stil | 50 ms |
| B | 152 ms | — |
| C | 13 ms | 66 ms |
| **D** | **6 ms** | **50 ms** |

Op de emulator is ≈ 50 ms de basislijn (ook zonder werk); daar onderscheidt de meting niet.
Op Windows wél: A comprimeert synchroon op de platformthread (bevestigd in de broncode: geen
workerthread), dus bij een 50 MP-foto hangt het venster ≈ 4 s.

## Waarom A en B afvallen

**A `image_compress_plus`:**
1. **Crash in geoptimaliseerde Windows-builds.** `0xc0000409` (fail-fast) in
   `image_compress_plus_windows_plugin.dll`, bij synthetische én echte foto's, ook met
   `autoCorrectionAngle: false` (dus niet het exiv2-pad). In debug werkt dezelfde aanroep.
   De bundel bevatte correct de release-varianten van de vcpkg-DLL's; er is geen debug/release-mix.
   Oorzaak niet verder uitgezocht (buiten de tijdbox).
2. **Geen oriëntatie op Android** bij `compressWithList`: de uitvoer is de onbewerkte
   pixelrichting. De Windows-implementatie doet het wel; de platforms gedragen zich dus verschillend.
3. **Windows-build vereist vcpkg** (libjpeg-turbo, libpng, libwebp, exiv2) plus een aanpassing
   in de `CMakeLists.txt` van de app; de README vermeldt dat maar documenteert de aansluiting
   niet. Eerste build **515 s**; daarna uit de binaire cache van vcpkg
   (`%LOCALAPPDATA%\vcpkg\archives`, 20 MB): schone rebuild **66 s**, 11 pakketten in 0,5 s
   hersteld. Voegt zes DLL's toe.
4. **Synchroon op de platformthread** op Windows (zie UI-tabel).
5. API met *minimum*-semantiek (`minWidth`/`minHeight`); "langste zijde ≤ N" moet je zelf
   uitrekenen uit de beeldverhouding.

Wel positief: op Android werkt de aanroep ook vanuit een achtergrond-isolate
(`BackgroundIsolateBinaryMessenger` + `DartPluginRegistrant`).

**B `ironpress`:**
1. **Geen EXIF-oriëntatie**: staande foto's komen 90° gekanteld uit, 180°-foto's op hun kop.
   Er is ook geen `rotate`-parameter om het zelf te corrigeren.
2. **Leveranciersrisico:** v0.2.0, ongeverifieerde uploader, pakket van 96 MB met losse
   `*(1).zip`-bestanden, foutlogs en een `opencode.json` in de publicatie, en prebuilt
   `.so`/`.dll` zonder herkomstbewijs. Past slecht bij een app die zich op privacy laat
   beoordelen (DD-008).

## Aanbevolen aanpak (D) in het kort

```dart
// 1. Upright size: SOF-afmetingen + EXIF-oriëntatie (5–8 = wissel breedte/hoogte).
// 2. Alleen de lange kant begrenzen; de engine behoudt de verhouding en past EXIF toe.
final codec = await ui.instantiateImageCodec(bytes,
    targetWidth: landscape ? 1600 : null, targetHeight: landscape ? null : 1600);
final image = (await codec.getNextFrame()).image;
final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
// 3. Alleen het kleine resultaat coderen, buiten de UI-isolate.
final jpeg = await Isolate.run(() => img.encodeJpg(
    img.Image.fromBytes(width: w, height: h, bytes: rgba!.buffer, numChannels: 4),
    quality: 82));
```

- Uitvoer bevat per constructie geen EXIF (ruwe pixels → nieuwe JPEG).
- Eén keer decoderen, één keer coderen per variant; geen dubbele JPEG-verliesstap.
- Geen native code, geen plugin, geen manifest-wijziging, geen vcpkg; `image` is pure Dart.

## Valkuilen

1. **`package:image` lekt EXIF.** `bakeOrientation` kopieert alle EXIF behalve de oriëntatie
   (GPS blijft staan), en `encodeJpg` schrijft EXIF weg zodra die aanwezig is. Altijd
   `image.exif = ExifData()` vóór het coderen. (Bij aanpak D niet van toepassing: `fromBytes`
   begint zonder EXIF.)
2. **Engine-codec: kies de juiste doelzijde.** `targetWidth`/`targetHeight` gelden voor het
   gedraaide beeld. Lees daarom zelf de EXIF-oriëntatie (`decodeJpgExif`) om te bepalen welke
   kant de lange is; anders wordt de lange zijde te groot.
3. **Debug-tijden zijn misleidend.** Pure Dart was in debug (JIT) *sneller* dan in profile (AOT):
   1,4 s tegenover 2,4 s voor 12 MP. Meet altijd in profile.
4. **`dart:ui`-decodering vraagt een Flutter-engine.** Aanroepen vanaf de hoofdisolate van een
   engine (ook een headless engine); niet vanuit een gewone `Isolate.run`. Het zware werk
   gebeurt wel op engine-threads, niet in de Dart-UI-isolate (gemeten: geen framepauzes).
5. **Kotlin-plugins en twee schijven (ontwikkelomgeving).** Project op `D:`, pub-cache op `C:`
   → Kotlin-incrementele compilatie faalt met "Could not close incremental caches". Oplossing:
   `kotlin.incremental=false` in `android/gradle.properties` (of `PUB_CACHE` naar `D:`
   verplaatsen). S1 had geen Kotlin-plugin en merkte dit niet.
6. **PowerShell 5.1 schrijft een BOM** met `Set-Content -Encoding utf8`. Een BOM vooraan
   `build.gradle.kts` breekt de Kotlin-DSL (`plugins {}` wordt niet herkend, `kotlin {}` is
   onbekend). Bestanden schrijven met `UTF8Encoding($false)` of via de editor.

## Niet getest

- **Echt ARM-toestel.** Alle Android-tijden zijn van de x86_64-emulator. Een meting op het
  toestel van de product owner is aan te raden vóór T5.2, met de 50 MP-foto's.
- **Piekgeheugen** bij het decoderen van 50 MP met `targetWidth`.
- **Gespiegelde oriëntaties** (2, 4, 5, 7) — zeldzaam, soms bij frontcamera's.
- **Andere invoerformaten** (HEIC, PNG, WebP). De engine gebruikt de platformcodecs; HEIC op
  Windows is *onzeker*.
- `ironpress` op Android; release-build (profile is ook AOT, dus vergelijkbaar).
- De oorzaak van de crash van `image_compress_plus` op Windows.

## Besluiten (product owner, 24-09-2026)

Beide punten hieronder zijn **akkoord**: `image` mag als productie-dependency, en DD-006/D5 en
punt 4 zijn bijgewerkt in `DESIGN.md`. SPEC Q1 is gesloten.

### Oorspronkelijke vraag

1. **`image` als productie-dependency** (pure Dart, geen native code, geen permissies).
   Nodig voor aanpak D (CLAUDE.md: geen nieuwe dependency zonder overleg).
2. **DD-006/D5 en punt 4 bijwerken.** D5 wordt "engine-codec + `package:image`". Punt 4 zegt
   "Compressie draait buiten de UI-isolate"; bij D start de aanroep in de UI-isolate, maar het
   decoderen/verkleinen draait native op engine-threads en het coderen in een `Isolate.run`.
   Voorstel om de eis te formuleren als "blokkeert de UI niet (geen framepauzes)" — dat is wat
   gemeten is. Vastgelegd als aanvulling op Q1 in SPEC §9.

## Reproduceren

```powershell
cd spikes/s2_image_compress
dart run tool/make_fixtures.dart            # testfoto's; eigen foto's in fixtures/real/
flutter drive --profile -d windows --driver=test_driver/integration_test.dart `
  --target=integration_test/s2_test.dart --dart-define=SKIP_ICP=true
flutter drive --profile -d emulator-5554 --driver=test_driver/integration_test.dart `
  --target=integration_test/s2_test.dart
# Crash van image_compress_plus reproduceren (Windows, profile):
flutter drive --profile -d windows --driver=test_driver/integration_test.dart `
  --target=integration_test/s2_crash_test.dart `
  --dart-define=INPUT=fixtures/synthetic/small_o1.jpg
```

`ironpress` is na de Windows-meting uit `pubspec.yaml` gehaald; de aanroep staat als commentaar
in `lib/pipeline.dart`.

## Bronnen

- `image_compress_plus`: https://pub.dev/packages/image_compress_plus ·
  Windows-implementatie: https://pub.dev/packages/image_compress_plus_windows ·
  broncode: https://github.com/WuTangNaiLao/image_compress_plus
- `ironpress`: https://pub.dev/packages/ironpress
- `image`: https://pub.dev/packages/image
- `dart:ui` `instantiateImageCodec`: https://api.flutter.dev/flutter/dart-ui/instantiateImageCodec.html
- Broncode van alle pakketten gelezen in de lokale pub-cache (versies zoals hierboven).
