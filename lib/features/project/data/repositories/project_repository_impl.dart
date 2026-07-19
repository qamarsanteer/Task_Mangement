import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/dio_error_mapper.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/project_entity.dart';
import '../../domain/repositories/project_repository.dart';
import '../datasources/project_remote_data_source.dart';

class ProjectRepositoryImpl implements ProjectRepository {
  final ProjectRemoteDataSource _remoteDataSource;

  ProjectRepositoryImpl({required ProjectRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, List<ProjectEntity>>> getProjects(String workspaceId) async {
    try {
      final projects = await _remoteDataSource.getProjects(workspaceId);
      return Right(projects);
    } on DioException catch (e) {
      return Left(DioErrorMapper.map(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ProjectEntity>> createProject({
    required String workspaceId,
    required String name,
  }) async {
    try {
      final project = await _remoteDataSource.createProject(workspaceId: workspaceId, name: name);
      return Right(project);
    } on DioException catch (e) {
      return Left(DioErrorMapper.map(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProject(String projectId) async {
    try {
      await _remoteDataSource.deleteProject(projectId);
      return const Right(null);
    } on DioException catch (e) {
      return Left(DioErrorMapper.map(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}