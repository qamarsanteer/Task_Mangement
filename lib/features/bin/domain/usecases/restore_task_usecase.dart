import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../../../task/domain/entities/task_entity.dart';
import '../repositories/bin_repository.dart';

class RestoreTaskUseCase {
  final BinRepository repository;
  RestoreTaskUseCase(this.repository);

  Future<Either<Failure, TaskEntity>> call(String taskId) {
    return repository.restoreTask(taskId);
  }
}