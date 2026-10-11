/// How the prefix bar in quick capture is shown (REQ-034, DD-004 "Keuze —
/// invoerhulp"). A setting of this device, never synchronised.
enum PrefixBarMode {
  /// A button with sign and label per token; the default (AC REQ-034).
  always,

  /// One slim row with only the signs, which the user can expand to the
  /// full buttons; the bar remembers which of the two it shows.
  collapsed,

  /// No bar.
  off;

  /// The stored name, or [always] for a missing or unknown value.
  static PrefixBarMode parse(String? stored) =>
      values.firstWhere((mode) => mode.name == stored, orElse: () => always);
}
