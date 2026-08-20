import 'package:equatable/equatable.dart';
import '../../../workspace/domain/entities/workspace_entity.dart';
import '../../domain/entities/project_option.dart';
import '../../domain/entities/task_with_context.dart';

abstract class CalendarState extends Equatable {
  const CalendarState();
  @override
  List<Object?> get props => [];
}

class CalendarInitial extends CalendarState {}

class CalendarLoading extends CalendarState {}

class CalendarLoaded extends CalendarState {
  final List<TaskWithContext> tasks;
  final List<WorkspaceEntity> workspaces;
  final List<ProjectOption> projectOptions;
  final bool isMutating;

  const CalendarLoaded({
    required this.tasks,
    required this.workspaces,
    required this.projectOptions,
    this.isMutating = false,
  });

  @override
  List<Object?> get props => [tasks, workspaces, projectOptions, isMutating];
}

class CalendarError extends CalendarState {
  final String message;
  final List<TaskWithContext> tasks;
  final List<WorkspaceEntity> workspaces;
  final List<ProjectOption> projectOptions;

  const CalendarError({
    required this.message,
    this.tasks = const [],
    this.workspaces = const [],
    this.projectOptions = const [],
  });

  @override
  List<Object?> get props => [message, tasks, workspaces, projectOptions];
}