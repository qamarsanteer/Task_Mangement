import 'package:equatable/equatable.dart';
import '../../../workspace/domain/entities/workspace_entity.dart';
import '../../domain/entities/project_entity.dart';

class ProjectPickerState extends Equatable {
  final bool isLoadingWorkspaces;
  final List<WorkspaceEntity> workspaces;
  final String? selectedWorkspaceId;
  final bool isLoadingProjects;
  final List<ProjectEntity> projectsForSelectedWorkspace;
  final String? selectedProjectId;
  final String? errorMessage;

  const ProjectPickerState({
    this.isLoadingWorkspaces = false,
    this.workspaces = const [],
    this.selectedWorkspaceId,
    this.isLoadingProjects = false,
    this.projectsForSelectedWorkspace = const [],
    this.selectedProjectId,
    this.errorMessage,
  });

  WorkspaceEntity? get selectedWorkspace =>
      workspaces.where((w) => w.id == selectedWorkspaceId).firstOrNull;

  ProjectEntity? get selectedProject =>
      projectsForSelectedWorkspace.where((p) => p.id == selectedProjectId).firstOrNull;

  ProjectPickerState copyWith({
    bool? isLoadingWorkspaces,
    List<WorkspaceEntity>? workspaces,
    String? selectedWorkspaceId,
    bool clearSelectedWorkspaceId = false,
    bool? isLoadingProjects,
    List<ProjectEntity>? projectsForSelectedWorkspace,
    String? selectedProjectId,
    bool clearSelectedProjectId = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProjectPickerState(
      isLoadingWorkspaces: isLoadingWorkspaces ?? this.isLoadingWorkspaces,
      workspaces: workspaces ?? this.workspaces,
      selectedWorkspaceId: clearSelectedWorkspaceId ? null : (selectedWorkspaceId ?? this.selectedWorkspaceId),
      isLoadingProjects: isLoadingProjects ?? this.isLoadingProjects,
      projectsForSelectedWorkspace: projectsForSelectedWorkspace ?? this.projectsForSelectedWorkspace,
      selectedProjectId: clearSelectedProjectId ? null : (selectedProjectId ?? this.selectedProjectId),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        isLoadingWorkspaces,
        workspaces,
        selectedWorkspaceId,
        isLoadingProjects,
        projectsForSelectedWorkspace,
        selectedProjectId,
        errorMessage,
      ];
}