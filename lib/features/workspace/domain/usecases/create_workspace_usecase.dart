import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/workspace_entity.dart';
import '../repositories/workspace_repository.dart';

class CreateWorkspaceUseCase {
  final WorkspaceRepository repository;
  CreateWorkspaceUseCase(this.repository);

  Future<Either<Failure, WorkspaceEntity>> call(String name) {
    return repository.createWorkspace(name);
  }
}