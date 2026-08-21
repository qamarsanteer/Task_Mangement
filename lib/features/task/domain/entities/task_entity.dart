enum TaskStatus { notStarted, pending, inProgress, completed }

enum RepeatFrequency { none, daily, weekly, monthly }

class TaskEntity {
  final String id;
  final String title;
  final String? description;
  final TaskStatus status;
  final bool isImportant;
  final bool isUrgent;
  final DateTime? dueDate;
   final DateTime? startDate;
  final bool hasStartTime;
  final String projectId;
  final DateTime? createdAt;
  final String? labelId;
  final List<String> attachmentUrls;
  final RepeatFrequency repeatFrequency;

  const TaskEntity({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    this.isImportant = false,
    this.isUrgent = false,
    this.dueDate,
    this.startDate,
    this.hasStartTime = false,
    required this.projectId,
    this.createdAt,
    this.labelId,
    this.attachmentUrls = const [],
    this.repeatFrequency = RepeatFrequency.none,
  });

  /// محسوبة تلقائياً — مش مخزّنة بقاعدة البيانات.
  bool get isOverdue {
    if (dueDate == null) return false;
    if (status == TaskStatus.completed) return false;
    return dueDate!.isBefore(DateTime.now());
  }

  TaskEntity copyWith({
    String? id,
    String? title,
    String? description,
    TaskStatus? status,
    bool? isImportant,
    bool? isUrgent,
    DateTime? dueDate,
    DateTime? startDate,
    bool? hasStartTime,
    String? projectId,
    DateTime? createdAt,
    String? labelId,
    List<String>? attachmentUrls,
    RepeatFrequency? repeatFrequency,
  }) {
    return TaskEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      isImportant: isImportant ?? this.isImportant,
      isUrgent: isUrgent ?? this.isUrgent,
      dueDate: dueDate ?? this.dueDate,
      startDate: startDate ?? this.startDate,
      hasStartTime: hasStartTime ?? this.hasStartTime,
      projectId: projectId ?? this.projectId,
      createdAt: createdAt ?? this.createdAt,
      labelId: labelId ?? this.labelId,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      repeatFrequency: repeatFrequency ?? this.repeatFrequency,
    );
  }
}