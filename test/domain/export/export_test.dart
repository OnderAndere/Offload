import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:offload/domain/export/export_data.dart';
import 'package:offload/domain/export/export_json.dart';
import 'package:offload/domain/export/export_markdown.dart';
import 'package:offload/domain/items/item.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/domain/people/birthday.dart';
import 'package:offload/domain/people/contact_detail.dart';
import 'package:offload/domain/people/person.dart';
import 'package:offload/domain/projects/project.dart';
import 'package:offload/domain/time/local_date.dart';
import 'package:offload/domain/tokens/token_processing.dart';

/// Export to Markdown and JSON (T7.3, REQ-014, PO decisions 09-10-2026).
void main() {
  final exportedAt = DateTime.utc(2026, 10, 9, 12, 30);

  // UUIDv7-like ids: the first 12 hex digits are the capture time in ms.
  String idAt(DateTime moment, String rest) =>
      '${moment.millisecondsSinceEpoch.toRadixString(16).padLeft(12, '0')}'
      '-7000-8000-$rest';

  final kozijnen = idAt(DateTime.utc(2026, 10, 1, 9), '000000000001');
  final tegels = idAt(DateTime.utc(2026, 10, 2, 9), '000000000002');
  final boodschappen = idAt(DateTime.utc(2026, 10, 3, 9), '000000000003');
  final kyiv = idAt(DateTime.utc(2026, 10, 4, 9), '000000000004');

  ExportData sample() => ExportData(
    items: [
      Item(
        id: tegels,
        rawText: 'Tegelzetter mailen !vr *hoog @Jan',
        status: ItemStatus.waiting,
        source: ItemSource.app,
        type: ItemType.task,
        projectId: 'keuken',
        priority: ItemPriority.high,
        dueAt: dateOnlyToStored(LocalDate(2026, 10, 10)),
        waitingOnId: 'jj',
        expectedAt: LocalDate(2026, 10, 12),
      ),
      Item(
        id: kozijnen,
        rawText: 'Offerte kozijnen\n# geen kop\n- geen lijst\n\n1. ook niet',
        status: ItemStatus.active,
        source: ItemSource.widget,
        projectId: 'verbouwing',
        body: 'Prijzen per raam',
      ),
      Item(
        id: boodschappen,
        rawText: 'Boodschappen',
        status: ItemStatus.done,
        source: ItemSource.app,
      ),
      Item(
        id: kyiv,
        rawText: 'Подзвонити в Київ',
        status: ItemStatus.inbox,
        source: ItemSource.share,
        projectId: 'gone',
      ),
    ],
    projects: [
      const Project(id: 'keuken', name: 'Keuken', parentId: 'verbouwing'),
      const Project(id: 'verbouwing', name: 'Verbouwing'),
      Project(id: 'tuin', name: 'Tuin', archivedAt: DateTime.utc(2026, 9, 1)),
    ],
    people: [
      ExportPerson(
        person: Person(
          id: 'jan',
          name: 'Jan Jansen',
          aliases: const ['jj'],
          birthday: Birthday.tryCreate(3, 5, 1980),
          note: 'Fietst graag',
          organisation: 'Bouwbedrijf',
        ),
      ),
      const ExportPerson(
        person: Person(id: 'jj', name: 'JJ', aliases: []),
        mergedIntoId: 'jan',
      ),
      const ExportPerson(
        person: Person(id: 'olena', name: 'Олена', aliases: []),
      ),
    ],
    contactDetails: const [
      ContactDetail(
        id: 'c2',
        personId: 'jan',
        kind: ContactKind.email,
        value: 'jan@example.org',
        sortOrder: 2,
      ),
      ContactDetail(
        id: 'c1',
        personId: 'jan',
        kind: ContactKind.phone,
        value: '+31 6 12345678',
        label: 'work',
        sortOrder: 1,
      ),
    ],
    links: [
      ExportLink(
        fromItemId: tegels,
        toItemId: kozijnen,
        kind: 'link',
        label: 'x',
      ),
    ],
    completions: [
      ExportCompletion(
        itemId: boodschappen,
        occurrenceOn: LocalDate(2026, 10, 5),
        completedOn: LocalDate(2026, 10, 5),
      ),
    ],
    notes: [
      ExportNote(
        id: 'n1',
        itemId: kozijnen,
        nextStep: 'Drie offertes naast elkaar',
        savedAt: DateTime.utc(2026, 10, 8),
      ),
      ExportNote(
        id: 'n2',
        projectId: 'verbouwing',
        inMind: 'Budget nakijken',
        savedAt: DateTime.utc(2026, 10, 7),
      ),
      ExportNote(
        id: 'n3',
        itemId: boodschappen,
        nextStep: 'Weg',
        savedAt: DateTime.utc(2026, 10, 1),
        resumedAt: DateTime.utc(2026, 10, 2),
      ),
    ],
  );

  group('JSON', () {
    late Map<String, Object?> json;
    setUp(() {
      json =
          jsonDecode(
                exportJson(
                  sample(),
                  exportedAt: exportedAt,
                  appVersion: '0.4.5',
                ),
              )
              as Map<String, Object?>;
    });

    List<Map<String, Object?>> list(String key) =>
        (json[key]! as List).cast<Map<String, Object?>>();

    test('names its format and version', () {
      expect(json['format'], 'offload-export');
      expect(json['version'], 1);
      expect(json['exportedAt'], '2026-10-09T12:30:00.000Z');
      expect(json['appVersion'], '0.4.5');
    });

    test('items in capture order with every field, days as yyyy-mm-dd', () {
      final items = list('items');
      expect(
        [for (final i in items) i['id']],
        [kozijnen, tegels, boodschappen, kyiv],
      );
      final tile = items[1];
      expect(tile['rawText'], 'Tegelzetter mailen !vr *hoog @Jan');
      expect(tile['status'], 'waiting');
      expect(tile['type'], 'task');
      expect(tile['priority'], 'high');
      expect(tile['dueOn'], '2026-10-10');
      expect(tile['expectedOn'], '2026-10-12');
      expect(tile['waitingOnId'], 'jj');
      expect(tile['capturedAt'], '2026-10-02T09:00:00.000Z');
      expect(tile.containsKey('note'), isTrue);
      expect(tile['note'], isNull);
      expect(items[0]['note'], 'Prijzen per raam');
    });

    test('people with birthday, merge and contact details in order', () {
      final jan = list('people').first;
      expect(jan['birthday'], {'day': 3, 'month': 5, 'year': 1980});
      expect(jan['aliases'], ['jj']);
      expect(
        [
          for (final d
              in (jan['contactDetails']! as List).cast<Map<String, Object?>>())
            d['kind'],
        ],
        ['phone', 'email'],
      );
      expect(list('people')[1]['mergedIntoId'], 'jan');
    });

    test('links, completions and every note, resumed ones too', () {
      expect(list('links').single['label'], 'x');
      expect(list('completions').single['occurrenceOn'], '2026-10-05');
      expect(list('whereWasI'), hasLength(3));
      expect(list('whereWasI').last['resumedAt'], '2026-10-02T00:00:00.000Z');
    });

    test('Cyrillic stays as written, not escaped', () {
      final text = exportJson(
        sample(),
        exportedAt: exportedAt,
        appVersion: '0.4.5',
      );
      expect(text, contains('Подзвонити в Київ'));
      expect(text, contains('Олена'));
    });
  });

  group('Markdown', () {
    late String md;
    setUp(() {
      md = exportMarkdown(sample(), _Labels(), exportedAt: exportedAt);
    });

    test('header with the counts; projects, then without project, then '
        'people', () {
      expect(md, startsWith('# Export\n\nMade 2026-10-09T12:30 · 4/3/2\n'));
      final projects = md.indexOf('## Projects');
      final loose = md.indexOf('## Without project');
      final people = md.indexOf('## People');
      expect(projects, greaterThan(0));
      expect(loose, greaterThan(projects));
      expect(people, greaterThan(loose));
    });

    test('by name, sub-projects after their parent, archived ones '
        'marked', () {
      final tuin = md.indexOf('### Tuin (archived)');
      final verbouwing = md.indexOf('### Verbouwing\n');
      final keuken = md.indexOf('### Verbouwing › Keuken');
      expect(tuin, greaterThan(0));
      expect(verbouwing, greaterThan(tuin));
      expect(keuken, greaterThan(verbouwing));
    });

    test('the item as typed, block markers escaped, facts below', () {
      expect(
        md,
        contains(
          '#### Waiting\n\n'
          '- Tegelzetter mailen !vr *hoog @Jan\n\n'
          '  task · due 2026-10-10 · high · waits on Jan Jansen · '
          'expected 2026-10-12 · captured 2026-10-02  \n',
        ),
      );
      expect(
        md,
        contains(
          '- Offerte kozijnen  \n'
          '  \\# geen kop  \n'
          '  \\- geen lijst  \n'
          '\n'
          '  1\\. ook niet\n',
        ),
      );
      expect(md, contains('  > Prijzen per raam\n'));
    });

    test('open notes under their item or project; resumed ones not', () {
      expect(md, contains('  ⏸ next: Drie offertes naast elkaar  \n'));
      expect(md, contains('⏸ in mind: Budget nakijken  \n'));
      expect(md, isNot(contains('Weg')));
    });

    test('completions under the item', () {
      expect(md, contains('  done: 2026-10-05  \n'));
    });

    test('an item of a project not exported counts as without project', () {
      final loose = md.substring(md.indexOf('## Without project'));
      expect(loose, contains('- Подзвонити в Київ'));
      expect(loose, contains('### Done'));
    });

    test('people by name, merged ones left out, details in order', () {
      final people = md.substring(md.indexOf('## People'));
      expect(people, contains('### Jan Jansen'));
      expect(people, contains('### Олена'));
      expect(people, isNot(contains('### JJ')));
      expect(
        people.indexOf('### Jan Jansen'),
        lessThan(people.indexOf('### Олена')),
      );
      expect(
        people,
        contains(
          'aka jj  \nborn 3-5-1980  \nworks Bouwbedrijf/-  \n\n'
          '- phone (work): +31 6 12345678\n'
          '- email: jan@example.org\n',
        ),
      );
      expect(people, contains('> Fietst graag'));
    });

    test('nothing made yet: only the header', () {
      final empty = exportMarkdown(
        const ExportData(
          items: [],
          projects: [],
          people: [],
          contactDetails: [],
          links: [],
          completions: [],
          notes: [],
        ),
        _Labels(),
        exportedAt: exportedAt,
      );
      expect(empty, '# Export\n\nMade 2026-10-09T12:30 · 0/0/0\n');
    });
  });
}

/// Plain labels, so the tests read the structure.
class _Labels implements ExportLabels {
  @override
  String get title => 'Export';
  @override
  String madeOn(DateTime moment) =>
      'Made ${moment.toIso8601String().substring(0, 16)}';
  @override
  String counts(int items, int projects, int people) =>
      '$items/$projects/$people';
  @override
  String get projects => 'Projects';
  @override
  String get withoutProject => 'Without project';
  @override
  String get people => 'People';
  @override
  String get archived => 'archived';
  @override
  String status(ItemStatus status) =>
      '${status.name[0].toUpperCase()}${status.name.substring(1)}';
  @override
  String? type(ItemType? type) => type?.name;
  @override
  String priority(ItemPriority priority) => priority.name;
  @override
  String due(LocalDate day) => 'due $day';
  @override
  String revisit(LocalDate day) => 'back $day';
  @override
  String requester(String name) => 'asked by $name';
  @override
  String waitingOn(String name) => 'waits on $name';
  @override
  String asked(LocalDate day) => 'asked $day';
  @override
  String promise(String text) => 'promised $text';
  @override
  String expected(LocalDate day) => 'expected $day';
  @override
  String captured(DateTime moment) =>
      'captured ${moment.toIso8601String().substring(0, 10)}';
  @override
  String nextStep(String text) => 'next: $text';
  @override
  String inMind(String text) => 'in mind: $text';
  @override
  String completions(List<LocalDate> days) => 'done: ${days.join(', ')}';
  @override
  String aliases(List<String> aliases) => 'aka ${aliases.join(', ')}';
  @override
  String birthday(Birthday birthday) =>
      'born ${birthday.day}-${birthday.month}-${birthday.year}';
  @override
  String work(String? organisation, String? jobTitle) =>
      'works ${organisation ?? '-'}/${jobTitle ?? '-'}';
  @override
  String contact(ContactKind kind, String? label) =>
      label == null ? kind.name : '${kind.name} ($label)';
}
