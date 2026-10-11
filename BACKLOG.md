# BACKLOG.md — Offload

The order is deliberate: first the risks, then a thin vertical slice through all layers, only
after that features in breadth. References: `SPEC.md` (REQ-xxx), `DESIGN.md` (DD-xxx).
Translated from Dutch to English on 28-09-2026 (PO decision); content unchanged.

Status: `[ ]` open · `[~]` in progress · `[x]` done · `[!]` blocked

---

## M0 · Spikes (throwaway code, time box 1 day each)

Goal: test the four assumptions that could bring the spec down. The result is a note in
`docs/spikes/`, not production code. If a spike fails, the spec changes first.

- [x] **S1 · Encrypted database on both platforms** — Drift ≥ 2.32 with
      SQLite3MultipleCiphers, opening and reading on Android and Windows, also from a
      background isolate. *Done when:* a test database opens on both platforms and the file is
      unreadable without the key. (DD-001, DD-007)
      → **GO**, see [`docs/spikes/S1-encrypted-db.md`](docs/spikes/S1-encrypted-db.md)
- [x] **S2 · Compression library with Windows support** — compare `image_compress_plus` and
      `ironpress`: do scaling + orientation correction + EXIF stripping work on Android and
      Windows? *Done when:* a recommendation is in `docs/spikes/` and SPEC Q1 can be closed.
      (DD-006, REQ-009)
      → both candidates **no-go**; decided: engine codec (`dart:ui`) + `package:image`
      (DD-006/D5). Q1 closed. See [`docs/spikes/S2-image-compress.md`](docs/spikes/S2-image-compress.md)
- [x] **S3 · Home-screen widget to Flutter** — the widget writes text that the app picks up,
      without starting the app. *Done when:* an item arrives within 3 s after the tap. (REQ-001,
      DD-010)
      → advice **variant A** (native window + encrypted, loss-free queue); loss tests
      17/17 passed; loss-free added as an AC to REQ-001. The 3 s measurement on the own device
      is optional (PO) and moved to T1.7.
      See [`docs/spikes/S3-widget.md`](docs/spikes/S3-widget.md)
- [x] **S4 · whisper.cpp through `dart:ffi`** — build for Android (NDK) and Windows, model
      imported by hand, transcribe one WAV in Dutch. *Done when:* the transcription time and
      model size are measured (SPEC Q4). (DD-002)
      → **GO**; Q4 decided: `ggml-small-q5_1` (181 MB). Speed on the phone not measured yet
      (the emulator is not representative), follows in T6.1. See [`docs/spikes/S4-whisper.md`](docs/spikes/S4-whisper.md)
- [x] **S6 · Handwriting from a photo with a small vision model** (REQ-064, DD-010, DD-002; PO
      09-10-2026) — llama.cpp (`llama-mtmd-cli`, GGUF + `mmproj`) on Windows (CPU) first.
      Candidates: SmolVLM-500M, InternVL3-2B, Qwen2.5-VL-3B, Gemma 4 E2B, plus Qwen3-VL-2B (PO:
      yes, as another candidate within the size limit); per model source, version, licence, size and SHA-256,
      and privacy and offline behaviour. Test set: about 10 photos made by the PO (whiteboard and
      notebook, fictional content), kept outside the repository. Measure per model and prompt
      variant: tokens exactly right (per kind), lines split correctly, character error rate, time
      per photo, peak memory; plus the effect of straightening and contrast beforehand
      (`package:image`). Why not ML Kit, Windows.Media.Ocr or Tesseract: argued with sources.
      *Done when:* `docs/spikes/S6-handwriting.md` gives GO/NO-GO, the model (the smallest that is
      good enough, at most 1.5 GB on Android; raised from 1 GB by the PO on 09-10-2026), the expected size and speed on the phone, and the
      native cost (`allowed_native_libs`, `bundledLicenses`; a separate question to the PO). The
      phone measurement only after GO, together with the Whisper measurement of T6.1. Also says
      whether the same model could answer Q14 (business cards, S5)
      — *PO 10-10-2026 (SPEC Q45):* the report also advises on cropping and straightening a photo (four corners):
      does straightening help the model enough to offer it in M6a, and should the photo capture of T5.3 get it too
      — *done 11-10-2026:* `docs/spikes/S6-handwriting.md` (c7b3dda). **GO (PO 11-10-2026)** with Qwen3-VL-2B (1,552 MB,
      Apache-2.0) at 1280 px and context 2048: about 5 % character errors, 77 % of the tokens exact after a small
      clean-up, 20–41 s and 3.0 GB on the PC (DD-021). PO decisions: the phone measurement is the gate and first task
      of M6a (not killed, at most about 2 minutes per photo; fallback `--image-max-tokens 512`); the `-` convention
      stays (Q44); four-corner straightening in M6a, *rotate 90°* for attachments (Q45, T5.9); M6a before M6, the
      Whisper measurement stays with T6.1 (Q43); llama.cpp's native libraries and MIT licence allowed. Q14: probably
      the same model, untested

## M1 · Walking skeleton

One vertical slice through all layers. Proves S1, S3 and the project structure in working form.

- [x] **T1.1** Project set-up: Flutter app, folders according to `CLAUDE.md`, lints, `build_runner`
      — *from S1:* decide whether the sqlite3mc binaries come as a prebuilt download (default)
      or are built from source (`source: source`); record the choice in DD-008
      → decided: prebuilt download (DD-008). Runs on Windows and Android 16 (emulator)
- [x] **T1.2** `tool/check_permissions.sh` + a CI step that fails on `INTERNET` in the
      release manifest (REQ-003, DD-008) — *from S1:* set up a dependency allowlist, including
      transitive native libraries (e.g. `jni` through `path_provider_android`)
      → `tool/check_permissions.sh` (allowlist of permissions) and `tool/check_dependencies.sh`
      (packages + `.so`/`.dll`); no CI while the repo is local: scripts in the DoD,
      GitHub Actions in T8.7 (PO decision, option A)
- [x] **T1.3** Drift schema v1: Item, Person, Context, Tag, Attachment, ItemLink, Token,
      ChangeLog — with UUID, HLC, tombstone (REQ-008)
      → `lib/data/database/` (schema dump in `drift_schemas/`), `Hlc` and UUIDv7 in
      `lib/domain/`; tokens without sync columns (DD-003); the app does not open a
      database file yet (encryption first, T1.4)
- [x] **T1.4** `CryptoService` + key in Keystore/DPAPI; database encrypted from the
      first run (REQ-004) — *from S1:* set the cipher explicitly (`chacha20`) and verify whether
      sqlite3mc stores the scheme in the file; cipher check as a hard error; raw
      256-bit key; check FTS5 in the build; include WAL files in a permanent
      "unreadable without key" integration test — *PO decision 25-09-2026 (DD-007):* own
      `KeyStore` with a fake (no `flutter_secure_storage`); master key as a wrapped file;
      HKDF-SHA256 per purpose; database without key = hard error, never a new key;
      `allowBackup="false"` plus `dataExtractionRules` (cloud-backup and device-transfer)
      — *done 25-09-2026:* `lib/platform/key_store/` (Android through `KeyStoreChannel.kt`,
      Windows through DPAPI/`dart:ffi`), `lib/data/crypto/` (HKDF, `CryptoService`),
      `lib/data/database/database_encryption.dart`; `crypto` as a direct dependency (approved by
      the PO). Measured: the raw key works (opening ~6 ms, with passphrase KDF ~33 ms); the cipher
      is not in the file (another cipher cannot open it); FTS5 present; WAL file
      encrypted. Integration test `integration_test/encryption_test.dart` green on the Android 16
      emulator and Windows. The app does not connect the database yet (T1.6)
- [x] **T1.5** i18n set-up with `app_nl.arb` and `app_en.arb`; language choice in Settings
      (REQ-005, REQ-029) — set up so that a third language (Ukrainian, T8.6) is only an extra
      ARB file and a choice option. *Done 25-09-2026:* `gen-l10n` (NL source, EN), language choice
      System / one option per ARB file in its own language; default the system language, otherwise
      English (AC REQ-029). Riverpod 2.6 (not 3.x: that pulls `flutter_test` into the app). The
      choice is not stored yet: store it in `local_state` in T1.6. Check `tool/check_hardcoded_strings.sh`.
      A new language = only an ARB file (proven by `test/l10n/arb_files_test.dart`)
- [x] **T1.5b** Change log replayable on its own: payload with the full new field values and
      a format version; test "replaying the log on an empty database = same content" (REQ-037, DD-003) —
      before T1.6, because after that a change is a migration; basis for the sync in M9
      — in the same schema change: the owner of an attachment becomes item *or* person (REQ-041,
      DD-006); changing it later needs a table rebuild. Contact details themselves follow in T3.5
      — *done 25-09-2026:* format v1 recorded in DD-003; `lib/data/sync/` with
      `ChangeLogWriter` (row + log entry in one transaction, only really changed columns,
      UTC mandatory) and `ChangeLogReplayer`; `attachments.person_id` with a CHECK "exactly one
      owner". Schema v1 changed without a migration (no data yet). Test: replaying the log on an
      empty database gives the same content, also in reverse order
- [x] **T1.6** Quick capture → save item → inbox list (reactive Drift stream)
      — *from T1.4:* determine the database folder without `path_provider` (Android: through the own
      channel, e.g. `filesDir`; Windows: `%LOCALAPPDATA%\eu.marandos.offload`, where the key also
      is); `existingDataFound` = the database file exists; make errors from `CryptoService`
      visible with an ARB message, never silently a new database; in
      `WindowsKeyStore.createMasterKey` pass file errors on as `KeyStoreException` and make
      cleaning up the temporary file best-effort (review T1.4)
      — *from T1.5:* store the language choice (`languageChoiceProvider`) in `local_state` and read
      it at start-up (REQ-029)
      — *from T1.5b:* repositories write only through `ChangeLogWriter`; device id in
      `local_state`, last HLC at start-up from the change log (see step A) (DD-003)
      — *step A done 25-09-2026:* `AppDirectory` (Android channel, Windows), `AppStorage`
      (opening, device id, clock, language choice stored), loading and error screen, `WindowsKeyStore`
      points from T1.4. The last HLC comes from the change log, not from `local_state` (approved by
      the PO). Integration test `integration_test/app_storage_test.dart` on Android and Windows
      — *step B done 27-09-2026:* **Windows: one instance** (`windows/runner/single_instance.cpp`,
      mutex per session before the database opens, own window class; DD-003), tested by hand
      on the release build: a second start stops and brings the minimised window back to the
      front. `Item` + `ItemRepository` (domain; time derived from the UUIDv7, no column),
      `DriftItemRepository` through `ChangeLogWriter`, the Capture screen (desktop: Enter = save,
      Shift+Enter = new line; phone: the keyboard action saves, no new lines; on an
      error the text stays) and a live inbox as the start screen. Tests: unit, widget
      (`testDriftWidgets`, see the pitfall in CLAUDE.md), "empty update fails as a Future" (review T1.5b),
      integration test `integration_test/capture_test.dart` on Android and Windows. Saving measured:
      Windows median 8 ms (max 10), Android emulator (debug) median 28 ms (max 86)
- [x] **T1.7** Android widget and Windows keyboard shortcut through `CaptureChannel` (REQ-001, REQ-017)
      — *from T1.3:* `ItemSource` has no value yet for "New item" through the Windows
      system tray (DD-010); add it when that entry point comes
      — *from S3:* adopt variant A + the encrypted queue, keep the loss tests T1–T4;
      optional: measure the time from tap to keyboard on the own device
      — *from review T1.6 step B:* `CaptureScreen` must be reachable without first building
      `InboxScreen` and its Drift stream (hard rule 7); measure AC REQ-001 (≤ 3 s from the tap) here,
      because T1.6 only measured the saving itself
      — *PO decisions 27-09-2026:* two steps; a separate Keystore key for the queue
      (exception in DD-007); the widget window follows the system language; Windows: the main window
      instead of a separate window, closing = system tray, no autostart; keyboard shortcut only the
      default `Win+Shift+B` for now (making it configurable = later item); no device measurement now
      — *step A done 27-09-2026 (Android widget, DD-010):* `QuickCaptureActivity` (native,
      `exported=false`, closes only after `fsync`, double saving blocked), `CaptureQueue`
      (encrypted, UUIDv7 at the tap, quarantine, only removed after `acknowledge`), widget with one
      button; Dart `CaptureChannel` (`pending`/`acknowledge`), pulled in at start and on return,
      stored under its own id (`insertWithId`, once when received twice), messages in the
      inbox; Android texts generated from the ARBs (`tool/gen_android_strings.dart`). Tests:
      Kotlin (`gradlew :app:testDebugUnitTest`, 22: S3 tests T2–T4, key temporarily gone = nothing
      to quarantine, "empty" equal to Dart), Dart (a refused item is set aside and
      does not block the rest), integration test
      `integration_test/widget_queue_test.dart` on the emulator; T1 (reboot) by hand on the
      release APK: the item survives the reboot, once in the inbox, with the time of the tap.
      The CaptureScreen remark from the review of T1.6 does not apply to the widget (native window);
      it does to step B. The 3 s measurement from the tap stays open (no device measurement, PO decision)
      — *step B done 27-09-2026 (Windows, DD-010):* `windows_shell.cpp` in the runner: keyboard shortcut
      `Win+Shift+B` (taken = message in the inbox), main window to the front with the capture screen and
      afterwards back to how it was (hidden, minimised or behind), system tray with
      New item / Open / Exit (texts from the ARBs, also with the keyboard), closing =
      to the system tray; `ItemSource.tray` added (point from T1.3). The manual test found a
      real bug: after the keyboard shortcut Win stayed "pressed" for Flutter and Enter gave a new line;
      fixed in the runner (see DD-010). Tests: widget tests for requests, source, message on a taken
      shortcut, system-tray texts per language and an already open capture screen; `tool/check_windows_shell.ps1`
      (9 checks on the release build in a temporary `LOCALAPPDATA`, also: on a start error
      the window really closes) all passed. After the review closing hides the window only if the system-tray menu is there.

- [x] **T1.8** Version and build moment at the top of Settings (REQ-060, DD-008) — PO request
      27-09-2026: without a dependency (`tool/write_build_info.dart` + `--dart-define-from-file`),
      without a git commit; without build information Settings shows "Development build"
      — *done 27-09-2026:* `BuildInfo` (domain), heading *About Offload* at the top of Settings,
      texts NL/EN, tests (domain + widget); build commands in CLAUDE.md adjusted; checked on
      the release builds of Windows (sandbox) and Android (emulator). Taken along from the review of
      T1.7 step B: `didReplace` in `CaptureRouteObserver`, two explanations in the runner
      — *follow-up 28-09-2026 (PO request):* build number automatically = number of commits;
      `tool/build_release.dart apk|windows` replaces `tool/write_build_info.dart` and runs
      the build information and `flutter build` together (was parked, review T1.8)
- [x] **T1.11** Widget "Offload bar" (NL "Offload-balk"): 2×1 Capture and Today, 3×1 also Insights (REQ-063,
      DD-010, DD-019; PO request 05-10-2026)
      — *decided 06-10-2026 (PO, Q39–Q42 as proposed; sketch `docs/design/screens/21-offload-bar.png`):* v1, built
      right after T4.7 (bump `task`); opening over an open screen as a reminder tap but a capture screen with text
      stays; app shortcuts with the same three actions in this task; no change to the Windows tray; three buttons. A second provider next to `CaptureWidgetProvider`; capture opens
      `QuickCaptureActivity`, Today and Insights open `MainActivity` through the launch path of a reminder tap.
      Tests on the emulator in 2×1 and 3×1, cold and with the app open, with TalkBack. The Material Icons copied as
      VectorDrawables need an entry in `bundledLicenses` (REQ-062); the About test does not catch drawables, so check
      it by hand. Fix along the way: a reminder tap pops an in-app capture screen with typed text (found 06-10-2026,
      same path)
      — *done 06-10-2026:* the bar, the app shortcuts, opening on Today or Insights also over an open screen, a
      capture screen with text kept; the widgets 60 dp high instead of a full cell (PO, while building), the
      1×1 too; the Material icons' licence in About Offload. Checked on the emulator: 2×1 and 3×1, cold start
      on Insights, typed text kept, shortcuts, one MainActivity, the accessibility tree (TalkBack is not in the
      AOSP image)
- [x] **T1.9** Widget 1×1 with the new widget icon, and the Offload app icon (REQ-001, DD-019)
      — PO feedback 28-09-2026: the 2×1 widget is too big for one button; use the icons from
      `branding/`
      — *done 28-09-2026:* glyph `ic_widget_capture` (VectorDrawable, evenOdd plus) tinted through
      `@color/widget_glyph`; 1×1 tile by default, wide variant with "Capture something…" from
      ~180 dp (`RemoteViews` with a size map); `previewLayout`, `previewImage` as fallback; hint
      through ARB (`androidWidgetHint`); adaptive + themed app icon on Android; `app_icon.ico` on
      Windows through `tool/gen_windows_icon.ps1`. Checked on the emulator (1×1, wide, preview,
      tap opens the capture window) and on the Windows release build. Microphone button not built
      (REQ-006, see DD-019).
- [x] **T1.10** Version name `0.M.y` with `tool/bump_version.dart task|milestone` (REQ-060, DD-008)
      — PO decision 28-09-2026: `task` raises `y`, `milestone` raises `M` and sets `y` to 0; fixes
      do not raise the name. The script rewrites only the version name in `pubspec.yaml` (keeps
      `+1`), turns `[Unreleased]` in `CHANGELOG.md` into `[<version>] – <date>` with a fresh empty
      `[Unreleased]` above it, and warns when `[Unreleased]` is empty (it runs before the commit, so a
      dirty tree is normal here). Start value
      `0.2.9`. Unit tests on the pure parts (parse/raise, CHANGELOG rewrite); `CLAUDE.md`: run it in
      the commit that finishes a task — *done 29-09-2026:* `pubspec.yaml` was set to `0.2.8` and the
      script ran once, so the changes so far are released as `[0.2.9]` (PO decision 29-09-2026)

**Milestone M1 done when:** you capture a thought from the home screen and from Windows,
it appears in the inbox, the database is encrypted and CI guards the permission.

## M2 · Capturing and processing

- [x] **T2.1** Share target for text and URL (REQ-002); files → T5.8
      — *done 27-09-2026 (DD-010; PO decisions 27-09-2026):* Offload in the Android share menu
      for `text/plain`; the same native window as the widget, filled with the shared text,
      editable, Save through the encrypted queue with source `share`. Subject on the first
      line, text below it (only the text if it already contains the subject); line breaks
      are kept. A URL stays text. Windows: nothing (the share contract needs MSIX). The PO
      may decide differently about the window or saving directly after use
- [x] **T2.2** `InlineTokenRegistry` + tokens `@person`, `#tag`, `!date`, with live chips and
      escape (REQ-019, REQ-028, DD-004)
      — set up `TokenTrigger` (prefix *or* pattern) right away (DD-004 point 3a); `*` reserved
      for priority with a strict grammar, `+` not reserved (Q11)
      → `^project`, `*priority` and *next week* follow in T10.5
      — *PO decisions 27-09-2026:* `@Name` when capturing = only a link (role in triage);
      date words today, tomorrow, the day after, weekdays short and long, next week (Monday),
      `!dd-mm(-yyyy)`; `!vr` on a Friday = Friday next week; two steps
      — *step A done 27-09-2026:* registry and parser in the domain (`lib/domain/tokens/`,
      `LocalDate`), date words from the ARBs, live chips below the capture field; DD-004 point 7.
      Also tested with Cyrillic names and a Cyrillic word list (preparation T8.6)
      — *step B done 27-09-2026:* `DriftTokenProcessor` (DD-004 point 8): after saving, after
      pulling in widget items and at start-up; people and tags looked up or created
      (Unicode, one at a time), tokens stored with `parserVersion`, the first `!date` → `dueAt`
      if it is empty, relative dates from the moment of capture. Also: a token directly after an
      opening bracket (`(@Jan)`, PO decision). Integration test `integration_test/token_processing_test.dart`
      (Cyrillic too). Not visible in the inbox yet: showing the deadline and links belongs to the
      screen layout (Q5b)
- [x] **T2.2a** Suggestion list on a trigger: filters while typing, "create new",
      keyboard operation on Windows (REQ-033)
      — *done 27-09-2026 (DD-004 point 9; PO decisions 27-09-2026):* at most 5 suggestions,
      most used first; "New: …" only creates on saving; choosing a date puts the full
      word; Windows: top one selected, Enter/Tab chooses, Escape closes the list, Enter saves
      when the list is closed; people/tags only loaded on the first trigger
- [x] **T2.2b** Prefix bar + syntax overview behind `?`, with the setting
      Always / Collapsed / Off (REQ-034)
      — *done 27-09-2026 (DD-004 point 10; PO decisions 27-09-2026):* buttons from the registry;
      directly after a word a space first; Android above the keyboard, Windows below the
      text field; collapsed = only the signs, expanded state remembered; overview with an example per
      token and the `\` rule; setting per device in `local_state`
- [x] **T2.3** Item detail with inline editing; status machine (REQ-018)
      — *also (from T2.5 step C):* open the other item from the duplicate hint (AC REQ-053)
      — *design decided 27-09-2026 (Q5b, DD-018 point 1):* text first; automatic saving;
      Enter = new line; the deadline follows the text (adjust `DriftTokenProcessor`: also
      clear, and existing date tokens keep their date); trash with undo
      — *plan approved 27-09-2026 (PO decisions):* temporary switch "Also show processed items" in
      the inbox until T2.6/T3; detail on Windows also as a screen of its own (two panes with T2.6); "Wait
      for…" only sets the status (who: T2.4); "Pick a date…" in the date suggestions (calendar →
      fixed date), when capturing and in the detail; no share icon until T2.7
      — *step A done 27-09-2026 (DD-018, implementation T2.3 step A):* editing, status machine,
      trash with `restore`, the deadline follows the text with dates from the text history
      — *step B done 27-09-2026 (DD-018, implementation T2.3 step B):* shared editor; item detail
      according to the sketch with automatic saving, trash with undo, "Pick a date…";
      opening from the inbox, search and the duplicate hint; temporary switch in the inbox
- [x] **T2.5** FTS5 index over title, text, notes and later transcriptions (REQ-011)
      — *worked out 27-09-2026 (M10 point 8, priority high, DD-016):* FTS5 table through Drift over
      the titles, text and notes of items, person notes, contact details and transcribed
      speech; indexing **after saving**: triggers only put the table and id in the local
      queue `fts_pending`, an indexing task processes it directly afterwards and on every start
      (hard rule 7; derived data like `tokens`: no HLC, no log, never in a
      sync package); no external content on `rowid` (UUID keys, see DD-016);
      `unicode61 remove_diacritics 2`; prefix search; `bm25` ranking (title heavier);
      basic search screen from the top bar; rebuild path from the source tables. Measure in the
      integration test that capturing with the index is not slower than without. **Verify early** with an integration test on Android and Windows: FTS5 (T1.4
      only tested with a unit test on the development machine), diacritic insensitivity, prefix,
      `bm25`, and whether the `trigram` tokenizer is available (for T10.13). Also delivers
      duplicate detection "Does this already exist?" after saving and in triage, asynchronous and never
      blocking (REQ-053, REQ-001). Basis for T10.9 and T10.13
      — *plan approved 27-09-2026 (PO decisions):* three steps: A index without a screen, B plain
      search screen from the inbox's top bar (styling follows in Q5b), C hint "Does this already
      exist?" in the inbox (own short plan; the triage card takes it over later). People also findable
      by name and alias; no button "rebuild index"
      — *step A done 27-09-2026 (DD-016, implementation step A):* schema v2 with `search_index`,
      `search_map`, `search_pending` and triggers; indexing after saving; tested on Android and
      Windows (SQLite 3.53.4, trigram present); capturing not slower
      — *step B done 27-09-2026 (DD-016, implementation step B):* plain search screen through the
      magnifying glass in the inbox; searches while typing; items and people in one list; tapping
      does nothing yet (T2.3)
      — *step C done 27-09-2026 (DD-016, implementation step C):* hint "Looks like another item" in
      the inbox on the newer item of a pair; comparison with Ignore/Close; ignoring
      synchronised (schema v3). Opening and linking from the hint: with T2.3 and T10.9
- [x] **T2.4** Triage mode: card by card, swipe actions (REQ-010)
      — *extended 27-09-2026 (M10 point 4, priority high):* process with one swipe or one tap
      to task / idea / request / waiting for / reference / trash (AC REQ-010). Android:
      swipe actions plus buttons for all destinations (≥ 44 dp); Windows: one key per
      destination, no mouse swipe needed. Every action can be undone immediately;
      trash = tombstone. Hint "Does this already exist?" on the card (REQ-053, through T2.5).
      Which destination gives which type and which status: AC REQ-010 (Q20, PO decision 27-09-2026);
      gestures: Q5b
      — *design decided 28-09-2026 (Q5b screen 3, DD-018 point 3):* swipe right = skip, swipe left =
      trash; the six destinations as a 3×2 grid of large buttons; asking who for request and
      waiting for (skippable); undo message; progress "3 of 12"; end screen with the skipped
      count; Windows: keys 1–5, `Del`, → / Space skip, Ctrl+Z undo, Enter open, Esc stop
      — *plan approved 28-09-2026 (PO decisions):* start button "Verwerken · N" in the inbox with a
      stack-of-cards icon; undo one step; closing stops without asking
      — *done 28-09-2026 (DD-018, implementation T2.4):* `sortInto`, `TriageSession`,
      `ItemRepository.classify`, `DriftPeopleRepository` (shared with the token processor),
      `TriageScreen` with the person sheet; `ItemType.thought` removed. Checked on the emulator
      (release): button, card, person sheet with "New: …", undo message above the buttons
      — *code:* the type *thought* is dropped (a thought is an idea): remove `ItemType.thought` from
      `lib/domain/items/item_enums.dart`; no migration needed as long as no item has that type
      (that is only possible through triage)
- [x] **T2.6** Navigation: Today · Inbox · Overview · Projects · People, start on Today
      (REQ-030, DD-011)
      — *revised 27-09-2026 (Q18):* five destinations. The tab *Overview* only appears with T10.7;
      set up the navigation so that this fifth destination is just an extra entry
      — *Today designed 28-09-2026 (Q5b screen 4, DD-018 point 4):* overdue and today in two
      sections, the inbox line with "Process", swipe right = complete, left = trash; nothing for
      waiting-for yet
      — *navigation and Windows two panes designed 29-09-2026 (Q5b screen 5, DD-018 point 5):* only
      built destinations (Today, Inbox with a badge); Windows rail with ＋ and Settings, search field
      above the list, two panes from 840 dp; keys; Ctrl+Enter completes from the list only on Today
      — *step A done 29-09-2026:* Today (sections, inbox line, swipes with undo, empty day) and the
      navigation (bottom bar / rail, start on Today, Android back)
      — *step B done 29-09-2026:* Windows two panes from 840 dp with the search field above the list,
      list keys, Ctrl+1/2, Ctrl+N, Ctrl+F; narrow window one pane with the rail staying. Overview,
      Projects and People join the bar/rail with T10.7 and M3
- [x] **T2.7** `ShareChannel` (Android `ACTION_SEND`, Windows clipboard + "Save as…") and sharing an item
      as text with an editable preview (REQ-043, DD-014) — *done 30-09-2026 (DD-014, implementation
      T2.7):* text only (`shareFile` with T3.7); share icon in the item detail, preview with the switch
      "Include tags"; `@jj` as typed, dates written out; Android chooser, Windows copy and "Save as…"
- [x] **T2.7a** Share an item *as typed (for Offload)* (REQ-043, DD-014) — *PO 09-10-2026, after T7.3, as the
      counterpart of sharing one item:* a switch in the preview shares the raw text with every token and fixed dates,
      so Offload on another device makes the same item of it; the tags switch hides; only text travels — *done 09-10-2026*
- [x] **T2.8** Inbox row as a card (REQ-030, REQ-053, DD-018 point 2) — *design decided 28-09-2026
      (Q5b screen 2):* first non-empty line as a bold title without tokens, "+ N lines" for a text of several
      lines, chips from the stored tokens (date orange only when today or overdue), relative time,
      no capture source; Windows: the same cards in the list pane (with T2.6)
      — *done 28-09-2026 (DD-018, implementation T2.8/T2.9):* `itemHeadline` and `relativeAge` in
      the domain, one query for the processed tokens of all live items, `InboxCard` with the shared
      `TokenChip`; checked on the emulator (release) and the Windows release build
- [x] **T2.9** Swipe an inbox card to the trash on Android, with undo (AC REQ-010, DD-018 points 2
      and 3) — Q26 answered 28-09-2026: left = trash, as in triage; swiping right does nothing in the
      list; build after or with T2.8
      — *done 28-09-2026 together with T2.8:* swipe left on touch platforms, grey background, the
      same "Moved to trash · Undo" message as the detail (`trashWithUndo`); screen readers get
      "Move to trash" as an action on every card
- [x] **T2.10** The type on the card: icon plus name as the first chip (AC REQ-010, REQ-016,
      DD-018 point 2) — *PO request 29-09-2026 after using the MVP:* on a card you could not see
      whether it is a task, an idea or something else. Variant A (icon + name, no colour of its own);
      the triage button Reference becomes Note, as in the detail. *Done 29-09-2026:* chip on the
      inbox and triage cards, icon also on the type chip in the detail, `TriageDestination.note`

**Scheduled from M10 (Q22):** T10.8 = T2.5 (before T2.4) and T10.4 = T2.4.

## M3 · People, projects and review

**Build order from here (PO decision 02-10-2026):** T10.5 → T3.6 → T10.1 (without the nudge) →
T10.2 → T10.7 (the *Overview* tab, the new entry in the app) → T10.3 → T10.9; then M4. T3.7 and T3.8
later. Before T10.7: decide the naming point SPEC Q27, and choose the typeface and record the colours
as tokens (from T8.1). By then there are about 2–4 weeks of own use (M4b).
*PO 02-10-2026:* Q27 decided (tab NL "Inzicht", EN "Insights"; "Weekoverzicht" stays); typeface IBM
Plex (bundled assets, OFL) and the colours as tokens agreed; build T10.7 now, without waiting for 2–4
weeks of use: Standstill will show mostly "< 1 wk" at first, its classes are re-assessed after use.

- [x] **T3.1** Projects: two levels, item overview per project — *design decided 30-09-2026 (sketch
      `06-projects`, DD-018 point 6, AC REQ-030 Projects):* destination Projects with *Without project*;
      project screen by status; picker from the item detail and the triage card; project chip on cards;
      archive and delete (items kept); Windows list pane one level deeper; the temporary Inbox switch goes;
      archiving needs schema v4 (`contexts.archived_at`, with a migration)
      — *step A done 30-09-2026 (DD-018 point 6, implementation T3.1 step A):* schema v4, domain rules,
      `DriftProjectRepository` with delete/undo, items in projects; screens follow in step B
      — *step B done 30-09-2026 (DD-018 point 6, implementation T3.1 step B):* destination Projects,
      list and project screen, picker from the detail and the triage card, project chip on cards,
      Inbox switch removed
- [x] **T3.2** People: *requested by* and *waiting for* (REQ-012)
      → extended in T10.1 (commitment ledger) and T10.2 (commitment balance, 1-on-1)
      — *design decided 01-10-2026 (sketch `07-people`, DD-018 point 7, AC REQ-012):* destination People
      (fourth for now, Ctrl+4) with a filter field and open counts; a person with *requested by*, *waiting for*
      and *mentioned in*; renaming (old name becomes an alias); requester and waiting-for chips in the item
      detail, *Waiting for…* asks who; `@person` chip in the detail opens the person; the person on cards
      elsewhere. Step A data, step B screens
      — *step A done 01-10-2026 (DD-018 point 7, implementation T3.2 step A):* `Person`, counts and lists
      per person, find/watch/rename people (old name becomes an alias), items per person (also named in the
      text), requester and waiting-for on an item, `waitFor`; screens follow in step B
      — *step B done 01-10-2026 (DD-018 point 7, implementation T3.2 step B):* destination People
      (Ctrl+4), people list with filter, person screen with three lists, rename dialog, person chips and
      *Wait for…* in the item detail, `@person` chip and search result open the person, people on cards
- [x] **T3.2b** Merge people (DD-015): A into B through the change log in one transaction, `merged_into_id`
      (schema change with a migration), late references follow it — right after T3.2; needed before T10.5
      — review note T3.2 step A: a name that sync made an alias of two live people resolves to the first
      match (`idFor`, `find`, `rename`); decide the rule here
      — *decided 01-10-2026 (DD-018 point 7, Merging):* ⋮ Merge with… on the person, also offered when a
      rename is refused; A into B, B keeps its name; confirmation and Undo; profile joined; a shared name goes
      to the oldest person
      — *step A done 01-10-2026:* schema v5 `people.merged_into_id`, `merge`/`undoMerge`, reading follows
      merged people, one rule for shared names; screens follow in step B
      — *step B done 01-10-2026:* ⋮ Merge with… (list with filter, confirmation, Undo); a refused rename
      offers the merge
- [x] **T3.3** Person profile: birthday + free-form note (REQ-031, DD-012)
      — *done 01-10-2026 (DD-018 point 7, Profile):* birthday line with age and a small dialog, note that
      saves itself on the person screen; plain text until notes are formatted
- [x] **T3.4** Guided weekly review (REQ-013)
      → a step for stalled items in T10.6; the Overview (T10.7) is embedded in the review
      — *design decided 01-10-2026 (sketch `08-weekly-review`, DD-018 point 8, AC REQ-013):* built together
      with T10.6; four steps (inbox, waiting for, deadlines, stale), one per screen; start from *Today* and
      Ctrl+Shift+W; X per device, 3 weeks; schema v6 `items.reviewed_at`. Step A data, step B screens
      — *step A done 01-10-2026:* schema v6, last touch from HLC and `reviewed_at`, the rules of the
      four steps, `markReviewed`, X as local state; screens follow in step B
      — *step B done 01-10-2026:* start screen, four steps, end screen; ⋮ on Today and Ctrl+Shift+W; a mode in
      the list pane on Windows; Settings *Stale after*; archiving from every open status (PO decision)
      — *entry revised 02-10-2026 (PO: ⋮ felt hidden; sketch `04b-today-review-entry`, variant C, DD-018 points
      4 and 8):* **T3.4b** an icon in the top bar of *Today* (tooltip names Ctrl+Shift+W on Windows), a line
      on *Today* while a review is due, the last completed review as local state, Settings *Due again
      after* (3–28 days, 7 by default); ⋮ on *Today* removed once the icon is there
      — *T3.4b done 02-10-2026*
- [x] **T3.5** Contact details per person: phone numbers and email addresses (a list with label),
      organisation, job title (REQ-038, DD-012)
      — *plan approved 02-10-2026 (PO):* (a) E.164 only with T3.6, after measuring what a package brings
      (DD-008); the text is kept as typed; (b) tapping a number or address dials or mails in v1, through
      an own capability in `platform/` without a new dependency or permission (step C); (c) labels: a
      fixed set shown translated (work, mobile, private, other) plus an own text; (d) a small sketch
      `09-contact-details` before the screen. Step A data, step B screen, step C dial and mail
      — *step A done 02-10-2026:* schema v7 (`contact_details`, `people.organisation`/`job_title`) with a
      migration tested with v6 data in a unit test, an integration test on the emulator and Windows, and
      an upgrade of the 0.3.6 release over real data on both; repository, merge with undo, search;
      screens follow in step B
      — *screen decided 02-10-2026 (sketch `09-contact-details`, DD-018 point 9):* all as proposed; the version
      goes up when step C closes the task
      — *steps B and C done 02-10-2026:* the profile with the job title line, the section, the sheet, delete
      with undo; tap dials (Android) or copies (Windows) a number and mails an address through the own
      `ContactLauncher` (no permission, no package); Windows runner ignores the F10 menu mode so Esc closes
      a menu opened with Shift+F10
- [x] **T3.6** Pattern tokens phone and email in the input, linked to `@person`, E.164
      (REQ-039, DD-004) — needs T2.2 and T3.5
      — *plan approved 02-10-2026 (PO, DD-004 point 12):* (a) E.164 by an own rule, no package (measured
      `phone_numbers_parser`: pure Dart, MIT, ~180 KB); (b) home country in Settings from a list of ~35 countries,
      the Netherlands by default; (c) saving is confirming, only newly typed, with Undo; (d) one person or
      nothing, "Link to a person" in the detail; (e) *Mobile* for a Dutch mobile number; (f) 9–15 digits from
      `+` or `0`
      — *done 02-10-2026*
- [ ] **T3.7** Export a person as vCard 3.0 through `ShareChannel`; test the import in the
      Contacts app on the own device (REQ-040) — needs T2.7
- [ ] **T3.8** Business-card photo on a person (REQ-041) — needs T5.2 and T5.3
      — *T3.7 and T3.8: later (PO 02-10-2026), see the build order above*

**Scheduled from M10 (Q22):** T10.5 after T3.1 (`^project` needs projects); T10.1 (without nudge) and
T10.2 after T3.2; T10.6 with T3.4; T10.3 and T10.9.

## M4 · Reminders

- [x] **T4.1** `ReminderScheduler` (abstraction + Android implementation, inexact alarms)
      (REQ-020, DD-005)
      — *designed 04-10-2026:* deadline reminders, one notification per day at a set time (09:00), own Kotlin
      channel without a package, `POST_NOTIFICATIONS` asked at the first deadline (approved); DD-005, DD-018 point 16,
      sketch `docs/design/screens/16-reminders.png`. Steps: A planning (domain) and settings (done); B the Android channel,
      permission and Settings section (done 04-10-2026, 0.3.20)
- [x] **T4.2** "Revisit on": item back to the inbox, with a start-up safety net (REQ-021)
      — *designed 04-10-2026:* parked = status scheduled with a date, back to the inbox from the start of that day
      (checked at start-up, on resume and at a change of day), in the one notification a day, a group on *Today*;
      set from the detail, triage (*Later…*), the weekly review and the status chip (approved); AC REQ-021, DD-005,
      DD-018 point 17, sketch `docs/design/screens/17-revisit.png`. Steps: A domain and data, B screens, C notification
      (all done 04-10-2026, 0.3.21)
- [x] **T4.3** Rescheduling after a reboot (`BOOT_COMPLETED`)
      — *planned 04-10-2026 (PO decisions a–e as proposed):* an encrypted plan file on the Kotlin side (dates,
      times, count lines, no titles) restored by a receiver on `BOOT_COMPLETED`, `MY_PACKAGE_REPLACED` and
      `TIMEZONE_CHANGED`; `RECEIVE_BOOT_COMPLETED` approved; force stop accepted (DD-005). Built together with the
      Sunday rule of *Next week* (T4.2, PO 04-10-2026) and the small leftovers of the T4.2 review
      — *done 04-10-2026 (0.3.22)*
      — *from the review of T4.1 (04-10-2026):* planned alarms are also gone after a force-stop and possibly an app
      update; consider `MY_PACKAGE_REPLACED` too
- [x] **T4.4** Weekly-review reminder (REQ-022)
      — *02-10-2026 (DD-018 point 8):* notifies only when a review is due, through the same domain function as
      the line on *Today* (T3.4b)
      — *PO 04-10-2026:* built small (off by default, Friday 16:00, own notification, a tap opens the review; DD-018
      point 16a), done 04-10-2026 (0.3.23); to be judged at M4b
- [x] **T4.5** Windows implementation; open point: closed app (SPEC Q2)
      — *planned 04-10-2026 (PO decisions a, c–f as proposed; b: titles):* balloon notifications of the tray icon while
      the app runs, checked every half minute; a click opens the item, Today or the review; Settings section on
      Windows; Q2 answered (not for v1). DD-005 — *done 04-10-2026 (0.3.24)*
- [x] **T4.6** Yearly birthday reminder (REQ-031)
      — *PO decision 01-10-2026 (T3.3):* together with it, a line on *Today* for a birthday today
      — *PO decisions 04-10-2026:* everyone with a birthday, one switch (on), a notification of its own on the day
      at the day's time, no names on the lock screen, 29 Feb → 28 Feb, a line on Today (DD-005); done 04-10-2026
      (0.3.25). *Order PO 04-10-2026:* next the nudge of T10.1, then T4.7 as the last of M4
- [x] **T4.7** Recurring tasks: a task comes back daily, weekly or monthly (REQ-061, PO request 02-10-2026)
      — *recorded only, not to be built yet:* draft AC in SPEC; open design questions Q29–Q35 (entry and token,
      rhythm, missed periods, one item or one per occurrence, sync without duplicates, Today/review/reminders,
      stopping and undo), to be decided with a sketch; *PO decision 02-10-2026 (Q36):* v1, here in M4, after
      T4.1 and T4.2. PO's idea for the entry: a choice "repeat" when completing a task
      — *designed 06-10-2026 (PO decisions on Q29–Q35, all as proposed, 6b; sketch
      `docs/design/screens/20-recurring-tasks.png`):* model B, one series item plus a record per completed time
      (`item_completions`, schema v12, UUIDv5 per item and date); token `!dagelijks`/`!wekelijks`/`!maandelijks`
      in every app language, button *↻ herhalen*, ⋮ *Afronden en herhalen…* and *Herhaling stoppen*; for a task or an
      untyped item; next time = first series date after the completed time and today; reminders on every series
      date; never stale; undo in the item detail too. AC REQ-061, DD-003, DD-004 point 14, DD-005, DD-018 point 18.
      Required test among the date rules: `!maandelijks` without a date from 31 January gives 31 Jan → 28 Feb → 31 Mar.
      — *step A done 06-10-2026 (no screens yet):* domain rules, token, schema v12 `item_completions`, completing and
      undo in one transaction, the processor's series date, stale and reminder rules; tests incl. two devices
      — *for step B (review of step A):* guard every completing entry point against a double tap (two calls record
      two times); *Herhaling stoppen* must not rely on stored tokens that may be stale (process the text first, or
      decide from the text); the `!` suggestion list gets the repeat words; until then the prefix bar shows the repeat
      button with the date list
      — *step B done 06-10-2026 (0.4.0, M4 complete):* chips, the repeat button with only the rhythms, *Gedaan*,
      *Afronden en herhalen…* and *Herhaling stoppen*, every *Afronden* with undo and a double-tap guard; checked on
      the emulator and in the Windows release
      Steps: A data and rules (domain, token, schema, completing and undo, processor), B screens. Last task of M4:
      `bump_version milestone`

**Scheduled from M10 (Q22):** the nudge of T10.1, after T4.1.

## M4b · Overview

After 2–4 weeks of own use of M1–M4, so that the views are judged on real data
(DD-017). Belongs to v1 (Q22). *PO 02-10-2026:* T10.7 comes before M4, right after T10.2 (see the
build order at M3).

- **Judge after use (PO 04-10-2026):** is the weekly-review reminder (T4.4) used, or is the line on *Today*
  enough? Keep, change or remove it.
- **Judged after use (PO 06-10-2026, at the end of M4):**
  - *Without project* in Projects as the replacement of the inbox switch: good, stays.
  - Archiving from every open status: used once so far; stays for now.
  - A parked item whose deadline is before its revisit date still shows on *Today* as overdue (DD-005, T4.2):
    unexpected in use, but kept for now; to be looked at again.
  - Still to judge: the weekly-review reminder, the Standstill classes and orange from 6 weeks, the person as
    1-on-1 preparation, the Horizon span, *job title* or a field *role* (Q23), a fourth button on the Offload
    bar (Q42), the day reminder for a daily task, the finishing of T8.1.
- [x] **T4b.1** High priority on top of *Today* (PO decision 06-10-2026, after use; DD-004 point 11 left it
      open): within *Verlopen* and *Vandaag* the items with high priority first, then the rest in the
      current order. Plan first
      — *done 09-10-2026 (PO decisions 09-10-2026):* only high moves up; low stays among the rest (option A);
      no extra header or line; `todaySections` sorts on it, no schema or screen change
- [x] **T4b.2** "Where was I" on *Today*, as a trial (PO decision 06-10-2026, after use; DD-018 point 13 (e)
      left it out "to be judged after use"): open notes shown on *Today*. Plan and sketch first
      — *done 09-10-2026 (PO decisions 09-10-2026, sketch 22 variant A):* a group at the top, at most 3 with "+n meer",
      no age limit, no buttons or swipe; Settings → *Vandaag* switch per device, on by default. Judge after use (M4b)
- → **T10.7** Overview (see M10). Beforehand from T8.1: choose the typeface (bundled, with
  Cyrillic) and record the colours as tokens

**Order for the rest of v1 (PO decision 04-10-2026):** M4 (T4.2–T4.7 and the nudge of T10.1) → T1.11 (Offload bar, PO 06-10-2026) → T4b.1 and T4b.2 (PO 06-10-2026) → M4b (after
2–4 weeks of use) → M7 (T7.3, T7.5) → M6 (T5.1 first, then T7.2b backup with attachments, then T6.1–T6.3, then
T7.4; PO 09-10-2026; before it M7b, Help in the app, T8.11–T8.14, PO 09-10-2026, and M6a, image input, GO after S6, PO 11-10-2026) → M5 (*PO 10-10-2026: M5 now, before M6, while S6 waits*; T5.2–T5.8, with regenerating thumbnails on restore (rest of T7.2) and T3.8) → M8, so that finishing (accessibility, the manual) comes last. The sections below
follow that order; the milestone numbers stay.

## M7 · Backup, export, clean-up

*PO decisions 03-10-2026:* T7.1 and T7.2 (without attachments, which do not exist yet) come forward: right
after T10.9 and T8.10, before M4, because the app holds real data and the device key cannot be exported
(DD-007). Scope: only making and restoring the encrypted backup; export (T7.3) and importing stay here.
The part "with attachments" and regenerating thumbnails follow right after M5. Then T10.14 (*Connections*)
comes into v1, after the backup.

- [x] **T7.1** Settings → Backup: set/change the passphrase, Argon2id, warning
      (REQ-026, DD-007)
- [~] **T7.2** Make and restore a backup; option with/without attachments; regenerate thumbnails
      on restore (REQ-014, DD-006/D7)
      — *plan approved 03-10-2026 (DD-007, implementation decided):* AEGIS cipher of SQLite3MultipleCiphers
      with built-in Argon2id (no new package), VACUUM INTO an encrypted copy without `local_state`, restore by
      rekeying a copy to the device key, new device id (Q15), passphrase once in Settings (≥ 12 characters).
      Step A: data and logic with tests; step B: saving and opening the file per platform; step C: screens
      — *step A done 03-10-2026 (no visible change):* `BackupFiles` and `AppStorage` make, check and restore backups,
      with recovery of a restore stopped halfway; checked on the emulator and Windows (times in DESIGN DD-007)
      — *steps B and C done 03-10-2026 (0.3.18):* `BackupFilePicker` (Android document picker through
      `BackupFileChannel.kt`, a copy in the own cache removed right after; Windows Save as and Open in the runner),
      Settings → Back-up (passphrase, make, restore), checked end to end on the emulator and in the Windows release.
      **T7.1 done; T7.2 done without attachments** — "with attachments" and regenerating thumbnails follow right after
      M5
      — *PO 09-10-2026:* "with attachments" becomes its own task **T7.2b** in M6, right after T5.1 and before T6.2
      (once there are recordings, a backup would otherwise miss audio that is not, or badly, transcribed; the audio
      is the source, DD-002). Regenerating thumbnails on restore stays here, with M5
      — *follow-ups from the review of steps B and C (small):* say so when a restored database did not open and
      the previous one came back (now silent, the data is safe); on Android remove the empty document the picker
      created when making the backup fails; keep the pending picker answer across a recreated activity
      — *done 10-10-2026 (clean-up round):* a restored database that does not open still brings the previous one back,
      and now the app says so once after start (*Terugzetten niet gelukt*, `AppStorage.restoreUndone`; after a capture
      asked for at start); on Android a save that fails (also for too little room, and for an export) deletes the
      document only when the picker made it (empty when picked) or the copy had already cut it off; an existing file
      the user chose to overwrite stays when the save fails before copying (review: else a second backup on the same
      day could delete the first). Checked on the emulator for both cases. The pending picker answer: parked (see *Parked*)
- [x] **T7.2a** Share a backup through the Android share menu (REQ-014, DD-007, DD-014)
      — *done 09-10-2026 (PO decisions 09-10-2026):* *Make a backup* on Android opens a sheet with *Share…* and
      *Save on this device…*; Windows unchanged. `ShareChannel.shareFile` + `fileTargets`, `FileProvider` on
      `cache/share/` only (`androidx.core:core:1.13.1`, already in the release, now named explicitly), one shared
      file at a time, removed at app start after 24 hours (SPEC Q12 answered for the backup)
- [x] **T7.3** Export to Markdown and JSON, with a warning that this is unencrypted
      — *done 09-10-2026 (PO decisions 09-10-2026, AC REQ-014):* Settings → *Back-up en export* → *Exporteren*;
      one format per export, the warning confirmed every time; Android share or save, Windows Save as; everything
      outside the trash, raw text as typed in the Markdown, a versioned JSON structure; no import
      — *small leftovers from the review (09-10-2026):* `export_tile.dart` and `backup_section.dart` import each
      other (move `BackupSection.busy` and `backupFilePickerProvider` to a small shared file); `DriftExportRepository`
      has its own copy of `_hlcTime` (share it with `DriftItemRepository`)
      — *done 10-10-2026 (clean-up round, PO):* `busy`/`withProgress` in `busy_dialog.dart`, the picker provider in
      `backup_file_picker_provider.dart`; one `hlcTime` in `lib/domain/sync/hlc.dart` for the item, export and snapshot
      repositories
- [ ] **T7.4** Cleaning up orphans: files without an attachment record and vice versa (REQ-025)
      — *from the review of T5.3 (10-10-2026):* a photo deleted while its thumbnail is made again can leave that
      thumbnail behind (`PhotoStorageService.thumbnail` writes after the delete); the orphan clean-up covers it
      — *from the review of T5.2 (10-10-2026):* include `attachments/thumbs/` (a thumbnail whose photo record is gone or
      tombstoned, e.g. after a crash between the thumbnail and the record, or a regeneration that overlapped a delete);
      `AttachmentStore.totalBytes` counts only the top folder, so thumbnails would be missed if Settings → *Storage* ever uses it
      — *after M6 (PO 04-10-2026):* only useful once there are files (audio from T6.2)
- [x] **T7.5** Storage use in Settings
      — *done 09-10-2026 (PO decisions 09-10-2026, option a: small now, the rest when it is built):* Settings →
      *Storage* (*Opslag*): database, temporary files (Android), content with the trash; no clear button. **M7 complete** (0.5.0)

## M7b · Help in the app (REQ-065, DD-020; PO 09-10-2026)

*Order (PO 09-10-2026):* T8.11 → T8.12 → T8.13 → T8.14, each its own task with review; then T5.1; after the S6 decision M6a
or M6.

- [x] **T8.11** The documentation agent runs *before* the release build: `tool/build_release.dart` with `--copy` refuses
      to build when `.claude/.docs-marker` does not hold the current content hash (the same as `Get-DocsState`, recorded by `mark-docs.ps1`); without
      `--copy` it warns. `docs-trigger.ps1` (the reminder after every release build) is removed. CLAUDE.md (Agents en
      poorten, Definition of done) and `.claude/` updated (PO approval; through the review). No visible change
      — *done 09-10-2026:* c233f8f in the private history (script, hook removed) and the CLAUDE.md commit after it
- [x] **T8.12** The manual in English: translate it once into `docs/user-manual/en/` (screen names and date words from
      `app_en.arb`, examples fictional); the Dutch text leaves the tree (history keeps it; `nl/` follows with T8.5). The
      index becomes a task-oriented table of contents; "Status" and "Already built" move to `docs/features.md`. The
      documentation agent, the reviewer and CLAUDE.md (language) follow. No visible change in the app
      — *done 09-10-2026:* translated by three documentation agents with the labels of `app_en.arb`; anchors fixed and
      checked (0 broken); dates as the English app shows them (`MMMEd`); the CLAUDE.md language rules in their own commit
- [x] **T8.13** Markdown renderer: `markdown` (+ `args`) in `tool/allowed_packages.txt` with date and reason; own widget
      renderer for the manual's subset, heading ids, IBM Plex, theme and text size; licence through Flutter's overview, not `bundledLicenses` (PO 09-10-2026); unit
      and widget tests. Shared with T10.10
      — *done 09-10-2026:* `lib/domain/markdown/` (blocks, GitHub heading anchors) and `lib/presentation/markdown/`
      (`MarkdownView`); tests parse every chapter, check every link between chapters and draw each chapter at 360 px with
      double text size; both licences appear in Flutter's overview (NOTICES); not reachable in the app until T8.14
- [x] **T8.14** The viewer: Settings → *Help*, the manual as assets, links and anchors inside the viewer with Back,
      external links as URL only, the note when the app language has no manual; a "?" per screen from one table
      screen → `chapter.md#anchor`, with a test on every anchor
      — *done 09-10-2026 (PO decisions 09-10-2026: on Today the date moves to the page when the bar has no room; F1 on
      Windows; "More in the manual" in the syntax overview; an internet address shown with Copy):* `HelpScreen`,
      `HelpScope`/`HelpButton`/`HelpKey`, the table `HelpTopic` in `lib/domain/help/`; checked on the emulator (1×, 1.5×,
      2× text) and in the Windows release (F1, Esc). **M7b complete** (0.6.0)

## M6a · Image input (GO after S6, PO 11-10-2026; before M6, SPEC Q43)

*PO 11-10-2026:* S6 gave GO with Qwen3-VL-2B (DD-021); M6a comes before speech (M6). It needs
neither T5.1 nor M5: the photo is discarded after confirming (AC REQ-064 d). Each task is planned
first; the order follows the gate.

- [x] **T6a.1** Phone gate: llama.cpp for Android arm64 (C shim + `dart:ffi`, as in S4) in a spike app, the model
      on the Fairphone; measure time per photo and peak memory at 1280 px, context 2048. Pass: not killed, at most
      about 2 minutes per photo; else try `--image-max-tokens 512`; NO-GO if that fails too (DD-021). Whisper
      waits for T6.1 (PO 11-10-2026)
      — *done 11-10-2026, gate passed (PO raised it to about 3 minutes the same day):* shell (prebuilt b11526) and a
      spike app (`spikes/s6_app`, own package, prebuilt `.so` + a C shim): 46–138 s per photo at 2.4–2.6 GB with the
      model read into memory, 34–75 s with the fallback, never killed; memory-mapped took 3.2–3.35 GB and once stalled
      (paged out). CPU only, 6 threads; the GPU build gave no gain. Android freezes the app ~70 s after leaving it:
      reading pauses and resumes. PO decisions: read into memory; message + progress + screen on, a foreground service
      only if missed in use; the 5-minute stop. Details in DD-021 and the S6 report (*Phone*). The spike app and files
      were removed from the phone
- [ ] **T6a.2** The native library in the app on Android and Windows: shim, isolate, `tool/allowed_native_libs.txt`
      and `bundledLicenses` (MIT, PO 11-10-2026), the network check of DD-008
- [ ] **T6a.3** Settings → *Models*, shared with speech: import of several files at once, free-space check,
      progress, SHA-256 against a list in the app, remove, the source and licence as text; the model as a row in
      Settings → *Storage*; never in a backup, and the message after a restore (DD-007). Replaces the import of T6.1
      — *PO 11-10-2026:* the files are chosen with the system's document picker, as for *Restore a backup*: on Android
      the Storage Access Framework, so a NAS or cloud app that offers documents (Synology, Nextcloud, an SMB app) works
      too; on Windows the Open window, network drives included. The app copies the files into its own private storage
      (llama.cpp needs a local file) and computes the SHA-256 while copying, so a wrong or damaged file is refused at
      once; it needs room for the copy (about 1.5 GB). To settle in the plan: both files in one pick, and what happens
      when there is too little room
      — *PO 11-10-2026:* under the handwriting model a choice *Nauwkeurig / Sneller* (EN "Accurate / Faster"),
      *Accurate* by default, per device, never in a backup (DD-021); the reading of T6a.4 uses it
- [ ] **T6a.4** The photo screen: take or choose a photo, optional straightening with four draggable corners
      (SPEC Q45), reading with progress, the clean-up of DD-021
- [ ] **T6a.5** The review screen: one candidate per thought (`-` convention), edit or skip, save as `inbox`
      items after confirming (AC REQ-064 c); the button in capture only with a verified model

## M6 · Speech

- [x] **T5.1** `AttachmentStore`: AES-256-GCM per file, storage and path convention (REQ-023)
      — *PO decisions 09-10-2026:* the platform's own AES-GCM (Android `javax.crypto`, Windows CNG), no package; records
      with change log in T5.1; Settings → Storage row *Attachments* per kind, only when there are any; 64 KiB segments.
      **Step A done 09-10-2026:** format v1 (`AttachmentHeader`), `AttachmentStore`, `AeadCipher` (Windows, Android, fake);
      GCM test vectors and a reference file written by pyca/cryptography pass on Windows and the emulator; emulator
      (debug) 50 MB write 4.8 s / read 4.2 s, Windows 1.0 / 0.9 s; batches of 64 instead of 16 segments only ~15 % faster.
      **Step B done 09-10-2026:** `DriftAttachmentRepository` (file first, then the record through the change log; a failed
      record removes the file; removing: tombstone, then file), `AppStorage` holds the attachments key and folder and clears
      leftover `.partial` files when opening, Settings → *Storage* row *Attachments* per kind (only with attachments). No
      visible change until attachments can be added (T5.3, T6.2)
      — *moved from M5 (PO 04-10-2026):* a recording is an encrypted audio attachment (T6.2)
      — *from T7.5 (09-10-2026):* add the attachments, per type, as a row to Settings → *Storage* (*Opslag*)
      — *for T7.2b (PO 09-10-2026, the starting point of this design; DD-007 "Backup with attachments" point 4):* read
      and write as a stream in segments, each authenticated on its own, so a large file never has to be whole in
      memory and nothing unverified is passed on
- [x] **T7.2b** Backup **with attachments** (REQ-014, DD-007, DD-006/D7) — *PO 09-10-2026: right after T5.1,
      before T6.2.* **Designed and decided 09-10-2026** (DESIGN DD-007 "Backup with attachments", AC REQ-014; all as
      advised): a switch *Met bijlagen (≈ size)*, on by default; attachments as BLOBs inside the encrypted backup file itself (one file, AEGIS/Argon2id; sharing and
      restoring unchanged), decrypted with the device's attachment key while making, encrypted with the target's while
      restoring, never unencrypted on disk; photos only as display versions (D7); restore all or nothing
      — *from the review of T5.1 (09-10-2026):* `AttachmentStore` uses `AeadCipher`; on Android that is a method channel, so the
      backup's background isolate needs `BackgroundIsolateBinaryMessenger.ensureInitialized`; on Windows the CNG calls block
      the isolate they run in (keep them off the UI isolate)
      — *PO decisions 09-10-2026:* steps A (making), B (restoring), C (screen), each reviewed, version at C; restoring a backup
      without attachments keeps this device's files that belong to a restored record (option b, DD-007 point 7c revised);
      schema version 13 without table changes (point 6); an integration test from Android to Windows.
      **Step A done 09-10-2026:** `backup_meta`, `backup_attachments`, `backup_attachment_chunks` (1 MiB) in the backup copy,
      filled in the backup's isolate (`copyAttachmentsInto`, cipher through `backgroundAeadCipherFactory`), `temp_store =
      MEMORY`; a missing or unverifiable file is left out and counted; every live attachment record goes in, also of an
      item in the trash (it can come back). Emulator (debug): 20 MB in 2.5 s; Windows 1.0 s. Screen unchanged (no attachments)
      **Step B done 09-10-2026:** restore verifies each attachment's size and SHA-256 while re-encrypting it with this
      device's key into `attachments.restore/`; a backup without attachments writes the keep list `attachments.keep`
      (option b); the chunk tables are dropped and the copy vacuumed; `finishRestore` swaps the folder with the database
      (the old one as `attachments.before-restore/`); once the restored database opens, the kept files move over and the old
      folder goes; interrupted starts finish or roll back; `BackupInfo` says whether a backup has attachments and how many; a
      newer `format_version` is too new. A backup made on the emulator restores on Windows with equal SHA-256
      (`integration_test/backup_cross_device_test.dart`)
      **Step C done 10-10-2026 (0.6.1):** with attachments on this device, *Make a backup* first asks *Met bijlagen
      (≈ size)*, on by default (a dialog, also on Windows, PO 10-10-2026); the free space is checked before making
      (database + attachments) and before restoring (twice the backup), through `AppDirectory.freeBytes` (Android
      `StatFs`, Windows `GetDiskFreeSpaceExW`), with `roomNeeded` adding a tenth and 16 MiB (PO 10-10-2026: also for
      restoring); progress "12 MB van 85 MB" from 4 MiB on, no cancel; "n bijlagen ontbraken"; the restore confirmation
      names the attachments or warns (option b). `undoRestore` now removes the restored database first (review
      leftover; the order "database back first" would have let a stop halfway remove this device's own folder).
      Checked in the Windows release (a sandbox filled with 3 × 8 MB of attachments) and with
      `integration_test/backup_progress_test.dart` on the emulator and Windows
      — *small leftovers from the review of step C (10-10-2026), done the same day (PO: before the copy to H:):* widget tests for the restore confirmation lines
      ("Met n bijlagen.", the option-b warning), the no-room message on restore and `backupMissingNote` (now only checked
      in the Windows release); `undoRestore` renames the main before-restore file before its companions, so a stop in
      between could leave a `-wal` that the commit in `open` then deletes (only if the old database kept a WAL after
      closing, which SQLite normally folds back). Now: the texts are `BackupSection.restoreAttachmentsLine` and `madeText`,
      tested directly, plus a widget test for no room on restore; `undoRestore` removes and renames companions before
      the main file, so the main file tells where a stop came (file tests per stop)
- [ ] **T6.1** Model import through the file picker, with a SHA-256 check (DD-002) — *from S4:*
      adopt the C shim + `dart:ffi`; known hashes are in `docs/spikes/S4-whisper.md`;
      build with ARM extensions; measure the speed on the own device
      — *from T7.5 (09-10-2026):* add the speech model as a row to Settings → *Storage* (*Opslag*)
      — *PO 09-10-2026 (REQ-064):* the model is never in a backup; after a restore the app says it has to be
      imported again (DD-007). If M6a comes first, the import goes through the shared Settings → *Models*
- [ ] **T6.2** Recording → encrypted audio attachment → asynchronous transcription (REQ-006)
      — *from the review of T5.1 (09-10-2026):* do not seal a long recording on the UI isolate (`DriftAttachmentRepository.add`)
- [ ] **T6.3** Transcription in the FTS index; a proper message when there is no model

## M5 · Attachments and photos

*PO 10-10-2026:* M5 comes before M6 while S6 waits for its photos: it does not depend on S6, and the photo capture of
T5.3 is what M6a needs as its input; T6.1 waits, as the shared Settings → *Models* of M6a would replace it.

Order from `photo-resize-port-spec.md`: first the service, then the capture flow, then the lists.

- → **T5.1** `AttachmentStore`: moved to M6 as its first step (PO 04-10-2026: T6.2 needs it)
- [x] **T5.2** `PhotoStorageService`: compressing (1600/q82), thumbnail (256/q75), path derivation,
      "delete both" — the screen stays smooth while processing (REQ-027, DD-006) — *from S2:*
      engine codec + `package:image` (dependency approved by the PO); measure the speed on the own
      Android device with the 50 MP photos (S2 only measured on the emulator)
      — *from the review of T5.1 (09-10-2026):* the display version and the thumbnail share the attachment id and key; bind the
      variant into the key or the associated data (a new format version or a variant byte), so the two cannot be swapped unseen
      — *done 10-10-2026 (PO decisions a–e; DD-006 adjustments point 6):* `ImagePolicy`, `PhotoCompressor`, `PhotoStorageService`;
      thumbnail in `attachments/thumbs/<id>`, made from the display version; the variant in the key and the associated data;
      `image` with `archive` and `posix` in `tool/allowed_packages.txt` (PO 10-10-2026). Measured in profile with the real
      50 MP photos: Windows ≈ 0.95 s, emulator ≈ 1.5 s per photo (both files). No visible change yet. Still open: the
      measurement on the PO's Fairphone (Monday 12-10-2026, with the S2 measuring app, its own package id)
- [x] **T5.3** Take/import a photo: apply rotation, strip EXIF (REQ-024)
      — *from the review of T5.1 (09-10-2026):* `DriftAttachmentRepository.add` encrypts on the calling isolate; keep large
      content off the UI isolate; and measure start-to-capture time (REQ-001) once there are many attachment files, as
      `AppStorage.open` lists the folder to remove leftovers
      — *done 10-10-2026 (PO decisions a–f; sketch 23; DD-018 point 19):* `PhotoSource` (`PhotoChannel.kt`: camera app
      through `ACTION_IMAGE_CAPTURE` into `cache/camera/`, removed after reading and at start, the CLAUDE.md rule 2
      exception of the PO; `ACTION_PICK_IMAGES`; Windows the Open window with several extensions); *Add photo* in the item
      detail, the row of thumbnails with `AttachmentImage` (pulled forward from T5.4), the viewer with zoom, deleting
      after asking, *Attachment not in this backup* (pulled forward from T5.4). Only the encryption of the small results
      runs on the UI isolate (T5.2); measured: a 2400×1800 photo in 1.2 s on the emulator, 0.7 s on Windows.
      Start (REQ-001): the scan for `.partial` leftovers in `AppStorage.open` lists both folders; measured 10-10-2026 with
      500 photos (1,000 files) ≈ 9 ms, with 5,000 photos (10,000 files) ≈ 55 ms, on the emulator and on Windows alike
      — *proposal (to the PO):* write `.partial` files in a folder of their own (`attachments/partial/`, renamed into
      place), so the scan at start lists only that folder and stays constant however many photos there are
      — *done 11-10-2026 (PO approved):* writes go through `partial/` in the attachments and the thumbnails folder; a
      `<id>.partial` of a version up to 0.6.2 goes once per device after the start (DD-006)
      — *from the review of T5.3 (10-10-2026, clean-up):* `PhotoChannel` and `BackupFileChannel` each make an executor
      that is never shut down; one idle thread per activity instance. Shut them down in `onDestroy` or share one
      — *done 11-10-2026:* every channel with a worker thread (photos, backup files, sharing, AES-GCM, the capture queue)
      has `close()`, called in `MainActivity.onDestroy` after `super`; a running task still finishes
- [x] **T5.4** Own `ImageProvider` with a cache key and `cacheWidth`; lists show only
      thumbnails (DD-006 point 5)
      — *from T7.2b (PO 09-10-2026):* the first task that shows attachments (this or T6.2) shows *Attachment not in this backup*
      (NL "Bijlage niet in deze back-up") for a record whose file is absent after a restore (DD-007 point 7a)
      — *T5.3 (10-10-2026):* `AttachmentImage` and the text for a missing photo exist (in the item detail); left here: a
      photo mark or thumbnail on the cards in the lists
      — *done 11-10-2026 (PO decisions 1–3, DESIGN point 19):* `CardPhoto` on every `InboxCard` and in the search
      results: the newest photo, 40 dp, with the number; one query for the list (`watchItemPhotoSummaries`);
      measured in profile mode (`integration_test/card_photos_test.dart`, 120 items with a photo, scrolling while the
      thumbnails load): Windows 429 frames, build avg 0.7 ms, raster avg 1.3 ms, none over 16.7 ms; emulator build avg
      1.6 ms (none over), raster 24 of 436 over, but 45 of 434 over in the same list without photos (the emulator's
      rasteriser, not the photos). The Fairphone (the lower bound) still to measure
- [ ] **T5.5** Fallback for a missing thumbnail + lazy regeneration (REQ-032)
- [ ] **T5.6** In-app view of photo and PDF; "open in external app" with a warning and
      clean-up (REQ-025) — *T5.3 (10-10-2026):* a photo already opens full screen with zoom (`PhotoViewer`); left here:
      PDFs, *Open in another app*, and perhaps swiping to the next photo
- [ ] **T5.7** Tests: sizes, orientation, path derivation, delete-both; measure the file size
      before and after for a sample photo
- [ ] **T5.8** Receive files and photos through the Android share menu (REQ-002, SPEC §6.3
      "Receiving"; split off from T2.1 on 27-09-2026, PO decision) — *depends on:* T5.1–T5.3
      — *PO 09-10-2026 (after T7.2a):* take along here: a received `.offload` backup ("Open with" or
      "Share" → Offload, e.g. a mail attachment) starts *Restore a backup* with that file. Restoring from
      another place already works through the document picker (Downloads, NAS, cloud apps; checked by the PO)
- [ ] **T5.9** *Rotate 90°* for a photo in the item detail (SPEC Q45, PO 11-10-2026): a photo that came out on its
      side is turned, both files rewritten and the thumbnail made again; four-corner straightening of a kept photo
      is parked

## M8 · Finishing

- [x] **T8.1a** Colour tokens through a `ThemeExtension` (DD-017, REQ-016; *PO 11-10-2026: after S6*): a refactor
      without visible change, preparing the dark theme; the light theme stays pixel for pixel the same
      — *done 11-10-2026:* `OffloadColors` (light instance only) in `offloadTheme()`, `context.offloadColors` in all
      18 users, painters get colours through the constructor, `design_tokens.dart` gone (typefaces in `typography.dart`),
      a source test guards it; Windows screenshots before and after compared (Today, Inbox, Projects, Insights:
      Horizon/Standstill, People, Connections 1 and 2 steps, a person): 0 differing pixels
- [ ] **T8.1** Light/dark theme, dynamic colours, design system (SPEC Q6) — the chosen
      fonts must contain Cyrillic (AC REQ-005, preparation T8.6)
      — typeface and colour tokens come earlier already, in M4b (T10.7, DD-017)
      — *left after T8.1a:* a dark `OffloadColors` instance with a contrast calculation (REQ-016; including white on
      a meaning colour, see the comments), `darkTheme` + `themeMode`, a `ThemeChoice` (system/light/dark) on the model
      of `LanguageChoice`, and optionally dynamic colours (a new dependency, PO approval)
      — *from the review of T8.1a:* let the source test also fail on a raw `Color(0x…)` / `Colors.…` outside `theme/`,
      with an allowlist for the colours that are fixed on purpose; give the dark instance the same length check of
      the standstill lists (`lerp` goes per entry)
- [ ] **T8.2** Accessibility: scalable text, TalkBack/Narrator, contrast (REQ-016)
      — *found 29-09-2026:* the Flutter Windows embedder only reports high contrast, never
      `accessibleNavigation` (`FlutterWindowsEngine::SendAccessibilityFeatures`), so with Narrator
      an undo message still leaves after 5 s (`keepUndoMessage`). Find another signal on Windows
      (e.g. `SPI_GETSCREENREADER` through `platform/`) or a longer time for everyone
- [ ] **T8.3** Windows packaging and installation
      — *from T4.5 (04-10-2026):* consider an option "start at sign-in" (reminders after a restart depend on it),
      and notifications while the app is fully closed (SPEC Q2: app id in the registry, COM activation)
- [ ] **T8.4** Onboarding: first start, backup passphrase, optional speech model,
      syntax overview (SPEC Q8)
- [ ] **T8.5** Finish the user manual — kept up to date continuously by the
      `docs-writer` in `docs/user-manual/`; here the final edit (documentation agent)
      — *PO 09-10-2026 (T8.12):* English is the base; here also the Dutch translation (`nl/`), made from the English
      — *from the review of T8.14:* when `nl` joins `manualLanguages`, key the help screen's chapter cache by language
      (a chapter still loading when the app language changes is now stored under the new language)
- [ ] **T8.6** Ukrainian as the third UI language: `app_uk.arb`, choice Українська in Settings,
      Ukrainian plural forms; Cyrillic correct on screen, in the widget, notifications, exports
      and any PDFs (AC REQ-005); open points in SPEC Q9 (REQ-005, REQ-029)
- [ ] **T8.7** CI on GitHub Actions when the repo is published: analyze, test, release builds
      Android and Windows, then `tool/check_permissions.sh` and `tool/check_dependencies.sh`
      always on fresh builds from the same job; a Linux job without a Windows build sets
      `SKIP_WINDOWS=1` (REQ-003, DD-008)
- [ ] **T8.8** Windows keyboard shortcut configurable in Settings, with a check that the combination is
      free (REQ-017, DD-010) — PO decision 27-09-2026: in T1.7 only the default `Win+Shift+B`
- [ ] **T8.9** System-tray icon on Windows based on `branding/widget/widget_glyph.svg` instead of
      the app icon (REQ-017, DD-019) — *depends on:* Q25 (hand-pixelled 16 px variant or the
      downscaled glyph); the icon goes into the runner's resources next to `app_icon.ico`
- [x] **T8.10** Screen *About Offload* (REQ-062, PO request 02-10-2026): reached from the section *About
      Offload* in Settings, which keeps what it shows now (REQ-060); purpose in two or three sentences,
      version, licence GPL-3.0-or-later (Q37) with its text bundled, and *Licences of components* through Flutter's
      `showLicensePage` (the IBM Plex OFL is registered already) — *order (PO):* after T10.7;
      the `LICENSE` file in the repo comes with it
      — *done 03-10-2026 (0.3.17):* screen, `LICENSE` (gnu.org text, sha256 3972dc97…), purpose text (PO), and the
      licences Flutter does not collect: SQLite3MultipleCiphers (MIT) and SQLite (public domain) next to IBM Plex;
      a test fails when an allowed native library or a bundled typeface has no licence (PO request: keep it current)
- [x] **T8.15** The root `README.md` in English (PO 09-10-2026): the project will be published on GitHub; it is still
      Dutch (found in the review of T8.12)
      — *done 10-10-2026 (clean-up round):* translated; CLAUDE.md is marked as Dutch (working agreements with the PO)
- [x] **T8.16** Prepare the repository for publication (SPEC Q28, REQ-060, DD-008; PO 11-10-2026): the repository
      starts afresh from the content of the last private commit (tree `7883e02`); the private history stays local.
      The build number becomes `buildNumberBase` (260) plus the commit count, so it stays above every APK built
      before; the Windows version resource says GPL-3.0-or-later instead of "All rights reserved"; machine-specific
      paths move from `CLAUDE.md` to a local `CLAUDE.local.md`; example e-mail domains become `example.org`
      (reserved for examples); a leftover comment in `.gitignore` is gone
      — *done 11-10-2026*

## M9 · Manual sync (after v1)

Keep the work phone and work laptop in step through encrypted packages, exchanged through Signal, mail
or USB. The app stays network-free (REQ-003). Basis: T1.5b. (REQ-035, REQ-036, DD-013)

- [ ] **T9.1** Pairing: QR code with a 256-bit key, passphrase as the fallback; unpairing
      (REQ-036) — first open point Q13 (`CAMERA` and scanning library); with the passphrase
      both devices must use the same Argon2id salt (e.g. shown or sent along)
- [ ] **T9.2** Make a package: changes since the last exchange per device, optionally with
      attachments, encrypted; share through `ShareChannel` (REQ-035)
- [ ] **T9.3** Receive a package and merge in one transaction: idempotent, LWW per field,
      conflict copy for `rawText`, tombstones, derive tokens again (REQ-035)
      — *from review backup step A (03-10-2026):* after a restore (T7.2) the clock starts from the wall clock under a
      new device id; seed it from the newest HLC in the change log, as after receiving a package (DD-007)
      — *from review T1.5b:* `ChangeLogReplayer` does not check values against the column type yet
      (e.g. a number in `deleted_at`); check per column before reading in packages
- [ ] **T9.4** Merge proposal for people and tags with the same name (DD-003, DD-013)
- [ ] **T9.5** Receiving on Windows: file picker, drag and drop, file association `.offload`
- [ ] **T9.6** Tests: two simulated devices, packages twice and in random order,
      concurrent edits, wrong key, damaged package

## M10 · Follow-up, overview and connections

Added 27-09-2026 (product owner). The order below is the **priority** of the PO.
Build order (Q22, PO decision 27-09-2026): **priority high = v1**, scheduled in M2, M3, M4 and
M4b (see the lines "Scheduled from M10" there); **priority medium = after v1**. Whether those come
before or after M9 is still open (Q22). Requirements and
acceptance criteria: `SPEC.md` §6.10 (REQ-046 to REQ-059) and the additions to REQ-010 and
REQ-011. Design: DD-015 (people), DD-016 (search), DD-017 (visualisations). Sketches:
[`docs/design/overview/`](docs/design/overview/README.md) — indicative; the text wins.

Points 4 and 8 overlap so strongly with T2.4 and T2.5 that they were worked out there; here there is only
a reference.

**For all items:** fully offline, no new permission; all texts through ARB (Dutch
source, English translation); Android (primary) and Windows 11, platform difference named per item;
touch targets ≥ 44 dp, text contrast ≥ 4.5:1, information never through colour alone; new entities
with UUID, HLC, tombstone and change log through `ChangeLogWriter`; every schema change is a
migration (since T1.6 there is data).

### Priority high — v1

- [x] **T10.1 · Commitment ledger** — per item record who asked something, when, what I
      promised and by when; conversely *waiting for*: what others owe me, with a
      nudge if it stays silent after X days (REQ-046, REQ-047, DD-015, DD-005)
      — *overlap:* builds on T3.2 (REQ-012) and on schema v1 (`requester_id`, `waiting_on_id`,
      status `waiting`); the nudge uses `ReminderScheduler` (T4.1), inexact (DD-005)
      — *new in the data model:* moment of asking, promised text, promised-by, expected-by
      for waiting for
      — *platform:* Android: notification plus *Today*; Windows: notification while the app runs in the
      system tray (Q2), otherwise at start-up on *Today*
      — *for the architecture agent:* is *promised by* the same as `due_at` or a field of its own;
      derive "waiting since" from the change log or store it; one commitment per item or more
      — *depends on:* T3.2, T4.1 (only the nudge); renaming and merging people
      (DD-015)
      — *assumption:* the default period of the nudge is still to be decided (proposal: 7 days)
      — *plan and sketch decided 02-10-2026 (DD-018 point 10, `10-commitments`):* one commitment per item as fields
      (schema v9 `asked_at`, `promise`, `expected_at`); promised-by = `due_at`; "waiting since" waits for the nudge;
      block "Toezegging" in the detail, expected date in "Wacht op…", group "Had binnen moeten zijn" on Today
      — *built without the nudge 02-10-2026 (0.3.10):* the nudge after X silent days and "chased" follow with
      T4.1; until then the item stays `[~]`
      — *the nudge, PO decisions 04-10-2026 (sketch `19-nudge`, DD-018 point 10):* silent = waiting, no expected
      date, X days untouched (7, "Navragen na"); group "Blijft stil" on Today with Ontvangen/Nagevraagd; its own
      notification on the day it goes silent; done 04-10-2026 (0.3.26)
- [x] **T10.2 · People view with commitment balance** — per person what I owe them and
      what they owe me; usable as preparation for a 1-on-1 (REQ-048, REQ-012, DD-015, DD-017)
      — at the top two totals ("I still have to deliver: N to X people" / "I am still waiting for: N from
      Y people"); per person a diverging bar from a central axis, left (orange) what I
      deliver, right (blue) what I am waiting for, count in the bar; age of the oldest open
      item, highlighted above a configurable threshold (default 21 days); tap on a person →
      1-on-1 preparation
      — *sketch:* `docs/design/overview/03-people.png`
      — *overlap:* adds to the destination *People* (DD-011, T3.2); the same balance is in the
      People segment of *Overview* (T10.7)
      — *platform:* Windows: balance and preparation side by side (list–detail); Android:
      preparation as a screen of its own
      — *accessibility:* a textual summary per person for TalkBack/Narrator; the
      threshold highlight also through font weight or symbol; orange text not on the
      page background (4.34:1, DD-017)
      — *depends on:* T10.1
      — *plan and sketch decided 02-10-2026 (DD-018 point 11, `11-people-balance`):* order by balance (alphabetical
      when equal), age from asked-on / capture day, "Old after" 7–60 days (21), the person screen as 1-on-1
      preparation, Windows person in the right pane; no schema change
      — *done 02-10-2026 (0.3.11)*
- [x] **T10.3 · "Where was I" snapshot** — on a context switch record in ~10 seconds what
      the next step was and what I had in mind; a resume card when resuming (REQ-049)
      — new entity: a snapshot on an item or project; the form loads no lists or
      heavy state (hard rule 7) and a confirmed snapshot is never lost
      — *platform:* Android: an action in the item or project detail, keyboard action Save; Windows:
      Enter = save, Shift+Enter = new line (as in T1.6)
      — *design decided 02-10-2026 (sketch `13-where-was-i`, DD-018 point 13):* a button "Where was I?"
      (NL "Waar was ik?") by Complete (variant B) and Ctrl+Shift+P; two fields; closing with text saves
      it (the button reads Close, NL "Sluiten"); one current note per item or project; a resume card
      with Update/Resume (NL "Bijwerken"/"Hervat"); not on Today; counts as a touch; entity
      `snapshots`, schema v10
      — *step A done 02-10-2026 (no visible change):* table, migration to v10 (tested on v9 data, in the
      change-log round trip, on the emulator and Windows), `SnapshotRepository`
      — *step B done 02-10-2026 (0.3.14):* the button by Complete and under a project, the form (sheet or
      dialog), the resume card, Ctrl+Shift+P. **T10.3 done.**
      — *depends on:* T2.3 (item detail), T3.1 (projects)
- [ ] **T10.4 · Inbox triage** → worked out in **T2.4** (REQ-010, REQ-053): process with one
      swipe or tap to task / idea / request / waiting for / reference / trash (Q20 answered)
- [x] **T10.5 · Smart quick capture** — e.g. `bel Jan @Jan !vr ^renovatie *hoog` → deadline, person,
      project, priority; recognise relative dates (`!morgen`, `!vr`, *next week*); recognised
      parts visible before saving; Dutch by default, English supported (REQ-050, REQ-019,
      REQ-028, DD-004, DD-015)
      — *overlap:* T2.2 already delivers `@person`, `#tag` and `!date` with live chips and date words per
      language; T2.2a/T2.2b the suggestion list and the prefix bar. This item adds: priority (`*`,
      grammar already recorded in DD-004) and project (`^`), both now under "Parked";
      multi-word dates (*next week*); automatic creation of unknown people (DD-015)
      — *PO decision 27-09-2026 (Q19):* stick to the tokens of DD-004; dates only with `!`
      and in the active UI language; a token is one word (*next week* through the suggestion list);
      an unknown project through "New: create …", not automatically on saving
      — grammar of `^` still to be recorded, following the example of `*` (DD-004 point 3)
      — *new in the data model:* priority (schema v1 has no field)
      — *platform:* Windows: suggestion list fully with the keyboard (REQ-033); Android:
      prefix bar above the keyboard (REQ-034)
      — *depends on:* T2.2, T2.2a, T3.1; merging people (DD-015) before or together with
      this item, because automatic creation turns a typo into an extra person
      — *plan approved 02-10-2026 (DD-004 point 11, AC REQ-050):* already there from T2.2/T2.2a: `!volgendeweek`
      and creating unknown people; new: `^project` (key without case/spaces/`-`/`_`, `^a/b` for a sub-project,
      new token = choice, picker wins later, "New: create …" creates at once) and `*priority` (schema v8, follows
      the text, chip only for high/low). Step A: domain, data, schema v8; step B: screens
      — *steps A and B done 02-10-2026:* chips and suggestions for `^` and `*`, "Create project: …", priority
      chip on cards, the item detail saves typed text before the project picker opens
      — *follow-up from use (PO 03-10-2026):* an item whose `^word` named no project when saved was never
      linked once the project existed (fix: the processing at start-up links it); a `^word` of no project
      stays without auto-creation (PO decision, reason: one word, typos, projects weigh more than tags), but
      now says so: a chip "kas · geen project", in the item detail tappable to create the project with this
      item in it; in quick capture only telling. The project picker still writes no token in the text
- [x] **T10.6 · Stale detection** — items not touched for X weeks (configurable)
      appear in the weekly review (REQ-051, REQ-013, DD-003)
      — "touched" = changed, opening does not count; last touch derived from the HLC of the
      row, no column of its own (hard rule 6)
      — per item: keep, archive, trash; *Keep* and *Still waiting* (step 2) record the moment in
      `items.reviewed_at` (schema v6, a synchronised user fact); last touch = max(time from the HLC,
      `reviewed_at`) (AC REQ-051, review architecture agent)
      — merging people (DD-015) touches the items involved; deliberately accepted
      — *decided 01-10-2026 (DD-018 point 8):* X per device, 1–12 weeks, 3 by default, not synchronised;
      notes count; items with a future `revisit_at` do not count (the column exists since v1)
      — built together with T3.4 (steps A and B); *Revisit on…* as a choice joins with T4.2
- [x] **T10.7 · Overview (visual)** — embedded in the weekly review and reachable as its own tab
      "Overview" in the main navigation, with the segments Horizon / Standstill / People (= balance from
      T10.2) / Connections (= T10.14) (REQ-052, DD-017)
      — **a. Horizon:** timeline today + 6 weeks; columns = ISO weeks (number + start date), one
      lane per project. Markers: filled blue = I deliver (deadline/commitment), open blue ring =
      waiting for someone else, filled orange = overdue. Per week a busy bar; weeks above a
      threshold marked as "busy" (label, not only colour). Tap on a week → list of the items
      of that week with person, date and project. Sketch `01-horizon.png`
      — **b. Standstill:** treemap per project; area = number of open items, colour = time since
      the last touch in 4 classes (< 1 wk, 1–3 wk, 3–6 wk, > 6 wk; blue-grey → dark orange).
      Tap on a tile → items of that project. Below it the top 3 "untouched the longest" with age
      and a link to the review. Sketch `02-standstill.png`
      — *status:* design v1 (sketch approved); re-assess after 2–4 weeks of use
      — *PO decisions 27-09-2026:* fifth destination, DD-011 revised (Q18); orange = needs my attention
      *now*, delivering or waiting visible from the shape (Q21, DD-017)
      — *platform:* Windows: Horizon and Standstill side by side, mouse pointer for details;
      Android: one segment at a time
      — *accessibility:* every standstill tile shows name, count and age as text, small
      tiles too (the classes < 1 wk and 1–3 wk are equal in lightness, DD-017); a textual
      equivalent for screen readers
      — *dependency:* typeface (bundled as an asset, with Cyrillic) and chart package or own
      `CustomPainter`. Advice architecture agent: IBM Plex as plain assets (no `google_fonts`)
      and `CustomPainter` without a package; the treemap layout as a pure function in `domain/` (DD-017)
      — *assumption:* items without a project get a lane/tile of their own "No project"; the first
      column starts today; *busy threshold decided (PO 02-10-2026):* only what I deliver counts
      (open items with a deadline in the week), busy from 5 items, Settings → Inzicht → "Druk vanaf" 3–15
      — *naming (SPEC Q27, decided PO 02-10-2026):* the tab is NL "Inzicht", EN "Insights"; the weekly
      review keeps "Weekoverzicht"
      — *design decided 02-10-2026 (sketch `12-insights`, DD-018 point 12, all as proposed):* fifth tab
      after People (Ctrl+5); v1 segments Horizon, Standstill, People; IBM Plex app-wide; Overview is the
      first step of the weekly review (start screen with five steps, both panes on Windows). Steps: A
      typeface + colour tokens, B Horizon, C Standstill, D tab, review step, setting and Windows
      — *step A done 02-10-2026 (0.3.12):* IBM Plex Sans (400/500/600/700) and Mono (400/600) from the
      official IBM/plex releases as assets (`assets/fonts/`, OFL-1.1, checksums in its README, Cyrillic
      checked), `offloadTheme()` sets Plex Sans app-wide, the OFL is in `LicenseRegistry`; the meaning
      colours moved to `lib/presentation/theme/design_tokens.dart` (plus the chips and standstill classes)
      — *step B done 02-10-2026 (no visible change yet):* `horizonOf` in `lib/domain/overview/`, the
      setting `busy_from_items` in storage (UI in step D), `HorizonView` with the week list, ←/→ on
      Windows, a sentence per week for screen readers (DD-018 point 12, implementation); *left for
      step D (point 12 (f)):* hover titles on dots and tiles, ↑/↓ and Enter in the week list, the Tab
      order across Horizon, list, Standstill and list; checked in the Windows release
      — *step C done 02-10-2026 (no visible change yet):* `squarify` and `standstillOf` in
      `lib/domain/overview/`, `StandstillView` with tiles, legend and the list of the oldest three or a
      tapped tile, ←/→ on Windows; checked with a temporary mount on the emulator and in the Windows
      release (DD-018 point 12, implementation)
      — *step D done 02-10-2026 (0.3.13):* the fifth tab *Inzicht* (Ctrl+5), segments, the first step of
      the weekly review, Settings → Inzicht → Druk vanaf; Windows: both panes for Horizon and Standstill
      (also in the review), tooltips, ↑/↓ in the lists. **T10.7 done.** Re-assess after 2–4 weeks of
      use (DD-017), including the orange of six weeks in the Standstill list
      — *depends on:* T10.1, T10.6; further T3.1 (projects) and T3.4 (weekly review)
- [ ] **T10.8 · Search foundation (FTS5)** → worked out in **T2.5** (REQ-011, REQ-053, DD-016):
      index after saving (queue), diacritic-insensitive, prefix, `bm25`, basic search screen, verification on
      Android and Windows, duplicate detection
- [x] **T10.9 · Links between items** — `[[…]]` syntax with autocomplete (through the index from
      T2.5), backlinks per item; light Zettelkasten, not a full knowledge base (REQ-054, DD-004,
      DD-016)
      — a new token type in the registry with the trigger `[[`; a link as `ItemLink` (exists in
      schema v1, with `kind`)
      — *for the architecture agent:* how does `[[…]]` in `rawText` identify the target (a title
      breaks on renaming, an id is unreadable)? Is the link derived (token),
      synchronised (`ItemLink`) or both? Does `[[` clash with Markdown (`[text](url)`, `- [ ]`)?
      — *first advice architecture agent (27-09-2026):* `[[Title]]` stays readable in `rawText`;
      the synchronised `ItemLink` (on UUID, created when choosing from the suggestion list) is the
      source of truth and the token is resolved through that `ItemLink`, not by title, so that
      renaming breaks nothing. `[[` does not clash with `- [ ]` or `[text](url)`
      — *platform:* Windows: suggestion list with the keyboard (REQ-033)
      — *depends on:* T2.5, T2.2a
      — *also (from T2.5 step C):* link the two items from the duplicate hint (AC REQ-053)
      — *plan and sketch approved 03-10-2026 (DD-004 point 13, DD-018 point 14, sketch 14):* `[[…]]` with spaces, no
      tokens inside; `ItemLink` plus `label` (schema v11) resolves the token; links written after saving, removed
      with the text; unique first line links typed text too; no auto-create ("geen item", create from the detail);
      trash keeps the link; *Koppelen* writes into the newer item; *Verwijst hiernaar* below the buttons; `[[ item`
      button. Step A: domain, data, schema v11, processing, replay test; step B: screens
      — *step A done 03-10-2026 (no visible change yet):* `[[…]]` in the registry (parser v5), schema v11
      `item_links.label`, links saved with the text, *Koppelen* and "geen item" in the repository, the processor
      keeps links with the text (remove, restore, unique title), duplicates ignore links; migration checked on
      the emulator and Windows
      — *step B done 03-10-2026 (0.3.16):* `[[` list from the search index (newest items without a query),
      `[[ item` in the prefix bar, link chips (current title, in the trash, "geen item" creates an inbox item),
      *Verwijst hiernaar*, *Koppelen* in the duplicate hint, no chip on cards. **T10.9 done.**

### Priority medium — after v1

- [ ] **T10.10 · Markdown in notes** — formatting including checklists and code blocks (REQ-055,
      DD-004)
      — *from T8.13 (review 09-10-2026):* the renderer flattens footnotes and other unhandled blocks into a paragraph;
      handle them when notes are rendered
      — `body` and the person note are already Markdown text (SPEC §7); this item is the formatted
      view and ticking off checklist points (an ordinary change through the log)
      — never load images or other content from the internet; do not open or
      preview links automatically (hard rule 1)
      — *dependency:* Markdown renderer → dependency review (DD-008) and PO approval; include in it
      whether and how a link to the outside may be opened
      — *after v1 (Q22):* easy to add later. `body` and notes are already stored as Markdown text
      and the parser works on `rawText`, so no schema change or migration is needed;
      until then notes are shown as plain text
      — *depends on:* T2.3
- [ ] **T10.11 · Open questions and hypotheses** — as an item type with status open / tested / rejected
      (REQ-056, DD-004)
      — *for the architecture agent:* a status of its own next to the status machine of DD-004, or mapped
      onto it? One type or two (*question*, *hypothesis*)? The reserved prefix `?` (open question,
      DD-004 point 3) as input?
      — *depends on:* T2.3
- [ ] **T10.12 · Decision log / lab journal per project** — timestamped entries, only
      adding (append-only), corrections as a new entry (REQ-057, DD-003)
      — a new entity with UUID, HLC, tombstone and log (hard rule 4); the UI offers no editing
      or deleting; searchable (T2.5), included in export (T7.3), backup and sync
      — *for the architecture agent:* a decision is a node type in Connections (T10.14). Does
      a journal entry become an entity of its own (then `ItemLink` must also handle other targets) or
      an item of the type *decision*?
      — *depends on:* T3.1
- [ ] **T10.13 · Advanced search** — builds on T2.5: phrase and `NEAR` queries,
      snippet/highlight in results, evaluation of the trigram tokenizer for searching on part
      of a word, saved searches as smart lists (REQ-058, DD-016)
      — a smart list = a new entity, live through a Drift stream; record the outcome of the
      trigram evaluation (index size against usefulness) in DD-016
      — smart lists reachable from search in the top bar; search stays not a destination
      (DD-011) — *assumption*
      — *depends on:* T2.5
- [x] **T10.14 · Connections** — *PO decision 03-10-2026: v1, right after the backup (T7.1, T7.2).* *Designed 04-10-2026: DD-018 point 15, sketch `docs/design/screens/15-connections.png` (NL "Verbanden"; items, projects and people; no tags in v1; not in the weekly review; no schema change). Steps: A graph and layout (domain) plus the query (data) — done 04-10-2026; B the screen, with zoom (PO 04-10-2026) — done 04-10-2026. Limits revised 04-10-2026: 2 steps at most 8 direct and 8 second-step nodes. To judge after use: tag nodes; 2 second-step nodes per direct node as a setting (PO).* Local graph of links around one focus item, depth 1 or 2 steps
      (switch); no global graph (REQ-059, DD-017)
      — node shape per type: project, task, decision, question/hypothesis, person, note; direct
      links solid, second step dotted and dimmed; tap on a node = new focus,
      long press = preview. Sketch `docs/design/overview/04-connections.png`
      — *platform:* Windows: the mouse pointer shows the preview, the keyboard moves the focus
      — *accessibility:* the same information as a list for screen readers; dimmed labels still
      reach 4.5:1; every node also has a text label with the type
      — *for the architecture agent:* graph layout (own code or package, DD-008) and a maximum
      number of nodes at depth 2
      — *depends on:* T10.9; T10.11 and T10.12 for those node types

---

- [x] **Clean-up: Dutch identifiers in older tests** — `test/data/connections/connection_sources_test.dart`
      (`gaas`, `hok`, `maten`) and `test/data/tokens/drift_token_*_test.dart` (`tuin`) use Dutch variable
      names; rename to English (CLAUDE.md "Taal"). Found in the review of T10.14 step B (04-10-2026);
      the fixture texts themselves may stay Dutch.
      — *done 10-10-2026 (clean-up round):* also `renovatie`, `schuur`, `oud`, `keukenTop`/`keukenSub` and `kas`

## Parked

- *Parked in the clean-up round (10-10-2026, to confirm with the PO):* keeping the pending answer of the Android document
  picker across a recreated `MainActivity` (T7.2 follow-up). Flutter's engine lives with the activity, so when the
  activity is recreated (low memory, "Don't keep activities") the Dart side that waited for the answer is gone too;
  a rotation does not recreate it (the manifest's `configChanges`). The only effect is that the user picks the file
  again. Worth it only if it is seen in use
  — *PO 11-10-2026:* stays parked; take it up only if it is seen in use
- *Proposal (review of 3085837, 09-10-2026):* `ShareChannel.kt` and `BackupFileChannel.kt` each create their own
  single-thread executor per channel instance and never shut it down; Android recreating `MainActivity` (e.g. a
  rotation) leaves an idle thread per instance until the process ends (harmless: no CPU, little memory). Tidy:
  one shared executor for both. Take along with the next Android-side task
  — *done 11-10-2026* with the T5.3 review point: each executor is shut down in `MainActivity.onDestroy` instead
- Sharing an item with attachments (REQ-044, Could) — first Q12
- *Proposal (T7.2a, 09-10-2026):* `tool/check_dependencies.sh` checks Dart packages and native libraries, but
  not the Gradle/Maven dependencies of the Android build (a gap in DD-008). Now `androidx.core` is named in
  `android/app/build.gradle.kts`; a later version bump there, or a new `implementation(...)`, would pass
  the release gate unseen. Option: compare the resolved `releaseRuntimeClasspath` (or the merged manifest
  report) against a `tool/allowed_android_deps.txt`
- Showing an item as a QR code (REQ-045, Could) — after T9.1
- OCR of business cards (REQ-042, Could) — first spike S5 (Q14); S6: probably the same model (Qwen3-VL-2B, DD-021), untested
- *PO 11-10-2026 (SPEC Q45):* four-corner straightening of a kept photo attachment, reusing the corners of M6a; and
  automatic corner detection for M6a. Only if missed in use
- *PO 09-10-2026 (REQ-064 a):* let the vision model *suggest* tokens (`@person`, `!date`, …) for handwriting
  that has none; for now the transcription is literal
- File-based sync through a chosen folder (the app stays network-free) — can reuse the package format
  of M9
- Extra inline tokens: `~duration`, `?question` (`^project` and `*priority` → T10.5; `?` possibly
  for T10.11)
- Recompression pass with `pipelineVersion` when the photo sizes change
- WebP instead of JPEG (check platform support first)
- Periodic check "do you still remember your backup passphrase?"
- Lead-time statistics per person
- Retrying or exporting items in the quarantine of the widget queue; now they are
  kept but cannot be retrieved from the app (review T1.7 step A)
- *PO observation 30-09-2026, not decided yet:* the Android keyboard (autocomplete) puts a space
  after a typed `!`, so `!vandaag` becomes `! vandaag`, which stays text; easy to miss, especially
  in the widget window. Options once it proves annoying: no autocorrect after a prefix in the
  capture window, or recognise `! word` too (DD-004)
- *To ask the PO after some use (T2.7, 30-09-2026):* share `@jj` as typed (now) or as the full name
  of the linked person (REQ-043)
- *To judge after use (T4b.1, PO 09-10-2026):* the daily reminder ("3 deadlines today", at most 5 titles)
  lists its titles in its own order; put high priority first there too, as on *Today*?
- *PO 02-10-2026, after use:* make the Horizon span (today + 6 weeks, T10.7) a setting? Fixed for now
- *PO observation 02-10-2026, to experience first:* since IBM Plex (wider) the prefix bar on a phone no
  longer fits; "* prioriteit" scrolls off to the right (the bar scrolls, nothing is lost). Options
  once it annoys: smaller buttons, only the symbols, or a second line

## Open points (mirror of `SPEC.md` §9)

| # | Question | Blocks |
|---|---|---|
| Q2 | Windows notifications while the app is closed — answered 04-10-2026 (not for v1, DD-005; T8.3) | T4.5 |
| Q5b | Detailed layout per screen | M2 |
| Q6 | Design system | T8.1 |
| Q7 | Display size 1600 or 2048 px | Nothing (starts at 1600) |
| Q8 | Content of the onboarding | T8.4 |
| Q9 | Ukrainian: translation check, date words, speech | T8.6 |
| Q12 | Clean-up period for temporary files when sharing (attachments, vCard); answered for the backup and the export 09-10-2026 | T3.7, REQ-044 |
| Q13 | QR pairing: `CAMERA` permission and scanning library | T9.1 |
| Q14 | OCR engine for business cards (spike S5) | REQ-042 |
| Q43 | Image input (M6a) before speech (M6), if S6 gives GO — *answered 11-10-2026: yes* | Order after M4b |
| Q44 | Handwriting: is the `-` convention needed (AC REQ-064 b)? — *answered 11-10-2026: it stays* | REQ-064 |
| Q15 | New device id after restoring a backup | T7.2, T9.1 |
| Q16 | Default country and library for E.164 phone numbers | T3.6 |
| Q22 | After v1: first sync (M9) or first the medium items from M10 | Nothing (planning) |
| Q24 | Deadline with or without time (00:00 UTC is ambiguous) — answered 04-10-2026 (DD-005) | T4.1 |
| Q25 | 16 px variant of the widget glyph for the Windows system tray (`.ico`) | T8.9 |
| Q29–Q35 | Recurring tasks: entry, rhythm, missed periods, model, sync, the rest of the app, stopping — answered 06-10-2026 (AC REQ-061) | T4.7 |
| Q39–Q42 | Offload bar: v1 after T4.7, opening over an open screen, app shortcuts, tray, a fourth button — answered 06-10-2026 (AC REQ-063) | T1.11 |
