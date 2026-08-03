import '../../domain/entities/task_entity.dart';

class TaskModel extends TaskEntity {
  const TaskModel({
    required super.id,
    required super.title,
    super.description,
    required super.status,
    super.isImportant = false,
    super.isUrgent = false,
    super.dueDate,
    required super.projectId,
    super.createdAt,
    super.labelId,
    super.attachmentUrls = const [],
    super.repeatFrequency = RepeatFrequency.none,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? json['name'] ?? '',
      description: json['description'],
      status: _statusFromString(json['status']?.toString()),
      isImportant: json['is_important'] ?? json['isImportant'] ?? false,
      isUrgent: json['is_urgent'] ?? json['isUrgent'] ?? false,
      dueDate: json['due_date'] != null ? DateTime.tryParse(json['due_date'].toString()) : null,
      projectId: json['project_id']?.toString() ?? json['projectId']?.toString() ?? '',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      labelId: json['label_id']?.toString() ?? json['labelId']?.toString(),
      attachmentUrls: (json['attachment_urls'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      repeatFrequency: _repeatFromString(json['repeat_frequency']?.toString()),
    );
  }

  static TaskStatus _statusFromString(String? value) {
    switch (value) {
      case 'in_progress':
      case 'inProgress':
        return TaskStatus.inProgress;
      case 'completed':
      case 'done':
        return TaskStatus.completed;
      case 'not_started':
      case 'notStarted':
      default:
        return TaskStatus.notStarted;
    }
  }

  static String statusToString(TaskStatus status) {
    switch (status) {
      case TaskStatus.notStarted:
        return 'not_started';
      case TaskStatus.inProgress:
        return 'in_progress';
      case TaskStatus.completed:
        return 'completed';
    }
  }

  static RepeatFrequency _repeatFromString(String? value) {
    switch (value) {
      case 'daily':
        return RepeatFrequency.daily;
      case 'weekly':
        return RepeatFrequency.weekly;
      case 'monthly':
        return RepeatFrequency.monthly;
      case 'none':
      default:
        return RepeatFrequency.none;
    }
  }

  static String repeatToString(RepeatFrequency frequency) {
    switch (frequency) {
      case RepeatFrequency.daily:
        return 'daily';
      case RepeatFrequency.weekly:
        return 'weekly';
      case RepeatFrequency.monthly:
        return 'monthly';
      case RepeatFrequency.none:
        return 'none';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      if (description != null) 'description': description,
      'status': statusToString(status),
      'is_important': isImportant,
      'is_urgent': isUrgent,
      if (dueDate != null) 'due_date': dueDate!.toIso8601String(),
      'project_id': projectId,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (labelId != null) 'label_id': labelId,
      'attachment_urls': attachmentUrls,
      'repeat_frequency': repeatToString(repeatFrequency),
    };
  }
}