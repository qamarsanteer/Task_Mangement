import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/workspace_entity.dart';
import '../repositories/workspace_repository.dart';

class GetWorkspacesUseCase {
  final WorkspaceRepository repository;
  GetWorkspacesUseCase(this.repository);

  Future<Either<Failure, List<WorkspaceEntity>>> call() {
    return repository.getWorkspaces();
  }
}