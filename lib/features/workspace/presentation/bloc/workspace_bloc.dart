import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/workspace_entity.dart';
import '../../domain/usecases/create_workspace_usecase.dart';
import '../../domain/usecases/delete_workspace_usecase.dart';
import '../../domain/usecases/get_workspaces_usecase.dart';
import 'workspace_event.dart';
import 'workspace_state.dart';

class WorkspaceBloc extends Bloc<WorkspaceEvent, WorkspaceState> {
  final GetWorkspacesUseCase _getWorkspacesUseCase;
  final CreateWorkspaceUseCase _createWorkspaceUseCase;
  final DeleteWorkspaceUseCase _deleteWorkspaceUseCase;

  WorkspaceBloc({
    required GetWorkspacesUseCase getWorkspacesUseCase,
    required CreateWorkspaceUseCase createWorkspaceUseCase,
    required DeleteWorkspaceUseCase deleteWorkspaceUseCase,
  })  : _getWorkspacesUseCase = getWorkspacesUseCase,
        _createWorkspaceUseCase = createWorkspaceUseCase,
        _deleteWorkspaceUseCase = deleteWorkspaceUseCase,
        super(WorkspaceInitial()) {
    on<WorkspacesLoadRequested>(_onWorkspacesLoadRequested);
    on<WorkspaceCreateRequested>(_onWorkspaceCreateRequested);
    on<WorkspaceDeleteRequested>(_onWorkspaceDeleteRequested);
    on<WorkspacesDeleteRequested>(_onWorkspacesDeleteRequested);
  }

  Future<void> _onWorkspacesLoadRequested(WorkspacesLoadRequested event, Emitter<WorkspaceState> emit) async {
    emit(WorkspaceLoading());
    final result = await _getWorkspacesUseCase();
    result.fold(
      (failure) => emit(WorkspaceError(message: failure.message, workspaces: const [])),
      (workspaces) => emit(WorkspaceLoaded(workspaces: workspaces)),
    );
  }

  Future<void> _onWorkspaceCreateRequested(WorkspaceCreateRequested event, Emitter<WorkspaceState> emit) async {
    final current = _currentWorkspaces();
    emit(WorkspaceLoaded(workspaces: current, isMutating: true));

    final result = await _createWorkspaceUseCase(event.name);
    result.fold(
      (failure) => emit(WorkspaceError(message: failure.message, workspaces: current)),
      (newWorkspace) => emit(WorkspaceLoaded(workspaces: [...current, newWorkspace])),
    );
  }

  Future<void> _onWorkspaceDeleteRequested(WorkspaceDeleteRequested event, Emitter<WorkspaceState> emit) async {
    final current = _currentWorkspaces();
    emit(WorkspaceLoaded(workspaces: current, isMutating: true));

    final result = await _deleteWorkspaceUseCase(event.workspaceId);
    result.fold(
      (failure) => emit(WorkspaceError(message: failure.message, workspaces: current)),
      (_) {
        final updated = current.where((w) => w.id != event.workspaceId).toList();
        emit(WorkspaceLoaded(workspaces: updated));
      },
    );
  }

  Future<void> _onWorkspacesDeleteRequested(WorkspacesDeleteRequested event, Emitter<WorkspaceState> emit) async {
    final current = _currentWorkspaces();
    emit(WorkspaceLoaded(workspaces: current, isMutating: true));

    final ids = event.workspaceIds;
    var updated = current;
    String? errorMessage;

    for (final id in ids) {
      final result = await _deleteWorkspaceUseCase(id);
      result.fold(
        (failure) => errorMessage = failure.message,
        (_) => updated = updated.where((w) => w.id != id).toList(),
      );
    }

    if (errorMessage != null) {
      emit(WorkspaceError(message: errorMessage!, workspaces: updated));
    } else {
      emit(WorkspaceLoaded(workspaces: updated));
    }
  }

  List<WorkspaceEntity> _currentWorkspaces() {
    final currentState = state;
    if (currentState is WorkspaceLoaded) return currentState.workspaces;
    if (currentState is WorkspaceError) return currentState.workspaces;
    return [];
  }
}
