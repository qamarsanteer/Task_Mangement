import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/cache/local_cache_service.dart';
import '../../../../core/error/dio_error_mapper.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/sync/syncable.dart';
import '../../../task/domain/repositories/task_repository.dart';
import '../../domain/entities/project_entity.dart';
import '../../domain/repositories/project_repository.dart';
import '../datasources/project_remote_data_source.dart';
import '../models/project_model.dart';
import '../../domain/entities/project_member_entity.dart';

class ProjectRepositoryImpl implements ProjectRepository, Syncable {
  static const _pendingOpsKey = 'pending_project_ops';
  static const _indexKey = 'project_workspace_index';

  final ProjectRemoteDataSource _remoteDataSource;
  final LocalCacheService _cache;
  final ConnectivityService _connectivityService;
  final TaskRepository _taskRepository;

  ProjectRepositoryImpl({
    required ProjectRemoteDataSource remoteDataSource,
    required LocalCacheService cache,
    required ConnectivityService connectivityService,
    required TaskRepository taskRepository,
  }) : _remoteDataSource = remoteDataSource,
       _cache = cache,
       _connectivityService = connectivityService,
       _taskRepository = taskRepository,
       super();

  String _cacheKey(String workspaceId) => 'cache_projects_$workspaceId';

  @override
Future<Either<Failure, List<ProjectEntity>>> getProjects(String workspaceId) async {
  final isConnected = await _connectivityService.isConnected;
  if (isConnected) {
    try {
      final projects = await _remoteDataSource.getProjects(workspaceId);
      final binnedIds = await _binnedProjectIds();
      final filtered = projects.where((p) => !binnedIds.contains(p.id)).toList();
      await _cache.saveList(
        _cacheKey(workspaceId),
        filtered.map((p) => (p as ProjectModel).toJson()).toList(),
      );
      await _indexProjects(workspaceId, filtered.map((p) => p.id));
      return Right(filtered);
    } on DioException catch (e) {
      return _readCachedList(workspaceId) ?? Left(DioErrorMapper.map(e));
    } catch (e) {
      return _readCachedList(workspaceId) ?? Left(UnknownFailure(e.toString()));
    }
  }
  return _readCachedList(workspaceId) ??
      const Left(NetworkFailure('لا يوجد اتصال بالإنترنت ولا بيانات محفوظة محلياً.'));
}

Future<Set<String>> _binnedProjectIds() async {
  final result = await _taskRepository.getDeletedProjects();
  return result.fold(
    (_) => <String>{},
    (entries) => entries.map((e) => e.project.id).toSet(),
  );
}

  @override
  Future<Either<Failure, ProjectEntity>> createProject({
    required String workspaceId,
    required String name,
    String? description,
  }) async {
    final isConnected = await _connectivityService.isConnected;
    if (isConnected) {
      try {
        final project = await _remoteDataSource.createProject(
          workspaceId: workspaceId, name: name, description: description,
        );
        final current = _cache.getList(_cacheKey(workspaceId)) ?? [];
        current.add((project as ProjectModel).toJson());
        await _cache.saveList(_cacheKey(workspaceId), current);
        await _indexProjects(workspaceId, [project.id]);
        return Right(project);
      } on DioException catch (e) {
        return Left(DioErrorMapper.map(e));
      } catch (e) {
        return Left(UnknownFailure(e.toString()));
      }
    }
    final tempId = 'local_${DateTime.now().millisecondsSinceEpoch}';
    final localProject = ProjectModel(
      id: tempId, name: name, description: description,
      workspaceId: workspaceId, createdAt: DateTime.now(),
    );
    final current = _cache.getList(_cacheKey(workspaceId)) ?? [];
    current.add(localProject.toJson());
    await _cache.saveList(_cacheKey(workspaceId), current);
    await _indexProjects(workspaceId, [tempId]);
    await _addPendingOp({
      'type': 'create', 'tempId': tempId, 'workspaceId': workspaceId,
      'name': name, 'description': description,
    });
    return Right(localProject);
  }

@override
Future<Either<Failure, void>> deleteProject(
  String projectId, {
  required String workspaceId,
  required String workspaceName,
}) async {
  final currentProjects = _cache.getList(_cacheKey(workspaceId)) ?? [];
  final projectMap = currentProjects.cast<Map<String, dynamic>>().firstWhere(
        (p) => p['id'] == projectId,
        orElse: () => {},
      );
  final projectEntity = projectMap.isNotEmpty ? ProjectModel.fromJson(projectMap) : null;

 
  await _removeFromCache(workspaceId, projectId);

 
  final binResult = await _taskRepository.deleteProjectToBin(
    projectId: projectId,
    workspaceId: workspaceId,
    workspaceName: workspaceName,
    project: projectEntity,
  );

  return binResult;
}

  @override
  Future<Either<Failure, void>> inviteMember({
    required String projectId, required String email,
  }) async {
    final isConnected = await _connectivityService.isConnected;
    if (!isConnected) {
      return const Left(NetworkFailure('لا يوجد اتصال بالإنترنت.'));
    }
    try {
      await _remoteDataSource.inviteMember(projectId: projectId, email: email);
      return const Right(null);
    } on DioException catch (e) {
      return Left(DioErrorMapper.map(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ProjectMemberEntity>>> getMembers(String projectId) async {
    final isConnected = await _connectivityService.isConnected;
    if (!isConnected) {
      return const Left(NetworkFailure('لا يوجد اتصال بالإنترنت.'));
    }
    try {
      final members = await _remoteDataSource.getMembers(projectId);
      return Right(members);
    } on DioException catch (e) {
      return Left(DioErrorMapper.map(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<void> syncPendingChanges() async {
    final ops = _cache.getList(_pendingOpsKey) ?? [];
    if (ops.isEmpty) return;
    final remaining = <Map<String, dynamic>>[];
    for (final op in ops) {
      try {
        if (op['type'] == 'create') {
          final created = await _remoteDataSource.createProject(
            workspaceId: op['workspaceId'] as String,
            name: op['name'] as String,
            description: op['description'] as String?,
          );
          await _replaceTempId(op['workspaceId'] as String, op['tempId'] as String, created as ProjectModel);
        } else if (op['type'] == 'delete') {
          await _remoteDataSource.deleteProject(op['id'] as String);
        }
      } catch (_) {
        remaining.add(op);
      }
    }
    await _cache.saveList(_pendingOpsKey, remaining);
  }

  Either<Failure, List<ProjectEntity>>? _readCachedList(String workspaceId) {
    final json = _cache.getList(_cacheKey(workspaceId));
    if (json == null) return null;
    return Right(json.map(ProjectModel.fromJson).toList());
  }

  Future<void> _removeFromCache(String workspaceId, String projectId) async {
    final current = _cache.getList(_cacheKey(workspaceId)) ?? [];
    current.removeWhere((p) => p['id'] == projectId);
    await _cache.saveList(_cacheKey(workspaceId), current);
    final index = _cache.getObject(_indexKey) ?? {};
    index.remove(projectId);
    await _cache.saveObject(_indexKey, index);
  }

  Future<void> _replaceTempId(String workspaceId, String tempId, ProjectModel synced) async {
    final current = _cache.getList(_cacheKey(workspaceId)) ?? [];
    final index = current.indexWhere((p) => p['id'] == tempId);
    if (index != -1) {
      current[index] = synced.toJson();
      await _cache.saveList(_cacheKey(workspaceId), current);
    }
    final wIndex = _cache.getObject(_indexKey) ?? {};
    wIndex.remove(tempId);
    wIndex[synced.id] = workspaceId;
    await _cache.saveObject(_indexKey, wIndex);
  }

  Future<void> _indexProjects(String workspaceId, Iterable<String> projectIds) async {
    final index = _cache.getObject(_indexKey) ?? {};
    for (final id in projectIds) { index[id] = workspaceId; }
    await _cache.saveObject(_indexKey, index);
  }

  Future<void> _addPendingOp(Map<String, dynamic> op) async {
    final ops = _cache.getList(_pendingOpsKey) ?? [];
    ops.add(op);
    await _cache.saveList(_pendingOpsKey, ops);
  }

  Future<void> _removePendingCreate(String tempId) async {
    final ops = _cache.getList(_pendingOpsKey) ?? [];
    ops.removeWhere((op) => op['type'] == 'create' && op['tempId'] == tempId);
    await _cache.saveList(_pendingOpsKey, ops);
  }
}