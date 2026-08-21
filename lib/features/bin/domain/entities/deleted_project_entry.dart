import '../../../project/domain/entities/project_entity.dart';
import '../../../task/domain/entities/task_entity.dart';

class DeletedProjectEntry {
  static const int retentionDays = 30;

  final ProjectEntity project;
  final List<TaskEntity> tasks;
  final String workspaceId;
  final String workspaceName;
  final DateTime deletedAt;

  const DeletedProjectEntry({
    required this.project,
    required this.tasks,
    required this.workspaceId,
    required this.workspaceName,
    required this.deletedAt,
  });

  String get projectId => project.id;
  int get taskCount => tasks.length;

  int get daysRemaining {
    final elapsed = DateTime.now().difference(deletedAt).inDays;
    final remaining = retentionDays - elapsed;
    return remaining < 0 ? 0 : remaining;
  }

  bool get isExpired =>
      DateTime.now().difference(deletedAt).inDays >= retentionDays;
}