import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';

class MoveTaskToProjectUseCase {
  final TaskRepository repository;
  MoveTaskToProjectUseCase(this.repository);

  Future<Either<Failure, TaskEntity>> call({
    required String taskId,
    required String newProjectId,
  }) {
    return repository.moveTaskToProject(taskId: taskId, newProjectId: newProjectId);
  }
}