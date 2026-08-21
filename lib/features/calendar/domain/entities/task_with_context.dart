import 'package:equatable/equatable.dart';
import '../../../task/domain/entities/task_entity.dart';

class TaskWithContext extends Equatable {
  final TaskEntity task;
  final String projectId;
  final String projectName;
  final String workspaceId;
  final String workspaceName;

  const TaskWithContext({
    required this.task,
    required this.projectId,
    required this.projectName,
    required this.workspaceId,
    required this.workspaceName,
  });

  @override
  List<Object?> get props => [task, projectId, projectName, workspaceId, workspaceName];
}