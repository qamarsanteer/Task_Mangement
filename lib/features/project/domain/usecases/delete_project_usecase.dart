import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../repositories/project_repository.dart';

class DeleteProjectUseCase {
  final ProjectRepository repository;
  DeleteProjectUseCase(this.repository);

  Future<Either<Failure, void>> call(String projectId) {
    return repository.deleteProject(projectId);
  }
}