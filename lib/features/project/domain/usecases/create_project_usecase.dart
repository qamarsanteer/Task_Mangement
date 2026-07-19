import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/project_entity.dart';
import '../repositories/project_repository.dart';

class CreateProjectUseCase {
  final ProjectRepository repository;
  CreateProjectUseCase(this.repository);

  Future<Either<Failure, ProjectEntity>> call({
    required String workspaceId,
    required String name,
  }) {
    return repository.createProject(workspaceId: workspaceId, name: name);
  }
}