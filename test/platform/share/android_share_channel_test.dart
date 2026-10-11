import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/platform/share/android_share_channel.dart';
import 'package:offload/platform/share/share_channel.dart';

/// Sharing a file on Android (DD-014): written into the share folder the
/// platform hands out, then passed to the share menu; never half a file.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('eu.marandos.offload/share');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final share = AndroidShareChannel();
  late Directory directory;
  late List<MethodCall> calls;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('offload_share_');
    calls = [];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return switch (call.method) {
        'prepareShareDirectory' => directory.path,
        _ => null,
      };
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    directory.deleteSync(recursive: true);
  });

  Future<ShareResult> shareBackup(Future<void> Function(File) write) =>
      share.shareFile(
        fileName: 'Offload-backup.offload',
        mimeType: 'application/octet-stream',
        target: ShareTarget.system,
        subject: 'Offload-backup',
        write: write,
      );

  test('only the share menu takes files', () {
    expect(share.fileTargets, [ShareTarget.system]);
  });

  test('the written file is handed to the share menu', () async {
    final result = await shareBackup((file) => file.writeAsString('encrypted'));

    expect(result, ShareResult.done);
    expect(calls.map((c) => c.method), ['prepareShareDirectory', 'shareFile']);
    final path = '${directory.path}/Offload-backup.offload';
    expect(calls.last.arguments, {
      'path': path,
      'mimeType': 'application/octet-stream',
      'subject': 'Offload-backup',
    });
    expect(File(path).readAsStringSync(), 'encrypted');
  });

  test('a failed write removes the half file and shares nothing', () async {
    await expectLater(
      shareBackup((file) async {
        await file.writeAsString('half');
        throw const FileSystemException('disk full');
      }),
      throwsA(isA<FileSystemException>()),
    );

    expect(calls.map((c) => c.method), ['prepareShareDirectory']);
    expect(directory.listSync(), isEmpty);
  });

  test('a failing share menu is a ShareChannelException', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'shareFile') {
        throw PlatformException(code: 'unavailable', message: 'no app');
      }
      return directory.path;
    });

    await expectLater(
      shareBackup((file) => file.writeAsString('encrypted')),
      throwsA(isA<ShareChannelException>()),
    );
  });

  test('another target is refused', () async {
    await expectLater(
      share.shareFile(
        fileName: 'x',
        mimeType: 'application/octet-stream',
        target: ShareTarget.file,
        write: (_) async {},
      ),
      throwsArgumentError,
    );
  });
}
