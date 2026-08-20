class ProjectEntity {
  final String id;
  final String name;
  final String? description;
  final String workspaceId;
  final DateTime? createdAt;

  const ProjectEntity({
    required this.id,
    required this.name,
    this.description,
    required this.workspaceId,
    this.createdAt,
  });
}