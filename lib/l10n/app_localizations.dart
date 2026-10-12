import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_nl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('nl'),
  ];

  /// Name of the app, shown in the title bar and the task switcher.
  ///
  /// In nl, this message translates to:
  /// **'Offload'**
  String get appTitle;

  /// Name of this language in the language itself (endonym), shown as an option in the language picker. Never translate it into another language.
  ///
  /// In nl, this message translates to:
  /// **'Nederlands'**
  String get languageName;

  /// Tooltip and screen-reader label of the gear button that opens Settings.
  ///
  /// In nl, this message translates to:
  /// **'Instellingen openen'**
  String get openSettingsTooltip;

  /// Title of the Settings screen.
  ///
  /// In nl, this message translates to:
  /// **'Instellingen'**
  String get settingsTitle;

  /// Section header above the language choice in Settings.
  ///
  /// In nl, this message translates to:
  /// **'Taal'**
  String get settingsLanguageHeader;

  /// Language option that follows the language of the device.
  ///
  /// In nl, this message translates to:
  /// **'Systeemtaal'**
  String get settingsLanguageSystem;

  /// Explanation under the system-language option: the app falls back to English when the device language is not offered.
  ///
  /// In nl, this message translates to:
  /// **'Volgt de taal van het toestel; is die niet beschikbaar, dan Engels'**
  String get settingsLanguageSystemHint;

  /// Screen-reader label of the progress indicator while the encrypted storage opens.
  ///
  /// In nl, this message translates to:
  /// **'Offload wordt gestart'**
  String get startupLoading;

  /// Title of the start-up error when data exists but its encryption key is missing.
  ///
  /// In nl, this message translates to:
  /// **'Sleutel ontbreekt'**
  String get startupMissingKeyTitle;

  /// Explanation of the missing-key start-up error. Must say that nothing was changed.
  ///
  /// In nl, this message translates to:
  /// **'Er staan gegevens van Offload op dit apparaat, maar de sleutel om ze te openen ontbreekt. Offload maakt geen nieuwe sleutel aan, want dan worden je gegevens voorgoed onleesbaar. Er is niets gewijzigd.'**
  String get startupMissingKeyBody;

  /// Title of the start-up error when the stored key cannot be read.
  ///
  /// In nl, this message translates to:
  /// **'Sleutel niet leesbaar'**
  String get startupKeyUnavailableTitle;

  /// Explanation of the unreadable-key start-up error.
  ///
  /// In nl, this message translates to:
  /// **'De sleutel van Offload is aanwezig, maar kan nu niet worden gelezen. Er is niets gewijzigd. Probeer het opnieuw of start het apparaat opnieuw op.'**
  String get startupKeyUnavailableBody;

  /// Title of the start-up error when the encrypted database cannot be opened.
  ///
  /// In nl, this message translates to:
  /// **'Gegevens niet te openen'**
  String get startupDatabaseTitle;

  /// Explanation of the database start-up error.
  ///
  /// In nl, this message translates to:
  /// **'De gegevens van Offload kunnen niet worden geopend. Er is niets verwijderd.'**
  String get startupDatabaseBody;

  /// Title of an unexpected start-up error.
  ///
  /// In nl, this message translates to:
  /// **'Offload kan niet starten'**
  String get startupUnexpectedTitle;

  /// Explanation of an unexpected start-up error.
  ///
  /// In nl, this message translates to:
  /// **'Er ging iets mis bij het starten. Er is niets verwijderd.'**
  String get startupUnexpectedBody;

  /// Technical error text under a start-up error, for support.
  ///
  /// In nl, this message translates to:
  /// **'Technische details: {details}'**
  String startupErrorDetails(String details);

  /// Button that retries opening the storage after a start-up error.
  ///
  /// In nl, this message translates to:
  /// **'Opnieuw proberen'**
  String get startupRetry;

  /// Message when the chosen language could not be stored; the choice still applies until the app restarts.
  ///
  /// In nl, this message translates to:
  /// **'De taalkeuze kon niet worden bewaard'**
  String get settingsLanguageSaveFailed;

  /// Title of the inbox: captured items that are not processed yet.
  ///
  /// In nl, this message translates to:
  /// **'Inbox'**
  String get inboxTitle;

  /// Number of items in the inbox; the zero form is also the text of the empty inbox.
  ///
  /// In nl, this message translates to:
  /// **'{count, plural, =0{Nog geen items} =1{1 item} other{{count} items}}'**
  String inboxItemCount(int count);

  /// When an inbox item was captured, in local time and the active language. Both placeholders get the same moment.
  ///
  /// In nl, this message translates to:
  /// **'{date}, {time}'**
  String inboxCapturedAt(DateTime date, DateTime time);

  /// Shown instead of the inbox when reading it fails.
  ///
  /// In nl, this message translates to:
  /// **'De inbox kan niet worden geladen. Er is niets verwijderd.'**
  String get inboxLoadFailed;

  /// Button on the inbox that opens quick capture.
  ///
  /// In nl, this message translates to:
  /// **'Vastleggen'**
  String get captureAction;

  /// Title of the quick-capture screen.
  ///
  /// In nl, this message translates to:
  /// **'Vastleggen'**
  String get captureTitle;

  /// Placeholder in the empty quick-capture field.
  ///
  /// In nl, this message translates to:
  /// **'Wat heb je in je hoofd?'**
  String get captureHint;

  /// Tooltip and screen-reader label of the button that saves the captured text.
  ///
  /// In nl, this message translates to:
  /// **'Opslaan'**
  String get captureSave;

  /// Shown under the capture field when saving fails. Must say the text was kept.
  ///
  /// In nl, this message translates to:
  /// **'Opslaan is mislukt. Je tekst staat er nog; probeer het opnieuw.'**
  String get captureSaveFailed;

  /// Description of the capture widget in the Android widget picker. Android resource, generated by tool/gen_android_strings.dart; no placeholders.
  ///
  /// In nl, this message translates to:
  /// **'Leg met één tik een gedachte vast'**
  String get androidWidgetDescription;

  /// Text next to the icon when the capture widget is made wide (DD-019). Android resource, generated by tool/gen_android_strings.dart; no placeholders.
  ///
  /// In nl, this message translates to:
  /// **'Leg iets vast…'**
  String get androidWidgetHint;

  /// Note in the inbox when captures from the widget could not be read. They are kept in quarantine, never deleted.
  ///
  /// In nl, this message translates to:
  /// **'{count, plural, =1{1 vastgelegd item kon niet worden gelezen. Het is apart bewaard, niet verwijderd.} other{{count} vastgelegde items konden niet worden gelezen. Ze zijn apart bewaard, niet verwijderd.}}'**
  String captureUnreadable(int count);

  /// Note in the inbox when captures waiting outside the app could not be fetched. Nothing is lost; the app tries again when it comes back.
  ///
  /// In nl, this message translates to:
  /// **'Items uit de widget konden nog niet worden opgehaald. Ze blijven bewaard; Offload probeert het opnieuw.'**
  String get captureFetchFailed;

  /// Tooltip and screen-reader label of the button that closes a note.
  ///
  /// In nl, this message translates to:
  /// **'Sluiten'**
  String get noticeDismiss;

  /// Windows system-tray menu item that opens quick capture.
  ///
  /// In nl, this message translates to:
  /// **'Nieuw item'**
  String get trayNewItem;

  /// Windows system-tray menu item that shows the Offload window.
  ///
  /// In nl, this message translates to:
  /// **'Openen'**
  String get trayOpen;

  /// Windows system-tray menu item that really quits Offload (closing the window only hides it to the tray).
  ///
  /// In nl, this message translates to:
  /// **'Afsluiten'**
  String get trayQuit;

  /// Note in the inbox (Windows) when the global capture shortcut could not be registered because another program uses it.
  ///
  /// In nl, this message translates to:
  /// **'De sneltoets Win+Shift+B is al in gebruik door een ander programma. Vastleggen kan via het systeemvak of met de knop Vastleggen.'**
  String get hotkeyUnavailable;

  /// Section in Settings for making and restoring backups and for the export (T7.1, T7.2, T7.3).
  ///
  /// In nl, this message translates to:
  /// **'Back-up en export'**
  String get settingsBackupHeader;

  /// Row in Settings → Back-up that sets or changes the backup passphrase.
  ///
  /// In nl, this message translates to:
  /// **'Wachtwoordzin'**
  String get backupPassphraseRow;

  /// Second line of the passphrase row when a passphrase is set.
  ///
  /// In nl, this message translates to:
  /// **'Ingesteld'**
  String get backupPassphraseSet;

  /// Second line of the passphrase row when none is set yet.
  ///
  /// In nl, this message translates to:
  /// **'Nog niet ingesteld: nodig voor een back-up'**
  String get backupPassphraseNotSet;

  /// Title of the dialog that sets the backup passphrase.
  ///
  /// In nl, this message translates to:
  /// **'Wachtwoordzin voor back-ups'**
  String get backupPassphraseTitle;

  /// Label of the first passphrase field.
  ///
  /// In nl, this message translates to:
  /// **'Wachtwoordzin'**
  String get backupPassphraseField;

  /// Label of the field that repeats the passphrase.
  ///
  /// In nl, this message translates to:
  /// **'Nog een keer'**
  String get backupPassphraseRepeat;

  /// Explanation under the passphrase fields (PO decision: at least 12 characters).
  ///
  /// In nl, this message translates to:
  /// **'Minstens {min} tekens, bijvoorbeeld vier losse woorden. Je typt hem alleen als je een back-up op een ander toestel terugzet.'**
  String backupPassphraseHint(int min);

  /// Error when the repeated passphrase differs.
  ///
  /// In nl, this message translates to:
  /// **'De twee zijn niet gelijk'**
  String get backupPassphraseMismatch;

  /// Error when the passphrase is too short.
  ///
  /// In nl, this message translates to:
  /// **'Minstens {min} tekens'**
  String backupPassphraseTooShort(int min);

  /// Error when the passphrase holds a control character.
  ///
  /// In nl, this message translates to:
  /// **'Zonder tab of nieuwe regel'**
  String get backupPassphraseInvalid;

  /// Strength indicator of the passphrase, a rough guide on length and variety.
  ///
  /// In nl, this message translates to:
  /// **'Sterkte: {level}'**
  String backupStrength(String level);

  /// Strength level: below the minimum.
  ///
  /// In nl, this message translates to:
  /// **'te kort'**
  String get backupStrengthTooShort;

  /// Strength level.
  ///
  /// In nl, this message translates to:
  /// **'redelijk'**
  String get backupStrengthFair;

  /// Strength level.
  ///
  /// In nl, this message translates to:
  /// **'goed'**
  String get backupStrengthGood;

  /// Strength level.
  ///
  /// In nl, this message translates to:
  /// **'sterk'**
  String get backupStrengthStrong;

  /// The explicit warning of AC REQ-026, to be confirmed.
  ///
  /// In nl, this message translates to:
  /// **'Zonder deze wachtwoordzin kan een back-up niet worden teruggezet, ook niet door de app.'**
  String get backupPassphraseWarning;

  /// Checkbox that confirms the warning; saving needs it.
  ///
  /// In nl, this message translates to:
  /// **'Ik begrijp het'**
  String get backupPassphraseWarningConfirm;

  /// Note when changing an existing passphrase (AC REQ-026).
  ///
  /// In nl, this message translates to:
  /// **'Oudere back-ups houden hun oude wachtwoordzin.'**
  String get backupPassphraseChangeNote;

  /// Tooltip of the eye button that shows or hides the passphrase.
  ///
  /// In nl, this message translates to:
  /// **'Wachtwoordzin tonen'**
  String get backupPassphraseShow;

  /// Button that saves the passphrase.
  ///
  /// In nl, this message translates to:
  /// **'Opslaan'**
  String get backupSave;

  /// Button that closes a backup dialog without changes.
  ///
  /// In nl, this message translates to:
  /// **'Annuleren'**
  String get backupCancel;

  /// Message after saving the passphrase.
  ///
  /// In nl, this message translates to:
  /// **'Wachtwoordzin opgeslagen'**
  String get backupPassphraseSaved;

  /// Row in Settings → Back-up that makes a backup.
  ///
  /// In nl, this message translates to:
  /// **'Back-up maken'**
  String get backupMake;

  /// Second line of the row Back-up maken.
  ///
  /// In nl, this message translates to:
  /// **'Alles versleuteld in één bestand; je kiest zelf waar'**
  String get backupMakeSubtitle;

  /// Name of the file type in the save and open windows.
  ///
  /// In nl, this message translates to:
  /// **'Offload-back-up'**
  String get backupFileType;

  /// Proposed file name, without extension; the date as year-month-day.
  ///
  /// In nl, this message translates to:
  /// **'Offload-back-up-{date}'**
  String backupFileName(String date);

  /// Shown while a backup is made or read.
  ///
  /// In nl, this message translates to:
  /// **'Even geduld…'**
  String get backupBusy;

  /// Message after a backup was saved.
  ///
  /// In nl, this message translates to:
  /// **'Back-up gemaakt'**
  String get backupMade;

  /// Message when making a backup failed; nothing was saved.
  ///
  /// In nl, this message translates to:
  /// **'De back-up is niet gelukt'**
  String get backupFailed;

  /// Settings → Backup and export: row that starts an export (T7.3).
  ///
  /// In nl, this message translates to:
  /// **'Exporteren'**
  String get exportRow;

  /// Second line of the row Exporteren.
  ///
  /// In nl, this message translates to:
  /// **'Leesbaar, niet versleuteld (Markdown of JSON)'**
  String get exportRowSubtitle;

  /// Title of the dialog that chooses the export format and shows the warning.
  ///
  /// In nl, this message translates to:
  /// **'Exporteren'**
  String get exportDialogTitle;

  /// Warning in the export dialog, confirmed every time by the export button (PO 09-10-2026).
  ///
  /// In nl, this message translates to:
  /// **'Deze export is niet versleuteld. Iedereen met het bestand kan alles lezen.'**
  String get exportWarning;

  /// Export format choice: a readable text file.
  ///
  /// In nl, this message translates to:
  /// **'Markdown'**
  String get exportMarkdown;

  /// Second line of the Markdown choice.
  ///
  /// In nl, this message translates to:
  /// **'Leesbaar, in elke teksteditor'**
  String get exportMarkdownHint;

  /// Export format choice: structured data for other programs.
  ///
  /// In nl, this message translates to:
  /// **'JSON'**
  String get exportJson;

  /// Second line of the JSON choice.
  ///
  /// In nl, this message translates to:
  /// **'Gestructureerd, voor andere programma\'s'**
  String get exportJsonHint;

  /// Button in the export dialog: confirms the warning and starts the export.
  ///
  /// In nl, this message translates to:
  /// **'Exporteren'**
  String get exportConfirm;

  /// Proposed name of an export file, without extension; date is year-month-day.
  ///
  /// In nl, this message translates to:
  /// **'Offload-export-{date}'**
  String exportFileName(String date);

  /// File type name in the Windows save window for a Markdown export.
  ///
  /// In nl, this message translates to:
  /// **'Markdown-bestand'**
  String get exportMarkdownFileType;

  /// File type name in the Windows save window for a JSON export.
  ///
  /// In nl, this message translates to:
  /// **'JSON-bestand'**
  String get exportJsonFileType;

  /// Message after an export was saved.
  ///
  /// In nl, this message translates to:
  /// **'Export opgeslagen'**
  String get exportSaved;

  /// Message after the export was handed to the share menu; Android does not say whether it was sent.
  ///
  /// In nl, this message translates to:
  /// **'Export klaargezet om te delen'**
  String get exportReadyToShare;

  /// Message when an export failed; nothing was saved.
  ///
  /// In nl, this message translates to:
  /// **'De export is niet gelukt'**
  String get exportFailed;

  /// Markdown export: the title at the top of the file.
  ///
  /// In nl, this message translates to:
  /// **'Offload-export'**
  String get exportTitle;

  /// Markdown export: when it was made, local time. Both placeholders get the same moment.
  ///
  /// In nl, this message translates to:
  /// **'Gemaakt op {date}, {time}'**
  String exportMadeOn(DateTime date, DateTime time);

  /// Markdown export: the numbers under the title.
  ///
  /// In nl, this message translates to:
  /// **'Items: {items} · projecten: {projects} · personen: {people}'**
  String exportCounts(int items, int projects, int people);

  /// Markdown export: heading of the projects.
  ///
  /// In nl, this message translates to:
  /// **'Projecten'**
  String get exportProjects;

  /// Markdown export: heading of the items without a project.
  ///
  /// In nl, this message translates to:
  /// **'Zonder project'**
  String get exportWithoutProject;

  /// Markdown export: heading of the people.
  ///
  /// In nl, this message translates to:
  /// **'Personen'**
  String get exportPeople;

  /// Markdown export: after the name of an archived project, in brackets.
  ///
  /// In nl, this message translates to:
  /// **'gearchiveerd'**
  String get exportArchived;

  /// Markdown export: the deadline of an item, in its line of facts.
  ///
  /// In nl, this message translates to:
  /// **'deadline {date}'**
  String exportDue(DateTime date);

  /// Markdown export: when a parked item comes back.
  ///
  /// In nl, this message translates to:
  /// **'terugzien op {date}'**
  String exportRevisit(DateTime date);

  /// Markdown export: who asked for the item.
  ///
  /// In nl, this message translates to:
  /// **'gevraagd door {name}'**
  String exportRequester(String name);

  /// Markdown export: whom the item waits for.
  ///
  /// In nl, this message translates to:
  /// **'wacht op {name}'**
  String exportWaitingOn(String name);

  /// Markdown export: the day it was asked (commitment).
  ///
  /// In nl, this message translates to:
  /// **'gevraagd op {date}'**
  String exportAsked(DateTime date);

  /// Markdown export: what was promised.
  ///
  /// In nl, this message translates to:
  /// **'toegezegd: {text}'**
  String exportPromise(String text);

  /// Markdown export: the day a waiting item is expected.
  ///
  /// In nl, this message translates to:
  /// **'verwacht op {date}'**
  String exportExpected(DateTime date);

  /// Markdown export: the day the item was captured.
  ///
  /// In nl, this message translates to:
  /// **'vastgelegd {date}'**
  String exportCaptured(DateTime date);

  /// Markdown export: the next step of an open Where was I note.
  ///
  /// In nl, this message translates to:
  /// **'Waar was ik, volgende stap: {text}'**
  String exportNextStep(String text);

  /// Markdown export: what was in mind in an open Where was I note.
  ///
  /// In nl, this message translates to:
  /// **'Waar was ik, in mijn hoofd: {text}'**
  String exportInMind(String text);

  /// Markdown export: the completed times of a recurring task; dates is a list of dates.
  ///
  /// In nl, this message translates to:
  /// **'Gedaan: {dates}'**
  String exportCompletions(String dates);

  /// Markdown export: one date in a list of dates.
  ///
  /// In nl, this message translates to:
  /// **'{date}'**
  String exportDay(DateTime date);

  /// Markdown export: the other names of a person.
  ///
  /// In nl, this message translates to:
  /// **'Ook: {aliases}'**
  String exportAliases(String aliases);

  /// Markdown export: a birthday with a year.
  ///
  /// In nl, this message translates to:
  /// **'Verjaardag: {date}'**
  String exportBirthday(DateTime date);

  /// Markdown export: a birthday without a year.
  ///
  /// In nl, this message translates to:
  /// **'Verjaardag: {date}'**
  String exportBirthdayNoYear(DateTime date);

  /// Markdown export: organisation and job title of a person.
  ///
  /// In nl, this message translates to:
  /// **'Werk: {text}'**
  String exportWork(String text);

  /// Markdown export: the kind of a contact detail with its label, e.g. 'Telefoonnummer (werk)'.
  ///
  /// In nl, this message translates to:
  /// **'{kind} ({label})'**
  String exportContact(String kind, String label);

  /// Settings: header of the section that shows what Offload keeps on this device (T7.5).
  ///
  /// In nl, this message translates to:
  /// **'Opslag'**
  String get settingsStorageHeader;

  /// Settings → Storage: row of the encrypted database.
  ///
  /// In nl, this message translates to:
  /// **'Database'**
  String get storageDatabase;

  /// Settings → Storage: second line of the database row.
  ///
  /// In nl, this message translates to:
  /// **'Versleuteld: alles wat je hebt vastgelegd'**
  String get storageDatabaseHint;

  /// Settings → Storage: row of Offload's own temporary copies (Android).
  ///
  /// In nl, this message translates to:
  /// **'Tijdelijke bestanden'**
  String get storageTemporary;

  /// Settings → Storage: second line of the temporary files row.
  ///
  /// In nl, this message translates to:
  /// **'Een gedeelde back-up of export; gaat na een dag weg'**
  String get storageTemporaryHint;

  /// Settings → Storage: row with the numbers of items, projects and people.
  ///
  /// In nl, this message translates to:
  /// **'Inhoud'**
  String get storageContent;

  /// Settings → Storage: the number of items, the trash included.
  ///
  /// In nl, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String storageItems(int count);

  /// Settings → Storage: after the number of items, when some are in the trash.
  ///
  /// In nl, this message translates to:
  /// **'waarvan {count} in de prullenbak'**
  String storageTrashed(int count);

  /// Settings → Storage: the number of projects.
  ///
  /// In nl, this message translates to:
  /// **'{count, plural, =1{1 project} other{{count} projecten}}'**
  String storageProjects(int count);

  /// Settings → Storage: the number of people.
  ///
  /// In nl, this message translates to:
  /// **'{count, plural, =1{1 persoon} other{{count} personen}}'**
  String storagePeople(int count);

  /// Settings → Storage: a size in kilobytes (1000 bytes), whole.
  ///
  /// In nl, this message translates to:
  /// **'{value} kB'**
  String storageKilobytes(double value);

  /// Settings → Storage: a size in megabytes, one decimal.
  ///
  /// In nl, this message translates to:
  /// **'{value} MB'**
  String storageMegabytes(double value);

  /// Settings → Storage: a size in gigabytes, one decimal.
  ///
  /// In nl, this message translates to:
  /// **'{value} GB'**
  String storageGigabytes(double value);

  /// Settings → Storage: shown when the sizes could not be read.
  ///
  /// In nl, this message translates to:
  /// **'Niet te bepalen'**
  String get storageUnavailable;

  /// Settings → Storage: joins two parts of the content line.
  ///
  /// In nl, this message translates to:
  /// **'{first} · {second}'**
  String storageJoin(String first, String second);

  /// Settings → Storage: the number of items followed by how many are in the trash.
  ///
  /// In nl, this message translates to:
  /// **'{items}, {trashed}'**
  String storageWithTrash(String items, String trashed);

  /// Choice when making a backup on Android: hand the encrypted backup file to another app through the share menu (DD-014).
  ///
  /// In nl, this message translates to:
  /// **'Delen…'**
  String get backupShare;

  /// Choice when making a backup on Android: save the file with the system document picker.
  ///
  /// In nl, this message translates to:
  /// **'Opslaan op dit toestel…'**
  String get backupSaveOnDevice;

  /// Message after the backup was handed to the share menu; Android does not say whether it was really sent.
  ///
  /// In nl, this message translates to:
  /// **'Back-up klaargezet om te delen'**
  String get backupReadyToShare;

  /// Row in Settings → Back-up that restores a backup.
  ///
  /// In nl, this message translates to:
  /// **'Back-up terugzetten'**
  String get backupRestore;

  /// Second line of the row Back-up terugzetten.
  ///
  /// In nl, this message translates to:
  /// **'Vervangt alles op dit toestel'**
  String get backupRestoreSubtitle;

  /// Title of the dialog asking the passphrase when this device's own does not open the backup.
  ///
  /// In nl, this message translates to:
  /// **'Wachtwoordzin van deze back-up'**
  String get backupRestoreAskTitle;

  /// Explanation in the dialog that asks the passphrase of a backup.
  ///
  /// In nl, this message translates to:
  /// **'Deze back-up is gemaakt met een andere wachtwoordzin, of op een ander toestel.'**
  String get backupRestoreAskBody;

  /// Button that tries the typed passphrase.
  ///
  /// In nl, this message translates to:
  /// **'Openen'**
  String get backupRestoreAskOk;

  /// Error when the passphrase does not open the file.
  ///
  /// In nl, this message translates to:
  /// **'Deze wachtwoordzin past niet, of het bestand is geen back-up van Offload.'**
  String get backupWrongPassphrase;

  /// Error for a backup of a newer app version.
  ///
  /// In nl, this message translates to:
  /// **'Deze back-up komt van een nieuwere versie van Offload. Werk de app eerst bij.'**
  String get backupTooNew;

  /// Error when the file could not be read or written.
  ///
  /// In nl, this message translates to:
  /// **'Het bestand kon niet worden gelezen of geschreven.'**
  String get backupUnreadable;

  /// Title of the confirmation before restoring.
  ///
  /// In nl, this message translates to:
  /// **'Alles vervangen?'**
  String get backupRestoreConfirmTitle;

  /// Body of the confirmation before restoring; the date of the newest change in the backup.
  ///
  /// In nl, this message translates to:
  /// **'{count, plural, =1{Deze back-up bevat 1 item} other{Deze back-up bevat {count} items}}, laatst gewijzigd op {date}. Alles wat nu op dit toestel staat, wordt vervangen; je instellingen blijven. Dit is een kopie, geen synchronisatie.'**
  String backupRestoreConfirmBody(int count, DateTime date);

  /// Body of the confirmation before restoring a backup that records no change (so no date).
  ///
  /// In nl, this message translates to:
  /// **'{count, plural, =1{Deze back-up bevat 1 item} other{Deze back-up bevat {count} items}}. Alles wat nu op dit toestel staat, wordt vervangen; je instellingen blijven. Dit is een kopie, geen synchronisatie.'**
  String backupRestoreConfirmBodyUndated(int count);

  /// Button that restores, replacing everything.
  ///
  /// In nl, this message translates to:
  /// **'Terugzetten'**
  String get backupRestoreConfirm;

  /// Button that goes on from the choice with or without attachments to saving the backup.
  ///
  /// In nl, this message translates to:
  /// **'Verder'**
  String get backupOptionsContinue;

  /// Switch when making a backup: include the attachments; the size is their total on this device now.
  ///
  /// In nl, this message translates to:
  /// **'Met bijlagen (≈ {size})'**
  String backupWithAttachments(String size);

  /// Line under the switch with or without attachments.
  ///
  /// In nl, this message translates to:
  /// **'Zonder bijlagen is de back-up kleiner, maar zitten ze er niet in.'**
  String get backupWithAttachmentsHint;

  /// Progress while a backup is made or restored, e.g. '12 MB van 85 MB'.
  ///
  /// In nl, this message translates to:
  /// **'{done} van {total}'**
  String backupProgress(String done, String total);

  /// Message after a backup was made or shared while some attachment files were missing or damaged; message is the usual message.
  ///
  /// In nl, this message translates to:
  /// **'{message}. {count, plural, =1{1 bijlage ontbrak en zit er niet in.} other{{count} bijlagen ontbraken en zitten er niet in.}}'**
  String backupMissingNote(String message, int count);

  /// Message when there is too little free space to make or restore a backup; nothing was changed.
  ///
  /// In nl, this message translates to:
  /// **'Niet genoeg vrije ruimte: nodig ongeveer {needed}, vrij {free}.'**
  String backupNoRoom(String needed, String free);

  /// Line in the restore confirmation: how many attachments the backup holds.
  ///
  /// In nl, this message translates to:
  /// **'{count, plural, =1{Met 1 bijlage.} other{Met {count} bijlagen.}}'**
  String backupRestoreWithAttachments(int count);

  /// Warning in the restore confirmation when the backup was made without attachments and this device has some.
  ///
  /// In nl, this message translates to:
  /// **'Deze back-up heeft geen bijlagen; bijlagen die niet bij de teruggezette items horen, verdwijnen.'**
  String get backupRestoreNoAttachments;

  /// Title shown once after start when a restored backup could not be opened and the previous data came back.
  ///
  /// In nl, this message translates to:
  /// **'Terugzetten niet gelukt'**
  String get restoreUndoneTitle;

  /// Body of that message.
  ///
  /// In nl, this message translates to:
  /// **'De teruggezette back-up kon niet worden geopend. Je gegevens van vóór het terugzetten zijn er weer; er is niets verloren.'**
  String get restoreUndoneBody;

  /// Button that closes that message.
  ///
  /// In nl, this message translates to:
  /// **'OK'**
  String get restoreUndoneOk;

  /// Section header at the top of Settings with the version and build of the app.
  ///
  /// In nl, this message translates to:
  /// **'Over Offload'**
  String get settingsAboutHeader;

  /// Row in the section About Offload of Settings that opens the screen About Offload (REQ-062).
  ///
  /// In nl, this message translates to:
  /// **'Waarvoor Offload is en de licenties'**
  String get aboutOpen;

  /// What Offload is for, on the screen About Offload (text decided by the PO 03-10-2026, REQ-062).
  ///
  /// In nl, this message translates to:
  /// **'Offload maakt je hoofd leeg. Lopend werk, wat nog komt, ideeën en verzoeken van anderen leg je in een paar seconden vast, en je verwerkt ze als het jou uitkomt. Alles blijft op je eigen apparaat, versleuteld en zonder internet.'**
  String get aboutPurpose;

  /// Row on About Offload naming the licence of the app; tapping shows its full text.
  ///
  /// In nl, this message translates to:
  /// **'Licentie'**
  String get aboutLicenceTitle;

  /// The licence of Offload (GPL-3.0-or-later, Q37), under the row Licentie.
  ///
  /// In nl, this message translates to:
  /// **'GNU GPL 3.0 of later'**
  String get aboutLicenceName;

  /// Shown instead of the licence text when the bundled file could not be read.
  ///
  /// In nl, this message translates to:
  /// **'De licentietekst kon niet worden geladen'**
  String get aboutLicenceFailed;

  /// Row on About Offload that opens Flutter's licence overview: every shipped package, library and typeface.
  ///
  /// In nl, this message translates to:
  /// **'Licenties van onderdelen'**
  String get aboutComponentsTitle;

  /// Second line of the row Licenties van onderdelen.
  ///
  /// In nl, this message translates to:
  /// **'Pakketten, bibliotheken en lettertypen in de app'**
  String get aboutComponentsSubtitle;

  /// Version of the app in Settings.
  ///
  /// In nl, this message translates to:
  /// **'Versie {version} (build {buildNumber})'**
  String settingsVersion(String version, String buildNumber);

  /// Moment the app was built, in local time and the active language. Both placeholders get the same moment.
  ///
  /// In nl, this message translates to:
  /// **'Gebouwd op {date}, {time}'**
  String settingsBuiltAt(DateTime date, DateTime time);

  /// Shown in Settings instead of version and build moment for a build made without build information (development).
  ///
  /// In nl, this message translates to:
  /// **'Ontwikkelversie'**
  String get settingsDevelopmentBuild;

  /// Date word of the inline syntax after '!' (DD-004), in lowercase without spaces. Several words may be given, separated by commas. Means today.
  ///
  /// In nl, this message translates to:
  /// **'vandaag'**
  String get tokenDateToday;

  /// Date word of the inline syntax after '!' (DD-004), in lowercase without spaces. Several words may be given, separated by commas. Means tomorrow.
  ///
  /// In nl, this message translates to:
  /// **'morgen'**
  String get tokenDateTomorrow;

  /// Date word of the inline syntax after '!' (DD-004), in lowercase without spaces. Several words may be given, separated by commas. Means the day after tomorrow.
  ///
  /// In nl, this message translates to:
  /// **'overmorgen'**
  String get tokenDateDayAfterTomorrow;

  /// Date word of the inline syntax after '!' (DD-004), in lowercase without spaces. Several words may be given, separated by commas. Means Monday of next week.
  ///
  /// In nl, this message translates to:
  /// **'volgendeweek'**
  String get tokenDateNextWeek;

  /// Priority word of the inline syntax after '*' (DD-004 point 3), in lowercase without spaces. Several words may be given, separated by commas. Means high priority; '*1' works in every language.
  ///
  /// In nl, this message translates to:
  /// **'hoog'**
  String get tokenPriorityHigh;

  /// Priority word of the inline syntax after '*' (DD-004 point 3), in lowercase without spaces. Several words may be given, separated by commas. Means low priority; '*3' works in every language.
  ///
  /// In nl, this message translates to:
  /// **'laag'**
  String get tokenPriorityLow;

  /// Short weekday words of the inline syntax after '!' (DD-004): exactly seven, comma-separated, lowercase, Monday first. A weekday means the next such day, never today.
  ///
  /// In nl, this message translates to:
  /// **'ma,di,wo,do,vr,za,zo'**
  String get tokenWeekdaysShort;

  /// Full weekday words of the inline syntax after '!' (DD-004): exactly seven, comma-separated, lowercase, Monday first.
  ///
  /// In nl, this message translates to:
  /// **'maandag,dinsdag,woensdag,donderdag,vrijdag,zaterdag,zondag'**
  String get tokenWeekdaysLong;

  /// Name of the person token (@) for chips, screen readers and later the prefix bar.
  ///
  /// In nl, this message translates to:
  /// **'persoon'**
  String get tokenPersonLabel;

  /// Name of the tag token (#) for chips, screen readers and later the prefix bar.
  ///
  /// In nl, this message translates to:
  /// **'tag'**
  String get tokenTagLabel;

  /// Name of the date token (!) for chips, screen readers and later the prefix bar.
  ///
  /// In nl, this message translates to:
  /// **'datum'**
  String get tokenDateLabel;

  /// The recognised date on a chip under the capture field, short, in the active language.
  ///
  /// In nl, this message translates to:
  /// **'{date}'**
  String tokenDateChip(DateTime date);

  /// Screen-reader label of a recognised token chip, e.g. 'datum: vr 2 okt'.
  ///
  /// In nl, this message translates to:
  /// **'{kind}: {value}'**
  String tokenChipSemantics(String kind, String value);

  /// Name of a recognised token of a type without its own name (fallback, for screen readers).
  ///
  /// In nl, this message translates to:
  /// **'herkend woord'**
  String get tokenOtherLabel;

  /// Line in the suggestion list that adds a person or tag not known yet; it is created when the item is saved.
  ///
  /// In nl, this message translates to:
  /// **'Nieuw: {name}'**
  String tokenSuggestionNew(String name);

  /// Header of the settings section about capturing text.
  ///
  /// In nl, this message translates to:
  /// **'Invoer'**
  String get settingsInputHeader;

  /// Title above the prefix bar options: the bar with @, # and ! buttons in quick capture.
  ///
  /// In nl, this message translates to:
  /// **'Prefix-balk'**
  String get settingsPrefixBar;

  /// Explains the prefix bar in Settings. Does not list the signs: the bar grows with new token types.
  ///
  /// In nl, this message translates to:
  /// **'Knoppen voor de invoertekens bij het vastleggen'**
  String get settingsPrefixBarHint;

  /// Prefix bar option: always shown with sign and label (default).
  ///
  /// In nl, this message translates to:
  /// **'Altijd zichtbaar'**
  String get settingsPrefixBarAlways;

  /// Prefix bar option: one slim row with only the signs, expandable.
  ///
  /// In nl, this message translates to:
  /// **'Ingeklapt'**
  String get settingsPrefixBarCollapsed;

  /// Explains the collapsed prefix bar option.
  ///
  /// In nl, this message translates to:
  /// **'Eén smalle regel met alleen de tekens, uit te klappen'**
  String get settingsPrefixBarCollapsedHint;

  /// Prefix bar option: no bar.
  ///
  /// In nl, this message translates to:
  /// **'Uit'**
  String get settingsPrefixBarOff;

  /// Shown when the prefix bar setting could not be stored; it still applies until restart.
  ///
  /// In nl, this message translates to:
  /// **'De instelling van de prefix-balk kon niet worden bewaard'**
  String get settingsPrefixBarSaveFailed;

  /// Button in the prefix bar and title in the syntax overview, e.g. '@ persoon'.
  ///
  /// In nl, this message translates to:
  /// **'{sign} {label}'**
  String prefixBarButton(String sign, String label);

  /// Tooltip and screen-reader label of a prefix bar button, e.g. 'persoon invoegen'.
  ///
  /// In nl, this message translates to:
  /// **'{label} invoegen'**
  String prefixBarInsert(String label);

  /// Tooltip of the ? button in the prefix bar.
  ///
  /// In nl, this message translates to:
  /// **'Syntaxoverzicht'**
  String get prefixBarHelp;

  /// Tooltip: show the full prefix bar buttons.
  ///
  /// In nl, this message translates to:
  /// **'Uitklappen'**
  String get prefixBarExpand;

  /// Tooltip: show only the signs in the prefix bar.
  ///
  /// In nl, this message translates to:
  /// **'Inklappen'**
  String get prefixBarCollapse;

  /// Title of the overview of all inline tokens.
  ///
  /// In nl, this message translates to:
  /// **'Syntaxoverzicht'**
  String get syntaxOverviewTitle;

  /// Intro line of the syntax overview.
  ///
  /// In nl, this message translates to:
  /// **'Zet een teken direct voor een woord. Je tekst blijft zoals je hem typt.'**
  String get syntaxOverviewIntro;

  /// Closes the syntax overview.
  ///
  /// In nl, this message translates to:
  /// **'Sluiten'**
  String get syntaxOverviewClose;

  /// Example line for the person token in the syntax overview.
  ///
  /// In nl, this message translates to:
  /// **'Bel @Jan over de offerte'**
  String get tokenPersonExample;

  /// Example line for the tag token in the syntax overview.
  ///
  /// In nl, this message translates to:
  /// **'Dakgoot schoonmaken #klussen'**
  String get tokenTagExample;

  /// Example line for the date token in the syntax overview; use this language's date words.
  ///
  /// In nl, this message translates to:
  /// **'Offerte af !vrijdag, ook !morgen of !12-10'**
  String get tokenDateExample;

  /// Item detail: header of the block with who asked, what was promised and by when, or whom it waits for (T10.1).
  ///
  /// In nl, this message translates to:
  /// **'Toezegging'**
  String get commitmentHeader;

  /// Item detail, commitment block: the day it was asked (by default the day it was captured).
  ///
  /// In nl, this message translates to:
  /// **'Gevraagd op {date}'**
  String commitmentAskedOn(DateTime date);

  /// Item detail, commitment block: what I promised (by default the item title).
  ///
  /// In nl, this message translates to:
  /// **'Beloofd: {text}'**
  String commitmentPromised(String text);

  /// Item detail, commitment block: by when I promised it, the item deadline.
  ///
  /// In nl, this message translates to:
  /// **'Voor: {date}'**
  String commitmentDue(DateTime date);

  /// Item detail, commitment block: no deadline yet; tapping picks one and puts it in the text.
  ///
  /// In nl, this message translates to:
  /// **'Datum toevoegen'**
  String get commitmentDueAdd;

  /// Item detail, commitment block: whom the item waits for.
  ///
  /// In nl, this message translates to:
  /// **'Wacht op {name}'**
  String commitmentWaitsOn(String name);

  /// Item detail, commitment block: a waiting item without a person.
  ///
  /// In nl, this message translates to:
  /// **'Wacht (op niemand in het bijzonder)'**
  String get commitmentWaitsOnNobody;

  /// Item detail, commitment block: by when I expect it, for a waiting item.
  ///
  /// In nl, this message translates to:
  /// **'Verwacht: {date}'**
  String commitmentExpected(DateTime date);

  /// Item detail, commitment block: the expected day has passed; shown in orange with a warning icon.
  ///
  /// In nl, this message translates to:
  /// **'Verwacht: {date} · {days, plural, =1{1 dag} other{{days} dagen}} te laat'**
  String commitmentExpectedLate(DateTime date, int days);

  /// Item detail, commitment block: a waiting item without an expected date.
  ///
  /// In nl, this message translates to:
  /// **'Verwacht op toevoegen'**
  String get commitmentExpectedAdd;

  /// Item detail, commitment block: tooltip of the button that clears a value set by hand (asked on back to the capture day, expected date removed).
  ///
  /// In nl, this message translates to:
  /// **'Terugzetten'**
  String get commitmentReset;

  /// Title of the dialog that edits what was promised.
  ///
  /// In nl, this message translates to:
  /// **'Wat heb je beloofd?'**
  String get commitmentPromiseTitle;

  /// Label of the field in the dialog that edits what was promised.
  ///
  /// In nl, this message translates to:
  /// **'Beloofd'**
  String get commitmentPromiseField;

  /// Help text under the field that edits what was promised.
  ///
  /// In nl, this message translates to:
  /// **'Leeg: de titel van het item.'**
  String get commitmentPromiseHint;

  /// Message when changing a commitment failed.
  ///
  /// In nl, this message translates to:
  /// **'Opslaan is mislukt.'**
  String get commitmentChangeFailed;

  /// Chip on the card of a waiting item: the expected day, still ahead.
  ///
  /// In nl, this message translates to:
  /// **'verwacht {date}'**
  String commitmentExpectedChip(DateTime date);

  /// Chip on the card of a waiting item past its expected day (with a warning icon), and on Today.
  ///
  /// In nl, this message translates to:
  /// **'{days} d te laat'**
  String commitmentLateChip(int days);

  /// Screen-reader text of the late chip.
  ///
  /// In nl, this message translates to:
  /// **'{days, plural, =1{1 dag te laat} other{{days} dagen te laat}}'**
  String commitmentLateChipLabel(int days);

  /// Today: header of the group of waiting items past their expected day (T10.1).
  ///
  /// In nl, this message translates to:
  /// **'Had binnen moeten zijn · {count}'**
  String todayLateSection(int count);

  /// Person sheet when waiting: the optional line that picks by when it is expected.
  ///
  /// In nl, this message translates to:
  /// **'Verwacht op…'**
  String get waitForExpected;

  /// Person sheet when waiting: the expected day picked.
  ///
  /// In nl, this message translates to:
  /// **'Verwacht op {date}'**
  String waitForExpectedDate(DateTime date);

  /// Person sheet when waiting: under the line that picks the expected day.
  ///
  /// In nl, this message translates to:
  /// **'optioneel'**
  String get waitForExpectedOptional;

  /// People: header of the total of open items people asked for (T10.2).
  ///
  /// In nl, this message translates to:
  /// **'Ik moet nog leveren'**
  String get peopleDeliverTitle;

  /// People: the total of open items I deliver and to how many people.
  ///
  /// In nl, this message translates to:
  /// **'{count} aan {people, plural, =1{1 persoon} other{{people} personen}}'**
  String peopleDeliverTotal(int count, int people);

  /// People: header of the total of open items waiting on people.
  ///
  /// In nl, this message translates to:
  /// **'Ik wacht nog op'**
  String get peopleWaitTitle;

  /// People: the total of open items I wait for and from how many people.
  ///
  /// In nl, this message translates to:
  /// **'{count} van {people, plural, =1{1 persoon} other{{people} personen}}'**
  String peopleWaitTotal(int count, int people);

  /// People: legend above the bars, the left (orange) part.
  ///
  /// In nl, this message translates to:
  /// **'← ik lever'**
  String get peopleLegendDeliver;

  /// People: legend above the bars, the right (blue) part.
  ///
  /// In nl, this message translates to:
  /// **'ik wacht →'**
  String get peopleLegendWait;

  /// People: legend above the age column (the oldest open item).
  ///
  /// In nl, this message translates to:
  /// **'oudste'**
  String get peopleLegendOldest;

  /// People: age in days of the oldest open item with a person, short.
  ///
  /// In nl, this message translates to:
  /// **'{days} d'**
  String peopleAge(int days);

  /// People: screen-reader text of a person row with open items.
  ///
  /// In nl, this message translates to:
  /// **'{name}: jij levert {deliver}, jij wacht op {waiting}, oudste {days, plural, =1{1 dag} other{{days} dagen}}'**
  String peopleRowSemantics(String name, int deliver, int waiting, int days);

  /// People: screen-reader text of a row whose oldest item is past the threshold; text is peopleRowSemantics.
  ///
  /// In nl, this message translates to:
  /// **'{text}, oud'**
  String peopleRowSemanticsOld(String text);

  /// Settings: header of the people settings.
  ///
  /// In nl, this message translates to:
  /// **'Personen'**
  String get settingsPeopleHeader;

  /// Settings: from how many days an open item with a person counts as old.
  ///
  /// In nl, this message translates to:
  /// **'Oud na'**
  String get settingsOldAfter;

  /// Settings: explanation under Old after.
  ///
  /// In nl, this message translates to:
  /// **'Vanaf zo veel dagen is een open item bij een persoon oud: het valt op in de balans.'**
  String get settingsOldAfterHint;

  /// Name of the phone-number token (recognised without a sign) for chips, screen readers and the syntax overview.
  ///
  /// In nl, this message translates to:
  /// **'telefoonnummer'**
  String get tokenPhoneLabel;

  /// Example line for the phone-number token in the syntax overview.
  ///
  /// In nl, this message translates to:
  /// **'Bel @Jan op 06-12345678 of +31 6 1234 5678'**
  String get tokenPhoneExample;

  /// Name of the email-address token (recognised without a sign) for chips, screen readers and the syntax overview.
  ///
  /// In nl, this message translates to:
  /// **'e-mailadres'**
  String get tokenEmailLabel;

  /// Example line for the email-address token in the syntax overview.
  ///
  /// In nl, this message translates to:
  /// **'Mail @Jan op jan@example.org'**
  String get tokenEmailExample;

  /// Chip of a phone number or email address in the text, with the one person in the same text it will be added to after saving.
  ///
  /// In nl, this message translates to:
  /// **'{value} → {name}'**
  String tokenContactFor(String value, String name);

  /// Chip of a ^project word that names no project in use (PO decision 03-10-2026): saving does not put the item in a project. In the item detail tapping creates it.
  ///
  /// In nl, this message translates to:
  /// **'{word} · geen project'**
  String tokenProjectNone(String word);

  /// Chip of a ^project word that fits sub-projects under different parents, so it names none; the path (parent/name) from the suggestion list tells them apart.
  ///
  /// In nl, this message translates to:
  /// **'{word} · meerdere projecten'**
  String tokenProjectSeveral(String word);

  /// Tooltip and screen-reader hint of the 'no project' chip in the item detail: tapping asks for the name, creates the project and puts this item in it.
  ///
  /// In nl, this message translates to:
  /// **'Project maken en dit item erin zetten'**
  String get tokenProjectCreateTooltip;

  /// Tooltip and screen-reader hint of a phone-number or email chip in the item detail when the text names no person or several: tapping asks to whom it belongs.
  ///
  /// In nl, this message translates to:
  /// **'Koppelen aan een persoon'**
  String get contactLinkTooltip;

  /// Title of the person sheet that links a phone number or email address from the text to a person.
  ///
  /// In nl, this message translates to:
  /// **'Van wie is dit?'**
  String get contactLinkTitle;

  /// Message after saving: phone numbers or email addresses from the text were added to the person's contact details. Shown with Undo.
  ///
  /// In nl, this message translates to:
  /// **'{count, plural, =1{Toegevoegd aan {name}} other{{count} gegevens toegevoegd aan {name}}}'**
  String contactsTakenFromText(int count, String name);

  /// Message when undoing contact details taken from the text failed.
  ///
  /// In nl, this message translates to:
  /// **'Weghalen is mislukt; de gegevens staan nog bij de persoon.'**
  String get contactsTakenUndoFailed;

  /// Settings: the country of phone numbers typed without a country code.
  ///
  /// In nl, this message translates to:
  /// **'Land voor telefoonnummers'**
  String get settingsPhoneCountry;

  /// Settings: explanation under the country for phone numbers.
  ///
  /// In nl, this message translates to:
  /// **'Voor nummers zonder +landcode, zoals 06-12345678.'**
  String get settingsPhoneCountryHint;

  /// One country in the list of Settings, with its calling code.
  ///
  /// In nl, this message translates to:
  /// **'{country} (+{code})'**
  String settingsCountryOption(String country, String code);

  /// Name of a country by its ISO 3166-1 code, for the list of countries for phone numbers in Settings.
  ///
  /// In nl, this message translates to:
  /// **'{iso, select, NL{Nederland} BE{België} LU{Luxemburg} DE{Duitsland} FR{Frankrijk} GB{Verenigd Koninkrijk} IE{Ierland} ES{Spanje} PT{Portugal} IT{Italië} AT{Oostenrijk} CH{Zwitserland} DK{Denemarken} SE{Zweden} NO{Noorwegen} FI{Finland} IS{IJsland} PL{Polen} CZ{Tsjechië} SK{Slowakije} HU{Hongarije} GR{Griekenland} HR{Kroatië} SI{Slovenië} RO{Roemenië} BG{Bulgarije} EE{Estland} LV{Letland} UA{Oekraïne} TR{Turkije} MA{Marokko} SR{Suriname} ZA{Zuid-Afrika} US{Verenigde Staten} CA{Canada} AU{Australië} NZ{Nieuw-Zeeland} other{{iso}}}'**
  String countryName(String iso);

  /// Name of the project token (^) for chips, screen readers, the prefix bar and the syntax overview.
  ///
  /// In nl, this message translates to:
  /// **'project'**
  String get tokenProjectLabel;

  /// Example line for the project token in the syntax overview: a name without spaces (a dash for a space), and a sub-project after a slash.
  ///
  /// In nl, this message translates to:
  /// **'Kozijnen bestellen ^verbouwing, ook ^oude-schuur of ^verbouwing/keuken'**
  String get tokenProjectExample;

  /// Name of the link token ([[…]], T10.9) for chips, screen readers, the prefix bar ('[[ item') and the syntax overview: it links to another item.
  ///
  /// In nl, this message translates to:
  /// **'item'**
  String get tokenLinkLabel;

  /// Example line for the link token in the syntax overview: the title of another item between double square brackets.
  ///
  /// In nl, this message translates to:
  /// **'Kozijnen bestellen, zie [[Offerte kozijnen vergelijken]]'**
  String get tokenLinkExample;

  /// Second line of an item in the [[ suggestion list: its status and the project it is in.
  ///
  /// In nl, this message translates to:
  /// **'{status} · {project}'**
  String tokenSuggestionItemDetail(String status, String project);

  /// Chip of a link whose target item is in the trash (DD-018 point 14); tapping opens it, where it can be restored.
  ///
  /// In nl, this message translates to:
  /// **'{title} · in prullenbak'**
  String tokenLinkTrashed(String title);

  /// Chip of a [[…]] that names no item (PO decision 03-10-2026): nothing is created by itself. In the item detail tapping creates an inbox item with this text and links it.
  ///
  /// In nl, this message translates to:
  /// **'{label} · geen item'**
  String tokenLinkNone(String label);

  /// Tooltip and screen-reader hint of the 'geen item' chip in the item detail: tapping creates an inbox item with that text and links it.
  ///
  /// In nl, this message translates to:
  /// **'Nieuw item maken en koppelen'**
  String get tokenLinkCreateTooltip;

  /// Screen-reader hint of a link chip in the item detail: tapping opens the linked item.
  ///
  /// In nl, this message translates to:
  /// **'Item openen'**
  String get tokenLinkOpenTooltip;

  /// Message when creating an item from the 'geen item' chip failed; nothing changed.
  ///
  /// In nl, this message translates to:
  /// **'Het item kon niet worden gemaakt'**
  String get tokenLinkCreateFailed;

  /// Header of the section of backlinks in the item detail (DD-018 point 14): the items whose text links to this one.
  ///
  /// In nl, this message translates to:
  /// **'Verwijst hiernaar · {count}'**
  String itemLinkedFrom(int count);

  /// Action in the duplicate comparison (AC REQ-053): writes [[…]] with the other item into the text of the newer one and links them.
  ///
  /// In nl, this message translates to:
  /// **'Koppelen'**
  String get duplicateLink;

  /// Message when linking from the duplicate hint failed; nothing changed.
  ///
  /// In nl, this message translates to:
  /// **'Koppelen is niet gelukt'**
  String get duplicateLinkFailed;

  /// Name of the priority token (*) for chips, screen readers, the prefix bar and the syntax overview.
  ///
  /// In nl, this message translates to:
  /// **'prioriteit'**
  String get tokenPriorityLabel;

  /// Example line for the priority token in the syntax overview; use this language's priority words (tokenPriorityHigh, tokenPriorityLow).
  ///
  /// In nl, this message translates to:
  /// **'Offerte nakijken *hoog, ook *laag of *1, *2, *3'**
  String get tokenPriorityExample;

  /// Text of a priority chip on cards, in the item detail and in the suggestion list.
  ///
  /// In nl, this message translates to:
  /// **'{priority, select, high{Hoge prioriteit} low{Lage prioriteit} other{Normale prioriteit}}'**
  String tokenPriorityChip(String priority);

  /// Line in the suggestion list after '^' that creates a project with this name right away, at the top level (AC REQ-050).
  ///
  /// In nl, this message translates to:
  /// **'Project maken: {name}'**
  String tokenSuggestionNewProject(String name);

  /// Syntax overview: a backslash before a sign keeps it plain text.
  ///
  /// In nl, this message translates to:
  /// **'gewone tekst'**
  String get syntaxEscapeLabel;

  /// Example line for the escape in the syntax overview.
  ///
  /// In nl, this message translates to:
  /// **'Zet er \\ voor: \\@Jan wordt niet herkend'**
  String get syntaxEscapeExample;

  /// Tooltip of the search button in the inbox app bar.
  ///
  /// In nl, this message translates to:
  /// **'Zoeken'**
  String get searchTooltip;

  /// Hint in the search field.
  ///
  /// In nl, this message translates to:
  /// **'Zoek in items en personen'**
  String get searchHint;

  /// Shown on the search screen before anything is typed; explains prefix search.
  ///
  /// In nl, this message translates to:
  /// **'Typ een of meer woorden. Het begin van een woord is genoeg.'**
  String get searchStart;

  /// Shown when a search finds nothing.
  ///
  /// In nl, this message translates to:
  /// **'Niets gevonden voor „{query}”'**
  String searchNoResults(String query);

  /// Shown when searching failed.
  ///
  /// In nl, this message translates to:
  /// **'Zoeken lukte niet. Probeer het opnieuw.'**
  String get searchFailed;

  /// Tooltip of the button that clears the search field.
  ///
  /// In nl, this message translates to:
  /// **'Wissen'**
  String get searchClear;

  /// Screen-reader label of the icon of an item in the search results.
  ///
  /// In nl, this message translates to:
  /// **'Item'**
  String get searchKindItem;

  /// Screen-reader label of the icon of a person in the search results.
  ///
  /// In nl, this message translates to:
  /// **'Persoon'**
  String get searchKindPerson;

  /// Hint under an inbox item that nearly repeats an older item (REQ-053); opens the comparison.
  ///
  /// In nl, this message translates to:
  /// **'Lijkt op een ander item'**
  String get duplicateHint;

  /// Title of the dialog comparing an item with the older item it looks like.
  ///
  /// In nl, this message translates to:
  /// **'Bestaat dit al?'**
  String get duplicateTitle;

  /// Label above the text of the new item in the comparison.
  ///
  /// In nl, this message translates to:
  /// **'Dit item'**
  String get duplicateThisItem;

  /// Label above the older item in the comparison. Both placeholders get the same moment.
  ///
  /// In nl, this message translates to:
  /// **'Lijkt op dit item van {date}, {time}'**
  String duplicateOtherItem(DateTime date, DateTime time);

  /// Button: these are not the same; the hint does not come back for this pair.
  ///
  /// In nl, this message translates to:
  /// **'Negeren'**
  String get duplicateIgnore;

  /// Closes the comparison without a choice.
  ///
  /// In nl, this message translates to:
  /// **'Sluiten'**
  String get duplicateClose;

  /// Shown when storing the ignore choice failed.
  ///
  /// In nl, this message translates to:
  /// **'Negeren is niet bewaard. Probeer het opnieuw.'**
  String get duplicateIgnoreFailed;

  /// Last line of the date suggestions: opens a calendar; the chosen day goes into the text as a fixed date.
  ///
  /// In nl, this message translates to:
  /// **'Kies een datum…'**
  String get tokenSuggestionPickDate;

  /// Item status: not processed yet.
  ///
  /// In nl, this message translates to:
  /// **'Inbox'**
  String get itemStatusInbox;

  /// Item status: being worked on.
  ///
  /// In nl, this message translates to:
  /// **'Actief'**
  String get itemStatusActive;

  /// Item status: waiting on someone else.
  ///
  /// In nl, this message translates to:
  /// **'Wacht op'**
  String get itemStatusWaiting;

  /// Item status: planned for later.
  ///
  /// In nl, this message translates to:
  /// **'Gepland'**
  String get itemStatusScheduled;

  /// Item status: completed.
  ///
  /// In nl, this message translates to:
  /// **'Afgerond'**
  String get itemStatusDone;

  /// Item status: done and put away.
  ///
  /// In nl, this message translates to:
  /// **'Gearchiveerd'**
  String get itemStatusArchived;

  /// Item without a type (REQ-018).
  ///
  /// In nl, this message translates to:
  /// **'Geen type'**
  String get itemTypeNone;

  /// Item type.
  ///
  /// In nl, this message translates to:
  /// **'Taak'**
  String get itemTypeTask;

  /// Item type: something someone asked.
  ///
  /// In nl, this message translates to:
  /// **'Verzoek'**
  String get itemTypeRequest;

  /// Item type.
  ///
  /// In nl, this message translates to:
  /// **'Idee'**
  String get itemTypeIdea;

  /// Item type; also the triage button that keeps an item as a note.
  ///
  /// In nl, this message translates to:
  /// **'Notitie'**
  String get itemTypeNote;

  /// Screen-reader kind of the type chip on a card, read as 'type: Taak' (tokenChipSemantics).
  ///
  /// In nl, this message translates to:
  /// **'type'**
  String get itemTypeKind;

  /// Tooltip of the status chip in the item detail.
  ///
  /// In nl, this message translates to:
  /// **'Status wijzigen'**
  String get itemStatusTooltip;

  /// Tooltip of the type chip in the item detail.
  ///
  /// In nl, this message translates to:
  /// **'Type wijzigen'**
  String get itemTypeTooltip;

  /// Button: mark the item done.
  ///
  /// In nl, this message translates to:
  /// **'Afronden'**
  String get itemComplete;

  /// Button: make a done or archived item active again.
  ///
  /// In nl, this message translates to:
  /// **'Heropenen'**
  String get itemReopen;

  /// Button: set the item to waiting (who comes later).
  ///
  /// In nl, this message translates to:
  /// **'Wachten op…'**
  String get itemWaitFor;

  /// Hint in the text field of the item detail.
  ///
  /// In nl, this message translates to:
  /// **'Tekst van het item'**
  String get itemTextHint;

  /// Shown under the text field when it is empty; nothing is saved.
  ///
  /// In nl, this message translates to:
  /// **'Een item heeft tekst nodig. De vorige tekst blijft bewaard.'**
  String get itemTextEmpty;

  /// Label above the note field of the item detail.
  ///
  /// In nl, this message translates to:
  /// **'Notitie'**
  String get itemNoteLabel;

  /// Hint in the empty note field.
  ///
  /// In nl, this message translates to:
  /// **'Notitie toevoegen'**
  String get itemNoteHint;

  /// Destination Projects in the bottom bar and the rail, and the title of the project list (DD-018 point 6).
  ///
  /// In nl, this message translates to:
  /// **'Projecten'**
  String get navProjects;

  /// Fixed row at the top of the project list: the items that have no project.
  ///
  /// In nl, this message translates to:
  /// **'Zonder project'**
  String get projectsWithout;

  /// Folded part at the bottom of the project list with the archived projects.
  ///
  /// In nl, this message translates to:
  /// **'Gearchiveerd · {count}'**
  String projectsArchived(int count);

  /// Tooltip of the + button in the project list, and title of the dialog that creates a project.
  ///
  /// In nl, this message translates to:
  /// **'Nieuw project'**
  String get projectsNew;

  /// Project list without any project.
  ///
  /// In nl, this message translates to:
  /// **'Nog geen projecten. Maak er een met +.'**
  String get projectsEmpty;

  /// Screen-reader text for the number on a project row.
  ///
  /// In nl, this message translates to:
  /// **'{count, plural, =1{1 open item} other{{count} open items}}'**
  String projectsOpenCount(int count);

  /// The overdue count on a project row, for screen readers and as tooltip.
  ///
  /// In nl, this message translates to:
  /// **'{count} verlopen'**
  String projectsOverdueCount(int count);

  /// Header of a group of items in a project, by status (DD-018 point 6).
  ///
  /// In nl, this message translates to:
  /// **'{group, select, inbox{Inbox} active{Actief} waiting{Wacht op} scheduled{Gepland} notes{Notities} other{Afgerond}} · {count}'**
  String projectGroup(String group, int count);

  /// A project without items and without sub-projects.
  ///
  /// In nl, this message translates to:
  /// **'Nog niets in dit project.'**
  String get projectEmpty;

  /// Project menu: rename.
  ///
  /// In nl, this message translates to:
  /// **'Hernoemen'**
  String get projectRename;

  /// Project menu: put the project under another one, or at the top level.
  ///
  /// In nl, this message translates to:
  /// **'Verplaatsen…'**
  String get projectMove;

  /// Project menu: archive a finished project.
  ///
  /// In nl, this message translates to:
  /// **'Archiveren'**
  String get projectArchive;

  /// Menu of an archived project: bring it back.
  ///
  /// In nl, this message translates to:
  /// **'Terugzetten'**
  String get projectRestore;

  /// Project menu: delete the project (its items stay).
  ///
  /// In nl, this message translates to:
  /// **'Verwijderen'**
  String get projectDelete;

  /// Tooltip of the ⋮ menu of a project.
  ///
  /// In nl, this message translates to:
  /// **'Projectacties'**
  String get projectMenuTooltip;

  /// Title of the rename dialog.
  ///
  /// In nl, this message translates to:
  /// **'Project hernoemen'**
  String get projectRenameTitle;

  /// Name field in the project dialogs.
  ///
  /// In nl, this message translates to:
  /// **'Naam'**
  String get projectNameLabel;

  /// Choice of the parent project in the new-project dialog.
  ///
  /// In nl, this message translates to:
  /// **'Onder'**
  String get projectParentLabel;

  /// Parent choice: no parent project.
  ///
  /// In nl, this message translates to:
  /// **'Bovenaan (geen hoofdproject)'**
  String get projectTopLevel;

  /// Title of the move dialog.
  ///
  /// In nl, this message translates to:
  /// **'Verplaatsen naar'**
  String get projectMoveTitle;

  /// Button that creates a project.
  ///
  /// In nl, this message translates to:
  /// **'Maken'**
  String get projectCreate;

  /// Button that saves a renamed project.
  ///
  /// In nl, this message translates to:
  /// **'Opslaan'**
  String get projectSave;

  /// Closes a project dialog without a change.
  ///
  /// In nl, this message translates to:
  /// **'Annuleren'**
  String get projectCancel;

  /// Title of the confirmation before deleting a project.
  ///
  /// In nl, this message translates to:
  /// **'{name} verwijderen?'**
  String projectDeleteTitle(String name);

  /// Body of the confirmation before deleting a project.
  ///
  /// In nl, this message translates to:
  /// **'De items blijven bestaan en raken dit project kwijt. Deelprojecten komen bovenaan te staan. Je kunt het meteen ongedaan maken.'**
  String get projectDeleteBody;

  /// Message after deleting a project, with Undo.
  ///
  /// In nl, this message translates to:
  /// **'Project verwijderd'**
  String get projectDeleted;

  /// Message after archiving a project, with Undo.
  ///
  /// In nl, this message translates to:
  /// **'Project gearchiveerd'**
  String get projectArchived;

  /// Message after restoring a project from the archive.
  ///
  /// In nl, this message translates to:
  /// **'Project teruggezet'**
  String get projectRestored;

  /// A project name that is taken under the same parent.
  ///
  /// In nl, this message translates to:
  /// **'Er is al een project met deze naam.'**
  String get projectErrorNameTaken;

  /// An empty project name.
  ///
  /// In nl, this message translates to:
  /// **'Geef het project een naam.'**
  String get projectErrorEmptyName;

  /// A change that would make a third level of projects.
  ///
  /// In nl, this message translates to:
  /// **'Dat kan niet: projecten hebben hoogstens twee niveaus.'**
  String get projectErrorTooDeep;

  /// A change to a project that is deleted or archived.
  ///
  /// In nl, this message translates to:
  /// **'Dit project bestaat niet meer of is gearchiveerd.'**
  String get projectErrorNotAvailable;

  /// Any other failure of a project change.
  ///
  /// In nl, this message translates to:
  /// **'Dat is niet gelukt. Probeer het nog eens.'**
  String get projectChangeFailed;

  /// Title of the sheet that chooses the project of an item.
  ///
  /// In nl, this message translates to:
  /// **'Project'**
  String get projectPickerTitle;

  /// Filter field in the project sheet.
  ///
  /// In nl, this message translates to:
  /// **'Zoek of typ een nieuwe naam'**
  String get projectPickerHint;

  /// The choice "no project", and the project chip of an item without one.
  ///
  /// In nl, this message translates to:
  /// **'Geen project'**
  String get projectNone;

  /// Creates a project with the typed name and chooses it.
  ///
  /// In nl, this message translates to:
  /// **'Nieuw project: {name}'**
  String projectNewNamed(String name);

  /// Opens the dialog for a new project from the project sheet.
  ///
  /// In nl, this message translates to:
  /// **'Nieuw project…'**
  String get projectNewEllipsis;

  /// Tooltip of the project chip in the item detail and on the triage card.
  ///
  /// In nl, this message translates to:
  /// **'Project kiezen'**
  String get projectChipTooltip;

  /// An archived project on the chip of an item that still belongs to it.
  ///
  /// In nl, this message translates to:
  /// **'{name} (gearchiveerd)'**
  String projectArchivedName(String name);

  /// The full path of a sub-project, e.g. in a tooltip.
  ///
  /// In nl, this message translates to:
  /// **'{parent} › {name}'**
  String projectPath(String parent, String name);

  /// Kind of chip for screen readers, before the project name ("project: Renovatie").
  ///
  /// In nl, this message translates to:
  /// **'project'**
  String get projectKind;

  /// Screen-reader label of the row of sub-project chips.
  ///
  /// In nl, this message translates to:
  /// **'Deelprojecten'**
  String get projectSubprojects;

  /// Share icon in the top bar of the item detail (tooltip) and the button that opens the Android share menu (REQ-043).
  ///
  /// In nl, this message translates to:
  /// **'Delen'**
  String get itemShare;

  /// Title of the share preview.
  ///
  /// In nl, this message translates to:
  /// **'Item delen'**
  String get itemShareTitle;

  /// Switch in the share preview: keep the #tags in the shared text (left out by default, AC REQ-043).
  ///
  /// In nl, this message translates to:
  /// **'Tags meenemen'**
  String get itemShareIncludeTags;

  /// Switch in the share preview: share the text with all tokens and fixed dates, so Offload on another device makes an item with the same text and tokens (T2.7a).
  ///
  /// In nl, this message translates to:
  /// **'Zoals getypt (voor Offload)'**
  String get itemShareAsTyped;

  /// Second line of the switch Zoals getypt (voor Offload).
  ///
  /// In nl, this message translates to:
  /// **'Met @, #, ^, * en vaste datums: Offload op een ander toestel maakt er een item met dezelfde tekst en tokens van.'**
  String get itemShareAsTypedHint;

  /// Under the editable text in the share preview (AC REQ-043).
  ///
  /// In nl, this message translates to:
  /// **'Wat je hier aanpast, verandert het item niet.'**
  String get itemShareHelper;

  /// Windows: copies the shared text to the clipboard.
  ///
  /// In nl, this message translates to:
  /// **'Kopiëren'**
  String get itemShareCopy;

  /// Windows: saves the shared text as a text file through the save window.
  ///
  /// In nl, this message translates to:
  /// **'Opslaan als…'**
  String get itemShareSaveAs;

  /// Closes the share preview without sharing.
  ///
  /// In nl, this message translates to:
  /// **'Annuleren'**
  String get itemShareCancel;

  /// Message after copying the shared text.
  ///
  /// In nl, this message translates to:
  /// **'Gekopieerd naar het klembord'**
  String get itemShareCopied;

  /// Message after saving the shared text as a file.
  ///
  /// In nl, this message translates to:
  /// **'Opgeslagen'**
  String get itemShareSaved;

  /// Message when sharing, copying or saving failed.
  ///
  /// In nl, this message translates to:
  /// **'Delen is niet gelukt. Probeer het nog eens.'**
  String get itemShareFailed;

  /// Windows: name of the file type (.txt) in the save window.
  ///
  /// In nl, this message translates to:
  /// **'Tekstbestand'**
  String get itemShareFileType;

  /// A date token written out in the shared text, this year: e.g. 'vrijdag 2 oktober'.
  ///
  /// In nl, this message translates to:
  /// **'{date}'**
  String itemShareDate(DateTime date);

  /// A date token written out in the shared text, another year: e.g. 'vrijdag 1 januari 2027'.
  ///
  /// In nl, this message translates to:
  /// **'{date}'**
  String itemShareDateWithYear(DateTime date);

  /// Menu action in the item detail.
  ///
  /// In nl, this message translates to:
  /// **'Naar de prullenbak'**
  String get itemMoveToTrash;

  /// Message after moving an item to the trash.
  ///
  /// In nl, this message translates to:
  /// **'Naar de prullenbak verplaatst'**
  String get itemMovedToTrash;

  /// Action in the message after moving to the trash.
  ///
  /// In nl, this message translates to:
  /// **'Ongedaan maken'**
  String get itemUndo;

  /// Shown in the item detail when saving an edit failed.
  ///
  /// In nl, this message translates to:
  /// **'Opslaan is mislukt. Je wijziging staat er nog; probeer het opnieuw.'**
  String get itemSaveFailed;

  /// Shown when an opened item is gone.
  ///
  /// In nl, this message translates to:
  /// **'Dit item staat in de prullenbak of bestaat niet meer.'**
  String get itemGone;

  /// Bottom line of the item detail; source is one of the itemSource* texts.
  ///
  /// In nl, this message translates to:
  /// **'Vastgelegd {date}, {time} via {source}'**
  String itemCapturedVia(DateTime date, DateTime time, String source);

  /// Capture source, completes 'via …'.
  ///
  /// In nl, this message translates to:
  /// **'de app'**
  String get itemSourceApp;

  /// Capture source, completes 'via …'.
  ///
  /// In nl, this message translates to:
  /// **'de widget'**
  String get itemSourceWidget;

  /// Capture source, completes 'via …'.
  ///
  /// In nl, this message translates to:
  /// **'delen'**
  String get itemSourceShare;

  /// Capture source, completes 'via …'.
  ///
  /// In nl, this message translates to:
  /// **'de sneltoets'**
  String get itemSourceHotkey;

  /// Capture source, completes 'via …'.
  ///
  /// In nl, this message translates to:
  /// **'het systeemvak'**
  String get itemSourceTray;

  /// Capture source, completes 'via …'.
  ///
  /// In nl, this message translates to:
  /// **'spraak'**
  String get itemSourceVoice;

  /// Capture source: a thought read from a photo of handwriting (REQ-064); completes 'via …'.
  ///
  /// In nl, this message translates to:
  /// **'handschrift'**
  String get itemSourceHandwriting;

  /// Opens the older item from the duplicate hint.
  ///
  /// In nl, this message translates to:
  /// **'Openen'**
  String get duplicateOpen;

  /// Under the title of an inbox card: how many more non-empty lines the text has (DD-018 point 2).
  ///
  /// In nl, this message translates to:
  /// **'{count, plural, =1{+ 1 regel} other{+ {count} regels}}'**
  String inboxMoreLines(int count);

  /// Relative time on an inbox card: less than a minute ago (DD-018 point 2).
  ///
  /// In nl, this message translates to:
  /// **'zojuist'**
  String get ageJustNow;

  /// Relative time on an inbox card: minutes ago, short.
  ///
  /// In nl, this message translates to:
  /// **'{count} min'**
  String ageMinutes(int count);

  /// Relative time on an inbox card: hours ago today, short.
  ///
  /// In nl, this message translates to:
  /// **'{count} u'**
  String ageHours(int count);

  /// Relative time on an inbox card: the previous calendar day.
  ///
  /// In nl, this message translates to:
  /// **'gisteren'**
  String get ageYesterday;

  /// Relative time on an inbox card: days ago (2 to 6), short.
  ///
  /// In nl, this message translates to:
  /// **'{count} d'**
  String ageDays(int count);

  /// Relative time on an inbox card: a week or longer ago, the date, short.
  ///
  /// In nl, this message translates to:
  /// **'{date}'**
  String ageDate(DateTime date);

  /// Relative time for screen readers: minutes ago, written out.
  ///
  /// In nl, this message translates to:
  /// **'{count, plural, =1{1 minuut geleden} other{{count} minuten geleden}}'**
  String ageMinutesLong(int count);

  /// Relative time for screen readers: hours ago, written out.
  ///
  /// In nl, this message translates to:
  /// **'{count, plural, =1{1 uur geleden} other{{count} uur geleden}}'**
  String ageHoursLong(int count);

  /// Relative time for screen readers: days ago, written out.
  ///
  /// In nl, this message translates to:
  /// **'{count, plural, =1{1 dag geleden} other{{count} dagen geleden}}'**
  String ageDaysLong(int count);

  /// Relative time for screen readers: a week or longer ago, the full date.
  ///
  /// In nl, this message translates to:
  /// **'op {date}'**
  String ageDateLong(DateTime date);

  /// Button at the top of the inbox that starts triage, card by card (T2.4, DD-018 point 3), with the number of inbox items.
  ///
  /// In nl, this message translates to:
  /// **'Verwerken · {count}'**
  String inboxTriage(int count);

  /// Title of the triage screen.
  ///
  /// In nl, this message translates to:
  /// **'Verwerken'**
  String get triageTitle;

  /// Progress in triage: the card being handled and the total.
  ///
  /// In nl, this message translates to:
  /// **'{position} van {total}'**
  String triageProgress(int position, int total);

  /// Tooltip of the close button of triage; what was chosen stays.
  ///
  /// In nl, this message translates to:
  /// **'Stoppen'**
  String get triageStop;

  /// Triage button: waiting for someone (status waiting, asks for whom).
  ///
  /// In nl, this message translates to:
  /// **'Wacht op'**
  String get triageWaitFor;

  /// Triage button and screen-reader action: to the trash.
  ///
  /// In nl, this message translates to:
  /// **'Prullenbak'**
  String get triageTrash;

  /// Skip this card (it stays in the inbox); also in the person sheet: go on without a person.
  ///
  /// In nl, this message translates to:
  /// **'Overslaan'**
  String get triageSkip;

  /// Opens the item of the card in the item detail.
  ///
  /// In nl, this message translates to:
  /// **'Openen'**
  String get triageOpen;

  /// Title of the person sheet after Request.
  ///
  /// In nl, this message translates to:
  /// **'Wie vroeg dit?'**
  String get triageWhoAsked;

  /// Title of the person sheet after Wait for.
  ///
  /// In nl, this message translates to:
  /// **'Op wie wacht je?'**
  String get triageWaitingOn;

  /// Hint in the name field of the person sheet.
  ///
  /// In nl, this message translates to:
  /// **'Naam'**
  String get triagePersonHint;

  /// Confirms the person in the sheet.
  ///
  /// In nl, this message translates to:
  /// **'Klaar'**
  String get triagePersonDone;

  /// Message after a triage choice, with Undo.
  ///
  /// In nl, this message translates to:
  /// **'Naar {destination}'**
  String triageMovedTo(String destination);

  /// End of triage: every card has been handled.
  ///
  /// In nl, this message translates to:
  /// **'Alles heeft een plek'**
  String get triageDoneTitle;

  /// End of triage: how many cards got a destination.
  ///
  /// In nl, this message translates to:
  /// **'{count, plural, =1{1 verwerkt} other{{count} verwerkt}}'**
  String triageDoneProcessed(int count);

  /// End of triage: how many cards were skipped; only shown when there are any.
  ///
  /// In nl, this message translates to:
  /// **'{count, plural, =1{1 overgeslagen, die staat nog in je inbox} other{{count} overgeslagen, die staan nog in je inbox}}'**
  String triageDoneSkipped(int count);

  /// Name of the Delete key on the trash button of triage (Windows).
  ///
  /// In nl, this message translates to:
  /// **'Del'**
  String get triageDeleteKey;

  /// A triage button on Windows: its label and its key (1-5, Del).
  ///
  /// In nl, this message translates to:
  /// **'{label}  {key}'**
  String triageButtonWithKey(String label, String key);

  /// Button on the end screen of triage.
  ///
  /// In nl, this message translates to:
  /// **'Terug naar de inbox'**
  String get triageBackToInbox;

  /// Subtitle of a processed item in the inbox list: its status and when it was captured.
  ///
  /// In nl, this message translates to:
  /// **'{status} · {when}'**
  String inboxStatusAndTime(String status, String when);

  /// Shown when changing status or type, or moving to the trash, failed.
  ///
  /// In nl, this message translates to:
  /// **'Wijzigen is mislukt. Probeer het opnieuw.'**
  String get itemChangeFailed;

  /// Shown when taking an item out of the trash failed.
  ///
  /// In nl, this message translates to:
  /// **'Ongedaan maken is mislukt; het item staat nog in de prullenbak.'**
  String get itemUndoFailed;

  /// Navigation destination and title of the Today screen (DD-011, DD-018 point 4).
  ///
  /// In nl, this message translates to:
  /// **'Vandaag'**
  String get navToday;

  /// Screen-reader text of the badge on the Inbox destination, read with its label 'Inbox': the number of unprocessed items (DD-018 point 5).
  ///
  /// In nl, this message translates to:
  /// **'{count, plural, =0{geen onverwerkte items} =1{1 onverwerkt item} other{{count} onverwerkte items}}'**
  String navInboxBadge(int count);

  /// Today's date next to the title of the Today screen, short (e.g. 'ma 28 sep').
  ///
  /// In nl, this message translates to:
  /// **'{date}'**
  String todayDate(DateTime date);

  /// Line at the top of Today: how many items wait in the inbox; tapping it goes to the Inbox.
  ///
  /// In nl, this message translates to:
  /// **'{count, plural, =1{1 in je inbox} other{{count} in je inbox}}'**
  String todayInboxLine(int count);

  /// Button on the inbox line of Today: starts triage.
  ///
  /// In nl, this message translates to:
  /// **'Verwerken'**
  String get todayProcess;

  /// Section header on Today: items whose deadline has passed, with their number.
  ///
  /// In nl, this message translates to:
  /// **'Verlopen · {count}'**
  String todayOverdue(int count);

  /// Section header on Today: items due today, with their number.
  ///
  /// In nl, this message translates to:
  /// **'Vandaag · {count}'**
  String todayDueToday(int count);

  /// Today with nothing due: a positive confirmation, never a blank screen.
  ///
  /// In nl, this message translates to:
  /// **'Niets voor vandaag'**
  String get todayEmptyTitle;

  /// Explanation under 'Niets voor vandaag'.
  ///
  /// In nl, this message translates to:
  /// **'Geen deadlines vandaag en niets verlopen.'**
  String get todayEmptyText;

  /// Shown when the items for Today cannot be read.
  ///
  /// In nl, this message translates to:
  /// **'Vandaag kon niet worden geladen.'**
  String get todayLoadFailed;

  /// Message after completing an item from Today, with an Undo button.
  ///
  /// In nl, this message translates to:
  /// **'Afgerond'**
  String get itemCompleted;

  /// End button of triage started from Today: back to Today.
  ///
  /// In nl, this message translates to:
  /// **'Terug'**
  String get triageBack;

  /// Detail pane on Windows with nothing selected (DD-018 point 5).
  ///
  /// In nl, this message translates to:
  /// **'Kies een item'**
  String get panesChooseItem;

  /// Hint under 'Kies een item': how to select a card.
  ///
  /// In nl, this message translates to:
  /// **'Met de muis, of met ↑ en ↓ in de lijst.'**
  String get panesChooseHint;

  /// Destination People in the bottom bar and the rail, and the title of the people list (DD-018 point 7).
  ///
  /// In nl, this message translates to:
  /// **'Personen'**
  String get navPeople;

  /// Hint in the filter field above the people list; it matches names and aliases.
  ///
  /// In nl, this message translates to:
  /// **'Zoek een persoon'**
  String get peopleFilterHint;

  /// People list without any person.
  ///
  /// In nl, this message translates to:
  /// **'Nog geen personen. Noem iemand met @naam bij het vastleggen.'**
  String get peopleEmpty;

  /// People list when the filter matches nobody.
  ///
  /// In nl, this message translates to:
  /// **'Niemand gevonden.'**
  String get peopleNoMatch;

  /// Under the name on a person screen: the other names the person is found by.
  ///
  /// In nl, this message translates to:
  /// **'ook: {aliases}'**
  String personAliases(String aliases);

  /// Header of a list on a person screen with its number of open items (DD-018 point 7).
  ///
  /// In nl, this message translates to:
  /// **'{list, select, requestedBy{Gevraagd door {name}} waitingFor{Wacht op {name}} other{Genoemd in}} · {count}'**
  String personList(String list, String name, int count);

  /// Person screen without any linked item.
  ///
  /// In nl, this message translates to:
  /// **'Nog niets met deze persoon.'**
  String get personEmpty;

  /// Tooltip of the menu on a person screen.
  ///
  /// In nl, this message translates to:
  /// **'Persoonacties'**
  String get personMenuTooltip;

  /// Menu entry on a person screen.
  ///
  /// In nl, this message translates to:
  /// **'Hernoemen'**
  String get personRename;

  /// Title of the rename dialog.
  ///
  /// In nl, this message translates to:
  /// **'Persoon hernoemen'**
  String get personRenameTitle;

  /// Label of the name field in the rename dialog.
  ///
  /// In nl, this message translates to:
  /// **'Naam'**
  String get personNameLabel;

  /// Under the name field in the rename dialog: the old name becomes an alias (DD-015).
  ///
  /// In nl, this message translates to:
  /// **'\"{name}\" blijft werken als bijnaam.'**
  String personRenameKeeps(String name);

  /// Confirm button of the rename dialog.
  ///
  /// In nl, this message translates to:
  /// **'Opslaan'**
  String get personSave;

  /// Cancel button of the rename dialog.
  ///
  /// In nl, this message translates to:
  /// **'Annuleren'**
  String get personCancel;

  /// Rename refused: the name is empty.
  ///
  /// In nl, this message translates to:
  /// **'Geef een naam.'**
  String get personErrorEmptyName;

  /// Rename refused: the name or an alias of another person (merging comes later).
  ///
  /// In nl, this message translates to:
  /// **'Er is al een persoon die zo heet.'**
  String get personErrorNameTaken;

  /// A change refused because the person was deleted.
  ///
  /// In nl, this message translates to:
  /// **'Deze persoon bestaat niet meer.'**
  String get personErrorNotAvailable;

  /// Kind of the requester chip, for screen readers and as tooltip.
  ///
  /// In nl, this message translates to:
  /// **'Gevraagd door'**
  String get personRequesterKind;

  /// Kind of the waiting-for chip, for screen readers and as tooltip.
  ///
  /// In nl, this message translates to:
  /// **'Wacht op'**
  String get personWaitingKind;

  /// Menu entry of a person chip in the item detail: opens the person.
  ///
  /// In nl, this message translates to:
  /// **'{name} openen'**
  String personOpen(String name);

  /// Menu entry of a person chip in the item detail: choose another person.
  ///
  /// In nl, this message translates to:
  /// **'Andere persoon…'**
  String get personChange;

  /// Menu entry of a person chip in the item detail: the item no longer has this person.
  ///
  /// In nl, this message translates to:
  /// **'Weghalen'**
  String get personRemove;

  /// In the person sheet, after a person named with @ in the item text.
  ///
  /// In nl, this message translates to:
  /// **'in de tekst'**
  String get personInText;

  /// Merge refused: a person cannot be merged with themselves.
  ///
  /// In nl, this message translates to:
  /// **'Kies een andere persoon.'**
  String get personErrorSamePerson;

  /// Menu entry on a person screen: merge this person into another (DD-015, T3.2b).
  ///
  /// In nl, this message translates to:
  /// **'Samenvoegen met…'**
  String get personMerge;

  /// Title of the list that chooses the person to merge into.
  ///
  /// In nl, this message translates to:
  /// **'{name} samenvoegen met'**
  String personMergePickerTitle(String name);

  /// The merge list when there is no other person.
  ///
  /// In nl, this message translates to:
  /// **'Er is nog niemand anders.'**
  String get personMergeNoOthers;

  /// Title of the confirmation before merging.
  ///
  /// In nl, this message translates to:
  /// **'Personen samenvoegen?'**
  String get personMergeTitle;

  /// Body of the confirmation before merging person {from} into {into}.
  ///
  /// In nl, this message translates to:
  /// **'{from} samenvoegen met {into}? Alle items en bijnamen gaan naar {into}; \"{from}\" blijft werken als bijnaam.'**
  String personMergeBody(String from, String into);

  /// Confirm button of the merge confirmation.
  ///
  /// In nl, this message translates to:
  /// **'Samenvoegen'**
  String get personMergeConfirm;

  /// Message after merging, with Undo.
  ///
  /// In nl, this message translates to:
  /// **'{from} is samengevoegd met {into}'**
  String personMerged(String from, String into);

  /// Button in the rename dialog when the name belongs to another person.
  ///
  /// In nl, this message translates to:
  /// **'Samenvoegen met {name}…'**
  String personMergeWith(String name);

  /// Message when undoing a merge of people failed.
  ///
  /// In nl, this message translates to:
  /// **'Ongedaan maken is mislukt; de personen blijven samengevoegd.'**
  String get personMergeUndoFailed;

  /// On a person screen without a birthday: opens the birthday dialog (REQ-031).
  ///
  /// In nl, this message translates to:
  /// **'Verjaardag toevoegen'**
  String get personBirthdayAdd;

  /// A birthday without a year, e.g. "3 april".
  ///
  /// In nl, this message translates to:
  /// **'{date}'**
  String personBirthday(DateTime date);

  /// A birthday with its year and the age now, e.g. "3 april 1980 · 46 jaar".
  ///
  /// In nl, this message translates to:
  /// **'{date} · {age, plural, =1{1 jaar} other{{age} jaar}}'**
  String personBirthdayWithAge(DateTime date, int age);

  /// Title of the birthday dialog, and the kind for screen readers.
  ///
  /// In nl, this message translates to:
  /// **'Verjaardag'**
  String get personBirthdayTitle;

  /// Tooltip and screen-reader hint of the birthday line on a person screen.
  ///
  /// In nl, this message translates to:
  /// **'Verjaardag wijzigen'**
  String get personBirthdayTooltip;

  /// Label of the day field in the birthday dialog.
  ///
  /// In nl, this message translates to:
  /// **'Dag'**
  String get personBirthdayDay;

  /// Label of the month choice in the birthday dialog.
  ///
  /// In nl, this message translates to:
  /// **'Maand'**
  String get personBirthdayMonth;

  /// Label of the year field in the birthday dialog.
  ///
  /// In nl, this message translates to:
  /// **'Jaar (optioneel)'**
  String get personBirthdayYear;

  /// A month name in the month choice of the birthday dialog.
  ///
  /// In nl, this message translates to:
  /// **'{date}'**
  String personMonthName(DateTime date);

  /// Birthday dialog: the day, month and year give no real date.
  ///
  /// In nl, this message translates to:
  /// **'Deze datum bestaat niet.'**
  String get personBirthdayInvalid;

  /// Label of the note field on a person screen (REQ-031).
  ///
  /// In nl, this message translates to:
  /// **'Notitie'**
  String get personNoteLabel;

  /// Hint in the empty note field on a person screen.
  ///
  /// In nl, this message translates to:
  /// **'Wat je over deze persoon wilt onthouden'**
  String get personNoteHint;

  /// Screen-reader label of the birthday line on a person screen.
  ///
  /// In nl, this message translates to:
  /// **'Verjaardag: {value}'**
  String personBirthdaySemantics(String value);

  /// Title of the weekly review, and the tooltip of its icon at the top of Today (REQ-013, DD-018 point 8).
  ///
  /// In nl, this message translates to:
  /// **'Weekoverzicht'**
  String get reviewTitle;

  /// Windows: tooltip of the weekly review icon at the top of Today, naming its key (DD-018 point 8).
  ///
  /// In nl, this message translates to:
  /// **'Weekoverzicht (Ctrl+Shift+W)'**
  String get reviewStartTooltipWithKey;

  /// Today: line shown while a weekly review is due; days since the last completed review, short (DD-018 point 4).
  ///
  /// In nl, this message translates to:
  /// **'Weekoverzicht · laatste {days} d geleden'**
  String todayReviewLine(int days);

  /// Today: what a screen reader says for the weekly review line, the age in words (REQ-016).
  ///
  /// In nl, this message translates to:
  /// **'Weekoverzicht, laatste keer {days, plural, =1{1 dag} other{{days} dagen}} geleden'**
  String todayReviewLineLabel(int days);

  /// Today: the weekly review line when no review was completed yet.
  ///
  /// In nl, this message translates to:
  /// **'Weekoverzicht · nog niet gedaan'**
  String get todayReviewLineNever;

  /// Today: what a screen reader says for the weekly review line when no review was completed yet.
  ///
  /// In nl, this message translates to:
  /// **'Weekoverzicht, nog niet gedaan'**
  String get todayReviewLineNeverLabel;

  /// Tooltip of the close button of the weekly review.
  ///
  /// In nl, this message translates to:
  /// **'Weekoverzicht sluiten'**
  String get reviewClose;

  /// Button on the start screen of the weekly review.
  ///
  /// In nl, this message translates to:
  /// **'Beginnen'**
  String get reviewStart;

  /// Step 1 of the weekly review.
  ///
  /// In nl, this message translates to:
  /// **'Inbox leeg maken'**
  String get reviewStepInbox;

  /// Step 2 of the weekly review.
  ///
  /// In nl, this message translates to:
  /// **'Wacht op doorlopen'**
  String get reviewStepWaiting;

  /// Step 3 of the weekly review.
  ///
  /// In nl, this message translates to:
  /// **'Deadlines'**
  String get reviewStepDeadlines;

  /// Step 4 of the weekly review: items not touched for a while.
  ///
  /// In nl, this message translates to:
  /// **'Stilgevallen'**
  String get reviewStepStale;

  /// Start screen, step 1.
  ///
  /// In nl, this message translates to:
  /// **'{count, plural, =1{1 item te verwerken} other{{count} items te verwerken}}'**
  String reviewInboxCount(int count);

  /// Start screen, step 2.
  ///
  /// In nl, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String reviewWaitingCount(int count);

  /// Start screen, step 3.
  ///
  /// In nl, this message translates to:
  /// **'{overdue} verlopen · {upcoming} in de komende 2 weken'**
  String reviewDeadlinesCount(int overdue, int upcoming);

  /// Start screen, step 4.
  ///
  /// In nl, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}, {weeks, plural, =1{1 week} other{{weeks} weken}} of langer niet aangeraakt'**
  String reviewStaleCount(int count, int weeks);

  /// Start screen: a step with nothing to do, which is skipped.
  ///
  /// In nl, this message translates to:
  /// **'✓ niets te doen'**
  String get reviewNothing;

  /// Which step of how many, in the top bar.
  ///
  /// In nl, this message translates to:
  /// **'{step} / {total}'**
  String reviewStepOf(int step, int total);

  /// Button: the previous step.
  ///
  /// In nl, this message translates to:
  /// **'Vorige'**
  String get reviewPrevious;

  /// Button: the next step.
  ///
  /// In nl, this message translates to:
  /// **'Volgende'**
  String get reviewNext;

  /// Button on the last step.
  ///
  /// In nl, this message translates to:
  /// **'Klaar'**
  String get reviewFinish;

  /// Step 1 when there is nothing to process.
  ///
  /// In nl, this message translates to:
  /// **'✓ De inbox is leeg'**
  String get reviewInboxEmpty;

  /// Step 1: starts the triage.
  ///
  /// In nl, this message translates to:
  /// **'Verwerken'**
  String get reviewProcess;

  /// Step 2, per card: you looked and still wait (records the moment).
  ///
  /// In nl, this message translates to:
  /// **'Wacht nog'**
  String get reviewStillWaiting;

  /// Step 4, per card: keep it as it is (records the moment).
  ///
  /// In nl, this message translates to:
  /// **'Houden'**
  String get reviewKeep;

  /// Step 4, per card: archive with undo.
  ///
  /// In nl, this message translates to:
  /// **'Archiveren'**
  String get reviewArchive;

  /// Message after archiving from the weekly review, with undo.
  ///
  /// In nl, this message translates to:
  /// **'Gearchiveerd'**
  String get reviewArchived;

  /// A handled card in step 2.
  ///
  /// In nl, this message translates to:
  /// **'✓ Wacht nog'**
  String get reviewHandledWaiting;

  /// A handled card in step 4.
  ///
  /// In nl, this message translates to:
  /// **'✓ Gehouden'**
  String get reviewHandledKept;

  /// A card completed in the review.
  ///
  /// In nl, this message translates to:
  /// **'✓ Afgerond'**
  String get reviewHandledDone;

  /// A card archived in the review.
  ///
  /// In nl, this message translates to:
  /// **'✓ Gearchiveerd'**
  String get reviewHandledArchived;

  /// A card sent to the trash in the review.
  ///
  /// In nl, this message translates to:
  /// **'✓ In de prullenbak'**
  String get reviewHandledTrashed;

  /// How long an item was not touched, under two weeks.
  ///
  /// In nl, this message translates to:
  /// **'{days, plural, =1{1 dag niet aangeraakt} other{{days} dagen niet aangeraakt}}'**
  String reviewAgeDays(int days);

  /// How long an item was not touched, two weeks or more.
  ///
  /// In nl, this message translates to:
  /// **'{weeks} weken niet aangeraakt'**
  String reviewAgeWeeks(int weeks);

  /// Step 3: header of the overdue items.
  ///
  /// In nl, this message translates to:
  /// **'Verlopen · {count}'**
  String reviewOverdue(int count);

  /// Step 3: header of the items due from today up to 14 days ahead.
  ///
  /// In nl, this message translates to:
  /// **'Komende 2 weken · {count}'**
  String reviewUpcoming(int count);

  /// Step 4: header with X and the number of items.
  ///
  /// In nl, this message translates to:
  /// **'{weeks, plural, =1{1 week} other{{weeks} weken}} of langer niet aangeraakt · {count}'**
  String reviewStaleHeader(int weeks, int count);

  /// End screen of the weekly review.
  ///
  /// In nl, this message translates to:
  /// **'Klaar ✓'**
  String get reviewEndTitle;

  /// End screen: how many items were kept or still waited for.
  ///
  /// In nl, this message translates to:
  /// **'{count} gehouden'**
  String reviewEndKept(int count);

  /// End screen: how many items were completed.
  ///
  /// In nl, this message translates to:
  /// **'{count} afgerond'**
  String reviewEndDone(int count);

  /// End screen: how many items were archived.
  ///
  /// In nl, this message translates to:
  /// **'{count} gearchiveerd'**
  String reviewEndArchived(int count);

  /// End screen: how many items went to the trash.
  ///
  /// In nl, this message translates to:
  /// **'{count} in de prullenbak'**
  String reviewEndTrashed(int count);

  /// End screen when nothing was changed.
  ///
  /// In nl, this message translates to:
  /// **'Alles was al bij.'**
  String get reviewEndNothing;

  /// End screen: back to Today.
  ///
  /// In nl, this message translates to:
  /// **'Naar Vandaag'**
  String get reviewEndBack;

  /// Settings: section of the weekly review.
  ///
  /// In nl, this message translates to:
  /// **'Weekoverzicht'**
  String get settingsReviewHeader;

  /// Settings: after how many weeks an untouched open item is stale (AC REQ-051).
  ///
  /// In nl, this message translates to:
  /// **'Stilgevallen na'**
  String get settingsStaleAfter;

  /// Settings: explanation under Stale after.
  ///
  /// In nl, this message translates to:
  /// **'Een open item dat zo lang niet is aangeraakt, komt in de laatste stap van het weekoverzicht.'**
  String get settingsStaleAfterHint;

  /// Settings: after how many days since the last completed weekly review a new one is due (DD-018 point 8).
  ///
  /// In nl, this message translates to:
  /// **'Aan de beurt na'**
  String get settingsReviewDueAfter;

  /// Settings: explanation under Due again after.
  ///
  /// In nl, this message translates to:
  /// **'Zo lang na het laatste afgeronde weekoverzicht toont Vandaag een regel om het te starten.'**
  String get settingsReviewDueAfterHint;

  /// Settings: a number of days in the Due again after choice.
  ///
  /// In nl, this message translates to:
  /// **'{days, plural, =1{1 dag} other{{days} dagen}}'**
  String settingsDays(int days);

  /// Settings: a number of weeks in the Stale after choice.
  ///
  /// In nl, this message translates to:
  /// **'{weeks, plural, =1{1 week} other{{weeks} weken}}'**
  String settingsWeeks(int weeks);

  /// Settings: storing a choice failed (Stale after, Due again after).
  ///
  /// In nl, this message translates to:
  /// **'Opslaan is mislukt; de keuze geldt tot de app opnieuw start.'**
  String get settingsSaveFailed;

  /// End screen: for how many items you still wait.
  ///
  /// In nl, this message translates to:
  /// **'{count} wacht nog'**
  String reviewEndWaiting(int count);

  /// Person profile: the line when neither job title nor organisation is set (DD-018 point 9).
  ///
  /// In nl, this message translates to:
  /// **'Functie en organisatie toevoegen'**
  String get personWorkAdd;

  /// Person profile: tooltip of the job title and organisation line.
  ///
  /// In nl, this message translates to:
  /// **'Functie en organisatie wijzigen'**
  String get personWorkTooltip;

  /// Person profile: what a screen reader says for the job title and organisation line.
  ///
  /// In nl, this message translates to:
  /// **'Functie en organisatie: {value}'**
  String personWorkSemantics(String value);

  /// Person profile: job title and organisation on one line, job title first.
  ///
  /// In nl, this message translates to:
  /// **'{jobTitle} · {organisation}'**
  String personWork(String jobTitle, String organisation);

  /// Title of the dialog for job title and organisation.
  ///
  /// In nl, this message translates to:
  /// **'Functie en organisatie'**
  String get personWorkTitle;

  /// Field: the job title of a person (REQ-038).
  ///
  /// In nl, this message translates to:
  /// **'Functie'**
  String get personJobTitle;

  /// Field: the organisation of a person (REQ-038).
  ///
  /// In nl, this message translates to:
  /// **'Organisatie'**
  String get personOrganisation;

  /// Person profile: header of the phone numbers and email addresses (REQ-038, DD-018 point 9).
  ///
  /// In nl, this message translates to:
  /// **'Contactgegevens'**
  String get contactSection;

  /// A phone number: the add button, the field label and the kind a screen reader says.
  ///
  /// In nl, this message translates to:
  /// **'Telefoonnummer'**
  String get contactKindPhone;

  /// An email address: the add button, the field label and the kind a screen reader says.
  ///
  /// In nl, this message translates to:
  /// **'E-mailadres'**
  String get contactKindEmail;

  /// Title of the sheet, and tooltip of the button, for a new phone number.
  ///
  /// In nl, this message translates to:
  /// **'Telefoonnummer toevoegen'**
  String get contactAddPhone;

  /// Title of the sheet, and tooltip of the button, for a new email address.
  ///
  /// In nl, this message translates to:
  /// **'E-mailadres toevoegen'**
  String get contactAddEmail;

  /// Title of the sheet for changing a phone number.
  ///
  /// In nl, this message translates to:
  /// **'Telefoonnummer wijzigen'**
  String get contactEditPhone;

  /// Title of the sheet for changing an email address.
  ///
  /// In nl, this message translates to:
  /// **'E-mailadres wijzigen'**
  String get contactEditEmail;

  /// A standard label of a contact detail, shown translated (PO decision 02-10-2026).
  ///
  /// In nl, this message translates to:
  /// **'{label, select, work{Werk} mobile{Mobiel} private{Privé} other{Anders}}'**
  String contactStandardLabel(String label);

  /// Sheet: the chip that opens a text field for an own label.
  ///
  /// In nl, this message translates to:
  /// **'Eigen label…'**
  String get contactOwnLabel;

  /// Sheet: the text field of an own label.
  ///
  /// In nl, this message translates to:
  /// **'Label'**
  String get contactOwnLabelField;

  /// Sheet: the value is not a phone number (digits, spaces and + ( ) . / - only, at least three digits).
  ///
  /// In nl, this message translates to:
  /// **'Dit lijkt geen telefoonnummer.'**
  String get contactInvalidPhone;

  /// Sheet: the value is not an email address.
  ///
  /// In nl, this message translates to:
  /// **'Dit lijkt geen e-mailadres.'**
  String get contactInvalidEmail;

  /// Sheet: the value is empty.
  ///
  /// In nl, this message translates to:
  /// **'Vul iets in.'**
  String get contactEmpty;

  /// Tooltip of ⋮ on a contact detail.
  ///
  /// In nl, this message translates to:
  /// **'Acties'**
  String get contactMenuTooltip;

  /// Menu of a contact detail: copy the value.
  ///
  /// In nl, this message translates to:
  /// **'Kopiëren'**
  String get contactCopy;

  /// Message after copying a contact detail.
  ///
  /// In nl, this message translates to:
  /// **'Gekopieerd'**
  String get contactCopied;

  /// Menu of a contact detail: change it.
  ///
  /// In nl, this message translates to:
  /// **'Wijzigen…'**
  String get contactEdit;

  /// Menu of a contact detail: delete it, with undo.
  ///
  /// In nl, this message translates to:
  /// **'Verwijderen'**
  String get contactDelete;

  /// Message with undo after deleting a phone number.
  ///
  /// In nl, this message translates to:
  /// **'Telefoonnummer verwijderd'**
  String get contactDeletedPhone;

  /// Message with undo after deleting an email address.
  ///
  /// In nl, this message translates to:
  /// **'E-mailadres verwijderd'**
  String get contactDeletedEmail;

  /// A contact detail could not be saved.
  ///
  /// In nl, this message translates to:
  /// **'Opslaan is mislukt.'**
  String get contactSaveFailed;

  /// Undo of a deleted contact detail failed, for example because the person was merged meanwhile.
  ///
  /// In nl, this message translates to:
  /// **'Het gegeven kon niet terugkomen.'**
  String get contactUndoFailed;

  /// What a screen reader says for a contact detail without a label.
  ///
  /// In nl, this message translates to:
  /// **'{value}, {kind}'**
  String contactRowSemantics(String value, String kind);

  /// What a screen reader says for a contact detail with a label.
  ///
  /// In nl, this message translates to:
  /// **'{value}, {label}, {kind}'**
  String contactRowSemanticsWithLabel(String value, String label, String kind);

  /// Menu of a phone number: open it in the dialler (the user still calls).
  ///
  /// In nl, this message translates to:
  /// **'Bellen'**
  String get contactCall;

  /// Menu of an email address: start a message to it in the mail app.
  ///
  /// In nl, this message translates to:
  /// **'Mailen'**
  String get contactMail;

  /// No dialler or mail app took a phone number or address.
  ///
  /// In nl, this message translates to:
  /// **'Geen app gevonden om dit te openen.'**
  String get contactLaunchFailed;

  /// Overview, Horizon: title of the timeline card (T10.7).
  ///
  /// In nl, this message translates to:
  /// **'Komende {weeks} weken'**
  String horizonTitle(int weeks);

  /// Overview, Horizon: how many lanes (projects) and items the timeline shows.
  ///
  /// In nl, this message translates to:
  /// **'{lanes, plural, =1{1 baan} other{{lanes} banen}} · {items, plural, =1{1 item} other{{items} items}}'**
  String horizonSummary(int lanes, int items);

  /// Overview, Horizon: label above the lane names, left of the week numbers.
  ///
  /// In nl, this message translates to:
  /// **'week'**
  String get horizonWeekColumn;

  /// Overview, Horizon: the first day of a week column, short (day and month).
  ///
  /// In nl, this message translates to:
  /// **'{date}'**
  String horizonDay(DateTime date);

  /// Overview, Horizon: label of a week with at least "Busy from" items to deliver; text, not only colour (DD-017).
  ///
  /// In nl, this message translates to:
  /// **'druk'**
  String get horizonBusy;

  /// Overview, Horizon: the lane of items without a project, the last lane.
  ///
  /// In nl, this message translates to:
  /// **'Geen project'**
  String get horizonNoProject;

  /// Overview, Horizon: shown instead of the lanes when nothing has a deadline or expected day.
  ///
  /// In nl, this message translates to:
  /// **'Niets met een datum in de komende {weeks} weken.'**
  String horizonEmpty(int weeks);

  /// Overview, Horizon legend: a filled blue dot, a deadline of mine.
  ///
  /// In nl, this message translates to:
  /// **'ik lever'**
  String get horizonLegendDeliver;

  /// Overview, Horizon legend: a blue ring, waiting with an expected day.
  ///
  /// In nl, this message translates to:
  /// **'wacht op ander'**
  String get horizonLegendWaiting;

  /// Overview, Horizon legend: a filled orange dot, a deadline that has passed.
  ///
  /// In nl, this message translates to:
  /// **'verlopen'**
  String get horizonLegendOverdue;

  /// Overview, Horizon legend: an orange ring, waiting past its expected day.
  ///
  /// In nl, this message translates to:
  /// **'te laat binnen'**
  String get horizonLegendLate;

  /// Overview, Horizon: header of the list of one week.
  ///
  /// In nl, this message translates to:
  /// **'Week {number} · {from} – {to}'**
  String horizonWeekRange(int number, DateTime from, DateTime to);

  /// Overview, Horizon: header of the list of the first week, which starts today.
  ///
  /// In nl, this message translates to:
  /// **'Week {number} · vanaf {from}'**
  String horizonWeekFrom(int number, DateTime from);

  /// Overview, Horizon: label in the header of a week list, the items I deliver that week.
  ///
  /// In nl, this message translates to:
  /// **'{count} te leveren'**
  String horizonToDeliver(int count);

  /// Overview, Horizon: the same label for a busy week.
  ///
  /// In nl, this message translates to:
  /// **'{count} te leveren · druk'**
  String horizonToDeliverBusy(int count);

  /// Overview, Horizon: the list of a week without items.
  ///
  /// In nl, this message translates to:
  /// **'Niets in deze week.'**
  String get horizonWeekEmpty;

  /// Overview, Horizon list: an item I deliver, with its deadline.
  ///
  /// In nl, this message translates to:
  /// **'Deadline {date}'**
  String horizonEntryDue(DateTime date);

  /// Overview, Horizon list: an item whose deadline has passed.
  ///
  /// In nl, this message translates to:
  /// **'Verlopen · {date}'**
  String horizonEntryOverdue(DateTime date);

  /// Overview, Horizon list: a waiting item with its person and expected day.
  ///
  /// In nl, this message translates to:
  /// **'Wacht op {person} · verwacht {date}'**
  String horizonEntryWaiting(String person, DateTime date);

  /// Overview, Horizon list: a waiting item without a person, with its expected day.
  ///
  /// In nl, this message translates to:
  /// **'Wacht · verwacht {date}'**
  String horizonEntryWaitingNobody(DateTime date);

  /// Overview, Horizon list: a waiting item past its expected day (as the group on Today).
  ///
  /// In nl, this message translates to:
  /// **'Had binnen moeten zijn · {date}'**
  String horizonEntryLate(DateTime date);

  /// Overview, Horizon list: who asked for the item (the requester).
  ///
  /// In nl, this message translates to:
  /// **'voor {person}'**
  String horizonEntryFor(String person);

  /// Overview, Horizon list: joins the parts of the line under an item (date, project, person).
  ///
  /// In nl, this message translates to:
  /// **'{text} · {more}'**
  String horizonEntryMore(String text, String more);

  /// Overview, Horizon: what a screen reader says for one week column (DD-017: a textual equivalent).
  ///
  /// In nl, this message translates to:
  /// **'Week {number}, {from} tot {to}: {deliver, plural, =0{niets te leveren} =1{1 te leveren} other{{deliver} te leveren}}{busy, select, true{, druk} other{}}; {waiting, plural, =0{niets wachtend} =1{1 wachtend} other{{waiting} wachtend}}'**
  String horizonWeekSemantics(
    int number,
    DateTime from,
    DateTime to,
    int deliver,
    String busy,
    int waiting,
  );

  /// Overview, Standstill: title of the treemap card (T10.7).
  ///
  /// In nl, this message translates to:
  /// **'Wat ligt er stil?'**
  String get standstillTitle;

  /// Overview, Standstill: what the size of a tile means.
  ///
  /// In nl, this message translates to:
  /// **'grootte = open items'**
  String get standstillSizeHint;

  /// Overview, Standstill: the open items of a project, on a large tile.
  ///
  /// In nl, this message translates to:
  /// **'{count} open'**
  String standstillOpen(int count);

  /// Overview, Standstill: how long a project has stood still, on a large tile, e.g. "stil 4 wk".
  ///
  /// In nl, this message translates to:
  /// **'stil {age}'**
  String standstillStill(String age);

  /// Overview, Standstill: count and age on a small tile, e.g. "6 · 2 wk".
  ///
  /// In nl, this message translates to:
  /// **'{count} · {age}'**
  String standstillTileShort(int count, String age);

  /// Overview, Standstill: an age shorter than two weeks, in days.
  ///
  /// In nl, this message translates to:
  /// **'{days} d'**
  String standstillAgeDays(int days);

  /// Overview, Standstill: an age of two weeks or more, in weeks.
  ///
  /// In nl, this message translates to:
  /// **'{weeks} wk'**
  String standstillAgeWeeks(int weeks);

  /// Overview, Standstill: an age in days, for a screen reader.
  ///
  /// In nl, this message translates to:
  /// **'{days, plural, =1{1 dag} other{{days} dagen}}'**
  String standstillAgeSpokenDays(int days);

  /// Overview, Standstill: an age in weeks, for a screen reader.
  ///
  /// In nl, this message translates to:
  /// **'{weeks, plural, =1{1 week} other{{weeks} weken}}'**
  String standstillAgeSpokenWeeks(int weeks);

  /// Overview, Standstill: what a screen reader says for one tile (DD-017: a textual equivalent).
  ///
  /// In nl, this message translates to:
  /// **'{project}: {count} open, {age} stil'**
  String standstillTileSemantics(String project, int count, String age);

  /// Overview, Standstill legend: the four classes of time since the last touch.
  ///
  /// In nl, this message translates to:
  /// **'{level, select, fresh{< 1 wk} weeks{1–3 wk} longer{3–6 wk} other{> 6 wk}}'**
  String standstillLevel(String level);

  /// Overview, Standstill: header of the list of the three items untouched the longest.
  ///
  /// In nl, this message translates to:
  /// **'Langst niet aangeraakt'**
  String get standstillOldest;

  /// Overview, Standstill: link that starts the weekly review (not shown inside it).
  ///
  /// In nl, this message translates to:
  /// **'Naar weekoverzicht →'**
  String get standstillToReview;

  /// Overview, Standstill: header of the list of one tapped tile.
  ///
  /// In nl, this message translates to:
  /// **'{project} · {count} open'**
  String standstillProjectItems(String project, int count);

  /// Overview, Standstill: link that opens the project of the tapped tile.
  ///
  /// In nl, this message translates to:
  /// **'Project openen →'**
  String get standstillOpenProject;

  /// Overview, Standstill: tooltip of the button that leaves a tapped tile.
  ///
  /// In nl, this message translates to:
  /// **'Terug naar langst niet aangeraakt'**
  String get standstillShowOldest;

  /// Overview, Standstill: shown instead of the tiles when nothing is open.
  ///
  /// In nl, this message translates to:
  /// **'Niets open: er ligt niets stil.'**
  String get standstillEmpty;

  /// Navigation: the fifth destination, the Overview (T10.7, SPEC Q27).
  ///
  /// In nl, this message translates to:
  /// **'Inzicht'**
  String get navInsights;

  /// Insights: today and its ISO week number in the top bar.
  ///
  /// In nl, this message translates to:
  /// **'{date} · wk {week}'**
  String insightsDate(DateTime date, int week);

  /// Insights: the segments; "both" is Horizon and Standstill side by side on Windows.
  ///
  /// In nl, this message translates to:
  /// **'{segment, select, horizon{Horizon} standstill{Stilstand} both{Horizon en stilstand} connections{Verbanden} other{Personen}}'**
  String insightsSegment(String segment);

  /// Weekly review: the first step, the Overview (DD-018 point 12 (g)).
  ///
  /// In nl, this message translates to:
  /// **'Inzicht'**
  String get reviewStepInsights;

  /// Weekly review start screen: what the Insights step shows.
  ///
  /// In nl, this message translates to:
  /// **'Wat komt eraan, wat ligt stil, hoe sta je ervoor met wie'**
  String get reviewInsightsSummary;

  /// Weekly review: the button after the Insights step.
  ///
  /// In nl, this message translates to:
  /// **'Verder'**
  String get reviewContinue;

  /// Settings: header of the section of the Overview.
  ///
  /// In nl, this message translates to:
  /// **'Inzicht'**
  String get settingsInsightsHeader;

  /// Settings: from how many items to deliver a week is busy on the Horizon.
  ///
  /// In nl, this message translates to:
  /// **'Druk vanaf'**
  String get settingsBusyFrom;

  /// Settings: explanation under Busy from.
  ///
  /// In nl, this message translates to:
  /// **'Een week met zo veel items met een deadline, of meer, heet druk in de Horizon.'**
  String get settingsBusyFromHint;

  /// Settings: a number of items in the Busy from choice.
  ///
  /// In nl, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String settingsItemCount(int count);

  /// Overview, Standstill on Windows: the tooltip of a tile (name, open items, age).
  ///
  /// In nl, this message translates to:
  /// **'{project} · {count} open · {age}'**
  String standstillTileTooltip(String project, int count, String age);

  /// Button in the item detail and a project, and the title of its form (T10.3, REQ-049).
  ///
  /// In nl, this message translates to:
  /// **'Waar was ik?'**
  String get whereWasI;

  /// Windows: tooltip of the Where was I button, with its key.
  ///
  /// In nl, this message translates to:
  /// **'Waar was ik? (Ctrl+Shift+P)'**
  String get whereWasITooltipWithKey;

  /// Where was I form: the first field.
  ///
  /// In nl, this message translates to:
  /// **'Volgende stap'**
  String get whereWasINextStep;

  /// Where was I form: the second field.
  ///
  /// In nl, this message translates to:
  /// **'Wat ik in mijn hoofd had'**
  String get whereWasIInMind;

  /// Where was I form: hint in the second field.
  ///
  /// In nl, this message translates to:
  /// **'Bijv. waarom, wat je wilde checken…'**
  String get whereWasIInMindHint;

  /// Where was I form: closes it and keeps what was typed (not Cancel, PO 02-10-2026).
  ///
  /// In nl, this message translates to:
  /// **'Sluiten'**
  String get whereWasIClose;

  /// Where was I form: saves.
  ///
  /// In nl, this message translates to:
  /// **'Opslaan'**
  String get whereWasISave;

  /// Message when the Where was I note could not be saved.
  ///
  /// In nl, this message translates to:
  /// **'Waar was ik? is niet opgeslagen.'**
  String get whereWasISaveFailed;

  /// Resume card at the top of an item or project: its header.
  ///
  /// In nl, this message translates to:
  /// **'Waar was ik'**
  String get resumeCardTitle;

  /// Resume card: opens the form filled in.
  ///
  /// In nl, this message translates to:
  /// **'Bijwerken'**
  String get resumeUpdate;

  /// Resume card: closes the note.
  ///
  /// In nl, this message translates to:
  /// **'Hervat'**
  String get resumeResume;

  /// Connections: the label above the focus title; kind is item, person or project.
  ///
  /// In nl, this message translates to:
  /// **'{kind, select, person{Focus · persoon} project{Focus · project} other{Focus}}'**
  String connectionsFocusKind(String kind);

  /// Connections: button that opens the sheet to choose another focus.
  ///
  /// In nl, this message translates to:
  /// **'Wijzig'**
  String get connectionsChange;

  /// Connections: depth switch, only the direct connections.
  ///
  /// In nl, this message translates to:
  /// **'1 stap'**
  String get connectionsOneStep;

  /// Connections: depth switch, also what is linked to those.
  ///
  /// In nl, this message translates to:
  /// **'2 stappen'**
  String get connectionsTwoSteps;

  /// Connections legend: a solid line.
  ///
  /// In nl, this message translates to:
  /// **'direct gekoppeld'**
  String get connectionsLegendDirect;

  /// Connections legend: a dotted line, the second step.
  ///
  /// In nl, this message translates to:
  /// **'via tussenstap'**
  String get connectionsLegendThrough;

  /// Connections: hint below the graph on a phone.
  ///
  /// In nl, this message translates to:
  /// **'Tik om te focussen · lang indrukken voor een voorbeeld · knijp om te zoomen'**
  String get connectionsHint;

  /// Connections: hint below the graph on Windows.
  ///
  /// In nl, this message translates to:
  /// **'Klik om te focussen · wijs aan voor een voorbeeld · Ctrl+scrollen zoomt'**
  String get connectionsHintDesktop;

  /// Connections: button that zooms the graph so all of it shows.
  ///
  /// In nl, this message translates to:
  /// **'Passend'**
  String get connectionsFit;

  /// Connections: the node for direct connections that are not drawn; opens the list.
  ///
  /// In nl, this message translates to:
  /// **'+{count} meer'**
  String connectionsMore(int count);

  /// Connections without a focus: title.
  ///
  /// In nl, this message translates to:
  /// **'Hoe hangt het samen?'**
  String get connectionsEmptyTitle;

  /// Connections without a focus: explanation.
  ///
  /// In nl, this message translates to:
  /// **'Kies een item, persoon of project; je ziet wat ermee verbonden is.'**
  String get connectionsEmptyBody;

  /// Connections without a focus: button that opens the sheet to choose one.
  ///
  /// In nl, this message translates to:
  /// **'Kies een item'**
  String get connectionsChoose;

  /// Connections: the focus has no connections.
  ///
  /// In nl, this message translates to:
  /// **'Nog niets gekoppeld'**
  String get connectionsNothing;

  /// Connections: title of the sheet to choose a focus.
  ///
  /// In nl, this message translates to:
  /// **'Focus kiezen'**
  String get connectionsChooseTitle;

  /// Connections: hint in the search field of the focus sheet.
  ///
  /// In nl, this message translates to:
  /// **'Zoek een item, persoon of project'**
  String get connectionsChooseHint;

  /// Connections focus sheet: header above what was opened last.
  ///
  /// In nl, this message translates to:
  /// **'Recent geopend'**
  String get connectionsRecent;

  /// Connections focus sheet: header above the items found.
  ///
  /// In nl, this message translates to:
  /// **'Items'**
  String get connectionsChooseItems;

  /// Connections focus sheet: header above the people found.
  ///
  /// In nl, this message translates to:
  /// **'Personen'**
  String get connectionsChoosePeople;

  /// Connections focus sheet: header above the projects found.
  ///
  /// In nl, this message translates to:
  /// **'Projecten'**
  String get connectionsChooseProjects;

  /// Connections focus sheet: nothing matches.
  ///
  /// In nl, this message translates to:
  /// **'Niets gevonden'**
  String get connectionsNoResults;

  /// Connections: title of the list of all direct connections.
  ///
  /// In nl, this message translates to:
  /// **'Verbanden van {name} · {count}'**
  String connectionsAllTitle(String name, int count);

  /// Connections list: header.
  ///
  /// In nl, this message translates to:
  /// **'Direct gekoppeld · {count}'**
  String connectionsDirectHeader(int count);

  /// Connections preview: makes the node the focus.
  ///
  /// In nl, this message translates to:
  /// **'Focussen'**
  String get connectionsFocusAction;

  /// Connections preview: opens the item, person or project.
  ///
  /// In nl, this message translates to:
  /// **'Openen'**
  String get connectionsOpenAction;

  /// Connections: screen reader action that shows the preview of a node.
  ///
  /// In nl, this message translates to:
  /// **'Voorbeeld'**
  String get connectionsPreviewAction;

  /// Menu of an item, person or project: opens Insights → Connections with it as the focus.
  ///
  /// In nl, this message translates to:
  /// **'Verbanden tonen'**
  String get connectionsShow;

  /// Connections: the type line of a project, a person, or an item without a type.
  ///
  /// In nl, this message translates to:
  /// **'{kind, select, project{Project} person{Persoon} other{Item}}'**
  String connectionsKind(String kind);

  /// Connections: added to the type line of an item due today or overdue.
  ///
  /// In nl, this message translates to:
  /// **'{urgency, select, today{vandaag} other{verlopen}}'**
  String connectionsUrgency(String urgency);

  /// Connections: added to the type line of a done item.
  ///
  /// In nl, this message translates to:
  /// **'af'**
  String get connectionsDone;

  /// Connections: added to the type line of an archived item or project.
  ///
  /// In nl, this message translates to:
  /// **'gearchiveerd'**
  String get connectionsArchived;

  /// Connections: why a node is linked to the focus.
  ///
  /// In nl, this message translates to:
  /// **'{reason, select, linksTo{koppeling} linkedFrom{verwijst hiernaar} project{project} inProject{in dit project} parent{hoofdproject} other{subproject}}'**
  String connectionsReason(String reason);

  /// Connections: how an item and a person are linked; name is the person.
  ///
  /// In nl, this message translates to:
  /// **'{reason, select, requester{gevraagd door {name}} waitingOn{wacht op {name}} other{noemt {name}}}'**
  String connectionsReasonPerson(String reason, String name);

  /// Connections, screen reader: the focus with its counts.
  ///
  /// In nl, this message translates to:
  /// **'Focus: {kind} {title}. {direct} direct gekoppeld, {through} via een tussenstap.'**
  String connectionsFocusSemantics(
    String kind,
    String title,
    int direct,
    int through,
  );

  /// Connections, screen reader: a direct node.
  ///
  /// In nl, this message translates to:
  /// **'Direct gekoppeld: {kind} {title}, {reasons}'**
  String connectionsDirectSemantics(String kind, String title, String reasons);

  /// Connections, screen reader: a second-step node; via is the node it goes through.
  ///
  /// In nl, this message translates to:
  /// **'Via tussenstap {via}: {kind} {title}'**
  String connectionsThroughSemantics(String via, String kind, String title);

  /// Connections, screen reader: more second-step nodes behind a node than are drawn.
  ///
  /// In nl, this message translates to:
  /// **'nog {count} via {title}'**
  String connectionsBehindSemantics(int count, String title);

  /// Connections, screen reader: the "+n more" node.
  ///
  /// In nl, this message translates to:
  /// **'Nog {count} verbanden, opent de lijst'**
  String connectionsMoreSemantics(int count);

  /// Connections preview: the project of the item.
  ///
  /// In nl, this message translates to:
  /// **'Project'**
  String get connectionsPreviewProject;

  /// Connections preview: the deadline of the item.
  ///
  /// In nl, this message translates to:
  /// **'Deadline'**
  String get connectionsPreviewDeadline;

  /// Connections preview: the people of the item.
  ///
  /// In nl, this message translates to:
  /// **'Personen'**
  String get connectionsPreviewPeople;

  /// Connections preview: a deadline.
  ///
  /// In nl, this message translates to:
  /// **'{date}'**
  String connectionsPreviewDate(DateTime date);

  /// Connections preview of a person or project: how many open items are linked.
  ///
  /// In nl, this message translates to:
  /// **'{count, plural, =0{Geen open items} =1{1 open item} other{{count} open items}}'**
  String connectionsPreviewOpenItems(int count);

  /// Connections: two parts of a line, such as the type and the status.
  ///
  /// In nl, this message translates to:
  /// **'{first} · {second}'**
  String connectionsJoin(String first, String second);

  /// Connections: items of a list, such as names or reasons.
  ///
  /// In nl, this message translates to:
  /// **'{first}, {second}'**
  String connectionsList(String first, String second);

  /// Name of the notification channel in Android's settings (deadlines and Revisit on).
  ///
  /// In nl, this message translates to:
  /// **'Herinneringen'**
  String get reminderChannelName;

  /// Reminder notification for one item due today: its title.
  ///
  /// In nl, this message translates to:
  /// **'Deadline vandaag'**
  String get reminderTitleOne;

  /// Reminder notification for more items due today: its title.
  ///
  /// In nl, this message translates to:
  /// **'{count} deadlines vandaag'**
  String reminderTitleMany(int count);

  /// Reminder notification: the last line when there are more than five items.
  ///
  /// In nl, this message translates to:
  /// **'en nog {count}'**
  String reminderMore(int count);

  /// Message after the notification permission was refused.
  ///
  /// In nl, this message translates to:
  /// **'Zonder meldingen zie je deadlines en teruggekomen items op Vandaag.'**
  String get reminderRefused;

  /// Action of the refusal message: opens the Android notification settings of the app.
  ///
  /// In nl, this message translates to:
  /// **'Instellingen'**
  String get reminderRefusedAction;

  /// Settings: section header.
  ///
  /// In nl, this message translates to:
  /// **'Herinneringen'**
  String get settingsRemindersHeader;

  /// Settings: switch for the reminders of deadlines and of items back from Revisit on.
  ///
  /// In nl, this message translates to:
  /// **'Meldingen bij deadlines en terugzien'**
  String get settingsRemindersOn;

  /// Settings: explanation under the switch.
  ///
  /// In nl, this message translates to:
  /// **'Op de dag zelf; één melding per dag.'**
  String get settingsRemindersOnHint;

  /// Settings: when the reminder of a day comes.
  ///
  /// In nl, this message translates to:
  /// **'Tijdstip'**
  String get settingsReminderTime;

  /// Settings: explanation under the time.
  ///
  /// In nl, this message translates to:
  /// **'Wanneer de melding van die dag komt.'**
  String get settingsReminderTimeHint;

  /// Settings: notifications for the app are off in the system.
  ///
  /// In nl, this message translates to:
  /// **'Meldingen staan uit in Android'**
  String get settingsRemindersBlocked;

  /// Settings: explanation when notifications are off in the system.
  ///
  /// In nl, this message translates to:
  /// **'Deadlines en teruggekomen items staan wel op Vandaag.'**
  String get settingsRemindersBlockedHint;

  /// Settings: opens the system's notification settings of the app.
  ///
  /// In nl, this message translates to:
  /// **'Meldingen toestaan'**
  String get settingsRemindersAllow;

  /// Item detail menu, triage and review: parks the item until a date (REQ-021, DD-018 point 17).
  ///
  /// In nl, this message translates to:
  /// **'Terugzien op…'**
  String get revisitAction;

  /// Title of the sheet (dialog on Windows) with the dates to revisit an item on.
  ///
  /// In nl, this message translates to:
  /// **'Terugzien op'**
  String get revisitSheetTitle;

  /// Revisit sheet: the quick choice tomorrow.
  ///
  /// In nl, this message translates to:
  /// **'Morgen'**
  String get revisitTomorrow;

  /// Revisit sheet: the quick choice next Monday.
  ///
  /// In nl, this message translates to:
  /// **'Volgende week'**
  String get revisitNextWeek;

  /// Revisit sheet: the quick choice the same day next month.
  ///
  /// In nl, this message translates to:
  /// **'Over een maand'**
  String get revisitInAMonth;

  /// Revisit sheet: opens the date picker, from tomorrow.
  ///
  /// In nl, this message translates to:
  /// **'Kies datum…'**
  String get revisitChooseDate;

  /// Revisit sheet and the line in the item detail: the item is no longer parked and becomes active.
  ///
  /// In nl, this message translates to:
  /// **'Niet meer terugzien'**
  String get revisitStop;

  /// A revisit date, short (e.g. 'ma 12 okt'): next to a quick choice and on the chip of a parked card.
  ///
  /// In nl, this message translates to:
  /// **'{date}'**
  String revisitDate(DateTime date);

  /// Item detail of a parked item, under the status; also what a screen reader reads for its chip on a card.
  ///
  /// In nl, this message translates to:
  /// **'Terugzien op {date}'**
  String revisitLine(DateTime date);

  /// Message after parking an item, with Undo.
  ///
  /// In nl, this message translates to:
  /// **'Terug op {date}'**
  String revisitBackOn(DateTime date);

  /// Triage and weekly review (step Stale): parks the card until a date.
  ///
  /// In nl, this message translates to:
  /// **'Later…'**
  String get revisitLater;

  /// Triage on Windows: the Later button with its key.
  ///
  /// In nl, this message translates to:
  /// **'Later…  {key}'**
  String revisitLaterWithKey(String key);

  /// Weekly review: what was done with a card parked with Later.
  ///
  /// In nl, this message translates to:
  /// **'✓ Terug op {date}'**
  String reviewHandledParked(DateTime date);

  /// Weekly review end screen: how many items were parked with Later.
  ///
  /// In nl, this message translates to:
  /// **'{count} later terugzien'**
  String reviewEndParked(int count);

  /// Today: the group of items that came back from Revisit on and are still in the inbox.
  ///
  /// In nl, this message translates to:
  /// **'Terug in je inbox · {count}'**
  String todayBackSection(int count);

  /// Reminder notification for one item back from Revisit on, and nothing due: its title (the item's title below).
  ///
  /// In nl, this message translates to:
  /// **'Terug in je inbox'**
  String get reminderBackOne;

  /// Reminder notification for more items back from Revisit on, and nothing due: its title.
  ///
  /// In nl, this message translates to:
  /// **'{count} terug in je inbox'**
  String reminderBackMany(int count);

  /// Reminder notification for a day with deadlines and items back from Revisit on: its title.
  ///
  /// In nl, this message translates to:
  /// **'{deadlines, plural, =1{1 deadline} other{{deadlines} deadlines}} · {back} terug in je inbox'**
  String reminderTitleBoth(int deadlines, int back);

  /// A line in the reminder notification for an item back from Revisit on, under the deadlines.
  ///
  /// In nl, this message translates to:
  /// **'Terug: {title}'**
  String reminderBackLine(String title);

  /// Settings → Reminders: switch for the weekly-review reminder (REQ-022).
  ///
  /// In nl, this message translates to:
  /// **'Herinnering weekoverzicht'**
  String get settingsReviewReminderOn;

  /// Settings → Reminders: under the weekly-review reminder switch.
  ///
  /// In nl, this message translates to:
  /// **'Alleen als het weekoverzicht aan de beurt is.'**
  String get settingsReviewReminderOnHint;

  /// Settings → Reminders: the weekday of the weekly-review reminder.
  ///
  /// In nl, this message translates to:
  /// **'Dag'**
  String get settingsReviewReminderDay;

  /// A weekday written out (e.g. 'vrijdag'), in the choice of the weekly-review reminder's day.
  ///
  /// In nl, this message translates to:
  /// **'{date}'**
  String settingsReviewReminderDayName(DateTime date);

  /// Weekly-review reminder notification: its title (also on the lock screen).
  ///
  /// In nl, this message translates to:
  /// **'Weekoverzicht aan de beurt'**
  String get reviewReminderTitle;

  /// Weekly-review reminder notification: the line under the title, days since the last completed review.
  ///
  /// In nl, this message translates to:
  /// **'{days, plural, =1{Laatste keer 1 dag geleden} other{Laatste keer {days} dagen geleden}}'**
  String reviewReminderLast(int days);

  /// Weekly-review reminder notification: the line under the title when no review was completed yet.
  ///
  /// In nl, this message translates to:
  /// **'Nog niet gedaan'**
  String get reviewReminderNever;

  /// Birthday reminder notification for one person: its title.
  ///
  /// In nl, this message translates to:
  /// **'{name} is vandaag jarig'**
  String birthdayReminderOne(String name);

  /// Birthday reminder notification for one person whose year is known: the line under the title.
  ///
  /// In nl, this message translates to:
  /// **'wordt {age}'**
  String birthdayReminderTurns(int age);

  /// Birthday reminder notification for more people: its title, and the lock screen's.
  ///
  /// In nl, this message translates to:
  /// **'{count} verjaardagen vandaag'**
  String birthdayReminderMany(int count);

  /// Birthday reminder notification for more people: a line with a name and the age reached.
  ///
  /// In nl, this message translates to:
  /// **'{name} ({age})'**
  String birthdayReminderPersonAge(String name, int age);

  /// Birthday reminder for one person on the lock screen: never the name.
  ///
  /// In nl, this message translates to:
  /// **'Verjaardag vandaag'**
  String get birthdayReminderPublic;

  /// Today: the line for a person whose birthday is today, year unknown; a tap opens the person.
  ///
  /// In nl, this message translates to:
  /// **'{name} is vandaag jarig'**
  String todayBirthday(String name);

  /// Today: the line for a person whose birthday is today, with the age reached; a tap opens the person.
  ///
  /// In nl, this message translates to:
  /// **'{name} wordt vandaag {age}'**
  String todayBirthdayAge(String name, int age);

  /// Settings → Reminders: switch for the birthday reminders (REQ-031).
  ///
  /// In nl, this message translates to:
  /// **'Verjaardagen'**
  String get settingsBirthdayRemindersOn;

  /// Settings → Reminders: under the birthday switch.
  ///
  /// In nl, this message translates to:
  /// **'Op de dag zelf, op het tijdstip van de dagmelding.'**
  String get settingsBirthdayRemindersOnHint;

  /// A waiting item that stays silent: how many days without a touch (chip on Today, line in the item).
  ///
  /// In nl, this message translates to:
  /// **'{days, plural, =1{1 dag stil} other{{days} dagen stil}}'**
  String nudgeSilentDays(int days);

  /// Nudge notification for one silent waiting item: its title (the item's title below).
  ///
  /// In nl, this message translates to:
  /// **'Wacht nog op {person} · {days, plural, =1{1 dag stil} other{{days} dagen stil}}'**
  String nudgeReminderOne(String person, int days);

  /// Nudge notification for one silent waiting item without a person: its title.
  ///
  /// In nl, this message translates to:
  /// **'Wacht nog · {days, plural, =1{1 dag stil} other{{days} dagen stil}}'**
  String nudgeReminderOneNobody(int days);

  /// Nudge notification for more silent waiting items: its title, also on the lock screen.
  ///
  /// In nl, this message translates to:
  /// **'{count} wacht-items blijven stil'**
  String nudgeReminderMany(int count);

  /// Nudge notification for one item on the lock screen: never the title or the person.
  ///
  /// In nl, this message translates to:
  /// **'Wacht-item blijft stil'**
  String get nudgeReminderPublic;

  /// Today: the group of waiting items without a touch for X days (AC REQ-047).
  ///
  /// In nl, this message translates to:
  /// **'Blijft stil · {count}'**
  String todaySilentSection(int count);

  /// Today, group Blijft stil: completes the waiting item as received.
  ///
  /// In nl, this message translates to:
  /// **'Ontvangen'**
  String get nudgeReceived;

  /// Today: the group of open 'Where was I' notes at the top (T4b.2, DD-018 point 13 (e)).
  ///
  /// In nl, this message translates to:
  /// **'Waar was ik · {count}'**
  String todayNotesSection(int count);

  /// Today: button under the first three 'Where was I' notes that shows the rest in place.
  ///
  /// In nl, this message translates to:
  /// **'+{count} meer'**
  String todayNotesMore(int count);

  /// Today: second line of a 'Where was I' note without a next step: what was in mind.
  ///
  /// In nl, this message translates to:
  /// **'In mijn hoofd: {text}'**
  String todayNoteInMind(String text);

  /// Today: what a screen reader says for the project icon on a 'Where was I' note of a project.
  ///
  /// In nl, this message translates to:
  /// **'Project'**
  String get todayNoteProject;

  /// Settings: header of the section about the Today screen.
  ///
  /// In nl, this message translates to:
  /// **'Vandaag'**
  String get settingsTodayHeader;

  /// Settings: switch that shows the open 'Where was I' notes at the top of Today (T4b.2); a setting of this device.
  ///
  /// In nl, this message translates to:
  /// **'Waar was ik op Vandaag'**
  String get settingsTodayNotes;

  /// Settings: second line of the switch Waar was ik op Vandaag.
  ///
  /// In nl, this message translates to:
  /// **'Je open notities bovenaan Vandaag, nieuwste eerst.'**
  String get settingsTodayNotesHint;

  /// Today, group Blijft stil, and the item's commitment block: records that you chased it; the period starts again.
  ///
  /// In nl, this message translates to:
  /// **'Nagevraagd'**
  String get nudgeChased;

  /// Message after Chased (no undo: putting the moment back would be a touch too).
  ///
  /// In nl, this message translates to:
  /// **'Nagevraagd'**
  String get nudgeChasedMessage;

  /// Settings → Reminders: switch for the nudge notification (AC REQ-047).
  ///
  /// In nl, this message translates to:
  /// **'Wacht-items die stil blijven'**
  String get settingsNudgeOn;

  /// Settings → Reminders: under the nudge switch.
  ///
  /// In nl, this message translates to:
  /// **'Eén melding op de dag dat een item stil wordt.'**
  String get settingsNudgeOnHint;

  /// Settings → Reminders: after how many days without a touch a waiting item is silent.
  ///
  /// In nl, this message translates to:
  /// **'Navragen na'**
  String get settingsNudgeAfter;

  /// Settings → Reminders: under Chase after.
  ///
  /// In nl, this message translates to:
  /// **'Zo lang niets veranderd: dan staat het item op Vandaag.'**
  String get settingsNudgeAfterHint;

  /// Repeat word of the inline syntax after '!' (DD-004 point 14, REQ-061), in lowercase without spaces. Several words may be given, separated by commas; the last is the one the suggestion list inserts. The words of every app language are recognised, whatever language is shown. Means: every day.
  ///
  /// In nl, this message translates to:
  /// **'dagelijks'**
  String get tokenRepeatDaily;

  /// Repeat word of the inline syntax after '!' (DD-004 point 14, REQ-061), in lowercase without spaces. Several words may be given, separated by commas; the last is the one the suggestion list inserts. The words of every app language are recognised, whatever language is shown. Means: every week, on the weekday of the first time.
  ///
  /// In nl, this message translates to:
  /// **'wekelijks'**
  String get tokenRepeatWeekly;

  /// Repeat word of the inline syntax after '!' (DD-004 point 14, REQ-061), in lowercase without spaces. Several words may be given, separated by commas; the last is the one the suggestion list inserts. The words of every app language are recognised, whatever language is shown. Means: every month, on the day of the month of the first time.
  ///
  /// In nl, this message translates to:
  /// **'maandelijks'**
  String get tokenRepeatMonthly;

  /// Name of the repeat token (!dagelijks, !wekelijks, !maandelijks) for chips, screen readers, the prefix bar and the syntax overview (REQ-061).
  ///
  /// In nl, this message translates to:
  /// **'herhalen'**
  String get tokenRepeatLabel;

  /// Example line for the repeat token in the syntax overview; use this language's repeat words (tokenRepeatDaily, tokenRepeatWeekly, tokenRepeatMonthly) and a date word.
  ///
  /// In nl, this message translates to:
  /// **'Hardlopen !wekelijks !di, ook !dagelijks of !maandelijks'**
  String get tokenRepeatExample;

  /// Message after completing a time of a recurring task (REQ-061), with an Undo button; date is the next time.
  ///
  /// In nl, this message translates to:
  /// **'Afgerond · volgende keer {date}'**
  String itemCompletedNextTime(DateTime date);

  /// The rhythm of a recurring task on cards, in lowercase (REQ-061). code is 1-letter: D daily, W weekly, M monthly.
  ///
  /// In nl, this message translates to:
  /// **'{code, select, D{dagelijks} W{wekelijks} M{maandelijks} other{herhaalt}}'**
  String repeatRhythm(String code);

  /// The rhythm of a recurring task as a chip while typing and as a choice in 'Complete and repeat' (REQ-061). code: D daily, W weekly, M monthly.
  ///
  /// In nl, this message translates to:
  /// **'{code, select, D{Dagelijks} W{Wekelijks} M{Maandelijks} other{Herhaalt}}'**
  String repeatRhythmTitle(String code);

  /// Second line of a repeat word in the suggestion list (REQ-061). code: D daily, W weekly, M monthly.
  ///
  /// In nl, this message translates to:
  /// **'{code, select, D{elke dag} W{elke week} M{elke maand} other{herhaalt}}'**
  String repeatEvery(String code);

  /// Chip of a daily recurring task in the item detail; since is its first time.
  ///
  /// In nl, this message translates to:
  /// **'Dagelijks · sinds {since}'**
  String repeatSinceDaily(DateTime since);

  /// Chip of a weekly recurring task in the item detail; weekday is the day of the week it repeats on, since its first time.
  ///
  /// In nl, this message translates to:
  /// **'Wekelijks · elke {weekday}, sinds {since}'**
  String repeatSinceWeekly(DateTime weekday, DateTime since);

  /// Chip of a monthly recurring task in the item detail; day is the day of the month (shorter months: their last day), since its first time.
  ///
  /// In nl, this message translates to:
  /// **'Maandelijks · op de {day}e, sinds {since}'**
  String repeatSinceMonthly(int day, DateTime since);

  /// Chip of a repeat word on an idea, request or note, which does not repeat (decision 6b, REQ-061); rhythm is repeatRhythmTitle.
  ///
  /// In nl, this message translates to:
  /// **'{rhythm} · herhaalt alleen bij een taak'**
  String repeatNotForType(String rhythm);

  /// Chip of a recurring task in the item detail: the date of the current time.
  ///
  /// In nl, this message translates to:
  /// **'Deze keer: {date}'**
  String repeatThisTime(DateTime date);

  /// Header of the history of a recurring task in the item detail (REQ-061): how many times it was done.
  ///
  /// In nl, this message translates to:
  /// **'Gedaan · {count}×'**
  String completionsTitle(int count);

  /// A time of a recurring task done on or before its date, in the history.
  ///
  /// In nl, this message translates to:
  /// **'op tijd'**
  String get completionOnTime;

  /// A time of a recurring task done after its date, in the history: the date of that time and how late.
  ///
  /// In nl, this message translates to:
  /// **'keer van {date} · {days, plural, =1{1 dag te laat} other{{days} dagen te laat}}'**
  String completionLate(DateTime date, int days);

  /// Button under the five newest times in the history; shows all.
  ///
  /// In nl, this message translates to:
  /// **'Alles tonen ({count})'**
  String completionsShowAll(int count);

  /// Menu entry in the item detail for a task that does not repeat yet (REQ-061): completes it and lets it come back.
  ///
  /// In nl, this message translates to:
  /// **'Afronden en herhalen…'**
  String get completeAndRepeat;

  /// Title of the sheet or dialog of 'Complete and repeat'.
  ///
  /// In nl, this message translates to:
  /// **'Afronden en herhalen'**
  String get completeAndRepeatTitle;

  /// Line under the title of 'Complete and repeat'.
  ///
  /// In nl, this message translates to:
  /// **'Deze keer is klaar. Wanneer komt hij terug?'**
  String get completeAndRepeatQuestion;

  /// Note at the foot of 'Complete and repeat': the choice adds the repeat word to the text.
  ///
  /// In nl, this message translates to:
  /// **'Zet het woord in de tekst; weghalen stopt de herhaling.'**
  String get completeAndRepeatNote;

  /// Menu entry in the item detail of a recurring task: removes the repeat word and completes the item (REQ-061).
  ///
  /// In nl, this message translates to:
  /// **'Herhaling stoppen'**
  String get stopRepeating;

  /// Message after 'Stop repeating', with an Undo button.
  ///
  /// In nl, this message translates to:
  /// **'Herhaling gestopt · afgerond'**
  String get repeatStopped;

  /// Name of the second home-screen widget in the widget picker (REQ-063): buttons to capture, open Today and (wider) Insights.
  ///
  /// In nl, this message translates to:
  /// **'Offload-balk'**
  String get androidBarName;

  /// Description of the Offload bar widget in the widget picker (REQ-063).
  ///
  /// In nl, this message translates to:
  /// **'Vastleggen, Vandaag en Inzicht met één tik'**
  String get androidBarDescription;

  /// Screen-reader label of the Today button on the Offload bar widget, and the long label of the app shortcut (REQ-063).
  ///
  /// In nl, this message translates to:
  /// **'Vandaag openen'**
  String get androidOpenToday;

  /// Screen-reader label of the Insights button on the Offload bar widget, and the long label of the app shortcut (REQ-063).
  ///
  /// In nl, this message translates to:
  /// **'Inzicht openen'**
  String get androidOpenInsights;

  /// Title of the help screen and of its row in Settings (REQ-065).
  ///
  /// In nl, this message translates to:
  /// **'Help'**
  String get helpTitle;

  /// Second line of the Help row in Settings (REQ-065).
  ///
  /// In nl, this message translates to:
  /// **'De handleiding: hoe Offload werkt'**
  String get helpOpenRow;

  /// Tooltip of the "?" button in the title bar of a screen (REQ-065).
  ///
  /// In nl, this message translates to:
  /// **'Help'**
  String get helpTooltip;

  /// Tooltip of the "?" button on Windows, teaching its key (REQ-065).
  ///
  /// In nl, this message translates to:
  /// **'Help (F1)'**
  String get helpTooltipWithKey;

  /// Button on the help screen that opens the table of contents of the manual (REQ-065).
  ///
  /// In nl, this message translates to:
  /// **'Inhoud'**
  String get helpContents;

  /// Note at the top of the help screen when the app language has no manual of its own (REQ-065, DD-020).
  ///
  /// In nl, this message translates to:
  /// **'De handleiding is in het Engels.'**
  String get helpInEnglish;

  /// Shown on the help screen when a chapter cannot be read (REQ-065).
  ///
  /// In nl, this message translates to:
  /// **'Dit deel van de handleiding kon niet worden geopend.'**
  String get helpLoadFailed;

  /// Message after tapping a link to an internet address in the manual: the app shows it, never opens it (REQ-003, REQ-065).
  ///
  /// In nl, this message translates to:
  /// **'Offload opent geen internetadressen: {address}'**
  String helpExternalLink(String address);

  /// Action of the message about an internet address: copies it (REQ-065).
  ///
  /// In nl, this message translates to:
  /// **'Kopiëren'**
  String get helpCopy;

  /// Button at the bottom of the syntax overview that opens the part of the manual about the signs (REQ-065).
  ///
  /// In nl, this message translates to:
  /// **'Meer in de handleiding'**
  String get syntaxOverviewManual;

  /// Row in Settings → Storage: the encrypted attachments, with their total size (T5.1).
  ///
  /// In nl, this message translates to:
  /// **'Bijlagen'**
  String get storageAttachments;

  /// One kind of attachment with its size, in the Attachments row of Settings → Storage (T5.1).
  ///
  /// In nl, this message translates to:
  /// **'{kind, select, photo{Foto\'s} audio{Audio} other{Overig}} {size}'**
  String storageAttachmentKind(String kind, String size);

  /// Button in the item detail that adds a photo to the item (T5.3, DD-018 point 19); on Android it opens a sheet with camera and gallery.
  ///
  /// In nl, this message translates to:
  /// **'Foto toevoegen'**
  String get photoAdd;

  /// The same button where it opens the Open window directly (Windows: no camera).
  ///
  /// In nl, this message translates to:
  /// **'Foto toevoegen…'**
  String get photoAddOpen;

  /// Choice in the Add photo sheet: take a photo with the device's camera app.
  ///
  /// In nl, this message translates to:
  /// **'Foto maken'**
  String get photoTake;

  /// Choice in the Add photo sheet: choose a photo with Android's photo picker.
  ///
  /// In nl, this message translates to:
  /// **'Uit galerij'**
  String get photoFromGallery;

  /// Name of the file filter for pictures in the Windows Open window.
  ///
  /// In nl, this message translates to:
  /// **'Afbeeldingen'**
  String get photoFileTypeName;

  /// Heading above the row of photos of an item.
  ///
  /// In nl, this message translates to:
  /// **'Foto\'s · {count}'**
  String photosHeader(int count);

  /// Tile at the end of the row while a new photo is made small and encrypted.
  ///
  /// In nl, this message translates to:
  /// **'Foto verwerken…'**
  String get photoProcessing;

  /// Message when a chosen picture cannot be decoded; nothing is kept.
  ///
  /// In nl, this message translates to:
  /// **'Deze foto kan Offload niet lezen.'**
  String get photoUnreadable;

  /// Message when a chosen picture is larger than Offload reads.
  ///
  /// In nl, this message translates to:
  /// **'Deze foto is te groot.'**
  String get photoTooLarge;

  /// Message when the camera app, the photo picker or the file could not be opened or read.
  ///
  /// In nl, this message translates to:
  /// **'De foto kon niet worden geopend.'**
  String get photoSourceFailed;

  /// Message when storing a photo failed.
  ///
  /// In nl, this message translates to:
  /// **'De foto is niet opgeslagen.'**
  String get photoSaveFailed;

  /// What a screen reader says for a thumbnail in the row.
  ///
  /// In nl, this message translates to:
  /// **'Foto {index} van {count}'**
  String photoSemantics(int index, int count);

  /// What a screen reader says for the thumbnail on an item's card in a list (T5.4): how many photos the item has.
  ///
  /// In nl, this message translates to:
  /// **'{count, plural, =1{1 foto} other{{count} foto\'s}}'**
  String cardPhotos(int count);

  /// Menu entry on a thumbnail: open the photo full screen.
  ///
  /// In nl, this message translates to:
  /// **'Bekijken'**
  String get photoView;

  /// Menu entry on a thumbnail and button in the photo viewer: delete the photo (asks first).
  ///
  /// In nl, this message translates to:
  /// **'Verwijderen'**
  String get photoDelete;

  /// Title of the question before deleting a photo.
  ///
  /// In nl, this message translates to:
  /// **'Foto verwijderen?'**
  String get photoDeleteTitle;

  /// Text of the question before deleting a photo; there is no undo.
  ///
  /// In nl, this message translates to:
  /// **'De foto verdwijnt uit dit item. Dit kun je niet ongedaan maken.'**
  String get photoDeleteBody;

  /// Button that keeps the photo.
  ///
  /// In nl, this message translates to:
  /// **'Annuleren'**
  String get photoDeleteCancel;

  /// Message when deleting a photo failed.
  ///
  /// In nl, this message translates to:
  /// **'De foto is niet verwijderd.'**
  String get photoDeleteFailed;

  /// Shown instead of a photo whose file was not in the restored backup (DD-007 point 7a).
  ///
  /// In nl, this message translates to:
  /// **'Bijlage niet in deze back-up'**
  String get photoMissing;

  /// Row in Settings that opens the Models screen (T6a.3).
  ///
  /// In nl, this message translates to:
  /// **'Modellen'**
  String get settingsModels;

  /// Subtitle of the Models row in Settings.
  ///
  /// In nl, this message translates to:
  /// **'Voor het lezen van handschrift; alleen op dit toestel'**
  String get settingsModelsHint;

  /// Title of the Models screen.
  ///
  /// In nl, this message translates to:
  /// **'Modellen'**
  String get modelsTitle;

  /// Explanation at the top of the Models screen (DD-002, DD-007).
  ///
  /// In nl, this message translates to:
  /// **'Een model werkt zonder internet, op dit toestel. Offload downloadt niets: je kiest de bestanden zelf, bijvoorbeeld van je computer, een NAS of een cloud-app. Modellen gaan nooit mee in een back-up.'**
  String get modelsIntro;

  /// What the handwriting model is for, as the title of its section.
  ///
  /// In nl, this message translates to:
  /// **'Handschrift lezen'**
  String get modelKindHandwriting;

  /// The model's own name and its size, e.g. 'Qwen3-VL-2B-Instruct · 1.6 GB'.
  ///
  /// In nl, this message translates to:
  /// **'{name} · {size}'**
  String modelNameSize(String name, String size);

  /// Status of a model whose files are all imported and checked.
  ///
  /// In nl, this message translates to:
  /// **'Klaar voor gebruik'**
  String get modelReady;

  /// Status of a model with no files on this device.
  ///
  /// In nl, this message translates to:
  /// **'Niet geïmporteerd'**
  String get modelNotImported;

  /// Status of a model with some files imported; the file names still needed.
  ///
  /// In nl, this message translates to:
  /// **'Nog nodig: {files}'**
  String modelMissing(String files);

  /// Where the model's files are published and the name of its licence.
  ///
  /// In nl, this message translates to:
  /// **'Bron: {source} · licentie {licence}'**
  String modelSource(String source, String licence);

  /// Button that opens the file window to import a model's files.
  ///
  /// In nl, this message translates to:
  /// **'Importeren…'**
  String get modelImport;

  /// Button that removes a model's files from this device.
  ///
  /// In nl, this message translates to:
  /// **'Verwijderen'**
  String get modelRemove;

  /// Title of the confirmation before removing a model.
  ///
  /// In nl, this message translates to:
  /// **'Model verwijderen?'**
  String get modelRemoveTitle;

  /// Body of the confirmation before removing a model.
  ///
  /// In nl, this message translates to:
  /// **'{name} ({size}) verdwijnt van dit toestel. Je kunt het later opnieuw importeren.'**
  String modelRemoveBody(String name, String size);

  /// Message when removing a model failed, for example because a file is in use (Windows).
  ///
  /// In nl, this message translates to:
  /// **'Het model kon niet helemaal worden verwijderd. Misschien is een bestand nog in gebruik; probeer het later opnieuw.'**
  String get modelRemoveFailed;

  /// State of a model when its files could not be looked at.
  ///
  /// In nl, this message translates to:
  /// **'Status onbekend: de bestanden konden niet worden gelezen.'**
  String get modelStateUnknown;

  /// Name of the model file type in the Windows Open window.
  ///
  /// In nl, this message translates to:
  /// **'Modelbestanden'**
  String get modelFileTypeName;

  /// Shown while a model's files are copied and their checksums computed.
  ///
  /// In nl, this message translates to:
  /// **'Model wordt gekopieerd en gecontroleerd…'**
  String get modelImporting;

  /// Progress of a model import, e.g. '640 MB van 1.6 GB'.
  ///
  /// In nl, this message translates to:
  /// **'{done} van {total}'**
  String modelImportProgress(String done, String total);

  /// Button that stops a running model import.
  ///
  /// In nl, this message translates to:
  /// **'Stoppen'**
  String get modelImportStop;

  /// Title of the message after a model import.
  ///
  /// In nl, this message translates to:
  /// **'Model importeren'**
  String get modelImportTitle;

  /// After an import that completed the model.
  ///
  /// In nl, this message translates to:
  /// **'Het model is klaar voor gebruik.'**
  String get modelImportReady;

  /// After an import: files whose size or checksum matches no file of the model.
  ///
  /// In nl, this message translates to:
  /// **'Niet herkend als bestand van dit model, niet bewaard: {files}'**
  String modelImportUnknown(String files);

  /// After an import: picked files this device has already.
  ///
  /// In nl, this message translates to:
  /// **'Stond er al: {files}'**
  String modelImportAlready(String files);

  /// Before copying: too little room for the model files plus a margin.
  ///
  /// In nl, this message translates to:
  /// **'Te weinig vrije ruimte: nodig ongeveer {needed}, vrij {free}. Er is niets gekopieerd.'**
  String modelImportNoRoom(String needed, String free);

  /// The drive filled up during a model import.
  ///
  /// In nl, this message translates to:
  /// **'De opslag raakte vol tijdens het kopiëren. De halve kopie is weggehaald.'**
  String get modelImportFull;

  /// After the user stopped a model import.
  ///
  /// In nl, this message translates to:
  /// **'Importeren gestopt. De halve kopie is weggehaald.'**
  String get modelImportStopped;

  /// A picked model file could not be read, or the file window failed.
  ///
  /// In nl, this message translates to:
  /// **'Het bestand kon niet worden gelezen.'**
  String get modelImportFailed;

  /// Label of the choice Accurate / Faster under the handwriting model (DD-021).
  ///
  /// In nl, this message translates to:
  /// **'Lezen van handschrift'**
  String get readingSpeedLabel;

  /// Choice: read handwriting with the model's full image detail.
  ///
  /// In nl, this message translates to:
  /// **'Nauwkeurig'**
  String get readingSpeedAccurate;

  /// Choice: read handwriting faster with less image detail.
  ///
  /// In nl, this message translates to:
  /// **'Sneller'**
  String get readingSpeedFaster;

  /// Note under the choice Accurate / Faster.
  ///
  /// In nl, this message translates to:
  /// **'Sneller leest kleine tekens soms minder goed.'**
  String get readingSpeedHint;

  /// Row in Settings → Storage with the size of the imported models.
  ///
  /// In nl, this message translates to:
  /// **'Modellen'**
  String get storageModels;

  /// Subtitle of the Models row in Settings → Storage.
  ///
  /// In nl, this message translates to:
  /// **'Geïmporteerd; niet in een back-up'**
  String get storageModelsHint;

  /// Line in the restore confirmation when this device has no handwriting model (DD-007, T6a.3).
  ///
  /// In nl, this message translates to:
  /// **'Lees je handschrift van foto\'s? Het model gaat niet mee in een back-up: importeer het na het terugzetten opnieuw via Instellingen → Modellen.'**
  String get backupRestoreModelHint;

  /// Tooltip of the button in quick capture that reads handwriting from a photo (REQ-064, T6a.4).
  ///
  /// In nl, this message translates to:
  /// **'Handschrift lezen van een foto'**
  String get handwritingButton;

  /// Title of the photo screen and of the sheet that asks camera or gallery.
  ///
  /// In nl, this message translates to:
  /// **'Handschrift lezen'**
  String get handwritingTitle;

  /// Shown while the photo is decoded.
  ///
  /// In nl, this message translates to:
  /// **'Foto openen…'**
  String get handwritingOpening;

  /// Hint under the photo with four draggable corners (straightening, SPEC Q45).
  ///
  /// In nl, this message translates to:
  /// **'Sleep de hoeken naar de hoeken van het bord of blad, of lees de hele foto.'**
  String get handwritingCornersHint;

  /// Shown when the corners cannot be straightened (crossed, or a shape too small).
  ///
  /// In nl, this message translates to:
  /// **'De hoeken staan door elkaar. Sleep elke hoek terug naar zijn eigen kant.'**
  String get handwritingCornersCrossed;

  /// Button that puts the corners back on the photo corners.
  ///
  /// In nl, this message translates to:
  /// **'Hoeken herstellen'**
  String get handwritingResetCorners;

  /// Button that starts reading the photo.
  ///
  /// In nl, this message translates to:
  /// **'Lezen'**
  String get handwritingRead;

  /// Message while reading on Android, where reading pauses outside the app (DD-021).
  ///
  /// In nl, this message translates to:
  /// **'Dit kan een paar minuten duren. Laat Offload open; buiten de app pauzeert het lezen.'**
  String get handwritingWait;

  /// Message while reading on Windows.
  ///
  /// In nl, this message translates to:
  /// **'Dit kan een paar minuten duren.'**
  String get handwritingWaitDesktop;

  /// Reading phase: the model files are read into memory.
  ///
  /// In nl, this message translates to:
  /// **'Het model laden…'**
  String get handwritingPhaseLoading;

  /// Reading phase: the model looks at the image (most of the time).
  ///
  /// In nl, this message translates to:
  /// **'De foto bekijken…'**
  String get handwritingPhaseEncoding;

  /// Reading phase: the model writes the text.
  ///
  /// In nl, this message translates to:
  /// **'De tekst schrijven…'**
  String get handwritingPhaseWriting;

  /// Button that stops reading; the screen goes back to the corners.
  ///
  /// In nl, this message translates to:
  /// **'Stoppen'**
  String get handwritingStop;

  /// Shown after Stop until the model has stopped (a few seconds).
  ///
  /// In nl, this message translates to:
  /// **'Stoppen…'**
  String get handwritingStopping;

  /// The model wrote no text.
  ///
  /// In nl, this message translates to:
  /// **'Er is geen tekst op de foto gevonden.'**
  String get handwritingNothingFound;

  /// The model could not get the memory it needs.
  ///
  /// In nl, this message translates to:
  /// **'Te weinig vrij geheugen om te lezen. Sluit andere apps en probeer het opnieuw.'**
  String get handwritingOutOfMemory;

  /// A model file is missing or damaged.
  ///
  /// In nl, this message translates to:
  /// **'Het model kon niet worden geladen. Kijk bij Instellingen → Modellen.'**
  String get handwritingModelUnreadable;

  /// Any other failure while reading.
  ///
  /// In nl, this message translates to:
  /// **'Het lezen is mislukt. Probeer het opnieuw.'**
  String get handwritingFailed;

  /// Time spent reading, as minutes and two-digit seconds.
  ///
  /// In nl, this message translates to:
  /// **'Bezig: {minutes}:{seconds}'**
  String handwritingElapsed(String minutes, String seconds);

  /// Reading was stopped after the time limit (DD-021).
  ///
  /// In nl, this message translates to:
  /// **'Het lezen duurde langer dan {minutes} minuten en is gestopt. Waarschijnlijk heeft het toestel te weinig vrij geheugen: sluit andere apps en probeer het opnieuw.'**
  String handwritingTooLong(int minutes);

  /// Title of the review screen after reading handwriting (REQ-064 c, T6a.5).
  ///
  /// In nl, this message translates to:
  /// **'Gedachten controleren'**
  String get reviewThoughtsTitle;

  /// Checkbox of one thought on the review screen: kept when saving.
  ///
  /// In nl, this message translates to:
  /// **'Opnemen'**
  String get reviewThoughtsInclude;

  /// Saving the thoughts failed; nothing was saved.
  ///
  /// In nl, this message translates to:
  /// **'Opslaan is mislukt; de tekst staat er nog. Probeer het opnieuw.'**
  String get reviewThoughtsSaveFailed;

  /// Confirmation when leaving the review screen after an edit.
  ///
  /// In nl, this message translates to:
  /// **'Gelezen tekst weggooien?'**
  String get reviewThoughtsDiscardTitle;

  /// Body of the discard confirmation.
  ///
  /// In nl, this message translates to:
  /// **'Je aanpassingen gaan verloren. De foto blijft, zodat je opnieuw kunt lezen.'**
  String get reviewThoughtsDiscardBody;

  /// Button that confirms leaving the review screen.
  ///
  /// In nl, this message translates to:
  /// **'Weggooien'**
  String get reviewThoughtsDiscard;

  /// Intro on the review screen; count is the number of thoughts read.
  ///
  /// In nl, this message translates to:
  /// **'{count, plural, =1{1 gedachte gelezen.} other{{count} gedachten gelezen.}} Pas aan wat niet klopt en sla over wat je niet wilt; pas na Opslaan komen ze in de inbox.'**
  String reviewThoughtsIntro(int count);

  /// Save button of the review screen; count is the number of thoughts kept.
  ///
  /// In nl, this message translates to:
  /// **'{count, plural, =0{Niets op te slaan} =1{1 opslaan} other{{count} opslaan}}'**
  String reviewThoughtsSave(int count);

  /// Label of the field of one thought.
  ///
  /// In nl, this message translates to:
  /// **'Gedachte {index}'**
  String reviewThoughtLabel(int index);

  /// Message after the thoughts read from a photo were saved.
  ///
  /// In nl, this message translates to:
  /// **'{count, plural, =1{1 item in de inbox} other{{count} items in de inbox}}'**
  String handwritingSaved(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'nl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'nl':
      return AppLocalizationsNl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
