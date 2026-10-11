import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/projects/drift_project_repository.dart';
import '../../domain/items/item.dart';
import '../../domain/projects/project.dart';
import '../../domain/projects/project_overview.dart';
import '../../domain/projects/project_repository.dart';
import '../../domain/projects/project_tree.dart';
import '../../domain/time/local_date.dart';
import '../inbox/inbox_card.dart';
import '../items/item_providers.dart';
import '../startup/app_storage_provider.dart';

/// The project store of the opened storage (DD-018 point 6).
final projectRepositoryProvider = Provider<ProjectRepository>(
  (ref) => DriftProjectRepository(ref.watch(storageProvider)),
);

/// The live projects, archived ones included, by name.
final projectsProvider = StreamProvider<List<Project>>(
  (ref) => ref.watch(projectRepositoryProvider).watchProjects(),
);

/// The live projects as a tree, for the rules and the lookups by id.
final projectTreeProvider = Provider<ProjectTree>(
  (ref) => ProjectTree(ref.watch(projectsProvider).valueOrNull ?? const []),
);

/// Every live item, for the counts of the project list and the project of
/// a search result; released when no screen needs it.
final liveItemsProvider = StreamProvider.autoDispose<List<Item>>(
  (ref) => ref.watch(itemRepositoryProvider).watchLiveItems(),
);

/// The project id of every live item that has one, by item id.
final itemProjectIdsProvider = Provider.autoDispose<Map<String, String>>(
  (ref) => {
    for (final item in ref.watch(liveItemsProvider).valueOrNull ?? <Item>[])
      item.id: ?item.projectId,
  },
);

/// Open and overdue items per project id; null is *Without project*.
final projectCountsProvider = Provider.autoDispose<Map<String?, ProjectCount>>((
  ref,
) {
  final now = ref.watch(minuteClockProvider).valueOrNull ?? DateTime.now();
  return projectCounts(
    ref.watch(liveItemsProvider).valueOrNull ?? const [],
    ref.watch(projectTreeProvider),
    LocalDate.of(now),
  );
});

/// The items of project [id] (null: *Without project*).
final projectItemsProvider = StreamProvider.autoDispose
    .family<List<Item>, String?>(
      (ref, id) => ref.watch(itemRepositoryProvider).watchProjectItems(id),
    );

/// What the Projects destination shows: the list (null), or one project
/// opened from it. On Windows it replaces the list in the list pane (DD-018
/// point 6, variant A).
class OpenProject {
  const OpenProject(this.id);

  /// The project, or null for *Without project*.
  final String? id;

  @override
  bool operator ==(Object other) => other is OpenProject && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

final openProjectProvider = StateProvider<OpenProject?>((ref) => null);
