import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/task_entity.dart';
import '../entities/deleted_task_entry.dart';
import '../../../bin/domain/entities/deleted_project_entry.dart';
import '../../../project/domain/entities/project_entity.dart';

abstract class TaskRepository {
  Future<Either<Failure, List<TaskEntity>>> getTasks(String projectId);

  Future<Either<Failure, TaskEntity>> createTask({
    required String projectId,
    required String title,
    String? description,
    bool isImportant = false,
    bool isUrgent = false,
    DateTime? dueDate,
    DateTime? startDate,
    bool hasStartTime = false,
    String? labelId,
    RepeatFrequency repeatFrequency = RepeatFrequency.none,
  });

  Future<Either<Failure, TaskEntity>> updateTaskStatus({
    required String taskId,
    required TaskStatus status,
  });

  Future<Either<Failure, TaskEntity>> updateTask({
    required String taskId,
    required String title,
    String? description,
    bool isImportant = false,
    bool isUrgent = false,
    DateTime? dueDate,
    DateTime? startDate,
    bool? hasStartTime,
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

  Future<Either<Failure, void>> deleteTask(
    String taskId, {
    required String projectName,
    required String workspaceId,
    required String workspaceName,
  });

  Future<Either<Failure, List<DeletedTaskEntry>>> getDeletedTasks();
  Future<Either<Failure, TaskEntity>> restoreTask(String taskId);
  Future<Either<Failure, void>> deleteTaskForever(String taskId);

  Future<Either<Failure, TaskEntity>> moveTaskToProject({
    required String taskId,
    required String newProjectId,
  });

   Future<Either<Failure, void>> deleteProjectToBin({
    required String projectId,
    required String workspaceId,
    required String workspaceName,
    ProjectEntity? project,  
  });

  Future<Either<Failure, List<DeletedProjectEntry>>> getDeletedProjects();
  Future<Either<Failure, ProjectEntity>> restoreProject(String projectId);
  Future<Either<Failure, void>> deleteProjectForever(String projectId);
}