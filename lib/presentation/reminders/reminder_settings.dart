import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/items/nudge.dart';
import '../../l10n/app_localizations.dart';
import '../messages.dart';
import '../theme/design_tokens.dart';
import 'reminder_providers.dart';

/// Settings → Reminders (NL "Herinneringen", DD-018 point 16): the switch,
/// the time of day, a note when the platform has notifications off, and
/// the weekly-review reminder with its day and time (T4.4).
/// Not shown where the platform has no reminders (Android since T4.1,
/// Windows since T4.5).
class ReminderSettingsSection extends ConsumerStatefulWidget {
  const ReminderSettingsSection({super.key, required this.headerStyle});

  final TextStyle? headerStyle;

  @override
  ConsumerState<ReminderSettingsSection> createState() =>
      _ReminderSettingsSectionState();
}

class _ReminderSettingsSectionState
    extends ConsumerState<ReminderSettingsSection> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Back from Android's settings: read the state again.
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.invalidate(notificationsEnabledProvider),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _save(Future<void> Function() save) async {
    final failed = AppLocalizations.of(context).settingsSaveFailed;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await save();
    } catch (_) {
      // The choice still applies until restart.
      showMessage(messenger, SnackBar(content: Text(failed)));
    }
  }

  Future<void> _chooseTime() async {
    final minutes = ref.read(reminderMinuteProvider);
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
    );
    if (picked == null || !mounted) return;
    await _save(
      () => ref
          .read(reminderMinuteProvider.notifier)
          .choose(picked.hour * 60 + picked.minute),
    );
  }

  Future<void> _chooseReviewTime() async {
    final minutes = ref.read(reviewReminderMinuteProvider);
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
    );
    if (picked == null || !mounted) return;
    await _save(
      () => ref
          .read(reviewReminderMinuteProvider.notifier)
          .choose(picked.hour * 60 + picked.minute),
    );
  }

  String _time(BuildContext context, int minutes) =>
      MaterialLocalizations.of(context).formatTimeOfDay(
        TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
        alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
      );

  @override
  Widget build(BuildContext context) {
    final scheduler = ref.watch(reminderSchedulerProvider);
    if (!scheduler.supported) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final on = ref.watch(remindersOnProvider);
    final minutes = ref.watch(reminderMinuteProvider);
    final enabled = ref.watch(notificationsEnabledProvider).valueOrNull ?? true;
    final time = _time(context, minutes);
    final reviewOn = ref.watch(reviewReminderOnProvider);
    final birthdaysOn = ref.watch(birthdayRemindersOnProvider);
    final nudgeOn = ref.watch(nudgeOnProvider);
    final nudgeAfter = ref.watch(nudgeAfterProvider);
    final reviewWeekday = ref.watch(reviewReminderWeekdayProvider);
    final reviewTime = _time(context, ref.watch(reviewReminderMinuteProvider));
    // A week whose Monday is the 5th: day n is the (4 + n)th.
    String dayName(int weekday) =>
        l10n.settingsReviewReminderDayName(DateTime(2026, 10, 4 + weekday));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          title: Text(l10n.settingsRemindersHeader, style: widget.headerStyle),
        ),
        SwitchListTile(
          title: Text(l10n.settingsRemindersOn),
          subtitle: Text(l10n.settingsRemindersOnHint),
          value: on,
          onChanged: (value) => unawaited(
            _save(() => ref.read(remindersOnProvider.notifier).choose(value)),
          ),
        ),
        if ((on || reviewOn || birthdaysOn || nudgeOn) && !enabled)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: calmChipColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.settingsRemindersBlocked,
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(l10n.settingsRemindersBlockedHint),
                    TextButton(
                      onPressed: () => unawaited(scheduler.openSettings()),
                      child: Text(l10n.settingsRemindersAllow),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ListTile(
          enabled: on,
          title: Text(l10n.settingsReminderTime),
          subtitle: Text(l10n.settingsReminderTimeHint),
          trailing: OutlinedButton(
            onPressed: on ? () => unawaited(_chooseTime()) : null,
            child: Text(time, style: const TextStyle(fontFamily: monoFamily)),
          ),
        ),
        // Birthdays, at the day's time (REQ-031, T4.6).
        SwitchListTile(
          title: Text(l10n.settingsBirthdayRemindersOn),
          subtitle: Text(l10n.settingsBirthdayRemindersOnHint),
          value: birthdaysOn,
          onChanged: (value) => unawaited(
            _save(
              () =>
                  ref.read(birthdayRemindersOnProvider.notifier).choose(value),
            ),
          ),
        ),
        // Waiting items that stay silent (AC REQ-047, T10.1).
        SwitchListTile(
          title: Text(l10n.settingsNudgeOn),
          subtitle: Text(l10n.settingsNudgeOnHint),
          value: nudgeOn,
          onChanged: (value) => unawaited(
            _save(() => ref.read(nudgeOnProvider.notifier).choose(value)),
          ),
        ),
        // Counts for Today too, so never disabled.
        ListTile(
          title: Text(l10n.settingsNudgeAfter),
          subtitle: Text(l10n.settingsNudgeAfterHint),
          trailing: DropdownButton<int>(
            value: nudgeAfter,
            items: [
              for (final days in NudgeAfter.choices)
                DropdownMenuItem(
                  value: days,
                  child: Text(l10n.settingsDays(days)),
                ),
            ],
            onChanged: (days) {
              if (days == null) return;
              unawaited(
                _save(() => ref.read(nudgeAfterProvider.notifier).choose(days)),
              );
            },
          ),
        ),
        // The weekly-review reminder (REQ-022, T4.4).
        SwitchListTile(
          title: Text(l10n.settingsReviewReminderOn),
          subtitle: Text(l10n.settingsReviewReminderOnHint),
          value: reviewOn,
          onChanged: (value) => unawaited(
            _save(
              () => ref.read(reviewReminderOnProvider.notifier).choose(value),
            ),
          ),
        ),
        ListTile(
          enabled: reviewOn,
          title: Text(l10n.settingsReviewReminderDay),
          trailing: DropdownButton<int>(
            value: reviewWeekday,
            items: [
              for (var d = DateTime.monday; d <= DateTime.sunday; d++)
                DropdownMenuItem(value: d, child: Text(dayName(d))),
            ],
            // As the other choices in Settings; disabled while off.
            onChanged: reviewOn
                ? (weekday) {
                    if (weekday == null) return;
                    unawaited(
                      _save(
                        () => ref
                            .read(reviewReminderWeekdayProvider.notifier)
                            .choose(weekday),
                      ),
                    );
                  }
                : null,
          ),
        ),
        ListTile(
          enabled: reviewOn,
          title: Text(l10n.settingsReminderTime),
          trailing: OutlinedButton(
            onPressed: reviewOn ? () => unawaited(_chooseReviewTime()) : null,
            child: Text(
              reviewTime,
              style: const TextStyle(fontFamily: monoFamily),
            ),
          ),
        ),
      ],
    );
  }
}
