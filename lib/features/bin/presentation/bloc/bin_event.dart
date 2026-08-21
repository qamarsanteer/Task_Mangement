import 'package:equatable/equatable.dart';

abstract class BinEvent extends Equatable {
  const BinEvent();
  @override
  List<Object?> get props => [];
}

class LoadDeletedTasks extends BinEvent {}

class RestoreTask extends BinEvent {
  final String taskId;
  const RestoreTask(this.taskId);
  @override
  List<Object?> get props => [taskId];
}

class DeleteTaskForever extends BinEvent {
  final String taskId;
  const DeleteTaskForever(this.taskId);
  @override
  List<Object?> get props => [taskId];
}

class LoadDeletedProjects extends BinEvent {}

class RestoreProject extends BinEvent {
  final String projectId;
  const RestoreProject(this.projectId);
  @override
  List<Object?> get props => [projectId];
}

class DeleteProjectForever extends BinEvent {
  final String projectId;
  const DeleteProjectForever(this.projectId);
  @override
  List<Object?> get props => [projectId];
}