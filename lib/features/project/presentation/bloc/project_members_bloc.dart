import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_project_members_usecase.dart';
import 'project_members_event.dart';
import 'project_members_state.dart';

class ProjectMembersBloc extends Bloc<ProjectMembersEvent, ProjectMembersState> {
  final GetProjectMembersUseCase _getProjectMembersUseCase;

  ProjectMembersBloc({required GetProjectMembersUseCase getProjectMembersUseCase})
      : _getProjectMembersUseCase = getProjectMembersUseCase,
        super(ProjectMembersInitial()) {
    on<ProjectMembersLoadRequested>(_onLoadRequested);
  }

  Future<void> _onLoadRequested(
    ProjectMembersLoadRequested event,
    Emitter<ProjectMembersState> emit,
  ) async {
    emit(ProjectMembersLoading());
    final result = await _getProjectMembersUseCase(event.projectId);
    result.fold(
      (failure) => emit(ProjectMembersError(failure.message)),
      (members) => emit(ProjectMembersLoaded(members)),
    );
  }
}
