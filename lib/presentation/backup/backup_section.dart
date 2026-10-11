import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/backup/backup_attachments.dart';
import '../../data/storage/app_storage.dart';
import '../../data/storage/storage_counts.dart';
import '../../domain/backup/backup.dart';
import '../../l10n/app_localizations.dart';
import '../../platform/app_directory/app_directory.dart';
import '../../platform/backup_file/backup_file_picker.dart';
import '../../platform/cipher/platform_aead_cipher.dart';
import '../../platform/share/share_channel.dart';
import '../messages.dart';
import '../settings/storage_section.dart';
import '../share_channel_provider.dart';
import '../startup/app_storage_provider.dart';
import 'backup_file_picker_provider.dart';
import 'busy_dialog.dart';
import 'export_tile.dart';
import 'file_destination.dart';

/// Whether this device has a backup passphrase (T7.1).
final hasBackupPassphraseProvider = FutureProvider.autoDispose<bool>(
  (ref) => ref.watch(storageProvider).hasBackupPassphrase(),
);

/// Settings → Back-up en export (T7.1, T7.2, T7.3, REQ-014, REQ-026,
/// DD-007): the passphrase, making and restoring a backup, the export.
class BackupSection extends ConsumerWidget {
  const BackupSection({super.key, required this.headerStyle});

  final TextStyle? headerStyle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final hasPassphrase = ref.watch(hasBackupPassphraseProvider).valueOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(title: Text(l10n.settingsBackupHeader, style: headerStyle)),
        ListTile(
          leading: const Icon(Icons.key_outlined),
          title: Text(l10n.backupPassphraseRow),
          subtitle: Text(
            hasPassphrase ?? false
                ? l10n.backupPassphraseSet
                : l10n.backupPassphraseNotSet,
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _setPassphrase(context, ref),
        ),
        ListTile(
          leading: const Icon(Icons.save_alt),
          title: Text(l10n.backupMake),
          subtitle: Text(l10n.backupMakeSubtitle),
          onTap: () => _makeBackup(context, ref),
        ),
        ListTile(
          leading: const Icon(Icons.settings_backup_restore),
          title: Text(l10n.backupRestore),
          subtitle: Text(l10n.backupRestoreSubtitle),
          onTap: () => _restore(context, ref),
        ),
        // Unencrypted, so after the backup rows (T7.3).
        const ExportTile(),
      ],
    );
  }

  Future<bool> _setPassphrase(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final changing = await ref.read(storageProvider).hasBackupPassphrase();
    if (!context.mounted) return false;
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => PassphraseDialog(changing: changing),
    );
    if (saved ?? false) {
      ref.invalidate(hasBackupPassphraseProvider);
      showMessage(
        messenger,
        SnackBar(content: Text(l10n.backupPassphraseSaved)),
      );
      return true;
    }
    return false;
  }

  Future<void> _makeBackup(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final storage = ref.read(storageProvider);
    // Without a passphrase, set it first (AC REQ-026).
    if (!await storage.hasBackupPassphrase()) {
      if (!context.mounted || !await _setPassphrase(context, ref)) return;
    }
    // With or without the attachments (T7.2b, DD-007 point 7a): asked
    // only when this device has any, on by default.
    final counts = await readStorageCounts(storage.database);
    final attachmentBytes = counts.attachmentBytes.values.fold(
      0,
      (sum, bytes) => sum + bytes,
    );
    var withAttachments = false;
    if (counts.attachmentBytes.isNotEmpty) {
      if (!context.mounted) return;
      final chosen = await showDialog<bool>(
        context: context,
        builder: (_) => _BackupOptionsDialog(attachmentBytes: attachmentBytes),
      );
      if (chosen == null) return;
      withAttachments = chosen;
    }
    if (!context.mounted) return;
    final share = ref.read(shareChannelProvider);
    // Android also offers the share menu (DD-014); Windows saves directly.
    var destination = FileDestination.save;
    if (share.fileTargets.contains(ShareTarget.system)) {
      final chosen = await chooseFileDestination(context, l10n.backupMake);
      if (chosen == null || !context.mounted) return;
      destination = chosen;
    }
    final name = l10n.backupFileName(_today());
    final appDirectory = ref.read(appDirectoryProvider);
    final cipher = withAttachments ? backgroundAeadCipherFactory() : null;
    final needed = roomNeeded(
      storage.databaseBytes() + (withAttachments ? attachmentBytes : 0),
    );
    BackupAttachmentsResult? made;
    // Checked where the file goes, before anything is written (DD-007
    // point 5): on Android the copy in the app's cache.
    Future<void> write(File target) async {
      await _checkRoom(appDirectory, target.parent, needed);
      // Never a silent return: the picker would take it for a written file.
      if (!context.mounted) {
        throw const BackupException(BackupProblem.unreadable);
      }
      made = await withProgress(
        context,
        (onProgress) =>
            storage.makeBackup(target, cipher: cipher, onProgress: onProgress),
      );
    }

    String told(String message) => madeText(message, made, l10n);
    try {
      switch (destination) {
        case FileDestination.share:
          final result = await share.shareFile(
            fileName: '$name.$backupFileExtension', // l10n-ignore: a file name
            mimeType: backupMimeType,
            target: ShareTarget.system,
            subject: name,
            write: write,
          );
          // Android does not say whether it was really sent.
          if (result == ShareResult.done) {
            showMessage(
              messenger,
              SnackBar(content: Text(told(l10n.backupReadyToShare))),
            );
          }
        case FileDestination.save:
          final saved = await ref
              .read(backupFilePickerProvider)
              .saveBackup(
                suggestedName: name,
                fileTypeName: l10n.backupFileType,
                write: write,
              );
          if (saved) {
            showMessage(
              messenger,
              SnackBar(content: Text(told(l10n.backupMade))),
            );
          }
      }
    } on _NoRoom catch (e) {
      showMessage(messenger, SnackBar(content: Text(_problemText(e, l10n))));
    } catch (_) {
      showMessage(messenger, SnackBar(content: Text(l10n.backupFailed)));
    }
  }

  /// [message] after a backup was made, with how many attachments were
  /// missing from [made] (DD-007 point 2).
  @visibleForTesting
  static String madeText(
    String message,
    BackupAttachmentsResult? made,
    AppLocalizations l10n,
  ) => switch (made) {
    BackupAttachmentsResult(:final missing) when missing > 0 =>
      l10n.backupMissingNote(message, missing),
    _ => message,
  };

  /// The line about attachments in the restore confirmation, or null: how
  /// many the backup holds; for a backup without, when this device has some,
  /// that only its files of the restored items stay (DD-007 point 7c,
  /// option b).
  @visibleForTesting
  static String? restoreAttachmentsLine(
    BackupInfo info, {
    required bool deviceHasAttachments,
    required AppLocalizations l10n,
  }) {
    if (info.withAttachments) {
      return info.attachments > 0
          ? l10n.backupRestoreWithAttachments(info.attachments)
          : null;
    }
    return deviceHasAttachments ? l10n.backupRestoreNoAttachments : null;
  }

  /// Throws [_NoRoom] when the drive of [folder] has less than [needed]
  /// bytes free; goes on when the platform cannot tell.
  static Future<void> _checkRoom(
    AppDirectory appDirectory,
    Directory folder,
    int needed,
  ) async {
    int? free;
    try {
      free = await appDirectory.freeBytes(folder);
    } catch (_) {
      free = null;
    }
    if (free != null && free < needed) throw _NoRoom(needed, free);
  }

  /// Restore (DD-007): choose the file, check it with this device's own
  /// passphrase and else the one asked for, confirm, then the storage closes,
  /// the restore is put in place and the app opens again.
  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final storage = ref.read(storageProvider);
    final directory = storage.directory;
    if (directory == null) return;
    final appDirectory = ref.read(appDirectoryProvider);
    BackupInfo? info;
    try {
      await ref
          .read(backupFilePickerProvider)
          .openBackup(
            fileTypeName: l10n.backupFileType,
            read: (source) async {
              // The copy of the database and the attachments it holds,
              // each about the size of the backup (DD-007 point 5).
              await _checkRoom(
                appDirectory,
                directory,
                roomNeeded(2 * source.lengthSync()),
              );
              if (!context.mounted) return;
              info = await _prepare(context, storage, source);
            },
          );
    } catch (e) {
      AppStorage.discardRestore(directory);
      showMessage(messenger, SnackBar(content: Text(_problemText(e, l10n))));
      return;
    }
    final prepared = info;
    if (prepared == null || !context.mounted) {
      AppStorage.discardRestore(directory);
      return;
    }
    final attachmentsLine = restoreAttachmentsLine(
      prepared,
      deviceHasAttachments:
          !prepared.withAttachments &&
          (await readStorageCounts(
            storage.database,
          )).attachmentBytes.isNotEmpty,
      l10n: l10n,
    );
    if (!context.mounted) {
      AppStorage.discardRestore(directory);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.backupRestoreConfirmTitle),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(switch (prepared.newestChange) {
                final newest? => l10n.backupRestoreConfirmBody(
                  prepared.items,
                  newest.toLocal(),
                ),
                null => l10n.backupRestoreConfirmBodyUndated(prepared.items),
              }),
              if (attachmentsLine != null) ...[
                const SizedBox(height: 12),
                Text(attachmentsLine),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.backupCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.backupRestoreConfirm),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false)) {
      AppStorage.discardRestore(directory);
      return;
    }
    // Closed before the files change; opening again shows the start-up
    // screen, then the app with the restored data and a new device id.
    // Opened again whatever happens: a swap that failed halfway is finished
    // or rolled back at the start (`AppStorage.open`), never left running
    // on a closed database (review).
    await storage.close();
    try {
      AppStorage.finishRestore(directory);
    } finally {
      ref.invalidate(appStorageProvider);
    }
  }

  /// Prepares the restore of [source], asking for its passphrase while this
  /// device's own does not open it. Null when the user gave up.
  Future<BackupInfo?> _prepare(
    BuildContext context,
    AppStorage storage,
    File source,
  ) async {
    String? passphrase;
    var wrong = false;
    while (true) {
      if (!context.mounted) return null;
      try {
        // The cipher always: a backup with attachments needs it (T7.2b).
        return await withProgress(
          context,
          (onProgress) => storage.prepareRestore(
            source,
            passphrase: passphrase,
            cipher: backgroundAeadCipherFactory(),
            onProgress: onProgress,
          ),
        );
      } on BackupException catch (e) {
        if (e.problem != BackupProblem.wrongPassphrase || !context.mounted) {
          rethrow;
        }
        passphrase = await showDialog<String>(
          context: context,
          builder: (_) => _AskPassphraseDialog(wrong: wrong),
        );
        if (passphrase == null) return null;
        wrong = true;
      }
    }
  }

  static String _problemText(Object error, AppLocalizations l10n) =>
      switch (error) {
        BackupException(problem: BackupProblem.wrongPassphrase) =>
          l10n.backupWrongPassphrase,
        BackupException(problem: BackupProblem.tooNew) => l10n.backupTooNew,
        _NoRoom(:final needed, :final free) => l10n.backupNoRoom(
          sizeText(needed, l10n),
          sizeText(free, l10n),
        ),
        _ => l10n.backupUnreadable,
      };

  /// Today as year-month-day, for the file name.
  static String _today() {
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${now.year}-${two(now.month)}-${two(now.day)}'; // l10n-ignore: a date
  }
}

/// Too little free space for a backup or a restore; nothing was written.
class _NoRoom implements Exception {
  const _NoRoom(this.needed, this.free);

  final int needed;
  final int free;
}

/// Before making a backup on a device with attachments: with or without
/// them (T7.2b, DD-007 point 7a), with their size; on by default. Pops the
/// choice, or null when cancelled.
class _BackupOptionsDialog extends StatefulWidget {
  const _BackupOptionsDialog({required this.attachmentBytes});

  final int attachmentBytes;

  @override
  State<_BackupOptionsDialog> createState() => _BackupOptionsDialogState();
}

class _BackupOptionsDialogState extends State<_BackupOptionsDialog> {
  bool _withAttachments = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.backupMake),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _withAttachments,
          title: Text(
            l10n.backupWithAttachments(sizeText(widget.attachmentBytes, l10n)),
          ),
          subtitle: Text(l10n.backupWithAttachmentsHint),
          onChanged: (value) => setState(() => _withAttachments = value),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.backupCancel),
        ),
        FilledButton(
          autofocus: true,
          onPressed: () => Navigator.of(context).pop(_withAttachments),
          child: Text(l10n.backupOptionsContinue),
        ),
      ],
    );
  }
}

/// Sets or changes the backup passphrase (AC REQ-026): typed twice, at
/// least [minPassphraseLength] characters, a strength indicator, and the
/// warning confirmed; on a change, older backups keep their passphrase.
class PassphraseDialog extends ConsumerStatefulWidget {
  const PassphraseDialog({super.key, required this.changing});

  final bool changing;

  @override
  ConsumerState<PassphraseDialog> createState() => _PassphraseDialogState();
}

class _PassphraseDialogState extends ConsumerState<PassphraseDialog> {
  final _first = TextEditingController();
  final _second = TextEditingController();
  bool _visible = false;
  bool _understood = false;
  bool _tried = false;

  @override
  void initState() {
    super.initState();
    _first.addListener(_changed);
    _second.addListener(_changed);
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    _first.dispose();
    _second.dispose();
    super.dispose();
  }

  String? _error(AppLocalizations l10n) {
    final problem = passphraseProblem(_first.text);
    if (problem == BackupProblem.passphraseInvalid) {
      return l10n.backupPassphraseInvalid;
    }
    if (_tried && problem == BackupProblem.passphraseTooShort) {
      return l10n.backupPassphraseTooShort(minPassphraseLength);
    }
    return null;
  }

  bool get _valid =>
      passphraseProblem(_first.text) == null &&
      _first.text == _second.text &&
      _understood;

  Future<void> _save() async {
    setState(() => _tried = true);
    if (!_valid) return;
    final navigator = Navigator.of(context);
    await ref.read(storageProvider).saveBackupPassphrase(_first.text);
    navigator.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final strength = passphraseStrength(_first.text);
    final mismatch = _second.text.isNotEmpty && _second.text != _first.text;
    return AlertDialog(
      title: Text(l10n.backupPassphraseTitle),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.backupPassphraseHint(minPassphraseLength)),
              const SizedBox(height: 16),
              TextField(
                controller: _first,
                autofocus: true,
                obscureText: !_visible,
                enableSuggestions: false,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: l10n.backupPassphraseField,
                  errorText: _error(l10n),
                  helperText: _first.text.isEmpty
                      ? null
                      : l10n.backupStrength(_strengthText(strength, l10n)),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    tooltip: l10n.backupPassphraseShow,
                    icon: Icon(
                      _visible ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () => setState(() => _visible = !_visible),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _second,
                obscureText: !_visible,
                enableSuggestions: false,
                autocorrect: false,
                onSubmitted: (_) => _save(),
                decoration: InputDecoration(
                  labelText: l10n.backupPassphraseRepeat,
                  errorText: mismatch ? l10n.backupPassphraseMismatch : null,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.backupPassphraseWarning,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (widget.changing) ...[
                const SizedBox(height: 8),
                Text(l10n.backupPassphraseChangeNote),
              ],
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _understood,
                title: Text(l10n.backupPassphraseWarningConfirm),
                onChanged: (value) =>
                    setState(() => _understood = value ?? false),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.backupCancel),
        ),
        FilledButton(
          onPressed: _valid ? _save : null,
          child: Text(l10n.backupSave),
        ),
      ],
    );
  }

  static String _strengthText(
    PassphraseStrength strength,
    AppLocalizations l10n,
  ) => switch (strength) {
    PassphraseStrength.tooShort => l10n.backupStrengthTooShort,
    PassphraseStrength.fair => l10n.backupStrengthFair,
    PassphraseStrength.good => l10n.backupStrengthGood,
    PassphraseStrength.strong => l10n.backupStrengthStrong,
  };
}

/// Asks the passphrase of a backup that this device's own does not open.
class _AskPassphraseDialog extends StatefulWidget {
  const _AskPassphraseDialog({required this.wrong});

  /// The previous try did not fit.
  final bool wrong;

  @override
  State<_AskPassphraseDialog> createState() => _AskPassphraseDialogState();
}

class _AskPassphraseDialogState extends State<_AskPassphraseDialog> {
  final _field = TextEditingController();
  bool _visible = false;

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  void _ok() {
    if (_field.text.isEmpty) return;
    Navigator.of(context).pop(_field.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.backupRestoreAskTitle),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.backupRestoreAskBody),
            const SizedBox(height: 16),
            TextField(
              controller: _field,
              autofocus: true,
              obscureText: !_visible,
              enableSuggestions: false,
              autocorrect: false,
              onSubmitted: (_) => _ok(),
              decoration: InputDecoration(
                labelText: l10n.backupPassphraseField,
                errorText: widget.wrong ? l10n.backupWrongPassphrase : null,
                errorMaxLines: 3,
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: l10n.backupPassphraseShow,
                  icon: Icon(
                    _visible ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () => setState(() => _visible = !_visible),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.backupCancel),
        ),
        FilledButton(onPressed: _ok, child: Text(l10n.backupRestoreAskOk)),
      ],
    );
  }
}
