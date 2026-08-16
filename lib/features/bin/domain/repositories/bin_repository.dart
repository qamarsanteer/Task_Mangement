import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../../../task/domain/entities/deleted_task_entry.dart';
import '../../../task/domain/entities/task_entity.dart';

/// واجهة سلة المحذوفات. التخزين الفعلي موجود جوا TaskRepository (نفس
/// مصدر الكاش)، وهاد الـ Repository هون بس بيوفّر واجهة مخصصة نظيفة
/// لفيتشر الـ Bin بدون ما يعرف تفاصيل تخزين التاسكات.
abstract class BinRepository {
  Future<Either<Failure, List<DeletedTaskEntry>>> getDeletedTasks();
  Future<Either<Failure, TaskEntity>> restoreTask(String taskId);
  Future<Either<Failure, void>> deleteTaskForever(String taskId);
}