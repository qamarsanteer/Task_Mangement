import 'task_entity.dart';

class TaskProgressSummary {
  final int notStarted;
  final int pending;
  final int inProgress;
  final int completed;
  final int overdue;

  const TaskProgressSummary({
    this.notStarted = 0,
    this.pending = 0,
    this.inProgress = 0,
    this.completed = 0,
    this.overdue = 0,
  });

  int get total => notStarted + pending + inProgress + completed;

  double get completedRatio => total == 0 ? 0 : completed / total;
  double get inProgressRatio => total == 0 ? 0 : inProgress / total;
  double get notStartedRatio => total == 0 ? 0 : notStarted / total;
  double get pendingRatio => total == 0 ? 0 : pending / total;

  factory TaskProgressSummary.fromTasks(List<TaskEntity> tasks) {
    int notStarted = 0;
    int pending = 0;
    int inProgress = 0;
    int completed = 0;
    int overdue = 0;

    for (final task in tasks) {
      switch (task.status) {
        case TaskStatus.notStarted:
          notStarted++;
          break;
        case TaskStatus.pending:
          pending++;
          break;
        case TaskStatus.inProgress:
          inProgress++;
          break;
        case TaskStatus.completed:
          completed++;
          break;
      }
      if (task.isOverdue) overdue++;
    }

    return TaskProgressSummary(
      notStarted: notStarted,
      pending: pending,
      inProgress: inProgress,
      completed: completed,
      overdue: overdue,
    );
  }
}
