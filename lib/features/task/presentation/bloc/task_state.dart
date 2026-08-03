import 'package:equatable/equatable.dart';
import '../../domain/entities/task_entity.dart';

abstract class TaskState extends Equatable {
  const TaskState();
  @override
  List<Object?> get props => [];
}

class TaskInitial extends TaskState {}

class TaskLoading extends TaskState {}

class TaskLoaded extends TaskState {
  final List<TaskEntity> tasks;
  final bool isMutating;

  const TaskLoaded({required this.tasks, this.isMutating = false});

  @override
  List<Object?> get props => [tasks, isMutating];
}

class TaskError extends TaskState {
  final String message;
  final List<TaskEntity> tasks;

  const TaskError({required this.message, required this.tasks});

  @override
  List<Object?> get props => [message, tasks];
}