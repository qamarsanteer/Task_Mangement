import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/project_entity.dart';
import '../../domain/usecases/create_project_usecase.dart';
import '../../domain/usecases/delete_project_usecase.dart';
import '../../domain/usecases/get_projects_usecase.dart';
import 'project_event.dart';
import 'project_state.dart';

class ProjectBloc extends Bloc<ProjectEvent, ProjectState> {
  final GetProjectsUseCase _getProjectsUseCase;
  final CreateProjectUseCase _createProjectUseCase;
  final DeleteProjectUseCase _deleteProjectUseCase;

  ProjectBloc({
    required GetProjectsUseCase getProjectsUseCase,
    required CreateProjectUseCase createProjectUseCase,
    required DeleteProjectUseCase deleteProjectUseCase,
  })  : _getProjectsUseCase = getProjectsUseCase,
        _createProjectUseCase = createProjectUseCase,
        _deleteProjectUseCase = deleteProjectUseCase,
        super(ProjectInitial()) {
    on<ProjectsLoadRequested>(_onProjectsLoadRequested);
    on<ProjectCreateRequested>(_onProjectCreateRequested);
    on<ProjectDeleteRequested>(_onProjectDeleteRequested);
  }

  Future<void> _onProjectsLoadRequested(ProjectsLoadRequested event, Emitter<ProjectState> emit) async {
    emit(ProjectLoading());
    final result = await _getProjectsUseCase(event.workspaceId);
    result.fold(
      (failure) => emit(ProjectError(message: failure.message, projects: const [])),
      (projects) => emit(ProjectLoaded(projects: projects)),
    );
  }

  Future<void> _onProjectCreateRequested(ProjectCreateRequested event, Emitter<ProjectState> emit) async {
    final current = _currentProjects();
    emit(ProjectLoaded(projects: current, isMutating: true));

    final result = await _createProjectUseCase(workspaceId: event.workspaceId, name: event.name);
    result.fold(
      (failure) => emit(ProjectError(message: failure.message, projects: current)),
      (newProject) => emit(ProjectLoaded(projects: [...current, newProject])),
    );
  }

  Future<void> _onProjectDeleteRequested(ProjectDeleteRequested event, Emitter<ProjectState> emit) async {
    final current = _currentProjects();
    emit(ProjectLoaded(projects: current, isMutating: true));

    final result = await _deleteProjectUseCase(event.projectId);
    result.fold(
      (failure) => emit(ProjectError(message: failure.message, projects: current)),
      (_) {
        final updated = current.where((p) => p.id != event.projectId).toList();
        emit(ProjectLoaded(projects: updated));
      },
    );
  }

  List<ProjectEntity> _currentProjects() {
    final currentState = state;
    if (currentState is ProjectLoaded) return currentState.projects;
    if (currentState is ProjectError) return currentState.projects;
    return [];
  }
}