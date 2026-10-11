import '../items/item.dart';
import '../items/item_enums.dart';
import '../people/birthday.dart';
import '../people/contact_detail.dart';
import '../projects/project.dart';
import '../time/local_date.dart';
import '../tokens/token_processing.dart';
import 'export_data.dart';

/// The words of the Markdown export, in the app's language (DD-009); the
/// presentation layer fills them from the ARB files. Moments come in UTC.
abstract interface class ExportLabels {
  String get title;
  String madeOn(DateTime moment);
  String counts(int items, int projects, int people);
  String get projects;
  String get withoutProject;
  String get people;

  /// After the name of an archived project.
  String get archived;

  String status(ItemStatus status);

  /// The type, or null for an item without one (nothing is shown).
  String? type(ItemType? type);
  String priority(ItemPriority priority);
  String due(LocalDate day);
  String revisit(LocalDate day);
  String requester(String name);
  String waitingOn(String name);
  String asked(LocalDate day);
  String promise(String text);
  String expected(LocalDate day);
  String captured(DateTime moment);
  String nextStep(String text);
  String inMind(String text);
  String completions(List<LocalDate> days);
  String aliases(List<String> aliases);
  String birthday(Birthday birthday);
  String work(String? organisation, String? jobTitle);
  String contact(ContactKind kind, String? label);
}

/// [data] as one readable Markdown file (T7.3, PO 09-10-2026): per project
/// (sub-projects after their parent, archived ones marked) the items grouped
/// by status, then the items without a project, then the people. Each item
/// as typed, tokens and all (the raw text is the source, DD-004 point 1),
/// with a line of facts under it: type, deadline, priority, people, when
/// captured. Only Markdown's block markers at the start of a line are
/// escaped, so nothing typed becomes a heading or a list.
String exportMarkdown(
  ExportData data,
  ExportLabels labels, {
  required DateTime exportedAt,
}) {
  final out = StringBuffer()
    ..writeln('# ${labels.title}')
    ..writeln()
    ..writeln(
      '${labels.madeOn(exportedAt)} · '
      '${labels.counts(data.items.length, data.projects.length, _shownPeople(data).length)}',
    );

  final projectsById = {for (final p in data.projects) p.id: p};
  final peopleById = {for (final p in data.people) p.person.id: p};
  final itemsOf = <String?, List<Item>>{};
  for (final item in [...data.items]..sort((a, b) => a.id.compareTo(b.id))) {
    final project = projectsById.containsKey(item.projectId)
        ? item.projectId
        : null;
    itemsOf.putIfAbsent(project, () => []).add(item);
  }
  final openNoteOfItem = <String, ExportNote>{};
  final openNoteOfProject = <String, ExportNote>{};
  for (final note in data.notes.where((n) => n.isOpen)) {
    // The one saved last shows, as in the app (DD-018 point 13).
    bool newer(ExportNote? other) =>
        other == null ||
        (note.savedAt ?? DateTime(0)).isAfter(other.savedAt ?? DateTime(0));
    if (note.itemId case final id? when newer(openNoteOfItem[id])) {
      openNoteOfItem[id] = note;
    }
    if (note.projectId case final id? when newer(openNoteOfProject[id])) {
      openNoteOfProject[id] = note;
    }
  }
  final doneOn = <String, List<LocalDate>>{};
  for (final completion in data.completions) {
    doneOn
        .putIfAbsent(completion.itemId, () => [])
        .add(completion.occurrenceOn);
  }

  /// The name of person [id], following merges; null when unknown.
  String? nameOf(String? id) {
    var current = id;
    for (var step = 0; current != null && step < 10; step++) {
      final person = peopleById[current];
      if (person == null) return null;
      final next = person.mergedIntoId;
      if (next == null) return person.person.name;
      current = next;
    }
    return null;
  }

  void writeNote(ExportNote? note, String indent) {
    if (note == null) return;
    if (note.nextStep case final text?) {
      out.writeln('$indent⏸ ${_escapeLine(labels.nextStep(text))}  ');
    }
    if (note.inMind case final text?) {
      out.writeln('$indent⏸ ${_escapeLine(labels.inMind(text))}  ');
    }
  }

  void writeItem(Item item) {
    final lines = item.rawText.trim().split(_lineBreak);
    for (var i = 0; i < lines.length; i++) {
      final prefix = i == 0 ? '- ' : '  ';
      final line = lines[i].trimRight();
      // Two spaces keep the line break when the Markdown is rendered.
      final end = i < lines.length - 1 ? '  ' : '';
      out.writeln(line.isEmpty ? '' : '$prefix${_escapeLine(line)}$end');
    }
    final facts = <String>[
      ?labels.type(item.type),
      if (item.dueAt case final due?) labels.due(storedToDateOnly(due)),
      if (item.status == ItemStatus.scheduled)
        if (item.revisitAt case final at?) labels.revisit(storedToDateOnly(at)),
      if (item.priority case final priority?) labels.priority(priority),
      if (nameOf(item.requesterId) case final name?) labels.requester(name),
      if (nameOf(item.waitingOnId) case final name?) labels.waitingOn(name),
      if (item.askedAt case final day?) labels.asked(day),
      if (item.promise case final text?) labels.promise(text),
      if (item.expectedAt case final day?) labels.expected(day),
      labels.captured(item.capturedAt),
    ];
    out
      ..writeln()
      ..writeln('  ${_escapeLine(facts.join(' · '))}  ');
    if (doneOn[item.id] case final days?) {
      out.writeln('  ${_escapeLine(labels.completions(days..sort()))}  ');
    }
    writeNote(openNoteOfItem[item.id], '  ');
    if (item.body case final body? when body.trim().isNotEmpty) {
      out.writeln();
      for (final line in body.trimRight().split(_lineBreak)) {
        final text = line.trimRight();
        out.writeln(text.isEmpty ? '  >' : '  > ${_escapeLine(text)}');
      }
    }
    out.writeln();
  }

  void writeItems(List<Item>? items, String level) {
    if (items == null) return;
    for (final status in ItemStatus.values) {
      final inStatus = [
        for (final item in items)
          if (item.status == status) item,
      ];
      if (inStatus.isEmpty) continue;
      out
        ..writeln('$level ${labels.status(status)}')
        ..writeln();
      inStatus.forEach(writeItem);
    }
  }

  if (data.projects.isNotEmpty) {
    out
      ..writeln()
      ..writeln('## ${labels.projects}');
    for (final project in _treeOrder(data.projects)) {
      final parent = projectsById[project.parentId];
      final name = parent == null
          ? project.name
          : '${parent.name} › ${project.name}';
      out
        ..writeln()
        ..writeln(
          '### ${_escapeInline(name)}'
          '${project.isArchived ? ' (${labels.archived})' : ''}',
        )
        ..writeln();
      if (openNoteOfProject[project.id] case final note?) {
        writeNote(note, '');
        out.writeln();
      }
      writeItems(itemsOf[project.id], '####');
    }
  }

  if (itemsOf[null] case final loose?) {
    out
      ..writeln()
      ..writeln('## ${labels.withoutProject}')
      ..writeln();
    writeItems(loose, '###');
  }

  final shownPeople = _shownPeople(data);
  if (shownPeople.isNotEmpty) {
    final detailsOf = <String, List<ContactDetail>>{};
    for (final detail in data.contactDetails) {
      detailsOf.putIfAbsent(detail.personId, () => []).add(detail);
    }
    out
      ..writeln()
      ..writeln('## ${labels.people}');
    for (final exported in shownPeople) {
      final person = exported.person;
      out
        ..writeln()
        ..writeln('### ${_escapeInline(person.name)}')
        ..writeln();
      final lines = <String>[
        if (person.aliases.isNotEmpty) labels.aliases(person.aliases),
        if (person.birthday case final birthday?) labels.birthday(birthday),
        if (person.organisation != null || person.jobTitle != null)
          labels.work(person.organisation, person.jobTitle),
      ];
      for (final line in lines) {
        out.writeln('${_escapeLine(line)}  ');
      }
      final details = [...?detailsOf[person.id]]
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      if (details.isNotEmpty) {
        if (lines.isNotEmpty) out.writeln();
        for (final detail in details) {
          out.writeln(
            '- ${labels.contact(detail.kind, detail.label)}: '
            // Not at the start of a line: nothing to escape.
            '${detail.value.replaceAll(_lineBreak, ' ').trim()}',
          );
        }
      }
      if (person.note case final note? when note.trim().isNotEmpty) {
        out.writeln();
        for (final line in note.trimRight().split(_lineBreak)) {
          final text = line.trimRight();
          out.writeln(text.isEmpty ? '>' : '> ${_escapeLine(text)}');
        }
      }
    }
  }
  return out.toString();
}

/// The people the Markdown lists: not the merged ones, which live on as
/// names of the person they were merged into. By name.
List<ExportPerson> _shownPeople(ExportData data) =>
    [
      for (final p in data.people)
        if (p.mergedIntoId == null) p,
    ]..sort(
      (a, b) =>
          a.person.name.toLowerCase().compareTo(b.person.name.toLowerCase()),
    );

/// Top-level projects by name, each followed by its sub-projects by name;
/// a sub-project whose parent is not exported comes as a top-level one.
List<Project> _treeOrder(List<Project> projects) {
  int byName(Project a, Project b) =>
      a.name.toLowerCase().compareTo(b.name.toLowerCase());
  final ids = {for (final p in projects) p.id};
  final top = [
    for (final p in projects)
      if (p.parentId == null || !ids.contains(p.parentId)) p,
  ]..sort(byName);
  return [
    for (final parent in top) ...[
      parent,
      ...[
        for (final p in projects)
          if (p.parentId == parent.id) p,
      ]..sort(byName),
    ],
  ];
}

final _lineBreak = RegExp(r'\r\n|\r|\n');

/// A block marker at the start of a line: a heading, quote, list, fence,
/// table or rule.
final _blockStart = RegExp(r'^(\s*)([#>+\-*=`|~]|\d+[.)])');

/// [line] with a backslash before a block marker at its start, so typed
/// text never turns into structure.
String _escapeLine(String line) => line.replaceFirstMapped(_blockStart, (m) {
  final marker = m[2]!;
  final number = RegExp(r'^(\d+)([.)])$').firstMatch(marker);
  return number == null
      ? '${m[1]}\\$marker'
      : '${m[1]}${number[1]}\\${number[2]}';
});

/// [text] for a heading or a list line: on one line, its start escaped.
String _escapeInline(String text) =>
    _escapeLine(text.replaceAll(_lineBreak, ' ').trim());
