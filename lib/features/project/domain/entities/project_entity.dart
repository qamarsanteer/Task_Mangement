class ProjectEntity {
  final String id;
  final String name;
  final String workspaceId;
  final DateTime? createdAt;

  const ProjectEntity({
    required this.id,
    required this.name,
    required this.workspaceId,
    this.createdAt,
  });
}