import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/deleted_project_entry.dart';
import '../repositories/bin_repository.dart';

class GetDeletedProjectsUseCase {
  final BinRepository _repository;
  const GetDeletedProjectsUseCase(this._repository);

  Future<Either<Failure, List<DeletedProjectEntry>>> call() {
    return _repository.getDeletedProjects();
  }
}