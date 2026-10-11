import '../../domain/export/export_markdown.dart';
import '../../domain/items/item_enums.dart';
import '../../domain/people/birthday.dart';
import '../../domain/people/contact_detail.dart';
import '../../domain/time/local_date.dart';
import '../../l10n/app_localizations.dart';
import '../items/item_labels.dart';
import '../people/person_contacts.dart';

/// The words of the Markdown export in the app's language (T7.3, DD-009).
class L10nExportLabels implements ExportLabels {
  const L10nExportLabels(this.l10n);

  final AppLocalizations l10n;

  static DateTime _at(LocalDate day) => DateTime(day.year, day.month, day.day);

  @override
  String get title => l10n.exportTitle;

  @override
  String madeOn(DateTime moment) {
    final local = moment.toLocal();
    return l10n.exportMadeOn(local, local);
  }

  @override
  String counts(int items, int projects, int people) =>
      l10n.exportCounts(items, projects, people);

  @override
  String get projects => l10n.exportProjects;

  @override
  String get withoutProject => l10n.exportWithoutProject;

  @override
  String get people => l10n.exportPeople;

  @override
  String get archived => l10n.exportArchived;

  @override
  String status(ItemStatus status) => l10n.status(status);

  @override
  String? type(ItemType? type) => type == null ? null : l10n.type(type);

  @override
  String priority(ItemPriority priority) =>
      l10n.tokenPriorityChip(priority.name);

  @override
  String due(LocalDate day) => l10n.exportDue(_at(day));

  @override
  String revisit(LocalDate day) => l10n.exportRevisit(_at(day));

  @override
  String requester(String name) => l10n.exportRequester(name);

  @override
  String waitingOn(String name) => l10n.exportWaitingOn(name);

  @override
  String asked(LocalDate day) => l10n.exportAsked(_at(day));

  @override
  String promise(String text) => l10n.exportPromise(text);

  @override
  String expected(LocalDate day) => l10n.exportExpected(_at(day));

  @override
  String captured(DateTime moment) => l10n.exportCaptured(moment.toLocal());

  @override
  String nextStep(String text) => l10n.exportNextStep(text);

  @override
  String inMind(String text) => l10n.exportInMind(text);

  @override
  String completions(List<LocalDate> days) => l10n.exportCompletions(
    // A plain list separator, as for the aliases.
    days.map((day) => l10n.exportDay(_at(day))).join(', '),
  );

  @override
  String aliases(List<String> aliases) =>
      l10n.exportAliases(aliases.join(', '));

  @override
  String birthday(Birthday birthday) => switch (birthday.year) {
    null => l10n.exportBirthdayNoYear(
      DateTime(2000, birthday.month, birthday.day),
    ),
    final year => l10n.exportBirthday(
      DateTime(year, birthday.month, birthday.day),
    ),
  };

  @override
  String work(String? organisation, String? jobTitle) =>
      l10n.exportWork([?organisation, ?jobTitle].join(', '));

  @override
  String contact(ContactKind kind, String? label) {
    final kindText = switch (kind) {
      ContactKind.phone => l10n.contactKindPhone,
      ContactKind.email => l10n.contactKindEmail,
    };
    final labelText = contactLabelText(label, l10n);
    return labelText == null
        ? kindText
        : l10n.exportContact(kindText, labelText);
  }
}
