import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../repositories/bin_repository.dart';

class DeleteTaskForeverUseCase {
  final BinRepository repository;
  DeleteTaskForeverUseCase(this.repository);

  Future<Either<Failure, void>> call(String taskId) {
    return repository.deleteTaskForever(taskId);
  }
}