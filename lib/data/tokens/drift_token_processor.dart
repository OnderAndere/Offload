import 'dart:async';

import 'package:drift/drift.dart';

import '../../domain/ids/uuid_v7.dart';
import '../../domain/items/item_enums.dart';
import '../../domain/items/item_headline.dart';
import '../../domain/links/item_link.dart';
import '../../domain/projects/project.dart';
import '../../domain/projects/project_token.dart';
import '../../domain/repeats/repeat.dart';
import '../../domain/search/search_index.dart';
import '../../domain/sync/change_operation.dart';
import '../../domain/sync/hlc.dart';
import '../../domain/time/local_date.dart';
import '../../domain/tokens/inline_token.dart';
import '../../domain/tokens/inline_token_registry.dart';
import '../../domain/tokens/token_processing.dart';
import '../../domain/tokens/token_types.dart';
import '../database/app_database.dart';
import '../links/drift_item_link_repository.dart';
import '../people/drift_people_repository.dart';
import '../repeats/drift_completions.dart';
import '../search/drift_search_index.dart';
import '../storage/app_storage.dart';
import '../sync/change_log_format.dart';

/// [ItemTokenProcessor] on the encrypted Drift database (T2.2 step B,
/// DD-004, DD-015).
///
/// - Relative dates count from the moment the date entered the text, not
///   from the moment of processing: `!morgen` captured in the widget
///   yesterday is today. For text as captured that is the capture moment
///   (the item's UUIDv7); a date typed later in the item detail counts from
///   that edit, read from the synchronised change log (DD-018 point 1).
/// - Persons and tags are matched on name (and alias) with [nameKey];
///   unknown ones are created through the change log. All work runs one
///   item at a time, and a person is looked up and created in one
///   transaction ([DriftPeopleRepository]), so two captures with the same
///   new `@Jan`, or a capture and triage, create one person.
/// - Tokens are derived data: replaced per item, without HLC or change log
///   (DD-003). The deadline follows the text: the first date sets `due_at`,
///   and no date clears it (DD-018 point 1). The priority does the same
///   with the first `*` token.
/// - A `^project` sets the project only when it entered the text after the
///   project was last chosen ([projectTokenApplies], DD-004 point 11); a
///   name of no project in use sets nothing and creates nothing.
/// - A repeat word (`!wekelijks`, DD-004 point 14) makes the date that of
///   the series: from its first time ([repeatAnchor]) and the completed
///   times ([repeatDue]), read in the transaction, so a completion made
///   while this runs is never overwritten with an old date. The first time
///   is stored with the token (`1W@2026-09-08`).
class DriftTokenProcessor implements ItemTokenProcessor {
  DriftTokenProcessor(
    this._storage, {
    required this.registry,
    required this.dates,
    this.priorities = _digitsOnly,
    this.repeats = RepeatVocabulary.none,
  });

  static PriorityVocabulary _digitsOnly() => PriorityVocabulary.digitsOnly;

  final AppStorage _storage;
  late final _people = DriftPeopleRepository(_storage);
  final InlineTokenRegistry registry;

  /// The date words of the active UI language at the time of processing.
  final DateVocabulary Function() dates;

  /// The priority words of that language.
  final PriorityVocabulary Function() priorities;

  /// The repeat words of every app language (DD-004 point 14).
  final RepeatVocabulary repeats;
  final _ids = UuidV7Generator();
  Future<void> _queue = Future.value();

  AppDatabase get _db => _storage.database;

  @override
  Future<void> process(String itemId) => _serial(() => _process(itemId));

  @override
  Future<void> processOutdated() => _serial(() async {
    // An item needs work when its tokens come from an older parser version,
    // or when they no longer match its text: an edit whose processing was
    // interrupted (review T2.3 step A). Parsing is pure and cheap, so every
    // live item is compared; plain text without tokens costs no writes.
    // So is a `^project` that named no project when it was processed but
    // names one now (created, or back from the archive): a word that named
    // no project counts as never applied (DD-004 point 11).
    final rows = await _db
        .customSelect(
          'SELECT i.id, i.raw_text, '
          '(SELECT COUNT(*) FROM tokens t WHERE t.item_id = i.id '
          'AND t.parser_version <> ?) AS outdated, '
          '(SELECT group_concat(t.token_type || char(31) || t.raw_value, '
          'char(30)) FROM tokens t WHERE t.item_id = i.id) AS stored, '
          '(SELECT group_concat(t.raw_value, char(30)) FROM tokens t '
          'WHERE t.item_id = i.id AND t.token_type = ? '
          'AND t.resolved_value IS NULL) AS unresolved_projects '
          'FROM items i WHERE i.deleted_at IS NULL',
          variables: [
            Variable<int>(tokenParserVersion),
            Variable<String>(const ProjectTokenType().id),
          ],
          readsFrom: {_db.items, _db.tokens},
        )
        .get();
    List<Project>? projects;
    for (final (index, row) in rows.indexed) {
      // A breath for the UI now and then: this runs right after start.
      if (index % 50 == 49) await Future<void>.delayed(Duration.zero);
      final id = row.read<String>('id');
      try {
        final stored = row.read<String?>('stored');
        final storedKeys = stored == null
            ? const <String>{}
            : stored.split(_recordSeparator).toSet();
        final parsedKeys = {
          for (final match in _parse(id, row.read<String>('raw_text')))
            '${match.type.id}$_unitSeparator${match.word}',
        };
        final upToDate =
            row.read<int>('outdated') == 0 &&
            storedKeys.length == parsedKeys.length &&
            storedKeys.containsAll(parsedKeys);
        final unresolved = row.read<String?>('unresolved_projects');
        var nowNamed = false;
        if (upToDate && unresolved != null) {
          projects ??= await _projects();
          nowNamed = unresolved
              .split(_recordSeparator)
              .any((word) => projectForWord(word, projects!) != null);
        }
        if (upToDate && !nowNamed) continue;
        await _process(id);
      } catch (_) {
        // One item that fails never blocks the others; it is tried again
        // at the next start.
      }
    }
  });

  static final _unitSeparator = String.fromCharCode(31);
  static final _recordSeparator = String.fromCharCode(30);

  /// Runs [work] after everything queued before it, and keeps the queue
  /// going when it fails.
  Future<void> _serial(Future<void> Function() work) {
    final next = _queue.then((_) => work());
    _queue = next.catchError((Object _) {});
    return next;
  }

  List<TokenMatch> _parse(String itemId, String rawText) => registry.parse(
    rawText,
    ParseContext(
      today: LocalDate.of(uuidV7Time(itemId).toLocal()),
      dates: dates(),
      priorities: priorities(),
      repeats: repeats,
    ),
  );

  Future<void> _process(String itemId) async {
    final item = await (_db.select(
      _db.items,
    )..where((i) => i.id.equals(itemId))).getSingleOrNull();
    if (item == null || item.deletedAt != null) return;

    final rows = <TokensCompanion>[];
    LocalDate? firstDate;
    ItemPriority? firstPriority;
    // Project tokens that name a project, in text order; which one (if any)
    // sets the project is decided inside the transaction below.
    final projectTokens = <({TokenMatch match, String projectId})>[];
    _History? history;
    List<Project>? projects;
    // Links are resolved inside the transaction below (DD-004 point 13).
    final linkTokens = <TokenMatch>[];
    // Repeat words too: the first sets the series, read with its records.
    final repeatTokens = <TokenMatch>[];
    for (final parsed in _parse(item.id, item.rawText)) {
      var match = parsed;
      if (match.type is LinkTokenType) {
        linkTokens.add(match);
        continue;
      }
      if (match.type is RepeatTokenType) {
        repeatTokens.add(match);
        continue;
      }
      if (match.type is DateTokenType) {
        history ??= await _history(item.id);
        match = _resolveDateAt(item.id, match, history.versions);
      }
      final String? resolved;
      switch (match.type) {
        case PersonTokenType():
          resolved = await _personId(match.word);
        case TagTokenType():
          resolved = await _tagId(match.word);
        case DateTokenType():
          final date = match.value as LocalDate;
          firstDate ??= date;
          resolved = date.toString();
        case ProjectTokenType():
          projects ??= await _projects();
          resolved = projectForWord(match.word, projects);
          if (resolved != null) {
            projectTokens.add((match: match, projectId: resolved));
          }
        case PriorityTokenType():
          final level = match.value as ItemPriority;
          firstPriority ??= level;
          resolved = level.name;
        default:
          resolved = null;
      }
      rows.add(
        TokensCompanion.insert(
          id: _ids.next(),
          itemId: item.id,
          tokenType: match.type.id,
          rawValue: match.word,
          resolvedValue: Value(resolved),
          parserVersion: tokenParserVersion,
        ),
      );
    }

    // The day the first repeat word entered the text: the first time of a
    // series without a date token and without completed times.
    LocalDate? repeatEntered;
    if (repeatTokens.isNotEmpty) {
      history ??= await _history(item.id);
      repeatEntered = LocalDate.of(
        dateTokenAnchor(
          history.versions,
          (text) => _contains(item.id, text, repeatTokens.first),
          fallback: uuidV7Time(item.id),
        ).toLocal(),
      );
    }

    // Tokens and deadline together: the tokens mark the item as done, so
    // a deadline that failed to be written must not leave tokens behind.
    await _db.transaction(() async {
      final current = await (_db.select(
        _db.items,
      )..where((i) => i.id.equals(itemId))).getSingleOrNull();
      if (current == null || current.deletedAt != null) return;
      // Edited while this ran: the processing queued by that edit does the
      // work, so links chosen with the new text are never removed here.
      if (current.rawText != item.rawText) return;
      await (_db.delete(
        _db.tokens,
      )..where((t) => t.itemId.equals(itemId))).go();
      final linkRows = await _resolveLinks(itemId, linkTokens);
      // A repeating item's date is that of its series (DD-004 point 14).
      var dueDate = firstDate;
      final repeatRows = <TokensCompanion>[];
      for (final (index, token) in repeatTokens.indexed) {
        String? value;
        if (index == 0) {
          final records = await _db.liveCompletions(itemId);
          final rhythm = token.value as Rhythm;
          final anchor = repeatAnchor(
            dateToken: firstDate,
            records: records,
            entered: repeatEntered!,
          );
          dueDate = repeatDue(anchor, rhythm, records);
          value = ItemRepeat(rhythm, anchor).encode();
        }
        repeatRows.add(
          TokensCompanion.insert(
            id: _ids.next(),
            itemId: itemId,
            tokenType: token.type.id,
            rawValue: token.word,
            resolvedValue: Value(value),
            parserVersion: tokenParserVersion,
          ),
        );
      }
      await _db.batch(
        (batch) =>
            batch.insertAll(_db.tokens, [...rows, ...linkRows, ...repeatRows]),
      );
      // The project: the first token that entered the text after the last
      // choice. Read here, in the transaction, so a choice made in the
      // picker while this item was processed is never overwritten.
      String? newProject;
      if (projectTokens.isNotEmpty) {
        final now = await _history(itemId);
        for (final token in projectTokens) {
          final start = tokenRunStart(
            now.versions,
            (text) => _contains(itemId, text, token.match),
          );
          final entered = start == null ? -1 : now.positions[start];
          if (projectTokenApplies(entered, now.lastProjectChoice)) {
            newProject = token.projectId;
            break;
          }
        }
      }
      // Deadline and priority follow the text (DD-018 point 1); unchanged
      // values write nothing.
      await _storage.writer.update(
        _db.items,
        itemId,
        ItemsCompanion(
          dueAt: Value(dueDate == null ? null : dateOnlyToStored(dueDate)),
          priority: Value(firstPriority),
          contextId: newProject == null
              ? const Value.absent()
              : Value(newProject),
        ),
      );
    });
  }

  /// The tokens of the links `[[…]]` of item [itemId], and its links made
  /// to follow the text (DD-004 point 13): a link whose label left the text
  /// is removed; a label without a link gets back the link removed last
  /// with that label, so a bracket broken for a moment keeps the choice, or
  /// else a link to the one other live item with that title. Runs in the
  /// transaction of the tokens, which mark the item as processed.
  Future<List<TokensCompanion>> _resolveLinks(
    String itemId,
    List<TokenMatch> tokens,
  ) async {
    final live = await _links.liveLinksFrom(itemId);
    if (tokens.isEmpty && live.isEmpty) return const [];
    final keys = {for (final t in tokens) linkKey(t.word)};
    final targets = <String, String>{};
    for (final link in live) {
      final key = linkKey(link.label ?? '');
      if (keys.contains(key)) {
        // The oldest link of a label counts (lowest HLC, then id).
        targets.putIfAbsent(key, () => link.toItemId);
      } else {
        await _storage.writer.delete(_db.itemLinks, link.id);
      }
    }
    List<ItemLink>? removed;
    final rows = <TokensCompanion>[];
    for (final token in tokens) {
      final key = linkKey(token.word);
      var target = targets[key];
      if (target == null) {
        removed ??= await _links.removedLinksFrom(itemId);
        final back = removed
            .where((l) => linkKey(l.label ?? '') == key)
            .firstOrNull;
        if (back != null) {
          await _storage.writer.restore(_db.itemLinks, back.id);
          target = back.toItemId;
        }
      }
      if (target == null && !token.word.trim().endsWith('…')) {
        target = await _onlyItemTitled(itemId, token.word);
        if (target != null) {
          await _links.writeChosen(itemId, target, token.word);
        }
      }
      if (target != null) targets[key] = target;
      rows.add(
        TokensCompanion.insert(
          id: _ids.next(),
          itemId: itemId,
          tokenType: token.type.id,
          rawValue: token.word,
          resolvedValue: Value(target),
          parserVersion: tokenParserVersion,
        ),
      );
    }
    return rows;
  }

  late final _links = DriftItemLinkRepository(_storage);

  /// The one live item other than [itemId] whose title is [label] (by
  /// [linkKey]), or null when none or several are. The search index narrows
  /// the candidates, so this never reads every item (DD-004 point 13).
  Future<String?> _onlyItemTitled(String itemId, String label) async {
    final key = linkKey(label);
    const limit = 50;
    final hits = await DriftSearchIndex(_db).search(label, limit: limit);
    // A cut list could hide a second item with this title.
    if (hits.length == limit) return null;
    final ids = [
      for (final hit in hits)
        if (hit.entity == SearchEntity.item && hit.id != itemId) hit.id,
    ];
    if (ids.isEmpty) return null;
    final rows = await (_db.select(
      _db.items,
    )..where((i) => i.id.isIn(ids) & i.deletedAt.isNull())).get();
    final titled = [
      for (final row in rows)
        if (linkKey(_title(row)) == key) row.id,
    ];
    return titled.length == 1 ? titled.single : null;
  }

  /// The title of [row] as lists show it (DD-018 point 2).
  String _title(Item row) => itemHeadline(
    row.rawText,
    registry,
    ParseContext(
      today: LocalDate.of(uuidV7Time(row.id).toLocal()),
      dates: dates(),
      priorities: priorities(),
      repeats: repeats,
    ),
  ).title;

  /// The live projects; [projectForWord] leaves the archived ones out.
  Future<List<Project>> _projects() async {
    final rows = await (_db.select(
      _db.contexts,
    )..where((c) => c.deletedAt.isNull())).get();
    return [
      for (final row in rows)
        Project(
          id: row.id,
          name: row.name,
          parentId: row.parentId,
          archivedAt: row.archivedAt,
        ),
    ];
  }

  /// The history of the item from the change log, in HLC order: the saved
  /// versions of its text, oldest first (the capture at the capture moment,
  /// which for a widget capture is earlier than its import, and every edit
  /// at its HLC time), with their positions in that order, and the position
  /// of the last change of its project (DD-004 point 11).
  Future<_History> _history(String itemId) async {
    final entries =
        await (_db.select(_db.changeLog)
              ..where(
                (e) =>
                    e.entity.equals(_db.items.actualTableName) &
                    e.entityId.equals(itemId),
              )
              ..orderBy([(e) => OrderingTerm.asc(e.hlc)]))
            .get();
    final versions = <TextVersion>[];
    final positions = <int>[];
    int? lastProjectChoice;
    for (final (position, entry) in entries.indexed) {
      final payload = decodePayload(entry.payload);
      final insert = entry.operation == ChangeOperation.insert;
      final at = insert
          ? uuidV7Time(itemId)
          : DateTime.fromMillisecondsSinceEpoch(
              Hlc.parse(entry.hlc).millis,
              isUtc: true,
            );
      if (payload['raw_text'] case final String text) {
        versions.add((savedAt: at, rawText: text));
        positions.add(position);
      }
      // A capture sets no project; every later change of it is a choice.
      if (!insert && payload.containsKey(_db.items.contextId.name)) {
        lastProjectChoice = position;
      }
    }
    return (
      versions: versions,
      positions: positions,
      lastProjectChoice: lastProjectChoice,
    );
  }

  /// Whether [text] holds the same token as [match].
  bool _contains(String itemId, String text, TokenMatch match) => _parse(
    itemId,
    text,
  ).any((m) => m.type.id == match.type.id && m.word == match.word);

  /// [match] resolved from the moment its date entered the text.
  TokenMatch _resolveDateAt(
    String itemId,
    TokenMatch match,
    List<TextVersion> versions,
  ) {
    final anchor = dateTokenAnchor(
      versions,
      (text) => _contains(itemId, text, match),
      fallback: uuidV7Time(itemId),
    );
    final value = match.type.parse(
      match.word,
      ParseContext(
        today: LocalDate.of(anchor.toLocal()),
        dates: dates(),
        priorities: priorities(),
        repeats: repeats,
      ),
    );
    return value == null
        ? match
        : TokenMatch(
            type: match.type,
            start: match.start,
            end: match.end,
            word: match.word,
            value: value,
          );
  }

  /// The live person called [name], by name or alias; created when none.
  Future<String> _personId(String name) => _people.idFor(name);

  /// The live tag called [name]; created when none.
  Future<String> _tagId(String name) async {
    final key = nameKey(name);
    final tags = await (_db.select(
      _db.tags,
    )..where((t) => t.deletedAt.isNull())).get();
    for (final tag in tags) {
      if (nameKey(tag.name) == key) return tag.id;
    }
    return _storage.writer.insert(_db.tags, TagsCompanion(name: Value(name)));
  }
}

/// [positions] holds the change-log position of each of [versions].
typedef _History = ({
  List<TextVersion> versions,
  List<int> positions,
  int? lastProjectChoice,
});
