import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/help/help_topics.dart';
import '../../domain/items/item.dart';
import '../../l10n/app_localizations.dart';
import '../capture/pending_captures.dart';
import '../help/help_scope.dart';
import '../home/destination_actions.dart';
import '../home/list_keys.dart';
import '../items/item_providers.dart';
import '../items/swipe_backgrounds.dart';
import '../items/trash_undo.dart';
import '../tokens/token_editor.dart';
import '../triage/triage_screen.dart';
import 'inbox_card.dart';

/// The Inbox destination (DD-011): the live inbox, newest first, one card
/// per item (T2.8, DD-018 point 2). Capturing is the shell's button.
class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return HelpScope(
      topic: HelpTopic.inbox,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.inboxTitle),
          actions: [...destinationActions(context), const HelpButton()],
        ),
        body: Column(
          children: [
            const _CaptureNotices(),
            Expanded(
              child: ref
                  .watch(inboxProvider)
                  .when(
                    data: (items) => _InboxList(items: items),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          l10n.inboxLoadFailed,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Notes about captures from outside the app (AC REQ-001): unreadable ones
/// that were set aside, and a fetch that failed. Nothing is ever lost
/// silently.
class _CaptureNotices extends ConsumerWidget {
  const _CaptureNotices();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final notice = ref.watch(pendingCapturesProvider);
    final hotkeyTaken =
        ref.watch(hotkeyRegisteredProvider).valueOrNull == false &&
        !ref.watch(hotkeyNoticeDismissedProvider);
    return Column(
      children: [
        if (hotkeyTaken)
          _Notice(
            text: l10n.hotkeyUnavailable,
            onDismiss: () =>
                ref.read(hotkeyNoticeDismissedProvider.notifier).state = true,
          ),
        if (notice.unreadable > 0)
          _Notice(
            text: l10n.captureUnreadable(notice.unreadable),
            onDismiss: ref
                .read(pendingCapturesProvider.notifier)
                .dismissUnreadable,
          ),
        if (notice.failed) _Notice(text: l10n.captureFetchFailed),
      ],
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text, this.onDismiss});

  final String text;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      color: colors.errorContainer,
      child: ListTile(
        leading: Icon(Icons.warning_amber, color: colors.onErrorContainer),
        title: Text(text, style: TextStyle(color: colors.onErrorContainer)),
        trailing: onDismiss == null
            ? null
            : IconButton(
                icon: Icon(Icons.close, color: colors.onErrorContainer),
                tooltip: l10n.noticeDismiss,
                onPressed: onDismiss,
              ),
      ),
    );
  }
}

class _InboxList extends ConsumerStatefulWidget {
  const _InboxList({required this.items});

  final List<Item> items;

  @override
  ConsumerState<_InboxList> createState() => _InboxListState();
}

class _InboxListState extends ConsumerState<_InboxList> {
  /// Cards swiped away whose move to the trash the list has not caught up
  /// with yet: a dismissed card may not come back for a frame.
  final _gone = <String>{};

  @override
  void didUpdateWidget(_InboxList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Once the list itself no longer has an item, it need not be hidden;
    // if it comes back later (a restore from elsewhere), it shows again.
    final ids = {for (final item in widget.items) item.id};
    _gone.retainWhere(ids.contains);
  }

  /// To the trash with undo (AC REQ-010, Q26): by swiping a card left on a
  /// phone, or by the screen reader's action on any platform.
  Future<void> _trash(String id) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    setState(() => _gone.add(id));
    final trashed = await trashWithUndo(
      messenger: messenger,
      l10n: l10n,
      items: ref.read(itemRepositoryProvider),
      id: id,
      onUndo: () {
        if (mounted) setState(() => _gone.remove(id));
      },
    );
    if (!trashed && mounted) setState(() => _gone.remove(id));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final items = [
      for (final item in widget.items)
        if (!_gone.contains(item.id)) item,
    ];
    // Processed items are in Projects, under their project or *Without
    // project* (DD-018 point 6); the temporary switch of T2.3 is gone.
    final header = items.isEmpty
        // An empty list says so in the middle; not twice.
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                l10n.inboxItemCount(items.length),
                style: textTheme.titleSmall,
              ),
            ),
          );
    // Triage (T2.4, DD-018 point 3) goes through the inbox itself.
    final inbox = widget.items;
    final start = inbox.isEmpty
        ? null
        : Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: FilledButton.tonalIcon(
                icon: const Icon(Icons.style_outlined),
                label: Text(l10n.inboxTriage(inbox.length)),
                onPressed: () => TriageScreen.open(context, [
                  for (final item in inbox) item.id,
                ]),
              ),
            ),
          );
    if (items.isEmpty) {
      return Column(
        children: [
          header,
          Expanded(
            child: Center(
              child: Text(l10n.inboxItemCount(0), style: textTheme.bodyLarge),
            ),
          ),
        ],
      );
    }
    final now = ref.watch(minuteClockProvider).valueOrNull ?? DateTime.now();
    final tokens = ref.watch(liveItemTokensProvider).valueOrNull ?? const {};
    // Swiping is for touch (DD-018 point 2); on Windows Del follows with
    // the list pane (T2.6).
    final swipe = !isDesktop(context);
    return ListKeys(
      ids: [for (final item in items) item.id],
      onTrash: _trash,
      child: ListView.builder(
        // Room at the bottom so the capture button never hides the last item.
        padding: const EdgeInsets.only(bottom: 96),
        itemCount: items.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(children: [header, ?start]);
          }
          final item = items[index - 1];
          final card = KeyedSubtree(
            key: ListKeys.cardKey(item.id),
            child: Semantics(
              customSemanticsActions: {
                CustomSemanticsAction(label: l10n.itemMoveToTrash): () =>
                    _trash(item.id),
              },
              child: InboxCard(
                item: item,
                tokens: tokens[item.id] ?? const [],
                now: now,
                showStatus: false,
              ),
            ),
          );
          if (!swipe) return card;
          return Dismissible(
            key: ValueKey(item.id),
            direction: DismissDirection.endToStart,
            background: SwipeToTrash(label: l10n.itemMoveToTrash),
            onDismissed: (_) => _trash(item.id),
            child: card,
          );
        },
      ),
    );
  }
}
