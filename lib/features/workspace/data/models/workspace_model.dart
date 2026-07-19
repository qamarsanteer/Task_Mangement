import '../../domain/entities/workspace_entity.dart';

class WorkspaceModel extends WorkspaceEntity {
  const WorkspaceModel({
    required super.id,
    required super.name,
    super.createdAt,
  });

  factory WorkspaceModel.fromJson(Map<String, dynamic> json) {
    return WorkspaceModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? json['title'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}