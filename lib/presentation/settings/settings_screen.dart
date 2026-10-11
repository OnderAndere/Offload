import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/help/help_topics.dart';
import '../../domain/overview/horizon.dart';
import '../../domain/people/calling_country.dart';
import '../../domain/people/person_balance.dart';
import '../../domain/review/weekly_review.dart';
import '../../domain/settings/language_choice.dart';
import '../../domain/settings/prefix_bar_mode.dart';
import '../../l10n/app_localizations.dart';
import '../about/about_screen.dart';
import '../backup/backup_section.dart';
import '../help/help_scope.dart';
import '../help/help_screen.dart';
import '../messages.dart';
import '../overview/overview_providers.dart';
import '../people/people_providers.dart';
import '../reminders/reminder_providers.dart';
import '../reminders/reminder_settings.dart';
import '../review/review_providers.dart';
import '../today/today_notes.dart';
import 'build_info_provider.dart';
import 'language_choice_provider.dart';
import 'phone_country_provider.dart';
import 'prefix_bar_provider.dart';
import 'storage_section.dart';

/// Settings screen: the version and build of the app at the top (REQ-060),
/// then the UI language (REQ-029) and the input aids (REQ-034).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  /// Opens Settings over the current screen.
  static Future<void> open(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen()));

  static Future<void> _choose(
    BuildContext context,
    WidgetRef ref,
    LanguageChoice choice,
  ) async {
    try {
      await ref.read(languageChoiceProvider.notifier).choose(choice);
    } catch (_) {
      // Any storage failure: the choice still applies until restart. Wait
      // for the frame in the new language, so the note uses it too.
      await SchedulerBinding.instance.endOfFrame;
      if (!context.mounted) return;
      showMessage(
        ScaffoldMessenger.of(context),
        SnackBar(
          content: Text(
            AppLocalizations.of(context).settingsLanguageSaveFailed,
          ),
        ),
      );
    }
  }

  static Future<void> _choosePrefixBar(
    BuildContext context,
    WidgetRef ref,
    PrefixBarMode mode,
  ) async {
    final failed = AppLocalizations.of(context).settingsPrefixBarSaveFailed;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(prefixBarModeProvider.notifier).choose(mode);
    } catch (_) {
      // The mode still applies until restart.
      showMessage(messenger, SnackBar(content: Text(failed)));
    }
  }

  static Future<void> _chooseStaleAfter(
    BuildContext context,
    WidgetRef ref,
    int weeks,
  ) async {
    final failed = AppLocalizations.of(context).settingsSaveFailed;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(staleAfterProvider.notifier).choose(weeks);
    } catch (_) {
      // The choice still applies until restart.
      showMessage(messenger, SnackBar(content: Text(failed)));
    }
  }

  static Future<void> _chooseReviewDueAfter(
    BuildContext context,
    WidgetRef ref,
    int days,
  ) async {
    final failed = AppLocalizations.of(context).settingsSaveFailed;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(reviewDueAfterProvider.notifier).choose(days);
    } catch (_) {
      // The choice still applies until restart.
      showMessage(messenger, SnackBar(content: Text(failed)));
    }
  }

  static Future<void> _chooseTodayNotes(
    BuildContext context,
    WidgetRef ref,
    bool on,
  ) async {
    final failed = AppLocalizations.of(context).settingsSaveFailed;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(todayNotesOnProvider.notifier).choose(on);
    } catch (_) {
      // The choice still applies until restart.
      showMessage(messenger, SnackBar(content: Text(failed)));
    }
  }

  static Future<void> _chooseBusyFrom(
    BuildContext context,
    WidgetRef ref,
    int count,
  ) async {
    final failed = AppLocalizations.of(context).settingsSaveFailed;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(busyFromProvider.notifier).choose(count);
    } catch (_) {
      // The choice still applies until restart.
      showMessage(messenger, SnackBar(content: Text(failed)));
    }
  }

  static Future<void> _chooseOldAfter(
    BuildContext context,
    WidgetRef ref,
    int days,
  ) async {
    final failed = AppLocalizations.of(context).settingsSaveFailed;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(oldAfterProvider.notifier).choose(days);
    } catch (_) {
      // The choice still applies until restart.
      showMessage(messenger, SnackBar(content: Text(failed)));
    }
  }

  static Future<void> _choosePhoneCountry(
    BuildContext context,
    WidgetRef ref,
    CallingCountry country,
  ) async {
    final failed = AppLocalizations.of(context).settingsSaveFailed;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(phoneCountryProvider.notifier).choose(country);
    } catch (_) {
      showMessage(messenger, SnackBar(content: Text(failed)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final choice = ref.watch(languageChoiceProvider);
    final phoneCountry = ref.watch(phoneCountryProvider);
    final oldAfter = ref.watch(oldAfterProvider);
    final busyFrom = ref.watch(busyFromProvider);
    // The countries by their name in the language shown (T3.6).
    final countries = [...callingCountries]
      ..sort(
        (a, b) =>
            l10n.countryName(a.isoCode).compareTo(l10n.countryName(b.isoCode)),
      );
    final staleAfter = ref.watch(staleAfterProvider);
    final reviewDueAfter = ref.watch(reviewDueAfterProvider);
    final barMode = ref.watch(prefixBarModeProvider);
    final build = ref.watch(buildInfoProvider);
    final headerStyle = Theme.of(context).textTheme.titleSmall;
    // One option per ARB file, each named in its own language and sorted by
    // that name, so a new language needs no code change here (AC REQ-029).
    final languages = [
      for (final locale in AppLocalizations.supportedLocales)
        (
          code: locale.languageCode,
          name: lookupAppLocalizations(locale).languageName,
        ),
    ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return HelpScope(
      topic: HelpTopic.settings,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.settingsTitle),
          actions: const [HelpButton()],
        ),
        body: ListView(
          children: [
            ListTile(title: Text(l10n.settingsAboutHeader, style: headerStyle)),
            if (build == null)
              ListTile(title: Text(l10n.settingsDevelopmentBuild))
            else
              ListTile(
                title: Text(
                  l10n.settingsVersion(build.version, build.buildNumber),
                ),
                subtitle: Text(
                  l10n.settingsBuiltAt(
                    build.builtAt.toLocal(),
                    build.builtAt.toLocal(),
                  ),
                ),
              ),
            // What the app is for and its licences (T8.10, REQ-062).
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(l10n.aboutOpen),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => AboutScreen.open(context),
            ),
            // The user manual (REQ-065, DD-020).
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: Text(l10n.helpTitle),
              subtitle: Text(l10n.helpOpenRow),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => HelpScreen.open(context, HelpTopic.contents),
            ),
            const Divider(),
            ListTile(
              title: Text(l10n.settingsLanguageHeader, style: headerStyle),
            ),
            RadioGroup<LanguageChoice>(
              groupValue: choice,
              onChanged: (value) {
                if (value != null) unawaited(_choose(context, ref, value));
              },
              child: Column(
                children: [
                  RadioListTile<LanguageChoice>(
                    value: const LanguageChoice.system(),
                    title: Text(l10n.settingsLanguageSystem),
                    subtitle: Text(l10n.settingsLanguageSystemHint),
                  ),
                  for (final language in languages)
                    RadioListTile<LanguageChoice>(
                      value: LanguageChoice.language(language.code),
                      title: Text(language.name),
                    ),
                ],
              ),
            ),
            const Divider(),
            ListTile(title: Text(l10n.settingsInputHeader, style: headerStyle)),
            ListTile(
              title: Text(l10n.settingsPrefixBar),
              subtitle: Text(l10n.settingsPrefixBarHint),
            ),
            RadioGroup<PrefixBarMode>(
              groupValue: barMode,
              onChanged: (value) {
                if (value != null) {
                  unawaited(_choosePrefixBar(context, ref, value));
                }
              },
              child: Column(
                children: [
                  RadioListTile<PrefixBarMode>(
                    value: PrefixBarMode.always,
                    title: Text(l10n.settingsPrefixBarAlways),
                  ),
                  RadioListTile<PrefixBarMode>(
                    value: PrefixBarMode.collapsed,
                    title: Text(l10n.settingsPrefixBarCollapsed),
                    subtitle: Text(l10n.settingsPrefixBarCollapsedHint),
                  ),
                  RadioListTile<PrefixBarMode>(
                    value: PrefixBarMode.off,
                    title: Text(l10n.settingsPrefixBarOff),
                  ),
                ],
              ),
            ),
            ListTile(
              title: Text(l10n.settingsPhoneCountry),
              subtitle: Text(l10n.settingsPhoneCountryHint),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButton<CallingCountry>(
                isExpanded: true,
                value: phoneCountry,
                items: [
                  for (final country in countries)
                    DropdownMenuItem(
                      value: country,
                      child: Text(
                        l10n.settingsCountryOption(
                          l10n.countryName(country.isoCode),
                          country.callingCode,
                        ),
                      ),
                    ),
                ],
                onChanged: (country) {
                  if (country != null && country != phoneCountry) {
                    unawaited(_choosePhoneCountry(context, ref, country));
                  }
                },
              ),
            ),
            const Divider(),
            ListTile(title: Text(l10n.settingsTodayHeader, style: headerStyle)),
            SwitchListTile(
              title: Text(l10n.settingsTodayNotes),
              subtitle: Text(l10n.settingsTodayNotesHint),
              value: ref.watch(todayNotesOnProvider),
              onChanged: (on) => unawaited(_chooseTodayNotes(context, ref, on)),
            ),
            const Divider(),
            ListTile(
              title: Text(l10n.settingsReviewHeader, style: headerStyle),
            ),
            ListTile(
              title: Text(l10n.settingsStaleAfter),
              subtitle: Text(l10n.settingsStaleAfterHint),
              trailing: DropdownButton<int>(
                value: staleAfter,
                items: [
                  for (var w = StaleAfter.min; w <= StaleAfter.max; w++)
                    DropdownMenuItem(
                      value: w,
                      child: Text(l10n.settingsWeeks(w)),
                    ),
                ],
                onChanged: (weeks) {
                  if (weeks != null) {
                    unawaited(_chooseStaleAfter(context, ref, weeks));
                  }
                },
              ),
            ),
            ListTile(
              title: Text(l10n.settingsReviewDueAfter),
              subtitle: Text(l10n.settingsReviewDueAfterHint),
              trailing: DropdownButton<int>(
                value: reviewDueAfter,
                items: [
                  for (final days in ReviewDueAfter.choices)
                    DropdownMenuItem(
                      value: days,
                      child: Text(l10n.settingsDays(days)),
                    ),
                ],
                onChanged: (days) {
                  if (days != null) {
                    unawaited(_chooseReviewDueAfter(context, ref, days));
                  }
                },
              ),
            ),
            const Divider(),
            // Hidden where the platform has no reminders yet (Windows).
            ReminderSettingsSection(headerStyle: headerStyle),
            if (ref.watch(reminderSchedulerProvider).supported) const Divider(),
            ListTile(
              title: Text(l10n.settingsPeopleHeader, style: headerStyle),
            ),
            ListTile(
              title: Text(l10n.settingsOldAfter),
              subtitle: Text(l10n.settingsOldAfterHint),
              trailing: DropdownButton<int>(
                value: oldAfter,
                items: [
                  for (final days in OldAfter.choices)
                    DropdownMenuItem(
                      value: days,
                      child: Text(l10n.settingsDays(days)),
                    ),
                ],
                onChanged: (days) {
                  if (days != null) {
                    unawaited(_chooseOldAfter(context, ref, days));
                  }
                },
              ),
            ),
            const Divider(),
            ListTile(
              title: Text(l10n.settingsInsightsHeader, style: headerStyle),
            ),
            ListTile(
              title: Text(l10n.settingsBusyFrom),
              subtitle: Text(l10n.settingsBusyFromHint),
              trailing: DropdownButton<int>(
                value: busyFrom,
                items: [
                  for (var count = BusyFrom.min; count <= BusyFrom.max; count++)
                    DropdownMenuItem(
                      value: count,
                      child: Text(l10n.settingsItemCount(count)),
                    ),
                ],
                onChanged: (count) {
                  if (count != null) {
                    unawaited(_chooseBusyFrom(context, ref, count));
                  }
                },
              ),
            ),
            const Divider(),
            // Backup with a passphrase (T7.1, T7.2), at the end.
            BackupSection(headerStyle: headerStyle),
            const Divider(),
            StorageSection(headerStyle: headerStyle),
          ],
        ),
      ),
    );
  }
}
