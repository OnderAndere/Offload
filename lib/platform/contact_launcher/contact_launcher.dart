/// Opening a phone number in the dialler or an email address in the mail
/// app (REQ-038, DD-018 point 9). Nothing is sent: the dialler and the mail
/// app only open, the user calls or sends there. No permission and no
/// plugin: Android uses `ACTION_DIAL` and `ACTION_SENDTO`, Windows the
/// shell's `mailto:` handler.
abstract class ContactLauncher {
  /// Whether this platform can open a number in a dialler. Windows cannot
  /// reliably (a `tel:` link often has no target): there a number is copied
  /// instead.
  bool get canDial;

  /// Opens [number] in the dialler, as typed. Throws a
  /// [ContactLauncherException] when no app takes it.
  Future<void> dial(String number);

  /// Opens a new message to [address] in the mail app. Throws a
  /// [ContactLauncherException] when no app takes it.
  Future<void> mail(String address);
}

class ContactLauncherException implements Exception {
  const ContactLauncherException(this.message);

  final String message;

  @override
  String toString() => 'ContactLauncherException: $message';
}

/// The `tel:` link for [number]: only the characters a dialler knows (digits,
/// a leading `+`), so spaces and dashes as typed never break it. A trunk
/// zero written as "(0)" after a country code is left out ("+31 (0)20" is
/// "+3120"). A national number goes as typed: the dialler knows it, and a
/// wrong home country in Settings never breaks dialling (T3.6).
Uri telUri(String number) {
  final typed = number.trim();
  final text = typed.startsWith('+') ? typed.replaceAll('(0)', '') : typed;
  final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
  return Uri(scheme: 'tel', path: text.startsWith('+') ? '+$digits' : digits);
}

/// The `mailto:` link for [address].
Uri mailtoUri(String address) => Uri(scheme: 'mailto', path: address.trim());
