import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../../../task/domain/entities/deleted_task_entry.dart';
import '../repositories/bin_repository.dart';

class GetDeletedTasksUseCase {
  final BinRepository repository;
  GetDeletedTasksUseCase(this.repository);

  Future<Either<Failure, List<DeletedTaskEntry>>> call() {
    return repository.getDeletedTasks();
  }
}