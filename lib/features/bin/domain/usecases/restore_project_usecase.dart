import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../repositories/bin_repository.dart';
import '../../../project/domain/entities/project_entity.dart';

class RestoreProjectUseCase {
  final BinRepository _repository;
  const RestoreProjectUseCase(this._repository);

  Future<Either<Failure, ProjectEntity>> call(String projectId) {
    return _repository.restoreProject(projectId);
  }
}