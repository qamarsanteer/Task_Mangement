import 'package:equatable/equatable.dart';

abstract class ProjectEvent extends Equatable {
  const ProjectEvent();
  @override
  List<Object?> get props => [];
}

class ProjectsLoadRequested extends ProjectEvent {
  final String workspaceId;
  const ProjectsLoadRequested(this.workspaceId);
  @override
  List<Object?> get props => [workspaceId];
}

class ProjectCreateRequested extends ProjectEvent {
  final String workspaceId;
  final String name;
  const ProjectCreateRequested({required this.workspaceId, required this.name});
  @override
  List<Object?> get props => [workspaceId, name];
}

class ProjectDeleteRequested extends ProjectEvent {
  final String projectId;
  const ProjectDeleteRequested(this.projectId);
  @override
  List<Object?> get props => [projectId];
}