import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../repositories/project_repository.dart';

class DeleteProjectUseCase {
  final ProjectRepository _repository;
  const DeleteProjectUseCase(this._repository);

  Future<Either<Failure, void>> call(
    String projectId, {
    required String workspaceId,
    required String workspaceName,
  }) {
    return _repository.deleteProject(
      projectId,
      workspaceId: workspaceId,
      workspaceName: workspaceName,
    );
  }
}