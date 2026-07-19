import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/project_entity.dart';
import '../repositories/project_repository.dart';

class GetProjectsUseCase {
  final ProjectRepository repository;
  GetProjectsUseCase(this.repository);

  Future<Either<Failure, List<ProjectEntity>>> call(String workspaceId) {
    return repository.getProjects(workspaceId);
  }
}