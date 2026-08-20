import 'package:equatable/equatable.dart';
import '../../domain/entities/project_member_entity.dart';

abstract class ProjectMembersState extends Equatable {
  const ProjectMembersState();
  @override
  List<Object?> get props => [];
}

class ProjectMembersInitial extends ProjectMembersState {}

class ProjectMembersLoading extends ProjectMembersState {}

class ProjectMembersLoaded extends ProjectMembersState {
  final List<ProjectMemberEntity> members;
  const ProjectMembersLoaded(this.members);
  @override
  List<Object?> get props => [members];
}

class ProjectMembersError extends ProjectMembersState {
  final String message;
  const ProjectMembersError(this.message);
  @override
  List<Object?> get props => [message];
}
