import 'package:equatable/equatable.dart';
import '../../../workspace/domain/entities/workspace_entity.dart';
import '../../domain/entities/project_entity.dart';

/// حالة اختيار "workspace ثم مشروع منه" — مستخدمة بأي ديالوج بيحتاج
/// المستخدم يختار وجهة (مثلاً: نقل تاسك). حالة واحدة بدل subclasses
/// لأنها أقرب لنموذج (form state) فيه كذا حقل مستقل، مش آلة حالات خطية.
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

  /// الـ workspace/project المختارين حالياً كـ entities كاملة، لسهولة
  /// الاستخدام بالـ UI (بدل ما تدور عليهم بالـ id كل مرة).
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