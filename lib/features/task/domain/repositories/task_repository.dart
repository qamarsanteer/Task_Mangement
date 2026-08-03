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

  Future<Either<Failure, List<String>>> uploadAttachments({
    required String taskId,
    required List<String> filePaths,
  });

  Future<Either<Failure, void>> deleteTask(String taskId);
}