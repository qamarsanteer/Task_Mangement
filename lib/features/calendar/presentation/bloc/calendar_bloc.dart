import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/inbox_constants.dart';
import '../../../project/domain/usecases/get_projects_usecase.dart';
import '../../../task/domain/usecases/create_task_usecase.dart';
import '../../../task/domain/usecases/delete_task_usecase.dart';
import '../../../task/domain/usecases/get_tasks_usecase.dart';
import '../../../task/domain/usecases/upload_task_attachments_usecase.dart';
import '../../../workspace/domain/entities/workspace_entity.dart';
import '../../../workspace/domain/usecases/get_workspaces_usecase.dart';
import '../../domain/entities/project_option.dart';
import '../../domain/entities/task_with_context.dart';
import 'calendar_event.dart';
import 'calendar_state.dart';

class _CalendarData {
  final List<TaskWithContext> tasks;
  final List<WorkspaceEntity> workspaces;
  final List<ProjectOption> projectOptions;

  const _CalendarData({
    required this.tasks,
    required this.workspaces,
    required this.projectOptions,
  });

  static const empty = _CalendarData(tasks: [], workspaces: [], projectOptions: []);
}

class CalendarBloc extends Bloc<CalendarEvent, CalendarState> {
  final GetWorkspacesUseCase _getWorkspacesUseCase;
  final GetProjectsUseCase _getProjectsUseCase;
  final GetTasksUseCase _getTasksUseCase;
  final CreateTaskUseCase _createTaskUseCase;
  final DeleteTaskUseCase _deleteTaskUseCase;
  final UploadTaskAttachmentsUseCase _uploadTaskAttachmentsUseCase;

  CalendarBloc({
    required GetWorkspacesUseCase getWorkspacesUseCase,
    required GetProjectsUseCase getProjectsUseCase,
    required GetTasksUseCase getTasksUseCase,
    required CreateTaskUseCase createTaskUseCase,
    required DeleteTaskUseCase deleteTaskUseCase,
    required UploadTaskAttachmentsUseCase uploadTaskAttachmentsUseCase,
  })  : _getWorkspacesUseCase = getWorkspacesUseCase,
        _getProjectsUseCase = getProjectsUseCase,
        _getTasksUseCase = getTasksUseCase,
        _createTaskUseCase = createTaskUseCase,
        _deleteTaskUseCase = deleteTaskUseCase,
        _uploadTaskAttachmentsUseCase = uploadTaskAttachmentsUseCase,
        super(CalendarInitial()) {
    on<CalendarTasksLoadRequested>(_onTasksLoadRequested);
    on<CalendarTaskCreateRequested>(_onTaskCreateRequested);
    on<CalendarTaskDeleteRequested>(_onTaskDeleteRequested);
  }

  Future<void> _onTasksLoadRequested(
    CalendarTasksLoadRequested event,
    Emitter<CalendarState> emit,
  ) async {
    emit(CalendarLoading());
    final result = await _fetchAll(event.inboxLabel);
    result.fold(
      (message) => emit(CalendarError(message: message)),
      (data) => emit(CalendarLoaded(
        tasks: data.tasks,
        workspaces: data.workspaces,
        projectOptions: data.projectOptions,
      )),
    );
  }

  Future<void> _onTaskCreateRequested(
    CalendarTaskCreateRequested event,
    Emitter<CalendarState> emit,
  ) async {
    final current = _currentData();
    emit(CalendarLoaded(
      tasks: current.tasks,
      workspaces: current.workspaces,
      projectOptions: current.projectOptions,
      isMutating: true,
    ));

    final createResult = await _createTaskUseCase(
      projectId: event.project.projectId,
      title: event.title,
      description: event.description,
      isImportant: event.isImportant,
      isUrgent: event.isUrgent,
      dueDate: event.dueDate,
      labelId: event.labelId,
      repeatFrequency: event.repeatFrequency,
    );

    final failureMessage = createResult.fold((failure) => failure.message, (_) => null);
    if (failureMessage != null) {
      emit(CalendarError(
        message: failureMessage,
        tasks: current.tasks,
        workspaces: current.workspaces,
        projectOptions: current.projectOptions,
      ));
      return;
    }

    final newTask = createResult.fold((_) => null, (task) => task)!;

    if (event.attachmentPaths.isNotEmpty) {
      await _uploadTaskAttachmentsUseCase(taskId: newTask.id, filePaths: event.attachmentPaths);
    }

    final result = await _fetchAll(event.inboxLabel);
    result.fold(
      (message) => emit(CalendarError(
        message: message,
        tasks: current.tasks,
        workspaces: current.workspaces,
        projectOptions: current.projectOptions,
      )),
      (data) => emit(CalendarLoaded(
        tasks: data.tasks,
        workspaces: data.workspaces,
        projectOptions: data.projectOptions,
      )),
    );
  }

  Future<void> _onTaskDeleteRequested(
    CalendarTaskDeleteRequested event,
    Emitter<CalendarState> emit,
  ) async {
    final current = _currentData();
    emit(CalendarLoaded(
      tasks: current.tasks,
      workspaces: current.workspaces,
      projectOptions: current.projectOptions,
      isMutating: true,
    ));

    final result = await _deleteTaskUseCase(
      event.entry.task.id,
      projectName: event.entry.projectName,
      workspaceId: event.entry.workspaceId,
      workspaceName: event.entry.workspaceName,
    );

    result.fold(
      (failure) => emit(CalendarError(
        message: failure.message,
        tasks: current.tasks,
        workspaces: current.workspaces,
        projectOptions: current.projectOptions,
      )),
      (_) {
        final updatedTasks = current.tasks.where((e) => e.task.id != event.entry.task.id).toList();
        emit(CalendarLoaded(
          tasks: updatedTasks,
          workspaces: current.workspaces,
          projectOptions: current.projectOptions,
        ));
      },
    );
  }

  Future<Either<String, _CalendarData>> _fetchAll(String inboxLabel) async {
    try {
      final workspacesResult = await _getWorkspacesUseCase();
      final workspaces = workspacesResult.fold((failure) => null, (list) => list);
      if (workspaces == null) {
        return Left(workspacesResult.fold((failure) => failure.message, (_) => ''));
      }

      final collected = <TaskWithContext>[];
      final projectOptions = <ProjectOption>[];

      final inboxTasksResult = await _getTasksUseCase(kInboxProjectId);
      final inboxTasks = inboxTasksResult.fold((failure) => null, (list) => list);
      if (inboxTasks != null) {
        for (final task in inboxTasks) {
          collected.add(TaskWithContext(
            task: task,
            projectId: kInboxProjectId,
            projectName: inboxLabel,
            workspaceId: '',
            workspaceName: '',
          ));
        }
      }

      for (final workspace in workspaces) {
        final projectsResult = await _getProjectsUseCase(workspace.id);
        final projects = projectsResult.fold((failure) => null, (list) => list);
        if (projects == null) continue;

        for (final project in projects) {
          projectOptions.add(ProjectOption(
            projectId: project.id,
            projectName: project.name,
            workspaceId: workspace.id,
            workspaceName: workspace.name,
          ));

          final tasksResult = await _getTasksUseCase(project.id);
          final tasks = tasksResult.fold((failure) => null, (list) => list);
          if (tasks == null) continue;

          for (final task in tasks) {
            collected.add(TaskWithContext(
              task: task,
              projectId: project.id,
              projectName: project.name,
              workspaceId: workspace.id,
              workspaceName: workspace.name,
            ));
          }
        }
      }

      return Right(_CalendarData(tasks: collected, workspaces: workspaces, projectOptions: projectOptions));
    } catch (e) {
      return Left(e.toString());
    }
  }

  _CalendarData _currentData() {
    final currentState = state;
    if (currentState is CalendarLoaded) {
      return _CalendarData(
        tasks: currentState.tasks,
        workspaces: currentState.workspaces,
        projectOptions: currentState.projectOptions,
      );
    }
    if (currentState is CalendarError) {
      return _CalendarData(
        tasks: currentState.tasks,
        workspaces: currentState.workspaces,
        projectOptions: currentState.projectOptions,
      );
    }
    return _CalendarData.empty;
  }
}