import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import '../../domain/handwriting/reading_policy.dart';
import 'handwriting_reader.dart';

/// [HandwritingReader] on the app's own native library `offload_llama`
/// (`native/offload_llama/`, T6a.2): llama.cpp with mtmd, called through
/// `dart:ffi` in a background isolate, so the UI keeps running while the
/// model works. The same code on Android and Windows; only the library's
/// file name and the number of threads differ.
class NativeHandwritingReader implements HandwritingReader {
  NativeHandwritingReader({
    required this.libraryName,
    required this.threads,
    required this.pausesOutsideApp,
    this.pollInterval = const Duration(milliseconds: 250),
  });

  /// `liboffload_llama.so` or `offload_llama.dll`.
  final String libraryName;

  /// CPU threads for the model (DD-021: 6 on the phone).
  final int threads;

  @override
  final bool pausesOutsideApp;

  /// How often progress and [ReadingCancel] are looked at while reading.
  final Duration pollInterval;

  _Library? _library;
  bool _opened = false;

  /// One reading at a time in the whole process, whichever instance asks:
  /// the native library holds one model at a time (offload_llama.h).
  static bool _busy = false;

  _Library? get _lib {
    if (!_opened) {
      _opened = true;
      try {
        _library = _Library(DynamicLibrary.open(libraryName));
      } on ArgumentError {
        _library = null;
      }
    }
    return _library;
  }

  @override
  bool get isAvailable => _lib != null;

  @override
  Future<HandwritingReading> read({
    required HandwritingModel model,
    required ReadingImage image,
    ReadingSpeed speed = ReadingSpeed.accurate,
    ReadingPolicy policy = ReadingPolicy.standard,
    void Function(ReadingProgress progress)? onProgress,
    ReadingCancel? cancel,
  }) async {
    // Checked here, not only by an assert: the native side reads exactly
    // width × height × 3 bytes.
    if (image.width <= 0 ||
        image.height <= 0 ||
        image.rgb.length != image.width * image.height * 3) {
      throw const HandwritingReaderException(HandwritingFailure.badImage);
    }
    final lib = _lib;
    if (lib == null) {
      throw const HandwritingReaderException(HandwritingFailure.unavailable);
    }
    if (_busy) throw StateError('one reading at a time');
    // The status is shared with the reading thread: it writes phase and
    // tokens, this isolate writes cancel.
    final status = lib.bytes8(sizeOf<_Status>()).cast<_Status>();
    _busy = true;
    ReadingProgress? last;
    void poll() {
      if (cancel?.isCancelled ?? false) status.ref.cancel = 1;
      final phase = switch (status.ref.phase) {
        _phaseLoading => ReadingPhase.loading,
        _phaseEncoding => ReadingPhase.encoding,
        _phaseWriting => ReadingPhase.writing,
        _ => null,
      };
      if (phase == null) return;
      final progress = ReadingProgress(phase, status.ref.tokens);
      if (progress != last) {
        last = progress;
        onProgress?.call(progress);
      }
    }

    final timer = Timer.periodic(pollInterval, (_) => poll());
    try {
      final job = _Job(
        libraryName: libraryName,
        modelPath: model.languageModelPath,
        projectorPath: model.projectorPath,
        width: image.width,
        height: image.height,
        rgb: TransferableTypedData.fromList([image.rgb]),
        prompt: policy.prompt,
        threads: threads,
        contextSize: policy.contextSize,
        imageMaxTokens: policy.imageTokensFor(speed),
        maxTextTokens: policy.maxTextTokens,
        statusAddress: status.address,
      );
      final outcome = await _runInBackground(job);
      if (outcome.error != _errorNone) {
        throw HandwritingReaderException(_failureOf(outcome.error));
      }
      return HandwritingReading(
        text: outcome.text,
        loadTime: _ms(outcome.loadMs),
        encodeTime: _ms(outcome.encodeMs),
        totalTime: _ms(outcome.totalMs),
      );
    } finally {
      timer.cancel();
      lib.free(status.cast());
      _busy = false;
    }
  }

  static Duration _ms(double ms) => Duration(microseconds: (ms * 1000).round());

  static HandwritingFailure _failureOf(int error) => switch (error) {
    _errorModel || _errorProjector => HandwritingFailure.modelUnreadable,
    _errorContext => HandwritingFailure.outOfMemory,
    _errorImage => HandwritingFailure.badImage,
    _errorCancelled => HandwritingFailure.cancelled,
    _ => HandwritingFailure.failed,
  };
}

// enum ol_phase and enum ol_error of offload_llama.h.
const _phaseLoading = 1;
const _phaseEncoding = 2;
const _phaseWriting = 3;
const _errorNone = 0;
const _errorModel = 1;
const _errorProjector = 2;
const _errorContext = 3;
const _errorImage = 4;
const _errorCancelled = 7;

/// `ol_status` of offload_llama.h.
final class _Status extends Struct {
  @Int32()
  external int cancel;
  @Int32()
  external int phase;
  @Int32()
  external int tokens;
}

/// `ol_result` of offload_llama.h.
final class _Result extends Struct {
  external Pointer<Uint8> text;
  @Int32()
  external int error;
  @Double()
  external double loadMs;
  @Double()
  external double encodeMs;
  @Double()
  external double totalMs;
}

typedef _ReadNative =
    Void Function(
      Pointer<Uint8>,
      Pointer<Uint8>,
      Pointer<Uint8>,
      Int32,
      Int32,
      Pointer<Uint8>,
      Int32,
      Int32,
      Int32,
      Int32,
      Pointer<_Status>,
      Pointer<_Result>,
    );
typedef _ReadDart =
    void Function(
      Pointer<Uint8>,
      Pointer<Uint8>,
      Pointer<Uint8>,
      int,
      int,
      Pointer<Uint8>,
      int,
      int,
      int,
      int,
      Pointer<_Status>,
      Pointer<_Result>,
    );

/// The three functions of offload_llama.h.
class _Library {
  _Library(DynamicLibrary lib)
    : read = lib.lookupFunction<_ReadNative, _ReadDart>('ol_read'),
      alloc = lib
          .lookupFunction<
            Pointer<Void> Function(Int64),
            Pointer<Void> Function(int)
          >('ol_alloc'),
      free = lib
          .lookupFunction<
            Void Function(Pointer<Void>),
            void Function(Pointer<Void>)
          >('ol_free');

  final _ReadDart read;
  final Pointer<Void> Function(int) alloc;
  final void Function(Pointer<Void>) free;

  /// [text] as a NUL-terminated UTF-8 string; free with [free].
  Pointer<Uint8> string(String text) {
    final bytes = utf8.encode(text);
    final p = bytes8(bytes.length + 1);
    p.asTypedList(bytes.length + 1)
      ..setAll(0, bytes)
      ..[bytes.length] = 0;
    return p;
  }

  /// [length] zeroed bytes; throws when the memory is not there.
  Pointer<Uint8> bytes8(int length) {
    final p = alloc(length).cast<Uint8>();
    if (p == nullptr) {
      throw const HandwritingReaderException(HandwritingFailure.outOfMemory);
    }
    return p;
  }
}

/// Everything the background isolate needs: only sendable values.
class _Job {
  const _Job({
    required this.libraryName,
    required this.modelPath,
    required this.projectorPath,
    required this.width,
    required this.height,
    required this.rgb,
    required this.prompt,
    required this.threads,
    required this.contextSize,
    required this.imageMaxTokens,
    required this.maxTextTokens,
    required this.statusAddress,
  });

  final String libraryName;
  final String modelPath;
  final String projectorPath;
  final int width;
  final int height;
  final TransferableTypedData rgb;
  final String prompt;
  final int threads;
  final int contextSize;
  final int imageMaxTokens;
  final int maxTextTokens;
  final int statusAddress;
}

typedef _Outcome = ({
  int error,
  String text,
  double loadMs,
  double encodeMs,
  double totalMs,
});

// A top-level function: a closure made inside the reader would capture its
// Timer, which cannot be sent to another isolate (T6a.1).
Future<_Outcome> _runInBackground(_Job job) => Isolate.run(() => _read(job));

_Outcome _read(_Job job) {
  final lib = _Library(DynamicLibrary.open(job.libraryName));
  final pixels = job.rgb.materialize().asUint8List();
  final allocated = <Pointer<Uint8>>[];
  Pointer<Uint8> keep(Pointer<Uint8> p) {
    allocated.add(p);
    return p;
  }

  try {
    final model = keep(lib.string(job.modelPath));
    final projector = keep(lib.string(job.projectorPath));
    final prompt = keep(lib.string(job.prompt));
    final rgb = keep(lib.bytes8(pixels.length));
    rgb.asTypedList(pixels.length).setAll(0, pixels);
    final result = keep(lib.bytes8(sizeOf<_Result>())).cast<_Result>();
    lib.read(
      model,
      projector,
      rgb,
      job.width,
      job.height,
      prompt,
      job.threads,
      job.contextSize,
      job.imageMaxTokens,
      job.maxTextTokens,
      Pointer<_Status>.fromAddress(job.statusAddress),
      result,
    );
    final r = result.ref;
    var text = '';
    if (r.text != nullptr) {
      text = utf8.decode(_untilNul(r.text), allowMalformed: true);
      lib.free(r.text.cast());
    }
    return (
      error: r.error,
      text: text,
      loadMs: r.loadMs,
      encodeMs: r.encodeMs,
      totalMs: r.totalMs,
    );
  } finally {
    for (final p in allocated) {
      lib.free(p.cast());
    }
  }
}

Uint8List _untilNul(Pointer<Uint8> p) {
  var n = 0;
  while (p[n] != 0) {
    n++;
  }
  return p.asTypedList(n);
}
