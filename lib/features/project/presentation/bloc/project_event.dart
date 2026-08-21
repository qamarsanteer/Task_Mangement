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
  final String? description;
  const ProjectCreateRequested({required this.workspaceId, required this.name, this.description});
  @override
  List<Object?> get props => [workspaceId, name, description];
}

class ProjectDeleteRequested extends ProjectEvent {
  final String projectId;
  final String workspaceId;
  final String workspaceName;
  const ProjectDeleteRequested(
    this.projectId, {
    required this.workspaceId,
    required this.workspaceName,
  });
  @override
  List<Object?> get props => [projectId, workspaceId, workspaceName];
}

class ProjectsDeleteRequested extends ProjectEvent {
  final List<String> projectIds;
  final String workspaceId;
  final String workspaceName;
  const ProjectsDeleteRequested(
    this.projectIds, {
    required this.workspaceId,
    required this.workspaceName,
  });
  @override
  List<Object?> get props => [projectIds, workspaceId, workspaceName];
}