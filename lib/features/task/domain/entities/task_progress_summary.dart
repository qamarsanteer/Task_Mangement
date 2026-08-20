import 'task_entity.dart';

/// ملخّص محسوب من لستة التاسكات — مش مخزّن بقاعدة البيانات ولا بالـ
/// ProjectEntity، لأنه بيصير قديم (stale) أول ما تتبدّل حالة تاسك.
/// دايمًا بنحسبه من List<TaskEntity> الفعلية وقت العرض.
class TaskProgressSummary {
  final int notStarted;
  final int inProgress;
  final int completed;
  final int overdue;

  const TaskProgressSummary({
    this.notStarted = 0,
    this.inProgress = 0,
    this.completed = 0,
    this.overdue = 0,
  });

  int get total => notStarted + inProgress + completed;

  double get completedRatio => total == 0 ? 0 : completed / total;
  double get inProgressRatio => total == 0 ? 0 : inProgress / total;
  double get notStartedRatio => total == 0 ? 0 : notStarted / total;

  factory TaskProgressSummary.fromTasks(List<TaskEntity> tasks) {
    int notStarted = 0;
    int inProgress = 0;
    int completed = 0;
    int overdue = 0;

    for (final task in tasks) {
      switch (task.status) {
        case TaskStatus.notStarted:
          notStarted++;
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
      inProgress: inProgress,
      completed: completed,
      overdue: overdue,
    );
  }
}
