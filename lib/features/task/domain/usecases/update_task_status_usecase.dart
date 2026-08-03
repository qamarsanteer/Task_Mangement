import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';

class UpdateTaskStatusUseCase {
  final TaskRepository repository;
  UpdateTaskStatusUseCase(this.repository);

  Future<Either<Failure, TaskEntity>> call({
    required String taskId,
    required TaskStatus status,
  }) {
    return repository.updateTaskStatus(taskId: taskId, status: status);
  }
}