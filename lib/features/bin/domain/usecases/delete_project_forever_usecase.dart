import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../repositories/bin_repository.dart';

class DeleteProjectForeverUseCase {
  final BinRepository _repository;
  const DeleteProjectForeverUseCase(this._repository);

  Future<Either<Failure, void>> call(String projectId) {
    return _repository.deleteProjectForever(projectId);
  }
}