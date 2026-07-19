import '../../domain/entities/project_entity.dart';

class ProjectModel extends ProjectEntity {
  const ProjectModel({
    required super.id,
    required super.name,
    required super.workspaceId,
    super.createdAt,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? json['title'] ?? '',
      workspaceId: json['workspace_id']?.toString() ?? json['workspaceId']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'workspace_id': workspaceId,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}