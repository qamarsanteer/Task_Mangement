import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/cache/local_cache_service.dart';
import '../../../../core/error/dio_error_mapper.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/sync/syncable.dart';
import '../../domain/entities/workspace_entity.dart';
import '../../domain/repositories/workspace_repository.dart';
import '../datasources/workspace_remote_data_source.dart';
import '../models/workspace_model.dart';

class WorkspaceRepositoryImpl implements WorkspaceRepository, Syncable {
  static const _cacheKey = 'cache_workspaces';
  static const _pendingOpsKey = 'pending_workspace_ops';

  final WorkspaceRemoteDataSource _remoteDataSource;
  final LocalCacheService _cache;
  final ConnectivityService _connectivityService;

  WorkspaceRepositoryImpl({
    required WorkspaceRemoteDataSource remoteDataSource,
    required LocalCacheService cache,
    required ConnectivityService connectivityService,
  })  : _remoteDataSource = remoteDataSource,
        _cache = cache,
        _connectivityService = connectivityService;

  @override
  Future<Either<Failure, List<WorkspaceEntity>>> getWorkspaces() async {
    final isConnected = await _connectivityService.isConnected;

    if (isConnected) {
      try {
        final workspaces = await _remoteDataSource.getWorkspaces();
        await _cacheList(workspaces);
        return Right(workspaces);
      } on DioException catch (e) {
        return _readCachedList() ?? Left(DioErrorMapper.map(e));
      } catch (e) {
        return _readCachedList() ?? Left(UnknownFailure(e.toString()));
      }
    }

    return _readCachedList() ??
        const Left(NetworkFailure('لا يوجد اتصال بالإنترنت ولا بيانات محفوظة محلياً.'));
  }

  @override
  Future<Either<Failure, WorkspaceEntity>> createWorkspace(String name) async {
    final isConnected = await _connectivityService.isConnected;

    if (isConnected) {
      try {
        final workspace = await _remoteDataSource.createWorkspace(name);
        final current = _cache.getList(_cacheKey) ?? [];
        current.add((workspace as WorkspaceModel).toJson());
        await _cache.saveList(_cacheKey, current);
        return Right(workspace);
      } on DioException catch (e) {
        return Left(DioErrorMapper.map(e));
      } catch (e) {
        return Left(UnknownFailure(e.toString()));
      }
    }

    final tempId = 'local_${DateTime.now().millisecondsSinceEpoch}';
    final localWorkspace = WorkspaceModel(id: tempId, name: name, createdAt: DateTime.now());
    final current = _cache.getList(_cacheKey) ?? [];
    current.add(localWorkspace.toJson());
    await _cache.saveList(_cacheKey, current);
    await _addPendingOp({'type': 'create', 'tempId': tempId, 'name': name});
    return Right(localWorkspace);
  }

  @override
  Future<Either<Failure, void>> deleteWorkspace(String workspaceId) async {
    final isConnected = await _connectivityService.isConnected;
    final isLocalOnly = workspaceId.startsWith('local_');

    if (isConnected && !isLocalOnly) {
      try {
        await _remoteDataSource.deleteWorkspace(workspaceId);
        await _removeFromCache(workspaceId);
        return const Right(null);
      } on DioException catch (e) {
        return Left(DioErrorMapper.map(e));
      } catch (e) {
        return Left(UnknownFailure(e.toString()));
      }
    }

    await _removeFromCache(workspaceId);

    if (isLocalOnly) {

      await _removePendingCreate(workspaceId);
    } else {
      await _addPendingOp({'type': 'delete', 'id': workspaceId});
    }
    return const Right(null);
  }



  @override
  Future<void> syncPendingChanges() async {
    final ops = _cache.getList(_pendingOpsKey) ?? [];
    if (ops.isEmpty) return;

    final remaining = <Map<String, dynamic>>[];
    for (final op in ops) {
      try {
        if (op['type'] == 'create') {
          final created = await _remoteDataSource.createWorkspace(op['name'] as String);
          await _replaceTempId(op['tempId'] as String, created as WorkspaceModel);
        } else if (op['type'] == 'delete') {
          await _remoteDataSource.deleteWorkspace(op['id'] as String);
        }
      } catch (_) {
        remaining.add(op); 
      }
    }
    await _cache.saveList(_pendingOpsKey, remaining);
  }

  // ─── Helpers ───

  Future<void> _cacheList(List<WorkspaceEntity> workspaces) async {
    await _cache.saveList(
      _cacheKey,
      workspaces.map((w) => (w as WorkspaceModel).toJson()).toList(),
    );
  }

  Either<Failure, List<WorkspaceEntity>>? _readCachedList() {
    final json = _cache.getList(_cacheKey);
    if (json == null) return null;
    return Right(json.map(WorkspaceModel.fromJson).toList());
  }

  Future<void> _removeFromCache(String workspaceId) async {
    final current = _cache.getList(_cacheKey) ?? [];
    current.removeWhere((w) => w['id'] == workspaceId);
    await _cache.saveList(_cacheKey, current);
  }

  Future<void> _replaceTempId(String tempId, WorkspaceModel synced) async {
    final current = _cache.getList(_cacheKey) ?? [];
    final index = current.indexWhere((w) => w['id'] == tempId);
    if (index != -1) {
      current[index] = synced.toJson();
      await _cache.saveList(_cacheKey, current);
    }
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
