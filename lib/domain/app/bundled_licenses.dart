/// A licence Flutter does not collect by itself (REQ-062): of native code
/// and typefaces that ship with the app. Flutter's overview holds the Dart
/// packages and the engine; everything else is listed here.
///
/// [covers] names what the licence is for: file names from
/// `tool/allowed_native_libs.txt`, or a folder of bundled assets ending in
/// `/`. A test checks that every allowed native library and every bundled
/// font is covered, so a new one cannot ship without its licence.
typedef BundledLicense = ({
  List<String> packages,
  List<String> covers,
  String asset,
});

final bundledLicenses = <BundledLicense>[
  (
    packages: ['IBM Plex Sans', 'IBM Plex Mono'],
    covers: ['assets/fonts/'],
    asset: 'assets/fonts/OFL.txt',
  ),
  (
    packages: ['SQLite3MultipleCiphers'],
    covers: ['libsqlite3mc.so', 'sqlite3mc.dll'],
    asset: 'assets/licenses/SQLite3MultipleCiphers.txt',
  ),
  // Code by others inside SQLite3MultipleCiphers whose licence asks for
  // its notice in binary distributions (checked in its sources 03-10-2026;
  // public-domain and CC0 parts need none, miniz is not compiled in).
  for (final part in ['sha2', 'chacha20', 'aegis'])
    (
      packages: ['SQLite3MultipleCiphers'],
      covers: ['libsqlite3mc.so', 'sqlite3mc.dll'],
      asset: 'assets/licenses/SQLite3MultipleCiphers-$part.txt',
    ),
  // The Material icons: Flutter's icon font, which the app ships and
  // Flutter's overview does not list (found 06-10-2026), and the Today and
  // Insights icons of the Offload bar, copied from it as Android drawables
  // (REQ-063). The text is the one Flutter ships with the font.
  (
    packages: ['Material Icons (Google)'],
    covers: [
      'MaterialIcons-Regular.otf',
      'res/drawable/ic_bar_today.xml',
      'res/drawable/ic_bar_insights.xml',
      // Recoloured on a navy circle (CC BY 4.0 asks to say so).
      'res/drawable/ic_shortcut_today.xml',
      'res/drawable/ic_shortcut_insights.xml',
    ],
    asset: 'assets/licenses/MaterialIcons.txt',
  ),
  // Code by others inside the Dart packages image and archive (the JPEG
  // code of image comes from jpgjs, Apache-2.0): their LICENSE-other.md,
  // which Flutter does not collect (review T5.2), in full. Listed under the
  // package names, so they sit with the packages' own licences.
  for (final package in ['image', 'archive'])
    (
      packages: [package],
      covers: const <String>[],
      asset: 'assets/licenses/$package-other.txt',
    ),
  // The handwriting reader (T6a.2, DD-021): llama.cpp with ggml and mtmd,
  // built into offload_llama (MIT, PO 11-10-2026), and the code by others
  // inside it that carries its own notice: llamafile's matrix code
  // (Mozilla) and YaRN (checked in the b11526 sources 11-10-2026).
  // stb_image, miniaudio and the hash code of llama.cpp's vendor folder are
  // not linked in: the app passes pixels, not files.
  for (final part in ['', '-sgemm', '-yarn'])
    (
      packages: ['llama.cpp'],
      covers: ['liboffload_llama.so', 'offload_llama.dll'],
      asset: 'assets/licenses/llama.cpp$part.txt',
    ),
  // Under the name Flutter's own overview uses for SQLite, so both
  // statements are listed together.
  (
    packages: ['sqlite'],
    covers: ['libsqlite3mc.so', 'sqlite3mc.dll'],
    asset: 'assets/licenses/SQLite.txt',
  ),
];

/// Native files whose licences Flutter collects itself: the engine and the
/// app's own code (under the licence of Offload).
const flutterNativeFiles = {
  'libflutter.so',
  'libapp.so',
  'flutter_windows.dll',
  'offload.exe',
};

/// Where the licence of Offload itself is bundled: GPL-3.0-or-later (Q37).
const appLicenseAsset = 'LICENSE';
