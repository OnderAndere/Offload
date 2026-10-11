// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Offload';

  @override
  String get languageName => 'English';

  @override
  String get openSettingsTooltip => 'Open settings';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguageHeader => 'Language';

  @override
  String get settingsLanguageSystem => 'System language';

  @override
  String get settingsLanguageSystemHint =>
      'Follows the device language; English if that is not available';

  @override
  String get startupLoading => 'Offload is starting';

  @override
  String get startupMissingKeyTitle => 'Key missing';

  @override
  String get startupMissingKeyBody =>
      'There is Offload data on this device, but the key to open it is missing. Offload does not create a new key, because that would make your data unreadable for good. Nothing has been changed.';

  @override
  String get startupKeyUnavailableTitle => 'Key unreadable';

  @override
  String get startupKeyUnavailableBody =>
      'Offload\'s key is present but cannot be read right now. Nothing has been changed. Try again, or restart the device.';

  @override
  String get startupDatabaseTitle => 'Data cannot be opened';

  @override
  String get startupDatabaseBody =>
      'Offload\'s data cannot be opened. Nothing has been deleted.';

  @override
  String get startupUnexpectedTitle => 'Offload cannot start';

  @override
  String get startupUnexpectedBody =>
      'Something went wrong while starting. Nothing has been deleted.';

  @override
  String startupErrorDetails(String details) {
    return 'Technical details: $details';
  }

  @override
  String get startupRetry => 'Try again';

  @override
  String get settingsLanguageSaveFailed =>
      'The language choice could not be saved';

  @override
  String get inboxTitle => 'Inbox';

  @override
  String inboxItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
      zero: 'No items yet',
    );
    return '$_temp0';
  }

  @override
  String inboxCapturedAt(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jm(localeName);
    final String timeString = timeDateFormat.format(time);

    return '$dateString, $timeString';
  }

  @override
  String get inboxLoadFailed =>
      'The inbox cannot be loaded. Nothing was deleted.';

  @override
  String get captureAction => 'Capture';

  @override
  String get captureTitle => 'Capture';

  @override
  String get captureHint => 'What\'s on your mind?';

  @override
  String get captureSave => 'Save';

  @override
  String get captureSaveFailed =>
      'Saving failed. Your text is still here; please try again.';

  @override
  String get androidWidgetDescription => 'Capture a thought with one tap';

  @override
  String get androidWidgetHint => 'Capture something…';

  @override
  String captureUnreadable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count captured items could not be read. They were set aside, not deleted.',
      one: '1 captured item could not be read. It was set aside, not deleted.',
    );
    return '$_temp0';
  }

  @override
  String get captureFetchFailed =>
      'Items from the widget could not be fetched yet. They are kept; Offload will try again.';

  @override
  String get noticeDismiss => 'Close';

  @override
  String get trayNewItem => 'New item';

  @override
  String get trayOpen => 'Open';

  @override
  String get trayQuit => 'Quit';

  @override
  String get hotkeyUnavailable =>
      'The shortcut Win+Shift+B is already used by another program. You can capture from the system tray or with the Capture button.';

  @override
  String get settingsBackupHeader => 'Backup and export';

  @override
  String get backupPassphraseRow => 'Passphrase';

  @override
  String get backupPassphraseSet => 'Set';

  @override
  String get backupPassphraseNotSet => 'Not set yet: needed for a backup';

  @override
  String get backupPassphraseTitle => 'Passphrase for backups';

  @override
  String get backupPassphraseField => 'Passphrase';

  @override
  String get backupPassphraseRepeat => 'Once more';

  @override
  String backupPassphraseHint(int min) {
    return 'At least $min characters, for example four separate words. You only type it when you restore a backup on another device.';
  }

  @override
  String get backupPassphraseMismatch => 'The two are not the same';

  @override
  String backupPassphraseTooShort(int min) {
    return 'At least $min characters';
  }

  @override
  String get backupPassphraseInvalid => 'Without a tab or a new line';

  @override
  String backupStrength(String level) {
    return 'Strength: $level';
  }

  @override
  String get backupStrengthTooShort => 'too short';

  @override
  String get backupStrengthFair => 'fair';

  @override
  String get backupStrengthGood => 'good';

  @override
  String get backupStrengthStrong => 'strong';

  @override
  String get backupPassphraseWarning =>
      'Without this passphrase the backup cannot be restored, not even by the app.';

  @override
  String get backupPassphraseWarningConfirm => 'I understand';

  @override
  String get backupPassphraseChangeNote =>
      'Older backups keep their old passphrase.';

  @override
  String get backupPassphraseShow => 'Show passphrase';

  @override
  String get backupSave => 'Save';

  @override
  String get backupCancel => 'Cancel';

  @override
  String get backupPassphraseSaved => 'Passphrase saved';

  @override
  String get backupMake => 'Make a backup';

  @override
  String get backupMakeSubtitle =>
      'Everything encrypted in one file; you choose where';

  @override
  String get backupFileType => 'Offload backup';

  @override
  String backupFileName(String date) {
    return 'Offload-backup-$date';
  }

  @override
  String get backupBusy => 'One moment…';

  @override
  String get backupMade => 'Backup made';

  @override
  String get backupFailed => 'The backup did not work';

  @override
  String get exportRow => 'Export';

  @override
  String get exportRowSubtitle => 'Readable, not encrypted (Markdown or JSON)';

  @override
  String get exportDialogTitle => 'Export';

  @override
  String get exportWarning =>
      'This export is not encrypted. Anyone with the file can read everything.';

  @override
  String get exportMarkdown => 'Markdown';

  @override
  String get exportMarkdownHint => 'Readable, in any text editor';

  @override
  String get exportJson => 'JSON';

  @override
  String get exportJsonHint => 'Structured, for other programs';

  @override
  String get exportConfirm => 'Export';

  @override
  String exportFileName(String date) {
    return 'Offload-export-$date';
  }

  @override
  String get exportMarkdownFileType => 'Markdown file';

  @override
  String get exportJsonFileType => 'JSON file';

  @override
  String get exportSaved => 'Export saved';

  @override
  String get exportReadyToShare => 'Export ready to share';

  @override
  String get exportFailed => 'The export did not work';

  @override
  String get exportTitle => 'Offload export';

  @override
  String exportMadeOn(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jm(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Made on $dateString, $timeString';
  }

  @override
  String exportCounts(int items, int projects, int people) {
    return 'Items: $items · projects: $projects · people: $people';
  }

  @override
  String get exportProjects => 'Projects';

  @override
  String get exportWithoutProject => 'Without project';

  @override
  String get exportPeople => 'People';

  @override
  String get exportArchived => 'archived';

  @override
  String exportDue(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMEd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'deadline $dateString';
  }

  @override
  String exportRevisit(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMEd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'revisit on $dateString';
  }

  @override
  String exportRequester(String name) {
    return 'requested by $name';
  }

  @override
  String exportWaitingOn(String name) {
    return 'waiting for $name';
  }

  @override
  String exportAsked(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'asked on $dateString';
  }

  @override
  String exportPromise(String text) {
    return 'promised: $text';
  }

  @override
  String exportExpected(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'expected on $dateString';
  }

  @override
  String exportCaptured(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'captured $dateString';
  }

  @override
  String exportNextStep(String text) {
    return 'Where was I, next step: $text';
  }

  @override
  String exportInMind(String text) {
    return 'Where was I, in mind: $text';
  }

  @override
  String exportCompletions(String dates) {
    return 'Done: $dates';
  }

  @override
  String exportDay(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String exportAliases(String aliases) {
    return 'Also: $aliases';
  }

  @override
  String exportBirthday(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Birthday: $dateString';
  }

  @override
  String exportBirthdayNoYear(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Birthday: $dateString';
  }

  @override
  String exportWork(String text) {
    return 'Work: $text';
  }

  @override
  String exportContact(String kind, String label) {
    return '$kind ($label)';
  }

  @override
  String get settingsStorageHeader => 'Storage';

  @override
  String get storageDatabase => 'Database';

  @override
  String get storageDatabaseHint => 'Encrypted: everything you captured';

  @override
  String get storageTemporary => 'Temporary files';

  @override
  String get storageTemporaryHint =>
      'A shared backup or export; removed after a day';

  @override
  String get storageContent => 'Content';

  @override
  String storageItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String storageTrashed(int count) {
    return '$count of them in the trash';
  }

  @override
  String storageProjects(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count projects',
      one: '1 project',
    );
    return '$_temp0';
  }

  @override
  String storagePeople(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people',
      one: '1 person',
    );
    return '$_temp0';
  }

  @override
  String storageKilobytes(double value) {
    final intl.NumberFormat valueNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
          locale: localeName,
          decimalDigits: 0,
        );
    final String valueString = valueNumberFormat.format(value);

    return '$valueString kB';
  }

  @override
  String storageMegabytes(double value) {
    final intl.NumberFormat valueNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
          locale: localeName,
          decimalDigits: 1,
        );
    final String valueString = valueNumberFormat.format(value);

    return '$valueString MB';
  }

  @override
  String storageGigabytes(double value) {
    final intl.NumberFormat valueNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
          locale: localeName,
          decimalDigits: 1,
        );
    final String valueString = valueNumberFormat.format(value);

    return '$valueString GB';
  }

  @override
  String get storageUnavailable => 'Cannot be determined';

  @override
  String storageJoin(String first, String second) {
    return '$first · $second';
  }

  @override
  String storageWithTrash(String items, String trashed) {
    return '$items, $trashed';
  }

  @override
  String get backupShare => 'Share…';

  @override
  String get backupSaveOnDevice => 'Save on this device…';

  @override
  String get backupReadyToShare => 'Backup ready to share';

  @override
  String get backupRestore => 'Restore a backup';

  @override
  String get backupRestoreSubtitle => 'Replaces everything on this device';

  @override
  String get backupRestoreAskTitle => 'Passphrase of this backup';

  @override
  String get backupRestoreAskBody =>
      'This backup was made with another passphrase, or on another device.';

  @override
  String get backupRestoreAskOk => 'Open';

  @override
  String get backupWrongPassphrase =>
      'This passphrase does not fit, or the file is no Offload backup.';

  @override
  String get backupTooNew =>
      'This backup comes from a newer version of Offload. Update the app first.';

  @override
  String get backupUnreadable => 'The file could not be read or written.';

  @override
  String get backupRestoreConfirmTitle => 'Replace everything?';

  @override
  String backupRestoreConfirmBody(int count, DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'This backup holds $count items',
      one: 'This backup holds 1 item',
    );
    return '$_temp0, last changed on $dateString. Everything now on this device is replaced; your settings stay. This is a copy, not a sync.';
  }

  @override
  String backupRestoreConfirmBodyUndated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'This backup holds $count items',
      one: 'This backup holds 1 item',
    );
    return '$_temp0. Everything now on this device is replaced; your settings stay. This is a copy, not a sync.';
  }

  @override
  String get backupRestoreConfirm => 'Restore';

  @override
  String get backupOptionsContinue => 'Continue';

  @override
  String backupWithAttachments(String size) {
    return 'With attachments (≈ $size)';
  }

  @override
  String get backupWithAttachmentsHint =>
      'Without them the backup is smaller, but they are not in it.';

  @override
  String backupProgress(String done, String total) {
    return '$done of $total';
  }

  @override
  String backupMissingNote(String message, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count attachments were missing and are not in it.',
      one: '1 attachment was missing and is not in it.',
    );
    return '$message. $_temp0';
  }

  @override
  String backupNoRoom(String needed, String free) {
    return 'Not enough free space: about $needed needed, $free free.';
  }

  @override
  String backupRestoreWithAttachments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'With $count attachments.',
      one: 'With 1 attachment.',
    );
    return '$_temp0';
  }

  @override
  String get backupRestoreNoAttachments =>
      'This backup has no attachments; attachments that do not belong to the restored items will be gone.';

  @override
  String get restoreUndoneTitle => 'Restore did not work';

  @override
  String get restoreUndoneBody =>
      'The restored backup could not be opened. Your data from before the restore is back; nothing was lost.';

  @override
  String get restoreUndoneOk => 'OK';

  @override
  String get settingsAboutHeader => 'About Offload';

  @override
  String get aboutOpen => 'What Offload is for, and the licences';

  @override
  String get aboutPurpose =>
      'Offload empties your head. Capture ongoing work, what is coming, ideas and requests from others in a few seconds, and process them when it suits you. Everything stays on your own device, encrypted and without internet.';

  @override
  String get aboutLicenceTitle => 'Licence';

  @override
  String get aboutLicenceName => 'GNU GPL 3.0 or later';

  @override
  String get aboutLicenceFailed => 'The licence text could not be loaded';

  @override
  String get aboutComponentsTitle => 'Licences of components';

  @override
  String get aboutComponentsSubtitle =>
      'Packages, libraries and typefaces in the app';

  @override
  String settingsVersion(String version, String buildNumber) {
    return 'Version $version (build $buildNumber)';
  }

  @override
  String settingsBuiltAt(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jm(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Built on $dateString, $timeString';
  }

  @override
  String get settingsDevelopmentBuild => 'Development build';

  @override
  String get tokenDateToday => 'today';

  @override
  String get tokenDateTomorrow => 'tomorrow';

  @override
  String get tokenDateDayAfterTomorrow => 'dayafter';

  @override
  String get tokenDateNextWeek => 'nextweek';

  @override
  String get tokenPriorityHigh => 'high';

  @override
  String get tokenPriorityLow => 'low';

  @override
  String get tokenWeekdaysShort => 'mon,tue,wed,thu,fri,sat,sun';

  @override
  String get tokenWeekdaysLong =>
      'monday,tuesday,wednesday,thursday,friday,saturday,sunday';

  @override
  String get tokenPersonLabel => 'person';

  @override
  String get tokenTagLabel => 'tag';

  @override
  String get tokenDateLabel => 'date';

  @override
  String tokenDateChip(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMEd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String tokenChipSemantics(String kind, String value) {
    return '$kind: $value';
  }

  @override
  String get tokenOtherLabel => 'recognised word';

  @override
  String tokenSuggestionNew(String name) {
    return 'New: $name';
  }

  @override
  String get settingsInputHeader => 'Input';

  @override
  String get settingsPrefixBar => 'Prefix bar';

  @override
  String get settingsPrefixBarHint =>
      'Buttons for the input signs when capturing';

  @override
  String get settingsPrefixBarAlways => 'Always visible';

  @override
  String get settingsPrefixBarCollapsed => 'Collapsed';

  @override
  String get settingsPrefixBarCollapsedHint =>
      'One slim row with only the signs, expandable';

  @override
  String get settingsPrefixBarOff => 'Off';

  @override
  String get settingsPrefixBarSaveFailed =>
      'The prefix bar setting could not be saved';

  @override
  String prefixBarButton(String sign, String label) {
    return '$sign $label';
  }

  @override
  String prefixBarInsert(String label) {
    return 'Insert $label';
  }

  @override
  String get prefixBarHelp => 'Syntax overview';

  @override
  String get prefixBarExpand => 'Expand';

  @override
  String get prefixBarCollapse => 'Collapse';

  @override
  String get syntaxOverviewTitle => 'Syntax overview';

  @override
  String get syntaxOverviewIntro =>
      'Put a sign right before a word. Your text stays as you type it.';

  @override
  String get syntaxOverviewClose => 'Close';

  @override
  String get tokenPersonExample => 'Call @Jan about the quote';

  @override
  String get tokenTagExample => 'Clean the gutter #chores';

  @override
  String get tokenDateExample => 'Quote done !friday, or !tomorrow or !12-10';

  @override
  String get commitmentHeader => 'Commitment';

  @override
  String commitmentAskedOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMEd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Asked on $dateString';
  }

  @override
  String commitmentPromised(String text) {
    return 'Promised: $text';
  }

  @override
  String commitmentDue(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMEd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Due: $dateString';
  }

  @override
  String get commitmentDueAdd => 'Add a date';

  @override
  String commitmentWaitsOn(String name) {
    return 'Waiting for $name';
  }

  @override
  String get commitmentWaitsOnNobody => 'Waiting (for no one in particular)';

  @override
  String commitmentExpected(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMEd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Expected: $dateString';
  }

  @override
  String commitmentExpectedLate(DateTime date, int days) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMEd(localeName);
    final String dateString = dateDateFormat.format(date);

    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return 'Expected: $dateString · $_temp0 late';
  }

  @override
  String get commitmentExpectedAdd => 'Add an expected date';

  @override
  String get commitmentReset => 'Reset';

  @override
  String get commitmentPromiseTitle => 'What did you promise?';

  @override
  String get commitmentPromiseField => 'Promised';

  @override
  String get commitmentPromiseHint => 'Empty: the item\'s title.';

  @override
  String get commitmentChangeFailed => 'Saving failed.';

  @override
  String commitmentExpectedChip(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMEd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'expected $dateString';
  }

  @override
  String commitmentLateChip(int days) {
    return '$days d late';
  }

  @override
  String commitmentLateChipLabel(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days late',
      one: '1 day late',
    );
    return '$_temp0';
  }

  @override
  String todayLateSection(int count) {
    return 'Should have come in · $count';
  }

  @override
  String get waitForExpected => 'Expected by…';

  @override
  String waitForExpectedDate(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMEd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Expected by $dateString';
  }

  @override
  String get waitForExpectedOptional => 'optional';

  @override
  String get peopleDeliverTitle => 'I still have to deliver';

  @override
  String peopleDeliverTotal(int count, int people) {
    String _temp0 = intl.Intl.pluralLogic(
      people,
      locale: localeName,
      other: '$people people',
      one: '1 person',
    );
    return '$count to $_temp0';
  }

  @override
  String get peopleWaitTitle => 'I am still waiting for';

  @override
  String peopleWaitTotal(int count, int people) {
    String _temp0 = intl.Intl.pluralLogic(
      people,
      locale: localeName,
      other: '$people people',
      one: '1 person',
    );
    return '$count from $_temp0';
  }

  @override
  String get peopleLegendDeliver => '← I deliver';

  @override
  String get peopleLegendWait => 'I wait →';

  @override
  String get peopleLegendOldest => 'oldest';

  @override
  String peopleAge(int days) {
    return '$days d';
  }

  @override
  String peopleRowSemantics(String name, int deliver, int waiting, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return '$name: you deliver $deliver, you wait for $waiting, oldest $_temp0';
  }

  @override
  String peopleRowSemanticsOld(String text) {
    return '$text, old';
  }

  @override
  String get settingsPeopleHeader => 'People';

  @override
  String get settingsOldAfter => 'Old after';

  @override
  String get settingsOldAfterHint =>
      'From this many days an open item with a person is old: it stands out in the balance.';

  @override
  String get tokenPhoneLabel => 'phone number';

  @override
  String get tokenPhoneExample => 'Call @Jan on 06-12345678 or +31 6 1234 5678';

  @override
  String get tokenEmailLabel => 'email address';

  @override
  String get tokenEmailExample => 'Mail @Jan at jan@example.org';

  @override
  String tokenContactFor(String value, String name) {
    return '$value → $name';
  }

  @override
  String tokenProjectNone(String word) {
    return '$word · no project';
  }

  @override
  String tokenProjectSeveral(String word) {
    return '$word · several projects';
  }

  @override
  String get tokenProjectCreateTooltip =>
      'Create the project and put this item in it';

  @override
  String get contactLinkTooltip => 'Link to a person';

  @override
  String get contactLinkTitle => 'Whose is this?';

  @override
  String contactsTakenFromText(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count details added to $name',
      one: 'Added to $name',
    );
    return '$_temp0';
  }

  @override
  String get contactsTakenUndoFailed =>
      'Removing failed; the details are still with the person.';

  @override
  String get settingsPhoneCountry => 'Country for phone numbers';

  @override
  String get settingsPhoneCountryHint =>
      'For numbers without a +country code, such as 06-12345678.';

  @override
  String settingsCountryOption(String country, String code) {
    return '$country (+$code)';
  }

  @override
  String countryName(String iso) {
    String _temp0 = intl.Intl.selectLogic(iso, {
      'NL': 'Netherlands',
      'BE': 'Belgium',
      'LU': 'Luxembourg',
      'DE': 'Germany',
      'FR': 'France',
      'GB': 'United Kingdom',
      'IE': 'Ireland',
      'ES': 'Spain',
      'PT': 'Portugal',
      'IT': 'Italy',
      'AT': 'Austria',
      'CH': 'Switzerland',
      'DK': 'Denmark',
      'SE': 'Sweden',
      'NO': 'Norway',
      'FI': 'Finland',
      'IS': 'Iceland',
      'PL': 'Poland',
      'CZ': 'Czechia',
      'SK': 'Slovakia',
      'HU': 'Hungary',
      'GR': 'Greece',
      'HR': 'Croatia',
      'SI': 'Slovenia',
      'RO': 'Romania',
      'BG': 'Bulgaria',
      'EE': 'Estonia',
      'LV': 'Latvia',
      'UA': 'Ukraine',
      'TR': 'Türkiye',
      'MA': 'Morocco',
      'SR': 'Suriname',
      'ZA': 'South Africa',
      'US': 'United States',
      'CA': 'Canada',
      'AU': 'Australia',
      'NZ': 'New Zealand',
      'other': '$iso',
    });
    return '$_temp0';
  }

  @override
  String get tokenProjectLabel => 'project';

  @override
  String get tokenProjectExample =>
      'Order window frames ^renovation, or ^old-barn or ^renovation/kitchen';

  @override
  String get tokenLinkLabel => 'item';

  @override
  String get tokenLinkExample => 'Order frames, see [[Compare window quotes]]';

  @override
  String tokenSuggestionItemDetail(String status, String project) {
    return '$status · $project';
  }

  @override
  String tokenLinkTrashed(String title) {
    return '$title · in trash';
  }

  @override
  String tokenLinkNone(String label) {
    return '$label · no item';
  }

  @override
  String get tokenLinkCreateTooltip => 'Create an item and link it';

  @override
  String get tokenLinkOpenTooltip => 'Open item';

  @override
  String get tokenLinkCreateFailed => 'The item could not be created';

  @override
  String itemLinkedFrom(int count) {
    return 'Linked from · $count';
  }

  @override
  String get duplicateLink => 'Link';

  @override
  String get duplicateLinkFailed => 'Linking did not work';

  @override
  String get tokenPriorityLabel => 'priority';

  @override
  String get tokenPriorityExample =>
      'Check the quote *high, or *low or *1, *2, *3';

  @override
  String tokenPriorityChip(String priority) {
    String _temp0 = intl.Intl.selectLogic(priority, {
      'high': 'High priority',
      'low': 'Low priority',
      'other': 'Normal priority',
    });
    return '$_temp0';
  }

  @override
  String tokenSuggestionNewProject(String name) {
    return 'Create project: $name';
  }

  @override
  String get syntaxEscapeLabel => 'plain text';

  @override
  String get syntaxEscapeExample => 'Put \\ in front: \\@Jan is not recognised';

  @override
  String get searchTooltip => 'Search';

  @override
  String get searchHint => 'Search items and people';

  @override
  String get searchStart =>
      'Type one or more words. The start of a word is enough.';

  @override
  String searchNoResults(String query) {
    return 'Nothing found for “$query”';
  }

  @override
  String get searchFailed => 'Search did not work. Please try again.';

  @override
  String get searchClear => 'Clear';

  @override
  String get searchKindItem => 'Item';

  @override
  String get searchKindPerson => 'Person';

  @override
  String get duplicateHint => 'Looks like another item';

  @override
  String get duplicateTitle => 'Is this already there?';

  @override
  String get duplicateThisItem => 'This item';

  @override
  String duplicateOtherItem(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jm(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Looks like this item from $dateString, $timeString';
  }

  @override
  String get duplicateIgnore => 'Ignore';

  @override
  String get duplicateClose => 'Close';

  @override
  String get duplicateIgnoreFailed =>
      'Ignoring was not saved. Please try again.';

  @override
  String get tokenSuggestionPickDate => 'Pick a date…';

  @override
  String get itemStatusInbox => 'Inbox';

  @override
  String get itemStatusActive => 'Active';

  @override
  String get itemStatusWaiting => 'Waiting';

  @override
  String get itemStatusScheduled => 'Scheduled';

  @override
  String get itemStatusDone => 'Done';

  @override
  String get itemStatusArchived => 'Archived';

  @override
  String get itemTypeNone => 'No type';

  @override
  String get itemTypeTask => 'Task';

  @override
  String get itemTypeRequest => 'Request';

  @override
  String get itemTypeIdea => 'Idea';

  @override
  String get itemTypeNote => 'Note';

  @override
  String get itemTypeKind => 'type';

  @override
  String get itemStatusTooltip => 'Change status';

  @override
  String get itemTypeTooltip => 'Change type';

  @override
  String get itemComplete => 'Complete';

  @override
  String get itemReopen => 'Reopen';

  @override
  String get itemWaitFor => 'Wait for…';

  @override
  String get itemTextHint => 'Item text';

  @override
  String get itemTextEmpty => 'An item needs text. The previous text is kept.';

  @override
  String get itemNoteLabel => 'Note';

  @override
  String get itemNoteHint => 'Add a note';

  @override
  String get navProjects => 'Projects';

  @override
  String get projectsWithout => 'Without project';

  @override
  String projectsArchived(int count) {
    return 'Archived · $count';
  }

  @override
  String get projectsNew => 'New project';

  @override
  String get projectsEmpty => 'No projects yet. Create one with +.';

  @override
  String projectsOpenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count open items',
      one: '1 open item',
    );
    return '$_temp0';
  }

  @override
  String projectsOverdueCount(int count) {
    return '$count overdue';
  }

  @override
  String projectGroup(String group, int count) {
    String _temp0 = intl.Intl.selectLogic(group, {
      'inbox': 'Inbox',
      'active': 'Active',
      'waiting': 'Waiting for',
      'scheduled': 'Scheduled',
      'notes': 'Notes',
      'other': 'Done',
    });
    return '$_temp0 · $count';
  }

  @override
  String get projectEmpty => 'Nothing in this project yet.';

  @override
  String get projectRename => 'Rename';

  @override
  String get projectMove => 'Move…';

  @override
  String get projectArchive => 'Archive';

  @override
  String get projectRestore => 'Restore';

  @override
  String get projectDelete => 'Delete';

  @override
  String get projectMenuTooltip => 'Project actions';

  @override
  String get projectRenameTitle => 'Rename project';

  @override
  String get projectNameLabel => 'Name';

  @override
  String get projectParentLabel => 'Under';

  @override
  String get projectTopLevel => 'Top level (no parent)';

  @override
  String get projectMoveTitle => 'Move to';

  @override
  String get projectCreate => 'Create';

  @override
  String get projectSave => 'Save';

  @override
  String get projectCancel => 'Cancel';

  @override
  String projectDeleteTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get projectDeleteBody =>
      'The items stay and lose this project. Sub-projects move to the top level. You can undo it straight away.';

  @override
  String get projectDeleted => 'Project deleted';

  @override
  String get projectArchived => 'Project archived';

  @override
  String get projectRestored => 'Project restored';

  @override
  String get projectErrorNameTaken =>
      'There is already a project with this name.';

  @override
  String get projectErrorEmptyName => 'Give the project a name.';

  @override
  String get projectErrorTooDeep =>
      'Not possible: projects have at most two levels.';

  @override
  String get projectErrorNotAvailable =>
      'This project no longer exists or is archived.';

  @override
  String get projectChangeFailed => 'That did not work. Please try again.';

  @override
  String get projectPickerTitle => 'Project';

  @override
  String get projectPickerHint => 'Search or type a new name';

  @override
  String get projectNone => 'No project';

  @override
  String projectNewNamed(String name) {
    return 'New project: $name';
  }

  @override
  String get projectNewEllipsis => 'New project…';

  @override
  String get projectChipTooltip => 'Choose project';

  @override
  String projectArchivedName(String name) {
    return '$name (archived)';
  }

  @override
  String projectPath(String parent, String name) {
    return '$parent › $name';
  }

  @override
  String get projectKind => 'project';

  @override
  String get projectSubprojects => 'Sub-projects';

  @override
  String get itemShare => 'Share';

  @override
  String get itemShareTitle => 'Share item';

  @override
  String get itemShareIncludeTags => 'Include tags';

  @override
  String get itemShareAsTyped => 'As typed (for Offload)';

  @override
  String get itemShareAsTypedHint =>
      'With @, #, ^, * and fixed dates: Offload on another device makes an item with the same text and tokens of it.';

  @override
  String get itemShareHelper => 'Changes here do not change the item.';

  @override
  String get itemShareCopy => 'Copy';

  @override
  String get itemShareSaveAs => 'Save as…';

  @override
  String get itemShareCancel => 'Cancel';

  @override
  String get itemShareCopied => 'Copied to the clipboard';

  @override
  String get itemShareSaved => 'Saved';

  @override
  String get itemShareFailed => 'Sharing failed. Please try again.';

  @override
  String get itemShareFileType => 'Text file';

  @override
  String itemShareDate(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String itemShareDateWithYear(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String get itemMoveToTrash => 'Move to trash';

  @override
  String get itemMovedToTrash => 'Moved to trash';

  @override
  String get itemUndo => 'Undo';

  @override
  String get itemSaveFailed =>
      'Saving failed. Your change is still there; please try again.';

  @override
  String get itemGone => 'This item is in the trash or no longer exists.';

  @override
  String itemCapturedVia(DateTime date, DateTime time, String source) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jm(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Captured $dateString, $timeString via $source';
  }

  @override
  String get itemSourceApp => 'the app';

  @override
  String get itemSourceWidget => 'the widget';

  @override
  String get itemSourceShare => 'sharing';

  @override
  String get itemSourceHotkey => 'the hotkey';

  @override
  String get itemSourceTray => 'the tray';

  @override
  String get itemSourceVoice => 'voice';

  @override
  String get duplicateOpen => 'Open';

  @override
  String inboxMoreLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+ $count lines',
      one: '+ 1 line',
    );
    return '$_temp0';
  }

  @override
  String get ageJustNow => 'just now';

  @override
  String ageMinutes(int count) {
    return '$count min';
  }

  @override
  String ageHours(int count) {
    return '$count h';
  }

  @override
  String get ageYesterday => 'yesterday';

  @override
  String ageDays(int count) {
    return '$count d';
  }

  @override
  String ageDate(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMEd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String ageMinutesLong(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String ageHoursLong(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String ageDaysLong(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String ageDateLong(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);

    return 'on $dateString';
  }

  @override
  String inboxTriage(int count) {
    return 'Process · $count';
  }

  @override
  String get triageTitle => 'Process';

  @override
  String triageProgress(int position, int total) {
    return '$position of $total';
  }

  @override
  String get triageStop => 'Stop';

  @override
  String get triageWaitFor => 'Wait for';

  @override
  String get triageTrash => 'Trash';

  @override
  String get triageSkip => 'Skip';

  @override
  String get triageOpen => 'Open';

  @override
  String get triageWhoAsked => 'Who asked for this?';

  @override
  String get triageWaitingOn => 'Who are you waiting for?';

  @override
  String get triagePersonHint => 'Name';

  @override
  String get triagePersonDone => 'Done';

  @override
  String triageMovedTo(String destination) {
    return 'Moved to $destination';
  }

  @override
  String get triageDoneTitle => 'Everything has a place';

  @override
  String triageDoneProcessed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count processed',
      one: '1 processed',
    );
    return '$_temp0';
  }

  @override
  String triageDoneSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count skipped, still in your inbox',
      one: '1 skipped, still in your inbox',
    );
    return '$_temp0';
  }

  @override
  String get triageDeleteKey => 'Del';

  @override
  String triageButtonWithKey(String label, String key) {
    return '$label  $key';
  }

  @override
  String get triageBackToInbox => 'Back to the inbox';

  @override
  String inboxStatusAndTime(String status, String when) {
    return '$status · $when';
  }

  @override
  String get itemChangeFailed => 'The change failed. Please try again.';

  @override
  String get itemUndoFailed => 'Undo failed; the item is still in the trash.';

  @override
  String get navToday => 'Today';

  @override
  String navInboxBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unprocessed items',
      one: '1 unprocessed item',
      zero: 'no unprocessed items',
    );
    return '$_temp0';
  }

  @override
  String todayDate(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMEd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String todayInboxLine(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count in your inbox',
      one: '1 in your inbox',
    );
    return '$_temp0';
  }

  @override
  String get todayProcess => 'Process';

  @override
  String todayOverdue(int count) {
    return 'Overdue · $count';
  }

  @override
  String todayDueToday(int count) {
    return 'Today · $count';
  }

  @override
  String get todayEmptyTitle => 'Nothing for today';

  @override
  String get todayEmptyText => 'No deadlines today and nothing overdue.';

  @override
  String get todayLoadFailed => 'Today could not be loaded.';

  @override
  String get itemCompleted => 'Completed';

  @override
  String get triageBack => 'Back';

  @override
  String get panesChooseItem => 'Choose an item';

  @override
  String get panesChooseHint => 'With the mouse, or with ↑ and ↓ in the list.';

  @override
  String get navPeople => 'People';

  @override
  String get peopleFilterHint => 'Find a person';

  @override
  String get peopleEmpty =>
      'No people yet. Name someone with @name when you capture.';

  @override
  String get peopleNoMatch => 'Nobody found.';

  @override
  String personAliases(String aliases) {
    return 'also: $aliases';
  }

  @override
  String personList(String list, String name, int count) {
    String _temp0 = intl.Intl.selectLogic(list, {
      'requestedBy': 'Requested by $name',
      'waitingFor': 'Waiting for $name',
      'other': 'Mentioned in',
    });
    return '$_temp0 · $count';
  }

  @override
  String get personEmpty => 'Nothing with this person yet.';

  @override
  String get personMenuTooltip => 'Person actions';

  @override
  String get personRename => 'Rename';

  @override
  String get personRenameTitle => 'Rename person';

  @override
  String get personNameLabel => 'Name';

  @override
  String personRenameKeeps(String name) {
    return '\"$name\" keeps working as an alias.';
  }

  @override
  String get personSave => 'Save';

  @override
  String get personCancel => 'Cancel';

  @override
  String get personErrorEmptyName => 'Enter a name.';

  @override
  String get personErrorNameTaken =>
      'There is already a person with that name.';

  @override
  String get personErrorNotAvailable => 'This person no longer exists.';

  @override
  String get personRequesterKind => 'Requested by';

  @override
  String get personWaitingKind => 'Waiting for';

  @override
  String personOpen(String name) {
    return 'Open $name';
  }

  @override
  String get personChange => 'Other person…';

  @override
  String get personRemove => 'Remove';

  @override
  String get personInText => 'in the text';

  @override
  String get personErrorSamePerson => 'Choose another person.';

  @override
  String get personMerge => 'Merge with…';

  @override
  String personMergePickerTitle(String name) {
    return 'Merge $name with';
  }

  @override
  String get personMergeNoOthers => 'There is nobody else yet.';

  @override
  String get personMergeTitle => 'Merge people?';

  @override
  String personMergeBody(String from, String into) {
    return 'Merge $from with $into? All items and nicknames go to $into; \"$from\" keeps working as a nickname.';
  }

  @override
  String get personMergeConfirm => 'Merge';

  @override
  String personMerged(String from, String into) {
    return '$from was merged with $into';
  }

  @override
  String personMergeWith(String name) {
    return 'Merge with $name…';
  }

  @override
  String get personMergeUndoFailed => 'Undo failed; the people stay merged.';

  @override
  String get personBirthdayAdd => 'Add birthday';

  @override
  String personBirthday(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String personBirthdayWithAge(DateTime date, int age) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    String _temp0 = intl.Intl.pluralLogic(
      age,
      locale: localeName,
      other: '$age years',
      one: '1 year',
    );
    return '$dateString · $_temp0';
  }

  @override
  String get personBirthdayTitle => 'Birthday';

  @override
  String get personBirthdayTooltip => 'Change birthday';

  @override
  String get personBirthdayDay => 'Day';

  @override
  String get personBirthdayMonth => 'Month';

  @override
  String get personBirthdayYear => 'Year (optional)';

  @override
  String personMonthName(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMM(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String get personBirthdayInvalid => 'This date does not exist.';

  @override
  String get personNoteLabel => 'Note';

  @override
  String get personNoteHint => 'What you want to remember about this person';

  @override
  String personBirthdaySemantics(String value) {
    return 'Birthday: $value';
  }

  @override
  String get reviewTitle => 'Weekly review';

  @override
  String get reviewStartTooltipWithKey => 'Weekly review (Ctrl+Shift+W)';

  @override
  String todayReviewLine(int days) {
    return 'Weekly review · last $days d ago';
  }

  @override
  String todayReviewLineLabel(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return 'Weekly review, last time $_temp0 ago';
  }

  @override
  String get todayReviewLineNever => 'Weekly review · not done yet';

  @override
  String get todayReviewLineNeverLabel => 'Weekly review, not done yet';

  @override
  String get reviewClose => 'Close the weekly review';

  @override
  String get reviewStart => 'Start';

  @override
  String get reviewStepInbox => 'Empty the inbox';

  @override
  String get reviewStepWaiting => 'Go through waiting for';

  @override
  String get reviewStepDeadlines => 'Deadlines';

  @override
  String get reviewStepStale => 'Stale';

  @override
  String reviewInboxCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items to process',
      one: '1 item to process',
    );
    return '$_temp0';
  }

  @override
  String reviewWaitingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String reviewDeadlinesCount(int overdue, int upcoming) {
    return '$overdue overdue · $upcoming in the next 2 weeks';
  }

  @override
  String reviewStaleCount(int count, int weeks) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    String _temp1 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: '$weeks weeks',
      one: '1 week',
    );
    return '$_temp0, untouched for $_temp1 or longer';
  }

  @override
  String get reviewNothing => '✓ nothing to do';

  @override
  String reviewStepOf(int step, int total) {
    return '$step / $total';
  }

  @override
  String get reviewPrevious => 'Previous';

  @override
  String get reviewNext => 'Next';

  @override
  String get reviewFinish => 'Finish';

  @override
  String get reviewInboxEmpty => '✓ The inbox is empty';

  @override
  String get reviewProcess => 'Process';

  @override
  String get reviewStillWaiting => 'Still waiting';

  @override
  String get reviewKeep => 'Keep';

  @override
  String get reviewArchive => 'Archive';

  @override
  String get reviewArchived => 'Archived';

  @override
  String get reviewHandledWaiting => '✓ Still waiting';

  @override
  String get reviewHandledKept => '✓ Kept';

  @override
  String get reviewHandledDone => '✓ Done';

  @override
  String get reviewHandledArchived => '✓ Archived';

  @override
  String get reviewHandledTrashed => '✓ In the trash';

  @override
  String reviewAgeDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'untouched for $days days',
      one: 'untouched for 1 day',
    );
    return '$_temp0';
  }

  @override
  String reviewAgeWeeks(int weeks) {
    return 'untouched for $weeks weeks';
  }

  @override
  String reviewOverdue(int count) {
    return 'Overdue · $count';
  }

  @override
  String reviewUpcoming(int count) {
    return 'Next 2 weeks · $count';
  }

  @override
  String reviewStaleHeader(int weeks, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: '$weeks weeks',
      one: '1 week',
    );
    return 'Untouched for $_temp0 or longer · $count';
  }

  @override
  String get reviewEndTitle => 'Done ✓';

  @override
  String reviewEndKept(int count) {
    return '$count kept';
  }

  @override
  String reviewEndDone(int count) {
    return '$count done';
  }

  @override
  String reviewEndArchived(int count) {
    return '$count archived';
  }

  @override
  String reviewEndTrashed(int count) {
    return '$count in the trash';
  }

  @override
  String get reviewEndNothing => 'Everything was up to date.';

  @override
  String get reviewEndBack => 'To Today';

  @override
  String get settingsReviewHeader => 'Weekly review';

  @override
  String get settingsStaleAfter => 'Stale after';

  @override
  String get settingsStaleAfterHint =>
      'An open item untouched for this long comes up in the last step of the weekly review.';

  @override
  String get settingsReviewDueAfter => 'Due again after';

  @override
  String get settingsReviewDueAfterHint =>
      'This long after the last completed weekly review, Today shows a line to start it.';

  @override
  String settingsDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String settingsWeeks(int weeks) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: '$weeks weeks',
      one: '1 week',
    );
    return '$_temp0';
  }

  @override
  String get settingsSaveFailed =>
      'Saving failed; the choice applies until the app restarts.';

  @override
  String reviewEndWaiting(int count) {
    return '$count still waiting';
  }

  @override
  String get personWorkAdd => 'Add job title and organisation';

  @override
  String get personWorkTooltip => 'Change job title and organisation';

  @override
  String personWorkSemantics(String value) {
    return 'Job title and organisation: $value';
  }

  @override
  String personWork(String jobTitle, String organisation) {
    return '$jobTitle · $organisation';
  }

  @override
  String get personWorkTitle => 'Job title and organisation';

  @override
  String get personJobTitle => 'Job title';

  @override
  String get personOrganisation => 'Organisation';

  @override
  String get contactSection => 'Contact details';

  @override
  String get contactKindPhone => 'Phone number';

  @override
  String get contactKindEmail => 'Email address';

  @override
  String get contactAddPhone => 'Add phone number';

  @override
  String get contactAddEmail => 'Add email address';

  @override
  String get contactEditPhone => 'Change phone number';

  @override
  String get contactEditEmail => 'Change email address';

  @override
  String contactStandardLabel(String label) {
    String _temp0 = intl.Intl.selectLogic(label, {
      'work': 'Work',
      'mobile': 'Mobile',
      'private': 'Private',
      'other': 'Other',
    });
    return '$_temp0';
  }

  @override
  String get contactOwnLabel => 'Own label…';

  @override
  String get contactOwnLabelField => 'Label';

  @override
  String get contactInvalidPhone => 'This does not look like a phone number.';

  @override
  String get contactInvalidEmail => 'This does not look like an email address.';

  @override
  String get contactEmpty => 'Enter something.';

  @override
  String get contactMenuTooltip => 'Actions';

  @override
  String get contactCopy => 'Copy';

  @override
  String get contactCopied => 'Copied';

  @override
  String get contactEdit => 'Change…';

  @override
  String get contactDelete => 'Delete';

  @override
  String get contactDeletedPhone => 'Phone number deleted';

  @override
  String get contactDeletedEmail => 'Email address deleted';

  @override
  String get contactSaveFailed => 'Saving failed.';

  @override
  String get contactUndoFailed => 'The detail could not come back.';

  @override
  String contactRowSemantics(String value, String kind) {
    return '$value, $kind';
  }

  @override
  String contactRowSemanticsWithLabel(String value, String label, String kind) {
    return '$value, $label, $kind';
  }

  @override
  String get contactCall => 'Call';

  @override
  String get contactMail => 'Mail';

  @override
  String get contactLaunchFailed => 'No app found to open this.';

  @override
  String horizonTitle(int weeks) {
    return 'Next $weeks weeks';
  }

  @override
  String horizonSummary(int lanes, int items) {
    String _temp0 = intl.Intl.pluralLogic(
      lanes,
      locale: localeName,
      other: '$lanes lanes',
      one: '1 lane',
    );
    String _temp1 = intl.Intl.pluralLogic(
      items,
      locale: localeName,
      other: '$items items',
      one: '1 item',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get horizonWeekColumn => 'week';

  @override
  String horizonDay(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.Md(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String get horizonBusy => 'busy';

  @override
  String get horizonNoProject => 'No project';

  @override
  String horizonEmpty(int weeks) {
    return 'Nothing with a date in the next $weeks weeks.';
  }

  @override
  String get horizonLegendDeliver => 'I deliver';

  @override
  String get horizonLegendWaiting => 'waiting for someone';

  @override
  String get horizonLegendOverdue => 'overdue';

  @override
  String get horizonLegendLate => 'late';

  @override
  String horizonWeekRange(int number, DateTime from, DateTime to) {
    final intl.DateFormat fromDateFormat = intl.DateFormat.MMMd(localeName);
    final String fromString = fromDateFormat.format(from);
    final intl.DateFormat toDateFormat = intl.DateFormat.MMMd(localeName);
    final String toString = toDateFormat.format(to);

    return 'Week $number · $fromString – $toString';
  }

  @override
  String horizonWeekFrom(int number, DateTime from) {
    final intl.DateFormat fromDateFormat = intl.DateFormat.MMMEd(localeName);
    final String fromString = fromDateFormat.format(from);

    return 'Week $number · from $fromString';
  }

  @override
  String horizonToDeliver(int count) {
    return '$count to deliver';
  }

  @override
  String horizonToDeliverBusy(int count) {
    return '$count to deliver · busy';
  }

  @override
  String get horizonWeekEmpty => 'Nothing this week.';

  @override
  String horizonEntryDue(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMEd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Deadline $dateString';
  }

  @override
  String horizonEntryOverdue(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMEd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Overdue · $dateString';
  }

  @override
  String horizonEntryWaiting(String person, DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMEd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Waiting for $person · expected $dateString';
  }

  @override
  String horizonEntryWaitingNobody(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMEd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Waiting · expected $dateString';
  }

  @override
  String horizonEntryLate(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMEd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Should have come in · $dateString';
  }

  @override
  String horizonEntryFor(String person) {
    return 'for $person';
  }

  @override
  String horizonEntryMore(String text, String more) {
    return '$text · $more';
  }

  @override
  String horizonWeekSemantics(
    int number,
    DateTime from,
    DateTime to,
    int deliver,
    String busy,
    int waiting,
  ) {
    final intl.DateFormat fromDateFormat = intl.DateFormat.MMMMd(localeName);
    final String fromString = fromDateFormat.format(from);
    final intl.DateFormat toDateFormat = intl.DateFormat.MMMMd(localeName);
    final String toString = toDateFormat.format(to);

    String _temp0 = intl.Intl.pluralLogic(
      deliver,
      locale: localeName,
      other: '$deliver to deliver',
      one: '1 to deliver',
      zero: 'nothing to deliver',
    );
    String _temp1 = intl.Intl.selectLogic(busy, {
      'true': ', busy',
      'other': '',
    });
    String _temp2 = intl.Intl.pluralLogic(
      waiting,
      locale: localeName,
      other: '$waiting waiting',
      one: '1 waiting',
      zero: 'nothing waiting',
    );
    return 'Week $number, $fromString to $toString: $_temp0$_temp1; $_temp2';
  }

  @override
  String get standstillTitle => 'What has stalled?';

  @override
  String get standstillSizeHint => 'size = open items';

  @override
  String standstillOpen(int count) {
    return '$count open';
  }

  @override
  String standstillStill(String age) {
    return 'idle $age';
  }

  @override
  String standstillTileShort(int count, String age) {
    return '$count · $age';
  }

  @override
  String standstillAgeDays(int days) {
    return '$days d';
  }

  @override
  String standstillAgeWeeks(int weeks) {
    return '$weeks wk';
  }

  @override
  String standstillAgeSpokenDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String standstillAgeSpokenWeeks(int weeks) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: '$weeks weeks',
      one: '1 week',
    );
    return '$_temp0';
  }

  @override
  String standstillTileSemantics(String project, int count, String age) {
    return '$project: $count open, idle for $age';
  }

  @override
  String standstillLevel(String level) {
    String _temp0 = intl.Intl.selectLogic(level, {
      'fresh': '< 1 wk',
      'weeks': '1–3 wk',
      'longer': '3–6 wk',
      'other': '> 6 wk',
    });
    return '$_temp0';
  }

  @override
  String get standstillOldest => 'Untouched the longest';

  @override
  String get standstillToReview => 'To the weekly review →';

  @override
  String standstillProjectItems(String project, int count) {
    return '$project · $count open';
  }

  @override
  String get standstillOpenProject => 'Open project →';

  @override
  String get standstillShowOldest => 'Back to untouched the longest';

  @override
  String get standstillEmpty => 'Nothing open: nothing has stalled.';

  @override
  String get navInsights => 'Insights';

  @override
  String insightsDate(DateTime date, int week) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMEd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString · wk $week';
  }

  @override
  String insightsSegment(String segment) {
    String _temp0 = intl.Intl.selectLogic(segment, {
      'horizon': 'Horizon',
      'standstill': 'Standstill',
      'both': 'Horizon and standstill',
      'connections': 'Connections',
      'other': 'People',
    });
    return '$_temp0';
  }

  @override
  String get reviewStepInsights => 'Insights';

  @override
  String get reviewInsightsSummary =>
      'What is coming, what has stalled, where you stand with whom';

  @override
  String get reviewContinue => 'Continue';

  @override
  String get settingsInsightsHeader => 'Insights';

  @override
  String get settingsBusyFrom => 'Busy from';

  @override
  String get settingsBusyFromHint =>
      'A week with this many items with a deadline, or more, is busy on the Horizon.';

  @override
  String settingsItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String standstillTileTooltip(String project, int count, String age) {
    return '$project · $count open · $age';
  }

  @override
  String get whereWasI => 'Where was I?';

  @override
  String get whereWasITooltipWithKey => 'Where was I? (Ctrl+Shift+P)';

  @override
  String get whereWasINextStep => 'Next step';

  @override
  String get whereWasIInMind => 'What I had in mind';

  @override
  String get whereWasIInMindHint => 'E.g. why, what you wanted to check…';

  @override
  String get whereWasIClose => 'Close';

  @override
  String get whereWasISave => 'Save';

  @override
  String get whereWasISaveFailed => 'Where was I? was not saved.';

  @override
  String get resumeCardTitle => 'Where was I';

  @override
  String get resumeUpdate => 'Update';

  @override
  String get resumeResume => 'Resume';

  @override
  String connectionsFocusKind(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'person': 'Focus · person',
      'project': 'Focus · project',
      'other': 'Focus',
    });
    return '$_temp0';
  }

  @override
  String get connectionsChange => 'Change';

  @override
  String get connectionsOneStep => '1 step';

  @override
  String get connectionsTwoSteps => '2 steps';

  @override
  String get connectionsLegendDirect => 'directly linked';

  @override
  String get connectionsLegendThrough => 'through a step';

  @override
  String get connectionsHint =>
      'Tap to focus · long press for a preview · pinch to zoom';

  @override
  String get connectionsHintDesktop =>
      'Click to focus · point for a preview · Ctrl+scroll zooms';

  @override
  String get connectionsFit => 'Fit';

  @override
  String connectionsMore(int count) {
    return '+$count more';
  }

  @override
  String get connectionsEmptyTitle => 'How does it fit together?';

  @override
  String get connectionsEmptyBody =>
      'Choose an item, person or project to see what it is connected to.';

  @override
  String get connectionsChoose => 'Choose an item';

  @override
  String get connectionsNothing => 'Nothing linked yet';

  @override
  String get connectionsChooseTitle => 'Choose a focus';

  @override
  String get connectionsChooseHint => 'Search for an item, person or project';

  @override
  String get connectionsRecent => 'Recently opened';

  @override
  String get connectionsChooseItems => 'Items';

  @override
  String get connectionsChoosePeople => 'People';

  @override
  String get connectionsChooseProjects => 'Projects';

  @override
  String get connectionsNoResults => 'Nothing found';

  @override
  String connectionsAllTitle(String name, int count) {
    return 'Connections of $name · $count';
  }

  @override
  String connectionsDirectHeader(int count) {
    return 'Directly linked · $count';
  }

  @override
  String get connectionsFocusAction => 'Focus';

  @override
  String get connectionsOpenAction => 'Open';

  @override
  String get connectionsPreviewAction => 'Preview';

  @override
  String get connectionsShow => 'Show connections';

  @override
  String connectionsKind(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'project': 'Project',
      'person': 'Person',
      'other': 'Item',
    });
    return '$_temp0';
  }

  @override
  String connectionsUrgency(String urgency) {
    String _temp0 = intl.Intl.selectLogic(urgency, {
      'today': 'today',
      'other': 'overdue',
    });
    return '$_temp0';
  }

  @override
  String get connectionsDone => 'done';

  @override
  String get connectionsArchived => 'archived';

  @override
  String connectionsReason(String reason) {
    String _temp0 = intl.Intl.selectLogic(reason, {
      'linksTo': 'link',
      'linkedFrom': 'links here',
      'project': 'project',
      'inProject': 'in this project',
      'parent': 'parent project',
      'other': 'sub-project',
    });
    return '$_temp0';
  }

  @override
  String connectionsReasonPerson(String reason, String name) {
    String _temp0 = intl.Intl.selectLogic(reason, {
      'requester': 'asked by $name',
      'waitingOn': 'waiting for $name',
      'other': 'mentions $name',
    });
    return '$_temp0';
  }

  @override
  String connectionsFocusSemantics(
    String kind,
    String title,
    int direct,
    int through,
  ) {
    return 'Focus: $kind $title. $direct directly linked, $through through a step.';
  }

  @override
  String connectionsDirectSemantics(String kind, String title, String reasons) {
    return 'Directly linked: $kind $title, $reasons';
  }

  @override
  String connectionsThroughSemantics(String via, String kind, String title) {
    return 'Through $via: $kind $title';
  }

  @override
  String connectionsBehindSemantics(int count, String title) {
    return '$count more through $title';
  }

  @override
  String connectionsMoreSemantics(int count) {
    return '$count more connections, opens the list';
  }

  @override
  String get connectionsPreviewProject => 'Project';

  @override
  String get connectionsPreviewDeadline => 'Deadline';

  @override
  String get connectionsPreviewPeople => 'People';

  @override
  String connectionsPreviewDate(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMEd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String connectionsPreviewOpenItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count open items',
      one: '1 open item',
      zero: 'No open items',
    );
    return '$_temp0';
  }

  @override
  String connectionsJoin(String first, String second) {
    return '$first · $second';
  }

  @override
  String connectionsList(String first, String second) {
    return '$first, $second';
  }

  @override
  String get reminderChannelName => 'Reminders';

  @override
  String get reminderTitleOne => 'Deadline today';

  @override
  String reminderTitleMany(int count) {
    return '$count deadlines today';
  }

  @override
  String reminderMore(int count) {
    return 'and $count more';
  }

  @override
  String get reminderRefused =>
      'Without notifications you see deadlines and returned items on Today.';

  @override
  String get reminderRefusedAction => 'Settings';

  @override
  String get settingsRemindersHeader => 'Reminders';

  @override
  String get settingsRemindersOn => 'Notifications for deadlines and revisits';

  @override
  String get settingsRemindersOnHint =>
      'On the day itself; one notification a day.';

  @override
  String get settingsReminderTime => 'Time';

  @override
  String get settingsReminderTimeHint => 'When that day\'s notification comes.';

  @override
  String get settingsRemindersBlocked => 'Notifications are off in Android';

  @override
  String get settingsRemindersBlockedHint =>
      'Deadlines and returned items are still on Today.';

  @override
  String get settingsRemindersAllow => 'Allow notifications';

  @override
  String get revisitAction => 'Revisit on…';

  @override
  String get revisitSheetTitle => 'Revisit on';

  @override
  String get revisitTomorrow => 'Tomorrow';

  @override
  String get revisitNextWeek => 'Next week';

  @override
  String get revisitInAMonth => 'In a month';

  @override
  String get revisitChooseDate => 'Choose date…';

  @override
  String get revisitStop => 'Not any more';

  @override
  String revisitDate(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMEd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String revisitLine(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMEd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Revisit on $dateString';
  }

  @override
  String revisitBackOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMEd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Back on $dateString';
  }

  @override
  String get revisitLater => 'Later…';

  @override
  String revisitLaterWithKey(String key) {
    return 'Later…  $key';
  }

  @override
  String reviewHandledParked(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMEd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '✓ Back on $dateString';
  }

  @override
  String reviewEndParked(int count) {
    return '$count to revisit later';
  }

  @override
  String todayBackSection(int count) {
    return 'Back in your inbox · $count';
  }

  @override
  String get reminderBackOne => 'Back in your inbox';

  @override
  String reminderBackMany(int count) {
    return '$count back in your inbox';
  }

  @override
  String reminderTitleBoth(int deadlines, int back) {
    String _temp0 = intl.Intl.pluralLogic(
      deadlines,
      locale: localeName,
      other: '$deadlines deadlines',
      one: '1 deadline',
    );
    return '$_temp0 · $back back in your inbox';
  }

  @override
  String reminderBackLine(String title) {
    return 'Back: $title';
  }

  @override
  String get settingsReviewReminderOn => 'Weekly review reminder';

  @override
  String get settingsReviewReminderOnHint =>
      'Only when the weekly review is due.';

  @override
  String get settingsReviewReminderDay => 'Day';

  @override
  String settingsReviewReminderDayName(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.EEEE(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String get reviewReminderTitle => 'Weekly review due';

  @override
  String reviewReminderLast(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Last time $days days ago',
      one: 'Last time 1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get reviewReminderNever => 'Not done yet';

  @override
  String birthdayReminderOne(String name) {
    return '$name has a birthday today';
  }

  @override
  String birthdayReminderTurns(int age) {
    return 'turns $age';
  }

  @override
  String birthdayReminderMany(int count) {
    return '$count birthdays today';
  }

  @override
  String birthdayReminderPersonAge(String name, int age) {
    return '$name ($age)';
  }

  @override
  String get birthdayReminderPublic => 'Birthday today';

  @override
  String todayBirthday(String name) {
    return '$name has a birthday today';
  }

  @override
  String todayBirthdayAge(String name, int age) {
    return '$name turns $age today';
  }

  @override
  String get settingsBirthdayRemindersOn => 'Birthdays';

  @override
  String get settingsBirthdayRemindersOnHint =>
      'On the day itself, at the time of the day\'s notification.';

  @override
  String nudgeSilentDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'silent for $days days',
      one: 'silent for 1 day',
    );
    return '$_temp0';
  }

  @override
  String nudgeReminderOne(String person, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'silent for $days days',
      one: 'silent for 1 day',
    );
    return 'Still waiting for $person · $_temp0';
  }

  @override
  String nudgeReminderOneNobody(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'silent for $days days',
      one: 'silent for 1 day',
    );
    return 'Still waiting · $_temp0';
  }

  @override
  String nudgeReminderMany(int count) {
    return '$count waiting items stay silent';
  }

  @override
  String get nudgeReminderPublic => 'Waiting item stays silent';

  @override
  String todaySilentSection(int count) {
    return 'Stays silent · $count';
  }

  @override
  String get nudgeReceived => 'Received';

  @override
  String todayNotesSection(int count) {
    return 'Where was I · $count';
  }

  @override
  String todayNotesMore(int count) {
    return '+$count more';
  }

  @override
  String todayNoteInMind(String text) {
    return 'In mind: $text';
  }

  @override
  String get todayNoteProject => 'Project';

  @override
  String get settingsTodayHeader => 'Today';

  @override
  String get settingsTodayNotes => 'Where was I on Today';

  @override
  String get settingsTodayNotesHint =>
      'Your open notes at the top of Today, newest first.';

  @override
  String get nudgeChased => 'Chased';

  @override
  String get nudgeChasedMessage => 'Chased';

  @override
  String get settingsNudgeOn => 'Waiting items that stay silent';

  @override
  String get settingsNudgeOnHint =>
      'One notification on the day an item goes silent.';

  @override
  String get settingsNudgeAfter => 'Chase after';

  @override
  String get settingsNudgeAfterHint =>
      'That long without a change: then the item is on Today.';

  @override
  String get tokenRepeatDaily => 'daily';

  @override
  String get tokenRepeatWeekly => 'weekly';

  @override
  String get tokenRepeatMonthly => 'monthly';

  @override
  String get tokenRepeatLabel => 'repeat';

  @override
  String get tokenRepeatExample =>
      'Go running !weekly !tue, also !daily or !monthly';

  @override
  String itemCompletedNextTime(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMEd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Done · next time $dateString';
  }

  @override
  String repeatRhythm(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'D': 'daily',
      'W': 'weekly',
      'M': 'monthly',
      'other': 'repeats',
    });
    return '$_temp0';
  }

  @override
  String repeatRhythmTitle(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'D': 'Daily',
      'W': 'Weekly',
      'M': 'Monthly',
      'other': 'Repeats',
    });
    return '$_temp0';
  }

  @override
  String repeatEvery(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'D': 'every day',
      'W': 'every week',
      'M': 'every month',
      'other': 'repeats',
    });
    return '$_temp0';
  }

  @override
  String repeatSinceDaily(DateTime since) {
    final intl.DateFormat sinceDateFormat = intl.DateFormat.MMMd(localeName);
    final String sinceString = sinceDateFormat.format(since);

    return 'Daily · since $sinceString';
  }

  @override
  String repeatSinceWeekly(DateTime weekday, DateTime since) {
    final intl.DateFormat weekdayDateFormat = intl.DateFormat.E(localeName);
    final String weekdayString = weekdayDateFormat.format(weekday);
    final intl.DateFormat sinceDateFormat = intl.DateFormat.MMMd(localeName);
    final String sinceString = sinceDateFormat.format(since);

    return 'Weekly · every $weekdayString, since $sinceString';
  }

  @override
  String repeatSinceMonthly(int day, DateTime since) {
    final intl.DateFormat sinceDateFormat = intl.DateFormat.MMMd(localeName);
    final String sinceString = sinceDateFormat.format(since);

    return 'Monthly · on day $day, since $sinceString';
  }

  @override
  String repeatNotForType(String rhythm) {
    return '$rhythm · repeats only for a task';
  }

  @override
  String repeatThisTime(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMEd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'This time: $dateString';
  }

  @override
  String completionsTitle(int count) {
    return 'Done · $count×';
  }

  @override
  String get completionOnTime => 'on time';

  @override
  String completionLate(DateTime date, int days) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMEd(localeName);
    final String dateString = dateDateFormat.format(date);

    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days late',
      one: '1 day late',
    );
    return 'time of $dateString · $_temp0';
  }

  @override
  String completionsShowAll(int count) {
    return 'Show all ($count)';
  }

  @override
  String get completeAndRepeat => 'Complete and repeat…';

  @override
  String get completeAndRepeatTitle => 'Complete and repeat';

  @override
  String get completeAndRepeatQuestion =>
      'This time is done. When does it come back?';

  @override
  String get completeAndRepeatNote =>
      'Puts the word in the text; removing it stops the repeat.';

  @override
  String get stopRepeating => 'Stop repeating';

  @override
  String get repeatStopped => 'Repeat stopped · done';

  @override
  String get androidBarName => 'Offload bar';

  @override
  String get androidBarDescription => 'Capture, Today and Insights in one tap';

  @override
  String get androidOpenToday => 'Open Today';

  @override
  String get androidOpenInsights => 'Open Insights';

  @override
  String get helpTitle => 'Help';

  @override
  String get helpOpenRow => 'The manual: how Offload works';

  @override
  String get helpTooltip => 'Help';

  @override
  String get helpTooltipWithKey => 'Help (F1)';

  @override
  String get helpContents => 'Contents';

  @override
  String get helpInEnglish => 'The manual is in English.';

  @override
  String get helpLoadFailed => 'This part of the manual could not be opened.';

  @override
  String helpExternalLink(String address) {
    return 'Offload opens no internet addresses: $address';
  }

  @override
  String get helpCopy => 'Copy';

  @override
  String get syntaxOverviewManual => 'More in the manual';

  @override
  String get storageAttachments => 'Attachments';

  @override
  String storageAttachmentKind(String kind, String size) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'photo': 'Photos',
      'audio': 'Audio',
      'other': 'Other',
    });
    return '$_temp0 $size';
  }

  @override
  String get photoAdd => 'Add photo';

  @override
  String get photoAddOpen => 'Add photo…';

  @override
  String get photoTake => 'Take photo';

  @override
  String get photoFromGallery => 'From gallery';

  @override
  String get photoFileTypeName => 'Images';

  @override
  String photosHeader(int count) {
    return 'Photos · $count';
  }

  @override
  String get photoProcessing => 'Processing photo…';

  @override
  String get photoUnreadable => 'Offload cannot read this photo.';

  @override
  String get photoTooLarge => 'This photo is too large.';

  @override
  String get photoSourceFailed => 'The photo could not be opened.';

  @override
  String get photoSaveFailed => 'The photo was not saved.';

  @override
  String photoSemantics(int index, int count) {
    return 'Photo $index of $count';
  }

  @override
  String get photoView => 'View';

  @override
  String get photoDelete => 'Delete';

  @override
  String get photoDeleteTitle => 'Delete photo?';

  @override
  String get photoDeleteBody =>
      'The photo is removed from this item. This cannot be undone.';

  @override
  String get photoDeleteCancel => 'Cancel';

  @override
  String get photoDeleteFailed => 'The photo was not deleted.';

  @override
  String get photoMissing => 'Attachment not in this backup';
}
