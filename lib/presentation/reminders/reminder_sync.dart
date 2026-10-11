import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/app/open_targets.dart';
import '../../domain/items/item.dart';
import '../../domain/items/item_headline.dart';
import '../../domain/items/nudge.dart';
import '../../domain/items/revisit.dart';
import '../../domain/items/today.dart';
import '../../domain/people/person.dart';
import '../../domain/reminders/birthday_reminders.dart';
import '../../domain/reminders/day_reminders.dart';
import '../../domain/reminders/nudge_reminders.dart';
import '../../domain/reminders/review_reminders.dart';
import '../../domain/time/local_date.dart';
import '../../domain/tokens/token_processing.dart';
import '../../l10n/app_localizations.dart';
import '../../platform/reminders/reminder_scheduler.dart';
import '../capture/capture_screen.dart';
import '../home/destination.dart';
import '../home/item_panes.dart';
import '../inbox/inbox_card.dart';
import '../items/item_detail_screen.dart';
import '../messages.dart';
import '../people/people_providers.dart';
import '../people/person_screen.dart';
import '../projects/project_providers.dart';
import '../repeats/repeat_providers.dart';
import '../review/review_providers.dart';
import '../review/weekly_review_screen.dart';
import '../startup/app_storage_provider.dart';
import '../tokens/token_display.dart';
import '../tokens/token_editor.dart';
import 'reminder_providers.dart';

/// The most titles in one notification (DD-005).
const reminderTitlesShown = 5;

/// The notifications of the birthday reminders [days] (REQ-031, DD-005,
/// T4.6): "Jan Bakker is vandaag jarig" with "wordt 46", or "2
/// verjaardagen vandaag" with the names; on the lock screen never a name.
/// A tap opens the person, or *Today* for more.
List<PlannedReminder> birthdayRemindersOf(
  List<BirthdayDay> days, {
  required Map<String, Person> people,
  required AppLocalizations l10n,
}) => [
  for (final day in days)
    () {
      final born = [
        for (final id in day.personIds)
          if (people[id] != null) people[id]!,
      ];
      if (born.length == 1) {
        final person = born.single;
        final age = ageTurningOn(person.birthday!, day.day);
        return PlannedReminder(
          id: day.id,
          at: day.at,
          title: l10n.birthdayReminderOne(person.name),
          lines: [if (age != null) l10n.birthdayReminderTurns(age)],
          publicTitle: l10n.birthdayReminderPublic,
          open: personReminderOpen(person.id),
        );
      }
      final title = l10n.birthdayReminderMany(born.length);
      return PlannedReminder(
        id: day.id,
        at: day.at,
        title: title,
        lines: [
          for (final person in born.take(reminderTitlesShown))
            switch (ageTurningOn(person.birthday!, day.day)) {
              final age? => l10n.birthdayReminderPersonAge(person.name, age),
              null => person.name,
            },
          if (born.length > reminderTitlesShown)
            l10n.reminderMore(born.length - reminderTitlesShown),
        ],
        publicTitle: title,
        open: '',
      );
    }(),
];

/// The notifications of the nudges [days] (AC REQ-047, T10.1, decision c):
/// for one item "Wacht nog op Petra · 7 dagen stil" with its title, a tap
/// opens it; for more "3 wacht-items blijven stil" with the titles, a tap
/// opens *Today*. The lock screen shows neither titles nor names.
List<PlannedReminder> nudgeRemindersOf(
  List<NudgeDay> days, {
  required Map<String, Item> items,
  required Map<String, String> personNames,
  required String Function(String rawText) title,
  required int afterDays,
  required AppLocalizations l10n,
}) => [
  for (final day in days)
    () {
      final silent = [
        for (final id in day.itemIds)
          if (items[id] != null) items[id]!,
      ];
      if (silent.length == 1) {
        final item = silent.single;
        final person = personNames[item.waitingOnId];
        return PlannedReminder(
          id: day.id,
          at: day.at,
          title: person == null
              ? l10n.nudgeReminderOneNobody(afterDays)
              : l10n.nudgeReminderOne(person, afterDays),
          lines: [title(item.rawText)],
          publicTitle: l10n.nudgeReminderPublic,
          open: item.id,
        );
      }
      final head = l10n.nudgeReminderMany(silent.length);
      return PlannedReminder(
        id: day.id,
        at: day.at,
        title: head,
        lines: [
          for (final item in silent.take(reminderTitlesShown))
            title(item.rawText),
          if (silent.length > reminderTitlesShown)
            l10n.reminderMore(silent.length - reminderTitlesShown),
        ],
        publicTitle: head,
        open: '',
      );
    }(),
];

/// The notifications of the weekly-review reminders [reviews] (REQ-022,
/// DD-018 point 16): "Weekoverzicht aan de beurt" with "Laatste keer n
/// dagen geleden" or "Nog niet gedaan"; nothing private, so the lock screen
/// shows the same title. A tap opens the weekly review.
List<PlannedReminder> reviewRemindersOf(
  List<ReviewReminder> reviews, {
  required AppLocalizations l10n,
}) => [
  for (final review in reviews)
    PlannedReminder(
      id: review.id,
      at: review.at,
      title: l10n.reviewReminderTitle,
      lines: [
        switch (review.daysSince) {
          null => l10n.reviewReminderNever,
          final days => l10n.reviewReminderLast(days),
        },
      ],
      publicTitle: l10n.reviewReminderTitle,
      open: reviewReminderOpen,
    ),
];

/// The notifications of the plan [days], in the words of [l10n] (DD-005,
/// DD-018 points 16 and 17): per day "Deadline vandaag" or "n deadlines
/// vandaag", "Terug in je inbox" or "n terug in je inbox", or with both
/// "1 deadline · 2 terug in je inbox"; below it up to five titles, the
/// deadlines first, a returned one as "Terug: …", then "en nog n". The
/// lock screen shows only the title line. A tap opens the item when there
/// is one, else Today.
List<PlannedReminder> remindersOf(
  List<ReminderDay> days, {
  required Map<String, Item> items,
  required String Function(String rawText) title,
  required AppLocalizations l10n,
}) => [
  for (final day in days)
    () {
      final deadlines = [
        for (final id in day.deadlineIds)
          if (items[id] != null) (id, title(items[id]!.rawText)),
      ];
      final back = [
        for (final id in day.returningIds)
          if (items[id] != null) (id, title(items[id]!.rawText)),
      ];
      final lines = [
        for (final (_, text) in deadlines) text,
        for (final (_, text) in back) l10n.reminderBackLine(text),
      ];
      final count = lines.length;
      final head = switch ((deadlines.length, back.length)) {
        (1, 0) => l10n.reminderTitleOne,
        (final d, 0) => l10n.reminderTitleMany(d),
        (0, 1) => l10n.reminderBackOne,
        (0, final b) => l10n.reminderBackMany(b),
        (final d, final b) => l10n.reminderTitleBoth(d, b),
      };
      return PlannedReminder(
        id: day.id,
        at: day.at,
        title: head,
        lines: count == 1
            // One item: its title, not "Terug: …" (the title says it).
            ? [(deadlines.isEmpty ? back : deadlines).single.$2]
            : [
                ...lines.take(reminderTitlesShown),
                if (count > reminderTitlesShown)
                  l10n.reminderMore(count - reminderTitlesShown),
              ],
        publicTitle: head,
        open: count == 1 ? [...deadlines, ...back].single.$1 : '',
      );
    }(),
];

/// The reminder ids a new plan from [now] may take away: the days whose
/// time is still to come, up to a day past the plan. A reminder whose time
/// has passed is never cancelled, even if it was not shown yet: Android
/// may deliver it up to ten minutes late, or later in deep sleep (SPEC
/// Q38), and planning again in that gap must not lose it.
List<int> reminderIdsToCancel(DateTime now, int minuteOfDay, {int offset = 0}) {
  final today = LocalDate.of(now);
  final passed = !DateTime(
    today.year,
    today.month,
    today.day,
    minuteOfDay ~/ 60,
    minuteOfDay % 60,
  ).isAfter(now);
  return [
    for (var d = passed ? 1 : 0; d <= reminderDaysAhead + 1; d++)
      () {
        final day = today.addDays(d);
        return offset + day.year * 10000 + day.month * 100 + day.day;
      }(),
  ];
}

/// Whether [items] hold an open item with a deadline today or later, or
/// one parked until today or later: then the notification permission is
/// asked (AC REQ-020, AC REQ-021), also for a day further ahead than the
/// plan or one whose time today has passed.
bool hasComingReminder(Iterable<Item> items, DateTime now) {
  final today = LocalDate.of(now);
  return items.any(
    (item) =>
        (item.dueAt != null &&
            isOpen(item.status) &&
            storedToDateOnly(item.dueAt!).compareTo(today) >= 0) ||
        (parkedDayOf(item)?.compareTo(today) ?? -1) >= 0,
  );
}

/// Keeps the planned reminders (deadlines and "revisit on") in step with
/// the items and the settings (DD-005, T4.1, T4.2): after every change, the
/// whole plan again. Asks for the notification permission once, when the
/// first deadline or parked item is there (AC REQ-020, AC REQ-021), and
/// opens what a tap on a notification asks for.
class ReminderSync extends ConsumerStatefulWidget {
  const ReminderSync({
    super.key,
    required this.navigatorKey,
    required this.child,
  });

  /// The app's navigator, to open an item over everything.
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  ConsumerState<ReminderSync> createState() => _ReminderSyncState();
}

class _ReminderSyncState extends ConsumerState<ReminderSync> {
  Timer? _wait;
  StreamSubscription<String>? _taps;
  var _asking = false;

  @override
  void initState() {
    super.initState();
    final scheduler = ref.read(reminderSchedulerProvider);
    if (!scheduler.supported) return;
    _taps = scheduler.opened.listen(_open);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final open = await scheduler.takeOpened();
      if (open != null && mounted) _open(open);
    });
  }

  @override
  void dispose() {
    _wait?.cancel();
    unawaited(_taps?.cancel());
    super.dispose();
  }

  /// A tap on a notification: the item, *Today* (DD-005), the weekly
  /// review (T4.4) or a person (T4.6); or the Offload bar and the app
  /// shortcuts: *Today* or *Insights* (REQ-063). On Windows the item opens
  /// in the right pane and the review in the list pane, as from inside the
  /// app (T4.5). Open screens close (an open item saves on leaving, triage
  /// and the review end), but a capture screen with typed text stays on
  /// top, so nothing typed is lost: the destination is set underneath.
  void _open(String open) {
    ref.read(destinationProvider.notifier).state = open == openInsightsTarget
        ? Destination.insights
        : Destination.today;
    // As choosing Today in the rail does: an open review ends.
    ref.read(weeklyReviewOpenProvider.notifier).state = false;
    ref.read(weeklyReviewWideProvider.notifier).state = false;
    final navigator = widget.navigatorKey.currentState;
    if (navigator == null) return;
    var typing = false;
    navigator.popUntil((route) {
      typing = route is CaptureRoute && route.hasText;
      return route.isFirst || typing;
    });
    if (open.isEmpty ||
        open == openTodayTarget ||
        open == openInsightsTarget ||
        typing) {
      return;
    }
    final desktop = isDesktop(navigator.context);
    if (open == reviewReminderOpen) {
      if (desktop) {
        ref.read(selectedItemProvider.notifier).state = null;
        ref.read(weeklyReviewOpenProvider.notifier).state = true;
        return;
      }
      unawaited(
        navigator.push(
          MaterialPageRoute<void>(builder: (_) => const WeeklyReviewScreen()),
        ),
      );
      return;
    }
    final wide =
        desktop &&
        MediaQuery.sizeOf(navigator.context).width >= twoPaneMinWidth;
    if (personOfReminderOpen(open) case final personId?) {
      if (wide) {
        // As `openPerson` does with two panes (DD-018 point 11): through
        // null, so the shell hears it also when the person is open already.
        ref.read(openPersonProvider.notifier).state = null;
        ref.read(openPersonProvider.notifier).state = personId;
        ref.read(destinationProvider.notifier).state = Destination.people;
        return;
      }
      unawaited(
        navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => PersonScreen(personId: personId, standalone: true),
          ),
        ),
      );
      return;
    }
    if (wide) {
      ref.read(selectedItemProvider.notifier).state = open;
      return;
    }
    unawaited(
      navigator.push(
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: ItemDetailScreen.routeName),
          builder: (_) => ItemDetailScreen(itemId: open),
        ),
      ),
    );
  }

  /// Plans again a moment after the last change, so a burst of changes
  /// gives one plan.
  void _schedule() {
    _wait?.cancel();
    _wait = Timer(const Duration(milliseconds: 500), () => unawaited(_sync()));
  }

  Future<void> _sync() async {
    if (!mounted) return;
    final scheduler = ref.read(reminderSchedulerProvider);
    final items = ref.read(liveItemsProvider).valueOrNull;
    if (items == null) return;
    // Not before the repeats are known: a plan without them would take
    // away the later dates of a series for a moment (T4.7).
    final repeats = ref.read(repeatsProvider).valueOrNull;
    if (repeats == null) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final now = DateTime.now();
    final registry = ref.read(inlineTokenRegistryProvider);
    final parse = parseContextOf(l10n, LocalDate.of(now));
    final on = ref.read(remindersOnProvider);
    final minute = ref.read(reminderMinuteProvider);
    final days = on
        ? planDayReminders(
            items,
            now: now,
            minuteOfDay: minute,
            repeats: repeats,
          )
        : const <ReminderDay>[];
    final birthdaysOn = ref.read(birthdayRemindersOnProvider);
    // Not before the people are known: a plan without them would take
    // away their planned birthdays for a moment.
    final people = ref.read(peopleProvider).valueOrNull;
    if (people == null) return;
    final birthdays = birthdaysOn
        ? planBirthdayReminders(people, now: now, minuteOfDay: minute)
        : const <BirthdayDay>[];
    final nudgeOn = ref.read(nudgeOnProvider);
    final nudgeAfter = ref.read(nudgeAfterProvider);
    final nudges = nudgeOn
        ? planNudgeReminders(
            items,
            now: now,
            minuteOfDay: minute,
            afterDays: nudgeAfter,
          )
        : const <NudgeDay>[];
    final reviewOn = ref.read(reviewReminderOnProvider);
    final reviewMinute = ref.read(reviewReminderMinuteProvider);
    final reviews = reviewOn
        ? planReviewReminders(
            now: now,
            weekday: ref.read(reviewReminderWeekdayProvider),
            minuteOfDay: reviewMinute,
            lastCompleted: ref.read(lastReviewProvider),
            dueAfterDays: ref.read(reviewDueAfterProvider),
          )
        : const <ReviewReminder>[];
    try {
      await scheduler.replaceAll(
        [
          ...remindersOf(
            days,
            items: {for (final item in items) item.id: item},
            title: (raw) => itemHeadline(raw, registry, parse).title,
            l10n: l10n,
          ),
          ...reviewRemindersOf(reviews, l10n: l10n),
          ...birthdayRemindersOf(
            birthdays,
            people: {for (final p in people) p.id: p},
            l10n: l10n,
          ),
          ...nudgeRemindersOf(
            nudges,
            items: {for (final item in items) item.id: item},
            personNames: {for (final p in people) p.id: p.name},
            title: (raw) => itemHeadline(raw, registry, parse).title,
            afterDays: nudgeAfter,
            l10n: l10n,
          ),
        ],
        cancel: [
          ...reminderIdsToCancel(now, minute),
          ...reminderIdsToCancel(
            now,
            reviewMinute,
            offset: reviewReminderIdOffset,
          ),
          ...reminderIdsToCancel(now, minute, offset: birthdayReminderIdOffset),
          ...reminderIdsToCancel(now, minute, offset: nudgeReminderIdOffset),
        ],
        channelName: l10n.reminderChannelName,
      );
    } catch (_) {
      // Deadlines and returned items stay on Today; the next change tries
      // again.
      return;
    }
    final anyBirthday = people.any((p) => p.birthday != null);
    if ((on && hasComingReminder(items, now)) ||
        reviewOn ||
        (birthdaysOn && anyBirthday) ||
        (nudgeOn && items.any(canGoSilent))) {
      await _askOnce(scheduler, l10n, messenger);
    }
  }

  /// The permission, asked once: at the first deadline or parked item (AC
  /// REQ-020, AC REQ-021), or when the weekly-review reminder is switched on
  /// (T4.4). After a refusal, one message says where deadlines still show.
  Future<void> _askOnce(
    ReminderScheduler scheduler,
    AppLocalizations l10n,
    ScaffoldMessengerState? messenger,
  ) async {
    final storage = ref.read(storageProvider);
    if (_asking || storage.notificationsAsked) return;
    _asking = true;
    try {
      // Marked before asking: if asking fails, or Android loses the
      // question when the screen is rebuilt, the app does not ask again by
      // itself; Settings still offers "Meldingen toestaan".
      await storage.saveNotificationsAsked();
      if (await scheduler.enabled()) return;
      final granted = await scheduler.request();
      ref.invalidate(notificationsEnabledProvider);
      if (granted || messenger == null) return;
      showMessage(
        messenger,
        SnackBar(
          content: Text(l10n.reminderRefused),
          action: SnackBarAction(
            label: l10n.reminderRefusedAction,
            onPressed: () => unawaited(scheduler.openSettings()),
          ),
        ),
      );
    } catch (_) {
      // Not asked after all; Settings still shows the state.
    } finally {
      _asking = false;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The texts follow the language.
    if (ref.read(reminderSchedulerProvider).supported) _schedule();
  }

  @override
  Widget build(BuildContext context) {
    if (ref.read(reminderSchedulerProvider).supported) {
      ref
        ..listen(liveItemsProvider, (_, _) => _schedule())
        ..listen(repeatsProvider, (_, _) => _schedule())
        ..listen(remindersOnProvider, (_, _) => _schedule())
        ..listen(reminderMinuteProvider, (_, _) => _schedule())
        // The weekly-review reminder: its setting, and a review completed
        // or the rule changed (T4.4).
        ..listen(reviewReminderOnProvider, (_, _) => _schedule())
        ..listen(reviewReminderWeekdayProvider, (_, _) => _schedule())
        ..listen(reviewReminderMinuteProvider, (_, _) => _schedule())
        ..listen(lastReviewProvider, (_, _) => _schedule())
        ..listen(reviewDueAfterProvider, (_, _) => _schedule())
        // Birthdays: the people and their setting (T4.6).
        ..listen(peopleProvider, (_, _) => _schedule())
        ..listen(birthdayRemindersOnProvider, (_, _) => _schedule())
        // The nudge of silent waiting items (T10.1).
        ..listen(nudgeOnProvider, (_, _) => _schedule())
        ..listen(nudgeAfterProvider, (_, _) => _schedule())
        // A new day: today's reminder may have passed, a new day comes in.
        ..listen(
          minuteClockProvider.select(
            (now) =>
                now.valueOrNull == null ? null : LocalDate.of(now.valueOrNull!),
          ),
          (_, _) => _schedule(),
        );
    }
    return widget.child;
  }
}
