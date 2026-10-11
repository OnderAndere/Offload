import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/storage/storage_counts.dart';
import '../../domain/attachments/attachment.dart';
import '../../domain/storage/storage_use.dart';
import '../../l10n/app_localizations.dart';
import '../../platform/app_directory/app_directory.dart';
import '../../platform/app_directory/platform_app_directory.dart';
import '../startup/app_storage_provider.dart';

/// Where Offload keeps its files on this device.
final appDirectoryProvider = Provider<AppDirectory>(
  (ref) => createPlatformAppDirectory(),
);

/// What Offload keeps on this device, worked out each time Settings opens
/// (T7.5, PO 09-10-2026: not in the background).
final storageUseProvider = FutureProvider.autoDispose<StorageUse>((ref) async {
  final storage = ref.watch(storageProvider);
  final counts = await readStorageCounts(storage.database);
  int? temporary;
  var unknown = false;
  try {
    temporary = await ref.watch(appDirectoryProvider).temporaryFilesSize();
  } catch (_) {
    unknown = true;
  }
  return StorageUse(
    databaseBytes: storage.databaseBytes(),
    temporaryBytes: temporary,
    temporaryUnknown: unknown,
    items: counts.items,
    trashedItems: counts.trashedItems,
    projects: counts.projects,
    people: counts.people,
    attachmentBytes: counts.attachmentBytes,
  );
});

/// Settings → Storage (*Opslag*; T7.5, DD-006; PO 09-10-2026): the
/// database, the temporary copies (Android) and how much is in it, the
/// trash included.
/// No button to clear anything: the copies go by themselves (PO). The
/// attachments show per kind once there are any (T5.1); the speech model
/// joins with T6.1.
class StorageSection extends ConsumerWidget {
  const StorageSection({super.key, required this.headerStyle});

  final TextStyle? headerStyle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final use = ref.watch(storageUseProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(title: Text(l10n.settingsStorageHeader, style: headerStyle)),
        ...switch (use) {
          AsyncData(:final value) => _rows(value, l10n),
          AsyncError() => [ListTile(title: Text(l10n.storageUnavailable))],
          _ => const [LinearProgressIndicator()],
        },
      ],
    );
  }

  static List<Widget> _rows(StorageUse use, AppLocalizations l10n) {
    final items = l10n.storageItems(use.items);
    final withTrash = use.trashedItems == 0
        ? items
        : l10n.storageWithTrash(items, l10n.storageTrashed(use.trashedItems));
    final content = l10n.storageJoin(
      l10n.storageJoin(withTrash, l10n.storageProjects(use.projects)),
      l10n.storagePeople(use.people),
    );
    return [
      ListTile(
        leading: const Icon(Icons.storage_outlined),
        title: Text(l10n.storageDatabase),
        subtitle: Text(l10n.storageDatabaseHint),
        trailing: Text(sizeText(use.databaseBytes, l10n)),
      ),
      if (use.temporaryBytes != null || use.temporaryUnknown)
        ListTile(
          leading: const Icon(Icons.hourglass_empty),
          title: Text(l10n.storageTemporary),
          subtitle: Text(l10n.storageTemporaryHint),
          trailing: Text(switch (use.temporaryBytes) {
            final bytes? => sizeText(bytes, l10n),
            null => l10n.storageUnavailable,
          }),
        ),
      if (use.attachmentBytes.isNotEmpty)
        ListTile(
          leading: const Icon(Icons.attach_file),
          title: Text(l10n.storageAttachments),
          subtitle: Text(
            [
              for (final kind in AttachmentKind.values)
                if (use.attachmentBytes[kind] case final bytes?)
                  l10n.storageAttachmentKind(kind.name, sizeText(bytes, l10n)),
            ].reduce(l10n.storageJoin),
          ),
          trailing: Text(
            sizeText(
              use.attachmentBytes.values.fold(0, (sum, bytes) => sum + bytes),
              l10n,
            ),
          ),
        ),
      ListTile(
        leading: const Icon(Icons.inventory_2_outlined),
        title: Text(l10n.storageContent),
        subtitle: Text(content),
      ),
    ];
  }
}

/// [bytes] as the screens show it: kB, MB or GB (decimal, as Android).
String sizeText(int bytes, AppLocalizations l10n) {
  final amount = byteAmount(bytes);
  return switch (amount.unit) {
    ByteUnit.kilobytes => l10n.storageKilobytes(amount.value),
    ByteUnit.megabytes => l10n.storageMegabytes(amount.value),
    ByteUnit.gigabytes => l10n.storageGigabytes(amount.value),
  };
}
