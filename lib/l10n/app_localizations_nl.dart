// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get appTitle => 'Offload';

  @override
  String get languageName => 'Nederlands';

  @override
  String get openSettingsTooltip => 'Instellingen openen';

  @override
  String get settingsTitle => 'Instellingen';

  @override
  String get settingsLanguageHeader => 'Taal';

  @override
  String get settingsLanguageSystem => 'Systeemtaal';

  @override
  String get settingsLanguageSystemHint =>
      'Volgt de taal van het toestel; is die niet beschikbaar, dan Engels';

  @override
  String get startupLoading => 'Offload wordt gestart';

  @override
  String get startupMissingKeyTitle => 'Sleutel ontbreekt';

  @override
  String get startupMissingKeyBody =>
      'Er staan gegevens van Offload op dit apparaat, maar de sleutel om ze te openen ontbreekt. Offload maakt geen nieuwe sleutel aan, want dan worden je gegevens voorgoed onleesbaar. Er is niets gewijzigd.';

  @override
  String get startupKeyUnavailableTitle => 'Sleutel niet leesbaar';

  @override
  String get startupKeyUnavailableBody =>
      'De sleutel van Offload is aanwezig, maar kan nu niet worden gelezen. Er is niets gewijzigd. Probeer het opnieuw of start het apparaat opnieuw op.';

  @override
  String get startupDatabaseTitle => 'Gegevens niet te openen';

  @override
  String get startupDatabaseBody =>
      'De gegevens van Offload kunnen niet worden geopend. Er is niets verwijderd.';

  @override
  String get startupUnexpectedTitle => 'Offload kan niet starten';

  @override
  String get startupUnexpectedBody =>
      'Er ging iets mis bij het starten. Er is niets verwijderd.';

  @override
  String startupErrorDetails(String details) {
    return 'Technische details: $details';
  }

  @override
  String get startupRetry => 'Opnieuw proberen';

  @override
  String get settingsLanguageSaveFailed =>
      'De taalkeuze kon niet worden bewaard';

  @override
  String get inboxTitle => 'Inbox';

  @override
  String inboxItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
      zero: 'Nog geen items',
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
      'De inbox kan niet worden geladen. Er is niets verwijderd.';

  @override
  String get captureAction => 'Vastleggen';

  @override
  String get captureTitle => 'Vastleggen';

  @override
  String get captureHint => 'Wat heb je in je hoofd?';

  @override
  String get captureSave => 'Opslaan';

  @override
  String get captureSaveFailed =>
      'Opslaan is mislukt. Je tekst staat er nog; probeer het opnieuw.';

  @override
  String get androidWidgetDescription => 'Leg met één tik een gedachte vast';

  @override
  String get androidWidgetHint => 'Leg iets vast…';

  @override
  String captureUnreadable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count vastgelegde items konden niet worden gelezen. Ze zijn apart bewaard, niet verwijderd.',
      one:
          '1 vastgelegd item kon niet worden gelezen. Het is apart bewaard, niet verwijderd.',
    );
    return '$_temp0';
  }

  @override
  String get captureFetchFailed =>
      'Items uit de widget konden nog niet worden opgehaald. Ze blijven bewaard; Offload probeert het opnieuw.';

  @override
  String get noticeDismiss => 'Sluiten';

  @override
  String get trayNewItem => 'Nieuw item';

  @override
  String get trayOpen => 'Openen';

  @override
  String get trayQuit => 'Afsluiten';

  @override
  String get hotkeyUnavailable =>
      'De sneltoets Win+Shift+B is al in gebruik door een ander programma. Vastleggen kan via het systeemvak of met de knop Vastleggen.';

  @override
  String get settingsBackupHeader => 'Back-up en export';

  @override
  String get backupPassphraseRow => 'Wachtwoordzin';

  @override
  String get backupPassphraseSet => 'Ingesteld';

  @override
  String get backupPassphraseNotSet =>
      'Nog niet ingesteld: nodig voor een back-up';

  @override
  String get backupPassphraseTitle => 'Wachtwoordzin voor back-ups';

  @override
  String get backupPassphraseField => 'Wachtwoordzin';

  @override
  String get backupPassphraseRepeat => 'Nog een keer';

  @override
  String backupPassphraseHint(int min) {
    return 'Minstens $min tekens, bijvoorbeeld vier losse woorden. Je typt hem alleen als je een back-up op een ander toestel terugzet.';
  }

  @override
  String get backupPassphraseMismatch => 'De twee zijn niet gelijk';

  @override
  String backupPassphraseTooShort(int min) {
    return 'Minstens $min tekens';
  }

  @override
  String get backupPassphraseInvalid => 'Zonder tab of nieuwe regel';

  @override
  String backupStrength(String level) {
    return 'Sterkte: $level';
  }

  @override
  String get backupStrengthTooShort => 'te kort';

  @override
  String get backupStrengthFair => 'redelijk';

  @override
  String get backupStrengthGood => 'goed';

  @override
  String get backupStrengthStrong => 'sterk';

  @override
  String get backupPassphraseWarning =>
      'Zonder deze wachtwoordzin kan een back-up niet worden teruggezet, ook niet door de app.';

  @override
  String get backupPassphraseWarningConfirm => 'Ik begrijp het';

  @override
  String get backupPassphraseChangeNote =>
      'Oudere back-ups houden hun oude wachtwoordzin.';

  @override
  String get backupPassphraseShow => 'Wachtwoordzin tonen';

  @override
  String get backupSave => 'Opslaan';

  @override
  String get backupCancel => 'Annuleren';

  @override
  String get backupPassphraseSaved => 'Wachtwoordzin opgeslagen';

  @override
  String get backupMake => 'Back-up maken';

  @override
  String get backupMakeSubtitle =>
      'Alles versleuteld in één bestand; je kiest zelf waar';

  @override
  String get backupFileType => 'Offload-back-up';

  @override
  String backupFileName(String date) {
    return 'Offload-back-up-$date';
  }

  @override
  String get backupBusy => 'Even geduld…';

  @override
  String get backupMade => 'Back-up gemaakt';

  @override
  String get backupFailed => 'De back-up is niet gelukt';

  @override
  String get exportRow => 'Exporteren';

  @override
  String get exportRowSubtitle =>
      'Leesbaar, niet versleuteld (Markdown of JSON)';

  @override
  String get exportDialogTitle => 'Exporteren';

  @override
  String get exportWarning =>
      'Deze export is niet versleuteld. Iedereen met het bestand kan alles lezen.';

  @override
  String get exportMarkdown => 'Markdown';

  @override
  String get exportMarkdownHint => 'Leesbaar, in elke teksteditor';

  @override
  String get exportJson => 'JSON';

  @override
  String get exportJsonHint => 'Gestructureerd, voor andere programma\'s';

  @override
  String get exportConfirm => 'Exporteren';

  @override
  String exportFileName(String date) {
    return 'Offload-export-$date';
  }

  @override
  String get exportMarkdownFileType => 'Markdown-bestand';

  @override
  String get exportJsonFileType => 'JSON-bestand';

  @override
  String get exportSaved => 'Export opgeslagen';

  @override
  String get exportReadyToShare => 'Export klaargezet om te delen';

  @override
  String get exportFailed => 'De export is niet gelukt';

  @override
  String get exportTitle => 'Offload-export';

  @override
  String exportMadeOn(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jm(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Gemaakt op $dateString, $timeString';
  }

  @override
  String exportCounts(int items, int projects, int people) {
    return 'Items: $items · projecten: $projects · personen: $people';
  }

  @override
  String get exportProjects => 'Projecten';

  @override
  String get exportWithoutProject => 'Zonder project';

  @override
  String get exportPeople => 'Personen';

  @override
  String get exportArchived => 'gearchiveerd';

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

    return 'terugzien op $dateString';
  }

  @override
  String exportRequester(String name) {
    return 'gevraagd door $name';
  }

  @override
  String exportWaitingOn(String name) {
    return 'wacht op $name';
  }

  @override
  String exportAsked(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'gevraagd op $dateString';
  }

  @override
  String exportPromise(String text) {
    return 'toegezegd: $text';
  }

  @override
  String exportExpected(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'verwacht op $dateString';
  }

  @override
  String exportCaptured(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'vastgelegd $dateString';
  }

  @override
  String exportNextStep(String text) {
    return 'Waar was ik, volgende stap: $text';
  }

  @override
  String exportInMind(String text) {
    return 'Waar was ik, in mijn hoofd: $text';
  }

  @override
  String exportCompletions(String dates) {
    return 'Gedaan: $dates';
  }

  @override
  String exportDay(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String exportAliases(String aliases) {
    return 'Ook: $aliases';
  }

  @override
  String exportBirthday(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Verjaardag: $dateString';
  }

  @override
  String exportBirthdayNoYear(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Verjaardag: $dateString';
  }

  @override
  String exportWork(String text) {
    return 'Werk: $text';
  }

  @override
  String exportContact(String kind, String label) {
    return '$kind ($label)';
  }

  @override
  String get settingsStorageHeader => 'Opslag';

  @override
  String get storageDatabase => 'Database';

  @override
  String get storageDatabaseHint => 'Versleuteld: alles wat je hebt vastgelegd';

  @override
  String get storageTemporary => 'Tijdelijke bestanden';

  @override
  String get storageTemporaryHint =>
      'Een gedeelde back-up of export; gaat na een dag weg';

  @override
  String get storageContent => 'Inhoud';

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
    return 'waarvan $count in de prullenbak';
  }

  @override
  String storageProjects(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count projecten',
      one: '1 project',
    );
    return '$_temp0';
  }

  @override
  String storagePeople(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personen',
      one: '1 persoon',
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
  String get storageUnavailable => 'Niet te bepalen';

  @override
  String storageJoin(String first, String second) {
    return '$first · $second';
  }

  @override
  String storageWithTrash(String items, String trashed) {
    return '$items, $trashed';
  }

  @override
  String get backupShare => 'Delen…';

  @override
  String get backupSaveOnDevice => 'Opslaan op dit toestel…';

  @override
  String get backupReadyToShare => 'Back-up klaargezet om te delen';

  @override
  String get backupRestore => 'Back-up terugzetten';

  @override
  String get backupRestoreSubtitle => 'Vervangt alles op dit toestel';

  @override
  String get backupRestoreAskTitle => 'Wachtwoordzin van deze back-up';

  @override
  String get backupRestoreAskBody =>
      'Deze back-up is gemaakt met een andere wachtwoordzin, of op een ander toestel.';

  @override
  String get backupRestoreAskOk => 'Openen';

  @override
  String get backupWrongPassphrase =>
      'Deze wachtwoordzin past niet, of het bestand is geen back-up van Offload.';

  @override
  String get backupTooNew =>
      'Deze back-up komt van een nieuwere versie van Offload. Werk de app eerst bij.';

  @override
  String get backupUnreadable =>
      'Het bestand kon niet worden gelezen of geschreven.';

  @override
  String get backupRestoreConfirmTitle => 'Alles vervangen?';

  @override
  String backupRestoreConfirmBody(int count, DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Deze back-up bevat $count items',
      one: 'Deze back-up bevat 1 item',
    );
    return '$_temp0, laatst gewijzigd op $dateString. Alles wat nu op dit toestel staat, wordt vervangen; je instellingen blijven. Dit is een kopie, geen synchronisatie.';
  }

  @override
  String backupRestoreConfirmBodyUndated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Deze back-up bevat $count items',
      one: 'Deze back-up bevat 1 item',
    );
    return '$_temp0. Alles wat nu op dit toestel staat, wordt vervangen; je instellingen blijven. Dit is een kopie, geen synchronisatie.';
  }

  @override
  String get backupRestoreConfirm => 'Terugzetten';

  @override
  String get backupOptionsContinue => 'Verder';

  @override
  String backupWithAttachments(String size) {
    return 'Met bijlagen (≈ $size)';
  }

  @override
  String get backupWithAttachmentsHint =>
      'Zonder bijlagen is de back-up kleiner, maar zitten ze er niet in.';

  @override
  String backupProgress(String done, String total) {
    return '$done van $total';
  }

  @override
  String backupMissingNote(String message, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bijlagen ontbraken en zitten er niet in.',
      one: '1 bijlage ontbrak en zit er niet in.',
    );
    return '$message. $_temp0';
  }

  @override
  String backupNoRoom(String needed, String free) {
    return 'Niet genoeg vrije ruimte: nodig ongeveer $needed, vrij $free.';
  }

  @override
  String backupRestoreWithAttachments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Met $count bijlagen.',
      one: 'Met 1 bijlage.',
    );
    return '$_temp0';
  }

  @override
  String get backupRestoreNoAttachments =>
      'Deze back-up heeft geen bijlagen; bijlagen die niet bij de teruggezette items horen, verdwijnen.';

  @override
  String get restoreUndoneTitle => 'Terugzetten niet gelukt';

  @override
  String get restoreUndoneBody =>
      'De teruggezette back-up kon niet worden geopend. Je gegevens van vóór het terugzetten zijn er weer; er is niets verloren.';

  @override
  String get restoreUndoneOk => 'OK';

  @override
  String get settingsAboutHeader => 'Over Offload';

  @override
  String get aboutOpen => 'Waarvoor Offload is en de licenties';

  @override
  String get aboutPurpose =>
      'Offload maakt je hoofd leeg. Lopend werk, wat nog komt, ideeën en verzoeken van anderen leg je in een paar seconden vast, en je verwerkt ze als het jou uitkomt. Alles blijft op je eigen apparaat, versleuteld en zonder internet.';

  @override
  String get aboutLicenceTitle => 'Licentie';

  @override
  String get aboutLicenceName => 'GNU GPL 3.0 of later';

  @override
  String get aboutLicenceFailed => 'De licentietekst kon niet worden geladen';

  @override
  String get aboutComponentsTitle => 'Licenties van onderdelen';

  @override
  String get aboutComponentsSubtitle =>
      'Pakketten, bibliotheken en lettertypen in de app';

  @override
  String settingsVersion(String version, String buildNumber) {
    return 'Versie $version (build $buildNumber)';
  }

  @override
  String settingsBuiltAt(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jm(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Gebouwd op $dateString, $timeString';
  }

  @override
  String get settingsDevelopmentBuild => 'Ontwikkelversie';

  @override
  String get tokenDateToday => 'vandaag';

  @override
  String get tokenDateTomorrow => 'morgen';

  @override
  String get tokenDateDayAfterTomorrow => 'overmorgen';

  @override
  String get tokenDateNextWeek => 'volgendeweek';

  @override
  String get tokenPriorityHigh => 'hoog';

  @override
  String get tokenPriorityLow => 'laag';

  @override
  String get tokenWeekdaysShort => 'ma,di,wo,do,vr,za,zo';

  @override
  String get tokenWeekdaysLong =>
      'maandag,dinsdag,woensdag,donderdag,vrijdag,zaterdag,zondag';

  @override
  String get tokenPersonLabel => 'persoon';

  @override
  String get tokenTagLabel => 'tag';

  @override
  String get tokenDateLabel => 'datum';

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
  String get tokenOtherLabel => 'herkend woord';

  @override
  String tokenSuggestionNew(String name) {
    return 'Nieuw: $name';
  }

  @override
  String get settingsInputHeader => 'Invoer';

  @override
  String get settingsPrefixBar => 'Prefix-balk';

  @override
  String get settingsPrefixBarHint =>
      'Knoppen voor de invoertekens bij het vastleggen';

  @override
  String get settingsPrefixBarAlways => 'Altijd zichtbaar';

  @override
  String get settingsPrefixBarCollapsed => 'Ingeklapt';

  @override
  String get settingsPrefixBarCollapsedHint =>
      'Eén smalle regel met alleen de tekens, uit te klappen';

  @override
  String get settingsPrefixBarOff => 'Uit';

  @override
  String get settingsPrefixBarSaveFailed =>
      'De instelling van de prefix-balk kon niet worden bewaard';

  @override
  String prefixBarButton(String sign, String label) {
    return '$sign $label';
  }

  @override
  String prefixBarInsert(String label) {
    return '$label invoegen';
  }

  @override
  String get prefixBarHelp => 'Syntaxoverzicht';

  @override
  String get prefixBarExpand => 'Uitklappen';

  @override
  String get prefixBarCollapse => 'Inklappen';

  @override
  String get syntaxOverviewTitle => 'Syntaxoverzicht';

  @override
  String get syntaxOverviewIntro =>
      'Zet een teken direct voor een woord. Je tekst blijft zoals je hem typt.';

  @override
  String get syntaxOverviewClose => 'Sluiten';

  @override
  String get tokenPersonExample => 'Bel @Jan over de offerte';

  @override
  String get tokenTagExample => 'Dakgoot schoonmaken #klussen';

  @override
  String get tokenDateExample => 'Offerte af !vrijdag, ook !morgen of !12-10';

  @override
  String get commitmentHeader => 'Toezegging';

  @override
  String commitmentAskedOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMEd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Gevraagd op $dateString';
  }

  @override
  String commitmentPromised(String text) {
    return 'Beloofd: $text';
  }

  @override
  String commitmentDue(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMEd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Voor: $dateString';
  }

  @override
  String get commitmentDueAdd => 'Datum toevoegen';

  @override
  String commitmentWaitsOn(String name) {
    return 'Wacht op $name';
  }

  @override
  String get commitmentWaitsOnNobody => 'Wacht (op niemand in het bijzonder)';

  @override
  String commitmentExpected(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMEd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Verwacht: $dateString';
  }

  @override
  String commitmentExpectedLate(DateTime date, int days) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMEd(localeName);
    final String dateString = dateDateFormat.format(date);

    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dagen',
      one: '1 dag',
    );
    return 'Verwacht: $dateString · $_temp0 te laat';
  }

  @override
  String get commitmentExpectedAdd => 'Verwacht op toevoegen';

  @override
  String get commitmentReset => 'Terugzetten';

  @override
  String get commitmentPromiseTitle => 'Wat heb je beloofd?';

  @override
  String get commitmentPromiseField => 'Beloofd';

  @override
  String get commitmentPromiseHint => 'Leeg: de titel van het item.';

  @override
  String get commitmentChangeFailed => 'Opslaan is mislukt.';

  @override
  String commitmentExpectedChip(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMEd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'verwacht $dateString';
  }

  @override
  String commitmentLateChip(int days) {
    return '$days d te laat';
  }

  @override
  String commitmentLateChipLabel(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dagen te laat',
      one: '1 dag te laat',
    );
    return '$_temp0';
  }

  @override
  String todayLateSection(int count) {
    return 'Had binnen moeten zijn · $count';
  }

  @override
  String get waitForExpected => 'Verwacht op…';

  @override
  String waitForExpectedDate(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMEd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Verwacht op $dateString';
  }

  @override
  String get waitForExpectedOptional => 'optioneel';

  @override
  String get peopleDeliverTitle => 'Ik moet nog leveren';

  @override
  String peopleDeliverTotal(int count, int people) {
    String _temp0 = intl.Intl.pluralLogic(
      people,
      locale: localeName,
      other: '$people personen',
      one: '1 persoon',
    );
    return '$count aan $_temp0';
  }

  @override
  String get peopleWaitTitle => 'Ik wacht nog op';

  @override
  String peopleWaitTotal(int count, int people) {
    String _temp0 = intl.Intl.pluralLogic(
      people,
      locale: localeName,
      other: '$people personen',
      one: '1 persoon',
    );
    return '$count van $_temp0';
  }

  @override
  String get peopleLegendDeliver => '← ik lever';

  @override
  String get peopleLegendWait => 'ik wacht →';

  @override
  String get peopleLegendOldest => 'oudste';

  @override
  String peopleAge(int days) {
    return '$days d';
  }

  @override
  String peopleRowSemantics(String name, int deliver, int waiting, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dagen',
      one: '1 dag',
    );
    return '$name: jij levert $deliver, jij wacht op $waiting, oudste $_temp0';
  }

  @override
  String peopleRowSemanticsOld(String text) {
    return '$text, oud';
  }

  @override
  String get settingsPeopleHeader => 'Personen';

  @override
  String get settingsOldAfter => 'Oud na';

  @override
  String get settingsOldAfterHint =>
      'Vanaf zo veel dagen is een open item bij een persoon oud: het valt op in de balans.';

  @override
  String get tokenPhoneLabel => 'telefoonnummer';

  @override
  String get tokenPhoneExample => 'Bel @Jan op 06-12345678 of +31 6 1234 5678';

  @override
  String get tokenEmailLabel => 'e-mailadres';

  @override
  String get tokenEmailExample => 'Mail @Jan op jan@voorbeeld.nl';

  @override
  String tokenContactFor(String value, String name) {
    return '$value → $name';
  }

  @override
  String tokenProjectNone(String word) {
    return '$word · geen project';
  }

  @override
  String tokenProjectSeveral(String word) {
    return '$word · meerdere projecten';
  }

  @override
  String get tokenProjectCreateTooltip =>
      'Project maken en dit item erin zetten';

  @override
  String get contactLinkTooltip => 'Koppelen aan een persoon';

  @override
  String get contactLinkTitle => 'Van wie is dit?';

  @override
  String contactsTakenFromText(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gegevens toegevoegd aan $name',
      one: 'Toegevoegd aan $name',
    );
    return '$_temp0';
  }

  @override
  String get contactsTakenUndoFailed =>
      'Weghalen is mislukt; de gegevens staan nog bij de persoon.';

  @override
  String get settingsPhoneCountry => 'Land voor telefoonnummers';

  @override
  String get settingsPhoneCountryHint =>
      'Voor nummers zonder +landcode, zoals 06-12345678.';

  @override
  String settingsCountryOption(String country, String code) {
    return '$country (+$code)';
  }

  @override
  String countryName(String iso) {
    String _temp0 = intl.Intl.selectLogic(iso, {
      'NL': 'Nederland',
      'BE': 'België',
      'LU': 'Luxemburg',
      'DE': 'Duitsland',
      'FR': 'Frankrijk',
      'GB': 'Verenigd Koninkrijk',
      'IE': 'Ierland',
      'ES': 'Spanje',
      'PT': 'Portugal',
      'IT': 'Italië',
      'AT': 'Oostenrijk',
      'CH': 'Zwitserland',
      'DK': 'Denemarken',
      'SE': 'Zweden',
      'NO': 'Noorwegen',
      'FI': 'Finland',
      'IS': 'IJsland',
      'PL': 'Polen',
      'CZ': 'Tsjechië',
      'SK': 'Slowakije',
      'HU': 'Hongarije',
      'GR': 'Griekenland',
      'HR': 'Kroatië',
      'SI': 'Slovenië',
      'RO': 'Roemenië',
      'BG': 'Bulgarije',
      'EE': 'Estland',
      'LV': 'Letland',
      'UA': 'Oekraïne',
      'TR': 'Turkije',
      'MA': 'Marokko',
      'SR': 'Suriname',
      'ZA': 'Zuid-Afrika',
      'US': 'Verenigde Staten',
      'CA': 'Canada',
      'AU': 'Australië',
      'NZ': 'Nieuw-Zeeland',
      'other': '$iso',
    });
    return '$_temp0';
  }

  @override
  String get tokenProjectLabel => 'project';

  @override
  String get tokenProjectExample =>
      'Kozijnen bestellen ^verbouwing, ook ^oude-schuur of ^verbouwing/keuken';

  @override
  String get tokenLinkLabel => 'item';

  @override
  String get tokenLinkExample =>
      'Kozijnen bestellen, zie [[Offerte kozijnen vergelijken]]';

  @override
  String tokenSuggestionItemDetail(String status, String project) {
    return '$status · $project';
  }

  @override
  String tokenLinkTrashed(String title) {
    return '$title · in prullenbak';
  }

  @override
  String tokenLinkNone(String label) {
    return '$label · geen item';
  }

  @override
  String get tokenLinkCreateTooltip => 'Nieuw item maken en koppelen';

  @override
  String get tokenLinkOpenTooltip => 'Item openen';

  @override
  String get tokenLinkCreateFailed => 'Het item kon niet worden gemaakt';

  @override
  String itemLinkedFrom(int count) {
    return 'Verwijst hiernaar · $count';
  }

  @override
  String get duplicateLink => 'Koppelen';

  @override
  String get duplicateLinkFailed => 'Koppelen is niet gelukt';

  @override
  String get tokenPriorityLabel => 'prioriteit';

  @override
  String get tokenPriorityExample =>
      'Offerte nakijken *hoog, ook *laag of *1, *2, *3';

  @override
  String tokenPriorityChip(String priority) {
    String _temp0 = intl.Intl.selectLogic(priority, {
      'high': 'Hoge prioriteit',
      'low': 'Lage prioriteit',
      'other': 'Normale prioriteit',
    });
    return '$_temp0';
  }

  @override
  String tokenSuggestionNewProject(String name) {
    return 'Project maken: $name';
  }

  @override
  String get syntaxEscapeLabel => 'gewone tekst';

  @override
  String get syntaxEscapeExample => 'Zet er \\ voor: \\@Jan wordt niet herkend';

  @override
  String get searchTooltip => 'Zoeken';

  @override
  String get searchHint => 'Zoek in items en personen';

  @override
  String get searchStart =>
      'Typ een of meer woorden. Het begin van een woord is genoeg.';

  @override
  String searchNoResults(String query) {
    return 'Niets gevonden voor „$query”';
  }

  @override
  String get searchFailed => 'Zoeken lukte niet. Probeer het opnieuw.';

  @override
  String get searchClear => 'Wissen';

  @override
  String get searchKindItem => 'Item';

  @override
  String get searchKindPerson => 'Persoon';

  @override
  String get duplicateHint => 'Lijkt op een ander item';

  @override
  String get duplicateTitle => 'Bestaat dit al?';

  @override
  String get duplicateThisItem => 'Dit item';

  @override
  String duplicateOtherItem(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jm(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Lijkt op dit item van $dateString, $timeString';
  }

  @override
  String get duplicateIgnore => 'Negeren';

  @override
  String get duplicateClose => 'Sluiten';

  @override
  String get duplicateIgnoreFailed =>
      'Negeren is niet bewaard. Probeer het opnieuw.';

  @override
  String get tokenSuggestionPickDate => 'Kies een datum…';

  @override
  String get itemStatusInbox => 'Inbox';

  @override
  String get itemStatusActive => 'Actief';

  @override
  String get itemStatusWaiting => 'Wacht op';

  @override
  String get itemStatusScheduled => 'Gepland';

  @override
  String get itemStatusDone => 'Afgerond';

  @override
  String get itemStatusArchived => 'Gearchiveerd';

  @override
  String get itemTypeNone => 'Geen type';

  @override
  String get itemTypeTask => 'Taak';

  @override
  String get itemTypeRequest => 'Verzoek';

  @override
  String get itemTypeIdea => 'Idee';

  @override
  String get itemTypeNote => 'Notitie';

  @override
  String get itemTypeKind => 'type';

  @override
  String get itemStatusTooltip => 'Status wijzigen';

  @override
  String get itemTypeTooltip => 'Type wijzigen';

  @override
  String get itemComplete => 'Afronden';

  @override
  String get itemReopen => 'Heropenen';

  @override
  String get itemWaitFor => 'Wachten op…';

  @override
  String get itemTextHint => 'Tekst van het item';

  @override
  String get itemTextEmpty =>
      'Een item heeft tekst nodig. De vorige tekst blijft bewaard.';

  @override
  String get itemNoteLabel => 'Notitie';

  @override
  String get itemNoteHint => 'Notitie toevoegen';

  @override
  String get navProjects => 'Projecten';

  @override
  String get projectsWithout => 'Zonder project';

  @override
  String projectsArchived(int count) {
    return 'Gearchiveerd · $count';
  }

  @override
  String get projectsNew => 'Nieuw project';

  @override
  String get projectsEmpty => 'Nog geen projecten. Maak er een met +.';

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
    return '$count verlopen';
  }

  @override
  String projectGroup(String group, int count) {
    String _temp0 = intl.Intl.selectLogic(group, {
      'inbox': 'Inbox',
      'active': 'Actief',
      'waiting': 'Wacht op',
      'scheduled': 'Gepland',
      'notes': 'Notities',
      'other': 'Afgerond',
    });
    return '$_temp0 · $count';
  }

  @override
  String get projectEmpty => 'Nog niets in dit project.';

  @override
  String get projectRename => 'Hernoemen';

  @override
  String get projectMove => 'Verplaatsen…';

  @override
  String get projectArchive => 'Archiveren';

  @override
  String get projectRestore => 'Terugzetten';

  @override
  String get projectDelete => 'Verwijderen';

  @override
  String get projectMenuTooltip => 'Projectacties';

  @override
  String get projectRenameTitle => 'Project hernoemen';

  @override
  String get projectNameLabel => 'Naam';

  @override
  String get projectParentLabel => 'Onder';

  @override
  String get projectTopLevel => 'Bovenaan (geen hoofdproject)';

  @override
  String get projectMoveTitle => 'Verplaatsen naar';

  @override
  String get projectCreate => 'Maken';

  @override
  String get projectSave => 'Opslaan';

  @override
  String get projectCancel => 'Annuleren';

  @override
  String projectDeleteTitle(String name) {
    return '$name verwijderen?';
  }

  @override
  String get projectDeleteBody =>
      'De items blijven bestaan en raken dit project kwijt. Deelprojecten komen bovenaan te staan. Je kunt het meteen ongedaan maken.';

  @override
  String get projectDeleted => 'Project verwijderd';

  @override
  String get projectArchived => 'Project gearchiveerd';

  @override
  String get projectRestored => 'Project teruggezet';

  @override
  String get projectErrorNameTaken => 'Er is al een project met deze naam.';

  @override
  String get projectErrorEmptyName => 'Geef het project een naam.';

  @override
  String get projectErrorTooDeep =>
      'Dat kan niet: projecten hebben hoogstens twee niveaus.';

  @override
  String get projectErrorNotAvailable =>
      'Dit project bestaat niet meer of is gearchiveerd.';

  @override
  String get projectChangeFailed => 'Dat is niet gelukt. Probeer het nog eens.';

  @override
  String get projectPickerTitle => 'Project';

  @override
  String get projectPickerHint => 'Zoek of typ een nieuwe naam';

  @override
  String get projectNone => 'Geen project';

  @override
  String projectNewNamed(String name) {
    return 'Nieuw project: $name';
  }

  @override
  String get projectNewEllipsis => 'Nieuw project…';

  @override
  String get projectChipTooltip => 'Project kiezen';

  @override
  String projectArchivedName(String name) {
    return '$name (gearchiveerd)';
  }

  @override
  String projectPath(String parent, String name) {
    return '$parent › $name';
  }

  @override
  String get projectKind => 'project';

  @override
  String get projectSubprojects => 'Deelprojecten';

  @override
  String get itemShare => 'Delen';

  @override
  String get itemShareTitle => 'Item delen';

  @override
  String get itemShareIncludeTags => 'Tags meenemen';

  @override
  String get itemShareAsTyped => 'Zoals getypt (voor Offload)';

  @override
  String get itemShareAsTypedHint =>
      'Met @, #, ^, * en vaste datums: Offload op een ander toestel maakt er een item met dezelfde tekst en tokens van.';

  @override
  String get itemShareHelper => 'Wat je hier aanpast, verandert het item niet.';

  @override
  String get itemShareCopy => 'Kopiëren';

  @override
  String get itemShareSaveAs => 'Opslaan als…';

  @override
  String get itemShareCancel => 'Annuleren';

  @override
  String get itemShareCopied => 'Gekopieerd naar het klembord';

  @override
  String get itemShareSaved => 'Opgeslagen';

  @override
  String get itemShareFailed => 'Delen is niet gelukt. Probeer het nog eens.';

  @override
  String get itemShareFileType => 'Tekstbestand';

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
  String get itemMoveToTrash => 'Naar de prullenbak';

  @override
  String get itemMovedToTrash => 'Naar de prullenbak verplaatst';

  @override
  String get itemUndo => 'Ongedaan maken';

  @override
  String get itemSaveFailed =>
      'Opslaan is mislukt. Je wijziging staat er nog; probeer het opnieuw.';

  @override
  String get itemGone =>
      'Dit item staat in de prullenbak of bestaat niet meer.';

  @override
  String itemCapturedVia(DateTime date, DateTime time, String source) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jm(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Vastgelegd $dateString, $timeString via $source';
  }

  @override
  String get itemSourceApp => 'de app';

  @override
  String get itemSourceWidget => 'de widget';

  @override
  String get itemSourceShare => 'delen';

  @override
  String get itemSourceHotkey => 'de sneltoets';

  @override
  String get itemSourceTray => 'het systeemvak';

  @override
  String get itemSourceVoice => 'spraak';

  @override
  String get duplicateOpen => 'Openen';

  @override
  String inboxMoreLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+ $count regels',
      one: '+ 1 regel',
    );
    return '$_temp0';
  }

  @override
  String get ageJustNow => 'zojuist';

  @override
  String ageMinutes(int count) {
    return '$count min';
  }

  @override
  String ageHours(int count) {
    return '$count u';
  }

  @override
  String get ageYesterday => 'gisteren';

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
      other: '$count minuten geleden',
      one: '1 minuut geleden',
    );
    return '$_temp0';
  }

  @override
  String ageHoursLong(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count uur geleden',
      one: '1 uur geleden',
    );
    return '$_temp0';
  }

  @override
  String ageDaysLong(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dagen geleden',
      one: '1 dag geleden',
    );
    return '$_temp0';
  }

  @override
  String ageDateLong(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);

    return 'op $dateString';
  }

  @override
  String inboxTriage(int count) {
    return 'Verwerken · $count';
  }

  @override
  String get triageTitle => 'Verwerken';

  @override
  String triageProgress(int position, int total) {
    return '$position van $total';
  }

  @override
  String get triageStop => 'Stoppen';

  @override
  String get triageWaitFor => 'Wacht op';

  @override
  String get triageTrash => 'Prullenbak';

  @override
  String get triageSkip => 'Overslaan';

  @override
  String get triageOpen => 'Openen';

  @override
  String get triageWhoAsked => 'Wie vroeg dit?';

  @override
  String get triageWaitingOn => 'Op wie wacht je?';

  @override
  String get triagePersonHint => 'Naam';

  @override
  String get triagePersonDone => 'Klaar';

  @override
  String triageMovedTo(String destination) {
    return 'Naar $destination';
  }

  @override
  String get triageDoneTitle => 'Alles heeft een plek';

  @override
  String triageDoneProcessed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count verwerkt',
      one: '1 verwerkt',
    );
    return '$_temp0';
  }

  @override
  String triageDoneSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count overgeslagen, die staan nog in je inbox',
      one: '1 overgeslagen, die staat nog in je inbox',
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
  String get triageBackToInbox => 'Terug naar de inbox';

  @override
  String inboxStatusAndTime(String status, String when) {
    return '$status · $when';
  }

  @override
  String get itemChangeFailed => 'Wijzigen is mislukt. Probeer het opnieuw.';

  @override
  String get itemUndoFailed =>
      'Ongedaan maken is mislukt; het item staat nog in de prullenbak.';

  @override
  String get navToday => 'Vandaag';

  @override
  String navInboxBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count onverwerkte items',
      one: '1 onverwerkt item',
      zero: 'geen onverwerkte items',
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
      other: '$count in je inbox',
      one: '1 in je inbox',
    );
    return '$_temp0';
  }

  @override
  String get todayProcess => 'Verwerken';

  @override
  String todayOverdue(int count) {
    return 'Verlopen · $count';
  }

  @override
  String todayDueToday(int count) {
    return 'Vandaag · $count';
  }

  @override
  String get todayEmptyTitle => 'Niets voor vandaag';

  @override
  String get todayEmptyText => 'Geen deadlines vandaag en niets verlopen.';

  @override
  String get todayLoadFailed => 'Vandaag kon niet worden geladen.';

  @override
  String get itemCompleted => 'Afgerond';

  @override
  String get triageBack => 'Terug';

  @override
  String get panesChooseItem => 'Kies een item';

  @override
  String get panesChooseHint => 'Met de muis, of met ↑ en ↓ in de lijst.';

  @override
  String get navPeople => 'Personen';

  @override
  String get peopleFilterHint => 'Zoek een persoon';

  @override
  String get peopleEmpty =>
      'Nog geen personen. Noem iemand met @naam bij het vastleggen.';

  @override
  String get peopleNoMatch => 'Niemand gevonden.';

  @override
  String personAliases(String aliases) {
    return 'ook: $aliases';
  }

  @override
  String personList(String list, String name, int count) {
    String _temp0 = intl.Intl.selectLogic(list, {
      'requestedBy': 'Gevraagd door $name',
      'waitingFor': 'Wacht op $name',
      'other': 'Genoemd in',
    });
    return '$_temp0 · $count';
  }

  @override
  String get personEmpty => 'Nog niets met deze persoon.';

  @override
  String get personMenuTooltip => 'Persoonacties';

  @override
  String get personRename => 'Hernoemen';

  @override
  String get personRenameTitle => 'Persoon hernoemen';

  @override
  String get personNameLabel => 'Naam';

  @override
  String personRenameKeeps(String name) {
    return '\"$name\" blijft werken als bijnaam.';
  }

  @override
  String get personSave => 'Opslaan';

  @override
  String get personCancel => 'Annuleren';

  @override
  String get personErrorEmptyName => 'Geef een naam.';

  @override
  String get personErrorNameTaken => 'Er is al een persoon die zo heet.';

  @override
  String get personErrorNotAvailable => 'Deze persoon bestaat niet meer.';

  @override
  String get personRequesterKind => 'Gevraagd door';

  @override
  String get personWaitingKind => 'Wacht op';

  @override
  String personOpen(String name) {
    return '$name openen';
  }

  @override
  String get personChange => 'Andere persoon…';

  @override
  String get personRemove => 'Weghalen';

  @override
  String get personInText => 'in de tekst';

  @override
  String get personErrorSamePerson => 'Kies een andere persoon.';

  @override
  String get personMerge => 'Samenvoegen met…';

  @override
  String personMergePickerTitle(String name) {
    return '$name samenvoegen met';
  }

  @override
  String get personMergeNoOthers => 'Er is nog niemand anders.';

  @override
  String get personMergeTitle => 'Personen samenvoegen?';

  @override
  String personMergeBody(String from, String into) {
    return '$from samenvoegen met $into? Alle items en bijnamen gaan naar $into; \"$from\" blijft werken als bijnaam.';
  }

  @override
  String get personMergeConfirm => 'Samenvoegen';

  @override
  String personMerged(String from, String into) {
    return '$from is samengevoegd met $into';
  }

  @override
  String personMergeWith(String name) {
    return 'Samenvoegen met $name…';
  }

  @override
  String get personMergeUndoFailed =>
      'Ongedaan maken is mislukt; de personen blijven samengevoegd.';

  @override
  String get personBirthdayAdd => 'Verjaardag toevoegen';

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
      other: '$age jaar',
      one: '1 jaar',
    );
    return '$dateString · $_temp0';
  }

  @override
  String get personBirthdayTitle => 'Verjaardag';

  @override
  String get personBirthdayTooltip => 'Verjaardag wijzigen';

  @override
  String get personBirthdayDay => 'Dag';

  @override
  String get personBirthdayMonth => 'Maand';

  @override
  String get personBirthdayYear => 'Jaar (optioneel)';

  @override
  String personMonthName(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMM(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String get personBirthdayInvalid => 'Deze datum bestaat niet.';

  @override
  String get personNoteLabel => 'Notitie';

  @override
  String get personNoteHint => 'Wat je over deze persoon wilt onthouden';

  @override
  String personBirthdaySemantics(String value) {
    return 'Verjaardag: $value';
  }

  @override
  String get reviewTitle => 'Weekoverzicht';

  @override
  String get reviewStartTooltipWithKey => 'Weekoverzicht (Ctrl+Shift+W)';

  @override
  String todayReviewLine(int days) {
    return 'Weekoverzicht · laatste $days d geleden';
  }

  @override
  String todayReviewLineLabel(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dagen',
      one: '1 dag',
    );
    return 'Weekoverzicht, laatste keer $_temp0 geleden';
  }

  @override
  String get todayReviewLineNever => 'Weekoverzicht · nog niet gedaan';

  @override
  String get todayReviewLineNeverLabel => 'Weekoverzicht, nog niet gedaan';

  @override
  String get reviewClose => 'Weekoverzicht sluiten';

  @override
  String get reviewStart => 'Beginnen';

  @override
  String get reviewStepInbox => 'Inbox leeg maken';

  @override
  String get reviewStepWaiting => 'Wacht op doorlopen';

  @override
  String get reviewStepDeadlines => 'Deadlines';

  @override
  String get reviewStepStale => 'Stilgevallen';

  @override
  String reviewInboxCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items te verwerken',
      one: '1 item te verwerken',
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
    return '$overdue verlopen · $upcoming in de komende 2 weken';
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
      other: '$weeks weken',
      one: '1 week',
    );
    return '$_temp0, $_temp1 of langer niet aangeraakt';
  }

  @override
  String get reviewNothing => '✓ niets te doen';

  @override
  String reviewStepOf(int step, int total) {
    return '$step / $total';
  }

  @override
  String get reviewPrevious => 'Vorige';

  @override
  String get reviewNext => 'Volgende';

  @override
  String get reviewFinish => 'Klaar';

  @override
  String get reviewInboxEmpty => '✓ De inbox is leeg';

  @override
  String get reviewProcess => 'Verwerken';

  @override
  String get reviewStillWaiting => 'Wacht nog';

  @override
  String get reviewKeep => 'Houden';

  @override
  String get reviewArchive => 'Archiveren';

  @override
  String get reviewArchived => 'Gearchiveerd';

  @override
  String get reviewHandledWaiting => '✓ Wacht nog';

  @override
  String get reviewHandledKept => '✓ Gehouden';

  @override
  String get reviewHandledDone => '✓ Afgerond';

  @override
  String get reviewHandledArchived => '✓ Gearchiveerd';

  @override
  String get reviewHandledTrashed => '✓ In de prullenbak';

  @override
  String reviewAgeDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dagen niet aangeraakt',
      one: '1 dag niet aangeraakt',
    );
    return '$_temp0';
  }

  @override
  String reviewAgeWeeks(int weeks) {
    return '$weeks weken niet aangeraakt';
  }

  @override
  String reviewOverdue(int count) {
    return 'Verlopen · $count';
  }

  @override
  String reviewUpcoming(int count) {
    return 'Komende 2 weken · $count';
  }

  @override
  String reviewStaleHeader(int weeks, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: '$weeks weken',
      one: '1 week',
    );
    return '$_temp0 of langer niet aangeraakt · $count';
  }

  @override
  String get reviewEndTitle => 'Klaar ✓';

  @override
  String reviewEndKept(int count) {
    return '$count gehouden';
  }

  @override
  String reviewEndDone(int count) {
    return '$count afgerond';
  }

  @override
  String reviewEndArchived(int count) {
    return '$count gearchiveerd';
  }

  @override
  String reviewEndTrashed(int count) {
    return '$count in de prullenbak';
  }

  @override
  String get reviewEndNothing => 'Alles was al bij.';

  @override
  String get reviewEndBack => 'Naar Vandaag';

  @override
  String get settingsReviewHeader => 'Weekoverzicht';

  @override
  String get settingsStaleAfter => 'Stilgevallen na';

  @override
  String get settingsStaleAfterHint =>
      'Een open item dat zo lang niet is aangeraakt, komt in de laatste stap van het weekoverzicht.';

  @override
  String get settingsReviewDueAfter => 'Aan de beurt na';

  @override
  String get settingsReviewDueAfterHint =>
      'Zo lang na het laatste afgeronde weekoverzicht toont Vandaag een regel om het te starten.';

  @override
  String settingsDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dagen',
      one: '1 dag',
    );
    return '$_temp0';
  }

  @override
  String settingsWeeks(int weeks) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: '$weeks weken',
      one: '1 week',
    );
    return '$_temp0';
  }

  @override
  String get settingsSaveFailed =>
      'Opslaan is mislukt; de keuze geldt tot de app opnieuw start.';

  @override
  String reviewEndWaiting(int count) {
    return '$count wacht nog';
  }

  @override
  String get personWorkAdd => 'Functie en organisatie toevoegen';

  @override
  String get personWorkTooltip => 'Functie en organisatie wijzigen';

  @override
  String personWorkSemantics(String value) {
    return 'Functie en organisatie: $value';
  }

  @override
  String personWork(String jobTitle, String organisation) {
    return '$jobTitle · $organisation';
  }

  @override
  String get personWorkTitle => 'Functie en organisatie';

  @override
  String get personJobTitle => 'Functie';

  @override
  String get personOrganisation => 'Organisatie';

  @override
  String get contactSection => 'Contactgegevens';

  @override
  String get contactKindPhone => 'Telefoonnummer';

  @override
  String get contactKindEmail => 'E-mailadres';

  @override
  String get contactAddPhone => 'Telefoonnummer toevoegen';

  @override
  String get contactAddEmail => 'E-mailadres toevoegen';

  @override
  String get contactEditPhone => 'Telefoonnummer wijzigen';

  @override
  String get contactEditEmail => 'E-mailadres wijzigen';

  @override
  String contactStandardLabel(String label) {
    String _temp0 = intl.Intl.selectLogic(label, {
      'work': 'Werk',
      'mobile': 'Mobiel',
      'private': 'Privé',
      'other': 'Anders',
    });
    return '$_temp0';
  }

  @override
  String get contactOwnLabel => 'Eigen label…';

  @override
  String get contactOwnLabelField => 'Label';

  @override
  String get contactInvalidPhone => 'Dit lijkt geen telefoonnummer.';

  @override
  String get contactInvalidEmail => 'Dit lijkt geen e-mailadres.';

  @override
  String get contactEmpty => 'Vul iets in.';

  @override
  String get contactMenuTooltip => 'Acties';

  @override
  String get contactCopy => 'Kopiëren';

  @override
  String get contactCopied => 'Gekopieerd';

  @override
  String get contactEdit => 'Wijzigen…';

  @override
  String get contactDelete => 'Verwijderen';

  @override
  String get contactDeletedPhone => 'Telefoonnummer verwijderd';

  @override
  String get contactDeletedEmail => 'E-mailadres verwijderd';

  @override
  String get contactSaveFailed => 'Opslaan is mislukt.';

  @override
  String get contactUndoFailed => 'Het gegeven kon niet terugkomen.';

  @override
  String contactRowSemantics(String value, String kind) {
    return '$value, $kind';
  }

  @override
  String contactRowSemanticsWithLabel(String value, String label, String kind) {
    return '$value, $label, $kind';
  }

  @override
  String get contactCall => 'Bellen';

  @override
  String get contactMail => 'Mailen';

  @override
  String get contactLaunchFailed => 'Geen app gevonden om dit te openen.';

  @override
  String horizonTitle(int weeks) {
    return 'Komende $weeks weken';
  }

  @override
  String horizonSummary(int lanes, int items) {
    String _temp0 = intl.Intl.pluralLogic(
      lanes,
      locale: localeName,
      other: '$lanes banen',
      one: '1 baan',
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
  String get horizonBusy => 'druk';

  @override
  String get horizonNoProject => 'Geen project';

  @override
  String horizonEmpty(int weeks) {
    return 'Niets met een datum in de komende $weeks weken.';
  }

  @override
  String get horizonLegendDeliver => 'ik lever';

  @override
  String get horizonLegendWaiting => 'wacht op ander';

  @override
  String get horizonLegendOverdue => 'verlopen';

  @override
  String get horizonLegendLate => 'te laat binnen';

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

    return 'Week $number · vanaf $fromString';
  }

  @override
  String horizonToDeliver(int count) {
    return '$count te leveren';
  }

  @override
  String horizonToDeliverBusy(int count) {
    return '$count te leveren · druk';
  }

  @override
  String get horizonWeekEmpty => 'Niets in deze week.';

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

    return 'Verlopen · $dateString';
  }

  @override
  String horizonEntryWaiting(String person, DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMEd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Wacht op $person · verwacht $dateString';
  }

  @override
  String horizonEntryWaitingNobody(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMEd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Wacht · verwacht $dateString';
  }

  @override
  String horizonEntryLate(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMEd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Had binnen moeten zijn · $dateString';
  }

  @override
  String horizonEntryFor(String person) {
    return 'voor $person';
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
      other: '$deliver te leveren',
      one: '1 te leveren',
      zero: 'niets te leveren',
    );
    String _temp1 = intl.Intl.selectLogic(busy, {
      'true': ', druk',
      'other': '',
    });
    String _temp2 = intl.Intl.pluralLogic(
      waiting,
      locale: localeName,
      other: '$waiting wachtend',
      one: '1 wachtend',
      zero: 'niets wachtend',
    );
    return 'Week $number, $fromString tot $toString: $_temp0$_temp1; $_temp2';
  }

  @override
  String get standstillTitle => 'Wat ligt er stil?';

  @override
  String get standstillSizeHint => 'grootte = open items';

  @override
  String standstillOpen(int count) {
    return '$count open';
  }

  @override
  String standstillStill(String age) {
    return 'stil $age';
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
      other: '$days dagen',
      one: '1 dag',
    );
    return '$_temp0';
  }

  @override
  String standstillAgeSpokenWeeks(int weeks) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: '$weeks weken',
      one: '1 week',
    );
    return '$_temp0';
  }

  @override
  String standstillTileSemantics(String project, int count, String age) {
    return '$project: $count open, $age stil';
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
  String get standstillOldest => 'Langst niet aangeraakt';

  @override
  String get standstillToReview => 'Naar weekoverzicht →';

  @override
  String standstillProjectItems(String project, int count) {
    return '$project · $count open';
  }

  @override
  String get standstillOpenProject => 'Project openen →';

  @override
  String get standstillShowOldest => 'Terug naar langst niet aangeraakt';

  @override
  String get standstillEmpty => 'Niets open: er ligt niets stil.';

  @override
  String get navInsights => 'Inzicht';

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
      'standstill': 'Stilstand',
      'both': 'Horizon en stilstand',
      'connections': 'Verbanden',
      'other': 'Personen',
    });
    return '$_temp0';
  }

  @override
  String get reviewStepInsights => 'Inzicht';

  @override
  String get reviewInsightsSummary =>
      'Wat komt eraan, wat ligt stil, hoe sta je ervoor met wie';

  @override
  String get reviewContinue => 'Verder';

  @override
  String get settingsInsightsHeader => 'Inzicht';

  @override
  String get settingsBusyFrom => 'Druk vanaf';

  @override
  String get settingsBusyFromHint =>
      'Een week met zo veel items met een deadline, of meer, heet druk in de Horizon.';

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
  String get whereWasI => 'Waar was ik?';

  @override
  String get whereWasITooltipWithKey => 'Waar was ik? (Ctrl+Shift+P)';

  @override
  String get whereWasINextStep => 'Volgende stap';

  @override
  String get whereWasIInMind => 'Wat ik in mijn hoofd had';

  @override
  String get whereWasIInMindHint => 'Bijv. waarom, wat je wilde checken…';

  @override
  String get whereWasIClose => 'Sluiten';

  @override
  String get whereWasISave => 'Opslaan';

  @override
  String get whereWasISaveFailed => 'Waar was ik? is niet opgeslagen.';

  @override
  String get resumeCardTitle => 'Waar was ik';

  @override
  String get resumeUpdate => 'Bijwerken';

  @override
  String get resumeResume => 'Hervat';

  @override
  String connectionsFocusKind(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'person': 'Focus · persoon',
      'project': 'Focus · project',
      'other': 'Focus',
    });
    return '$_temp0';
  }

  @override
  String get connectionsChange => 'Wijzig';

  @override
  String get connectionsOneStep => '1 stap';

  @override
  String get connectionsTwoSteps => '2 stappen';

  @override
  String get connectionsLegendDirect => 'direct gekoppeld';

  @override
  String get connectionsLegendThrough => 'via tussenstap';

  @override
  String get connectionsHint =>
      'Tik om te focussen · lang indrukken voor een voorbeeld · knijp om te zoomen';

  @override
  String get connectionsHintDesktop =>
      'Klik om te focussen · wijs aan voor een voorbeeld · Ctrl+scrollen zoomt';

  @override
  String get connectionsFit => 'Passend';

  @override
  String connectionsMore(int count) {
    return '+$count meer';
  }

  @override
  String get connectionsEmptyTitle => 'Hoe hangt het samen?';

  @override
  String get connectionsEmptyBody =>
      'Kies een item, persoon of project; je ziet wat ermee verbonden is.';

  @override
  String get connectionsChoose => 'Kies een item';

  @override
  String get connectionsNothing => 'Nog niets gekoppeld';

  @override
  String get connectionsChooseTitle => 'Focus kiezen';

  @override
  String get connectionsChooseHint => 'Zoek een item, persoon of project';

  @override
  String get connectionsRecent => 'Recent geopend';

  @override
  String get connectionsChooseItems => 'Items';

  @override
  String get connectionsChoosePeople => 'Personen';

  @override
  String get connectionsChooseProjects => 'Projecten';

  @override
  String get connectionsNoResults => 'Niets gevonden';

  @override
  String connectionsAllTitle(String name, int count) {
    return 'Verbanden van $name · $count';
  }

  @override
  String connectionsDirectHeader(int count) {
    return 'Direct gekoppeld · $count';
  }

  @override
  String get connectionsFocusAction => 'Focussen';

  @override
  String get connectionsOpenAction => 'Openen';

  @override
  String get connectionsPreviewAction => 'Voorbeeld';

  @override
  String get connectionsShow => 'Verbanden tonen';

  @override
  String connectionsKind(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'project': 'Project',
      'person': 'Persoon',
      'other': 'Item',
    });
    return '$_temp0';
  }

  @override
  String connectionsUrgency(String urgency) {
    String _temp0 = intl.Intl.selectLogic(urgency, {
      'today': 'vandaag',
      'other': 'verlopen',
    });
    return '$_temp0';
  }

  @override
  String get connectionsDone => 'af';

  @override
  String get connectionsArchived => 'gearchiveerd';

  @override
  String connectionsReason(String reason) {
    String _temp0 = intl.Intl.selectLogic(reason, {
      'linksTo': 'koppeling',
      'linkedFrom': 'verwijst hiernaar',
      'project': 'project',
      'inProject': 'in dit project',
      'parent': 'hoofdproject',
      'other': 'subproject',
    });
    return '$_temp0';
  }

  @override
  String connectionsReasonPerson(String reason, String name) {
    String _temp0 = intl.Intl.selectLogic(reason, {
      'requester': 'gevraagd door $name',
      'waitingOn': 'wacht op $name',
      'other': 'noemt $name',
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
    return 'Focus: $kind $title. $direct direct gekoppeld, $through via een tussenstap.';
  }

  @override
  String connectionsDirectSemantics(String kind, String title, String reasons) {
    return 'Direct gekoppeld: $kind $title, $reasons';
  }

  @override
  String connectionsThroughSemantics(String via, String kind, String title) {
    return 'Via tussenstap $via: $kind $title';
  }

  @override
  String connectionsBehindSemantics(int count, String title) {
    return 'nog $count via $title';
  }

  @override
  String connectionsMoreSemantics(int count) {
    return 'Nog $count verbanden, opent de lijst';
  }

  @override
  String get connectionsPreviewProject => 'Project';

  @override
  String get connectionsPreviewDeadline => 'Deadline';

  @override
  String get connectionsPreviewPeople => 'Personen';

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
      zero: 'Geen open items',
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
  String get reminderChannelName => 'Herinneringen';

  @override
  String get reminderTitleOne => 'Deadline vandaag';

  @override
  String reminderTitleMany(int count) {
    return '$count deadlines vandaag';
  }

  @override
  String reminderMore(int count) {
    return 'en nog $count';
  }

  @override
  String get reminderRefused =>
      'Zonder meldingen zie je deadlines en teruggekomen items op Vandaag.';

  @override
  String get reminderRefusedAction => 'Instellingen';

  @override
  String get settingsRemindersHeader => 'Herinneringen';

  @override
  String get settingsRemindersOn => 'Meldingen bij deadlines en terugzien';

  @override
  String get settingsRemindersOnHint => 'Op de dag zelf; één melding per dag.';

  @override
  String get settingsReminderTime => 'Tijdstip';

  @override
  String get settingsReminderTimeHint => 'Wanneer de melding van die dag komt.';

  @override
  String get settingsRemindersBlocked => 'Meldingen staan uit in Android';

  @override
  String get settingsRemindersBlockedHint =>
      'Deadlines en teruggekomen items staan wel op Vandaag.';

  @override
  String get settingsRemindersAllow => 'Meldingen toestaan';

  @override
  String get revisitAction => 'Terugzien op…';

  @override
  String get revisitSheetTitle => 'Terugzien op';

  @override
  String get revisitTomorrow => 'Morgen';

  @override
  String get revisitNextWeek => 'Volgende week';

  @override
  String get revisitInAMonth => 'Over een maand';

  @override
  String get revisitChooseDate => 'Kies datum…';

  @override
  String get revisitStop => 'Niet meer terugzien';

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

    return 'Terugzien op $dateString';
  }

  @override
  String revisitBackOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMEd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Terug op $dateString';
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

    return '✓ Terug op $dateString';
  }

  @override
  String reviewEndParked(int count) {
    return '$count later terugzien';
  }

  @override
  String todayBackSection(int count) {
    return 'Terug in je inbox · $count';
  }

  @override
  String get reminderBackOne => 'Terug in je inbox';

  @override
  String reminderBackMany(int count) {
    return '$count terug in je inbox';
  }

  @override
  String reminderTitleBoth(int deadlines, int back) {
    String _temp0 = intl.Intl.pluralLogic(
      deadlines,
      locale: localeName,
      other: '$deadlines deadlines',
      one: '1 deadline',
    );
    return '$_temp0 · $back terug in je inbox';
  }

  @override
  String reminderBackLine(String title) {
    return 'Terug: $title';
  }

  @override
  String get settingsReviewReminderOn => 'Herinnering weekoverzicht';

  @override
  String get settingsReviewReminderOnHint =>
      'Alleen als het weekoverzicht aan de beurt is.';

  @override
  String get settingsReviewReminderDay => 'Dag';

  @override
  String settingsReviewReminderDayName(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.EEEE(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String get reviewReminderTitle => 'Weekoverzicht aan de beurt';

  @override
  String reviewReminderLast(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Laatste keer $days dagen geleden',
      one: 'Laatste keer 1 dag geleden',
    );
    return '$_temp0';
  }

  @override
  String get reviewReminderNever => 'Nog niet gedaan';

  @override
  String birthdayReminderOne(String name) {
    return '$name is vandaag jarig';
  }

  @override
  String birthdayReminderTurns(int age) {
    return 'wordt $age';
  }

  @override
  String birthdayReminderMany(int count) {
    return '$count verjaardagen vandaag';
  }

  @override
  String birthdayReminderPersonAge(String name, int age) {
    return '$name ($age)';
  }

  @override
  String get birthdayReminderPublic => 'Verjaardag vandaag';

  @override
  String todayBirthday(String name) {
    return '$name is vandaag jarig';
  }

  @override
  String todayBirthdayAge(String name, int age) {
    return '$name wordt vandaag $age';
  }

  @override
  String get settingsBirthdayRemindersOn => 'Verjaardagen';

  @override
  String get settingsBirthdayRemindersOnHint =>
      'Op de dag zelf, op het tijdstip van de dagmelding.';

  @override
  String nudgeSilentDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dagen stil',
      one: '1 dag stil',
    );
    return '$_temp0';
  }

  @override
  String nudgeReminderOne(String person, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dagen stil',
      one: '1 dag stil',
    );
    return 'Wacht nog op $person · $_temp0';
  }

  @override
  String nudgeReminderOneNobody(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dagen stil',
      one: '1 dag stil',
    );
    return 'Wacht nog · $_temp0';
  }

  @override
  String nudgeReminderMany(int count) {
    return '$count wacht-items blijven stil';
  }

  @override
  String get nudgeReminderPublic => 'Wacht-item blijft stil';

  @override
  String todaySilentSection(int count) {
    return 'Blijft stil · $count';
  }

  @override
  String get nudgeReceived => 'Ontvangen';

  @override
  String todayNotesSection(int count) {
    return 'Waar was ik · $count';
  }

  @override
  String todayNotesMore(int count) {
    return '+$count meer';
  }

  @override
  String todayNoteInMind(String text) {
    return 'In mijn hoofd: $text';
  }

  @override
  String get todayNoteProject => 'Project';

  @override
  String get settingsTodayHeader => 'Vandaag';

  @override
  String get settingsTodayNotes => 'Waar was ik op Vandaag';

  @override
  String get settingsTodayNotesHint =>
      'Je open notities bovenaan Vandaag, nieuwste eerst.';

  @override
  String get nudgeChased => 'Nagevraagd';

  @override
  String get nudgeChasedMessage => 'Nagevraagd';

  @override
  String get settingsNudgeOn => 'Wacht-items die stil blijven';

  @override
  String get settingsNudgeOnHint =>
      'Eén melding op de dag dat een item stil wordt.';

  @override
  String get settingsNudgeAfter => 'Navragen na';

  @override
  String get settingsNudgeAfterHint =>
      'Zo lang niets veranderd: dan staat het item op Vandaag.';

  @override
  String get tokenRepeatDaily => 'dagelijks';

  @override
  String get tokenRepeatWeekly => 'wekelijks';

  @override
  String get tokenRepeatMonthly => 'maandelijks';

  @override
  String get tokenRepeatLabel => 'herhalen';

  @override
  String get tokenRepeatExample =>
      'Hardlopen !wekelijks !di, ook !dagelijks of !maandelijks';

  @override
  String itemCompletedNextTime(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMEd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Afgerond · volgende keer $dateString';
  }

  @override
  String repeatRhythm(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'D': 'dagelijks',
      'W': 'wekelijks',
      'M': 'maandelijks',
      'other': 'herhaalt',
    });
    return '$_temp0';
  }

  @override
  String repeatRhythmTitle(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'D': 'Dagelijks',
      'W': 'Wekelijks',
      'M': 'Maandelijks',
      'other': 'Herhaalt',
    });
    return '$_temp0';
  }

  @override
  String repeatEvery(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'D': 'elke dag',
      'W': 'elke week',
      'M': 'elke maand',
      'other': 'herhaalt',
    });
    return '$_temp0';
  }

  @override
  String repeatSinceDaily(DateTime since) {
    final intl.DateFormat sinceDateFormat = intl.DateFormat.MMMd(localeName);
    final String sinceString = sinceDateFormat.format(since);

    return 'Dagelijks · sinds $sinceString';
  }

  @override
  String repeatSinceWeekly(DateTime weekday, DateTime since) {
    final intl.DateFormat weekdayDateFormat = intl.DateFormat.E(localeName);
    final String weekdayString = weekdayDateFormat.format(weekday);
    final intl.DateFormat sinceDateFormat = intl.DateFormat.MMMd(localeName);
    final String sinceString = sinceDateFormat.format(since);

    return 'Wekelijks · elke $weekdayString, sinds $sinceString';
  }

  @override
  String repeatSinceMonthly(int day, DateTime since) {
    final intl.DateFormat sinceDateFormat = intl.DateFormat.MMMd(localeName);
    final String sinceString = sinceDateFormat.format(since);

    return 'Maandelijks · op de ${day}e, sinds $sinceString';
  }

  @override
  String repeatNotForType(String rhythm) {
    return '$rhythm · herhaalt alleen bij een taak';
  }

  @override
  String repeatThisTime(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMEd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Deze keer: $dateString';
  }

  @override
  String completionsTitle(int count) {
    return 'Gedaan · $count×';
  }

  @override
  String get completionOnTime => 'op tijd';

  @override
  String completionLate(DateTime date, int days) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMEd(localeName);
    final String dateString = dateDateFormat.format(date);

    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dagen te laat',
      one: '1 dag te laat',
    );
    return 'keer van $dateString · $_temp0';
  }

  @override
  String completionsShowAll(int count) {
    return 'Alles tonen ($count)';
  }

  @override
  String get completeAndRepeat => 'Afronden en herhalen…';

  @override
  String get completeAndRepeatTitle => 'Afronden en herhalen';

  @override
  String get completeAndRepeatQuestion =>
      'Deze keer is klaar. Wanneer komt hij terug?';

  @override
  String get completeAndRepeatNote =>
      'Zet het woord in de tekst; weghalen stopt de herhaling.';

  @override
  String get stopRepeating => 'Herhaling stoppen';

  @override
  String get repeatStopped => 'Herhaling gestopt · afgerond';

  @override
  String get androidBarName => 'Offload-balk';

  @override
  String get androidBarDescription =>
      'Vastleggen, Vandaag en Inzicht met één tik';

  @override
  String get androidOpenToday => 'Vandaag openen';

  @override
  String get androidOpenInsights => 'Inzicht openen';

  @override
  String get helpTitle => 'Help';

  @override
  String get helpOpenRow => 'De handleiding: hoe Offload werkt';

  @override
  String get helpTooltip => 'Help';

  @override
  String get helpTooltipWithKey => 'Help (F1)';

  @override
  String get helpContents => 'Inhoud';

  @override
  String get helpInEnglish => 'De handleiding is in het Engels.';

  @override
  String get helpLoadFailed =>
      'Dit deel van de handleiding kon niet worden geopend.';

  @override
  String helpExternalLink(String address) {
    return 'Offload opent geen internetadressen: $address';
  }

  @override
  String get helpCopy => 'Kopiëren';

  @override
  String get syntaxOverviewManual => 'Meer in de handleiding';

  @override
  String get storageAttachments => 'Bijlagen';

  @override
  String storageAttachmentKind(String kind, String size) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'photo': 'Foto\'s',
      'audio': 'Audio',
      'other': 'Overig',
    });
    return '$_temp0 $size';
  }

  @override
  String get photoAdd => 'Foto toevoegen';

  @override
  String get photoAddOpen => 'Foto toevoegen…';

  @override
  String get photoTake => 'Foto maken';

  @override
  String get photoFromGallery => 'Uit galerij';

  @override
  String get photoFileTypeName => 'Afbeeldingen';

  @override
  String photosHeader(int count) {
    return 'Foto\'s · $count';
  }

  @override
  String get photoProcessing => 'Foto verwerken…';

  @override
  String get photoUnreadable => 'Deze foto kan Offload niet lezen.';

  @override
  String get photoTooLarge => 'Deze foto is te groot.';

  @override
  String get photoSourceFailed => 'De foto kon niet worden geopend.';

  @override
  String get photoSaveFailed => 'De foto is niet opgeslagen.';

  @override
  String photoSemantics(int index, int count) {
    return 'Foto $index van $count';
  }

  @override
  String get photoView => 'Bekijken';

  @override
  String get photoDelete => 'Verwijderen';

  @override
  String get photoDeleteTitle => 'Foto verwijderen?';

  @override
  String get photoDeleteBody =>
      'De foto verdwijnt uit dit item. Dit kun je niet ongedaan maken.';

  @override
  String get photoDeleteCancel => 'Annuleren';

  @override
  String get photoDeleteFailed => 'De foto is niet verwijderd.';

  @override
  String get photoMissing => 'Bijlage niet in deze back-up';
}
