class WorkspaceEntity {
  final String id;
  final String name;
  final DateTime? createdAt;

  const WorkspaceEntity({
    required this.id,
    required this.name,
    this.createdAt,
  });
}