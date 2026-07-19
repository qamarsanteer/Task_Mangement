import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/workspace_entity.dart';

abstract class WorkspaceRepository {
  Future<Either<Failure, List<WorkspaceEntity>>> getWorkspaces();
  Future<Either<Failure, WorkspaceEntity>> createWorkspace(String name);
  Future<Either<Failure, void>> deleteWorkspace(String workspaceId);
}