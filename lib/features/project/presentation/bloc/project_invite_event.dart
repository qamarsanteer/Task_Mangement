import 'package:equatable/equatable.dart';

abstract class ProjectInviteEvent extends Equatable {
  const ProjectInviteEvent();
  @override
  List<Object?> get props => [];
}

class ProjectInviteMemberRequested extends ProjectInviteEvent {
  final String projectId;
  final String email;

  const ProjectInviteMemberRequested({
    required this.projectId,
    required this.email,
  });

  @override
  List<Object?> get props => [projectId, email];
}

class ProjectInviteReset extends ProjectInviteEvent {}