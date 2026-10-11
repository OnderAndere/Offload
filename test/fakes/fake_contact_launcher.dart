import 'package:offload/platform/contact_launcher/contact_launcher.dart';

/// A [ContactLauncher] that remembers what it was asked to open.
class FakeContactLauncher implements ContactLauncher {
  FakeContactLauncher({this.canDial = true, this.fails = false});

  @override
  final bool canDial;

  /// Every call throws, as when no app takes the link.
  final bool fails;

  final dialled = <String>[];
  final mailed = <String>[];

  @override
  Future<void> dial(String number) async {
    if (fails) throw const ContactLauncherException('none');
    dialled.add(number);
  }

  @override
  Future<void> mail(String address) async {
    if (fails) throw const ContactLauncherException('none');
    mailed.add(address);
  }
}
