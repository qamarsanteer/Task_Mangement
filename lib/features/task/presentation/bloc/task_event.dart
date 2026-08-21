import 'package:equatable/equatable.dart';
import '../../domain/entities/task_entity.dart';

abstract class TaskEvent extends Equatable {
  const TaskEvent();
  @override
  List<Object?> get props => [];
}

class TasksLoadRequested extends TaskEvent {
  final String projectId;
  const TasksLoadRequested(this.projectId);
  @override
  List<Object?> get props => [projectId];
}

class TaskCreateRequested extends TaskEvent {
  final String projectId;
  final String title;
  final String? description;
  final bool isImportant;
  final bool isUrgent;
  final DateTime? dueDate;
  final DateTime? startDate;
  final bool hasStartTime;
  final String? labelId;
  final RepeatFrequency repeatFrequency;
  final List<String> attachmentPaths;

  const TaskCreateRequested({
    required this.projectId,
    required this.title,
    this.description,
    this.isImportant = false,
    this.isUrgent = false,
    this.dueDate,
     this.startDate,
    this.hasStartTime = false,
    this.labelId,
    this.repeatFrequency = RepeatFrequency.none,
    this.attachmentPaths = const [],
  });

  @override
  List<Object?> get props =>
      [projectId, title, description, isImportant, isUrgent, startDate, hasStartTime, dueDate, labelId, repeatFrequency, attachmentPaths];
}

class TaskUpdateRequested extends TaskEvent {
  final String taskId;
  final String title;
  final String? description;
  final bool isImportant;
  final bool isUrgent;
  final DateTime? dueDate;
  final DateTime? startDate;
  final bool? hasStartTime;
  final String? labelId;
  final RepeatFrequency repeatFrequency;

  const TaskUpdateRequested({
    required this.taskId,
    required this.title,
    this.description,
    this.isImportant = false,
    this.isUrgent = false,
    this.dueDate,
    this.startDate,
    this.hasStartTime,
    this.labelId,
    this.repeatFrequency = RepeatFrequency.none,
  });

  @override
  List<Object?> get props =>
      [taskId, title, description, isImportant, isUrgent, dueDate, startDate, hasStartTime, labelId, repeatFrequency];
}

class TaskAttachmentAddRequested extends TaskEvent {
  final String taskId;
  final List<String> filePaths;
  const TaskAttachmentAddRequested({required this.taskId, required this.filePaths});
  @override
  List<Object?> get props => [taskId, filePaths];
}

class TaskAttachmentRemoveRequested extends TaskEvent {
  final String taskId;
  final String attachmentUrl;
  const TaskAttachmentRemoveRequested({required this.taskId, required this.attachmentUrl});
  @override
  List<Object?> get props => [taskId, attachmentUrl];
}

class TaskStatusChangeRequested extends TaskEvent {
  final String taskId;
  final TaskStatus status;
  const TaskStatusChangeRequested({required this.taskId, required this.status});
  @override
  List<Object?> get props => [taskId, status];
}

class TaskDeleteRequested extends TaskEvent {
  final String taskId;
  final String projectName;
  final String workspaceId;
  final String workspaceName;

  const TaskDeleteRequested(
    this.taskId, {
    required this.projectName,
    required this.workspaceId,
    required this.workspaceName,
  });

  @override
  List<Object?> get props => [taskId, projectName, workspaceId, workspaceName];
}

class TaskMoveRequested extends TaskEvent {
  final String taskId;
  final String newProjectId;
  const TaskMoveRequested({required this.taskId, required this.newProjectId});
  @override
  List<Object?> get props => [taskId, newProjectId];
}

class TasksDeleteRequested extends TaskEvent {
  final List<String> taskIds;
  final String projectName;
  final String workspaceId;
  final String workspaceName;

  const TasksDeleteRequested(
    this.taskIds, {
    required this.projectName,
    required this.workspaceId,
    required this.workspaceName,
  });

  @override
  List<Object?> get props => [taskIds, projectName, workspaceId, workspaceName];
}