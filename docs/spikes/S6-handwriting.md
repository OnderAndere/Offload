# Spike S6 · Handwriting from a photo with a small vision model

> **Date:** 09–11-10-2026 · **Backlog:** S6 · **Tests:** REQ-064, DD-010, DD-002 · **Open questions:**
> SPEC Q43, Q44, Q45 (and Q14 in passing) · **Code:** `spikes/s6_handwriting/` (throwaway, not versioned)
>
> ⚠️ **AI disclaimer:** spike carried out and written up by an AI assistant (Claude, Anthropic).

## Summary and advice

- **Question:** can a small vision-language model, run fully on the device with llama.cpp, turn a photo of
  handwriting (whiteboard, notebook) into text that Offload's inline parser can use, within the size limit of
  1.5 GB (REQ-064)?
- **Advice: GO, with a phone gate.** Qwen3-VL-2B-Instruct (Q4_K_M + `mmproj` Q8_0, 1,552 MB, Apache-2.0) reads
  the PO's own handwriting with about **5 % character errors**, keeps the lines and continuation lines, and gets
  **77 % of the tokens exactly right** after a small clean-up. Wrong words remain (mostly letters the hand makes
  alike), so the review screen of AC REQ-064 (c) is essential, not optional.
- **Settings:** longest side **1280 px**, context **`-c 2048`**, the model's own number of image tokens. On the
  PC (Ryzen 9 4900H, 8 threads) that is **20–41 s per photo** and **3.0 GB peak memory**. Fewer image tokens
  (`--image-max-tokens 512`) halve the time and save 0.3 GB, at a cost of about 8 points of tokens.
- **Phone gate (proposal):** the Fairphone measurement (with Whisper, T6.1) is the first step of M6a, before
  any UI. The PO sets the limit; proposed: the app is not killed, and a photo takes at most about 2 minutes. If
  it fails, try `--image-max-tokens 512` first; NO-GO if that fails too.
- **Straightening helps (Q45):** on the two most skewed notebook photos, straightening by four corners took the
  character errors from 7.9 % to 4.5 % and fixed the split into thoughts completely (the unstraightened photo
  made the model put a `-` before every line). Contrast enhancement alone did not help. Advice: offer
  four-corner straightening in M6a; for the photo attachment of T5.3 a *rotate 90°* is enough for now.
- **The `-` convention (Q44):** keep it. With it, the model split all 5 whiteboard photos and 5 of 9 notebook
  photos into exactly the written thoughts. Of the other four, one had a stray lone `-` at the end (the app can
  drop it), one put a `-` before a continuation line, and the two most skewed photos got a `-` before every line;
  straightened, both were right. Without the convention a thought that runs over two lines cannot be told from
  two thoughts.
- **Not good enough:** InternVL3-1B (822 MB) breaks down on the notebook (repeats, invents tokens), SmolVLM-500M
  is too weak. The other candidates are over the limit or did not run (see *Models*).

## Set-up

- **Engine:** llama.cpp b11526 (commit `5e4878e9787fff9bcc5c12478c47618b73268610`, 09-10-2026), prebuilt
  `llama-b11526-bin-win-cpu-x64.zip` (SHA-256 `222759c0b6e068c52b52f600d506397868c75d7ed2f9535c53d254457c425d70`),
  `llama-mtmd-cli` with `--offline --temp 0 --seed 0 -n 400 -t 8`. A prebuilt Android arm64 package of the same
  build exists, for the phone measurement.
- **PC:** AMD Ryzen 9 4900H (8 cores / 16 threads), 31.4 GB RAM, Windows 11. Time is wall-clock per photo,
  including loading the model; memory is the peak working set of the process.
- **Test set:** 14 photos made by the PO on 11-10-2026, fictional content, kept outside the repository:
  - *notebook:* 9 photos of one page (blue ballpoint, lined paper, 7 lines, 6 thoughts), from different angles,
    up to about 20° skew;
  - *whiteboard:* 5 photos of one board (black and blue marker, 4 lines, 3 thoughts), different angles and
    light, one with a purple cast. The top of these photos showed unrelated content; it was cut off before any
    run (`prep/bin/crop.dart`).
  - The text uses every token kind (`@ ! # ^ *`), dates (`30-10-2026`), a phone number, continuation lines
    without `-`, and some deliberate quirks: `!vri` (the PO was unsure of `!vr`), an `@` that looks like a `c`.
- **Reference:** one text per set, written from the photos and checked by the PO.
- **Prompt B** (the best of three in the synthetic dry run): *"Transcribe the handwritten text in this image
  exactly, line by line, one output line per written line. Keep every symbol exactly as written, including
  `- @ ! # ^ *` and digits. Do not add, remove, correct, translate or complete anything. The text is Dutch.
  Output only the text."*
- **Scoring** (`score.dart`): character error rate (CER); tokens exactly right per kind (the whole token, so
  `#kweekbak` read as `#kweechbah` counts as wrong and as "invented"); thoughts by the `-` rule, exactly and
  nearly (CER ≤ 20 %) found.
- **Clean-up** an app can do cheaply (`normalise.py`), applied before scoring unless stated: a token sign
  followed by a space joins the next word (`@ Harry` → `@Harry`), `×` becomes `*`. Both are consistent habits of
  the model.

## Results

### Round 1 · models (1280 px, `-c 4096`, after clean-up)

| Model | Set | CER | Tokens exact | Invented | Time | Peak |
|---|---|---|---|---|---|---|
| **Qwen3-VL-2B** | notebook | **5.2 %** | **124/162 (77 %)** | 34 | 42 s | 3.2 GB |
| | whiteboard | **5.4 %** | **31/40 (78 %)** | 0 | 22 s | 3.1 GB |
| InternVL3-1B (Q4_K_M) | notebook | 57 % | 75/162 | 193 | 51 s | 1.0 GB |
| | whiteboard | 11 % | 26/40 | 4 | 37 s | 1.0 GB |
| SmolVLM-500M | both | ~60 % | 23/202 | 66 | 8–15 s | 0.7 GB |

At **1600 px** Qwen3-VL-2B scored the same (notebook CER 4.8 %, tokens 124/162; whiteboard 5.5 %, 31/40) at
almost twice the time (78 s / 39 s) and 3.3 GB. InternVL3-1B got worse (CER above 100 %: it repeats).

Without the clean-up, Qwen3-VL-2B got 102/162 and 21/40 tokens: the difference is almost entirely `@ X`, `^ X`
and `×`.

### Round 2 · memory (Qwen3-VL-2B, 1280 px, after clean-up)

| Variant | Notebook tokens | Notebook CER | Whiteboard tokens | Time (nb / wb) | Peak |
|---|---|---|---|---|---|
| `-c 4096` | 124/162 (77 %) | 5.2 % | 31/40 | 42 / 22 s | 3.21 GB |
| **`-c 2048`** | **124/162 (77 %)** | **5.2 %** | **31/40** | 41 / 21 s | **2.99 GB** |
| `--image-max-tokens 512` | 111/162 (69 %) | 5.9 % | 30/40 | 20 / 16 s | 2.88 GB |
| `-c 2048` + max 512 | 111/162 (69 %) | 5.9 % | 30/40 | 20 / 16 s | 2.66 GB |
| `--image-max-tokens 256` | 100/162 (62 %) | 8.1 % | 29/40 | 13 / 10 s | 2.77 GB |

`-c 2048` costs nothing. Below about 2.6 GB the weights and compute buffers dominate; a real step down needs a
smaller model, and none was good enough.

### Round 3 · preprocessing (Qwen3-VL-2B, 1280 px, `-c 2048`, after clean-up)

| Variant | Photos | Tokens | CER | Right number of thoughts | Thoughts nearly right |
|---|---|---|---|---|---|
| plain | notebook (9) | 124/162 | 5.2 % | 5 of 9 photos | 42/54 |
| contrast (grey, 2–98 % stretch) | notebook (9) | 121/162 | 5.7 % | — | — |
| plain | whiteboard (5) | 31/40 | 5.4 % | 5 of 5 photos | 10/15 |
| contrast | whiteboard (5) | 30/40 | 6.1 % | — | — |
| plain | 2 most skewed notebook photos | 26/36 | 7.9 % | 0 of 2 (3 extra) | 7/12 |
| **straightened** (four corners, + contrast) | same 2 | **28/36** | **4.5 %** | **2 of 2** | **11/12** |

"Nearly right": the thought appears in the output with at most 10 % character errors. On the whiteboard the
miss is the same thought on every photo, the one with `@Kees` read as `Chees`.

Straightening used `copyRectify` from `package:image` with hand-picked corners. Picking them matters: a first
try with corners too tight cut words off at the edge. Straightened photos were also faster (30 s instead of
40 s), as the background is gone.

### What still goes wrong (Qwen3-VL-2B)

- Letters the hand makes alike: `k` read as `h` (`#kweechbah`, `#hoffie`, `wehelijks`), `5km` as `Slim` once.
- The whiteboard `@` is read as `C` on all five photos (`Chees`): the hand, not the model; on paper `@` was
  right 18/18.
- `!` sometimes joins the word before it (`Chees! Morgen`).
- Digits: the phone number came back as `+31 612395678` (4 read as 9) on several photos; dates were right.
- Capitals change now and then (`*normaal`, `#buren`).

Nothing was invented out of thin air on the whiteboard; on the notebook the "invented" tokens are the misread
ones above. The review screen must show tokens, dates and numbers clearly, as they are what a wrong letter
changes.

## Models

Sizes in MB (decimal), GGUF + `mmproj`; limit 1.5 GB (PO 09-10-2026, "need not be strict").

| Model | Source (Hugging Face) | Licence | Size | Result |
|---|---|---|---|---|
| SmolVLM-256M Q8_0 | ggml-org/SmolVLM-256M-Instruct-GGUF@b9e4379 | Apache-2.0 | 278 | weak (synthetic) |
| SmolVLM-500M Q8_0 | ggml-org/SmolVLM-500M-Instruct-GGUF@72e9860 | Apache-2.0 | 544 | too weak |
| InternVL3-1B Q4_K_M | quantised here from ggml-org/InternVL3-1B-Instruct-GGUF@c622c04 (f16) | MIT (LLM part Apache-2.0) | 822 | fails on the notebook |
| InternVL3-1B Q8_0 | ggml-org/InternVL3-1B-Instruct-GGUF@c622c04 | as above | 1007 | not better than Q4 (synthetic) |
| InternVL3-2B Q4_K_M | ggml-org/InternVL3-2B-Instruct-GGUF@f763aa8 | MIT (LLM part Apache-2.0) | 1453 | 2 tokens invented (synthetic) |
| **Qwen3-VL-2B Q4_K_M** | **Qwen/Qwen3-VL-2B-Instruct-GGUF@52d6c8f** | **Apache-2.0** | **1552** | **chosen** |
| Qwen2.5-VL-3B Q4_K_M | ggml-org/Qwen2.5-VL-3B-Instruct-GGUF@5037fcf | Qwen Research (non-commercial) upstream | 2773 | over the limit; licence |
| Gemma 4 E2B Q4_0 | ggml-org/gemma-4-E2B-it-GGUF@b4243c1 | Apache-2.0 (Gemma terms linked) | 3398 | crashes on b11526; over the limit |

SHA-256 of the chosen files (equal to the Hugging Face LFS hashes):

```
089d75c52f4b7ffc56ba998ffc50aae89fcafc755f9e7208aacca281dca6c2ae  Qwen3VL-2B-Instruct-Q4_K_M.gguf
f9a68fabba69c3b81e153367b2c7521030b0fa8bb0de400c9599c8e6725f9c82  mmproj-Qwen3VL-2B-Instruct-Q8_0.gguf
```

The same two files serve Android and Windows; only the native library differs per platform.

## Privacy and offline

- The model runs fully local; llama.cpp was always started with `--offline`.
- Of the prebuilt libraries only `llama-common`, the CLI/server front ends and `ggml-rpc` reference network
  libraries (`ws2_32`, `crypt32`). `ggml-base`, `ggml`, `ggml-cpu-*`, `llama` and `mtmd` do not. An app links
  only the latter plus its own small C shim, built without `LLAMA_CURL` and without `common`, as with whisper.cpp
  in S4.
- The model is imported by hand and checked against SHA-256 values in the app (AC REQ-064 (e), DD-002); never in
  a backup (DD-007).

## Why not the platform OCR engines

- **ML Kit** (Android): "The ML Kit APIs also send metrics about the performance and utilization of the APIs in
  your app to Google", with no opt-out described (<https://developers.google.com/ml-kit/terms>). That conflicts
  with REQ-015, and it is Android only.
- **Windows.Media.Ocr:** "only supported for desktop apps with package identity" (MSIX)
  (<https://learn.microsoft.com/en-us/uwp/api/windows.media.ocr>), a printed-text engine, Windows only. Its
  successor `TextRecognizer` in the Windows App SDK needs an NPU and installs its model on demand
  (<https://learn.microsoft.com/en-us/windows/ai/apis/text-recognition>).
- **Tesseract:** "You can, but it won't work very well, as Tesseract is designed for printed text"
  (<https://tesseract-ocr.github.io/tessdoc/FAQ.html>).

## Native cost (a separate question to the PO)

- **Libraries:** `llama`, `ggml`, `ggml-base`, the `ggml-cpu` backend, `mtmd`, and an own shim, on Android
  (`.so`, arm64) and Windows (`.dll`). The Windows prebuild ships one `ggml-cpu-*` per CPU generation (0.9–1.9 MB
  each) and `libomp`; an own build can pick one backend. Order of size on Windows: `llama` 3.4 MB, `mtmd` 1.8 MB,
  `ggml-base` 0.8 MB, one CPU backend about 1.5 MB.
- They go into `tool/allowed_native_libs.txt` (PO approval) and `bundledLicenses` (llama.cpp and ggml: MIT).
  The model is not bundled, so its licence (Apache-2.0) belongs in the import screen and the manual, not in
  *About Offload*.

## Business cards (Q14)

Not tested. A model that reads handwriting at this level should read printed cards better, so S5 could start
from Qwen3-VL-2B instead of a separate OCR engine. A guess, not a result.

## Not tested

- The phone (speed, memory, whether Android kills the app at 3 GB). The emulator says nothing about this
  (S4: 30–50× slower than the PC).
- Other hands, long pages, tables or drawings, poor light at night, a photo upside down.
- Straightening on all photos, and automatic corner detection: corners were picked by hand.
- Prompts other than B on the real photos; quantisations other than Q4_K_M for Qwen3-VL-2B.

## Questions for the PO

1. GO for M6a with Qwen3-VL-2B, with the phone measurement as its first step and gate?
2. The limit for that gate (proposal: not killed, at most about 2 minutes per photo)?
3. Q44: keep the `-` convention?
4. Q45: four-corner straightening in M6a; for the photo attachment (T5.3) only *rotate 90°* for now?
5. Q43: image input (M6a) before speech (M6)?
6. The native libraries of llama.cpp into the allow-list (when M6a starts)?

## Reproducing

```
# spikes/s6_handwriting (not versioned): models in models/ (hashes in models/sha256.txt),
# llama.cpp in dl/llama-b11526/
dart run prep/bin/crop.dart <in.jpg> <out.jpg> <top>          # cut off the top of a photo
dart run prep/bin/prep.dart <in.jpg> <outDir> --side 1280 [--corners x1,y1,...,x4,y4]
powershell -File run.ps1 -ImageDir <dir> -Models qwen3vl2 -Prompts B -Tag <tag> -Ctx 2048 [-Extra '--image-max-tokens 512']
python -I normalise.py <tag>                                    # clean-up, then the same score
```
