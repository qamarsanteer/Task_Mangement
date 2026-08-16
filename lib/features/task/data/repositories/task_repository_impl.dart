import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/cache/local_cache_service.dart';
import '../../../../core/error/dio_error_mapper.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/sync/syncable.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/entities/deleted_task_entry.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_remote_data_source.dart';
import '../models/task_model.dart';

class TaskRepositoryImpl implements TaskRepository, Syncable {
  static const _pendingOpsKey = 'pending_task_ops';
  // فهرس صغير: taskId → projectId، حتى نعرف من أي كاش نمسح/نحدّث التاسك
  // (بما إنه updateTaskStatus وdeleteTask بياخدوا taskId بس).
  static const _indexKey = 'task_project_index';
  // كاش سلة المحذوفات — لقطة (snapshot) كاملة لكل تاسك محذوف مؤقتاً
  // (التاسك نفسه + اسم المشروع/الـ workspace وقت الحذف + تاريخ الحذف).
  static const _binCacheKey = 'cache_deleted_tasks';

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
  Future<Either<Failure, TaskEntity>> updateTask({
    required String taskId,
    required String title,
    String? description,
    bool isImportant = false,
    bool isUrgent = false,
    DateTime? dueDate,
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
          labelId: labelId,
          repeatFrequency: repeatFrequency,
        );
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
      labelId: labelId,
      repeatFrequency: repeatFrequency,
    );
    if (updated == null) {
      return const Left(NetworkFailure('التاسك غير موجود بالكاش.'));
    }

    if (isLocalOnly) {
      // لسا ما تزامن → منحدّث الحقول داخل عملية "الإنشاء" المعلّقة نفسها
      // (بدل ما نضيف عملية منفصلة ممكن تعمل تعارض بالترتيب وقت المزامنة).
      await _updatePendingCreateFields(
        taskId,
        title: title,
        description: description,
        isImportant: isImportant,
        isUrgent: isUrgent,
        dueDate: dueDate,
        labelId: labelId,
        repeatFrequency: repeatFrequency,
      );
    } else {
      // إذا في تعديل معلّق سابق لنفس التاسك، منستبدله بدل ما نكدّس عمليتين
      await _removePendingUpdate(taskId);
      await _addPendingOp({
        'type': 'update',
        'id': taskId,
        'title': title,
        'description': description,
        'isImportant': isImportant,
        'isUrgent': isUrgent,
        'dueDate': dueDate?.toIso8601String(),
        'labelId': labelId,
        'repeatFrequency': TaskModel.repeatToString(repeatFrequency),
      });
    }
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

    // تاسك محلي بعده ما تزامن (local_) أو الجهاز أوفلاين: منخزّن أسماء
    // الملفات بالكاش مباشرة بدل ما نحاول نرفعها عالـ remoteDataSource،
    // لأنه هداك ما رح يلاقي أصلاً تاسك بهيدا المعرّف المؤقت (وهاد بالضبط
    // كان سبب اختفاء/نقصان المرفقات وقت إنشاء تاسك جديد بدون اتصال حقيقي).
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

    // إذا كان التاسك لسا محلي (local_) وما انرفع عالسيرفر أصلاً، المرفق
    // كان مخزّن بس بالكاش المحلي أساساً، فحذفه من الكاش كافي وما في
    // داعي نسجّل عملية مزامنة منفصلة إلو.
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

    // منضيف الروابط الجداد لأي روابط موجودة أصلاً بالكاش (مش منستبدلها)،
    // نفس منطق الـ Bloc تماماً، حتى ما نفقد مرفقات سابقة كانت محفوظة.
    final existingUrls = (current[index]['attachment_urls'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final mergedUrls = {...existingUrls, ...attachmentUrls}.toList();

    current[index] = {...current[index], 'attachment_urls': mergedUrls};
    await _cache.saveList(_cacheKey(projectId), current);
    return TaskModel.fromJson(current[index]);
  }

  // ─── حذف مؤقت (نقل للسلة) / استرجاع / حذف نهائي ───

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

    // منلقط بيانات التاسك الكاملة قبل ما نمسحه من الكاش النشط، حتى
    // نخزّنها كـ Snapshot جوا سلة المحذوفات (اسم المشروع/الـ workspace
    // بيتخزنوا هلق كمان، مش بيتجابوا لاحقاً بالـ id، لأنه ممكن ينحذف
    // المشروع أو الـ workspace نفسه قبل ما يسترجع المستخدم التاسك).
    final task = TaskModel.fromJson(current[index]);

    // منشيل التاسك من كاش المشروع النشط + من فهرس taskId → projectId.
    // ⚠️ بقصد ما منلمس pending ops ولا منندي أي remote delete هون —
    // الحذف "المؤقت" (نقل للسلة) عملية محلية 100% لحتى الآن.
    await _removeFromCache(projectId, taskId);

    await _addToBin(DeletedTaskEntry(
      task: task,
      projectName: projectName,
      workspaceId: workspaceId,
      workspaceName: workspaceName,
      deletedAt: DateTime.now(),
    ));

    return const Right(null);
  }

  @override
  Future<Either<Failure, List<DeletedTaskEntry>>> getDeletedTasks() async {
    final entries = await _readBinList();

    // تنظيف كسول (lazy purge): أي تاسك عدّى عليه 30 يوم بالسلة بينحذف
    // نهائياً تلقائياً كل مرة نقرأ فيها قائمة السلة (مثلاً وقت ما تنفتح
    // شاشة الـ Bin). ما في background job حقيقي بالتطبيق فهاي أبسط طريقة
    // مضمونة بدون سيرفر.
    final expired = entries.where((e) => e.isExpired).toList();
    for (final entry in expired) {
      await _finalizeDelete(entry); // best-effort، ما بتوقف لو فشلت
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

    // منرجّعه لنفس كاش المشروع الأصلي (نفس projectId المخزّن بالتاسك
    // نفسه) بدون أي نداء remote، لأنه أصلاً ما كان انحذف من السيرفر.
    final projectId = entry.task.projectId;
    final current = _cache.getList(_cacheKey(projectId)) ?? [];
    current.add((entry.task as TaskModel).toJson());
    await _cache.saveList(_cacheKey(projectId), current);
    await _indexTasks(projectId, [taskId]);

    await _removeFromBin(taskId);
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

  /// الحذف الفعلي (النهائي) — سواء بطلب يدوي من المستخدم من شاشة السلة،
  /// أو تلقائياً بعد ما تعدي مدة الـ 30 يوم.
  Future<Either<Failure, void>> _finalizeDelete(DeletedTaskEntry entry) async {
    final taskId = entry.task.id;
    final isLocalOnly = taskId.startsWith('local_');

    if (isLocalOnly) {
      // التاسك أصلاً ما انخلق عالسيرفر (لسا محلي) — ما في شي نحذفه
      // هناك، بس منلغي عملية "الإنشاء" المعلّقة إلو حتى ما يظهر
      // فجأة بعد ما ترجع المزامنة.
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

    // أوفلاين: منشيله محلياً من السلة فوراً، ومنسجّل عملية حذف معلّقة
    // حتى يتحذف فعلياً من السيرفر لما يرجع الاتصال (نفس آلية 'delete'
    // الموجودة أصلاً بـ syncPendingChanges).
    await _removePendingUpdateStatus(taskId);
    await _removePendingUpdate(taskId);
    await _removeFromBin(taskId);
    await _addPendingOp({'type': 'delete', 'id': taskId});
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

          case 'update':
            await _remoteDataSource.updateTask(
              taskId: op['id'] as String,
              title: op['title'] as String,
              description: op['description'] as String?,
              isImportant: op['isImportant'] as bool? ?? false,
              isUrgent: op['isUrgent'] as bool? ?? false,
              dueDate: op['dueDate'] != null ? DateTime.tryParse(op['dueDate'] as String) : null,
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

  Future<TaskEntity?> _updateCachedFields(
    String taskId, {
    required String title,
    String? description,
    required bool isImportant,
    required bool isUrgent,
    DateTime? dueDate,
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

  // ─── سلة المحذوفات (Bin) — تخزين/قراءة ───

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
}