import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/project_entity.dart';
import '../entities/project_member_role.dart';
import '../entities/project_member_entity.dart';

abstract class ProjectRepository {
  Future<Either<Failure, List<ProjectEntity>>> getProjects(String workspaceId);

  Future<Either<Failure, ProjectEntity>> createProject({
    required String workspaceId,
    required String name,
    String? description,
  });

  Future<Either<Failure, void>> deleteProject(String projectId);

  Future<Either<Failure, void>> inviteMember({
    required String projectId,
    required String email,
    required ProjectMemberRole role,
  });

  Future<Either<Failure, List<ProjectMemberEntity>>> getMembers(String projectId);
}