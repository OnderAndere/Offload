import 'dart:io';
import 'dart:math' as math;

import 'handwriting_reader.dart';
import 'native_handwriting_reader.dart';

/// The [HandwritingReader] for the platform the app runs on (T6a.2).
HandwritingReader createPlatformHandwritingReader() {
  // 6 threads on the phone (T6a.1: 4 slower, 8 no faster on the Fairphone).
  if (Platform.isAndroid) {
    return NativeHandwritingReader(
      libraryName: 'liboffload_llama.so',
      threads: 6,
    );
  }
  // One thread per core on the PC: processors counts hyperthreads twice.
  if (Platform.isWindows) {
    return NativeHandwritingReader(
      libraryName: 'offload_llama.dll',
      threads: math.max(1, math.min(8, Platform.numberOfProcessors ~/ 2)),
    );
  }
  throw UnsupportedError('Offload runs on Android and Windows only');
}
