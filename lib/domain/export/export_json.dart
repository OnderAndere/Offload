import 'dart:convert';

import '../items/item.dart';
import '../people/contact_detail.dart';
import '../time/local_date.dart';
import '../tokens/token_processing.dart';
import 'export_data.dart';

/// The name of the format in [exportJson], for whoever reads it later.
const exportJsonFormat = 'offload-export';

/// The version of the structure of [exportJson]; raised when it changes.
const exportJsonVersion = 1;

/// [data] as JSON (T7.3, PO 09-10-2026): a fixed structure with
/// `"format": "offload-export"` and `"version": 1`, UUIDs as ids, moments in
/// ISO 8601 UTC, days as `yyyy-mm-dd`, English keys, every field of the
/// records with null where empty; [appVersion] null for a development
/// build. Indented, UTF-8 once written.
String exportJson(
  ExportData data, {
  required DateTime exportedAt,
  required String? appVersion,
}) {
  final detailsOf = <String, List<ContactDetail>>{};
  for (final detail in data.contactDetails) {
    detailsOf.putIfAbsent(detail.personId, () => []).add(detail);
  }
  return const JsonEncoder.withIndent('  ').convert({
    'format': exportJsonFormat,
    'version': exportJsonVersion,
    'exportedAt': _moment(exportedAt),
    'appVersion': appVersion,
    'items': [for (final item in _byId(data.items)) _item(item)],
    'projects': [
      for (final project in data.projects)
        {
          'id': project.id,
          'name': project.name,
          'parentId': project.parentId,
          'archivedAt': _moment(project.archivedAt),
        },
    ],
    'people': [
      for (final exported in data.people)
        {
          'id': exported.person.id,
          'name': exported.person.name,
          'aliases': exported.person.aliases,
          'birthday': switch (exported.person.birthday) {
            null => null,
            final birthday => {
              'day': birthday.day,
              'month': birthday.month,
              'year': birthday.year,
            },
          },
          'note': exported.person.note,
          'organisation': exported.person.organisation,
          'jobTitle': exported.person.jobTitle,
          'mergedIntoId': exported.mergedIntoId,
          'contactDetails': [
            for (final detail in _inOrder(detailsOf[exported.person.id]))
              {
                'id': detail.id,
                'kind': detail.kind.name,
                'value': detail.value,
                'label': detail.label,
                'sortOrder': detail.sortOrder,
              },
          ],
        },
    ],
    'links': [
      for (final link in data.links)
        {
          'fromItemId': link.fromItemId,
          'toItemId': link.toItemId,
          'kind': link.kind,
          'label': link.label,
        },
    ],
    'completions': [
      for (final completion in data.completions)
        {
          'itemId': completion.itemId,
          'occurrenceOn': _day(completion.occurrenceOn),
          'completedOn': _day(completion.completedOn),
        },
    ],
    'whereWasI': [
      for (final note in data.notes)
        {
          'id': note.id,
          'itemId': note.itemId,
          'projectId': note.projectId,
          'nextStep': note.nextStep,
          'inMind': note.inMind,
          'savedAt': _moment(note.savedAt),
          'resumedAt': _moment(note.resumedAt),
        },
    ],
  });
}

Map<String, Object?> _item(Item item) => {
  'id': item.id,
  'capturedAt': _moment(item.capturedAt),
  'changedAt': _moment(item.changedAt),
  'rawText': item.rawText,
  'note': item.body,
  'type': item.type?.name,
  'status': item.status.name,
  'source': item.source.name,
  'projectId': item.projectId,
  'priority': item.priority?.name,
  'dueOn': _day(_dateOf(item.dueAt)),
  'revisitOn': _day(_dateOf(item.revisitAt)),
  'requesterId': item.requesterId,
  'waitingOnId': item.waitingOnId,
  'askedOn': _day(item.askedAt),
  'promise': item.promise,
  'expectedOn': _day(item.expectedAt),
  'reviewedAt': _moment(item.reviewedAt),
};

/// Contact details in the order the person shows them.
List<ContactDetail> _inOrder(List<ContactDetail>? details) =>
    [...?details]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

/// Items in the order of capture (UUIDv7 ids).
List<Item> _byId(List<Item> items) =>
    [...items]..sort((a, b) => a.id.compareTo(b.id));

LocalDate? _dateOf(DateTime? stored) =>
    stored == null ? null : storedToDateOnly(stored);

String? _day(LocalDate? day) => day?.toString();

String? _moment(DateTime? moment) => moment?.toUtc().toIso8601String();
