import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../repositories/task_repository.dart';

class DeleteTaskUseCase {
  final TaskRepository repository;
  DeleteTaskUseCase(this.repository);

  Future<Either<Failure, void>> call(String taskId) {
    return repository.deleteTask(taskId);
  }
}