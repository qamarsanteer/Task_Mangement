import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../task/domain/entities/deleted_task_entry.dart';
import '../../domain/entities/deleted_project_entry.dart';
import '../../domain/usecases/delete_project_forever_usecase.dart';
import '../../domain/usecases/delete_task_forever_usecase.dart';
import '../../domain/usecases/get_deleted_projects_usecase.dart';
import '../../domain/usecases/get_deleted_tasks_usecase.dart';
import '../../domain/usecases/restore_project_usecase.dart';
import '../../domain/usecases/restore_task_usecase.dart';
import 'bin_event.dart';
import 'bin_state.dart';

class BinBloc extends Bloc<BinEvent, BinState> {
  final GetDeletedTasksUseCase _getDeletedTasksUseCase;
  final RestoreTaskUseCase _restoreTaskUseCase;
  final DeleteTaskForeverUseCase _deleteTaskForeverUseCase;
  final GetDeletedProjectsUseCase _getDeletedProjectsUseCase;
  final RestoreProjectUseCase _restoreProjectUseCase;
  final DeleteProjectForeverUseCase _deleteProjectForeverUseCase;

  BinBloc({
    required GetDeletedTasksUseCase getDeletedTasksUseCase,
    required RestoreTaskUseCase restoreTaskUseCase,
    required DeleteTaskForeverUseCase deleteTaskForeverUseCase,
    required GetDeletedProjectsUseCase getDeletedProjectsUseCase,
    required RestoreProjectUseCase restoreProjectUseCase,
    required DeleteProjectForeverUseCase deleteProjectForeverUseCase,
  })  : _getDeletedTasksUseCase = getDeletedTasksUseCase,
        _restoreTaskUseCase = restoreTaskUseCase,
        _deleteTaskForeverUseCase = deleteTaskForeverUseCase,
        _getDeletedProjectsUseCase = getDeletedProjectsUseCase,
        _restoreProjectUseCase = restoreProjectUseCase,
        _deleteProjectForeverUseCase = deleteProjectForeverUseCase,
        super(BinInitial()) {
    on<LoadDeletedTasks>(_onLoadDeletedTasks);
    on<RestoreTask>(_onRestoreTask);
    on<DeleteTaskForever>(_onDeleteTaskForever);
    on<LoadDeletedProjects>(_onLoadDeletedProjects);
    on<RestoreProject>(_onRestoreProject);
    on<DeleteProjectForever>(_onDeleteProjectForever);
  }

  Future<void> _onLoadDeletedTasks(LoadDeletedTasks event, Emitter<BinState> emit) async {
    emit(BinLoading());
    final result = await _getDeletedTasksUseCase();
    result.fold(
      (failure) => emit(BinError(message: failure.message, taskEntries: const [], projectEntries: const [])),
      (entries) => emit(BinLoaded(taskEntries: entries, selectedTab: 0)),
    );
  }

  Future<void> _onRestoreTask(RestoreTask event, Emitter<BinState> emit) async {
    final current = _currentState();
    emit(BinLoaded(taskEntries: current.taskEntries, projectEntries: current.projectEntries, isMutating: true, selectedTab: current.selectedTab));
    final result = await _restoreTaskUseCase(event.taskId);
    result.fold(
      (failure) => emit(BinError(message: failure.message, taskEntries: current.taskEntries, projectEntries: current.projectEntries, selectedTab: current.selectedTab)),
      (_) {
        final updated = current.taskEntries.where((e) => e.taskId != event.taskId).toList();
        emit(BinLoaded(taskEntries: updated, projectEntries: current.projectEntries, selectedTab: current.selectedTab));
      },
    );
  }

  Future<void> _onDeleteTaskForever(DeleteTaskForever event, Emitter<BinState> emit) async {
    final current = _currentState();
    emit(BinLoaded(taskEntries: current.taskEntries, projectEntries: current.projectEntries, isMutating: true, selectedTab: current.selectedTab));
    final result = await _deleteTaskForeverUseCase(event.taskId);
    result.fold(
      (failure) => emit(BinError(message: failure.message, taskEntries: current.taskEntries, projectEntries: current.projectEntries, selectedTab: current.selectedTab)),
      (_) {
        final updated = current.taskEntries.where((e) => e.taskId != event.taskId).toList();
        emit(BinLoaded(taskEntries: updated, projectEntries: current.projectEntries, selectedTab: current.selectedTab));
      },
    );
  }

  Future<void> _onLoadDeletedProjects(LoadDeletedProjects event, Emitter<BinState> emit) async {
    emit(BinLoading());
    final result = await _getDeletedProjectsUseCase();
    result.fold(
      (failure) => emit(BinError(message: failure.message, taskEntries: const [], projectEntries: const [])),
      (entries) => emit(BinLoaded(taskEntries: const [], projectEntries: entries, selectedTab: 1)),
    );
  }

  Future<void> _onRestoreProject(RestoreProject event, Emitter<BinState> emit) async {
    final current = _currentState();
    emit(BinLoaded(
      taskEntries: current.taskEntries,
      projectEntries: current.projectEntries,
      isMutating: true,
      selectedTab: current.selectedTab,
    ));

    final result = await _restoreProjectUseCase(event.projectId);
    result.fold(
      (failure) => emit(BinError(
        message: failure.message,
        taskEntries: current.taskEntries,
        projectEntries: current.projectEntries,
        selectedTab: current.selectedTab,
      )),
      (project) {  // ← استقبل ProjectEntity
        final updated = current.projectEntries.where((e) => e.projectId != event.projectId).toList();
        emit(BinLoaded(
          taskEntries: current.taskEntries,
          projectEntries: updated,
          selectedTab: current.selectedTab,
        ));
      },
    );
  }

  Future<void> _onDeleteProjectForever(DeleteProjectForever event, Emitter<BinState> emit) async {
    final current = _currentState();
    emit(BinLoaded(taskEntries: current.taskEntries, projectEntries: current.projectEntries, isMutating: true, selectedTab: current.selectedTab));
    final result = await _deleteProjectForeverUseCase(event.projectId);
    result.fold(
      (failure) => emit(BinError(message: failure.message, taskEntries: current.taskEntries, projectEntries: current.projectEntries, selectedTab: current.selectedTab)),
      (_) {
        final updated = current.projectEntries.where((e) => e.projectId != event.projectId).toList();
        emit(BinLoaded(taskEntries: current.taskEntries, projectEntries: updated, selectedTab: current.selectedTab));
      },
    );
  }

  _BinCurrent _currentState() {
    final s = state;
    if (s is BinLoaded) return _BinCurrent(s.taskEntries, s.projectEntries, s.selectedTab);
    if (s is BinError) return _BinCurrent(s.taskEntries, s.projectEntries, s.selectedTab);
    return _BinCurrent(const [], const [], 0);
  }
}

class _BinCurrent {
  final List<DeletedTaskEntry> taskEntries;
  final List<DeletedProjectEntry> projectEntries;
  final int selectedTab;
  _BinCurrent(this.taskEntries, this.projectEntries, this.selectedTab);
}