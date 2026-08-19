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

class TaskUpdateRequested extends TaskEvent {
  final String taskId;
  final String title;
  final String? description;
  final bool isImportant;
  final bool isUrgent;
  final DateTime? dueDate;
  final String? labelId;
  final RepeatFrequency repeatFrequency;

  const TaskUpdateRequested({
    required this.taskId,
    required this.title,
    this.description,
    this.isImportant = false,
    this.isUrgent = false,
    this.dueDate,
    this.labelId,
    this.repeatFrequency = RepeatFrequency.none,
  });

  @override
  List<Object?> get props =>
      [taskId, title, description, isImportant, isUrgent, dueDate, labelId, repeatFrequency];
}

/// طلب إضافة مرفقات لتاسك موجود مسبقاً (من شاشة تفاصيل التاسك).
/// منفصل عن TaskCreateRequested لأنه هون التاسك أصلاً موجود وممكن يكون
/// عندو مرفقات سابقة، فمنضيف الجداد إلها بدل ما نستبدلها.
class TaskAttachmentAddRequested extends TaskEvent {
  final String taskId;
  final List<String> filePaths;
  const TaskAttachmentAddRequested({required this.taskId, required this.filePaths});
  @override
  List<Object?> get props => [taskId, filePaths];
}

/// طلب حذف مرفق واحد من تاسك موجود (من شاشة تفاصيل التاسك).
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

/// حذف مؤقت (نقل لسلة المحذوفات). لازم نمرر اسم المشروع والـ workspace
/// هون (Snapshot) — الشاشة (TasksScreen) أصلاً عندها هالمعلومات بالذاكرة،
/// فما في داعي الـ Bloc/Repository يروحوا يجيبوها من مكان تاني.
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

/// طلب نقل التاسك من المشروع (أو الـ Inbox) الحالي إلو لمشروع تاني —
/// مستخدمة أساساً من شاشة الـ Inbox لما المستخدم يحدد مشروع لتاسك.
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