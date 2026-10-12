import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/attachments/photo_compressor.dart';
import '../../data/handwriting/reading_image_preparer.dart';
import '../../domain/handwriting/reading_clean_up.dart';
import '../../domain/handwriting/reading_clock.dart';
import '../../domain/handwriting/reading_policy.dart';
import '../../domain/handwriting/straightening.dart';
import '../../domain/help/help_topics.dart';
import '../../l10n/app_localizations.dart';
import '../../platform/handwriting/handwriting_reader.dart';
import '../../platform/photo_source/photo_source.dart';
import '../../platform/screen_awake/screen_awake.dart';
import '../help/help_scope.dart';
import '../messages.dart';
import '../models/model_providers.dart';
import '../photos/photo_providers.dart';
import '../photos/photo_source_sheet.dart';
import 'corners_editor.dart';
import 'handwriting_providers.dart';

/// Reads handwriting from a photo (REQ-064, T6a.4): takes or chooses a
/// photo, then the photo screen. The cleaned-up text, or null when the user
/// stopped somewhere or nothing was read. A failure to get the photo is a
/// message. Only with [model] (`handwritingModelProvider`).
Future<String?> readHandwriting(
  BuildContext context,
  WidgetRef ref,
  HandwritingModel model,
) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);
  final source = ref.read(photoSourceProvider);
  var take = false;
  if (source.canTakePhoto) {
    final choice = await choosePhotoSource(
      context,
      title: l10n.handwritingTitle,
    );
    if (choice == null) return null;
    take = choice;
  }
  final Uint8List? bytes;
  try {
    bytes = take
        ? await source.takePhoto()
        : await source.pickPhoto(fileTypeName: l10n.photoFileTypeName);
  } on PhotoSourceException catch (e) {
    showMessage(
      messenger,
      SnackBar(
        content: Text(
          e.failure == PhotoSourceFailure.tooLarge
              ? l10n.photoTooLarge
              : l10n.photoSourceFailed,
        ),
      ),
    );
    return null;
  }
  if (bytes == null) return null;
  return navigator.push(
    MaterialPageRoute<String>(
      builder: (_) => HandwritingScreen(photo: bytes!, model: model),
    ),
  );
}

/// The photo screen (T6a.4, DD-021): four corners to straighten the photo,
/// optionally, then reading with progress and a stop button. Closes with
/// the text read, cleaned up (DD-021). After *Stop* or a failure it goes back
/// to the corners with the same photo (PO 12-10-2026). The photo and every
/// copy of it live only in memory and go with the screen (AC REQ-064 d).
class HandwritingScreen extends ConsumerStatefulWidget {
  const HandwritingScreen({
    super.key,
    required this.photo,
    required this.model,
    this.policy = ReadingPolicy.standard,
  });

  /// The picture's bytes as the camera or the picker gave them.
  final Uint8List photo;
  final HandwritingModel model;
  final ReadingPolicy policy;

  @override
  ConsumerState<HandwritingScreen> createState() => _HandwritingScreenState();
}

enum _Stage { opening, corners, reading }

class _HandwritingScreenState extends ConsumerState<HandwritingScreen>
    with WidgetsBindingObserver {
  _Stage _stage = _Stage.opening;
  WorkingPhoto? _photo;
  Corners _corners = Corners.whole;

  /// Why the last reading gave no text, shown at the corners.
  String? _message;

  ReadingProgress? _progress;
  ReadingCancel? _cancel;
  bool _stopping = false;
  bool _timedOut = false;
  ReadingClock? _clock;
  Timer? _ticker;
  Duration _elapsed = Duration.zero;
  bool _pausesOutsideApp = true;

  /// Read at the start: [dispose] still needs it.
  late final ScreenAwake _awake;

  @override
  void initState() {
    super.initState();
    _awake = ref.read(screenAwakeProvider);
    WidgetsBinding.instance.addObserver(this);
    unawaited(_open());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    if (_cancel != null) {
      // Closed while reading: the reading stops, the device may sleep.
      _cancel!.cancel();
      _keepAwake(false);
    }
    _photo?.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    try {
      final photo = await ref
          .read(readingImagePreparerProvider)
          .open(widget.photo);
      if (!mounted) {
        photo.dispose();
        return;
      }
      setState(() {
        _photo = photo;
        _stage = _Stage.corners;
      });
    } on PhotoFormatException {
      if (!mounted) return;
      showMessage(
        ScaffoldMessenger.of(context),
        SnackBar(content: Text(AppLocalizations.of(context).photoUnreadable)),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final clock = _clock;
    if (clock == null || !_pausesOutsideApp) return;
    // Android freezes the app soon after it is left; the time outside does
    // not count (PO 12-10-2026). Inactive (a shade over the app) still runs.
    switch (state) {
      case AppLifecycleState.resumed || AppLifecycleState.inactive:
        clock.run();
      case AppLifecycleState.hidden ||
          AppLifecycleState.paused ||
          AppLifecycleState.detached:
        clock.pause();
    }
  }

  void _keepAwake(bool on) =>
      unawaited(_awake.keepAwake(on).catchError((Object _) {}));

  Future<void> _read() async {
    final photo = _photo;
    if (photo == null || _stage != _Stage.corners) return;
    if (!_corners.isWhole && !_corners.isUsable(photo.width, photo.height)) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final reader = ref.read(handwritingReaderProvider);
    final cancel = ReadingCancel();
    final clock = ReadingClock(ref.read(readingTimeSourceProvider))..run();
    _pausesOutsideApp = reader.pausesOutsideApp;
    setState(() {
      _stage = _Stage.reading;
      _message = null;
      _progress = null;
      _stopping = false;
      _timedOut = false;
      _elapsed = Duration.zero;
      _cancel = cancel;
      _clock = clock;
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _keepAwake(true);

    String? text;
    String? message;
    try {
      final image = await ref
          .read(readingImagePreparerProvider)
          .prepare(photo, _corners);
      final speed = await ref.read(readingSpeedProvider.future);
      if (cancel.isCancelled) {
        throw const HandwritingReaderException(HandwritingFailure.cancelled);
      }
      final reading = await reader.read(
        model: widget.model,
        image: image,
        speed: speed,
        policy: widget.policy,
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
        cancel: cancel,
      );
      text = cleanUpReading(reading.text);
      if (text.isEmpty) message = l10n.handwritingNothingFound;
    } on HandwritingReaderException catch (e) {
      message = switch (e.failure) {
        HandwritingFailure.cancelled =>
          _timedOut
              ? l10n.handwritingTooLong(widget.policy.maxReadingTime.inMinutes)
              : null,
        HandwritingFailure.outOfMemory => l10n.handwritingOutOfMemory,
        HandwritingFailure.modelUnreadable ||
        HandwritingFailure.unavailable => l10n.handwritingModelUnreadable,
        HandwritingFailure.badImage => l10n.photoUnreadable,
        HandwritingFailure.failed => l10n.handwritingFailed,
      };
    } catch (_) {
      message = l10n.handwritingFailed;
    } finally {
      _ticker?.cancel();
      _ticker = null;
      _clock = null;
      // Once closed, dispose has let the device sleep already.
      if (mounted) _keepAwake(false);
    }
    if (!mounted) return;
    _cancel = null;
    if (text != null && text.isNotEmpty) {
      Navigator.of(context).pop(text);
      return;
    }
    setState(() {
      _stage = _Stage.corners;
      _message = message;
    });
  }

  void _tick() {
    final clock = _clock;
    if (clock == null || !mounted) return;
    setState(() => _elapsed = clock.elapsed);
    if (_elapsed >= widget.policy.maxReadingTime && !_stopping) {
      _timedOut = true;
      _stop();
    }
  }

  void _stop() {
    final cancel = _cancel;
    if (cancel == null || _stopping) return;
    cancel.cancel();
    setState(() => _stopping = true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final reading = _stage == _Stage.reading;
    // The manual explains the photo screen under capturing (T6a.4).
    return HelpScope(
      topic: HelpTopic.capture,
      child: PopScope(
        // Back while reading stops it first; the next back closes.
        canPop: !reading,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _stop();
        },
        child: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.escape): () =>
                Navigator.of(context).maybePop(),
          },
          child: Focus(
            autofocus: true,
            child: Scaffold(
              appBar: AppBar(
                title: Text(l10n.handwritingTitle),
                actions: const [HelpButton()],
              ),
              body: SafeArea(
                child: switch (_stage) {
                  _Stage.opening => _Busy(text: l10n.handwritingOpening),
                  _Stage.corners => _cornersStage(context, _photo!),
                  _Stage.reading => _readingStage(context),
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _cornersStage(BuildContext context, WorkingPhoto photo) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final usable =
        _corners.isWhole || _corners.isUsable(photo.width, photo.height);
    final message = _message;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: CornersEditor(
            image: photo.image,
            corners: _corners,
            usable: usable,
            onChanged: (corners) => setState(() {
              _corners = corners;
              _message = null;
            }),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(
            message ??
                (usable
                    ? l10n.handwritingCornersHint
                    : l10n.handwritingCornersCrossed),
            style: message != null || !usable
                ? theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  )
                : theme.textTheme.bodyMedium,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              TextButton(
                onPressed: _corners.isWhole
                    ? null
                    : () => setState(() {
                        _corners = Corners.whole;
                        _message = null;
                      }),
                child: Text(l10n.handwritingResetCorners),
              ),
              FilledButton.icon(
                onPressed: usable ? () => unawaited(_read()) : null,
                icon: const Icon(Icons.document_scanner_outlined),
                label: Text(l10n.handwritingRead),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _readingStage(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final phase = switch (_progress?.phase) {
      null || ReadingPhase.loading => l10n.handwritingPhaseLoading,
      ReadingPhase.encoding => l10n.handwritingPhaseEncoding,
      ReadingPhase.writing => l10n.handwritingPhaseWriting,
    };
    final seconds = _elapsed.inSeconds;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _pausesOutsideApp
                    ? l10n.handwritingWait
                    : l10n.handwritingWaitDesktop,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              const LinearProgressIndicator(),
              const SizedBox(height: 12),
              Text(
                _stopping ? l10n.handwritingStopping : phase,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.handwritingElapsed(
                  (seconds ~/ 60).toString(),
                  (seconds % 60).toString().padLeft(2, '0'),
                ),
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: _stopping ? null : _stop,
                  child: Text(l10n.handwritingStop),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A spinner with a line of text.
class _Busy extends StatelessWidget {
  const _Busy({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text(text),
      ],
    ),
  );
}
