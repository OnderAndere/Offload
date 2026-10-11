import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/help/help_topics.dart';
import '../../domain/ids/uuid_v7.dart';
import '../../domain/search/search_index.dart';
import '../../l10n/app_localizations.dart';
import '../help/help_scope.dart';
import '../items/item_detail_screen.dart';
import '../items/item_providers.dart';
import '../people/people_providers.dart';
import '../people/person_actions.dart';
import '../people/person_look.dart';
import '../projects/project_look.dart';
import '../projects/project_providers.dart';
import 'search_providers.dart';

/// Search over items and people (REQ-011, T2.5 step B): results while
/// typing, best first. Plain on purpose; its design follows in Q5b (PO
/// decision 27-09-2026). Tapping an item opens it (T2.3), tapping a person
/// opens the person (DD-018 point 7).
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const SearchScreen()));

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return HelpScope(
      topic: HelpTopic.search,
      child: Scaffold(
        appBar: AppBar(
          title: TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: l10n.searchHint,
              border: InputBorder.none,
            ),
            onChanged: (query) => setState(() => _query = query),
          ),
          actions: [
            if (_query.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: l10n.searchClear,
                onPressed: _clear,
              ),
            const HelpButton(),
          ],
        ),
        body: SearchResults(query: _query),
      ),
    );
  }
}

/// The results for [query], best first, looked up again on every change;
/// the local index answers fast. Used by the search screen and by the
/// search field above the list on Windows (DD-018 point 5).
class SearchResults extends ConsumerStatefulWidget {
  const SearchResults({super.key, required this.query});

  final String query;

  @override
  ConsumerState<SearchResults> createState() => _SearchResultsState();
}

class _SearchResultsState extends ConsumerState<SearchResults> {
  List<SearchHit>? _hits;
  bool _failed = false;
  int _lookups = 0;

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void didUpdateWidget(SearchResults oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != oldWidget.query) _search();
  }

  /// An answer for older text is dropped.
  Future<void> _search() async {
    final query = widget.query;
    final lookup = ++_lookups;
    if (query.trim().isEmpty) return;
    List<SearchHit>? hits;
    var failed = false;
    try {
      hits = await ref.read(searchIndexProvider).search(query);
    } catch (_) {
      failed = true;
    }
    if (!mounted || lookup != _lookups) return;
    setState(() {
      _hits = hits;
      _failed = failed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final query = widget.query.trim();
    final hits = _hits;
    if (query.isEmpty) return _Message(l10n.searchStart);
    if (_failed) return _Message(l10n.searchFailed);
    if (hits == null) return const SizedBox.shrink();
    if (hits.isEmpty) return _Message(l10n.searchNoResults(query));
    return ListView.builder(
      itemCount: hits.length,
      itemBuilder: (context, index) => _ResultTile(hit: hits[index]),
    );
  }
}

class _ResultTile extends ConsumerWidget {
  const _ResultTile({required this.hit});

  final SearchHit hit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    switch (hit.entity) {
      case SearchEntity.item:
        final captured = uuidV7Time(hit.id).toLocal();
        // The project and the people of the item, as on the cards (DD-018
        // points 6 and 7).
        final projectId = ref.watch(itemProjectIdsProvider)[hit.id];
        final item = ref.watch(liveItemsByIdProvider)[hit.id];
        final chips = <Widget>[
          if (projectId != null &&
              ref.watch(projectTreeProvider)[projectId] != null)
            ProjectChip(projectId: projectId),
          if (item != null)
            ...personRoleChips(
              item,
              named: namedPersonIds(
                ref.watch(liveItemTokensProvider).valueOrNull?[hit.id] ??
                    const [],
                ref.watch(personIdByNameProvider),
              ),
            ),
        ];
        return ListTile(
          leading: Icon(Icons.notes, semanticLabel: l10n.searchKindItem),
          title: Text(
            hit.title ?? hit.text,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.inboxCapturedAt(captured, captured)),
              if (chips.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Wrap(spacing: 6, runSpacing: 4, children: chips),
                ),
            ],
          ),
          onTap: () => ItemDetailScreen.open(context, hit.id),
        );
      case SearchEntity.person:
        return ListTile(
          leading: Icon(
            Icons.person_outline,
            semanticLabel: l10n.searchKindPerson,
          ),
          title: Text(hit.title ?? ''),
          subtitle: hit.text.isEmpty
              ? null
              : Text(hit.text, maxLines: 1, overflow: TextOverflow.ellipsis),
          onTap: () => openPerson(context, ref, hit.id),
        );
    }
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(text, textAlign: TextAlign.center),
    ),
  );
}
