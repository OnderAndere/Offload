# Spike S1 · Versleutelde database op beide platforms

## English summary

*The report below is in Dutch and kept unchanged as the historical record.*

- **Question:** does an encrypted SQLite database work with Drift on Windows 11 and
  Android 16, including from background isolates (DD-001, DD-007)?
- **Outcome: GO.** Drift 2.35 with `sqlite3` 3.x and the build-hook option
  `source: sqlite3mc` (in the app `pubspec.yaml`) opens, writes and reads an encrypted
  database on both platforms and in every isolate. Without a key or with a wrong key the file
  is unreadable, also to an independent SQLite. `sqlcipher_flutter_libs` is not needed; the
  release manifest has no `INTERNET`.
- **Pitfalls found:** without sqlite3mc, `PRAGMA key` is a silent no-op, so check
  `PRAGMA cipher` on every connection and fail hard; set the cipher explicitly (`chacha20`)
  before the key; escape `'` in the key; the build hook downloads prebuilt binaries at build
  time (sha256-checked, no runtime network); `path_provider_android` pulls in native `jni`.
- **Later:** WAL, a raw 256-bit key and FTS5 were verified in T1.4 (see DD-007).

---

> **Datum:** 24-09-2026 · **Backlog:** S1 (M0) · **Toetst:** DD-001, DD-007 (REQ-004, REQ-009)
> **Code:** `spikes/s1_encrypted_db/` (wegwerpcode, geen productiecode)
>
> ⚠️ **AI-disclaimer:** spike uitgevoerd en beschreven door een AI-assistent (Claude, Anthropic).
> Alle uitkomsten hieronder komen uit daadwerkelijk gedraaide tests op deze machine, tenzij
> expliciet gemarkeerd als *niet getest* of *onzeker*.

## Conclusie

**GO voor DD-001 en DD-007.** Drift 2.35 met `sqlite3` 3.x en de build-hook-optie
`source: sqlite3mc` levert een versleutelde database die op **Windows 11** en **Android 16
(API 36)** opent, schrijft en leest — ook vanuit Drifts achtergrond-isolate en vanuit een
zelf gestarte isolate. Zonder sleutel of met een verkeerde sleutel is het bestand
onleesbaar; ook een onafhankelijke SQLite (Python) weigert het. Er is geen extra runtime-pakket
nodig (`sqlcipher_flutter_libs` vervalt), en het release-manifest bevat geen `INTERNET`.

Geen conflict met SPEC of DESIGN gevonden; §9 is daarom niet aangevuld. Wel enkele
aandachtspunten voor T1.1 en T1.4 (zie *Valkuilen* en *Aanbevelingen*).

## Opzet

- Flutter 3.44.4 (Dart 3.12.2), apart project met ID `eu.marandos.offload.spike_s1`.
- Android: `minSdk 33`, `targetSdk 36` (REQ-009).
- Eén Drift-tabel `notes (id TEXT PK, body TEXT)`; sleutel als constante (met een `'` erin,
  om het escapen te toetsen). Keystore/DPAPI is T1.4.
- Encryptie aangezet in `pubspec.yaml`:

  ```yaml
  hooks:
    user_defines:
      sqlite3:
        source: sqlite3mc
  ```

- Sleutel per verbinding in de `setup`-callback, na een controle dat de cipher echt aanwezig is
  (anders is `PRAGMA key` bij gewone SQLite een stille no-op):

  ```dart
  if (raw.select('PRAGMA cipher;').isEmpty) throw StateError('...');
  raw.execute("PRAGMA key = '${key.replaceAll("'", "''")}';");
  ```

- Tests als `integration_test` (`integration_test/s1_test.dart`), gedraaid met
  `flutter test integration_test/s1_test.dart -d <device>`.

## Resultaten

| Test | Wat | Windows 11 | Android 16 (emulator, x86_64) |
|---|---|---|---|
| T1 | Hoofdisolate: openen met sleutel, insert, select | ✅ | ✅ |
| T2 | `NativeDatabase.createInBackground` (Drift-achtergrondisolate) | ✅ | ✅ |
| T3 | Eigen `Isolate.run`: ruwe `sqlite3` schrijft, Drift leest in dezelfde isolate | ✅ | ✅ |
| T4 | Zonder sleutel: `SQLITE_NOTADB` (26), ook via Drift | ✅ | ✅ |
| T5 | Verkeerde sleutel: faalt | ✅ | ✅ |
| T6 | Bestandsniveau: geen `SQLite format 3`-header, markeertekst niet in bestand of bijbestanden; controle-db zónder sleutel toont beide wél | ✅ | ✅ |

Aanvullend gecontroleerd:

- **Runtime:** `PRAGMA cipher` → `chacha20`; `sqlite3mc_version()` → *SQLite3 Multiple Ciphers
  2.5.0*; `sqlite_version()` → *3.53.4* (op beide platforms gelijk).
- **Onafhankelijk:** Python `sqlite3` (SQLite 3.50.4) opent de controle-db wel en het
  versleutelde bestand niet: `DatabaseError: file is not a database`.
- **Release-APK:** `aapt2 dump permissions` toont géén `INTERNET`. Enige permissie is
  `…DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`, die androidx standaard als eigen
  signature-permissie toevoegt.
- **Gebundelde bibliotheken:** Windows (debug en release) bevat `sqlite3mc.dll` (≈ 2,0 MB) en
  géén gewone `sqlite3.dll`. De APK bevat `libsqlite3mc.so` (≈ 1,9–2,1 MB) per ABI
  (arm64-v8a, armeabi-v7a, x86_64).

## Gebruikte pakketversies

| Pakket | Versie | Soort |
|---|---|---|
| `drift` | 2.35.0 | runtime |
| `sqlite3` | 3.5.2 (3.6.0 bestaat; resolver koos 3.5.2) | runtime |
| `path_provider` | 2.1.6 (android 2.3.1, windows 2.3.0) | runtime |
| `drift_dev` | 2.35.0 | dev |
| `build_runner` | 2.15.1 | dev |
| `integration_test` | SDK | dev |
| transitief, relevant: `hooks` 2.0.2, `native_toolchain_c` 0.19.2, `jni` 1.0.3 / `jni_flutter` 1.0.3 | | |

Toolchain: Flutter 3.44.4, Android SDK 36.1 / NDK 28.2, JBR 21 (Android Studio),
Visual Studio Build Tools 2026 (18.7). Emulator 37.1.11 met image
`system-images;android-36;default;x86_64` (AOSP, zonder Google APIs).

## Valkuilen

1. **De build-hook downloadt tijdens het bouwen.** Standaard haalt `sqlite3` prebuilt
   binaries van GitHub-releases op, gecontroleerd tegen sha256-hashes in de pakketbron
   (bron: `sqlite3/doc/hook.md`). Geen runtime-netwerk, dus géén conflict met REQ-003, maar wel
   relevant voor het dependency-beleid (DD-008) en voor offline/CI-builds. Alternatief:
   `source: source` met een zelf aangeleverde sqlite3mc-amalgamation. Vanaf `sqlite3` 3.5.2
   zijn er SLSA-attestaties en een SBOM; verifiëren kan met `gh attestation verify`.
2. **`PRAGMA key` faalt stil zonder sqlite3mc.** Staat de hook-optie niet goed (bijv. in een
   workspace-root in plaats van de app-pubspec), dan krijg je gewone SQLite en een
   **onversleutelde** database zonder foutmelding. Daarom altijd eerst `PRAGMA cipher`
   controleren — in productie als harde fout, niet alleen als `assert`.
3. **Escapen van de sleutel.** De sleutel gaat als string-literal in een pragma; `'` moet
   verdubbeld worden. Getest met een sleutel met een aanhalingsteken.
4. **Isolates — nuance op de CLAUDE.md-valkuil.** Met `sqlite3` 3.x (build hooks /
   `@Native`) is er **geen** per-isolate initialisatie van de bibliotheek meer nodig (geen
   `open.overrideFor`): T3 werkte in een verse isolate direct. Wat wél per verbinding moet, in
   élke isolate: `PRAGMA key` (en de cipher-controle). De huidige tekst in CLAUDE.md
   ("sqlite3 en de cipher-hooks moeten ook in achtergrond-isolates geïnitialiseerd worden") is
   dus deels achterhaald; voorstel om die bij T1.4 aan te scherpen.
5. **Standaardcipher is ChaCha20-Poly1305** (`chacha20`), niet AES of SQLCipher-compatibel.
   Voor deze app prima, maar leg het expliciet vast. *Onzeker, te verifiëren in T1.4:* volgens
   mijn begrip slaat sqlite3mc het cipherschema niet in het bestand op, zodat een gewijzigde
   standaard in een toekomstige versie bestaande databases onleesbaar zou maken. Expliciet
   `PRAGMA cipher = 'chacha20'` vóór `PRAGMA key` zetten ondervangt dat.
6. **`path_provider_android` 2.3.x trekt `jni` mee.** Daardoor zit `dartjni.dll` ook in de
   Windows-build en `libdartjni.so` in de APK (≈ 60–190 kB). Geen netwerk of permissie, wel
   een punt voor de dependency-allowlist (DD-008).
7. **`sdkmanager` vereist Java 17+.** Op deze machine staat Java 15 op het `PATH`; gebruik
   `JAVA_HOME` = de JBR van Android Studio (`D:\Program Files\Android\Android Studio\jbr`).

## Niet getest

> **Bijgewerkt in T1.4 (25-09-2026):** WAL, ruwe sleutel en FTS5 zijn inmiddels getoetst en in
> orde; zie DD-007 ("Gemeten in T1.4") en `test/data/database/database_encryption_test.dart`.

- **Fysiek ARM64-toestel.** Alleen de x86_64-emulator; de arm64-`.so` zit wel in de APK.
- **WAL-modus.** Drift draaide in de standaard journal-modus; versleuteling van `-wal`-bestanden
  is niet expliciet getoetst.
- **Android-achtergrondengine** (bijv. WorkManager/headless `FlutterEngine`). Getest is een
  Dart-isolate binnen dezelfde engine; een aparte engine laadt dezelfde native bibliotheek,
  maar dat valt onder S3/T4.
- **Ruwe 256-bit sleutel** (`x'…'`) in plaats van een wachtwoordzin met KDF. Voor een
  willekeurige sleutel uit Keystore/DPAPI is dat logischer; openingstijd niet gemeten.
- **FTS5** in de sqlite3mc-build (nodig voor REQ-011). Niet in de scope van S1.

## Aanbevelingen voor M1

- **T1.1:** kies bewust tussen de standaard-download van prebuilt binaries en `source: source`
  (reproduceerbaar/offline bouwen); leg de keuze vast bij DD-008.
- **T1.3/T1.4:** cipher-controle als harde fout; cipher expliciet zetten; sleutel als ruwe
  256-bit waarde; controleren dat FTS5 in de sqlite3mc-build zit; WAL-bestanden meenemen in
  de "geen plaintext op schijf"-test.
- **T1.4:** een variant van T4/T6 behouden als permanente integratietest ("bestand is zonder
  sleutel onleesbaar").

## Reproduceren

```powershell
cd spikes/s1_encrypted_db
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter test integration_test/s1_test.dart -d windows
flutter emulators --launch Offload_API_36
flutter test integration_test/s1_test.dart -d emulator-5554
```

## Bronnen

- Drift — Encryption: https://drift.simonbinder.eu/platforms/encryption/
- `sqlite3` hook-opties: https://github.com/simolus3/sqlite3.dart/blob/main/sqlite3/doc/hook.md
- `sqlite3` op pub.dev: https://pub.dev/packages/sqlite3
