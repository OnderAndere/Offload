/// How a photo of handwriting is read (REQ-064, DD-021): the settings that
/// spike S6 and the phone gate of T6a.1 settled for Qwen3-VL-2B, in one
/// place.
library;

/// Accurate or faster reading (DD-021, PO 11-10-2026), chosen per device in
/// Settings → *Models* (T6a.3).
enum ReadingSpeed {
  /// The model's own number of image tokens: the default.
  accurate,

  /// At most 512 image tokens: about half the time, sometimes reads small
  /// signs less well.
  faster;

  /// The speed stored as [name]; [accurate] for anything else.
  static ReadingSpeed parse(String? name) =>
      values.where((s) => s.name == name).firstOrNull ?? accurate;
}

class ReadingPolicy {
  const ReadingPolicy({
    this.maxSide = 1280,
    this.contextSize = 2048,
    this.maxTextTokens = 1024,
    this.fasterImageTokens = 512,
    this.prompt = readingPrompt,
  });

  /// The values of DD-021.
  static const standard = ReadingPolicy();

  /// The longest side of the image given to the model, in pixels.
  final int maxSide;

  /// The model's context: image tokens, prompt and text together.
  final int contextSize;

  /// The most text tokens written for one image; the context ends it sooner
  /// when the image took most of it.
  final int maxTextTokens;

  /// The image tokens of [ReadingSpeed.faster].
  final int fasterImageTokens;

  /// What the model is asked.
  final String prompt;

  /// The limit on image tokens for [speed]; 0 keeps the model's own.
  int imageTokensFor(ReadingSpeed speed) => switch (speed) {
    ReadingSpeed.accurate => 0,
    ReadingSpeed.faster => fasterImageTokens,
  };
}

/// Prompt B of spike S6, literally (DD-021). English, because the model
/// follows English instructions best; the text it reads stays as written.
const readingPrompt =
    'Transcribe the handwritten text in this image exactly, line by line, '
    'one output line per written line. Keep every symbol exactly as written, '
    'including - @ ! # ^ * and digits. Do not add, remove, correct, translate '
    'or complete anything. The text is Dutch. Output only the text.';
