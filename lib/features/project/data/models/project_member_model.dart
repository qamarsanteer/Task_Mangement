import '../../domain/entities/project_member_entity.dart';
import '../../domain/entities/project_member_role.dart';

class ProjectMemberModel extends ProjectMemberEntity {
  const ProjectMemberModel({
    required super.id,
    super.userId,
    required super.email,
    super.fullName,
    super.avatarUrl,
    required super.role,
    required super.status,
    required super.invitedAt,
    super.joinedAt,
  });

  factory ProjectMemberModel.fromJson(Map<String, dynamic> json) {
    return ProjectMemberModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString(),
      email: json['email'] ?? '',
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      role: _roleFromApiValue(json['role']?.toString()),
      status: _statusFromApiValue(json['status']?.toString()),
      invitedAt: DateTime.tryParse(json['invited_at']?.toString() ?? '') ?? DateTime.now(),
      joinedAt: json['joined_at'] != null ? DateTime.tryParse(json['joined_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (userId != null) 'user_id': userId,
      'email': email,
      if (fullName != null) 'full_name': fullName,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      'role': role.apiValue,
      'status': status.name,
      'invited_at': invitedAt.toIso8601String(),
      if (joinedAt != null) 'joined_at': joinedAt!.toIso8601String(),
    };
  }

  static ProjectMemberRole _roleFromApiValue(String? value) {
    switch (value) {
      case 'read_write':
        return ProjectMemberRole.readWrite;
      case 'read_only':
      default:
        return ProjectMemberRole.readOnly;
    }
  }

  static InviteStatus _statusFromApiValue(String? value) {
    switch (value) {
      case 'accepted':
        return InviteStatus.accepted;
      case 'declined':
        return InviteStatus.declined;
      case 'pending':
      default:
        return InviteStatus.pending;
    }
  }
}
