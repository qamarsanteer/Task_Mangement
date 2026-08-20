import 'package:equatable/equatable.dart';
import '../../domain/entities/project_member_role.dart';

abstract class ProjectInviteEvent extends Equatable {
  const ProjectInviteEvent();
  @override
  List<Object?> get props => [];
}

class ProjectInviteMemberRequested extends ProjectInviteEvent {
  final String projectId;
  final String email;
  final ProjectMemberRole role;

  const ProjectInviteMemberRequested({
    required this.projectId,
    required this.email,
    required this.role,
  });

  @override
  List<Object?> get props => [projectId, email, role];
}

class ProjectInviteReset extends ProjectInviteEvent {}