# Fonts

IBM Plex, bundled as plain assets: never downloaded at run time (hard rule 1, DD-017).
Licence: SIL Open Font License 1.1, in [`OFL.txt`](OFL.txt). The app registers it with
Flutter's `LicenseRegistry` (`lib/presentation/theme/app_theme.dart`).

| File | Family | Weight |
|---|---|---|
| `IBMPlexSans-Regular.ttf` | IBM Plex Sans | 400 |
| `IBMPlexSans-Medium.ttf` | IBM Plex Sans | 500 |
| `IBMPlexSans-SemiBold.ttf` | IBM Plex Sans | 600 |
| `IBMPlexSans-Bold.ttf` | IBM Plex Sans | 700 |
| `IBMPlexMono-Regular.ttf` | IBM Plex Mono | 400 |
| `IBMPlexMono-SemiBold.ttf` | IBM Plex Mono | 600 |

Only the weights the app uses; no italics (the app has no italic text). Every file has the full
Cyrillic block U+0410–U+044F plus Ё/ё, Є/є, І/і, Ї/ї and Ґ/ґ (checked with fontTools, 02-10-2026;
AC REQ-005).

## Source

From the official releases of [IBM/plex](https://github.com/IBM/plex), downloaded on 02-10-2026
with the product owner's approval. The files are `fonts/complete/ttf/` of each archive, unchanged.

| Archive | Release | SHA-256 |
|---|---|---|
| `ibm-plex-sans.zip` | `@ibm/plex-sans@1.1.0` | `fb365d910566e6d199cc2c15579a7dd9a267128e18431a394ed81f1970c69200` |
| `ibm-plex-mono.zip` | `@ibm/plex-mono@2.5.0` | `6d23f01257663d8cc49a0d64c22ced630b79e0e2a0ac08a0da86e9a38bbc481c` |

| File | SHA-256 |
|---|---|
| `IBMPlexSans-Regular.ttf` | `975dcda37d80f038dcd143c22e33ca2d97a0cc5a929aace1c749153b0fe1afa5` |
| `IBMPlexSans-Medium.ttf` | `331c8639d7598b2cde62a911a71db195e30cb655cd6bdf2e324a7e984955f907` |
| `IBMPlexSans-SemiBold.ttf` | `a20caf8286023a6a7a85e40b1d2a4ae9fc3e3b1f9eda8f4c542dd4986af67bb1` |
| `IBMPlexSans-Bold.ttf` | `9e6c74a889a700d707613d24548fe4ffa6bc59559a0689d2cf9e133bdcdafb2f` |
| `IBMPlexMono-Regular.ttf` | `7c6fbddca4b700be918f5f6183d9bd4464fa427fe435f0b480d77fe2bb8c5a43` |
| `IBMPlexMono-SemiBold.ttf` | `f04d7c488ddf7d1fa99f2574efc3406ea4cbe17bb1af3a1ab960f84d0c96a172` |

`OFL.txt` is `LICENSE.txt` of the archives (identical in both).
