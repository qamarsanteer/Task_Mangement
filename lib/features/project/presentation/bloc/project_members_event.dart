import 'package:equatable/equatable.dart';

abstract class ProjectMembersEvent extends Equatable {
  const ProjectMembersEvent();
  @override
  List<Object?> get props => [];
}

class ProjectMembersLoadRequested extends ProjectMembersEvent {
  final String projectId;
  const ProjectMembersLoadRequested(this.projectId);
  @override
  List<Object?> get props => [projectId];
}
