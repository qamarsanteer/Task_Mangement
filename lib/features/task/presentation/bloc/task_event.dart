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
    this.labelId,
    this.repeatFrequency = RepeatFrequency.none,
    this.attachmentPaths = const [],
  });

  @override
  List<Object?> get props =>
      [projectId, title, description, isImportant, isUrgent, dueDate, labelId, repeatFrequency, attachmentPaths];
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
  const TaskDeleteRequested(this.taskId);
  @override
  List<Object?> get props => [taskId];
}