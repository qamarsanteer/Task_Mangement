import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../../../task/domain/entities/deleted_task_entry.dart';
import '../../../task/domain/entities/task_entity.dart';  
import '../entities/deleted_project_entry.dart';
import '../../../project/domain/entities/project_entity.dart';

abstract class BinRepository {
  Future<Either<Failure, List<DeletedTaskEntry>>> getDeletedTasks();
  Future<Either<Failure, TaskEntity>> restoreTask(String taskId);
  Future<Either<Failure, void>> deleteTaskForever(String taskId);

  Future<Either<Failure, List<DeletedProjectEntry>>> getDeletedProjects();
  Future<Either<Failure, ProjectEntity>> restoreProject(String projectId);
  Future<Either<Failure, void>> deleteProjectForever(String projectId);
}