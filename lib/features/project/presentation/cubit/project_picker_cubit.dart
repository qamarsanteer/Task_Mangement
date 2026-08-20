import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../workspace/domain/usecases/get_workspaces_usecase.dart';
import '../../domain/usecases/get_projects_usecase.dart';
import 'project_picker_state.dart';

/// Cubit خفيف بيدير ثلاث خطوات شائعة: تحميل الورك سبيسات، تحميل مشاريع
/// أي ورك سبيس يتم اختياره، وتخزين اختيار المشروع النهائي — كل شي
/// بمكان واحد (الحالة)، بدون أي state محلي موازي بالـ UI.
class ProjectPickerCubit extends Cubit<ProjectPickerState> {
  final GetWorkspacesUseCase _getWorkspacesUseCase;
  final GetProjectsUseCase _getProjectsUseCase;

  ProjectPickerCubit({
    required GetWorkspacesUseCase getWorkspacesUseCase,
    required GetProjectsUseCase getProjectsUseCase,
  })  : _getWorkspacesUseCase = getWorkspacesUseCase,
        _getProjectsUseCase = getProjectsUseCase,
        super(const ProjectPickerState());

  Future<void> loadWorkspaces() async {
    emit(state.copyWith(isLoadingWorkspaces: true, clearError: true));
    final result = await _getWorkspacesUseCase();
    result.fold(
      (failure) => emit(state.copyWith(isLoadingWorkspaces: false, errorMessage: failure.message)),
      (workspaces) => emit(state.copyWith(isLoadingWorkspaces: false, workspaces: workspaces)),
    );
  }

  Future<void> selectWorkspace(String workspaceId) async {
    emit(state.copyWith(
      selectedWorkspaceId: workspaceId,
      isLoadingProjects: true,
      projectsForSelectedWorkspace: const [],
      clearSelectedProjectId: true,
      clearError: true,
    ));
    final result = await _getProjectsUseCase(workspaceId);
    result.fold(
      (failure) => emit(state.copyWith(isLoadingProjects: false, errorMessage: failure.message)),
      (projects) => emit(state.copyWith(isLoadingProjects: false, projectsForSelectedWorkspace: projects)),
    );
  }

  void selectProject(String projectId) {
    emit(state.copyWith(selectedProjectId: projectId));
  }
}