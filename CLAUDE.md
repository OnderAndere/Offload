# CLAUDE.md — werkafspraken voor dit project

Offload is een **persoonlijke, volledig offline** app om lopend werk, toekomstig werk,
ideeën en verzoeken van anderen vast te leggen. Android + Windows 11, Flutter.

**Identiteit (vastgelegd, niet wijzigen):**
- App-naam: **Offload**
- Application ID / package: `eu.marandos.offload` — permanent, ook op Windows
- Repository: `offload`

**Lees eerst:** [`SPEC.md`](SPEC.md) (eisen, REQ-xxx) en [`DESIGN.md`](DESIGN.md)
(ontwerpbeslissingen, DD-xxx). Bij twijfel is SPEC leidend boven bestaande code.

---

## Harde regels (niet afwijken zonder overleg)

1. **Geen netwerk.** De release-build bevat géén `android.permission.INTERNET` (REQ-003).
   Geen HTTP-clients, geen SDK's die netwerken, geen analytics of crash-reporting (REQ-015).
   Twijfel je over een dependency? Controleer eerst de manifest-permissies en vraag het na.
2. **Alles versleuteld op schijf.** Database via SQLite3MultipleCiphers, elke bijlage los
   met AES-256-GCM (DD-006, DD-007). Nooit een bijlage onversleuteld wegschrijven, ook niet
   tijdelijk, behalve via de expliciete "openen in externe app"-actie die zelf opruimt, en de
   foto die de camera-app van het toestel in Offloads eigen cache schrijft (`cache/camera/`):
   die wordt direct na inlezen gewist, ook bij annuleren, en restanten bij de start (PO
   10-10-2026, T5.3, DD-018 punt 19).
   Verder alleen onversleuteld wat de gebruiker bewust naar buiten stuurt: export (DD-007),
   vCard en gedeelde tekst (DD-014). Tijdelijke kopieën in de eigen cache worden opgeruimd;
   een bestand dat de gebruiker zelf opslaat nooit. Een sync-pakket is altijd versleuteld
   (DD-013).
3. **Geen hardcoded UI-strings.** Alles via `gen-l10n`/ARB. `app_nl.arb` is het template,
   `app_en.arb` de vertaling (DD-009). Ook foutmeldingen en widget-teksten.
4. **UUID's, geen auto-increment.** Plus HLC, tombstones en wijzigingslog op elke entiteit
   (REQ-008, DD-003). Ook als synchronisatie nu niet gebouwd wordt. Uitzonderingen alleen
   zoals vastgelegd in DD-003 (afgeleide `tokens`, lokale tabellen).
5. **Geen exacte alarmen.** Geen `SCHEDULE_EXACT_ALARM` of `USE_EXACT_ALARM` (DD-005).
6. **Geen schema-kolom voor afgeleide data.** Het miniatuurpad wordt afgeleid, niet opgeslagen
   (DD-006/D3).
7. **Vastleggen mag nooit trager worden.** De snelle-invoerroute laadt geen lijsten, geen
   zware state. Eerst opslaan, daarna parsen en indexeren (REQ-001).

## Taal

- **Code, identifiers, commentaar, tests, commits en alle bestands- en mapnamen: Engels.**
  Het project wordt later op GitHub gepubliceerd. Nederlands alleen in gebruikersteksten
  (`app_nl.arb`), in de spikeverslagen, in dit bestand en straks in de Nederlandse vertaling
  van de handleiding (`docs/user-manual/nl/`, T8.5) (zie hieronder).
- **UI-teksten: Nederlands als bron** (ARB), Engels als vertaling.
- **Projectdocumenten (`SPEC.md`, `DESIGN.md`, `BACKLOG.md`, `docs/design/`): Engels** (besluit
  PO 28-09-2026). Schermnamen en UI-teksten daarin in het Engels zoals in `app_en.arb`; de
  Nederlandse tekst er letterlijk bij waar die ertoe doet.
- **Spikeverslagen (`docs/spikes/`):** historisch verslag, blijven Nederlands, met een korte Engelse
  samenvatting bovenaan. Een nieuw spikeverslag schrijf je in het Engels.
- **Handleiding (`docs/user-manual/en/`): Engels als basis** (besluit PO 09-10-2026, herziet het
  eerdere "Nederlands"). Eén keer vertaald (T8.12); de `docs-writer` houdt alleen de Engelse
  bij, met de labels uit `app_en.arb`. Een Nederlandse vertaling (`nl/`, vanuit het Engels)
  volgt bij T8.5. Het overzicht "wat zit er al in" staat in `docs/features.md` (Engels), buiten
  de handleiding (DD-020).
- **Dit bestand (`CLAUDE.md`):** werkafspraken met de PO, in het Nederlands.

## Architectuur

```
lib/
  presentation/   schermen, widgets, state (Riverpod)
  domain/         entiteiten, use cases, InlineTokenRegistry — puur Dart
  data/           Drift-repositories, AttachmentStore, CryptoService, PhotoStorageService
  platform/       CaptureChannel, ReminderScheduler, SpeechTranscriber, KeyStore, ShareChannel
  l10n/           ARB-bestanden
android/  windows/  test/  integration_test/
```

- `domain/` importeert **niets** uit `data/`, `platform/` of Flutter-UI. Puur Dart, volledig
  unit-testbaar.
- `platform/` bevat per capability een abstracte klasse plus implementaties per platform.
  Altijd een fake voor tests.
- Geen platformcode (`dart:io`-takken, `Platform.isAndroid`) buiten `platform/`.

## Werkwijze

- **Eén taak per keer**, uit `BACKLOG.md`. Werk het item bij als het klaar is.
- **Voor je begint:** benoem welke REQ/DD je implementeert. Staat het er niet in, vraag het
  dan — voeg geen eisen toe op eigen gezag.
- **Conflict tussen spec en werkelijkheid?** Melden, niet zelf oplossen. Zet het als open punt
  in `SPEC.md` §9.
- Kleine, zelfstandige commits. Conventional commits: `feat:`, `fix:`, `test:`, `docs:`,
  `refactor:`, `chore:`.
- **Versienaam (DD-008): `dart run tool/bump_version.dart task`** in de commit die een taak
  afsluit, ná het bijwerken van `CHANGELOG.md` en vóór het stagen. De laatste taak van een
  mijlpaal draait `milestone` in plaats van `task`. Alleen taken met een voor de gebruiker
  zichtbare wijziging; fixes en taken zonder zichtbare wijziging verhogen de naam niet (een fix
  komt onder *Fixed* in `[Unreleased]`). `1.0.0` alleen met de PO.
- Geen nieuwe dependency zonder overleg. Wel toegestaan zonder vragen: dev-dependencies voor
  tests en lints.

## Agents en poorten

Twee project-agents in `.claude/agents/`, afgedwongen met hooks in `.claude/settings.json`
(scripts in `.claude/hooks/`; een bash-voorfilter start PowerShell alleen als het nodig is).
Rapporten van de agents zijn Engels, net als de handleiding.

- **`architecture-reviewer`** (Opus; de rol "architecture agent" uit SPEC/DESIGN) — code- en
  architectuurreview. Werkwijze per taak:
  1. taak af en getest (analyze, test, draait op Android/Windows);
  2. stagen met `git add` in een **aparte** aanroep;
  3. `architecture-reviewer` draaien op de staged wijzigingen; bij FAIL herstellen, opnieuw
     stagen en opnieuw reviewen;
  4. bij PASS committen met `git commit` als **enige** git-opdracht in de aanroep, zonder
     bestandsnamen, `--`, `-a`, `-o`, `-i` of `-p`. Commit-boodschap via `-F <bestand>` of
     `@'…'@ | git commit -F -` (niet als argument).
  De hook `review-gate.ps1` blokkeert elke commit waarvan de staged inhoud niet exact is
  goedgekeurd (`git write-tree`), en ook `merge`, `cherry-pick`, `revert`, `rebase`, `am` en
  `pull` (die vragen de product owner). Hij blokkeert bij twijfel of fouten. Vrijgesteld:
  commits met alleen `.md`-bestanden, behalve `CLAUDE.md` en alles onder `.claude/`.
  Alleen de reviewer zelf mag `approve-review.ps1` aanroepen (afspraak, niet technisch
  afgedwongen).
- **`docs-writer`** (Sonnet; de rol "documentation agent" uit BACKLOG) — houdt
  `docs/user-manual/en/` (Engels), `docs/features.md` en `CHANGELOG.md` (Engels) bij. Hij
  draait **vóór** een release-build voor gebruik, niet erna, zodat de meegebouwde handleiding
  bij de gebouwde code hoort (DD-020). Volgorde: taak committen → `docs-writer` →
  zijn wijzigingen committen → `build_release.dart … --copy`. Hij legt met `mark-docs.ps1`
  vast welke codestand hij beschreef (op inhoud, zonder zijn eigen uitvoer);
  `build_release.dart --copy` weigert te bouwen als dat niet de huidige codestand is, een
  testbuild zonder `--copy` waarschuwt alleen. Hij beschrijft alleen wat geïmplementeerd en
  gecommit is, en commit niet zelf.
- De hooks gelden alleen voor wat Claude uitvoert; handmatige commits in VS Code gaan er buiten.

## Definition of done

- [ ] Unit-tests voor domeinlogica; widget-tests voor niet-triviale schermen
- [ ] Nederlandse én Engelse strings aanwezig
- [ ] `flutter analyze` schoon, `dart format` toegepast
- [ ] Draait op Android én Windows (of het platformverschil is expliciet gedocumenteerd)
- [ ] Geen nieuwe permissie in het manifest; `tool/check_permissions.sh` en
      `tool/check_dependencies.sh` slagen op de release-builds
- [ ] *Over Offload* actueel (REQ-062): een nieuwe native bibliotheek of een meegeleverd font of
      ander onderdeel van derden heeft zijn licentie in `bundledLicenses`
      (`lib/domain/app/bundled_licenses.dart`). `test/presentation/about/` faalt anders voor native
      bibliotheken en fonts; code van derden ín een bibliotheek (zoals in SQLite3MultipleCiphers)
      controleer je zelf in de bron. Bij de laatste taak van een mijlpaal: de doeltekst
      (`aboutPurpose`) klopt nog met wat de app doet
- [ ] Bijbehorende REQ genoemd in de commit-boodschap
- [ ] Bestandsnamen, identifiers en commentaar in het Engels
- [ ] `architecture-reviewer`: PASS op de staged wijzigingen (vóór de commit)
- [ ] Vóór een release-build voor gebruik (`--copy`): `docs-writer` gedraaid en zijn wijzigingen
      gecommit (`build_release.dart` controleert het)

## Commando's

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # Drift + codegen
flutter analyze && dart format --set-exit-if-changed .
tool/check_hardcoded_strings.sh   # geen letterlijke teksten in lib/presentation/ (DD-009)
flutter test
flutter run -d windows
dart run tool/bump_version.dart task|milestone   # versienaam 0.M.y + CHANGELOG-kop (DD-008)
# release-builds (REQ-060): buildnummer = aantal commits, plus versie en buildmoment voor
# Instellingen; stopt vóór de APK de Gradle-daemon en controleert het uitvoerbestand
dart run tool/build_release.dart apk       # zet eerst JAVA_HOME (zie hieronder)
dart run tool/build_release.dart windows
# kopie voor gebruik (alleen vanaf een schone stand, na akkoord PO en na de docs-writer): --copy,
# naar een map per build onder $OFFLOAD_RELEASE_DIR (lokale instelling, staat niet in de repo)
dart run tool/build_release.dart apk --copy
tool/check_permissions.sh    # release-APK: alleen permissies uit tool/allowed_permissions.txt
tool/check_dependencies.sh   # pakketten en native libs alleen uit tool/allowed_*.txt
powershell -File tool/check_windows_shell.ps1   # sneltoets/systeemvak op de Windows-release (handmatig, bureaublad nodig)
powershell -File tool/windows_ui_run.ps1 -Out x.png -KeysFile keys.txt   # Windows-release in zandbak: klik, toetsen, screenshot
```

De twee `tool/check_*.sh`-scripts zijn de release-poort (DD-008): draai ze na elke
`flutter build apk --release` (en `flutter build windows --release` voor de DLL-controle).
Een regel toevoegen aan een `tool/allowed_*.txt` vraagt akkoord van de product owner.

## Ontwikkelomgeving (deze machine)

Windows 11, PowerShell 5.1. Tools die **niet** op het `PATH` staan; gebruik deze paden. De paden die per
machine verschillen (JDK, vcpkg, Git Bash) staan in `CLAUDE.local.md` (niet in de repo, T8.16):

| Tool | Pad / gebruik |
|---|---|
| `adb` | `$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe` — in PowerShell: `$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"; & $adb devices` |
| `emulator` | `$env:LOCALAPPDATA\Android\Sdk\emulator\emulator.exe -avd Offload_API_36` (op de achtergrond starten) |
| `sdkmanager`, `avdmanager` | `$env:LOCALAPPDATA\Android\Sdk\cmdline-tools\latest\bin\` — vereisen Java 17+ |
| Java voor Android-builds | `$env:JAVA_HOME` naar de `jbr` van Android Studio (JBR 21, pad in `CLAUDE.local.md`). Op het `PATH` staat Java 15; die is te oud |
| `vcpkg` | in de Visual Studio Build Tools, pad in `CLAUDE.local.md` (alleen nodig als een Windows-plugin het vraagt) |

- **Test-emulator:** `Offload_API_36` (Android 16 / API 36, AOSP-image zonder Google APIs),
  device-id `emulator-5554` zodra hij draait. Controleer met `flutter devices`.
- **Windows-app handmatig testen zonder echte data:** start de exe met `$env:LOCALAPPDATA` naar een
  tijdelijke map; database én sleutel komen dan daar (zie `tool/check_windows_shell.ps1`). Er mag
  geen andere Offload draaien (één instantie).
- **Windows-UI bekijken en met toetsen bedienen:** `powershell -File tool/windows_ui_run.ps1 -Out
  x.png -KeysFile keys.txt` start de release in zo'n zandbak, klikt, stuurt toetsen en maakt een
  screenshot van het venster (uitleg bovenin het script). Wat we daarbij leerden:
  - **Eerst klikken in het venster.** Windows laat een achtergrondproces een venster niet naar voren
    halen (`SetForegroundWindow` wordt genegeerd); zonder klik gaan de toetsen naar een ander venster
    (bijvoorbeeld VS Code). Klik op de titelbalk om niets in de app te raken.
  - **Ctrl-combinaties als echte toetsaanslagen mét scancode** (`keybd_event(vk,
    MapVirtualKey(vk, 0), …)`, in het script `VK:11+32`). Met scancode 0, en ook met `SendKeys`
    `^n`, ziet Flutter tussen Ctrl en de letter een Ctrl-omhoog, zodat de combinatie nooit aankomt;
    dat leek een fout in de app, maar was de simulatie. `SendKeys` is prima voor tekst, `{ENTER}` en
    pijltjes.
  - **Pijltjes en Delete via `SendKeys`** (`{DOWN}`, `{RIGHT}`, `{DEL}`), niet als `VK:27` of
    `VK:2E`: zonder de extended-key-vlag komen die aan als numpad-toets. Dat leek twee keer een fout
    in de app (01-10 en 02-10-2026). Esc als `VK:1B` werkt wel.
  - **Tussendoor klikken, screenshots en wachten:** in het toetsenbestand `CLICK:x,y` (vanaf de
    linkerbovenhoek van het venster, titelbalk meegeteld), `SHOT:bestand.png` (het vensterdeel nú,
    ook een venster erboven zoals "Opslaan als") en `WAIT:ms`. Werkwijze: eerst een screenshot om
    coördinaten te vinden, dan per ronde een stap verder.
  - **Enter in een invoerveld met open suggestielijst** (bv. na `!vandaag`) kiest eerst de
    suggestie; pas de tweede Enter slaat op.
  - **Toetsen die Flutter ontvangt uitlezen:** tijdelijk een `debugPrint` in de handler en de app
    starten met `flutter run -d windows --profile` (met `$env:LOCALAPPDATA` naar een tijdelijke
    map); de uitvoer staat in de log. In profile/release zijn `debugName`s van toetsen `null`.
- **Tijd meten op het toestel:** `& $adb shell 'date +%s%3N'` geeft epoch-milliseconden; handig
  om als `--el t0 <ms>` aan een `am start` mee te geven.
- **Schermtoetsenbord op de emulator:** de AVD heeft een hardwaretoetsenbord, waardoor Android
  het schermtoetsenbord onderdrukt. Zet het aan met
  `& $adb shell settings put secure show_ime_with_hard_keyboard 1`.
- **Schermafbeelding:** `& $adb shell screencap -p /sdcard/x.png; & $adb pull /sdcard/x.png <pad>`.
  Niet via `>` omleiden: PowerShell verminkt binaire uitvoer.
- **PowerShell en native commando's:** `Select-Object -First n` stopt het commando zodra er genoeg
  regels zijn (bij `adb shell "a; b"` wordt `b` dan niet uitgevoerd). Eerst alle uitvoer inlezen.
- `am start -W` kan op de emulator blijven hangen; gebruik `am start` plus een wachttijd.
- `run-as <pakket>` (bestanden van de app bekijken) werkt alleen bij debug-builds.
- **Android-build hangt (meerdere keren voorgekomen).** Oorzaak: een Gradle-daemon
  van een eerdere build heeft zijn console verloren. Elk hulpproces dat hij start blijft dan
  hangen, met een `conhost.exe` op hoge CPU: eerder `llvm-objcopy`
  (`extractReleaseNativeSymbolTables`), ook `const_finder` en `flutter assemble`
  (`cmd.exe /c …dart…` onder een `java.exe`). Kenmerk: geen voortgang, geen nieuwe uitvoer.
  - **Voorkomen:** `tool/build_release.dart apk` stopt de daemon vóór het bouwen en controleert
    na afloop de tijdstempel van de APK ("exit 0" alleen bewijst niet dat er gebouwd is). Bouw je
    zonder dat script, stop de daemon dan eerst zelf:
    `$env:JAVA_HOME` zetten (zie boven) en dan `& .\android\gradlew.bat -p android --stop`.
    Bouw APK en Windows in **aparte** aanroepen (niet achter elkaar in één commando).
  - **Herstellen:** met `Get-CimInstance Win32_Process` (kolommen `ProcessId`,
    `ParentProcessId`, `CommandLine`) twee bomen zoeken en elk stoppen met
    `taskkill /T /F /PID <pid>`: de hangende `flutter build`, én de `java.exe` waarvan de
    `CommandLine` `GradleDaemon` bevat. De hangende hulpprocessen hangen onder díe daemon,
    niet onder `flutter build`, en `gradlew --stop` alleen laat ze op Windows als wees achter.
    Daarna `gradlew --stop` zoals hierboven en opnieuw bouwen.
  - Stop alleen processen die aantoonbaar bij de build horen: op deze machine draaien ook
    `conhost.exe`-processen van podman met hoge CPU, en een Java-proces van een andere ontwikkeltool.
- **Bash-scripts (`tool/*.sh`) via Git Bash draaien.** Vanuit PowerShell wijst `bash` naar de
  WSL-bash in `C:\Windows\system32` (exitcode 127). Gebruik de Bash-tool, of vanuit PowerShell
  de `bash.exe` van Git for Windows (pad in `CLAUDE.local.md`), bv. `& $gitBash tool/check_permissions.sh`.

## Valkuilen (eerder geraakt of voorzien)

- Flutter zet `INTERNET` standaard in de **debug-** en **profile-**manifesten. De controle
  geldt het samengevoegde **release**-manifest.
- Foto's: EXIF-rotatie op de pixels toepassen **vóór** het strippen van EXIF, anders staan ze
  scheef (DD-006/D4).
- Miniaturen renderen via een eigen `ImageProvider` met `attachmentId` als cache-sleutel, plus
  `cacheWidth`. Een verse `MemoryImage` per frame omzeilt de cache en dan is de hele
  foto-pijplijn voor niets (DD-006, punt 5).
- **Versleutelde database** (zie `docs/spikes/S1-encrypted-db.md`):
  - Encryptie staat aan via `hooks.user_defines.sqlite3.source: sqlite3mc` in de
    **app-`pubspec.yaml`**. Geen `sqlcipher_flutter_libs`.
  - Staat die optie verkeerd, dan krijg je gewone SQLite en is `PRAGMA key` een **stille
    no-op**: een onversleutelde database zonder foutmelding. Controleer daarom bij elke
    verbinding eerst `PRAGMA cipher` en gooi een harde fout (geen `assert`).
  - Zet de cipher expliciet (`PRAGMA cipher = 'chacha20'`) vóór `PRAGMA key`; vertrouw niet
    op de standaard van de bibliotheek.
  - Sleutel in een pragma altijd escapen (`'` → `''`).
  - Isolates: de bibliotheek hoeft niet per isolate geïnitialiseerd te worden (build hooks),
    maar **elke verbinding, in elke isolate**, moet cipher-controle en `PRAGMA key` doen.
    Gebruik daarvoor één gedeelde setup-functie in de `setup`-callback.
  - De `sqlite3`-build-hook downloadt bij het bouwen prebuilt binaries van GitHub
    (sha256-gecontroleerd). Geen runtime-netwerk, wel een punt voor offline/CI-builds.
- **Dependencies trekken soms native code mee:** `path_provider_android` ≥ 2.3 brengt `jni`
  mee (`dartjni.dll` / `libdartjni.so`, ook in de Windows-build). Neem transitieve native
  bibliotheken mee in de dependency-review (DD-008).
- **Kotlin-plugins en twee schijven:** het project staat op `D:`, de pub-cache op `C:`. Dan faalt
  Kotlins incrementele compilatie ("Could not close incremental caches"). Zet
  `kotlin.incremental=false` in `android/gradle.properties` (zie `docs/spikes/S2-image-compress.md`).
- **Geen BOM in buildbestanden.** PowerShell 5.1 schrijft met `Set-Content -Encoding utf8` een
  BOM; vooraan `build.gradle.kts` breekt dat de Kotlin-DSL (`kotlin {}` onbekend). Bewerk via de
  editor of schrijf met `New-Object System.Text.UTF8Encoding($false)`.
- Inline-parser: de ruwe tekst blijft altijd bewaard; tokens zijn afgeleide data met een
  `parserVersion` (DD-004).
- **Widgettests met live Drift-queries hangen zonder melding.** Een gesloten stream-query laat
  een timer achter in de nep-tijd van de test; de database sluiten wacht daar dan eeuwig op, en
  `--timeout` vangt dat niet. Gebruik voor elk scherm dat een Drift-stream toont
  `testDriftWidgets` uit `test/fakes/drift_widgets.dart` (ruimt ook op bij een fout).
  Hulpbestanden in `test/` heten niet `*_test.dart`, anders ziet `flutter test` ze als test.
  Ook `await repository.watch…().first` in de test zelf wacht eeuwig (30-09-2026); lees gegevens
  in een widgettest met een gewone query (`select(…).get()`).
- **`tester.enterText` bouwt niet opnieuw op.** Na `enterText` eerst `await tester.pump()`, vóór
  een stap die op de nieuwe tekst leunt (bv. `testTextInput.receiveAction(TextInputAction.done)`).
  Zonder pump roept het veld de `onSubmitted` van de vorige build aan, met de oude tekst; dat leek
  een fout in de keuzelijst (30-09-2026). In de app zelf: lees in `onSubmitted` de tekst uit de
  controller, niet uit waarden die bij de laatste build zijn uitgerekend.
- **`\uXXXX`-escapes worden bij het schrijven echte tekens.** Via de bewerkingstools (en in
  Python-heredocs) wordt `'\uFEFF'` in de broncode een onzichtbaar teken. Controleer na het
  schrijven van escapes op onzichtbare tekens (Unicode-categorie Z, Cc, Cf); bouw in scripts de
  backslash op met `chr(92)`.
- **Integratietests wissen de app op het toestel.** `flutter test integration_test -d <toestel>`
  verwijdert de app na afloop (standaard `--uninstall`), met alle data en Keystore-sleutels. Nooit
  draaien op een toestel met echte gegevens; op de emulator is het geen probleem. Moet de app
  blijven staan, gebruik dan `--no-uninstall`.
- **Tests draaien:** via de Bash-tool met een harde grens en zichtbare voortgang
  (`timeout 600 flutter test --timeout 30s -r expanded`), niet via PowerShell met
  `Select-Object -Last`: dat houdt alle uitvoer vast tot het einde, zodat een vastloper onzichtbaar
  blijft. Een nieuw widgettestbestand eerst los draaien.
- **Een widgettest bewijst niet dat een sneltoets op Windows werkt.** `tester.sendKeyEvent` gaat
  niet door de echte invoerweg van Windows. Controleer elke nieuwe sneltoets ook in de
  Windows-release met `tool/windows_ui_run.ps1` (met `VK:` en scancode, zie boven), vóór je
  concludeert dat hij wel of niet werkt.
- **F10 zet het Windows-venster in menumodus**, ook Shift+F10 (het contextmenu van de app). De
  volgende toets, bijvoorbeeld Esc, gaat dan naar Windows in plaats van naar het open menu. De
  runner (`windows/runner/flutter_window.cpp`) negeert daarom `WM_SYSCOMMAND`/`SC_KEYMENU` met
  `lparam` 0 (02-10-2026). Haal dat er niet uit; Alt+Spatie blijft werken.
- **Pijltjes tussen rijen: `focusInDirection`, niet `nextFocus`.** `nextFocus`/`previousFocus`
  volgt de leesvolgorde over het hele venster en springt op Windows naar het andere paneel. Voor
  ↑/↓ binnen een lijst gebruik je `focusInDirection(TraversalDirection.down/up)` (02-10-2026).
- **`flutter build windows` kan ook vastlopen** (29-09-2026: geen uitvoer meer, na 10 minuten
  afgebroken; een tweede poging liep in een minuut). Bouw met een harde grens op de achtergrond
  (`timeout 800 dart run tool/build_release.dart windows`) en kijk bij stilstand met
  `Get-CimInstance Win32_Process` naar `cmake`/`MSBuild`/`flutter assemble`. De `dart … daemon` van
  VS Code hoort er niet bij: laat die staan.
- **Alle `flutter`/`dart`-opdrachten hangen stil** (01-10-2026: zelfs `flutter --version` gaf na
  2 minuten niets). Oorzaak: een eerdere opdracht (hier `dart format` vanuit Bash) bleef hangen in
  Flutters eigen versiecontrole (`cmd /c PUSHD …\flutter & $git rev-parse HEAD`) en hield het slot
  `flutter\bin\cache\flutter.bat.lock` vast; elke volgende opdracht wacht daarop, zonder melding.
  Zoek met `Get-CimInstance Win32_Process` naar een `CommandLine` met `rev-parse` of `dart.bat` en
  stop die boom met `taskkill /T /F /PID <bash-ouder>`. Alleen de eigen, hangende opdracht; de
  `flutter.bat daemon` en `dart language-server` van VS Code laat je staan.

## Wat je niet doet

- Geen "handige" cloudback-up, sync, of het ophalen van link-previews.
- Geen telemetrie, geen "anonieme" statistieken.
- Geen bibliotheek toevoegen die Google Play Services vereist.
- Geen refactor van een laag die niet bij je taak hoort. Stel het voor in `BACKLOG.md`.
