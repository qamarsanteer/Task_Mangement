import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/project_entity.dart';

abstract class ProjectRepository {
  Future<Either<Failure, List<ProjectEntity>>> getProjects(String workspaceId);

  Future<Either<Failure, ProjectEntity>> createProject({
    required String workspaceId,
    required String name,
  });

  Future<Either<Failure, void>> deleteProject(String projectId);
}