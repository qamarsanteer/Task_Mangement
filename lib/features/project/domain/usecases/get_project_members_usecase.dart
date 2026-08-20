import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/project_member_entity.dart';
import '../repositories/project_repository.dart';

class GetProjectMembersUseCase {
  final ProjectRepository repository;
  GetProjectMembersUseCase(this.repository);

  Future<Either<Failure, List<ProjectMemberEntity>>> call(String projectId) {
    return repository.getMembers(projectId);
  }
}
