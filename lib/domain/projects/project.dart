/// A project (SPEC section 7, "Context/project"; DD-011, DD-018 point 6):
/// a name, optionally under a top-level project, at most two levels.
class Project {
  const Project({
    required this.id,
    required this.name,
    this.parentId,
    this.archivedAt,
  });

  final String id;
  final String name;

  /// The top-level project this one is under; null at the top level.
  final String? parentId;

  /// When it was archived; null while it is in use.
  final DateTime? archivedAt;

  bool get isArchived => archivedAt != null;
  bool get isTopLevel => parentId == null;

  @override
  bool operator ==(Object other) =>
      other is Project &&
      other.id == id &&
      other.name == name &&
      other.parentId == parentId &&
      other.archivedAt == archivedAt;

  @override
  int get hashCode => Object.hash(id, name, parentId, archivedAt);

  @override
  String toString() => 'Project($name)';
}
