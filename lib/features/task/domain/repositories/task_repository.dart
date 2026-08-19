import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/task_entity.dart';
import '../entities/deleted_task_entry.dart'; // ⬅️ جديد

abstract class TaskRepository {
  Future<Either<Failure, List<TaskEntity>>> getTasks(String projectId);

  Future<Either<Failure, TaskEntity>> createTask({
    required String projectId,
    required String title,
    String? description,
    bool isImportant = false,
    bool isUrgent = false,
    DateTime? dueDate,
    String? labelId,
    RepeatFrequency repeatFrequency = RepeatFrequency.none,
  });

  Future<Either<Failure, TaskEntity>> updateTaskStatus({
    required String taskId,
    required TaskStatus status,
  });

  /// تعديل بيانات التاسك (العنوان، الوصف، تاريخ الاستحقاق، الأولوية، التصنيف، التكرار).
  Future<Either<Failure, TaskEntity>> updateTask({
    required String taskId,
    required String title,
    String? description,
    bool isImportant = false,
    bool isUrgent = false,
    DateTime? dueDate,
    String? labelId,
    RepeatFrequency repeatFrequency = RepeatFrequency.none,
  });

  Future<Either<Failure, List<String>>> uploadAttachments({
    required String taskId,
    required List<String> filePaths,
  });

  Future<Either<Failure, TaskEntity>> removeAttachment({
    required String taskId,
    required String attachmentUrl,
  });

  /// نقل التاسك لسلة المحذوفات (soft-delete) — ما بيحذفه نهائياً من
  /// السيرفر إطلاقاً. لازم نمرر اسم المشروع والـ workspace هون لأنه
  /// ممكن ينحذف المشروع نفسه قبل ما المستخدم يسترجع التاسك من السلة.
  Future<Either<Failure, void>> deleteTask(
    String taskId, {
    required String projectName,
    required String workspaceId,
    required String workspaceName,
  });

  /// قائمة التاسكات الموجودة حالياً بسلة المحذوفات. بتنظّف تلقائياً أي
  /// تاسك عدّى عليه 30 يوم قبل ما ترجّع القائمة (حذف نهائي تلقائي).
  Future<Either<Failure, List<DeletedTaskEntry>>> getDeletedTasks();

  /// يرجّع تاسك من السلة لمكانه الأصلي (نفس المشروع اللي كان فيه).
  Future<Either<Failure, TaskEntity>> restoreTask(String taskId);

  /// حذف نهائي من السلة — هون بس بيصير نداء حذف حقيقي عالسيرفر
  /// (أو تسجيل عملية معلّقة لو الجهاز أوفلاين).
  Future<Either<Failure, void>> deleteTaskForever(String taskId);

  /// منقل التاسك من المشروع (أو الـ Inbox) الحالي إلو، لمشروع تاني —
  /// مستخدمة أساساً لما المستخدم يحدد مشروع لتاسك كان بالـ Inbox
  /// (projectId = 'inbox'). التاسك نفسه بيضل بنفس المعرّف (id)، بس
  /// projectId تبعو بيتغيّر، وبيصير يظهر بليستة المشروع الجديد.
  Future<Either<Failure, TaskEntity>> moveTaskToProject({
    required String taskId,
    required String newProjectId,
  });
}