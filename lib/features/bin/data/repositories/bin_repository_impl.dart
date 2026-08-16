import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../../../task/domain/entities/deleted_task_entry.dart';
import '../../../task/domain/entities/task_entity.dart';
import '../../../task/domain/repositories/task_repository.dart';
import '../../domain/repositories/bin_repository.dart';

/// Wrapper بس — كل التخزين الفعلي (الكاش، السلة، منطق الـ 30 يوم)
/// موجود جوا TaskRepositoryImpl حتى ما يتكرر نفس منطق الكاش بمكانين.
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
}