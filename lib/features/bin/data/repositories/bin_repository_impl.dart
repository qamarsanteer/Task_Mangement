import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../../../task/domain/entities/deleted_task_entry.dart';
import '../../../task/domain/entities/task_entity.dart';  
import '../../../task/domain/repositories/task_repository.dart';
import '../../domain/entities/deleted_project_entry.dart';
import '../../domain/repositories/bin_repository.dart';
import '../../../project/domain/entities/project_entity.dart';

class BinRepositoryImpl implements BinRepository {
  final TaskRepository _taskRepository;

  BinRepositoryImpl({required TaskRepository taskRepository})
      : _taskRepository = taskRepository;

  @override
  Future<Either<Failure, List<DeletedTaskEntry>>> getDeletedTasks() {
    return _taskRepository.getDeletedTasks();
  }

  @override
  Future<Either<Failure, TaskEntity>> restoreTask(String taskId) {
    return _taskRepository.restoreTask(taskId);
  }

  @override
  Future<Either<Failure, void>> deleteTaskForever(String taskId) {
    return _taskRepository.deleteTaskForever(taskId);
  }

  @override
  Future<Either<Failure, List<DeletedProjectEntry>>> getDeletedProjects() {
    return _taskRepository.getDeletedProjects();
  }

  @override
  Future<Either<Failure, ProjectEntity>> restoreProject(String projectId) {
    return _taskRepository.restoreProject(projectId);
  }

  @override
  Future<Either<Failure, void>> deleteProjectForever(String projectId) {
    return _taskRepository.deleteProjectForever(projectId);
  }
}