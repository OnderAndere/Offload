import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/items/item_enums.dart';
import '../domain/settings/language_choice.dart';
import '../domain/time/local_date.dart';
import '../l10n/app_localizations.dart';
import '../platform/desktop_shell/desktop_shell.dart';
import 'capture/capture_screen.dart';
import 'capture/pending_captures.dart';
import 'help/help_scope.dart';
import 'home/home_shell.dart';
import 'inbox/inbox_card.dart';
import 'items/item_providers.dart';
import 'reminders/reminder_sync.dart';
import 'search/search_providers.dart';
import 'settings/app_locale.dart';
import 'settings/language_choice_provider.dart';
import 'startup/app_storage_provider.dart';
import 'startup/startup_screens.dart';
import 'theme/app_theme.dart';

/// Root widget of Offload.
///
/// Opens the encrypted storage first (T1.6); until then it shows a loading
/// screen, and an explanation if opening fails; then the destinations
/// (T2.6). The typeface and the meaning colours come from `theme/` (DD-017);
/// the rest of the theming (T8.1) is its own backlog item. Every user-visible string
/// comes from [AppLocalizations] (CLAUDE.md rule 3, DD-009).
class OffloadApp extends ConsumerWidget {
  const OffloadApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(appStorageProvider)
      .when(
        skipLoadingOnRefresh: false,
        data: (_) => const _StartedApp(key: ValueKey(_Phase.started)),
        loading: () => const _LocalizedApp(
          key: ValueKey(_Phase.loading),
          home: StartupLoadingScreen(),
        ),
        // Before the storage is open the stored language is unknown, so these
        // screens follow the system language.
        error: (error, _) => _LocalizedApp(
          key: const ValueKey(_Phase.error),
          home: StartupErrorScreen(
            error: error,
            onRetry: () => ref.invalidate(appStorageProvider),
          ),
        ),
      );
}

/// Start-up phases; each gets its own [MaterialApp], so the navigator starts
/// fresh with the right home screen.
enum _Phase { loading, error, started }

class _StartedApp extends ConsumerStatefulWidget {
  const _StartedApp({super.key});

  @override
  ConsumerState<_StartedApp> createState() => _StartedAppState();
}

class _StartedAppState extends ConsumerState<_StartedApp> {
  late final AppLifecycleListener _lifecycle;
  late final StreamSubscription<ItemSource> _captureRequests;
  final _navigator = GlobalKey<NavigatorState>();
  final _captureRoutes = CaptureRouteObserver();

  @override
  void initState() {
    super.initState();
    // Captures made outside the app (the Android widget) come in at start
    // and whenever the app comes back to the foreground (DD-010).
    // Parked items whose day came go back to the inbox at start, when the
    // app comes back to the front and at a change of day (DD-005): a
    // notification cannot write the encrypted database, so this is how
    // they return.
    _lifecycle = AppLifecycleListener(
      onResume: () {
        _fetchCaptures();
        _returnRevisited();
        // The minute clock may have slept with the app: Today shows the new
        // day at once, not up to a minute later.
        ref.invalidate(minuteClockProvider);
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchCaptures();
      _returnRevisited();
      unawaited(_tellRestoreUndone());
      unawaited(_removeOldPartialFiles());
    });
    // The search index follows every saved change, after saving (DD-016).
    ref.read(searchIndexingProvider);
    // The Windows hotkey and tray menu ask for the capture screen (REQ-017).
    _captureRequests = ref
        .read(captureChannelProvider)
        .captureRequests
        .listen(_openRequestedCapture);
  }

  void _fetchCaptures() =>
      unawaited(ref.read(pendingCapturesProvider.notifier).fetch());

  /// A failure leaves the items parked until the next try; nothing is lost.
  void _returnRevisited() => unawaited(
    ref
        .read(itemRepositoryProvider)
        .returnRevisited(LocalDate.of(DateTime.now()))
        .then((_) {}, onError: (Object _) {}),
  );

  /// Leftovers of older versions, once per device (DD-006): lists the whole
  /// attachments folder, so it waits until a capture asked for at start has
  /// closed (REQ-001); asynchronous, so a capture opened meanwhile is not
  /// held up. A failure tries again at the next start.
  Future<void> _removeOldPartialFiles() async {
    if (_captureRoutes.captureOpen) await _captureRoutes.whenClosed();
    try {
      await ref.read(storageProvider).removeOldPartialFiles();
    } catch (_) {
      // Next start.
    }
  }

  /// A restored backup that did not open: the previous data came back at
  /// start (`AppStorage.open`); said once, as the restore the user confirmed
  /// did not happen (T7.2 follow-up, DD-007).
  Future<void> _tellRestoreUndone() async {
    if (!ref.read(storageProvider).restoreUndone) return;
    // A capture asked for at start comes first (REQ-001): told after it.
    if (_captureRoutes.captureOpen) await _captureRoutes.whenClosed();
    final context = _navigator.currentContext;
    if (context == null || !context.mounted) return;
    unawaited(
      showDialog<void>(
        context: context,
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          return AlertDialog(
            title: Text(l10n.restoreUndoneTitle),
            content: Text(l10n.restoreUndoneBody),
            actions: [
              FilledButton(
                autofocus: true,
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.restoreUndoneOk),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Opens the capture screen for a request from outside the window; when
  /// it closes, the platform puts back what was in front before.
  ///
  /// A capture screen that is already open (from the in-app button or an
  /// earlier request) is used as it is: the platform already brought the
  /// window forward, and a second screen would hide the text in the first.
  /// The request counts as handled when that screen closes.
  Future<void> _openRequestedCapture(ItemSource source) async {
    final navigator = _navigator.currentState;
    try {
      if (_captureRoutes.captureOpen) {
        await _captureRoutes.whenClosed();
      } else if (navigator != null) {
        await navigator.push(CaptureScreen.route(source: source));
      }
    } finally {
      final channel = ref.read(captureChannelProvider);
      unawaited(channel.captureRequestHandled().catchError((Object _) {}));
    }
  }

  @override
  void dispose() {
    unawaited(_captureRequests.cancel());
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // A new day while the app runs: what was parked until today returns.
    ref.listen(
      minuteClockProvider.select(
        (now) =>
            now.valueOrNull == null ? null : LocalDate.of(now.valueOrNull!),
      ),
      (before, day) {
        if (before != null && day != null && day != before) {
          _returnRevisited();
        }
      },
    );
    return _LocalizedApp(
      locale: fixedAppLocale(ref.watch(languageChoiceProvider)),
      navigatorKey: _navigator,
      navigatorObservers: [_captureRoutes],
      builder: (context, child) => _TrayTexts(
        child: HelpKey(
          navigatorKey: _navigator,
          child: ReminderSync(navigatorKey: _navigator, child: child!),
        ),
      ),
      home: const HomeShell(),
    );
  }
}

/// Hands the tray texts to the platform in the active language, again
/// whenever the language changes (DD-009).
class _TrayTexts extends ConsumerStatefulWidget {
  const _TrayTexts({required this.child});

  final Widget child;

  @override
  ConsumerState<_TrayTexts> createState() => _TrayTextsState();
}

class _TrayTextsState extends ConsumerState<_TrayTexts> {
  Locale? _sentFor;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context);
    if (locale == _sentFor) return;
    _sentFor = locale;
    final l10n = AppLocalizations.of(context);
    unawaited(
      ref
          .read(desktopShellProvider)
          .setTrayTexts(
            TrayTexts(
              tooltip: l10n.appTitle,
              newItem: l10n.trayNewItem,
              open: l10n.trayOpen,
              quit: l10n.trayQuit,
            ),
          )
          .catchError((Object _) {}),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _LocalizedApp extends StatelessWidget {
  const _LocalizedApp({
    super.key,
    this.locale,
    this.navigatorKey,
    this.navigatorObservers = const [],
    this.builder,
    required this.home,
  });

  final Locale? locale;
  final GlobalKey<NavigatorState>? navigatorKey;
  final List<NavigatorObserver> navigatorObservers;
  final TransitionBuilder? builder;
  final Widget home;

  @override
  Widget build(BuildContext context) => MaterialApp(
    navigatorKey: navigatorKey,
    navigatorObservers: navigatorObservers,
    builder: builder,
    onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
    // An offered fixed choice sets the locale; "system" (and a choice that
    // is not offered) leaves it to the callback below, which Flutter calls
    // again whenever the device language changes.
    locale: locale,
    localeListResolutionCallback: (systemLocales, _) =>
        resolveAppLocale(const LanguageChoice.system(), systemLocales ?? []),
    supportedLocales: AppLocalizations.supportedLocales,
    theme: offloadTheme(),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: home,
  );
}
