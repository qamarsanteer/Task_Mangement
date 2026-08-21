import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/cache/local_cache_service.dart';
import '../../../../core/error/dio_error_mapper.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/events/task_changes_bus.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/sync/syncable.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/entities/deleted_task_entry.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_remote_data_source.dart';
import '../models/task_model.dart';
import '../../../project/data/models/project_model.dart';     
import '../../../bin/domain/entities/deleted_project_entry.dart'; 
import '../../../project/domain/entities/project_entity.dart';
import '../../../project/data/datasources/project_remote_data_source.dart';

class TaskRepositoryImpl implements TaskRepository, Syncable {
  static const _pendingOpsKey = 'pending_task_ops';
  static const _indexKey = 'task_project_index';
  static const _binCacheKey = 'cache_deleted_tasks';
  static const _projectBinCacheKey = 'cache_deleted_projects';

  final TaskRemoteDataSource _remoteDataSource;
  final ProjectRemoteDataSource _projectRemoteDataSource;
  final LocalCacheService _cache;
  final ConnectivityService _connectivityService;
  final TaskChangesBus _taskChangesBus;

  TaskRepositoryImpl({
    required TaskRemoteDataSource remoteDataSource,
    required ProjectRemoteDataSource projectRemoteDataSource,
    required LocalCacheService cache,
    required ConnectivityService connectivityService,
    required TaskChangesBus taskChangesBus,
  })  : _remoteDataSource = remoteDataSource,
        _projectRemoteDataSource = projectRemoteDataSource,
        _cache = cache,
        _connectivityService = connectivityService,
        _taskChangesBus = taskChangesBus;

  String _cacheKey(String projectId) => 'cache_tasks_$projectId';

    @override
  Future<Either<Failure, List<TaskEntity>>> getTasks(String projectId) async {
    final isConnected = await _connectivityService.isConnected;

    if (isConnected) {
      try {
        final tasks = await _remoteDataSource.getTasks(projectId);
        final binnedIds = await _binnedTaskIds();
        final filtered = tasks.where((t) => !binnedIds.contains(t.id)).toList();
        await _cache.saveList(
          _cacheKey(projectId),
          filtered.map((t) => (t as TaskModel).toJson()).toList(),
        );
        await _indexTasks(projectId, filtered.map((t) => t.id));
        return Right(filtered);
      } on DioException catch (e) {
        return _readCachedList(projectId) ?? Left(DioErrorMapper.map(e));
      } catch (e) {
        return _readCachedList(projectId) ?? Left(UnknownFailure(e.toString()));
      }
    }

    return _readCachedList(projectId) ??
        const Left(NetworkFailure('لا يوجد اتصال بالإنترنت ولا بيانات محفوظة محلياً.'));
  }

  Future<Set<String>> _binnedTaskIds() async {
    final entries = await _readBinList();
    return entries.map((e) => e.task.id).toSet();
  }

  @override
  Future<Either<Failure, TaskEntity>> createTask({
    required String projectId,
    required String title,
    String? description,
    bool isImportant = false,
    bool isUrgent = false,
    DateTime? dueDate,
    DateTime? startDate,
    bool hasStartTime = false,
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
          startDate: startDate,
          hasStartTime: hasStartTime,
          labelId: labelId,
          repeatFrequency: repeatFrequency,
        );
        final current = _cache.getList(_cacheKey(projectId)) ?? [];
        current.add((task as TaskModel).toJson());
        await _cache.saveList(_cacheKey(projectId), current);
        await _indexTasks(projectId, [task.id]);
        _taskChangesBus.notifyProjectChanged(projectId);
        return Right(task);
      } on DioException catch (e) {
        return Left(DioErrorMapper.map(e));
      } catch (e) {
        return Left(UnknownFailure(e.toString()));
      }
    }

    final tempId = 'local_${DateTime.now().millisecondsSinceEpoch}';
    final localTask = TaskModel(
      id: tempId,
      title: title,
      description: description,
      status: TaskStatus.notStarted,
      isImportant: isImportant,
      isUrgent: isUrgent,
      dueDate: dueDate,
      startDate: startDate,
      hasStartTime: hasStartTime,
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
      'startDate': startDate?.toIso8601String(),
      'hasStartTime': hasStartTime,
      'labelId': labelId,
      'repeatFrequency': TaskModel.repeatToString(repeatFrequency),
    });
    _taskChangesBus.notifyProjectChanged(projectId);
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
        _taskChangesBus.notifyProjectChanged(task.projectId);
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
      await _updatePendingCreateStatus(taskId, status);
    } else {
      await _addPendingOp({'type': 'updateStatus', 'id': taskId, 'status': TaskModel.statusToString(status)});
    }
    _taskChangesBus.notifyProjectChanged(updated.projectId);
    return Right(updated);
  }

  @override
  Future<Either<Failure, TaskEntity>> updateTask({
    required String taskId,
    required String title,
    String? description,
    bool isImportant = false,
    bool isUrgent = false,
    DateTime? dueDate,
    DateTime? startDate,
    bool? hasStartTime,
    String? labelId,
    RepeatFrequency repeatFrequency = RepeatFrequency.none,
  }) async {
    final isConnected = await _connectivityService.isConnected;
    final isLocalOnly = taskId.startsWith('local_');

    if (isConnected && !isLocalOnly) {
      try {
        final task = await _remoteDataSource.updateTask(
          taskId: taskId,
          title: title,
          description: description,
          isImportant: isImportant,
          isUrgent: isUrgent,
          dueDate: dueDate,
          startDate: startDate,
          hasStartTime: hasStartTime,
          labelId: labelId,
          repeatFrequency: repeatFrequency,
        );
        await _updateCachedFields(
          taskId,
          title: title,
          description: description,
          isImportant: isImportant,
          isUrgent: isUrgent,
          dueDate: dueDate,
          startDate: startDate,
          hasStartTime: hasStartTime,
          labelId: labelId,
          repeatFrequency: repeatFrequency,
        );
        _taskChangesBus.notifyProjectChanged(task.projectId);
        return Right(task);
      } on DioException catch (e) {
        return Left(DioErrorMapper.map(e));
      } catch (e) {
        return Left(UnknownFailure(e.toString()));
      }
    }

    final updated = await _updateCachedFields(
      taskId,
      title: title,
      description: description,
      isImportant: isImportant,
      isUrgent: isUrgent,
      dueDate: dueDate,
      startDate: startDate,
      hasStartTime: hasStartTime,
      labelId: labelId,
      repeatFrequency: repeatFrequency,
    );
    if (updated == null) {
      return const Left(NetworkFailure('التاسك غير موجود بالكاش.'));
    }

    if (isLocalOnly) {
      await _updatePendingCreateFields(
        taskId,
        title: title,
        description: description,
        isImportant: isImportant,
        isUrgent: isUrgent,
        dueDate: dueDate,
        startDate: startDate,
        hasStartTime: hasStartTime ?? false,
        labelId: labelId,
        repeatFrequency: repeatFrequency,
      );
    } else {
      await _removePendingUpdate(taskId);
      await _addPendingOp({
        'type': 'update',
        'id': taskId,
        'title': title,
        'description': description,
        'isImportant': isImportant,
        'isUrgent': isUrgent,
        'dueDate': dueDate?.toIso8601String(),
        'startDate': startDate?.toIso8601String(),
        'hasStartTime': hasStartTime,
        'labelId': labelId,
        'repeatFrequency': TaskModel.repeatToString(repeatFrequency),
      });
    }
    _taskChangesBus.notifyProjectChanged(updated.projectId);
    return Right(updated);
  }

  @override
  Future<Either<Failure, List<String>>> uploadAttachments({
    required String taskId,
    required List<String> filePaths,
  }) async {
    final isConnected = await _connectivityService.isConnected;
    final isLocalOnly = taskId.startsWith('local_');

    if (isConnected && !isLocalOnly) {
      try {
        final urls = await _remoteDataSource.uploadAttachments(taskId: taskId, filePaths: filePaths);
        await _updateCachedAttachments(taskId, urls);
        return Right(urls);
      } on DioException catch (e) {
        return Left(DioErrorMapper.map(e));
      } catch (e) {
        return Left(UnknownFailure(e.toString()));
      }
    }

    final updated = await _updateCachedAttachments(taskId, filePaths);
    if (updated == null) {
      return const Left(NetworkFailure('التاسك غير موجود بالكاش.'));
    }
    return Right(filePaths);
  }

  @override
  Future<Either<Failure, TaskEntity>> removeAttachment({
    required String taskId,
    required String attachmentUrl,
  }) async {
    final isConnected = await _connectivityService.isConnected;
    final isLocalOnly = taskId.startsWith('local_');

    if (isConnected && !isLocalOnly) {
      try {
        final task = await _remoteDataSource.removeAttachment(taskId: taskId, attachmentUrl: attachmentUrl);
        await _removeCachedAttachment(taskId, attachmentUrl);
        return Right(task);
      } on DioException catch (e) {
        return Left(DioErrorMapper.map(e));
      } catch (e) {
        return Left(UnknownFailure(e.toString()));
      }
    }

    final updated = await _removeCachedAttachment(taskId, attachmentUrl);
    if (updated == null) {
      return const Left(NetworkFailure('التاسك غير موجود بالكاش.'));
    }

    if (!isLocalOnly) {
      await _addPendingOp({'type': 'removeAttachment', 'id': taskId, 'attachmentUrl': attachmentUrl});
    }
    return Right(updated);
  }

  Future<TaskEntity?> _removeCachedAttachment(String taskId, String attachmentUrl) async {
    final projectId = await _lookupProjectId(taskId);
    if (projectId == null) return null;

    final current = _cache.getList(_cacheKey(projectId)) ?? [];
    final index = current.indexWhere((t) => t['id'] == taskId);
    if (index == -1) return null;

    final existingUrls = (current[index]['attachment_urls'] as List?)?.map((e) => e.toString()).toList() ?? [];
    existingUrls.remove(attachmentUrl);

    current[index] = {...current[index], 'attachment_urls': existingUrls};
    await _cache.saveList(_cacheKey(projectId), current);
    return TaskModel.fromJson(current[index]);
  }

  Future<TaskEntity?> _updateCachedAttachments(String taskId, List<String> attachmentUrls) async {
    final projectId = await _lookupProjectId(taskId);
    if (projectId == null) return null;

    final current = _cache.getList(_cacheKey(projectId)) ?? [];
    final index = current.indexWhere((t) => t['id'] == taskId);
    if (index == -1) return null;

    final existingUrls = (current[index]['attachment_urls'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final mergedUrls = {...existingUrls, ...attachmentUrls}.toList();

    current[index] = {...current[index], 'attachment_urls': mergedUrls};
    await _cache.saveList(_cacheKey(projectId), current);
    return TaskModel.fromJson(current[index]);
  }


  @override
  Future<Either<Failure, void>> deleteTask(
    String taskId, {
    required String projectName,
    required String workspaceId,
    required String workspaceName,
  }) async {
    final projectId = await _lookupProjectId(taskId);
    if (projectId == null) {
      return const Left(NetworkFailure('التاسك غير موجود بالكاش.'));
    }

    final current = _cache.getList(_cacheKey(projectId)) ?? [];
    final index = current.indexWhere((t) => t['id'] == taskId);
    if (index == -1) {
      return const Left(NetworkFailure('التاسك غير موجود بالكاش.'));
    }

    final task = TaskModel.fromJson(current[index]);

    await _removeFromCache(projectId, taskId);

    await _addToBin(DeletedTaskEntry(
      task: task,
      projectName: projectName,
      workspaceId: workspaceId,
      workspaceName: workspaceName,
      deletedAt: DateTime.now(),
    ));

    _taskChangesBus.notifyProjectChanged(projectId);

    return const Right(null);
  }

    @override
  Future<Either<Failure, List<DeletedTaskEntry>>> getDeletedTasks() async {
    final entries = await _readBinList();

    final expired = entries.where((e) => e.isExpired).toList();
    for (final entry in expired) {
      await _finalizeDelete(entry);
    }

    final projectEntries = await _readProjectBinList();
    final expiredProjects = projectEntries.where((e) => e.isExpired).toList();
    for (final entry in expiredProjects) {
      await _finalizeProjectDelete(entry);
    }

    final remaining = expired.isEmpty ? entries : await _readBinList();
    remaining.sort((a, b) => b.deletedAt.compareTo(a.deletedAt));
    return Right(remaining);
  }

  @override
  Future<Either<Failure, TaskEntity>> restoreTask(String taskId) async {
    final entries = await _readBinList();
    DeletedTaskEntry? entry;
    for (final e in entries) {
      if (e.task.id == taskId) {
        entry = e;
        break;
      }
    }
    if (entry == null) {
      return const Left(NetworkFailure('التاسك غير موجود بالسلة.'));
    }

    final projectId = entry.task.projectId;
    final current = _cache.getList(_cacheKey(projectId)) ?? [];
    current.add((entry.task as TaskModel).toJson());
    await _cache.saveList(_cacheKey(projectId), current);
    await _indexTasks(projectId, [taskId]);

    await _removeFromBin(taskId);

    _taskChangesBus.notifyProjectChanged(projectId);

    return Right(entry.task);
  }

  @override
  Future<Either<Failure, void>> deleteTaskForever(String taskId) async {
    final entries = await _readBinList();
    DeletedTaskEntry? entry;
    for (final e in entries) {
      if (e.task.id == taskId) {
        entry = e;
        break;
      }
    }
    if (entry == null) {
      return const Left(NetworkFailure('التاسك غير موجود بالسلة.'));
    }
    return _finalizeDelete(entry);
  }

  Future<Either<Failure, void>> _finalizeDelete(DeletedTaskEntry entry) async {
    final taskId = entry.task.id;
    final isLocalOnly = taskId.startsWith('local_');

    if (isLocalOnly) {
      await _removePendingCreate(taskId);
      await _removeFromBin(taskId);
      return const Right(null);
    }

    final isConnected = await _connectivityService.isConnected;
    if (isConnected) {
      try {
        await _remoteDataSource.deleteTask(taskId);
        await _removePendingUpdateStatus(taskId);
        await _removePendingUpdate(taskId);
        await _removeFromBin(taskId);
        return const Right(null);
      } on DioException catch (e) {
        return Left(DioErrorMapper.map(e));
      } catch (e) {
        return Left(UnknownFailure(e.toString()));
      }
    }

    await _removePendingUpdateStatus(taskId);
    await _removePendingUpdate(taskId);
    await _removeFromBin(taskId);
    await _addPendingOp({'type': 'delete', 'id': taskId});
    return const Right(null);
  }

    @override
  Future<Either<Failure, TaskEntity>> moveTaskToProject({
    required String taskId,
    required String newProjectId,
  }) async {
    final oldProjectId = await _lookupProjectId(taskId);
    if (oldProjectId == null) {
      return const Left(NetworkFailure('التاسك غير موجود بالكاش.'));
    }

    final oldList = _cache.getList(_cacheKey(oldProjectId)) ?? [];
    final index = oldList.indexWhere((t) => t['id'] == taskId);
    if (index == -1) {
      return const Left(NetworkFailure('التاسك غير موجود بالكاش.'));
    }

    if (oldProjectId == newProjectId) {
      return Right(TaskModel.fromJson(oldList[index]));
    }

    final isConnected = await _connectivityService.isConnected;
    final isLocalOnly = taskId.startsWith('local_');

    if (isConnected && !isLocalOnly) {
      try {
        await _remoteDataSource.updateTaskProject(taskId: taskId, newProjectId: newProjectId);
      } on DioException catch (e) {
        return Left(DioErrorMapper.map(e));
      } catch (e) {
        return Left(UnknownFailure(e.toString()));
      }
    }

    final movedJson = {...oldList[index], 'project_id': newProjectId};

    oldList.removeAt(index);
    await _cache.saveList(_cacheKey(oldProjectId), oldList);

    final newList = _cache.getList(_cacheKey(newProjectId)) ?? [];
    newList.add(movedJson);
    await _cache.saveList(_cacheKey(newProjectId), newList);

    await _indexTasks(newProjectId, [taskId]);

    if (isLocalOnly) {
      final ops = _cache.getList(_pendingOpsKey) ?? [];
      final opIndex = ops.indexWhere((op) => op['type'] == 'create' && op['tempId'] == taskId);
      if (opIndex != -1) {
        ops[opIndex] = {...ops[opIndex], 'projectId': newProjectId};
        await _cache.saveList(_pendingOpsKey, ops);
      }
    } else if (!isConnected) {
      await _addPendingOp({'type': 'move', 'id': taskId, 'newProjectId': newProjectId});
    }

    _taskChangesBus.notifyProjectChanged(oldProjectId);
    _taskChangesBus.notifyProjectChanged(newProjectId);

    return Right(TaskModel.fromJson(movedJson));
  }


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
              startDate: op['startDate'] != null ? DateTime.tryParse(op['startDate'] as String) : null,
              hasStartTime: op['hasStartTime'] as bool? ?? false,
              labelId: op['labelId'] as String?,
              repeatFrequency: _repeatFromStringPublic(op['repeatFrequency'] as String?),
            );
            var syncedTask = created as TaskModel;
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

          case 'update':
            await _remoteDataSource.updateTask(
              taskId: op['id'] as String,
              title: op['title'] as String,
              description: op['description'] as String?,
              isImportant: op['isImportant'] as bool? ?? false,
              isUrgent: op['isUrgent'] as bool? ?? false,
              dueDate: op['dueDate'] != null ? DateTime.tryParse(op['dueDate'] as String) : null,
              startDate: op['startDate'] != null ? DateTime.tryParse(op['startDate'] as String) : null,
              hasStartTime: op['hasStartTime'] as bool?,
              labelId: op['labelId'] as String?,
              repeatFrequency: _repeatFromStringPublic(op['repeatFrequency'] as String?),
            );
            break;

          case 'removeAttachment':
            await _remoteDataSource.removeAttachment(
              taskId: op['id'] as String,
              attachmentUrl: op['attachmentUrl'] as String,
            );
            break;

          case 'delete':
            await _remoteDataSource.deleteTask(op['id'] as String);
            break;

          case 'move':
            await _remoteDataSource.updateTaskProject(
              taskId: op['id'] as String,
              newProjectId: op['newProjectId'] as String,
            );
            break;

          case 'deleteProject':
            await _projectRemoteDataSource.deleteProject(op['id'] as String);
            break;  
        }
      } catch (_) {
        remaining.add(op);
      }
    }
    await _cache.saveList(_pendingOpsKey, remaining);
  }


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

  Future<TaskEntity?> _updateCachedFields(
    String taskId, {
    required String title,
    String? description,
    required bool isImportant,
    required bool isUrgent,
    DateTime? dueDate,
    DateTime? startDate,
    bool? hasStartTime,
    String? labelId,
    required RepeatFrequency repeatFrequency,
  }) async {
    final projectId = await _lookupProjectId(taskId);
    if (projectId == null) return null;

    final current = _cache.getList(_cacheKey(projectId)) ?? [];
    final index = current.indexWhere((t) => t['id'] == taskId);
    if (index == -1) return null;

    current[index] = {
      ...current[index],
      'title': title,
      'description': description,
      'is_important': isImportant,
      'is_urgent': isUrgent,
      'due_date': dueDate?.toIso8601String(),
      'start_date': startDate?.toIso8601String(),
      if (hasStartTime != null) 'has_start_time': hasStartTime,
      'label_id': labelId,
      'repeat_frequency': TaskModel.repeatToString(repeatFrequency),
    };
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

  Future<void> _removePendingUpdate(String taskId) async {
    final ops = _cache.getList(_pendingOpsKey) ?? [];
    ops.removeWhere((op) => op['type'] == 'update' && op['id'] == taskId);
    await _cache.saveList(_pendingOpsKey, ops);
  }

  Future<void> _updatePendingCreateFields(
    String tempId, {
    required String title,
    String? description,
    required bool isImportant,
    required bool isUrgent,
    DateTime? dueDate,
    DateTime? startDate,
    bool hasStartTime = false,
    String? labelId,
    required RepeatFrequency repeatFrequency,
  }) async {
    final ops = _cache.getList(_pendingOpsKey) ?? [];
    final index = ops.indexWhere((op) => op['type'] == 'create' && op['tempId'] == tempId);
    if (index != -1) {
      ops[index] = {
        ...ops[index],
        'title': title,
        'description': description,
        'isImportant': isImportant,
        'isUrgent': isUrgent,
        'dueDate': dueDate?.toIso8601String(),
        'startDate': startDate?.toIso8601String(),
        'hasStartTime': hasStartTime,
        'labelId': labelId,
        'repeatFrequency': TaskModel.repeatToString(repeatFrequency),
      };
      await _cache.saveList(_pendingOpsKey, ops);
    }
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
      case 'pending':
        return TaskStatus.pending;
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

  Future<List<DeletedTaskEntry>> _readBinList() async {
    final raw = _cache.getList(_binCacheKey) ?? [];
    return raw.map(_entryFromJson).toList();
  }

  Future<void> _addToBin(DeletedTaskEntry entry) async {
    final raw = _cache.getList(_binCacheKey) ?? [];
    raw.add(_entryToJson(entry));
    await _cache.saveList(_binCacheKey, raw);
  }

  Future<void> _removeFromBin(String taskId) async {
    final raw = _cache.getList(_binCacheKey) ?? [];
    raw.removeWhere((e) => e['task']?['id'] == taskId);
    await _cache.saveList(_binCacheKey, raw);
  }

  Map<String, dynamic> _entryToJson(DeletedTaskEntry entry) {
    return {
      'task': (entry.task as TaskModel).toJson(),
      'project_name': entry.projectName,
      'workspace_id': entry.workspaceId,
      'workspace_name': entry.workspaceName,
      'deleted_at': entry.deletedAt.toIso8601String(),
    };
  }

  DeletedTaskEntry _entryFromJson(Map<String, dynamic> json) {
    return DeletedTaskEntry(
      task: TaskModel.fromJson(json['task'] as Map<String, dynamic>),
      projectName: json['project_name']?.toString() ?? '',
      workspaceId: json['workspace_id']?.toString() ?? '',
      workspaceName: json['workspace_name']?.toString() ?? '',
      deletedAt: json['deleted_at'] != null
          ? DateTime.tryParse(json['deleted_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  @override
  Future<Either<Failure, void>> deleteProjectToBin({
    required String projectId,
    required String workspaceId,
    required String workspaceName,
    ProjectEntity? project, 
  }) async {
    final tasksJson = _cache.getList(_cacheKey(projectId)) ?? [];
    final tasks = tasksJson.map(TaskModel.fromJson).toList();

    final ProjectEntity projectToBin;
    if (project != null) {
      projectToBin = project;
    } else {
      final projectsJson = _cache.getList('cache_projects_$workspaceId') ?? [];
      final projectMap = projectsJson.cast<Map<String, dynamic>>().firstWhere(
            (p) => p['id'] == projectId,
            orElse: () => {},
          );
      if (projectMap.isEmpty) {
        return const Left(NetworkFailure('المشروع غير موجود بالكاش.'));
      }
      projectToBin = ProjectModel.fromJson(projectMap);
    }

    final currentProjects = _cache.getList('cache_projects_$workspaceId') ?? [];
    currentProjects.removeWhere((p) => p['id'] == projectId);
    await _cache.saveList('cache_projects_$workspaceId', currentProjects);

    await _cache.saveList(_cacheKey(projectId), []);
    final index = _cache.getObject(_indexKey) ?? {};
    for (final t in tasks) {
      index.remove(t.id);
    }
    await _cache.saveObject(_indexKey, index);

    await _addProjectToBin(DeletedProjectEntry(
      project: projectToBin,
      tasks: tasks,
      workspaceId: workspaceId,
      workspaceName: workspaceName,
      deletedAt: DateTime.now(),
    ));

    _taskChangesBus.notifyProjectChanged(projectId);

    return const Right(null);
  }

  @override
  Future<Either<Failure, List<DeletedProjectEntry>>> getDeletedProjects() async {
    final entries = await _readProjectBinList();
    final expired = entries.where((e) => e.isExpired).toList();
    for (final entry in expired) { await _finalizeProjectDelete(entry); }
    final remaining = expired.isEmpty ? entries : await _readProjectBinList();
    remaining.sort((a, b) => b.deletedAt.compareTo(a.deletedAt));
    return Right(remaining);
  }

  @override
  Future<Either<Failure, ProjectEntity>> restoreProject(String projectId) async {
    final entries = await _readProjectBinList();
    DeletedProjectEntry? entry;
    for (final e in entries) {
      if (e.project.id == projectId) { entry = e; break; }
    }
    if (entry == null) {
      return const Left(NetworkFailure('المشروع غير موجود بالسلة.'));
    }

    final workspaceId = entry.workspaceId;
    final currentProjects = _cache.getList('cache_projects_$workspaceId') ?? [];
    currentProjects.add((entry.project as ProjectModel).toJson());
    await _cache.saveList('cache_projects_$workspaceId', currentProjects);

    final taskJsonList = entry.tasks.map((t) => (t as TaskModel).toJson()).toList();
    await _cache.saveList(_cacheKey(projectId), taskJsonList);

    final index = _cache.getObject(_indexKey) ?? {};
    for (final t in entry.tasks) { index[t.id] = projectId; }
    await _cache.saveObject(_indexKey, index);

    await _removeFromProjectBin(projectId);
    _taskChangesBus.notifyProjectChanged(projectId);
    return Right(entry.project);
  }

  @override
  Future<Either<Failure, void>> deleteProjectForever(String projectId) async {
    final entries = await _readProjectBinList();
    DeletedProjectEntry? entry;
    for (final e in entries) {
      if (e.project.id == projectId) { entry = e; break; }
    }
    if (entry == null) {
      return const Left(NetworkFailure('المشروع غير موجود بالسلة.'));
    }
    return _finalizeProjectDelete(entry);
  }

  Future<Either<Failure, void>> _finalizeProjectDelete(DeletedProjectEntry entry) async {
  final projectId = entry.project.id;
  final isLocalOnly = projectId.startsWith('local_');
  final isConnected = await _connectivityService.isConnected;

  if (isConnected) {
    try {
      for (final task in entry.tasks) {
        if (!task.id.startsWith('local_')) {
          await _remoteDataSource.deleteTask(task.id);
        }
      }
      if (!isLocalOnly) {
        await _projectRemoteDataSource.deleteProject(projectId);
      }
    } on DioException catch (e) {
      return Left(DioErrorMapper.map(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  for (final task in entry.tasks) {
    await _removePendingUpdateStatus(task.id);
    await _removePendingUpdate(task.id);
    if (task.id.startsWith('local_')) {
      await _removePendingCreate(task.id);
    }
  }

  if (isLocalOnly) {
    await _removePendingCreateProject(projectId);
  } else if (!isConnected) {
    await _addPendingOp({'type': 'deleteProject', 'id': projectId});
  }

  await _removeFromProjectBin(projectId);
  return const Right(null);
}

Future<void> _removePendingCreateProject(String tempId) async {
}


  Future<List<DeletedProjectEntry>> _readProjectBinList() async {
    final raw = _cache.getList(_projectBinCacheKey) ?? [];
    return raw.map(_projectEntryFromJson).toList();
  }

  Future<void> _addProjectToBin(DeletedProjectEntry entry) async {
    final raw = _cache.getList(_projectBinCacheKey) ?? [];
    raw.add(_projectEntryToJson(entry));
    await _cache.saveList(_projectBinCacheKey, raw);
  }

  Future<void> _removeFromProjectBin(String projectId) async {
    final raw = _cache.getList(_projectBinCacheKey) ?? [];
    raw.removeWhere((e) => e['project']?['id'] == projectId);
    await _cache.saveList(_projectBinCacheKey, raw);
  }

  Map<String, dynamic> _projectEntryToJson(DeletedProjectEntry entry) {
    return {
      'project': (entry.project as ProjectModel).toJson(),
      'tasks': entry.tasks.map((t) => (t as TaskModel).toJson()).toList(),
      'workspace_id': entry.workspaceId,
      'workspace_name': entry.workspaceName,
      'deleted_at': entry.deletedAt.toIso8601String(),
    };
  }

  DeletedProjectEntry _projectEntryFromJson(Map<String, dynamic> json) {
    return DeletedProjectEntry(
      project: ProjectModel.fromJson(json['project'] as Map<String, dynamic>),
      tasks: (json['tasks'] as List? ?? [])
          .map((t) => TaskModel.fromJson(t as Map<String, dynamic>))
          .toList(),
      workspaceId: json['workspace_id']?.toString() ?? '',
      workspaceName: json['workspace_name']?.toString() ?? '',
      deletedAt: json['deleted_at'] != null
          ? DateTime.tryParse(json['deleted_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}