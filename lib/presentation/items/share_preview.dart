import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/items/item_share_text.dart';
import '../../domain/time/local_date.dart';
import '../../l10n/app_localizations.dart';
import '../../platform/share/share_channel.dart';
import '../messages.dart';
import '../share_channel_provider.dart';
import '../tokens/token_display.dart';

/// The share preview of an item's text [rawText] (REQ-043, DD-014): the
/// text as it will go out, editable, with a switch for the tags. Only what
/// is in the field is sent; editing it never changes the item. A date word
/// takes its date from [knownDates] (the stored tokens), as in the detail.
Future<void> showSharePreview(
  BuildContext context, {
  required String rawText,
  Map<String, LocalDate> knownDates = const {},
}) => showDialog<void>(
  context: context,
  builder: (_) => SharePreview(rawText: rawText, knownDates: knownDates),
);

class SharePreview extends ConsumerStatefulWidget {
  const SharePreview({
    super.key,
    required this.rawText,
    this.knownDates = const {},
  });

  final String rawText;
  final Map<String, LocalDate> knownDates;

  @override
  ConsumerState<SharePreview> createState() => _SharePreviewState();
}

class _SharePreviewState extends ConsumerState<SharePreview> {
  final _text = TextEditingController();
  bool _includeTags = false;

  /// The raw text with its tokens, for Offload elsewhere (T2.7a).
  bool _asTyped = false;
  bool _rendered = false;
  bool _busy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_rendered) {
      _rendered = true;
      _text.text = _render();
      // The buttons follow whether there is text.
      _text.addListener(_changed);
    }
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  /// The proposal for the field. Switching the tags or "as typed" makes a
  /// new proposal, which replaces what was edited so far.
  String _render() {
    final l10n = AppLocalizations.of(context);
    final today = todayOnDevice();
    final renderer = ItemShareRenderer(
      registry: ref.read(inlineTokenRegistryProvider),
      formatDate: (date) => date.year == today.year
          ? l10n.itemShareDate(date.toLocalDateTime())
          : l10n.itemShareDateWithYear(date.toLocalDateTime()),
    );
    if (_asTyped) {
      return renderer.renderAsTyped(
        widget.rawText,
        context: parseContextOf(l10n, today),
        knownDates: widget.knownDates,
      );
    }
    return renderer.render(
      widget.rawText,
      context: parseContextOf(l10n, today),
      knownDates: widget.knownDates,
      includeTags: _includeTags,
    );
  }

  Future<void> _share(ShareTarget target) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final text = _text.text;
    setState(() => _busy = true);
    final ShareResult result;
    try {
      result = await ref
          .read(shareChannelProvider)
          .shareText(
            text,
            target: target,
            subject: shareSubject(text),
            fileTypeName: l10n.itemShareFileType,
          );
    } on ShareChannelException {
      if (mounted) setState(() => _busy = false);
      showMessage(messenger, SnackBar(content: Text(l10n.itemShareFailed)));
      return;
    }
    if (result == ShareResult.cancelled) {
      // The save window was closed: the preview stays, as it was.
      if (mounted) setState(() => _busy = false);
      return;
    }
    if (mounted) navigator.pop();
    final done = switch (target) {
      ShareTarget.clipboard => l10n.itemShareCopied,
      ShareTarget.file => l10n.itemShareSaved,
      // The share menu shows itself what happens.
      ShareTarget.system => null,
    };
    if (done != null) showMessage(messenger, SnackBar(content: Text(done)));
  }

  String _label(ShareTarget target, AppLocalizations l10n) => switch (target) {
    ShareTarget.system => l10n.itemShare,
    ShareTarget.clipboard => l10n.itemShareCopy,
    ShareTarget.file => l10n.itemShareSaveAs,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final targets = ref.watch(shareChannelProvider).textTargets;
    final canShare = !_busy && _text.text.trim().isNotEmpty;
    return AlertDialog(
      title: Text(l10n.itemShareTitle),
      scrollable: true,
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.itemShareAsTyped),
              subtitle: Text(l10n.itemShareAsTypedHint),
              value: _asTyped,
              onChanged: _busy
                  ? null
                  : (value) {
                      setState(() => _asTyped = value);
                      _text.text = _render();
                    },
            ),
            // As typed, the tags always go along (PO 09-10-2026).
            if (!_asTyped)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.itemShareIncludeTags),
                value: _includeTags,
                onChanged: _busy
                    ? null
                    : (value) {
                        setState(() => _includeTags = value);
                        _text.text = _render();
                      },
              ),
            const SizedBox(height: 8),
            TextField(
              controller: _text,
              minLines: 4,
              maxLines: 12,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                helperText: l10n.itemShareHelper,
                helperMaxLines: 3,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.itemShareCancel),
        ),
        for (final (index, target) in targets.indexed)
          index == 0
              ? FilledButton(
                  onPressed: canShare ? () => _share(target) : null,
                  child: Text(_label(target, l10n)),
                )
              : OutlinedButton(
                  onPressed: canShare ? () => _share(target) : null,
                  child: Text(_label(target, l10n)),
                ),
      ],
    );
  }
}
