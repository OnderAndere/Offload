import 'package:flutter/services.dart';

import 'contact_launcher.dart';

/// [ContactLauncher] on Android (`ContactLauncherChannel.kt`): `ACTION_DIAL`
/// opens the dialler with the number filled in, `ACTION_SENDTO` a new
/// message; neither needs a permission, and nothing happens without the
/// user.
class AndroidContactLauncher implements ContactLauncher {
  static const _channel = MethodChannel('eu.marandos.offload/contact');

  @override
  bool get canDial => true;

  @override
  Future<void> dial(String number) => _open('dial', telUri(number));

  @override
  Future<void> mail(String address) => _open('mail', mailtoUri(address));

  Future<void> _open(String method, Uri uri) async {
    try {
      await _channel.invokeMethod<void>(method, {'uri': uri.toString()});
    } on PlatformException catch (e) {
      throw ContactLauncherException(e.message ?? e.code);
    }
  }
}
