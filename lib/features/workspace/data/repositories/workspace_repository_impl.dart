import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/dio_error_mapper.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/workspace_entity.dart';
import '../../domain/repositories/workspace_repository.dart';
import '../datasources/workspace_remote_data_source.dart';

class WorkspaceRepositoryImpl implements WorkspaceRepository {
  final WorkspaceRemoteDataSource _remoteDataSource;

  WorkspaceRepositoryImpl({required WorkspaceRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, List<WorkspaceEntity>>> getWorkspaces() async {
    try {
      final workspaces = await _remoteDataSource.getWorkspaces();
      return Right(workspaces);
    } on DioException catch (e) {
      return Left(DioErrorMapper.map(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, WorkspaceEntity>> createWorkspace(String name) async {
    try {
      final workspace = await _remoteDataSource.createWorkspace(name);
      return Right(workspace);
    } on DioException catch (e) {
      return Left(DioErrorMapper.map(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteWorkspace(String workspaceId) async {
    try {
      await _remoteDataSource.deleteWorkspace(workspaceId);
      return const Right(null);
    } on DioException catch (e) {
      return Left(DioErrorMapper.map(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}