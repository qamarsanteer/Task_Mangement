import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../task/domain/entities/deleted_task_entry.dart';
import '../../domain/usecases/delete_task_forever_usecase.dart';
import '../../domain/usecases/get_deleted_tasks_usecase.dart';
import '../../domain/usecases/restore_task_usecase.dart';
import 'bin_event.dart';
import 'bin_state.dart';

class BinBloc extends Bloc<BinEvent, BinState> {
  final GetDeletedTasksUseCase _getDeletedTasksUseCase;
  final RestoreTaskUseCase _restoreTaskUseCase;
  final DeleteTaskForeverUseCase _deleteTaskForeverUseCase;

  BinBloc({
    required GetDeletedTasksUseCase getDeletedTasksUseCase,
    required RestoreTaskUseCase restoreTaskUseCase,
    required DeleteTaskForeverUseCase deleteTaskForeverUseCase,
  })  : _getDeletedTasksUseCase = getDeletedTasksUseCase,
        _restoreTaskUseCase = restoreTaskUseCase,
        _deleteTaskForeverUseCase = deleteTaskForeverUseCase,
        super(BinInitial()) {
    on<LoadDeletedTasks>(_onLoadDeletedTasks);
    on<RestoreTask>(_onRestoreTask);
    on<DeleteTaskForever>(_onDeleteTaskForever);
  }

  Future<void> _onLoadDeletedTasks(LoadDeletedTasks event, Emitter<BinState> emit) async {
    emit(BinLoading());
    final result = await _getDeletedTasksUseCase();
    result.fold(
      (failure) => emit(BinError(message: failure.message, entries: const [])),
      (entries) => emit(BinLoaded(entries: entries)),
    );
  }

  Future<void> _onRestoreTask(RestoreTask event, Emitter<BinState> emit) async {
    final current = _currentEntries();
    emit(BinLoaded(entries: current, isMutating: true));

    final result = await _restoreTaskUseCase(event.taskId);
    result.fold(
      (failure) => emit(BinError(message: failure.message, entries: current)),
      (_) {
        final updated = current.where((e) => e.taskId != event.taskId).toList();
        emit(BinLoaded(entries: updated));
      },
    );
  }

  Future<void> _onDeleteTaskForever(DeleteTaskForever event, Emitter<BinState> emit) async {
    final current = _currentEntries();
    emit(BinLoaded(entries: current, isMutating: true));

    final result = await _deleteTaskForeverUseCase(event.taskId);
    result.fold(
      (failure) => emit(BinError(message: failure.message, entries: current)),
      (_) {
        final updated = current.where((e) => e.taskId != event.taskId).toList();
        emit(BinLoaded(entries: updated));
      },
    );
  }

  List<DeletedTaskEntry> _currentEntries() {
    final currentState = state;
    if (currentState is BinLoaded) return currentState.entries;
    if (currentState is BinError) return currentState.entries;
    return [];
  }
}
