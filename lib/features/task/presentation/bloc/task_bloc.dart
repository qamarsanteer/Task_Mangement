import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/usecases/create_task_usecase.dart';
import '../../domain/usecases/delete_task_usecase.dart';
import '../../domain/usecases/get_tasks_usecase.dart';
import '../../domain/usecases/move_task_to_project_usecase.dart';
import '../../domain/usecases/remove_task_attachment_usecase.dart';
import '../../domain/usecases/update_task_status_usecase.dart';
import '../../domain/usecases/update_task_usecase.dart';
import '../../domain/usecases/upload_task_attachments_usecase.dart';
import 'task_event.dart';
import 'task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final GetTasksUseCase _getTasksUseCase;
  final CreateTaskUseCase _createTaskUseCase;
  final UpdateTaskStatusUseCase _updateTaskStatusUseCase;
  final UpdateTaskUseCase _updateTaskUseCase;
  final UploadTaskAttachmentsUseCase _uploadTaskAttachmentsUseCase;
  final RemoveTaskAttachmentUseCase _removeTaskAttachmentUseCase;
  final DeleteTaskUseCase _deleteTaskUseCase;
  final MoveTaskToProjectUseCase _moveTaskToProjectUseCase;

  TaskBloc({
    required GetTasksUseCase getTasksUseCase,
    required CreateTaskUseCase createTaskUseCase,
    required UpdateTaskStatusUseCase updateTaskStatusUseCase,
    required UpdateTaskUseCase updateTaskUseCase,
    required UploadTaskAttachmentsUseCase uploadTaskAttachmentsUseCase,
    required RemoveTaskAttachmentUseCase removeTaskAttachmentUseCase,
    required DeleteTaskUseCase deleteTaskUseCase,
    required MoveTaskToProjectUseCase moveTaskToProjectUseCase,
  })  : _getTasksUseCase = getTasksUseCase,
        _createTaskUseCase = createTaskUseCase,
        _updateTaskStatusUseCase = updateTaskStatusUseCase,
        _updateTaskUseCase = updateTaskUseCase,
        _uploadTaskAttachmentsUseCase = uploadTaskAttachmentsUseCase,
        _removeTaskAttachmentUseCase = removeTaskAttachmentUseCase,
        _deleteTaskUseCase = deleteTaskUseCase,
        _moveTaskToProjectUseCase = moveTaskToProjectUseCase,
        super(TaskInitial()) {
    on<TasksLoadRequested>(_onTasksLoadRequested);
    on<TaskCreateRequested>(_onTaskCreateRequested);
    on<TaskStatusChangeRequested>(_onTaskStatusChangeRequested);
    on<TaskUpdateRequested>(_onTaskUpdateRequested);
    on<TaskAttachmentAddRequested>(_onTaskAttachmentAddRequested);
    on<TaskAttachmentRemoveRequested>(_onTaskAttachmentRemoveRequested);
    on<TaskDeleteRequested>(_onTaskDeleteRequested);
    on<TasksDeleteRequested>(_onTasksDeleteRequested);
    on<TaskMoveRequested>(_onTaskMoveRequested);
  }

  Future<void> _onTasksLoadRequested(TasksLoadRequested event, Emitter<TaskState> emit) async {
    emit(TaskLoading());
    final result = await _getTasksUseCase(event.projectId);
    result.fold(
      (failure) => emit(TaskError(message: failure.message, tasks: const [])),
      (tasks) => emit(TaskLoaded(tasks: tasks)),
    );
  }

  Future<void> _onTaskCreateRequested(TaskCreateRequested event, Emitter<TaskState> emit) async {
    final current = _currentTasks();
    emit(TaskLoaded(tasks: current, isMutating: true));

    final createResult = await _createTaskUseCase(
      projectId: event.projectId,
      title: event.title,
      description: event.description,
      isImportant: event.isImportant,
      isUrgent: event.isUrgent,
      dueDate: event.dueDate,
      startDate: event.startDate,
      hasStartTime: event.hasStartTime,
      labelId: event.labelId,
      repeatFrequency: event.repeatFrequency,
    );

    await createResult.fold(
      (failure) async => emit(TaskError(message: failure.message, tasks: current)),
      (newTask) async {
        if (event.attachmentPaths.isEmpty) {
          emit(TaskLoaded(tasks: [...current, newTask]));
          return;
        }

        final uploadResult = await _uploadTaskAttachmentsUseCase(
          taskId: newTask.id,
          filePaths: event.attachmentPaths,
        );

        uploadResult.fold(
          (failure) {
            emit(TaskError(message: failure.message, tasks: [...current, newTask]));
          },
          (urls) {
            final taskWithAttachments = newTask.copyWith(attachmentUrls: urls);
            emit(TaskLoaded(tasks: [...current, taskWithAttachments]));
          },
        );
      },
    );
  }

  Future<void> _onTaskStatusChangeRequested(TaskStatusChangeRequested event, Emitter<TaskState> emit) async {
    final current = _currentTasks();
    emit(TaskLoaded(tasks: current, isMutating: true));

    final result = await _updateTaskStatusUseCase(taskId: event.taskId, status: event.status);
    result.fold(
      (failure) => emit(TaskError(message: failure.message, tasks: current)),
      (updatedTask) {
        final updatedList = current.map((t) => t.id == updatedTask.id ? updatedTask : t).toList();
        emit(TaskLoaded(tasks: updatedList));
      },
    );
  }

  Future<void> _onTaskUpdateRequested(TaskUpdateRequested event, Emitter<TaskState> emit) async {
    final current = _currentTasks();
    emit(TaskLoaded(tasks: current, isMutating: true));

    final result = await _updateTaskUseCase(
      taskId: event.taskId,
      title: event.title,
      description: event.description,
      isImportant: event.isImportant,
      isUrgent: event.isUrgent,
      dueDate: event.dueDate,
      startDate: event.startDate,
      hasStartTime: event.hasStartTime,
      labelId: event.labelId,
      repeatFrequency: event.repeatFrequency,
    );
    result.fold(
      (failure) => emit(TaskError(message: failure.message, tasks: current)),
      (updatedTask) {
        final updatedList = current.map((t) => t.id == updatedTask.id ? updatedTask : t).toList();
        emit(TaskLoaded(tasks: updatedList));
      },
    );
  }

  Future<void> _onTaskAttachmentAddRequested(TaskAttachmentAddRequested event, Emitter<TaskState> emit) async {
    final current = _currentTasks();
    emit(TaskLoaded(tasks: current, isMutating: true));

    final result = await _uploadTaskAttachmentsUseCase(taskId: event.taskId, filePaths: event.filePaths);
    result.fold(
      (failure) => emit(TaskError(message: failure.message, tasks: current)),
      (urls) {
        final updatedList = current.map((t) {
          if (t.id != event.taskId) return t;
          return t.copyWith(attachmentUrls: [...t.attachmentUrls, ...urls]);
        }).toList();
        emit(TaskLoaded(tasks: updatedList));
      },
    );
  }

  Future<void> _onTaskAttachmentRemoveRequested(TaskAttachmentRemoveRequested event, Emitter<TaskState> emit) async {
    final current = _currentTasks();
    emit(TaskLoaded(tasks: current, isMutating: true));

    final result = await _removeTaskAttachmentUseCase(taskId: event.taskId, attachmentUrl: event.attachmentUrl);
    result.fold(
      (failure) => emit(TaskError(message: failure.message, tasks: current)),
      (updatedTask) {
        final updatedList = current.map((t) => t.id == updatedTask.id ? updatedTask : t).toList();
        emit(TaskLoaded(tasks: updatedList));
      },
    );
  }

  Future<void> _onTaskDeleteRequested(TaskDeleteRequested event, Emitter<TaskState> emit) async {
    final current = _currentTasks();
    emit(TaskLoaded(tasks: current, isMutating: true));

    final result = await _deleteTaskUseCase(
      event.taskId,
      projectName: event.projectName,
      workspaceId: event.workspaceId,
      workspaceName: event.workspaceName,
    );
    result.fold(
      (failure) => emit(TaskError(message: failure.message, tasks: current)),
      (_) {
        final updated = current.where((t) => t.id != event.taskId).toList();
        emit(TaskLoaded(tasks: updated));
      },
    );
  }

  Future<void> _onTasksDeleteRequested(TasksDeleteRequested event, Emitter<TaskState> emit) async {
    final current = _currentTasks();
    emit(TaskLoaded(tasks: current, isMutating: true));

    final ids = event.taskIds;
    var updated = current;
    String? errorMessage;

    for (final id in ids) {
      final result = await _deleteTaskUseCase(
        id,
        projectName: event.projectName,
        workspaceId: event.workspaceId,
        workspaceName: event.workspaceName,
      );
      result.fold(
        (failure) => errorMessage = failure.message,
        (_) => updated = updated.where((t) => t.id != id).toList(),
      );
    }

    if (errorMessage != null) {
      emit(TaskError(message: errorMessage!, tasks: updated));
    } else {
      emit(TaskLoaded(tasks: updated));
    }
  }

  Future<void> _onTaskMoveRequested(TaskMoveRequested event, Emitter<TaskState> emit) async {
    final current = _currentTasks();
    emit(TaskLoaded(tasks: current, isMutating: true));

    final result = await _moveTaskToProjectUseCase(
      taskId: event.taskId,
      newProjectId: event.newProjectId,
    );
    result.fold(
      (failure) => emit(TaskError(message: failure.message, tasks: current)),
      (_) {
        final updated = current.where((t) => t.id != event.taskId).toList();
        emit(TaskLoaded(tasks: updated));
      },
    );
  }

  List<TaskEntity> _currentTasks() {
    final currentState = state;
    if (currentState is TaskLoaded) return currentState.tasks;
    if (currentState is TaskError) return currentState.tasks;
    return [];
  }
}