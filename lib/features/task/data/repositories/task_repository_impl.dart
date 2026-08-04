import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/cache/local_cache_service.dart';
import '../../../../core/error/dio_error_mapper.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/sync/syncable.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_remote_data_source.dart';
import '../models/task_model.dart';

class TaskRepositoryImpl implements TaskRepository, Syncable {
  static const _pendingOpsKey = 'pending_task_ops';
  // فهرس صغير: taskId → projectId، حتى نعرف من أي كاش نمسح/نحدّث التاسك
  // (بما إنه updateTaskStatus وdeleteTask بياخدوا taskId بس).
  static const _indexKey = 'task_project_index';

  final TaskRemoteDataSource _remoteDataSource;
  final LocalCacheService _cache;
  final ConnectivityService _connectivityService;

  TaskRepositoryImpl({
    required TaskRemoteDataSource remoteDataSource,
    required LocalCacheService cache,
    required ConnectivityService connectivityService,
  })  : _remoteDataSource = remoteDataSource,
        _cache = cache,
        _connectivityService = connectivityService;

  String _cacheKey(String projectId) => 'cache_tasks_$projectId';

  @override
  Future<Either<Failure, List<TaskEntity>>> getTasks(String projectId) async {
    final isConnected = await _connectivityService.isConnected;

    if (isConnected) {
      try {
        final tasks = await _remoteDataSource.getTasks(projectId);
        await _cache.saveList(
          _cacheKey(projectId),
          tasks.map((t) => (t as TaskModel).toJson()).toList(),
        );
        await _indexTasks(projectId, tasks.map((t) => t.id));
        return Right(tasks);
      } on DioException catch (e) {
        return _readCachedList(projectId) ?? Left(DioErrorMapper.map(e));
      } catch (e) {
        return _readCachedList(projectId) ?? Left(UnknownFailure(e.toString()));
      }
    }

    return _readCachedList(projectId) ??
        const Left(NetworkFailure('لا يوجد اتصال بالإنترنت ولا بيانات محفوظة محلياً.'));
  }

  @override
  Future<Either<Failure, TaskEntity>> createTask({
    required String projectId,
    required String title,
    String? description,
    bool isImportant = false,
    bool isUrgent = false,
    DateTime? dueDate,
    String? labelId,
    RepeatFrequency repeatFrequency = RepeatFrequency.none,
  }) async {
    final isConnected = await _connectivityService.isConnected;

    if (isConnected) {
      try {
        final task = await _remoteDataSource.createTask(
          projectId: projectId,
          title: title,
          description: description,
          isImportant: isImportant,
          isUrgent: isUrgent,
          dueDate: dueDate,
          labelId: labelId,
          repeatFrequency: repeatFrequency,
        );
        final current = _cache.getList(_cacheKey(projectId)) ?? [];
        current.add((task as TaskModel).toJson());
        await _cache.saveList(_cacheKey(projectId), current);
        await _indexTasks(projectId, [task.id]);
        return Right(task);
      } on DioException catch (e) {
        return Left(DioErrorMapper.map(e));
      } catch (e) {
        return Left(UnknownFailure(e.toString()));
      }
    }

    // أوفلاين: تاسك محلي مؤقت + تسجيل عملية "إنشاء" بطابور المزامنة
    final tempId = 'local_${DateTime.now().millisecondsSinceEpoch}';
    final localTask = TaskModel(
      id: tempId,
      title: title,
      description: description,
      status: TaskStatus.notStarted,
      isImportant: isImportant,
      isUrgent: isUrgent,
      dueDate: dueDate,
      projectId: projectId,
      createdAt: DateTime.now(),
      labelId: labelId,
      repeatFrequency: repeatFrequency,
    );
    final current = _cache.getList(_cacheKey(projectId)) ?? [];
    current.add(localTask.toJson());
    await _cache.saveList(_cacheKey(projectId), current);
    await _indexTasks(projectId, [tempId]);
    await _addPendingOp({
      'type': 'create',
      'tempId': tempId,
      'projectId': projectId,
      'title': title,
      'description': description,
      'isImportant': isImportant,
      'isUrgent': isUrgent,
      'dueDate': dueDate?.toIso8601String(),
      'labelId': labelId,
      'repeatFrequency': TaskModel.repeatToString(repeatFrequency),
    });
    return Right(localTask);
  }

  @override
  Future<Either<Failure, TaskEntity>> updateTaskStatus({
    required String taskId,
    required TaskStatus status,
  }) async {
    final isConnected = await _connectivityService.isConnected;
    final isLocalOnly = taskId.startsWith('local_');

    if (isConnected && !isLocalOnly) {
      try {
        final task = await _remoteDataSource.updateTaskStatus(taskId: taskId, status: status);
        await _updateCachedStatus(taskId, status);
        return Right(task);
      } on DioException catch (e) {
        return Left(DioErrorMapper.map(e));
      } catch (e) {
        return Left(UnknownFailure(e.toString()));
      }
    }

    final updated = await _updateCachedStatus(taskId, status);
    if (updated == null) {
      return const Left(NetworkFailure('التاسك غير موجود بالكاش.'));
    }

    if (isLocalOnly) {
      // لسا ما تزامن → منحدّث الحالة داخل عملية "الإنشاء" المعلّقة نفسها
      await _updatePendingCreateStatus(taskId, status);
    } else {
      await _addPendingOp({'type': 'updateStatus', 'id': taskId, 'status': TaskModel.statusToString(status)});
    }
    return Right(updated);
  }

  @override
  Future<Either<Failure, List<String>>> uploadAttachments({
    required String taskId,
    required List<String> filePaths,
  }) async {
    // رفع مرفقات محتاج اتصال فعلي بالسيرفر، ما منعمله أوفلاين.
    final isConnected = await _connectivityService.isConnected;
    if (!isConnected) {
      return const Left(NetworkFailure('رفع المرفقات يحتاج اتصال بالإنترنت.'));
    }
    try {
      final urls = await _remoteDataSource.uploadAttachments(taskId: taskId, filePaths: filePaths);
      return Right(urls);
    } on DioException catch (e) {
      return Left(DioErrorMapper.map(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTask(String taskId) async {
    final isConnected = await _connectivityService.isConnected;
    final isLocalOnly = taskId.startsWith('local_');
    final projectId = await _lookupProjectId(taskId);

    if (isConnected && !isLocalOnly) {
      try {
        await _remoteDataSource.deleteTask(taskId);
        if (projectId != null) await _removeFromCache(projectId, taskId);
        return const Right(null);
      } on DioException catch (e) {
        return Left(DioErrorMapper.map(e));
      } catch (e) {
        return Left(UnknownFailure(e.toString()));
      }
    }

    if (projectId != null) await _removeFromCache(projectId, taskId);

    if (isLocalOnly) {
      await _removePendingCreate(taskId);
    } else {
      // إذا كان في تعديل حالة معلّق لنفس التاسك، ما عاد له داعي
      await _removePendingUpdateStatus(taskId);
      await _addPendingOp({'type': 'delete', 'id': taskId});
    }
    return const Right(null);
  }

  // ─── Syncable ───

  @override
  Future<void> syncPendingChanges() async {
    final ops = _cache.getList(_pendingOpsKey) ?? [];
    if (ops.isEmpty) return;

    final remaining = <Map<String, dynamic>>[];
    for (final op in ops) {
      try {
        switch (op['type']) {
          case 'create':
            final created = await _remoteDataSource.createTask(
              projectId: op['projectId'] as String,
              title: op['title'] as String,
              description: op['description'] as String?,
              isImportant: op['isImportant'] as bool? ?? false,
              isUrgent: op['isUrgent'] as bool? ?? false,
              dueDate: op['dueDate'] != null ? DateTime.tryParse(op['dueDate'] as String) : null,
              labelId: op['labelId'] as String?,
              repeatFrequency: _repeatFromStringPublic(op['repeatFrequency'] as String?),
            );
            var syncedTask = created as TaskModel;
            // إذا كانت الحالة تغيّرت أوفلاين لهاد التاسك (مثلاً صار Completed)
            // قبل ما ينخلق أصلاً بالسيرفر، منطبّق الحالة النهائية هلق.
            final pendingStatus = op['pendingStatus'] as String?;
            if (pendingStatus != null) {
              syncedTask = await _remoteDataSource.updateTaskStatus(
                taskId: syncedTask.id,
                status: _statusFromStringPublic(pendingStatus),
              ) as TaskModel;
            }
            await _replaceTempId(op['projectId'] as String, op['tempId'] as String, syncedTask);
            break;

          case 'updateStatus':
            await _remoteDataSource.updateTaskStatus(
              taskId: op['id'] as String,
              status: _statusFromStringPublic(op['status'] as String),
            );
            break;

          case 'delete':
            await _remoteDataSource.deleteTask(op['id'] as String);
            break;
        }
      } catch (_) {
        remaining.add(op);
      }
    }
    await _cache.saveList(_pendingOpsKey, remaining);
  }

  // ─── Helpers ───

  Either<Failure, List<TaskEntity>>? _readCachedList(String projectId) {
    final json = _cache.getList(_cacheKey(projectId));
    if (json == null) return null;
    return Right(json.map(TaskModel.fromJson).toList());
  }

  Future<TaskEntity?> _updateCachedStatus(String taskId, TaskStatus status) async {
    final projectId = await _lookupProjectId(taskId);
    if (projectId == null) return null;

    final current = _cache.getList(_cacheKey(projectId)) ?? [];
    final index = current.indexWhere((t) => t['id'] == taskId);
    if (index == -1) return null;

    current[index] = {...current[index], 'status': TaskModel.statusToString(status)};
    await _cache.saveList(_cacheKey(projectId), current);
    return TaskModel.fromJson(current[index]);
  }

  Future<void> _removeFromCache(String projectId, String taskId) async {
    final current = _cache.getList(_cacheKey(projectId)) ?? [];
    current.removeWhere((t) => t['id'] == taskId);
    await _cache.saveList(_cacheKey(projectId), current);
    final index = _cache.getObject(_indexKey) ?? {};
    index.remove(taskId);
    await _cache.saveObject(_indexKey, index);
  }

  Future<void> _replaceTempId(String projectId, String tempId, TaskModel synced) async {
    final current = _cache.getList(_cacheKey(projectId)) ?? [];
    final idx = current.indexWhere((t) => t['id'] == tempId);
    if (idx != -1) {
      current[idx] = synced.toJson();
      await _cache.saveList(_cacheKey(projectId), current);
    }
    final index = _cache.getObject(_indexKey) ?? {};
    index.remove(tempId);
    index[synced.id] = projectId;
    await _cache.saveObject(_indexKey, index);
  }

  Future<void> _indexTasks(String projectId, Iterable<String> taskIds) async {
    final index = _cache.getObject(_indexKey) ?? {};
    for (final id in taskIds) {
      index[id] = projectId;
    }
    await _cache.saveObject(_indexKey, index);
  }

  Future<String?> _lookupProjectId(String taskId) async {
    final index = _cache.getObject(_indexKey) ?? {};
    return index[taskId] as String?;
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

  Future<void> _removePendingUpdateStatus(String taskId) async {
    final ops = _cache.getList(_pendingOpsKey) ?? [];
    ops.removeWhere((op) => op['type'] == 'updateStatus' && op['id'] == taskId);
    await _cache.saveList(_pendingOpsKey, ops);
  }

  Future<void> _updatePendingCreateStatus(String tempId, TaskStatus status) async {
    final ops = _cache.getList(_pendingOpsKey) ?? [];
    final index = ops.indexWhere((op) => op['type'] == 'create' && op['tempId'] == tempId);
    if (index != -1) {
      ops[index] = {...ops[index], 'pendingStatus': TaskModel.statusToString(status)};
      await _cache.saveList(_pendingOpsKey, ops);
    }
  }

  TaskStatus _statusFromStringPublic(String value) {
    switch (value) {
      case 'in_progress':
        return TaskStatus.inProgress;
      case 'completed':
        return TaskStatus.completed;
      default:
        return TaskStatus.notStarted;
    }
  }

  RepeatFrequency _repeatFromStringPublic(String? value) {
    switch (value) {
      case 'daily':
        return RepeatFrequency.daily;
      case 'weekly':
        return RepeatFrequency.weekly;
      case 'monthly':
        return RepeatFrequency.monthly;
      default:
        return RepeatFrequency.none;
    }
  }
}
