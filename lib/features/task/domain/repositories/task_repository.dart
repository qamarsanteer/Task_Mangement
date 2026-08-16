import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/task_entity.dart';

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
  /// دايماً منبعت كل الحقول (متل TaskCreateRequested) — الحقل يلي ما تغيّر
  /// منبعته بقيمته الحالية، هيك ما في حاجة نميّز "ما تغيّر" عن "صار null".
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

  /// حذف مرفق واحد من التاسك (بالـ URL/المسار تبعو).
  Future<Either<Failure, TaskEntity>> removeAttachment({
    required String taskId,
    required String attachmentUrl,
  });

  Future<Either<Failure, void>> deleteTask(String taskId);
}