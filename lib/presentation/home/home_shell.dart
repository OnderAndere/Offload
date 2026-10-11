import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/connections/connection_graph.dart';
import '../../domain/items/item_headline.dart';
import '../../domain/snapshots/snapshot.dart';
import '../../domain/time/local_date.dart';
import '../../l10n/app_localizations.dart';
import '../capture/capture_screen.dart';
import '../inbox/inbox_screen.dart';
import '../items/item_detail_screen.dart';
import '../items/item_providers.dart';
import '../overview/connections_providers.dart';
import '../overview/insights_screen.dart';
import '../people/people_providers.dart';
import '../people/people_screen.dart';
import '../people/person_screen.dart';
import '../projects/project_providers.dart';
import '../projects/project_screen.dart';
import '../projects/projects_screen.dart';
import '../review/review_providers.dart';
import '../review/weekly_review_screen.dart';
import '../search/search_screen.dart';
import '../settings/settings_screen.dart';
import '../snapshots/where_was_i.dart';
import '../theme/offload_colors.dart';
import '../today/today_screen.dart';
import '../tokens/token_display.dart';
import '../tokens/token_editor.dart';
import '../triage/triage_screen.dart';
import 'destination.dart';
import 'item_panes.dart';

/// The frame around the destinations (T2.6, DD-018 point 5): on a phone a
/// bottom bar and the capture button; on Windows a rail with the capture
/// button at the top and Settings at its foot. Five destinations, the
/// Overview (NL "Inzicht") the fifth (DD-018 point 12).
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final destination = ref.watch(destinationProvider);
    final inboxCount = ref.watch(inboxProvider).valueOrNull?.length ?? 0;
    void select(int index) {
      // A destination opens on its start: Projects on the project list,
      // People on the people list.
      ref.read(openProjectProvider.notifier).state = null;
      ref.read(openPersonProvider.notifier).state = null;
      ref.read(destinationProvider.notifier).state = Destination.values[index];
    }

    final body = destinationBody(destination);
    final inboxIcon = Semantics(
      label: l10n.navInboxBadge(inboxCount),
      excludeSemantics: true,
      // Calm blue, not the default red: an inbox count needs no alarm
      // (DD-017).
      child: Badge.count(
        count: inboxCount,
        isLabelVisible: inboxCount > 0,
        backgroundColor: context.offloadColors.calm,
        // White on a meaning colour: check the contrast again with the
        // dark variant (T8.1).
        textColor: Colors.white,
        child: const Icon(Icons.inbox_outlined),
      ),
    );

    if (isDesktop(context)) return _DesktopShell(inboxIcon: inboxIcon);

    final projectOpen = ref.watch(openProjectProvider) != null;
    final personOpen = ref.watch(openPersonProvider) != null;
    final earlierFocus =
        destination == Destination.insights &&
        ref.watch(insightsSegmentProvider) == InsightsSegment.connections &&
        ref.watch(connectionsProvider.select((s) => s.history.isNotEmpty));
    return PopScope(
      // Back closes an open project or person first, in Connections it
      // goes to the previous focus (DD-018 point 15), then from another
      // destination to Today; from Today it leaves.
      canPop: destination == Destination.today,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (destination == Destination.projects && projectOpen) {
          ref.read(openProjectProvider.notifier).state = null;
        } else if (destination == Destination.people && personOpen) {
          ref.read(openPersonProvider.notifier).state = null;
        } else if (earlierFocus) {
          ref.read(connectionsProvider.notifier).back();
        } else {
          select(Destination.today.index);
        }
      },
      child: Scaffold(
        body: body,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => CaptureScreen.open(context),
          icon: const Icon(Icons.add),
          label: Text(l10n.captureAction),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: destination.index,
          onDestinationSelected: select,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.wb_sunny_outlined),
              selectedIcon: const Icon(Icons.wb_sunny),
              label: l10n.navToday,
            ),
            NavigationDestination(icon: inboxIcon, label: l10n.inboxTitle),
            NavigationDestination(
              icon: const Icon(Icons.folder_outlined),
              selectedIcon: const Icon(Icons.folder),
              label: l10n.navProjects,
            ),
            NavigationDestination(
              icon: const Icon(Icons.people_outline),
              selectedIcon: const Icon(Icons.people),
              label: l10n.navPeople,
            ),
            NavigationDestination(
              icon: const Icon(Icons.insights_outlined),
              selectedIcon: const Icon(Icons.insights),
              label: l10n.navInsights,
            ),
          ],
        ),
      ),
    );
  }
}

/// The screen of [destination] in the list (pane).
Widget destinationBody(Destination destination) => switch (destination) {
  Destination.today => const TodayScreen(),
  Destination.inbox => const InboxScreen(),
  Destination.projects => const ProjectsScreen(),
  Destination.people => const PeopleScreen(),
  Destination.insights => const InsightsScreen(),
};

/// Windows (DD-018 point 5): the rail, and beside it a navigator of its own
/// for the destination, so the rail stays while triage or, in a narrow
/// window, an item is open. From [twoPaneMinWidth] the list and the item
/// detail are two panes; a search field sits above the list. Ctrl+1 to 5
/// switch destination, Ctrl+N captures and Ctrl+F searches, also in a text
/// field; during triage Ctrl+1 to 4 and Ctrl+F do nothing (PO decision
/// 29-09-2026).
class _DesktopShell extends ConsumerStatefulWidget {
  const _DesktopShell({required this.inboxIcon});

  final Widget inboxIcon;

  @override
  ConsumerState<_DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends ConsumerState<_DesktopShell> {
  final _content = GlobalKey<NavigatorState>();
  final _triage = _TriageObserver();
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  final _listFocus = FocusNode();

  /// The list keys of a person in the right pane (DD-018 point 11): not
  /// the list pane's own, which keeps its focus node.
  final _personFocus = FocusNode();
  final _detailFocusRequests = ValueNotifier(0);
  final _width = _PaneWidth();

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    _listFocus.dispose();
    _personFocus.dispose();
    _detailFocusRequests.dispose();
    super.dispose();
  }

  /// Goes to [destination]: what is open over the list closes first (the
  /// detail in a narrow window, triage when the rail is clicked). The keys
  /// leave triage alone.
  void _go(Destination destination, {bool byKey = false}) {
    if (byKey && (_triage.open || ref.read(weeklyReviewOpenProvider))) return;
    // The rail ends the weekly review, as it ends triage (DD-018 point 8).
    ref.read(weeklyReviewOpenProvider.notifier).state = false;
    ref.read(weeklyReviewWideProvider.notifier).state = false;
    _content.currentState?.popUntil((route) => route.isFirst);
    // A destination opens on its start: Projects on the project list,
    // People on the people list.
    ref.read(openProjectProvider.notifier).state = null;
    ref.read(openPersonProvider.notifier).state = null;
    if (ref.read(destinationProvider) == destination) return;
    ref.read(selectedItemProvider.notifier).state = null;
    _search.clear();
    ref.read(destinationProvider.notifier).state = destination;
  }

  void _focusSearch() {
    if (_triage.open || ref.read(weeklyReviewOpenProvider)) return;
    _content.currentState?.popUntil((route) => route.isFirst);
    _searchFocus.requestFocus();
    _search.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _search.text.length,
    );
  }

  void _whereWasI() {
    if (_triage.open || ref.read(weeklyReviewOpenProvider)) return;
    final l10n = AppLocalizations.of(context);
    final selected = ref.read(selectedItemProvider);
    if (selected != null) {
      final item = ref.read(itemProvider(selected)).valueOrNull;
      if (item == null) return;
      final title = itemHeadline(
        item.rawText,
        ref.read(inlineTokenRegistryProvider),
        parseContextOf(l10n, LocalDate.of(DateTime.now())),
      ).title;
      unawaited(
        showWhereWasI(context, ref, ItemSnapshotOwner(selected), title: title),
      );
      return;
    }
    final open = ref.read(openProjectProvider)?.id;
    final project = open == null ? null : ref.read(projectTreeProvider)[open];
    if (ref.read(destinationProvider) != Destination.projects ||
        project == null ||
        project.isArchived) {
      return;
    }
    unawaited(
      showWhereWasI(
        context,
        ref,
        ProjectSnapshotOwner(project.id),
        title: project.name,
      ),
    );
  }

  void _select(String? id) {
    ref.read(selectedItemProvider.notifier).state = id;
    _listFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final destination = ref.watch(destinationProvider);
    // A person opened from an item or a search result (DD-018 point 7):
    // the search results make way for the person.
    ref.listen(openPersonProvider, (previous, next) {
      if (next != null) _search.clear();
      // Once the panes are built: a person opened in the right pane takes
      // the keys there; one closed hands them back to the list, and a card
      // selected in the person no longer is (DD-018 point 11). Opening goes
      // through null, so only what is still so counts.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || ref.read(openPersonProvider) != next) return;
        if (next != null) {
          if (_personFocus.context != null) _personFocus.requestFocus();
        } else if (previous != null) {
          ref.read(selectedItemProvider.notifier).state = null;
          _listFocus.requestFocus();
        }
      });
    });
    void go(Destination d) => _go(d, byKey: true);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.digit1, control: true): () =>
            go(Destination.today),
        const SingleActivator(LogicalKeyboardKey.numpad1, control: true): () =>
            go(Destination.today),
        const SingleActivator(LogicalKeyboardKey.digit2, control: true): () =>
            go(Destination.inbox),
        const SingleActivator(LogicalKeyboardKey.numpad2, control: true): () =>
            go(Destination.inbox),
        const SingleActivator(LogicalKeyboardKey.digit3, control: true): () =>
            go(Destination.projects),
        const SingleActivator(LogicalKeyboardKey.numpad3, control: true): () =>
            go(Destination.projects),
        const SingleActivator(LogicalKeyboardKey.digit4, control: true): () =>
            go(Destination.people),
        const SingleActivator(LogicalKeyboardKey.numpad4, control: true): () =>
            go(Destination.people),
        const SingleActivator(LogicalKeyboardKey.digit5, control: true): () =>
            go(Destination.insights),
        const SingleActivator(LogicalKeyboardKey.numpad5, control: true): () =>
            go(Destination.insights),
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): () =>
            CaptureScreen.open(context),
        // The weekly review (DD-018 point 8); not over triage.
        const SingleActivator(
          LogicalKeyboardKey.keyW,
          control: true,
          shift: true,
        ): () {
          if (_triage.open) return;
          _content.currentState?.popUntil((route) => route.isFirst);
          _search.clear();
          WeeklyReviewScreen.open(context, ref);
        },
        const SingleActivator(LogicalKeyboardKey.keyF, control: true):
            _focusSearch,
        // "Where was I" on the item selected in the list, or the open
        // project, when no item or project screen took the key first
        // (DD-018 point 13 (a)).
        const SingleActivator(
          LogicalKeyboardKey.keyP,
          control: true,
          shift: true,
        ): _whereWasI,
      },
      child: Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: destination.index,
              onDestinationSelected: (index) => _go(Destination.values[index]),
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: FloatingActionButton(
                  elevation: 0,
                  tooltip: l10n.captureAction,
                  onPressed: () => CaptureScreen.open(context),
                  child: const Icon(Icons.add),
                ),
              ),
              trailingAtBottom: true,
              trailing: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  tooltip: l10n.settingsTitle,
                  onPressed: () => SettingsScreen.open(context),
                ),
              ),
              destinations: [
                NavigationRailDestination(
                  icon: const Icon(Icons.wb_sunny_outlined),
                  selectedIcon: const Icon(Icons.wb_sunny),
                  label: Text(l10n.navToday),
                ),
                NavigationRailDestination(
                  icon: widget.inboxIcon,
                  label: Text(l10n.inboxTitle),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.folder_outlined),
                  selectedIcon: const Icon(Icons.folder),
                  label: Text(l10n.navProjects),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.people_outline),
                  selectedIcon: const Icon(Icons.people),
                  label: Text(l10n.navPeople),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.insights_outlined),
                  selectedIcon: const Icon(Icons.insights),
                  label: Text(l10n.navInsights),
                ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: Navigator(
                key: _content,
                observers: [_triage],
                onGenerateInitialRoutes: (_, _) => [
                  MaterialPageRoute<void>(
                    builder: (_) => _Panes(
                      search: _search,
                      searchFocus: _searchFocus,
                      listFocus: _listFocus,
                      personFocus: _personFocus,
                      detailFocusRequests: _detailFocusRequests,
                      width: _width,
                      select: _select,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Counts the triage screens open in the destination's navigator.
class _TriageObserver extends NavigatorObserver {
  int _open = 0;

  bool get open => _open > 0;

  bool _isTriage(Route<dynamic> route) =>
      route.settings.name == TriageScreen.routeName;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_isTriage(route)) _open++;
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_isTriage(route)) _open--;
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_isTriage(route)) _open--;
  }
}

/// The search field above the list, and from [twoPaneMinWidth] the item
/// detail beside it (DD-018 point 5).
class _Panes extends ConsumerWidget {
  const _Panes({
    required this.search,
    required this.searchFocus,
    required this.listFocus,
    required this.personFocus,
    required this.detailFocusRequests,
    required this.select,
    required this.width,
  });

  final TextEditingController search;
  final FocusNode searchFocus;
  final FocusNode listFocus;
  final FocusNode personFocus;
  final ValueNotifier<int> detailFocusRequests;
  final ValueChanged<String?> select;
  final _PaneWidth width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // The weekly review takes the list pane while it is open (DD-018 point
    // 8); the detail pane keeps showing the selected item.
    final reviewOpen = ref.watch(weeklyReviewOpenProvider);
    final destination = ref.watch(destinationProvider);
    final twoPanes = MediaQuery.sizeOf(context).width >= twoPaneMinWidth;
    final segment = ref.watch(insightsSegmentProvider);
    final body = reviewOpen
        ? const WeeklyReviewScreen(embedded: true)
        : destination == Destination.insights
        ? InsightsScreen(wide: twoPanes)
        : destinationBody(destination);
    // Both panes: the Overview's Horizon and Standstill, and the Overview
    // step of the weekly review (DD-018 point 12 (f), (g)).
    // People keeps two panes, in the tab and in the review alike.
    final shown = shownSegment(segment, inReview: reviewOpen);
    final full =
        shown != InsightsSegment.people &&
        shown != InsightsSegment.connections &&
        (reviewOpen
            ? ref.watch(weeklyReviewWideProvider)
            : destination == Destination.insights);
    final list = Material(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: CallbackShortcuts(
              bindings: {
                // Escape empties the field and goes back to the list.
                const SingleActivator(LogicalKeyboardKey.escape): () {
                  search.clear();
                  listFocus.requestFocus();
                },
              },
              // As wide as the list pane, also when the list takes both.
              child: Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 416),
                  child: ValueListenableBuilder(
                    valueListenable: search,
                    builder: (context, value, _) => TextField(
                      controller: search,
                      focusNode: searchFocus,
                      // The weekly review is a mode: no search over it.
                      enabled: !reviewOpen,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: l10n.searchHint,
                        prefixIcon: const Icon(Icons.search),
                        isDense: true,
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(24)),
                        ),
                        suffixIcon: value.text.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.close),
                                tooltip: l10n.searchClear,
                                onPressed: search.clear,
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: search,
              builder: (context, value, _) => value.text.trim().isEmpty
                  ? body
                  : SearchResults(query: value.text),
            ),
          ),
        ],
      ),
    );
    if (!twoPanes) {
      width.wasNarrow = true;
      return list;
    }
    // An item opened over the list in a narrow window closes when the
    // window becomes wide enough: the detail pane shows it, and two editors
    // of one item would both save. Only on that change, so an item opened
    // from triage in a wide window stays open when the window is resized.
    if (width.wasNarrow) {
      width.wasNarrow = false;
      final navigator = Navigator.of(context);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!navigator.mounted) return;
        navigator.popUntil(
          (route) => route.settings.name != ItemDetailScreen.routeName,
        );
      });
    }
    final selected = ref.watch(selectedItemProvider);
    // People: an open person is in the right pane while the list pane shows
    // the balance (DD-018 point 11). Search results and the weekly review
    // there show the selected item, as elsewhere; the person comes back
    // when they close.
    // The Overview's People segment is the balance too (DD-018 point 12).
    final balance =
        !reviewOpen &&
        (destination == Destination.people ||
            destination == Destination.insights &&
                segment == InsightsSegment.people);
    final person = balance ? ref.watch(openPersonProvider) : null;
    // Connections: a person or project focus is in the right pane (DD-018
    // point 15 (e)); an item focus the view selects as usual.
    final connectionsFocus =
        !reviewOpen &&
            destination == Destination.insights &&
            segment == InsightsSegment.connections
        ? ref.watch(connectionsFocusProvider)
        : null;
    final navigator = Navigator.of(context);
    // An item as a screen of its own, where no detail pane shows it.
    void pushItem(String? id) {
      if (id == null) return;
      navigator.push(
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: ItemDetailScreen.routeName),
          builder: (_) => ItemDetailScreen(itemId: id),
        ),
      );
    }

    Widget detail({required bool searching}) {
      final focus = connectionsFocus;
      if (focus != null && focus.kind != NodeKind.item && !searching) {
        void back() => ref.read(connectionsProvider.notifier).back();
        return ItemPanes(
          select: pushItem,
          listFocus: personFocus,
          detailFocusRequests: detailFocusRequests,
          detailPane: false,
          child: focus.kind == NodeKind.person
              ? PersonScreen(
                  key: ValueKey(focus),
                  personId: focus.id,
                  onBack: back,
                )
              : ProjectScreen(
                  key: ValueKey(focus),
                  projectId: focus.id,
                  onBack: back,
                ),
        );
      }
      if (person != null && !searching) {
        // An item from the person's lists opens as a screen of its own: the
        // right pane holds the person (DD-018 point 11).
        return ItemPanes(
          select: pushItem,
          listFocus: personFocus,
          detailFocusRequests: detailFocusRequests,
          detailPane: false,
          child: PersonScreen(key: ValueKey(person), personId: person),
        );
      }
      if (selected == null) return const _ChooseItem();
      return ItemDetailScreen(
        key: ValueKey(selected),
        itemId: selected,
        embedded: true,
      );
    }

    return ValueListenableBuilder(
      valueListenable: search,
      builder: (context, value, _) {
        final searching = value.text.trim().isNotEmpty;
        // Search results need the detail pane. The list keeps its place in
        // the tree, so the search field keeps its focus when this changes.
        final wide = full && !searching;
        return ItemPanes(
          select: wide ? pushItem : select,
          listFocus: listFocus,
          detailFocusRequests: detailFocusRequests,
          detailPane: !wide,
          child: LayoutBuilder(
            builder: (context, constraints) => Row(
              children: [
                SizedBox(width: wide ? constraints.maxWidth : 440, child: list),
                if (!wide) ...[
                  const VerticalDivider(width: 1),
                  Expanded(child: detail(searching: searching)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Whether the window was too narrow for two panes at the last build.
class _PaneWidth {
  bool wasNarrow = false;
}

/// The detail pane with nothing selected (DD-018 point 5).
class _ChooseItem extends StatelessWidget {
  const _ChooseItem();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Material(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_box_outline_blank,
              size: 40,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(l10n.panesChooseItem, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              l10n.panesChooseHint,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
