import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../repositories/workspace_repository.dart';

class DeleteWorkspaceUseCase {
  final WorkspaceRepository repository;
  DeleteWorkspaceUseCase(this.repository);

  Future<Either<Failure, void>> call(String workspaceId) {
    return repository.deleteWorkspace(workspaceId);
  }
}