import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/project_member_role.dart';
import '../repositories/project_repository.dart';

class InviteProjectMemberUseCase {
  final ProjectRepository repository;
  InviteProjectMemberUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String projectId,
    required String email,
    required ProjectMemberRole role,
  }) {
    return repository.inviteMember(projectId: projectId, email: email, role: role);
  }
}